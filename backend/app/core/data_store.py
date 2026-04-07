import json
from typing import Any

from .config import DATA_FILE


def load_entries() -> list[dict[str, Any]]:
    if not DATA_FILE.exists():
        return []

    with open(DATA_FILE, encoding="utf-8") as file:
        payload = json.load(file)

    return payload.get("entries", [])


ENTRIES = load_entries()
