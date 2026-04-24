#!/usr/bin/env python3
"""Export hadrami_dataset.json to CSV and upsert rows into Supabase ``entries``.

Usage (from repo root):

    python scripts/json_to_csv_and_supabase.py
    backend\\venv\\Scripts\\python.exe scripts/json_to_csv_and_supabase.py

The script prepends ``backend/venv/.../site-packages`` when present so the
system ``python`` can still import ``supabase`` from the backend venv. If that
fails, use the venv interpreter or ``pip install supabase`` in your environment.

Requires in ``backend/.env``:

    SUPABASE_URL=https://<ref>.supabase.co
    SUPABASE_SERVICE_KEY=<service_role secret>

JSON array/object columns in the CSV are stored as single JSON strings per cell
(synonyms, phonetic_variants, examples, proverbs, tags). The Supabase upsert uses
native Python lists/dicts for those columns so PostgREST maps them to jsonb.
"""

from __future__ import annotations

import argparse
import base64
import csv
import json
import os
import platform
import sys
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
BACKEND_DIR = REPO_ROOT / "backend"
DATA_JSON = BACKEND_DIR / "data" / "hadrami_dataset.json"
DEFAULT_CSV = BACKEND_DIR / "data" / "hadrami_entries.csv"


def _prepend_venv_site_packages() -> None:
    """Allow running with system ``python`` while using deps from ``backend/venv``."""
    win_site = BACKEND_DIR / "venv" / "Lib" / "site-packages"
    if win_site.is_dir():
        p = str(win_site)
        if p not in sys.path:
            sys.path.insert(0, p)
        return
    lib = BACKEND_DIR / "venv" / "lib"
    if not lib.is_dir():
        return
    matches = sorted(lib.glob("python*/site-packages"), key=lambda x: str(x), reverse=True)
    for site_pkg in matches:
        if site_pkg.is_dir():
            p = str(site_pkg)
            if p not in sys.path:
                sys.path.insert(0, p)
            break


_prepend_venv_site_packages()
sys.path.insert(0, str(BACKEND_DIR))

try:
    from dotenv import load_dotenv

    load_dotenv(BACKEND_DIR / ".env")
except ImportError:
    pass

SUPABASE_URL = os.getenv("SUPABASE_URL", "").strip()
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "").strip()

TABLE = "entries"
BATCH_SIZE = 100

CSV_COLUMNS = [
    "id",
    "word_vocalized",
    "word_clean",
    "root",
    "pos",
    "fusha_equivalent",
    "definition",
    "region",
    "synonyms",
    "phonetic_variants",
    "note",
    "source",
    "examples",
    "proverbs",
    "tags",
]


def _load_dataset() -> list[dict[str, Any]]:
    if not DATA_JSON.exists():
        sys.exit(f"ERROR: Dataset not found: {DATA_JSON}")
    with open(DATA_JSON, encoding="utf-8") as f:
        payload = json.load(f)
    if isinstance(payload, list):
        return payload
    if isinstance(payload, dict):
        return payload.get("entries", [])
    sys.exit("ERROR: JSON must be a list or {\"entries\": [...]}")


def _dedupe_entries_by_id(entries: list[dict[str, Any]]) -> list[dict[str, Any]]:
    """One row per numeric ``id`` (last wins). Duplicate ids in one upsert batch break PostgreSQL ON CONFLICT."""
    by_id: dict[Any, dict[str, Any]] = {}
    without_id: list[dict[str, Any]] = []
    for e in entries:
        eid = e.get("id")
        if eid is None:
            without_id.append(e)
        else:
            by_id[eid] = e
    ordered = [by_id[k] for k in sorted(by_id.keys())]
    return ordered + without_id


def _json_cell(value: Any) -> str:
    if value is None:
        return "[]"
    if isinstance(value, (list, dict)):
        return json.dumps(value, ensure_ascii=False)
    return json.dumps(value, ensure_ascii=False)


def _row_for_csv(entry: dict[str, Any]) -> dict[str, str]:
    """Flat string row for CSV (JSON columns as JSON text)."""
    return {
        "id": str(entry.get("id", "")),
        "word_vocalized": entry.get("word_vocalized") or "",
        "word_clean": entry.get("word_clean") or "",
        "root": entry.get("root") or "",
        "pos": entry.get("pos") or "",
        "fusha_equivalent": entry.get("fusha_equivalent") or "",
        "definition": entry.get("definition") or "",
        "region": entry.get("region") or "General",
        "synonyms": _json_cell(entry.get("synonyms") or []),
        "phonetic_variants": _json_cell(entry.get("phonetic_variants") or []),
        "note": entry.get("note") or "",
        "source": entry.get("source") or "",
        "examples": _json_cell(entry.get("examples") or []),
        "proverbs": _json_cell(entry.get("proverbs") or []),
        "tags": _json_cell(entry.get("tags") or []),
    }


def _row_for_supabase(entry: dict[str, Any]) -> dict[str, Any]:
    """Row payload for PostgREST (jsonb as Python list/dict)."""
    def _list(v: Any) -> list:
        return v if isinstance(v, list) else []

    return {
        "id": entry["id"],
        "word_vocalized": entry.get("word_vocalized") or "",
        "word_clean": entry.get("word_clean"),
        "root": entry.get("root"),
        "pos": entry.get("pos"),
        "fusha_equivalent": entry.get("fusha_equivalent"),
        "definition": entry.get("definition"),
        "region": entry.get("region") or "General",
        "note": entry.get("note") or "",
        "source": entry.get("source") or "",
        "synonyms": _list(entry.get("synonyms")),
        "phonetic_variants": _list(entry.get("phonetic_variants")),
        "examples": _list(entry.get("examples")),
        "proverbs": _list(entry.get("proverbs")),
        "tags": _list(entry.get("tags")),
    }


def _jwt_role_from_supabase_key(key: str) -> str | None:
    """Return JWT ``role`` claim from a Supabase key (payload only, no verify)."""
    key = (key or "").strip()
    if not key or "." not in key:
        return None
    try:
        parts = key.split(".")
        payload_b64 = parts[1]
        pad = "=" * (-len(payload_b64) % 4)
        raw = base64.urlsafe_b64decode(payload_b64 + pad)
        data = json.loads(raw.decode("utf-8"))
        r = data.get("role")
        return str(r) if r is not None else None
    except Exception:
        return None


def write_csv(entries: list[dict[str, Any]], csv_path: Path) -> None:
    csv_path.parent.mkdir(parents=True, exist_ok=True)
    with open(csv_path, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=CSV_COLUMNS, extrasaction="ignore")
        w.writeheader()
        for e in entries:
            w.writerow(_row_for_csv(e))
    print(f"Wrote {len(entries)} rows to {csv_path}")


def upsert_supabase(entries: list[dict[str, Any]]) -> None:
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        sys.exit("ERROR: Set SUPABASE_URL and SUPABASE_SERVICE_KEY in backend/.env")

    jwt_role = _jwt_role_from_supabase_key(SUPABASE_SERVICE_KEY)
    if jwt_role != "service_role":
        sys.exit(
            "ERROR: SUPABASE_SERVICE_KEY must be the **service_role** secret from Supabase "
            "(Dashboard -> Project Settings -> API -> **service_role**), not the **anon** key.\n"
            f"Decoded JWT role is {jwt_role!r}; with role 'anon', Row Level Security blocks INSERT/UPDATE.\n"
            "Paste the long service_role JWT into backend/.env as SUPABASE_SERVICE_KEY, then re-run."
        )

    try:
        from supabase import create_client
    except ImportError as exc:
        is_win = platform.system() == "Windows"
        venv_py = (
            BACKEND_DIR / "venv" / "Scripts" / "python.exe"
            if is_win
            else BACKEND_DIR / "venv" / "bin" / "python3"
        )
        sys.exit(
            "ERROR: The 'supabase' package is not importable.\n"
            "  Fix: use the backend venv Python, e.g.\n"
            f"    {venv_py} scripts/json_to_csv_and_supabase.py\n"
            "  Or: pip install supabase (in this environment).\n"
            f"  Original error: {exc}"
        )

    client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    total = 0
    for i in range(0, len(entries), BATCH_SIZE):
        batch = [_row_for_supabase(e) for e in entries[i : i + BATCH_SIZE]]
        client.table(TABLE).upsert(batch, on_conflict="id").execute()
        total += len(batch)
        print(f"  Upserted {total}/{len(entries)} into {TABLE}")
    print("Supabase upsert complete.")


def main() -> None:
    p = argparse.ArgumentParser(description="JSON -> CSV + Supabase entries upsert")
    p.add_argument(
        "--csv",
        type=Path,
        default=DEFAULT_CSV,
        help=f"Output CSV path (default: {DEFAULT_CSV})",
    )
    p.add_argument("--skip-csv", action="store_true", help="Only upsert to Supabase")
    p.add_argument("--skip-supabase", action="store_true", help="Only write CSV")
    args = p.parse_args()

    entries = _load_dataset()
    print(f"Loaded {len(entries)} entries from {DATA_JSON.name}")
    n_raw = len(entries)
    entries = _dedupe_entries_by_id(entries)
    if len(entries) < n_raw:
        print(
            f"Warning: deduplicated by id ({n_raw} -> {len(entries)} rows); "
            "last occurrence kept per id."
        )

    if not args.skip_csv:
        write_csv(entries, args.csv.resolve())

    if not args.skip_supabase:
        upsert_supabase(entries)


if __name__ == "__main__":
    main()
