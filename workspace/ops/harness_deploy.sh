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
# Seal 800 replaced a newer i9-12 harness with the older canonical tree, wiped the playtester's account and broke the import.
deployed=$(cat "$harness/backend/BACKEND_COMMIT" 2>/dev/null || true)
if [ -n "$deployed" ] && [ "${HARNESS_DEPLOY_FORCE:-0}" != 1 ] && ! git -C "$source_tree" merge-base --is-ancestor "$deployed" "$commit"; then
  echo "HARNESS_DEPLOY_SKIP: deployed $deployed is not an ancestor of $commit (set HARNESS_DEPLOY_FORCE=1 to go back)" >&2
  exit 0
fi
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
