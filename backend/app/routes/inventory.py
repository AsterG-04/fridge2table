from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date, datetime
import json
import os

import httpx

from ..config import OPENROUTER_API_KEY, OPENROUTER_MODEL, OPENROUTER_URL
from ..database import SessionLocal
from ..schemas import IngredientCreate, IngredientResponse
from ..crud import (
    create_ingredient,
    get_ingredients,
    update_ingredient,
    delete_ingredient
)

router = APIRouter()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


RECIPES_PATH = os.path.join(
    os.path.dirname(__file__),
    "..",
    "..",
    "data",
    "recipes_full.json"
)


# The AI ingredient classifier's class names don't always spell things the
# same way the recipe dataset does -- these would otherwise silently never
# match even when a relevant recipe exists (found while auditing recipe
# data quality: "sweetpotato" vs "sweet potato", "yoghurt" vs "yogurt",
# "capsicum" vs "bell pepper" -- same vegetable, different regional name).
_SYNONYMS = {
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
}


def _normalize(word: str) -> str:
    """Lowercases and lightly de-pluralizes an ingredient name so pantry
    entries like "Eggs" or "Tomatoes" match recipe ingredients like "egg"
    or "tomato" without needing an exact-plural match, and maps known
    alternate spellings (see _SYNONYMS) to one canonical form."""
    w = word.strip().lower()
    if w in _SYNONYMS:
        w = _SYNONYMS[w]
    if w.endswith("ies") and len(w) > 4:
        return w[:-3] + "y"
    if w.endswith("es") and len(w) > 4:
        return w[:-2]
    if w.endswith("s") and len(w) > 3:
        return w[:-1]
    return w


with open(RECIPES_PATH, "r", encoding="utf-8") as f:
    _data = json.load(f)
    ALL_RECIPES = _data["recipes"]

    # Rebuild the index over normalized ingredient names so lookups match
    # however the user actually typed the ingredient in their pantry.
    RECIPE_INDEX = {}
    for _i, _recipe in enumerate(ALL_RECIPES):
        for _ingredient in _recipe["ingredients"]:
            RECIPE_INDEX.setdefault(_normalize(_ingredient), []).append(_i)


@router.post("/ingredient", response_model=IngredientResponse)
def add_ingredient(
    ingredient: IngredientCreate,
    user_id: str,
    db: Session = Depends(get_db)
):
    return create_ingredient(db, ingredient, user_id)


@router.get("/inventory", response_model=list[IngredientResponse])
def get_inventory(
    user_id: str,
    db: Session = Depends(get_db)
):
    return get_ingredients(db, user_id)


def _expiry_status_for(expiry_date: str | None, today: date) -> str:
    """Same day-based classification used by /expiry-status, factored out so
    /ai-recommendation can identify expiring ingredients without a second
    round trip through that endpoint."""
    if not expiry_date:
        return "unknown"

    try:
        expiry = datetime.strptime(expiry_date, "%Y-%m-%d").date()
        days_left = (expiry - today).days

        if days_left < 0:
            return "expired"
        elif days_left == 0:
            return "today"
        elif days_left <= 3:
            return "soon"
        else:
            return "fresh"
    except ValueError:
        return "unknown"


@router.get("/expiry-status")
def get_expiry_status(
    user_id: str,
    db: Session = Depends(get_db)
):
    ingredients = get_ingredients(db, user_id)

    today = date.today()

    results = []

    for item in ingredients:

        status = _expiry_status_for(item.expiry_date, today)

        results.append({
            "id": item.id,
            "name": item.name,
            "quantity": item.quantity,
            "unit": item.unit,
            "category": item.category,
            "expiry_date": item.expiry_date,
            "status": status,
        })

    return results


@router.put("/ingredient/{ingredient_id}", response_model=IngredientResponse)
def edit_ingredient(
    ingredient_id: int,
    ingredient: IngredientCreate,
    user_id: str,
    db: Session = Depends(get_db)
):
    updated = update_ingredient(db, ingredient_id, ingredient, user_id)
    if not updated:
        raise HTTPException(status_code=404, detail="Ingredient not found")
    return updated


@router.delete("/ingredient/{ingredient_id}")
def remove_ingredient(
    ingredient_id: int,
    user_id: str,
    db: Session = Depends(get_db)
):
    deleted = delete_ingredient(db, ingredient_id, user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Ingredient not found")
    return deleted


# match_score is scaled by the *recipe's* ingredient count, so a small
# recipe (4-5 ingredients) can clear a percentage-only bar off a single
# shared generic ingredient like garlic or onion -- requiring at least 2
# actual matches alongside the percentage bar is what actually filters out
# "technically matches, not actually relevant" recommendations.
MIN_MATCH_SCORE = 20
MIN_MATCH_COUNT = 2

RECIPES_RETURNED = 25


def _matched_recipes(ingredient_names: list[str]):
    # Matching is exact-string equality on normalized (lowercased,
    # de-pluralized) names via set intersection -- not substring/fuzzy
    # matching, so e.g. "pea" cannot match inside "peanut".
    user_ingredients = set(_normalize(name) for name in ingredient_names)

    if not user_ingredients:
        return []

    candidate_ids = set()
    for ingredient in user_ingredients:
        if ingredient in RECIPE_INDEX:
            for idx in RECIPE_INDEX[ingredient]:
                candidate_ids.add(idx)

    results = []
    for idx in candidate_ids:
        recipe = ALL_RECIPES[idx]
        recipe_ingredients = set(_normalize(i) for i in recipe["ingredients"])
        matches = user_ingredients & recipe_ingredients

        if not matches:
            continue

        score = round(
            len(matches) / len(recipe_ingredients) * 100
        )

        if score < MIN_MATCH_SCORE or len(matches) < MIN_MATCH_COUNT:
            continue

        # Full recipe (steps, nutrition, cook_time, etc.) plus match info,
        # so Recipe Detail can render real data without a second lookup.
        results.append({
            **recipe,
            "match_score": score,
            "matched_ingredients": list(matches),
        })

    results.sort(
        key=lambda x: x["match_score"],
        reverse=True
    )

    return results


@router.get("/recipes")
def get_recipes(
    user_id: str,
    db: Session = Depends(get_db)
):
    ingredients = get_ingredients(db, user_id)
    results = _matched_recipes([item.name for item in ingredients])
    return results[:RECIPES_RETURNED]


@router.get("/ai-recommendation")
def get_ai_recommendation(
    user_id: str,
    db: Session = Depends(get_db)
):
    ingredients = get_ingredients(db, user_id)
    ingredient_names = [item.name for item in ingredients]

    all_candidates = _matched_recipes(ingredient_names)
    if not all_candidates:
        return {"recipe_name": None, "source": "none"}

    # Recipes that use an ingredient expiring today/soon take priority over
    # plain highest-match_score -- among those, match_score still decides
    # (all_candidates is already sorted by it). Falls back to the full
    # candidate list when nothing is actually expiring soon.
    today = date.today()
    expiring_names = {
        _normalize(item.name)
        for item in ingredients
        if _expiry_status_for(item.expiry_date, today) in ("today", "soon")
    }
    expiring_candidates = [
        c for c in all_candidates
        if expiring_names & set(c["matched_ingredients"])
    ]
    candidates = (expiring_candidates or all_candidates)[:10]

    if not OPENROUTER_API_KEY:
        return {"recipe_name": candidates[0]["name"], "source": "fallback"}

    recipe_names = [c["name"] for c in candidates]
    prompt = (
        f"Given these ingredients: {', '.join(ingredient_names)}, "
        f"suggest the best recipe name from this list: {', '.join(recipe_names)}. "
        "Reply with just the recipe name."
    )

    try:
        response = httpx.post(
            OPENROUTER_URL,
            headers={
                "Authorization": f"Bearer {OPENROUTER_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": OPENROUTER_MODEL,
                "messages": [{"role": "user", "content": prompt}],
            },
            timeout=10.0,
        )
        response.raise_for_status()
        reply = response.json()["choices"][0]["message"]["content"].strip().lower()

        # Match the model's free-text reply back to one of the candidate
        # names (case-insensitive) rather than trusting it verbatim.
        for name in recipe_names:
            if name.lower() in reply:
                return {"recipe_name": name, "source": "ai"}

        return {"recipe_name": candidates[0]["name"], "source": "fallback"}
    except Exception:
        return {"recipe_name": candidates[0]["name"], "source": "fallback"}