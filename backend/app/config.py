import os

from dotenv import load_dotenv

load_dotenv()

OPENROUTER_API_KEY = os.environ.get("OPENROUTER_API_KEY", "").strip()
OPENROUTER_MODEL = "meta-llama/llama-3.3-70b-instruct:free"
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"

# Supabase project URL -- used only to derive the JWKS endpoint that
# verifies every incoming request's JWT (see ../auth.py). Not sensitive:
# it's the same URL the frontend already embeds directly in
# lib/config/supabase_config.dart, so no Render env var is required for
# this to work -- unlike a shared secret, there's nothing here that needs
# to stay out of the repo. An env var override exists only in case this
# ever needs to point somewhere else (a different Supabase project) than
# the current one, e.g. multi-environment setups.
#
# Earlier this used a single shared SUPABASE_JWT_SECRET verified via
# HS256, on the assumption this project used Supabase's legacy shared-
# secret signing. That was wrong for this project: it actually signs
# tokens with ES256 (asymmetric, via Supabase's newer JWT Signing Keys
# system) -- confirmed by decoding a real token's header ("alg": "ES256")
# and cross-checking the project's own JWKS endpoint, which serves
# exactly one ES256/P-256 key. A shared secret can never verify an
# asymmetric signature, which is why every request was rejected with
# "Invalid or expired token" regardless of how fresh or genuinely valid
# the token was.
SUPABASE_URL = os.environ.get(
    "SUPABASE_URL", "https://xdwlhmuhqsndkimejlvi.supabase.co"
).strip()
SUPABASE_JWKS_URL = f"{SUPABASE_URL}/auth/v1/.well-known/jwks.json"
