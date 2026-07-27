"""Shared helpers for the eval scripts.

Adds ``backend/`` to ``sys.path`` so ``from app...`` works, picks the
backend venv site-packages when running with system python, and loads
``backend/.env`` for ``GEMINI_API_KEY`` / ``SUPABASE_*``.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
BACKEND_DIR = REPO_ROOT / "backend"
RESULTS_DIR = REPO_ROOT / "results"
FIXTURES_DIR = BACKEND_DIR / "tests" / "fixtures"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def setup_backend_path() -> None:
    """Make ``backend/`` importable + load .env. Idempotent."""
    if str(BACKEND_DIR) not in sys.path:
        sys.path.insert(0, str(BACKEND_DIR))
    # Pull in the venv site-packages if running on the system python.
    venv_lib = BACKEND_DIR / "venv" / "lib"
    if venv_lib.is_dir():
        for site_pkg in sorted(
            venv_lib.glob("python*/site-packages"), reverse=True
        ):
            if site_pkg.is_dir() and str(site_pkg) not in sys.path:
                sys.path.insert(0, str(site_pkg))
                break
    try:
        from dotenv import load_dotenv

        load_dotenv(BACKEND_DIR / ".env")
    except ImportError:
        pass


def load_fixture(name: str) -> dict[str, Any]:
    """Load a fixture JSON by stem from ``backend/tests/fixtures``."""
    candidates = [FIXTURES_DIR / f"{name}.json", FIXTURES_DIR / f"{name}.template.json"]
    for path in candidates:
        if path.exists():
            return json.loads(path.read_text(encoding="utf-8"))
    raise FileNotFoundError(
        f"Could not find fixture '{name}'. Looked in: "
        + ", ".join(str(c) for c in candidates)
    )


def write_results(name: str, payload: dict[str, Any]) -> Path:
    out = RESULTS_DIR / f"{name}.json"
    out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return out


def is_template(fixture: dict[str, Any]) -> bool:
    """Return True if the fixture is the placeholder shipped with the repo."""
    return "0.1-template" in str(fixture.get("version", ""))
