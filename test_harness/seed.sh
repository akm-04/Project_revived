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

# Test supplies for every account: 2 Sorcery Scrolls, 5 Dodgeball tickets (misc dodge_ticket),
# and for intimacy (R13, R17) 100 of every Affinity gift (library_gift), Engagement Ring included.
gifts=""
for item in 50001112 50001113 50005011 50005012 50005013 50005014 50005015 50005016 50005017 50005018; do
  gifts="$gifts --item $item:100"
done
for login in $("$python" -I -B "$harness/helpers.py" players | cut -f1); do
  "$python" -I -B "$harness/helpers.py" give "$login" --currency occult_ticket:2 --item 50001979:5 $gifts >/dev/null
done
# R19: every elite stage cleared, for awakening drops.
"$python" -I -B "$harness/helpers.py" unlock-elite
echo "SEED_PASS"
