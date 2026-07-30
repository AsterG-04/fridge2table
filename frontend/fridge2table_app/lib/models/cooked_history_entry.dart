import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/user_scope.dart';

class CookedHistoryEntry {
  final String name;
  final String time;
  final int calories;
  final int timesCooked;
  final String lastCookedLabel;
  final String deductionSummary;

  /// The recipe's ingredient names as of when it was first cooked — used to
  /// derive real "most used categories" stats. Empty for entries persisted
  /// before this field existed.
  final List<String> ingredientNames;

  const CookedHistoryEntry({
    required this.name,
    required this.time,
    required this.calories,
    required this.timesCooked,
    required this.lastCookedLabel,
    required this.deductionSummary,
    this.ingredientNames = const [],
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "time": time,
    "calories": calories,
    "timesCooked": timesCooked,
    "lastCookedLabel": lastCookedLabel,
    "deductionSummary": deductionSummary,
    "ingredientNames": ingredientNames,
  };

  factory CookedHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CookedHistoryEntry(
      name: json["name"] as String,
      time: json["time"] as String,
      calories: json["calories"] as int,
      timesCooked: json["timesCooked"] as int,
      lastCookedLabel: json["lastCookedLabel"] as String,
      deductionSummary: json["deductionSummary"] as String,
      ingredientNames:
          (json["ingredientNames"] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class CookedHistoryStore {
  static Future<String> get _prefsKey =>
      UserScope.key("cooked_history_entries");

  static List<CookedHistoryEntry>? _entries;

  /// Loads persisted history from disk on first call; subsequent calls
  /// return the already-loaded in-memory list. A user with no cooking
  /// history yet correctly gets an empty list, not placeholder data.
  static Future<List<CookedHistoryEntry>> load() async {
    final loaded = _entries;
    if (loaded != null) {
      debugPrint(
        "[CookedHistoryStore] load(): returning cached in-memory list (${loaded.length} entries)",
      );
      return loaded;
    }

    final key = await _prefsKey;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(key);

    _entries = raw == null
        ? []
        : raw
              .map(
                (s) => CookedHistoryEntry.fromJson(
                  jsonDecode(s) as Map<String, dynamic>,
                ),
              )
              .toList();

    debugPrint(
      "[CookedHistoryStore] load(): read from disk under key=\"$key\" -> ${_entries!.length} entries",
    );
    return _entries!;
  }

  /// Clears the in-memory cache so the next [load] re-reads from whichever
  /// user's scoped storage is current — call this on logout.
  static void reset() {
    _entries = null;
  }

  static Future<void> _persist() async {
    final entries = _entries;
    if (entries == null) return;
    final key = await _prefsKey;
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setStringList(
      key,
      entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
    debugPrint(
      "[CookedHistoryStore] _persist(): wrote ${entries.length} entries under key=\"$key\" -> success=$ok",
    );
  }

  static Future<void> recordCook({
    required String name,
    required String time,
    required int calories,
    required String deductionSummary,
    List<String> ingredientNames = const [],
  }) async {
    debugPrint("[CookedHistoryStore] recordCook(name=\"$name\") called");
    final entries = await load();

    final index = entries.indexWhere((e) => e.name == name);
    final today = DateTime.now();
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final label = "${today.day} ${months[today.month - 1]}";

    if (index == -1) {
      entries.insert(
        0,
        CookedHistoryEntry(
          name: name,
          time: time,
          calories: calories,
          timesCooked: 1,
          lastCookedLabel: label,
          deductionSummary: deductionSummary,
          ingredientNames: ingredientNames,
        ),
      );
      debugPrint(
        "[CookedHistoryStore] recordCook(): inserted new entry for \"$name\" (timesCooked=1)",
      );
    } else {
      final existing = entries[index];
      entries[index] = CookedHistoryEntry(
        name: existing.name,
        time: existing.time,
        calories: existing.calories,
        timesCooked: existing.timesCooked + 1,
        lastCookedLabel: label,
        deductionSummary: deductionSummary,
        ingredientNames: existing.ingredientNames.isNotEmpty
            ? existing.ingredientNames
            : ingredientNames,
      );
      debugPrint(
        "[CookedHistoryStore] recordCook(): bumped existing entry for \"$name\" "
        "(timesCooked ${existing.timesCooked} -> ${existing.timesCooked + 1})",
      );
    }

    await _persist();
    debugPrint(
      "[CookedHistoryStore] recordCook() done — totalMealsCooked=$totalMealsCooked "
      "uniqueRecipes=$uniqueRecipes",
    );
  }

  /// Synchronous access for widgets that have already awaited [load] once.
  static List<CookedHistoryEntry> get entries => _entries ?? const [];

  static int get totalMealsCooked =>
      entries.fold(0, (sum, e) => sum + e.timesCooked);

  static int get uniqueRecipes => entries.length;

  static int get totalCalories =>
      entries.fold(0, (sum, e) => sum + e.calories * e.timesCooked);

  // The app doesn't track exact per-cook ingredient weights in history (only
  // Recipe Complete has that, per-session), so food saved is estimated from
  // how many times each recipe was cooked using this average.
  static const double _avgKgPerCook = 0.15;

  static double get totalFoodSavedKg => totalMealsCooked * _avgKgPerCook;

  /// A simple, transparent 0-100 score rather than a fabricated number: 8
  /// points per meal cooked, capped at 100 so a new account starts at 0.
  static int get ecoScore => (totalMealsCooked * 8).clamp(0, 100);

  /// Milestone badges, keyed by how many meals cooked unlocks each one.
  static const List<int> badgeThresholds = [1, 5, 10, 25];

  static int get badgeCount =>
      badgeThresholds.where((t) => totalMealsCooked >= t).length;

  // Same category vocabulary as the pantry (see inventory_screen.dart) —
  // recipe ingredient names aren't pre-tagged with a category the way
  // pantry items are, so this is a best-effort keyword match rather than an
  // authoritative lookup.
  static const Map<String, List<String>> _categoryTerms = {
    "Vegetables": [
      "tomato",
      "onion",
      "garlic",
      "carrot",
      "spinach",
      "broccoli",
      "lettuce",
      "pepper",
      "mushroom",
      "potato",
      "cucumber",
      "cabbage",
      "corn",
    ],
    "Meat & Seafood": [
      "chicken",
      "beef",
      "pork",
      "egg",
      "shrimp",
      "salmon",
      "tuna",
      "fish",
      "turkey",
      "lamb",
      "bacon",
      "sausage",
      "tofu",
    ],
    "Dairy": [
      "milk",
      "cheese",
      "butter",
      "cream",
      "yogurt",
      "yoghurt",
      "parmesan",
      "mozzarella",
    ],
    "Fruits": ["banana", "lemon", "apple", "berry", "orange", "lime", "mango"],
    "Grains & Bread": [
      "rice",
      "pasta",
      "noodle",
      "bread",
      "flour",
      "tortilla",
      "oats",
    ],
  };

  static String? _categorize(String ingredientName) {
    final n = ingredientName.toLowerCase();
    for (final entry in _categoryTerms.entries) {
      if (entry.value.any((term) => n.contains(term))) return entry.key;
    }
    return null;
  }

  /// Tally of cooked ingredients per pantry category, weighted by how many
  /// times each recipe was cooked. Empty until at least one recipe with
  /// recognized ingredients has been cooked.
  static Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final entry in entries) {
      for (final ingredientName in entry.ingredientNames) {
        final category = _categorize(ingredientName);
        if (category == null) continue;
        counts[category] = (counts[category] ?? 0) + entry.timesCooked;
      }
    }
    return counts;
  }
}
