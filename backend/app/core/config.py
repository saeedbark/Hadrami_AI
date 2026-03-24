from pathlib import Path

APP_VERSION = "1.0.0"
APP_TITLE = "Hadrami Dialect NLP API"
APP_DESCRIPTION = "API for Hadrami Arabic dialect translation and search"

BASE_DIR = Path(__file__).resolve().parent.parent.parent
DATA_DIR = BASE_DIR / "data"
DATA_FILE = DATA_DIR / "hadrami_dataset.json"
FEEDBACK_FILE = DATA_DIR / "feedback.json"

DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100
