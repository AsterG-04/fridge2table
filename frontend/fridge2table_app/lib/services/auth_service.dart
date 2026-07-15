import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _kName = "auth_name";
  static const _kEmail = "auth_email";
  static const _kPasswordHash = "auth_password_hash";
  static const _kCreatedAt = "auth_created_at";
  static const _kDietPreferences = "auth_diet_preferences";
  static const _kAllergies = "auth_allergies";

  static String _hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static Future<void> saveAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, name.trim());
    await prefs.setString(_kEmail, email.trim().toLowerCase());
    await prefs.setString(_kPasswordHash, _hash(password));
    if (!prefs.containsKey(_kCreatedAt)) {
      await prefs.setString(_kCreatedAt, DateTime.now().toIso8601String());
    }
  }

  static Future<bool> checkCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_kEmail);
    final savedHash = prefs.getString(_kPasswordHash);
    if (savedEmail == null || savedHash == null) return false;
    return savedEmail == email.trim().toLowerCase() && savedHash == _hash(password);
  }

  static Future<bool> hasAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kEmail);
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
}
