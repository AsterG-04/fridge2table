import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared FlutterSecureStorage instance for anything genuinely sensitive:
/// the Supabase session (a live access/refresh token pair — whoever holds
/// it can act as the signed-in user against Supabase and, indirectly, this
/// app's backend), the PKCE code verifier used mid-OAuth-flow, and the
/// cached identity (email in particular). Diet/allergy prefs, cooked
/// history, and saved-recipe bookmarks are NOT sensitive and deliberately
/// stay on plain SharedPreferences (see AuthService, CookedHistoryStore,
/// SavedRecipesStore).
const secureStorage = FlutterSecureStorage();

/// Persists the Supabase session (access/refresh tokens) in secure storage
/// instead of supabase_flutter's SharedPreferences-backed default.
class SecureSupabaseLocalStorage extends LocalStorage {
  const SecureSupabaseLocalStorage();

  static const _key = "sb_session";

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      (await secureStorage.read(key: _key)) != null;

  @override
  Future<String?> accessToken() => secureStorage.read(key: _key);

  @override
  Future<void> removePersistedSession() => secureStorage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      secureStorage.write(key: _key, value: persistSessionString);
}

/// Persists the PKCE code verifier (used mid-OAuth-flow, between launching
/// the browser and the deep-link redirect completing) in secure storage
/// instead of the SharedPreferences-backed default.
class SecureSupabasePkceStorage extends GotrueAsyncStorage {
  const SecureSupabasePkceStorage();

  @override
  Future<String?> getItem({required String key}) =>
      secureStorage.read(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      secureStorage.write(key: key, value: value);

  @override
  Future<void> removeItem({required String key}) =>
      secureStorage.delete(key: key);
}
