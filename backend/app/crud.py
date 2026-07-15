from sqlalchemy.orm import Session
from .models import Ingredient


def create_ingredient(db: Session, ingredient):
    db_item = Ingredient(
        name=ingredient.name,
        quantity=ingredient.quantity,
        unit=ingredient.unit,
        expiry_date=ingredient.expiry_date,
        category=ingredient.category,
        location=ingredient.location
    )

    db.add(db_item)
    db.commit()
    db.refresh(db_item)

    return db_item


def get_ingredients(db: Session):
    return db.query(Ingredient).all()

def update_ingredient(db: Session, ingredient_id: int, ingredient):
    db_item = db.query(Ingredient).filter(
        Ingredient.id == ingredient_id
    ).first()

    if not db_item:
        return None

    db_item.name = ingredient.name
    db_item.quantity = ingredient.quantity
    db_item.unit = ingredient.unit
    db_item.expiry_date = ingredient.expiry_date
    db_item.category = ingredient.category
    db_item.location = ingredient.location

    db.commit()
    db.refresh(db_item)

    return db_item


def delete_ingredient(db: Session, ingredient_id: int):
    db_item = db.query(Ingredient).filter(
        Ingredient.id == ingredient_id
    ).first()

    if not db_item:
        return None

    db.delete(db_item)
    db.commit()

    return {"message": "Ingredient deleted"}