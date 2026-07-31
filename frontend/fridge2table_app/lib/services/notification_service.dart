import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'app_settings_service.dart';
import 'user_scope.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Per-ingredient-id -> last date (YYYY-MM-DD) a notification was fired for
  // it, so re-running checkAndNotify() repeatedly (Home load, every
  // ingredient refresh, every app resume) doesn't re-fire the same
  // notification for the same still-expiring item more than once a day.
  static Future<String> get _historyKey =>
      UserScope.key("notification_history");

  /// Sets up the plugin (Android notification channel etc.) -- safe to call
  /// once at app startup. Does NOT request permission; that's a separate,
  /// user-facing step (see [requestPermission]) deliberately deferred until
  /// right after sign-in, not thrown at the user before they've even seen
  /// the app.
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Prompts the OS notification permission dialog (Android 13+ only --
  /// a no-op on older versions where notifications don't need explicit
  /// permission). Called right before landing on MainScreen from every
  /// sign-in/sign-up completion path, not at raw app startup.
  static Future<void> requestPermission() async {
    await initialize();
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
  }

  static Future<Map<String, String>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _historyKey);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveHistory(Map<String, String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _historyKey, jsonEncode(history));
  }

  /// Fires at most one OS notification per ingredient per calendar day.
  /// Called from multiple places (Home load, every ingredient-list
  /// refresh, every app resume) so it has to be safe to call often --
  /// the per-id/per-day history is what keeps that from becoming spam.
  static Future<void> checkAndNotify() async {
    try {
      if (!await AppSettingsService.getNotificationsEnabled()) return;
      // Startup no longer blocks on this (see main.dart) -- ensure it's
      // actually done before touching the plugin. Cheap/no-op if the
      // fire-and-forget call from main() already finished, which in
      // practice it almost always has by the time this runs.
      await initialize();

      final items = await ApiService.getExpiryStatus();
      final history = await _loadHistory();
      final today = DateTime.now().toIso8601String().split('T')[0];

      var changed = false;

      for (final item in items) {
        final status = item["status"];

        String? message;
        if (status == "expired") {
          message =
              "⚠️ ${item["name"]} has expired! Remove it from your pantry.";
        } else if (status == "today") {
          message = "🔴 ${item["name"]} expires TODAY — use it now!";
        } else if (status == "soon") {
          message = "🟡 ${item["name"]} is expiring soon — plan a recipe!";
        }

        if (message == null) continue;

        final id = item["id"].toString();
        if (history[id] == today) continue; // already notified today

        await _plugin.show(
          id: item["id"],
          title: "Fridge2Table",
          body: message,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'expiry_channel',
              'Expiry Alerts',
              channelDescription:
                  'Notifications for ingredients nearing or past expiry',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );

        history[id] = today;
        changed = true;
      }

      if (changed) await _saveHistory(history);
    } catch (error, stackTrace) {
      // Best-effort — called from several places that shouldn't fail their
      // own primary purpose (loading Home, refreshing the pantry list, app
      // resume) just because a notification check hit an error (offline,
      // not signed in yet, etc.).
      debugPrint(
        "[NotificationService] checkAndNotify() failed: $error\n$stackTrace",
      );
    }
  }
}
