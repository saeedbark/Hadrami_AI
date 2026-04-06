import os
from pathlib import Path

APP_VERSION = "1.1.0"
APP_TITLE = "Hadrami Dialect NLP API"
APP_DESCRIPTION = "API for Hadrami Arabic dialect translation and search"

BASE_DIR = Path(__file__).resolve().parent.parent.parent
DATA_DIR = BASE_DIR / "data"
DATA_FILE = DATA_DIR / "hadrami_dataset.json"
FEEDBACK_FILE = DATA_DIR / "feedback.json"
EVAL_PAIRS_FILE = DATA_DIR / "eval_pairs.json"

DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100

PHRASE_TRANSLATE_MAX_CHARS = 3000
PHRASE_TRANSLATE_LONG_HINT_CHARS = 400
PHRASE_TRANSLATE_CHUNK_SIZE = 800
# Parallel Gemini calls for multi-chunk phrase translation (1 = sequential). Higher may hit API rate limits.
def _phrase_translate_max_workers() -> int:
    raw = (os.getenv("PHRASE_TRANSLATE_MAX_WORKERS") or "3").strip()
    try:
        v = int(raw)
    except ValueError:
        v = 3
    return max(1, min(8, v))


PHRASE_TRANSLATE_MAX_WORKERS = _phrase_translate_max_workers()
