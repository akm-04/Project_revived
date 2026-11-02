#!/usr/bin/env bash
# Import the three preserved v1 players after `harness.py up`. Fails loudly.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
harness="$root/test_harness"
python="$root/.toolchain/bin/python3"

"$python" -I -B "$harness/import_legacy.py" seed

for login in moppleton alpaca123 campaigner; do
  report="$harness/runtime/state/import_report_$login.json"
  test -s "$report" || { echo "seed: missing report $report" >&2; exit 1; }
  "$python" -I -B -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["player_id"] and "rows_written" in d and "content_refused" in d' "$report"
done

test -s "$harness/psk/accounts.txt" || { echo "seed: missing credentials" >&2; exit 1; }

"$python" -I -B "$harness/bots.py" create
"$python" -I -B "$harness/bots.py" enter
echo "SEED_PASS"
