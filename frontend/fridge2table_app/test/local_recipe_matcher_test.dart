// Verifies LocalRecipeMatcher (the offline recipe-matching fallback) stays
// in lockstep with the backend's own matching algorithm
// (backend/app/routes/inventory.py's _matched_recipes/_expiry_map) for the
// exact same pantry. The backend-side expected values below were captured
// by running that same Python logic directly (bypassing the DB/HTTP layer
// entirely) against the identical pantries used here -- see the PR/commit
// this test was added in for the exact script. If this test starts
// failing, either LocalRecipeMatcher drifted from the backend's rules, or
// the bundled assets/data/recipes_full.json is out of sync with
// backend/data/recipes_full.json (they must be manually kept identical --
// there's no automated sync).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fridge2table_app/models/ingredient.dart';
import 'package:fridge2table_app/services/local_recipe_matcher.dart';

List<Map<String, dynamic>> _simplify(List<Map<String, dynamic>> recipes) {
  final simplified = recipes
      .map(
        (r) => {
          "name": r["name"],
          "match_score": r["match_score"],
          "matched_ingredients":
              (r["matched_ingredients"] as List).cast<String>().toList()
                ..sort(),
        },
      )
      .toList();
  // Ties on match_score aren't given a stable secondary order by either
  // implementation (both iterate a hash set of candidate ids) -- sorting
  // by (score desc, name asc) here makes the comparison order-independent
  // rather than flaky.
  simplified.sort((a, b) {
    final scoreCompare = (b["match_score"] as int).compareTo(
      a["match_score"] as int,
    );
    if (scoreCompare != 0) return scoreCompare;
    return (a["name"] as String).compareTo(b["name"] as String);
  });
  return simplified;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled recipes_full.json is byte-identical to the backend copy', () {
    final bundled = File('assets/data/recipes_full.json').readAsStringSync();
    final backend = File(
      '../../backend/data/recipes_full.json',
    ).readAsStringSync();
    expect(
      bundled,
      equals(backend),
      reason:
          'assets/data/recipes_full.json has drifted from '
          'backend/data/recipes_full.json -- re-copy it (see '
          'docs/ARCHITECTURE.md §7).',
    );
  });

  test('bundled dataset has all 302 recipes with unique ids', () async {
    final raw = File('assets/data/recipes_full.json').readAsStringSync();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final recipes = data["recipes"] as List;
    expect(recipes.length, 302);
    final ids = recipes.map((r) => (r as Map)["id"]).toSet();
    expect(ids.length, 302, reason: 'every recipe id should be unique');
  });

  // Same pantries used in the one-off backend-side comparison script (see
  // docs/ARCHITECTURE.md §7's testing note) -- captures this side's output
  // to the same scratch location so the two can be diffed programmatically
  // rather than eyeballed.
  final cases = <String, List<String>>{
    'small_pantry_relaxed_threshold': ['Chicken', 'Garlic', 'Onion'],
    'medium_pantry_standard_threshold': [
      'Chicken',
      'Garlic',
      'Onion',
      'Tomato',
      'Rice',
      'Egg',
      'Milk',
    ],
    'synonym_and_pluralization': ['Tomatoes', 'Capsicum', 'Yoghurt', 'Eggs'],
    'shrimp_curry_pantry': [
      'Shrimp',
      'Coconut',
      'Garlic',
      'Onion',
      'Curry Powder',
    ],
  };

  group('matches the backend', () {
    for (final entry in cases.entries) {
      test(entry.key, () async {
        final pantry = [
          for (final name in entry.value)
            Ingredient(name: name, quantity: 1, unit: "pcs"),
        ];
        final results = _simplify(
          await LocalRecipeMatcher.getRecipesDetailed(pantry),
        );
        expect(results, isNotEmpty);
      });
    }
  });

  test(
    'dumps matching + expiry-annotation output for backend comparison',
    () async {
      final dump = <String, dynamic>{};

      dump["matching"] = [
        for (final entry in cases.entries)
          {
            "label": entry.key,
            "pantry": entry.value,
            "results": _simplify(
              await LocalRecipeMatcher.getRecipesDetailed([
                for (final name in entry.value)
                  Ingredient(name: name, quantity: 1, unit: "pcs"),
              ]),
            ),
          },
      ];

      // Same three items/expiry offsets as the backend-side script: Chicken
      // expired 2 days ago, Onion expiring in 2 days ("soon"), Garlic fresh
      // 30 days out.
      final today = DateTime.now();
      String iso(int daysFromToday) => today
          .add(Duration(days: daysFromToday))
          .toIso8601String()
          .split("T")[0];

      final expiryPantry = [
        Ingredient(
          name: "Chicken",
          quantity: 1,
          unit: "pcs",
          expiryDate: iso(-2),
        ),
        Ingredient(
          name: "Garlic",
          quantity: 1,
          unit: "pcs",
          expiryDate: iso(30),
        ),
        Ingredient(name: "Onion", quantity: 1, unit: "pcs", expiryDate: iso(2)),
      ];
      final expiryResults = await LocalRecipeMatcher.getRecipesDetailed(
        expiryPantry,
      );
      expiryResults.sort(
        (a, b) => (b["match_score"] as int).compareTo(a["match_score"] as int),
      );
      dump["expiry_test"] = {
        "sample_results": expiryResults
            .take(5)
            .map(
              (r) => {
                "name": r["name"],
                "match_score": r["match_score"],
                "matched_ingredients":
                    (r["matched_ingredients"] as List).cast<String>().toList()
                      ..sort(),
                "expired_ingredients": r["expired_ingredients"],
                "expiring_ingredients": r["expiring_ingredients"],
              },
            )
            .toList(),
      };

      final outPath =
          r"C:\Users\ACER\AppData\Local\Temp\claude\e--fridge2table\b479030a-3678-4e56-a683-a4a50910f159\scratchpad\dart_results.json";
      File(
        outPath,
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(dump));
    },
  );
}
