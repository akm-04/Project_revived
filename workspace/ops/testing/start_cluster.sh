#!/bin/bash
# Start the i853_dev test cluster on its own port and socket directory (TESTING_GUIDE.md section 0). A bare `pg_ctl -D <dir> start`
# starts it on 5432 with a /tmp socket and rewrites postmaster.opts (audit A-021).
set -euo pipefail
. /home/akm/Chatgpt/EOL_Game/ops/testing/goenv.sh > /dev/null
H=$W/tmp/test-databases/i853_dev
pg_ctl -D "$H/data" status > /dev/null 2>&1 && { echo "already running"; exit 0; }
# SSI lock budget (C1 Tier 0, C1_CAPACITY_DESIGN.md F3): the defaults escalate roster-sized reads to relation locks and abort
# unrelated players with 40001. Raising them needs a restart; ops/testing/ssi_escalation_probe.py checks the effect.
SSI="-c max_pred_locks_per_transaction=1024 -c max_pred_locks_per_relation=512 -c max_pred_locks_per_page=8"
pg_ctl -D "$H/data" -l "$H/server.log" -o "-p 55853 -k $H -c listen_addresses='' $SSI" -w start
