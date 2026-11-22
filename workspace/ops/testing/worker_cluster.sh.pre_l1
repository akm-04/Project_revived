#!/bin/bash
# One private PostgreSQL cluster per worker task (ACCEPTANCE_V2_DESIGN.md section 7); clusters live under tmp/worker_clusters.
# usage: worker_cluster.sh start|env <name> | worker_cluster.sh stop [--remove] <name>
set -euo pipefail
W=/home/akm/Chatgpt/EOL_Game
WORKER_ROOT=${GXB_WORKER_CLUSTERS_ROOT:-$W/tmp/worker_clusters}
SEATS=${GXB_TEST_SEATS:-3}
SEAT_WAIT_SECONDS=${GXB_TEST_SEAT_WAIT_SECONDS:-1800}
SSI="-c max_pred_locks_per_transaction=1024 -c max_pred_locks_per_relation=512 -c max_pred_locks_per_page=8 -c shared_buffers=128MB"

usage() { echo "usage: worker_cluster.sh start|env <name> | worker_cluster.sh stop [--remove] <name>" >&2; exit 2; }

if [ $# -lt 2 ]; then usage; fi
COMMAND=$1
shift
REMOVE=
if [ "$COMMAND" = stop ] && [ "${1:-}" = --remove ]; then REMOVE=1; shift; fi
NAME=${1:-}
if ! [[ $NAME =~ ^[a-z0-9_]{1,32}$ ]]; then echo "worker_cluster: name must match [a-z0-9_]{1,32}" >&2; exit 2; fi

if [ -n "${GXB_PG_BIN:-}" ]; then
  PG_BIN=$GXB_PG_BIN
else
  . "$W/ops/testing/goenv.sh" > /dev/null
  PG_BIN=$(dirname "$(command -v pg_ctl)")
  cd "$W"
fi

DIRECTORY=$WORKER_ROOT/$NAME
# A Unix socket path is limited to 107 bytes; "/.s.PGSQL.56100" adds 15.
if [ $(( ${#DIRECTORY} + 15 )) -gt 107 ]; then echo "worker_cluster: $DIRECTORY is too long for a socket path" >&2; exit 2; fi
DATA=$DIRECTORY/data
PORT_FILE=$DIRECTORY/port
SEAT_FILE=$DIRECTORY/seat.pid

cluster_running() { [ -d "$DATA" ] && "$PG_BIN/pg_ctl" -D "$DATA" status > /dev/null 2>&1; }

print_environment() {
  if [ ! -f "$PORT_FILE" ]; then echo "worker_cluster: $NAME has no port file" >&2; exit 1; fi
  echo "export GXB_TEST_PGHOST=$DIRECTORY"
  echo "export GXB_TEST_PGPORT=$(cat "$PORT_FILE")"
}

socket_lock_holds_port() {
  local lock
  for lock in "$WORKER_ROOT"/*/".s.PGSQL.$1.lock" "$W"/tmp/test-databases/*/".s.PGSQL.$1.lock"; do
    if [ -e "$lock" ]; then return 0; fi
  done
  return 1
}

postmaster_holds_port() {
  local pid_file
  for pid_file in "$WORKER_ROOT"/*/data/postmaster.pid "$W"/tmp/test-databases/*/data/postmaster.pid; do
    if [ ! -f "$pid_file" ]; then continue; fi
    if [ "$(sed -n '4p' "$pid_file")" != "$1" ]; then continue; fi
    if "$PG_BIN/pg_ctl" -D "$(dirname "$pid_file")" status > /dev/null 2>&1; then return 0; fi
  done
  return 1
}

choose_port() {
  local port
  for port in $(seq 56100 56199); do
    if [ -e "$DIRECTORY/.s.PGSQL.$port.lock" ]; then continue; fi
    if socket_lock_holds_port "$port"; then continue; fi
    if postmaster_holds_port "$port"; then continue; fi
    echo "$port"
    return 0
  done
  echo "worker_cluster: no free port in 56100-56199" >&2
  return 1
}

SEAT_PID=
release_seat_on_exit() {
  if [ -n "$SEAT_PID" ]; then
    kill "$SEAT_PID" 2>/dev/null || true
    rm -f "$SEAT_FILE"
  fi
}
trap release_seat_on_exit EXIT

acquire_seat() {
  mkdir -p "$WORKER_ROOT/seats"
  local deadline=$((SECONDS + SEAT_WAIT_SECONDS)) seat number
  while :; do
    for number in $(seq 1 "$SEATS"); do
      seat=$WORKER_ROOT/seats/$number.lock
      exec 8>>"$seat"
      if flock -n 8; then
        # The forked sleeper inherits the locked open file description; closing ours keeps the seat held until it dies.
        sleep 2147483647 < /dev/null > /dev/null 2>&1 &
        SEAT_PID=$!
        exec 8>&-
        echo "$SEAT_PID" > "$SEAT_FILE"
        return 0
      fi
      exec 8>&-
    done
    if [ "$SECONDS" -ge "$deadline" ]; then
      echo "worker_cluster: no free seat (GXB_TEST_SEATS=$SEATS) after ${SEAT_WAIT_SECONDS}s" >&2
      return 1
    fi
    sleep 2
  done
}

start() {
  mkdir -p "$DIRECTORY"
  if cluster_running; then
    if [ ! -f "$SEAT_FILE" ] || ! kill -0 "$(cat "$SEAT_FILE")" 2>/dev/null; then
      acquire_seat
    fi
    SEAT_PID=
    print_environment
    return 0
  fi
  acquire_seat
  if [ ! -f "$DATA/PG_VERSION" ]; then
    mkdir -p "$DATA"
    "$PG_BIN/initdb" -D "$DATA" -U postgres -A trust > "$DIRECTORY/initdb.log"
  fi
  local port
  # One start at a time, so two workers cannot choose the same free port.
  exec 7>"$WORKER_ROOT/start.lock"
  flock 7
  port=$(choose_port)
  # 7>&-: the postmaster must not inherit the start lock, or it holds it for its whole life.
  "$PG_BIN/pg_ctl" -D "$DATA" -l "$DIRECTORY/server.log" -o "-p $port -k $DIRECTORY -c listen_addresses='' $SSI" -w start >&2 7>&-
  exec 7>&-
  echo "$port" > "$PORT_FILE"
  SEAT_PID=
  print_environment
}

stop() {
  if cluster_running; then
    "$PG_BIN/pg_ctl" -D "$DATA" -m fast -w stop >&2
  fi
  if [ -f "$SEAT_FILE" ]; then
    kill "$(cat "$SEAT_FILE")" 2>/dev/null || true
    rm -f "$SEAT_FILE"
  fi
  if [ -n "$REMOVE" ]; then rm -rf "$DIRECTORY"; fi
}

case "$COMMAND" in
  start) start ;;
  env) print_environment ;;
  stop) stop ;;
  *) usage ;;
esac
