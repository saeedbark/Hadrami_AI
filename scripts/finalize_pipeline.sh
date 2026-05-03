#!/usr/bin/env bash
# Run after both validate_pos.py and generate_enrichment.py finish.
# 1. Apply auto-collapse POS corrections.
# 2. Re-audit the cleaned table.
# 3. Re-export Kaggle / HuggingFace bundles with the v2 schema.
set -euo pipefail

cd "$(dirname "$0")/.."

PY="backend/venv/bin/python"

echo "=== 1/4 apply POS corrections (auto-collapse) ==="
$PY scripts/apply_pos_corrections.py --apply 2>&1 | tail -50 || true

echo
echo "=== 2/4 re-audit ==="
$PY scripts/eval/audit_lexicon.py 2>&1 | tail -40

echo
echo "=== 3/4 re-export Kaggle bundle ==="
$PY scripts/export/to_kaggle.py 2>&1 | tail -10

echo
echo "=== 4/4 re-export HuggingFace bundle ==="
$PY scripts/export/to_huggingface.py 2>&1 | tail -10

echo
echo "DONE — full v2 pipeline applied."
