import jwt
from fastapi import Header, HTTPException
from jwt import PyJWKClient

from .config import SUPABASE_JWKS_URL

# Created once at import time and reused across every request. cache_keys
# caches the fetched key set in-process instead of hitting Supabase's JWKS
# endpoint on every single request; lifespan (seconds) is how long that
# cache is trusted before a fresh fetch, and PyJWKClient also transparently
# refetches on a cache miss (e.g. a kid it doesn't recognize after a key
# rotation on Supabase's side), so a rotated key doesn't require a
# deploy/restart here to keep working.
_jwks_client = PyJWKClient(
    SUPABASE_JWKS_URL,
    cache_keys=True,
    lifespan=3600,
)


def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    """Verifies the Supabase-issued JWT on every protected request and
    returns the authenticated user's id (the token's "sub" claim) -- the
    only source of truth for "who is this request from" now. A client-
    supplied user_id query parameter is no longer accepted anywhere (see
    routes/inventory.py) -- trusting that value let anyone who knew or
    guessed another user's id read or write their pantry.

    Verification is against Supabase's own published public key (fetched
    from its JWKS endpoint), not a shared secret -- this project signs
    tokens with ES256 (asymmetric), confirmed by decoding a real token's
    header and cross-checking the project's JWKS endpoint, which serves
    exactly one ES256/P-256 key. A shared secret (the previous approach,
    SUPABASE_JWT_SECRET) can never verify an asymmetric signature, which
    is why every request was rejected as "invalid" even with a genuinely
    fresh, valid token.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401, detail="Missing or invalid Authorization header"
        )

    token = authorization.removeprefix("Bearer ").strip()

    try:
        signing_key = _jwks_client.get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["ES256"],
            audience="authenticated",
        )
    except jwt.PyJWTError as e:
        raise HTTPException(status_code=401, detail=f"Invalid or expired token: {e}")
    except Exception:
        # Covers JWKS-fetch failures (network blip, Supabase down) --
        # still a 401 rather than a 500, since the practical effect for
        # the caller is the same either way: this request can't be
        # verified as authenticated right now.
        raise HTTPException(
            status_code=401, detail="Could not verify token (JWKS unavailable)"
        )

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token missing subject claim")

    return user_id
