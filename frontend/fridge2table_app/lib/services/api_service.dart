import 'dart:convert';
import 'dart:async';
import 'dart:io' show SocketException;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';
import '../config/supabase_config.dart';
import '../main.dart';
import '../models/ingredient.dart';
import '../screens/signin_screen.dart';
import 'auth_service.dart';
import 'delete_tombstones.dart';
import 'local_pantry_store.dart';
import 'supabase_service.dart';

/// Thrown by [ApiService._send] specifically for "couldn't reach the server
/// at all" failures (timeout, or no route to host) as opposed to a real
/// HTTP error response. Kept as its own type -- rather than the plain
/// Exception these cases used to throw -- purely so the offline-aware
/// wrappers below can tell "we're offline, fall back to the local cache"
/// apart from "the server responded but rejected the request" without
/// parsing message strings. toString() deliberately matches the format
/// Dart's own Exception('...') produces, so any existing call site that
/// strips a literal "Exception: " prefix off the message still works
/// unchanged.
class NetworkUnavailableException implements Exception {
  final String message;
  const NetworkUnavailableException(this.message);

  @override
  String toString() => "Exception: $message";
}

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static const _timeout = Duration(seconds: 10);

  /// The pantry backend has no notion of accounts of its own — every
  /// request is scoped by this id so one signed-in user never sees or
  /// modifies another's ingredients. Throws if nobody is signed in, since
  /// there should be no way to reach a pantry screen without auth already
  /// having happened.
  static String get _userId {
    if (!SupabaseConfig.isConfigured) {
      debugPrint("[ApiService] _userId: SupabaseConfig.isConfigured is false");
      throw Exception("You must be signed in to access your pantry");
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint(
        "[ApiService] _userId: currentUser is null "
        "(currentSession=${Supabase.instance.client.auth.currentSession != null}) "
        "-- this is a different failure than a 401 from the backend, it means "
        "the local Supabase client has no signed-in user at all right now.",
      );
      throw Exception("You must be signed in to access your pantry");
    }
    return user.id;
  }

  static Uri _uri(String path, [Map<String, String>? extraParams]) {
    return Uri.parse(
      "$baseUrl$path",
    ).replace(queryParameters: {"user_id": _userId, ...?extraParams});
  }

  /// Every request carries the current Supabase session's access token so
  /// the backend can verify who's actually asking (see backend/app/auth.py)
  /// instead of trusting the user_id query param above, which is now
  /// vestigial from the backend's point of view but still sent for any
  /// logging/debugging that inspects the URL.
  ///
  /// Proactively refreshes an expired-but-still-present session before
  /// building the header -- the SDK's own background auto-refresh timer
  /// only runs while the app is alive, so a session whose access token
  /// expired while the app was closed/backgrounded won't necessarily have
  /// been refreshed yet by the time the first request goes out after
  /// reopening.
  static Future<Map<String, String>> _headers({bool json = false}) async {
    var session = Supabase.instance.client.auth.currentSession;

    if (session != null && session.isExpired) {
      debugPrint(
        "[ApiService] Access token expired (expiresAt=${session.expiresAt}), "
        "refreshing session before this request...",
      );
      try {
        final result = await Supabase.instance.client.auth.refreshSession();
        session = result.session;
        debugPrint(
          session != null
              ? "[ApiService] Session refresh succeeded, new "
                    "expiresAt=${session.expiresAt}"
              : "[ApiService] Session refresh returned no session",
        );
      } catch (e) {
        debugPrint("[ApiService] Session refresh failed: $e");
      }
    }

    final token = session?.accessToken;
    debugPrint(
      token == null
          ? "[ApiService] No access token available -- request will go out "
                "with no Authorization header"
          : "[ApiService] Attaching Authorization header "
                "(token prefix: ${token.substring(0, token.length < 16 ? token.length : 16)}..., "
                "expiresAt=${session?.expiresAt}, isExpired=${session?.isExpired})",
    );

    return {
      if (token != null) "Authorization": "Bearer $token",
      if (json) "Content-Type": "application/json",
    };
  }

  /// Runs an HTTP call with a consistent timeout and turns the handful of
  /// ways it can fail into distinct, actionable messages instead of one
  /// generic "something went wrong" — this is the difference between
  /// "the server took too long" (slow/overloaded), "can't reach the
  /// server at all" (wrong address/adb reverse not set up/backend not
  /// running), and an actual HTTP error response from a reachable server.
  static Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw NetworkUnavailableException(
        ApiConfig.usingAdbReverse
            ? "The server didn't respond in time. Run `adb reverse tcp:8000 "
                  "tcp:8000` and make sure the backend is running, then try again."
            : "The server didn't respond in time. Check the backend is "
                  "running and reachable at ${ApiConfig.baseUrl}.",
      );
    } on SocketException {
      // On a physical device resolved via the adb-reverse address, a
      // connection failure (as opposed to a timeout) almost always means
      // adb reverse was never run this session -- nothing is listening on
      // the device's own localhost:8000 at all, so the OS refuses the
      // connection immediately rather than hanging. This is not the same
      // as "no internet" and telling the user to check their WiFi would be
      // actively misleading here.
      throw NetworkUnavailableException(
        ApiConfig.usingAdbReverse
            ? "Can't reach the app's server. Run this in a terminal, then "
                  "try again:\n\nadb reverse tcp:8000 tcp:8000\n\n"
                  "(This is not your phone's internet connection — the backend "
                  "runs on your dev machine and needs this USB port forward.)"
            : "Can't reach the app's server at ${ApiConfig.baseUrl}. Check "
                  "the backend is running and the address is correct.",
      );
    }

    debugPrint(
      "[ApiService] ${response.request?.method} ${response.request?.url} "
      "-> ${response.statusCode}",
    );

    if (response.statusCode == 401) {
      debugPrint(
        "[ApiService] 401 response body: "
        "${response.body.substring(0, response.body.length < 300 ? response.body.length : 300)}",
      );
      await _handleUnauthorized();
      throw Exception("Your session has expired. Please sign in again.");
    }

    return response;
  }

  /// A 401 means the backend no longer accepts this session's token (it
  /// expired, or was revoked) -- there's no path forward except signing in
  /// again, so this clears the stale local session and drops the user back
  /// on SignInScreen from wherever they were, rather than leaving them
  /// stuck on a screen that will just keep failing the same way.
  static Future<void> _handleUnauthorized() async {
    if (SupabaseConfig.isConfigured) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {
        // Best-effort -- still clear the local session below even if the
        // network sign-out call itself fails (e.g. already offline).
      }
    }
    await AuthService.clearSession();

    rootNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  // GET inventory -- offline-first: an unreachable backend falls back to
  // whatever was last cached locally (plus anything added/edited since)
  // instead of surfacing an error, since "no signal right now" shouldn't
  // mean "can't see your own pantry".
  static Future<List<Ingredient>> getInventory() async {
    try {
      await _pushPendingChanges();
      final serverItems = await _fetchInventoryFromServer();
      await LocalPantryStore.cacheServerSnapshot(serverItems);
      return LocalPantryStore.getVisibleInventory();
    } on NetworkUnavailableException {
      debugPrint("[ApiService] getInventory: offline, serving local cache");
      return LocalPantryStore.getVisibleInventory();
    }
  }

  static Future<List<Ingredient>> _fetchInventoryFromServer() async {
    final response = await _send(
      () async => http.get(_uri("/inventory"), headers: await _headers()),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      return data.map((item) => Ingredient.fromJson(item)).toList();
    }

    throw Exception(
      "Failed to load inventory (server returned ${response.statusCode})",
    );
  }

  // POST ingredient -- always written to the local mirror first (instant,
  // works offline), then pushed to the server immediately if reachable. If
  // the push fails purely because there's no connection, the row stays
  // queued in LocalPantryStore and a later getInventory()/sync pass will
  // finish sending it -- this call still returns normally either way, since
  // from the caller's point of view the ingredient has been saved.
  static Future<void> addIngredient(Ingredient ingredient) async {
    final queued = await LocalPantryStore.queueCreate(ingredient);
    try {
      final created = await _createIngredientOnServer(ingredient);
      // queued.id is the negative -localId sentinel; markSynced wants the
      // raw positive local_id.
      await LocalPantryStore.markSynced(-queued.id!, newServerId: created.id);
    } on NetworkUnavailableException {
      debugPrint(
        "[ApiService] addIngredient: offline, queued locally "
        "(local id ${queued.id})",
      );
    }
  }

  static Future<Ingredient> _createIngredientOnServer(
    Ingredient ingredient,
  ) async {
    // A create must never send an id -- in particular never the negative
    // local-only sentinel a queued row carries -- since the backend treats
    // any non-null id as "upsert this existing row" (see crud.py). Rebuilt
    // here rather than trusting the caller's ingredient.id to be null.
    final payload = Ingredient(
      name: ingredient.name,
      quantity: ingredient.quantity,
      unit: ingredient.unit,
      expiryDate: ingredient.expiryDate,
      category: ingredient.category,
      location: ingredient.location,
    );

    final response = await _send(
      () async => http.post(
        _uri("/ingredient"),
        headers: await _headers(json: true),
        body: jsonEncode(payload.toJson()),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to add ingredient (server returned ${response.statusCode})",
      );
    }

    return Ingredient.fromJson(jsonDecode(response.body));
  }

  // PUT ingredient -- same local-first, push-if-reachable pattern as
  // addIngredient. An id < 0 means this ingredient was created offline and
  // has never reached the server at all yet; in that case there's nothing
  // to PUT, the amended fields just sit in the still-pending local create
  // until that syncs.
  static Future<void> updateIngredient(int id, Ingredient ingredient) async {
    await LocalPantryStore.queueUpdate(id, ingredient);
    if (id < 0) return;

    try {
      await _updateIngredientOnServer(id, ingredient);
      await LocalPantryStore.markSyncedForUiId(id);
    } on NetworkUnavailableException {
      debugPrint(
        "[ApiService] updateIngredient: offline, queued update for id $id",
      );
    }
  }

  static Future<void> _updateIngredientOnServer(
    int id,
    Ingredient ingredient,
  ) async {
    final response = await _send(
      () async => http.put(
        _uri("/ingredient/$id"),
        headers: await _headers(json: true),
        body: jsonEncode(ingredient.toJson()),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to update ingredient (server returned ${response.statusCode})",
      );
    }
  }

  // DELETE ingredient -- same local-first pattern. An id < 0 was never
  // synced, so queueDelete has already removed it outright locally and
  // there is nothing on the server to delete.
  static Future<void> deleteIngredient(int id) async {
    await LocalPantryStore.queueDelete(id);
    if (id < 0) return;

    try {
      await _deleteIngredientOnServer(id);
      await LocalPantryStore.confirmDeleteForUiId(id);
    } on NetworkUnavailableException {
      debugPrint(
        "[ApiService] deleteIngredient: offline, queued delete for id $id",
      );
    }
  }

  static Future<void> _deleteIngredientOnServer(int id) async {
    final response = await _send(
      () async =>
          http.delete(_uri("/ingredient/$id"), headers: await _headers()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to delete ingredient (server returned ${response.statusCode})",
      );
    }

    // Recorded before the mirror-delete attempt so that, if it fails (e.g.
    // offline right at this instant), the next sync can finish deleting the
    // stale cloud row instead of resurrecting this ingredient locally.
    // Cleared immediately once the mirror confirms the cloud row is gone.
    await DeleteTombstones.add(id);
    final mirrored = await SupabaseService.deleteIngredient(id);
    if (mirrored) {
      await DeleteTombstones.remove(id);
    }
  }

  /// Pushes every locally-queued create/update/delete to the server, in
  /// the order they were made. Used both opportunistically at the top of
  /// [getInventory] and (via that same call) by MainScreen's
  /// connectivity-change listener, which calls getInventory() the moment
  /// the device comes back online. Stops at the first NetworkUnavailableException
  /// -- if the connection just dropped again mid-pass, there's no point
  /// attempting the rest -- but a failure for one specific row (e.g. it was
  /// deleted server-side some other way) is logged and skipped so it
  /// doesn't block the rows queued after it.
  static Future<void> _pushPendingChanges() async {
    final pending = await LocalPantryStore.getPendingRows();

    for (final row in pending) {
      final localId = row['local_id'] as int;
      final action = row['pending_action'] as String?;

      try {
        switch (action) {
          case 'create':
            final created = await _createIngredientOnServer(
              LocalPantryStore.ingredientFromRow(row),
            );
            await LocalPantryStore.markSynced(localId, newServerId: created.id);
            break;

          case 'update':
            final serverId = row['server_id'] as int?;
            if (serverId == null) break;
            await _updateIngredientOnServer(
              serverId,
              LocalPantryStore.ingredientFromRow(row),
            );
            await LocalPantryStore.markSynced(localId);
            break;

          case 'delete':
            final serverId = row['server_id'] as int?;
            if (serverId == null) {
              await LocalPantryStore.deleteLocalRow(localId);
              break;
            }
            await _deleteIngredientOnServer(serverId);
            await LocalPantryStore.deleteLocalRow(localId);
            break;
        }
      } on NetworkUnavailableException {
        debugPrint(
          "[ApiService] _pushPendingChanges: went offline mid-sync, "
          "stopping (local_id=$localId will retry next time)",
        );
        return;
      } catch (e) {
        debugPrint(
          "[ApiService] _pushPendingChanges: failed to sync "
          "local_id=$localId action=$action: $e -- leaving queued",
        );
      }
    }
  }

  static Future<List<String>> getRecipes() async {
    final response = await _send(
      () async => http.get(_uri("/recipes"), headers: await _headers()),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      return data.map<String>((item) => item.toString()).toList();
    }

    throw Exception(
      "Failed to load recipes (server returned ${response.statusCode})",
    );
  }

  static Future<List<Map<String, dynamic>>> getRecipesDetailed() async {
    final response = await _send(
      () async => http.get(_uri("/recipes"), headers: await _headers()),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception(
      "Failed to load recipes (server returned ${response.statusCode})",
    );
  }

  static Future<String?> getAiRecommendation() async {
    final response = await _send(
      () async =>
          http.get(_uri("/ai-recommendation"), headers: await _headers()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data["recipe_name"] as String?;
    }

    throw Exception(
      "Failed to load AI recommendation (server returned ${response.statusCode})",
    );
  }

  static Future<List<Map<String, dynamic>>> getExpiryStatus() async {
    final response = await _send(
      () async => http.get(_uri("/expiry-status"), headers: await _headers()),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception(
      "Failed to load expiry status (server returned ${response.statusCode})",
    );
  }
}
