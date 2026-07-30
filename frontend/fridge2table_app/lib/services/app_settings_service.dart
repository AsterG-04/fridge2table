import 'package:shared_preferences/shared_preferences.dart';

/// Small persisted device/app-level behavior toggles -- distinct from
/// AuthService's diet/allergy preferences (pantry profile data) and from
/// CookedHistoryStore/SavedRecipesStore (pantry usage data). These are
/// deliberately NOT scoped per-user (see UserScope) since they describe how
/// *this device* behaves (whether it shows notifications, when it backs
/// up), not something tied to a specific account's pantry.
class AppSettingsService {
  static const _kNotificationsEnabled = "settings_notifications_enabled";
  static const _kRecipeSuggestionsEnabled = "settings_recipe_suggestions_enabled";
  static const _kAutoBackupOnWifi = "settings_auto_backup_wifi";
  static const _kAutoBackupOnMobileData = "settings_auto_backup_mobile_data";
  static const _kBackgroundBackupEnabled = "settings_background_backup";

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotificationsEnabled) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, value);
  }

  static Future<bool> getRecipeSuggestionsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRecipeSuggestionsEnabled) ?? true;
  }

  static Future<void> setRecipeSuggestionsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRecipeSuggestionsEnabled, value);
  }

  static Future<bool> getAutoBackupOnWifi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoBackupOnWifi) ?? true;
  }

  static Future<void> setAutoBackupOnWifi(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoBackupOnWifi, value);
  }

  static Future<bool> getAutoBackupOnMobileData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoBackupOnMobileData) ?? false;
  }

  static Future<void> setAutoBackupOnMobileData(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoBackupOnMobileData, value);
  }

  static Future<bool> getBackgroundBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBackgroundBackupEnabled) ?? true;
  }

  static Future<void> setBackgroundBackupEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBackgroundBackupEnabled, value);
  }
}
