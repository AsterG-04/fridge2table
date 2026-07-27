import 'package:shared_preferences/shared_preferences.dart';

import 'user_scope.dart';

/// Records ingredient ids the user has deliberately deleted locally, so
/// cloud sync can tell "genuinely new cloud-only item" apart from "item I
/// deleted whose cloud mirror-delete never landed." Without this,
/// resolveConflicts()/syncFromCloud() see a cloud row with no local
/// counterpart and can only assume it's new -- silently resurrecting a
/// deleted ingredient on the next sync (e.g. the very next app launch,
/// since MainScreen kicks off a resync on every start).
class DeleteTombstones {
  static Future<String> get _key async =>
      UserScope.key("deleted_ingredient_ids");

  static Future<Set<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(await _key) ?? [];
    return stored.map(int.parse).toSet();
  }

  static Future<void> add(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key;
    final ids = (prefs.getStringList(key) ?? []).toSet();
    ids.add(id.toString());
    await prefs.setStringList(key, ids.toList());
  }

  static Future<void> remove(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _key;
    final ids = (prefs.getStringList(key) ?? []).toSet();
    ids.remove(id.toString());
    await prefs.setStringList(key, ids.toList());
  }
}
