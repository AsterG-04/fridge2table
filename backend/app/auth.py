import jwt
from fastapi import Header, HTTPException

from .config import SUPABASE_JWT_SECRET


def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    """Verifies the Supabase-issued JWT on every protected request and
    returns the authenticated user's id (the token's "sub" claim) -- the
    only source of truth for "who is this request from" now. A client-
    supplied user_id query parameter is no longer accepted anywhere (see
    routes/inventory.py) -- trusting that value let anyone who knew or
    guessed another user's id read or write their pantry.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401, detail="Missing or invalid Authorization header"
        )

    token = authorization.removeprefix("Bearer ").strip()

    if not SUPABASE_JWT_SECRET:
        # Fails closed rather than falling back to trusting an unverified
        # token -- an unset secret means this deployment simply can't
        # verify anyone yet, not that verification should be skipped.
        raise HTTPException(status_code=401, detail="Server auth is not configured")

    try:
        payload = jwt.decode(
            token,
            SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated",
        )
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token missing subject claim")

    return user_id
