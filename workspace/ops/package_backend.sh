#!/usr/bin/env bash
# Package the backend at its committed HEAD for seal generation <G> (ops/seal_passmap.sh runs it):
#   outputs/gxb-backend-v2-<version>-p<G>-<head7>-frozen-candidate.zip   clean `git archive HEAD` tree, no history
#   outputs/gxb-backend-v2-<version>-p<G>-<head7>-working-with-git.zip   the same tree plus the whole .git (all branches and history)
# each with a .sha256. Uncommitted and untracked files are never packaged. Both unzip to backend/.
# ops/state.py --write then points the inputs/backend symlinks at the newest pair.
# Usage: ops/package_backend.sh <generation>
set -euo pipefail
generation=$1
root=$(cd "$(dirname "$0")/.." && pwd)
backend=$root/work/backend_i7c4_full/backend
head=$(git -C "$backend" rev-parse --short=7 HEAD)
name=gxb-backend-v2-$(tr -d '[:space:]' < "$backend/VERSION")-p$generation-$head
staging=$root/tmp/package_backend_$generation
rm -rf "$staging" && mkdir -p "$staging/frozen" "$staging/working/backend"
git -C "$backend" archive --format=zip --prefix=backend/ -o "$staging/frozen/$name-frozen-candidate.zip" HEAD
cp -a "$backend/.git" "$staging/working/backend/.git"
git -C "$staging/working/backend" reset -q --hard HEAD
(cd "$staging/working" && zip -qr -X "$staging/frozen/$name-working-with-git.zip" backend)
for kind in frozen-candidate working-with-git; do
  unzip -tq "$staging/frozen/$name-$kind.zip" > /dev/null
  mv "$staging/frozen/$name-$kind.zip" "$root/outputs/"
  (cd "$root/outputs" && sha256sum "$name-$kind.zip" > "$name-$kind.sha256")
done
rm -rf "$staging"
echo "BACKEND_PACKAGED outputs/$name-{frozen-candidate,working-with-git}.zip"
