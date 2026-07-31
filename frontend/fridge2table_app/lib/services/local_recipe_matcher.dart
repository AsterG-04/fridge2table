import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/ingredient.dart';

const _recipesAssetPath = 'assets/data/recipes_full.json';

/// A line-for-line Dart port of the backend's recipe-matching logic
/// (`backend/app/routes/inventory.py`), run against the bundled copy of
/// `recipes_full.json` (see that file's own header comment for how to keep
/// it in sync) instead of a live pantry query. Exists so `RecipeScreen` and
/// `HomeScreen` get the *same* matches offline as online, rather than a
/// noticeably different or degraded experience just because there's no
/// network -- the scoring/threshold constants and matching rules below are
/// deliberately kept identical to the backend's, not just "close enough".
///
/// Deliberately does not attempt the OpenRouter LLM re-rank (§/ai-recommendation
/// online) -- there's no local LLM, so offline always uses the same
/// deterministic top-match fallback the backend itself uses when
/// `OPENROUTER_API_KEY` isn't set.
class LocalRecipeMatcher {
  static List<Map<String, dynamic>>? _allRecipes;
  static Map<String, List<int>>? _recipeIndex;

  // Same alternate-spelling map as backend/app/routes/inventory.py's
  // _SYNONYMS, kept manually in sync -- see that file if the AI
  // classifier's class names or the recipe dataset's ingredient spellings
  // ever change.
  static const _synonyms = {
    "sweetpotato": "sweet potato",
    "yoghurt": "yogurt",
    "capsicum": "bell pepper",
    "raddish": "radish",
    "chilli pepper": "chili",
    "jalepeno": "chili",
    "corn": "sweetcorn",
    "oat milk": "milk",
    "sour milk": "milk",
    "soy milk": "milk",
    "sour cream": "cream",
    "satsuma": "orange",
  };

  static const _statusSeverity = {
    "expired": 3,
    "today": 2,
    "soon": 2,
    "fresh": 1,
    "unknown": 0,
  };

  // Same thresholds as backend/app/routes/inventory.py -- see that file's
  // own comment for why the match-count floor relaxes for small pantries.
  static const _minMatchScore = 20;
  static const _minMatchCount = 2;
  static const _smallPantryThreshold = 5;
  static const _smallPantryMinMatchCount = 1;
  static const recipesReturned = 25;

  static String _normalize(String word) {
    var w = word.trim().toLowerCase();
    if (_synonyms.containsKey(w)) w = _synonyms[w]!;
    if (w.endsWith("ies") && w.length > 4) {
      return "${w.substring(0, w.length - 3)}y";
    }
    if (w.endsWith("es") && w.length > 4) {
      return w.substring(0, w.length - 2);
    }
    if (w.endsWith("s") && w.length > 3) {
      return w.substring(0, w.length - 1);
    }
    return w;
  }

  static Future<void> _ensureLoaded() async {
    if (_allRecipes != null) return;

    final raw = await rootBundle.loadString(_recipesAssetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final recipes = (data["recipes"] as List)
        .map((r) => Map<String, dynamic>.from(r as Map))
        .toList();

    // Rebuilt from scratch here rather than trusting the JSON's own
    // on-disk "index" field, matching the backend's own reasoning
    // (routes/inventory.py) -- that field isn't guaranteed to have been
    // built with the same normalization this matcher uses.
    final index = <String, List<int>>{};
    for (var i = 0; i < recipes.length; i++) {
      final ingredients = (recipes[i]["ingredients"] as List).cast<String>();
      for (final ingredient in ingredients) {
        index.putIfAbsent(_normalize(ingredient), () => []).add(i);
      }
    }

    _allRecipes = recipes;
    _recipeIndex = index;
  }

  static Future<List<Map<String, dynamic>>> _matchedRecipes(
    List<String> ingredientNames,
  ) async {
    await _ensureLoaded();

    final userIngredients = ingredientNames.map(_normalize).toSet();
    if (userIngredients.isEmpty) return [];

    final minMatchCount = userIngredients.length < _smallPantryThreshold
        ? _smallPantryMinMatchCount
        : _minMatchCount;

    final candidateIds = <int>{};
    for (final ingredient in userIngredients) {
      final ids = _recipeIndex![ingredient];
      if (ids != null) candidateIds.addAll(ids);
    }

    final results = <Map<String, dynamic>>[];
    for (final idx in candidateIds) {
      final recipe = _allRecipes![idx];
      final recipeIngredients = (recipe["ingredients"] as List)
          .cast<String>()
          .map(_normalize)
          .toSet();
      final matches = userIngredients.intersection(recipeIngredients);
      if (matches.isEmpty) continue;

      final score = (matches.length / recipeIngredients.length * 100).round();
      if (score < _minMatchScore || matches.length < minMatchCount) continue;

      results.add({
        ...recipe,
        "match_score": score,
        "matched_ingredients": matches.toList(),
      });
    }

    // Secondary key (name, ascending) matches the backend's own tie-break
    // (backend/app/routes/inventory.py's _matched_recipes) -- without it,
    // which recipes among several tied on match_score land in the top
    // recipesReturned is arbitrary (candidateIds is a Set), which used to
    // mean online and offline results could differ at the cutoff boundary
    // for the exact same pantry even though every ranked-above-the-tie
    // result already matched exactly.
    results.sort((a, b) {
      final scoreCompare = (b["match_score"] as int).compareTo(
        a["match_score"] as int,
      );
      if (scoreCompare != 0) return scoreCompare;
      return (a["name"] as String).compareTo(b["name"] as String);
    });

    return results;
  }

  /// Same day-based classification as the backend's `_expiry_status_for`.
  static String expiryStatusFor(String? expiryDate, DateTime today) {
    if (expiryDate == null || expiryDate.isEmpty) return "unknown";

    final expiry = DateTime.tryParse(expiryDate);
    if (expiry == null) return "unknown";

    final daysLeft = DateTime(
      expiry.year,
      expiry.month,
      expiry.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;

    if (daysLeft < 0) return "expired";
    if (daysLeft == 0) return "today";
    if (daysLeft <= 3) return "soon";
    return "fresh";
  }

  static Map<String, String> _expiryMap(
    List<Ingredient> pantry,
    DateTime today,
  ) {
    final result = <String, String>{};
    for (final item in pantry) {
      final status = expiryStatusFor(item.expiryDate, today);
      final key = _normalize(item.name);
      final existing = result[key];
      if (existing == null ||
          _statusSeverity[status]! > _statusSeverity[existing]!) {
        result[key] = status;
      }
    }
    return result;
  }

  /// Offline equivalent of `GET /recipes` -- same shape (full recipe object
  /// plus match_score/matched_ingredients/expired_ingredients/
  /// expiring_ingredients) so `RecipeDetail.fromJson()` can consume either
  /// with no caller-visible difference.
  static Future<List<Map<String, dynamic>>> getRecipesDetailed(
    List<Ingredient> pantry,
  ) async {
    final names = pantry.map((i) => i.name).toList();
    final results = (await _matchedRecipes(
      names,
    )).take(recipesReturned).toList();

    final today = DateTime.now();
    final statusByName = _expiryMap(pantry, today);
    for (final recipe in results) {
      final matched = (recipe["matched_ingredients"] as List).cast<String>();
      recipe["expired_ingredients"] =
          matched.where((n) => statusByName[n] == "expired").toList()..sort();
      recipe["expiring_ingredients"] =
          matched
              .where(
                (n) => statusByName[n] == "today" || statusByName[n] == "soon",
              )
              .toList()
            ..sort();
    }

    return results;
  }

  /// Offline equivalent of `GET /ai-recommendation` -- always the
  /// deterministic top-match pick (`source: "fallback"`), matching what
  /// the backend itself returns whenever no OpenRouter key is configured;
  /// there's no local LLM to re-rank with.
  static Future<String?> getAiRecommendationName(
    List<Ingredient> pantry,
  ) async {
    final names = pantry.map((i) => i.name).toList();
    final allCandidates = await _matchedRecipes(names);
    if (allCandidates.isEmpty) return null;

    final today = DateTime.now();
    final expiringNames = pantry
        .where((i) {
          final status = expiryStatusFor(i.expiryDate, today);
          return status == "today" || status == "soon";
        })
        .map((i) => _normalize(i.name))
        .toSet();

    final expiringCandidates = allCandidates.where((c) {
      final matched = (c["matched_ingredients"] as List).cast<String>();
      return matched.any(expiringNames.contains);
    }).toList();

    final candidates = expiringCandidates.isNotEmpty
        ? expiringCandidates
        : allCandidates;

    return candidates.first["name"] as String?;
  }
}
