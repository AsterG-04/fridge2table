import 'package:shared_preferences/shared_preferences.dart';

/// Local cache of the signed-in user's identity and preferences.
/// Supabase Auth is the source of truth for credentials — this only mirrors
/// display data (name/email) locally so Profile/Statistics work offline,
/// plus pantry-unrelated preferences (diet, allergies) that live purely on
/// this device.
class AuthService {
  static const _kName = "auth_name";
  static const _kEmail = "auth_email";
  static const _kCreatedAt = "auth_created_at";
  static const _kDietPreferences = "auth_diet_preferences";
  static const _kAllergies = "auth_allergies";

  static Future<void> cacheIdentity({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, name.trim());
    await prefs.setString(_kEmail, email.trim().toLowerCase());
    if (!prefs.containsKey(_kCreatedAt)) {
      await prefs.setString(_kCreatedAt, DateTime.now().toIso8601String());
    }
  }

  static Future<void> saveDietPreferences(List<String> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kDietPreferences, preferences);
  }

  static Future<void> saveAllergies(List<String> allergies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kAllergies, allergies);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kName);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kEmail);
  }

  static Future<DateTime?> getCreatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_kCreatedAt);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  static Future<List<String>> getDietPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kDietPreferences) ?? [];
  }

  static Future<List<String>> getAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kAllergies) ?? [];
  }

  /// Clears the locally cached identity (name/email/created at) on logout.
  /// Diet preferences and allergies are left in place — they're pantry
  /// profile settings, not auth session state, and this app doesn't
  /// support switching between multiple local accounts.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kCreatedAt);
  }
}
