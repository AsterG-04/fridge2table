import 'package:shared_preferences/shared_preferences.dart';

import 'user_scope.dart';

/// Tracks which recipes the user has bookmarked, keyed by recipe name.
/// Persisted locally so the "Saved" filter on the Recipe screen survives
/// app restarts, mirroring the pattern used by CookedHistoryStore.
class SavedRecipesStore {
  static Future<String> get _prefsKey => UserScope.key("saved_recipe_names");

  static Set<String>? _saved;

  static Future<Set<String>> load() async {
    final cached = _saved;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    _saved = (prefs.getStringList(await _prefsKey) ?? []).toSet();
    return _saved!;
  }

  /// Clears the in-memory cache so the next [load] re-reads from whichever
  /// user's scoped storage is current — call this on logout.
  static void reset() {
    _saved = null;
  }

  /// Synchronous access for widgets that have already awaited [load] once.
  static Set<String> get saved => _saved ?? const {};

  static bool isSaved(String name) => saved.contains(name);

  static Future<void> toggle(String name) async {
    final set = await load();
    if (set.contains(name)) {
      set.remove(name);
    } else {
      set.add(name);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(await _prefsKey, set.toList());
  }
}
