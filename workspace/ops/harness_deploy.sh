#!/usr/bin/env bash
# Replaces the real-client test harness backend with the committed canonical backend. Default: snapshot, archive logs,
# stop, copy the commit, 'harness.py upgrade' (forward migrations only; the database, phone accounts and OTA releases
# survive) and 'harness.py up'. HARNESS_DEPLOY_WIPE=1 wipes the database and reseeds with seed.sh instead; that loses
# the owner's phone (product SDK) accounts. Run by ops/seal_passmap.sh after a seal; its failure never fails the seal.
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
"$python" -I -B "$harness/harness.py" snapshot "harness deploy $commit"
"$python" -I -B "$harness/helpers.py" archive
"$python" -I -B "$harness/harness.py" down
rm -rf "$harness/backend"
mkdir "$harness/backend"
git -C "$source_tree" archive "$commit" | tar -x -C "$harness/backend"
echo "$commit" > "$harness/backend/BACKEND_COMMIT"
if [ "${HARNESS_DEPLOY_WIPE:-0}" = 1 ]; then
  cat >&2 <<'WARNING'
HARNESS_DEPLOY_WIPE=1: this wipes the harness database. The owner's phone (product SDK) accounts are LOST; seed.sh only
re-creates the stand-in accounts. Recover them with:
  .toolchain/bin/python3 -B ops/reimport_legacy_players.py
      (re-aligns the preserved legacy players with the product accounts, once the harness is up)
  test_harness/runtime/bin/gxb-operator --root test_harness/runtime/agent backup restore <snapshot id>
      (restores the unpinned 'pre-redeploy' snapshot taken above; run 'backup list' to find its id)
WARNING
  "$python" -I -B "$harness/harness.py" reset "$harness/backend"
  "$python" -I -B "$harness/harness.py" up
  [ ! -f "$harness/seed.sh" ] || bash "$harness/seed.sh"
else
  "$python" -I -B "$harness/harness.py" upgrade "$harness/backend"
  "$python" -I -B "$harness/harness.py" up
fi
echo "HARNESS_DEPLOY_PASS $commit"
