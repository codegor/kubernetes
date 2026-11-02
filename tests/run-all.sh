#!/usr/bin/env bash
# Runs every module-*/task-*/test.sh against the current cluster.
# Usage: tests/run-all.sh [filter]     e.g. tests/run-all.sh module-04
set -uo pipefail
cd "$(dirname "$0")/.."

FILTER=${1:-}
RESULTS=()
FAILED=0

for t in module-*/task-*/test.sh; do
  [[ -n "$FILTER" && "$t" != *"$FILTER"* ]] && continue
  start=$SECONDS
  if bash "$t"; then status=PASS; else status=FAIL; FAILED=1; fi
  RESULTS+=("$(printf '%-4s  %4ss  %s' "$status" "$((SECONDS - start))" "$(dirname "$t")")")
done

echo
echo "== Summary"
printf '  %s\n' "${RESULTS[@]}"
exit $FAILED
