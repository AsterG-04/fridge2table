import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';
import 'user_scope.dart';

/// Local cache of the signed-in user's identity and preferences.
/// Supabase Auth is the source of truth for credentials — this only mirrors
/// display data (name/email) locally so Profile/Statistics work offline,
/// plus pantry-unrelated preferences (diet, allergies) that live purely on
/// this device.
///
/// Name/email/created-at are stored in flutter_secure_storage (they're
/// identity data tied to the auth session, even though not credentials
/// themselves). Diet preferences and allergies stay on plain
/// SharedPreferences — they're pantry profile settings, not sensitive, and
/// are scoped per Supabase user id so switching accounts on one device
/// doesn't leak one user's preferences into another's.
class AuthService {
  static const _kName = "auth_name";
  static const _kEmail = "auth_email";
  static const _kCreatedAt = "auth_created_at";
  static Future<String> get _kDietPreferences => UserScope.key("auth_diet_preferences");
  static Future<String> get _kAllergies => UserScope.key("auth_allergies");

  static Future<void> cacheIdentity({
    required String name,
    required String email,
  }) async {
    await secureStorage.write(key: _kName, value: name.trim());
    await secureStorage.write(key: _kEmail, value: email.trim().toLowerCase());
    if (await secureStorage.read(key: _kCreatedAt) == null) {
      await secureStorage.write(
        key: _kCreatedAt,
        value: DateTime.now().toIso8601String(),
      );
    }
  }

  static Future<void> saveDietPreferences(List<String> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(await _kDietPreferences, preferences);
  }

  static Future<void> saveAllergies(List<String> allergies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(await _kAllergies, allergies);
  }

  static Future<String?> getName() => secureStorage.read(key: _kName);

  static Future<String?> getEmail() => secureStorage.read(key: _kEmail);

  static Future<DateTime?> getCreatedAt() async {
    final iso = await secureStorage.read(key: _kCreatedAt);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  static Future<List<String>> getDietPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(await _kDietPreferences) ?? [];
  }

  static Future<List<String>> getAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(await _kAllergies) ?? [];
  }

  /// Clears the locally cached identity (name/email/created at) on logout.
  /// Diet preferences and allergies are left on disk under their scoped
  /// keys — they belong to whichever user set them and are picked back up
  /// automatically if that user signs back in.
  static Future<void> clearSession() async {
    await secureStorage.delete(key: _kName);
    await secureStorage.delete(key: _kEmail);
    await secureStorage.delete(key: _kCreatedAt);
  }
}
