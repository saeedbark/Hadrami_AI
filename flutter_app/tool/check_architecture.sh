#!/usr/bin/env bash
# Enforces the dependency-direction rules from CLAUDE.md. These are invariants
# the Dart compiler cannot check: a violating import compiles, analyzes and
# tests clean, so without this script the architecture can only decay silently.
#
# Rules:
#   1. core/ must not import a module (composition root router.dart excepted).
#   2. Feature modules must not import each other; only modules/lexicon/
#      (the foundation domain module) may be imported across features.
#
# Run from flutter_app/:  bash tool/check_architecture.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

status=0

# --- Rule 1 -----------------------------------------------------------------
core_offenders=$(grep -rl "package:hadrami_nlp/src/modules/" lib/src/core \
  --include='*.dart' 2>/dev/null | grep -v 'routing/router.dart' || true)
if [ -n "$core_offenders" ]; then
  echo "✗ core/ must not depend on a feature module:"
  echo "$core_offenders" | sed 's/^/    /'
  status=1
fi

# --- Rule 2 -----------------------------------------------------------------
for dir in lib/src/modules/*/; do
  module=$(basename "$dir")
  # lexicon is the foundation: every feature may import it, so it must import
  # no module at all or the graph gains a cycle. Every other feature may import
  # lexicon, but never a sibling feature. Skipping lexicon here (as an earlier
  # version did) left the one rule that matters most unchecked.
  if [ "$module" = "lexicon" ]; then
    allowed="$module"
    label="foundation module 'lexicon' must not import any feature module:"
  else
    allowed="$module|lexicon"
    label="feature module '$module' must not import another feature module:"
  fi
  imported=$(grep -rh "package:hadrami_nlp/src/modules/" "$dir" \
    --include='*.dart' 2>/dev/null \
    | sed -E 's|.*modules/([a-z_]+)/.*|\1|' | sort -u \
    | grep -vxE "$allowed" || true)
  if [ -n "$imported" ]; then
    echo "✗ $label"
    echo "$imported" | sed "s/^/    $module -> /"
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "✓ architecture: dependency direction holds"
fi
exit "$status"
