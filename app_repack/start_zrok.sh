#!/bin/bash
# zrok2 tunnels for a GXB backend. Every public name this project owns is listed here, so none gets lost.
#   gxbsdk       v1 SDK (port 5000)                  https://gxbsdk.shares.zrok.io
#   gxbengine    v1 engine (port 9000)               https://gxbengine.shares.zrok.io
#   gxbv2sdk     v2 test harness SDK (port 18955)    https://gxbv2sdk.shares.zrok.io
#   gxbv2engine  v2 test harness engine (port 18956) https://gxbv2engine.shares.zrok.io
# The v2 test harness starts and stops its own two tunnels (test_harness/harness.py). This script is for running them by hand or for v1.
# Each tunnel stops by its own pid file; other zrok2 processes are left alone.
# A name is created once with: zrok2 create name <name>
# Realtime chat (v2 port 18954, v1 port 9100) is raw TCP and cannot use a public share. Phones reach it on the LAN, which needs:
#   sudo firewall-cmd --permanent --add-port=18954/tcp && sudo firewall-cmd --reload
# usage: start_zrok.sh v1|v2|stop
set -u
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

start() {
  nohup zrok2 share public "localhost:$2" -n "public:$1" --headless > "$HERE/zrok_$1.log" 2>&1 &
  echo $! > "$HERE/zrok_$1.pid"
  echo "$1: https://$1.shares.zrok.io -> localhost:$2 (log: zrok_$1.log)"
}

stop_all() {
  for pid_file in "$HERE"/zrok_*.pid; do
    [ -f "$pid_file" ] || continue
    kill "$(cat "$pid_file")" 2>/dev/null
    rm -f "$pid_file"
  done
}

case "${1:-}" in
  v1) start gxbsdk 5000; start gxbengine 9000 ;;
  v2) start gxbv2sdk 18955; start gxbv2engine 18956 ;;
  stop) stop_all ;;
  *) echo "usage: $0 v1|v2|stop" >&2; exit 2 ;;
esac
