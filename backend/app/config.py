import os

from dotenv import load_dotenv

load_dotenv()

OPENROUTER_API_KEY = os.environ.get("OPENROUTER_API_KEY", "").strip()
OPENROUTER_MODEL = "meta-llama/llama-3.3-70b-instruct:free"
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"

# Supabase Auth's shared HS256 signing secret, used to verify every
# incoming request actually comes from the user it claims to (see
# ../auth.py) -- Project Settings -> Data API / JWT Keys in the Supabase
# dashboard. Left blank in local dev is fine (auth.py fails closed with a
# 401 rather than silently trusting requests), but Render must have this
# set for the deployed API to accept any request at all.
SUPABASE_JWT_SECRET = os.environ.get("SUPABASE_JWT_SECRET", "").strip()
