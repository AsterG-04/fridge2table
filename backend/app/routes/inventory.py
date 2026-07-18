from fastapi import APIRouter, Depends
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


def _normalize(word: str) -> str:
    """Lowercases and lightly de-pluralizes an ingredient name so pantry
    entries like "Eggs" or "Tomatoes" match recipe ingredients like "egg"
    or "tomato" without needing an exact-plural match."""
    w = word.strip().lower()
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
    db: Session = Depends(get_db)
):
    return create_ingredient(db, ingredient)


@router.get("/inventory", response_model=list[IngredientResponse])
def get_inventory(
    db: Session = Depends(get_db)
):
    return get_ingredients(db)


@router.get("/expiry-status")
def get_expiry_status(
    db: Session = Depends(get_db)
):
    ingredients = get_ingredients(db)

    today = date.today()

    results = []

    for item in ingredients:

        status = "unknown"

        if item.expiry_date:

            try:
                expiry = datetime.strptime(
                    item.expiry_date, "%Y-%m-%d"
                ).date()

                days_left = (expiry - today).days

                if days_left < 0:
                    status = "expired"
                elif days_left == 0:
                    status = "today"
                elif days_left <= 3:
                    status = "soon"
                else:
                    status = "fresh"

            except ValueError:
                status = "unknown"

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
    db: Session = Depends(get_db)
):
    return update_ingredient(db, ingredient_id, ingredient)


@router.delete("/ingredient/{ingredient_id}")
def remove_ingredient(
    ingredient_id: int,
    db: Session = Depends(get_db)
):
    return delete_ingredient(db, ingredient_id)


def _matched_recipes(ingredient_names: list[str]):
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
    db: Session = Depends(get_db)
):
    ingredients = get_ingredients(db)
    results = _matched_recipes([item.name for item in ingredients])
    return results[:5]


@router.get("/ai-recommendation")
def get_ai_recommendation(
    db: Session = Depends(get_db)
):
    ingredients = get_ingredients(db)
    ingredient_names = [item.name for item in ingredients]

    candidates = _matched_recipes(ingredient_names)[:10]
    if not candidates:
        return {"recipe_name": None, "source": "none"}

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