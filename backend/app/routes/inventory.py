from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import date, datetime
import json
import os

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


INDEX_PATH = os.path.join(
    os.path.dirname(__file__),
    "..",
    "..",
    "recipes_index.json"
)

with open(INDEX_PATH, "r") as f:
    _data = json.load(f)
    ALL_RECIPES = _data["recipes"]
    RECIPE_INDEX = _data["index"]


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


@router.get("/recipes")
def get_recipes(
    db: Session = Depends(get_db)
):
    ingredients = get_ingredients(db)

    user_ingredients = set(
        item.name.lower()
        for item in ingredients
    )

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
        recipe_ingredients = set(recipe["ingredients"])
        matches = user_ingredients & recipe_ingredients

        if not matches:
            continue

        score = round(
            len(matches) / len(recipe_ingredients) * 100
        )

        results.append({
            "name": recipe["name"],
            "match_score": score,
            "matched_ingredients": list(matches),
            "prep_time": recipe.get("prep_time", "20 min"),
            "difficulty": recipe.get("difficulty", "Easy"),
            "diet_tags": recipe.get("diet_tags", ["Healthy"]),
        })

    results.sort(
        key=lambda x: x["match_score"],
        reverse=True
    )

    return results[:5]