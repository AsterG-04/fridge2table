from sqlalchemy.orm import Session
from .models import Ingredient


def create_ingredient(db: Session, ingredient, user_id: str):
    if getattr(ingredient, "id", None) is not None:
        existing = db.query(Ingredient).filter(
            Ingredient.id == ingredient.id,
            Ingredient.user_id == user_id,
        ).first()
        if existing:
            existing.name = ingredient.name
            existing.quantity = ingredient.quantity
            existing.unit = ingredient.unit
            existing.expiry_date = ingredient.expiry_date
            existing.category = ingredient.category
            existing.location = ingredient.location
            existing.user_id = user_id
            if getattr(ingredient, "updated_at", None) is not None:
                existing.updated_at = ingredient.updated_at
            db.commit()
            db.refresh(existing)
            return existing

    db_item = Ingredient(
        name=ingredient.name,
        quantity=ingredient.quantity,
        unit=ingredient.unit,
        expiry_date=ingredient.expiry_date,
        category=ingredient.category,
        location=ingredient.location,
        user_id=user_id,
    )

    if getattr(ingredient, "id", None) is not None:
        db_item.id = ingredient.id
    if getattr(ingredient, "updated_at", None) is not None:
        db_item.updated_at = ingredient.updated_at

    db.add(db_item)
    db.commit()
    db.refresh(db_item)

    return db_item


def get_ingredients(db: Session, user_id: str):
    return db.query(Ingredient).filter(Ingredient.user_id == user_id).all()


def update_ingredient(db: Session, ingredient_id: int, ingredient, user_id: str):
    db_item = db.query(Ingredient).filter(
        Ingredient.id == ingredient_id,
        Ingredient.user_id == user_id,
    ).first()

    if not db_item:
        return None

    db_item.name = ingredient.name
    db_item.quantity = ingredient.quantity
    db_item.unit = ingredient.unit
    db_item.expiry_date = ingredient.expiry_date
    db_item.category = ingredient.category
    db_item.location = ingredient.location
    if getattr(ingredient, "updated_at", None) is not None:
        db_item.updated_at = ingredient.updated_at

    db.commit()
    db.refresh(db_item)

    return db_item


def delete_ingredient(db: Session, ingredient_id: int, user_id: str):
    db_item = db.query(Ingredient).filter(
        Ingredient.id == ingredient_id,
        Ingredient.user_id == user_id,
    ).first()

    if not db_item:
        return None

    db.delete(db_item)
    db.commit()

    return {"message": "Ingredient deleted"}
