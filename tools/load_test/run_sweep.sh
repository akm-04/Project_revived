#!/bin/bash
# One fresh database, stack and player set per measured run. usage: run_sweep.sh [sizes] [ramp_seconds]
set -euo pipefail
W=/home/akm/Chatgpt/EOL_Game
DIR=$(dirname "$0")
SIZES=${SIZES:-50,200,500,1000}
RAMP=${RAMP:-0}
PY=/home/akm/Chatgpt/EOL_Game/.toolchain/bin/python3
SCRATCH=${LOAD_SCRATCH:-$W/tmp/lc}
RESULTS=$SCRATCH/results
mkdir -p "$RESULTS"

for n in ${SIZES//,/ }; do
  db=load_n$n
  players=$SCRATCH/players_$n.json
  out=$RESULTS/n${n}_ramp${RAMP}.json
  if [ -f "$out" ]; then
    echo "skip n=$n ramp=$RAMP (already measured)"
    continue
  fi
  rm -f "$players"
  bash "$DIR/fresh_load_db.sh" "$db"
  bash "$DIR/stack.sh" start "$db"
  "$PY" -B "$DIR/load_test.py" setup --database "$db" --players "$n" --players-file "$players"
  "$PY" -B "$DIR/load_test.py" run --database "$db" --players "$n" \
    --players-file "$players" --ramp-seconds "$RAMP" --login-mode prelogin \
    --login-concurrency 4 --out-file "$out"
  bash "$DIR/stack.sh" stop
done
echo "SWEEP complete"
