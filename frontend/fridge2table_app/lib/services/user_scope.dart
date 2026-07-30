import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Namespaces SharedPreferences keys by the signed-in Supabase user, so
/// switching accounts on the same device doesn't leak one user's local
/// data (cooked history, saved recipes, diet/allergy prefs) into another's.
///
/// Falling back to a *shared* literal like "guest" when nobody's signed in
/// yet would be a real leak vector: if auth state ever reads as null for a
/// moment during startup (e.g. session restoration still in flight) on two
/// different accounts' devices/sessions, both would land in that exact
/// same bucket and could see each other's data. Instead the fallback is a
/// random id generated once per install and persisted locally — it can
/// only ever collide with itself.
class UserScope {
  static const _kInstallFallbackId = "user_scope_install_fallback_id";
  static String? _cachedFallbackId;

  static Future<String> get _fallbackId async {
    final cached = _cachedFallbackId;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_kInstallFallbackId);
    if (id == null) {
      id =
          "${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}";
      await prefs.setString(_kInstallFallbackId, id);
    }
    _cachedFallbackId = id;
    return id;
  }

  static Future<String> get _uid async {
    if (!SupabaseConfig.isConfigured) return "local";
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) return userId;
    return _fallbackId;
  }

  /// The same per-account (or per-install-fallback) id used to namespace
  /// SharedPreferences keys via [key] -- exposed directly for storage
  /// mechanisms that need to filter/scope rows by user themselves (e.g. a
  /// local SQLite table) rather than folding it into a single string key.
  static Future<String> get uid => _uid;

  static Future<String> key(String base) async => "${base}_${await _uid}";
}
