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
import 'supabase_service.dart';

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
      throw Exception(
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
      throw Exception(
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

  // GET inventory
  static Future<List<Ingredient>> getInventory() async {
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

  // POST ingredient
  static Future<void> addIngredient(Ingredient ingredient) async {
    final response = await _send(
      () async => http.post(
        _uri("/ingredient"),
        headers: await _headers(json: true),
        body: jsonEncode(ingredient.toJson()),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to add ingredient (server returned ${response.statusCode})",
      );
    }
  }

  static Future<void> updateIngredient(int id, Ingredient ingredient) async {
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

  static Future<void> deleteIngredient(int id) async {
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
