import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CookedHistoryEntry {
  final String name;
  final String time;
  final int calories;
  final int timesCooked;
  final String lastCookedLabel;
  final String deductionSummary;

  const CookedHistoryEntry({
    required this.name,
    required this.time,
    required this.calories,
    required this.timesCooked,
    required this.lastCookedLabel,
    required this.deductionSummary,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "time": time,
        "calories": calories,
        "timesCooked": timesCooked,
        "lastCookedLabel": lastCookedLabel,
        "deductionSummary": deductionSummary,
      };

  factory CookedHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CookedHistoryEntry(
      name: json["name"] as String,
      time: json["time"] as String,
      calories: json["calories"] as int,
      timesCooked: json["timesCooked"] as int,
      lastCookedLabel: json["lastCookedLabel"] as String,
      deductionSummary: json["deductionSummary"] as String,
    );
  }
}

class CookedHistoryStore {
  static const _prefsKey = "cooked_history_entries";

  static List<CookedHistoryEntry>? _entries;

  static final List<CookedHistoryEntry> _seedEntries = [
    const CookedHistoryEntry(
      name: "Spinach Garlic Pasta",
      time: "22 min",
      calories: 410,
      timesCooked: 2,
      lastCookedLabel: "25 Jun",
      deductionSummary: "Cooked by estimate · 2 items skipped",
    ),
    const CookedHistoryEntry(
      name: "Tomato Egg Stir Fry",
      time: "12 min",
      calories: 240,
      timesCooked: 1,
      lastCookedLabel: "22 Jun",
      deductionSummary: "Cooked by measurement — full deduction",
    ),
    const CookedHistoryEntry(
      name: "Banana Pancakes",
      time: "20 min",
      calories: 320,
      timesCooked: 3,
      lastCookedLabel: "20 Jun",
      deductionSummary: "Cooked by estimate · 2 items skipped",
    ),
  ];

  /// Loads persisted history from disk on first call; subsequent calls
  /// return the already-loaded in-memory list.
  static Future<List<CookedHistoryEntry>> load() async {
    final loaded = _entries;
    if (loaded != null) return loaded;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);

    if (raw == null) {
      _entries = List.of(_seedEntries);
    } else {
      _entries = raw
          .map((s) => CookedHistoryEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    }

    return _entries!;
  }

  static Future<void> _persist() async {
    final entries = _entries;
    if (entries == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> recordCook({
    required String name,
    required String time,
    required int calories,
    required String deductionSummary,
  }) async {
    final entries = await load();

    final index = entries.indexWhere((e) => e.name == name);
    final today = DateTime.now();
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
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
        ),
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
      );
    }

    await _persist();
  }

  /// Synchronous access for widgets that have already awaited [load] once.
  static List<CookedHistoryEntry> get entries => _entries ?? _seedEntries;

  static int get totalMealsCooked =>
      entries.fold(0, (sum, e) => sum + e.timesCooked);

  static int get uniqueRecipes => entries.length;

  static int get totalCalories =>
      entries.fold(0, (sum, e) => sum + e.calories * e.timesCooked);
}
