"""
Backfills each recipe's "step_timers" field by extracting explicit
durations ("bake for 15-18 minutes", "simmer for 25 minutes", "1.5-2
hours") straight out of its own step instruction text via regex.

Why this exists: the cooking-timer UI (CookingModeScreen) has always
worked correctly, but only shows a countdown for a step when the
recipe's own data provides step_timers -- and as of this backfill, only
4 of 302 recipes had that field at all, so in practice almost nobody
cooking a recipe ever saw a timer. This isn't a UI bug; it's a data
coverage gap, closed here by mining the (frequently very explicit)
step text that was already there.

A step keeps step_timers[i] = null when no duration is mentioned (most
steps, e.g. "Whisk the eggs") -- that's correct, not a gap to fill.
For a range ("15-18 minutes") the two bounds are averaged and rounded;
hours are converted to minutes first. Recipes that already have
step_timers are left untouched, so this is safe to re-run after adding
new recipes without a duration annotation of their own.

Run: venv/Scripts/python.exe scripts/backfill_step_timers.py
"""

import json
import os
import re

RECIPES_PATH = os.path.join(
    os.path.dirname(__file__), "..", "data", "recipes_full.json"
)

_DURATION_RE = re.compile(
    r"(\d+(?:\.\d+)?)\s*(?:-|to)?\s*(\d+(?:\.\d+)?)?\s*(minutes?|mins?|hours?|hrs?)",
    re.IGNORECASE,
)


def _extract_minutes(step_text: str) -> int | None:
    match = _DURATION_RE.search(step_text)
    if not match:
        return None

    low = float(match.group(1))
    high = float(match.group(2)) if match.group(2) else low
    unit = match.group(3).lower()

    average = (low + high) / 2
    if unit.startswith("h"):
        average *= 60

    return max(1, round(average))


def main():
    with open(RECIPES_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    recipes = data["recipes"]
    backfilled = 0
    steps_tagged = 0
    already_had_it = 0

    for recipe in recipes:
        if "step_timers" in recipe:
            already_had_it += 1
            continue

        timers = [_extract_minutes(step) for step in recipe["steps"]]
        if not any(t is not None for t in timers):
            continue

        recipe["step_timers"] = timers
        backfilled += 1
        steps_tagged += sum(1 for t in timers if t is not None)

    with open(RECIPES_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"Recipes already annotated: {already_had_it}")
    print(f"Recipes backfilled: {backfilled}")
    print(f"Individual steps tagged with a timer: {steps_tagged}")
    print(
        f"Recipes with no detectable duration in any step: "
        f"{len(recipes) - already_had_it - backfilled}"
    )


if __name__ == "__main__":
    main()
