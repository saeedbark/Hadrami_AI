#!/usr/bin/env python3
"""Convert hadrami_dataset_final.csv to hadrami_dataset.json for the backend."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "data" / "hadrami_dataset_final.csv"
JSON_PATH = ROOT / "data" / "hadrami_dataset.json"

if len(sys.argv) >= 3:
    CSV_PATH = Path(sys.argv[1])
    JSON_PATH = Path(sys.argv[2])


def main():
    print(f"Reading:  {CSV_PATH.resolve()}")
    print(f"Writing:  {JSON_PATH.resolve()}")
    if not CSV_PATH.exists():
        print(f"ERROR: CSV file not found: {CSV_PATH}")
        sys.exit(1)
    entries = []
    with open(CSV_PATH, encoding="utf-8-sig") as f:
        raw = f.read()
    lines = raw.replace("\r\n", "\n").replace("\r", "\n").strip().split("\n")
    if not lines:
        print("CSV is empty")
        return
    # Skip header
    for line in lines[1:]:
        line = line.strip()
        if not line:
            continue
        parts = line.split(",", 3)
        if len(parts) < 4:
            continue
        try:
            id_val = int(parts[0].strip())
        except ValueError:
            continue
        hadrami = (parts[1] or "").strip()
        fus7a = (parts[2] or "").strip()
        definition = (parts[3] or "").strip()
        entries.append({
            "id": id_val,
            "hadrami_word": hadrami,
            "arabic_fus7a": fus7a,
            "full_definition": definition,
        })
    out = {"total": len(entries), "entries": entries}
    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print(f"OK: Wrote {len(entries)} entries to {JSON_PATH}")


if __name__ == "__main__":
    main()
