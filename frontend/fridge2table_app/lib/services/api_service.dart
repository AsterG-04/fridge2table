import 'dart:convert';
import 'dart:async';
import 'dart:io' show SocketException;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';
import '../config/supabase_config.dart';
import '../models/ingredient.dart';
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
      throw Exception("You must be signed in to access your pantry");
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception("You must be signed in to access your pantry");
    }
    return user.id;
  }

  static Uri _uri(String path, [Map<String, String>? extraParams]) {
    return Uri.parse("$baseUrl$path").replace(queryParameters: {
      "user_id": _userId,
      ...?extraParams,
    });
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
    try {
      return await request().timeout(_timeout);
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
  }

  // GET inventory
  static Future<List<Ingredient>> getInventory() async {
    final response = await _send(() => http.get(_uri("/inventory")));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      return data
          .map((item) => Ingredient.fromJson(item))
          .toList();
    }

    throw Exception("Failed to load inventory (server returned ${response.statusCode})");
  }



  // POST ingredient
  static Future<void> addIngredient(
      Ingredient ingredient) async {

    final response = await _send(() => http.post(
      _uri("/ingredient"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(
        ingredient.toJson()
      ),
    ));

    if (response.statusCode != 200) {
      throw Exception("Failed to add ingredient (server returned ${response.statusCode})");
    }
  }

    static Future<void> updateIngredient(
      int id, Ingredient ingredient) async {

    final response = await _send(() => http.put(
      _uri("/ingredient/$id"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(
        ingredient.toJson()
      ),
    ));

    if (response.statusCode != 200) {
      throw Exception("Failed to update ingredient (server returned ${response.statusCode})");
    }
  }

    static Future<void> deleteIngredient(
      int id) async {

    final response = await _send(() => http.delete(_uri("/ingredient/$id")));

    if (response.statusCode != 200) {
      throw Exception("Failed to delete ingredient (server returned ${response.statusCode})");
    }

    // Mirror the delete to Supabase too -- otherwise the cloud row survives
    // and the next sync recreates it locally as a duplicate.
    await SupabaseService.deleteIngredient(id);
  }

  static Future<List<String>>
    getRecipes() async {

      final response = await _send(() => http.get(_uri("/recipes")));

      if (response.statusCode == 200) {
        List data =
            jsonDecode(response.body);

        return data
            .map<String>(
                (item) => item.toString())
            .toList();
      }

      throw Exception("Failed to load recipes (server returned ${response.statusCode})");
    }

    static Future<List<Map<String, dynamic>>>
        getRecipesDetailed() async {

      final response = await _send(() => http.get(_uri("/recipes")));

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data
            .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception("Failed to load recipes (server returned ${response.statusCode})");
    }

    static Future<String?> getAiRecommendation() async {
      final response = await _send(() => http.get(_uri("/ai-recommendation")));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data["recipe_name"] as String?;
      }

      throw Exception("Failed to load AI recommendation (server returned ${response.statusCode})");
    }

    static Future<List<Map<String, dynamic>>>
        getExpiryStatus() async {

      final response = await _send(() => http.get(_uri("/expiry-status")));

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data
            .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item))
            .toList();
      }

      throw Exception("Failed to load expiry status (server returned ${response.statusCode})");
    }
}
