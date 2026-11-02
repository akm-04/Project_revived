#!/usr/bin/env bash
# Replaces the real-client test harness backend with the committed canonical backend: stop, wipe database and backend, copy, rebuild,
# seed players (test_harness/seed.sh), start. Run by ops/seal_passmap.sh after a seal; its failure never fails the seal.
# Keeps test_harness/runtime/state/secrets.json, so a client keeps working only by logging in again.
# usage: ops/harness_deploy.sh [commit, default the backend HEAD]
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
python=$root/.toolchain/bin/python3
harness=$root/test_harness
source_tree=$root/work/backend_i7c4_full/backend
commit=$(git -C "$source_tree" rev-parse "${1:-HEAD}")
exec 9> "$root/tmp/harness_deploy.lock"
flock -w 3600 9
"$python" -I -B "$harness/helpers.py" archive || echo "harness_deploy: log archive failed, continuing" >&2
"$python" -I -B "$harness/harness.py" down
rm -rf "$harness/backend"
mkdir "$harness/backend"
git -C "$source_tree" archive "$commit" | tar -x -C "$harness/backend"
echo "$commit" > "$harness/backend/BACKEND_COMMIT"
"$python" -I -B "$harness/harness.py" reset "$harness/backend"
"$python" -I -B "$harness/harness.py" up
[ ! -f "$harness/seed.sh" ] || bash "$harness/seed.sh"
echo "HARNESS_DEPLOY_PASS $commit"
