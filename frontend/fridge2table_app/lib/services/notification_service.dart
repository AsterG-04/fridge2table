import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';


class NotificationService {

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings: initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.requestNotificationsPermission();
  }

  static Future<void> checkAndNotify() async {

    final items = await ApiService.getExpiryStatus();

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
    }
  }
}
