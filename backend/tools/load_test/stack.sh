#!/bin/bash
# Start or stop the private load-test backend on ports 18970 (HTTP) and 18971 (realtime advertisement).
# usage: stack.sh start <load_db> | stack.sh stop
set -euo pipefail
W=/home/akm/Chatgpt/EOL_Game
RUN=${LOAD_SCRATCH:-$W/tmp/lc}
BIN=$RUN/bin
API_PORT=18970
REALTIME_PORT=18971
API_PID_FILE=$RUN/api.pid
WORKER_PID_FILE=$RUN/worker.pid

stop_process() {
  local file=$1
  if [ -f "$file" ]; then
    local pid
    pid=$(cat "$file")
    kill "$pid" 2>/dev/null || true
    for _ in $(seq 50); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.1
    done
    kill -9 "$pid" 2>/dev/null || true
    rm -f "$file"
  fi
}

if [ "${1:-}" = "stop" ]; then
  stop_process "$API_PID_FILE"
  stop_process "$WORKER_PID_FILE"
  echo "STACK stopped"
  exit 0
fi

DB=${2:?usage: stack.sh start <load_db>}
mkdir -p "$RUN/logs" "$RUN/private-media"
H=$W/tmp/test-databases/i853_dev
DSN="postgres://postgres@/${DB}?host=$H&port=55853"
ORIGIN=http://127.0.0.1:$API_PORT

stop_process "$API_PID_FILE"
stop_process "$WORKER_PID_FILE"

GXB_POSTGRES_DSN="$DSN" "$BIN/gxb-worker" > "$RUN/logs/worker.log" 2>&1 &
echo $! > "$WORKER_PID_FILE"

env GXB_POSTGRES_DSN="$DSN" GXB_HTTP_ADDR=127.0.0.1:$API_PORT \
  GXB_PUBLIC_ENGINE_URL=$ORIGIN/engine GXB_CLIENT_LOG_URL=$ORIGIN/client-log \
  GXB_REALTIME_PUBLIC_HOST=127.0.0.1 GXB_REALTIME_PUBLIC_PORT=$REALTIME_PORT \
  GXB_GAMEPLAY_BEARER_SECRET=gxb-load-bearer-key-000000000001 \
  GXB_REDEEM_DIGEST_SECRET=gxb-load-redeem-key-000000000001 \
  GXB_CREDENTIAL_DIGEST_SECRET=gxb-load-digest-key-000000000001 \
  GXB_DERIVATION_KEY_ID=load-native \
  GXB_COMBAT_ENTROPY_KEYS=load1=7663000000000000000000000000000000000000000000000000000000000001 \
  GXB_COMBAT_ENTROPY_KEY_CURRENT=load1 \
  GXB_COMBAT_WORKER_BINARY="$BIN/gxb-combat-worker" \
  "$BIN/gxb-api" > "$RUN/logs/api.log" 2>&1 &
echo $! > "$API_PID_FILE"

for _ in $(seq 600); do
  if curl -s -o /dev/null "$ORIGIN/client-log"; then
    echo "STACK ready $ORIGIN pid=$(cat "$API_PID_FILE")"
    exit 0
  fi
  sleep 0.2
done
echo "STACK failed to start; see $RUN/logs/api.log" >&2
exit 1
