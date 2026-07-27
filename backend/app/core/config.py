import os
from pathlib import Path

# Resolve backend root and load .env before any os.getenv reads (cwd-independent).
BASE_DIR = Path(__file__).resolve().parent.parent.parent
try:
    from dotenv import load_dotenv

    load_dotenv(BASE_DIR / ".env")
except ImportError:
    pass

APP_VERSION = "2.0.0"
APP_TITLE = "Hadrami Dialect NLP API"
APP_DESCRIPTION = "API for Hadrami Arabic dialect translation and search"

DATA_DIR = BASE_DIR / "data"
DATA_FILE = DATA_DIR / "hadrami_dataset.json"
EVAL_PAIRS_FILE = DATA_DIR / "eval_pairs.json"

DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100

PHRASE_TRANSLATE_MAX_CHARS = 3000
PHRASE_TRANSLATE_LONG_HINT_CHARS = 400
PHRASE_TRANSLATE_CHUNK_SIZE = 800


def _ask_max_chars() -> int:
    """Max characters accepted for /ask questions (body or query string)."""
    raw = (os.getenv("ASK_MAX_CHARS") or "").strip()
    if raw:
        try:
            return max(256, min(int(raw), 16000))
        except ValueError:
            pass
    return PHRASE_TRANSLATE_MAX_CHARS


ASK_MAX_CHARS = _ask_max_chars()


def _phrase_translate_max_workers() -> int:
    raw = (os.getenv("PHRASE_TRANSLATE_MAX_WORKERS") or "3").strip()
    try:
        v = int(raw)
    except ValueError:
        v = 3
    return max(1, min(8, v))


PHRASE_TRANSLATE_MAX_WORKERS = _phrase_translate_max_workers()

# ---------------------------------------------------------------------------
# Supabase
# ---------------------------------------------------------------------------
SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY: str = os.getenv("SUPABASE_SERVICE_KEY", "")
SUPABASE_VERIFY_SSL: bool = os.getenv("SUPABASE_VERIFY_SSL", "true").lower() == "true"

