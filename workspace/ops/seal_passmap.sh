#!/usr/bin/env bash
# Seal PassMap v2 generation <N> in one step. Agents never edit hot/ by hand: they write phase inputs and this script applies them.
#   1. work/authority_p<N> is created from the previous sealed v2 authority (hot copied, cold hard-linked) unless it already exists
#      (the one-time v1 -> v2 migration builds 764 itself);
#   2. passmap_maintain.py sync applies <phase workspace>/passmap/inputs and regenerates ENTRY.md, ROUTES.json and the generated records;
#   3. check (the seal guard) must be green; package writes outputs/gxb-backend-pass-<N>.0-passmap.zip, restores it into a scratch
#      directory, compares it byte for byte and re-runs the guard on the restored copy;
#   4. ops/package_backend.sh zips the committed backend HEAD into outputs/ (frozen candidate and working copy with Git);
#      ops/package_virtualclient.sh writes the virtual client kit into inputs/tools/ (replacing the previous kit); ops/ is mirrored
#      to inputs/ops_mirror (a checkpoint restore needs ops/checkpoint_archive.py);
#   5. ops/state.py --write then --check (WORKSPACE_LAYOUT.json, CLAUDE.md, START_HERE.md, inputs/memory_bank and inputs/backend hard links).
# Usage: ops/seal_passmap.sh <generation> <phase id, e.g. I8.5> [log directory, default logs/passmap-seal/<generation>]
set -euo pipefail
generation=$1
phase=$2
root=$(cd "$(dirname "$0")/.." && pwd)
logs=${3:-$root/logs/passmap-seal/$generation}
python=$root/.toolchain/bin/python3
authority=$root/work/authority_p$generation
backend=$root/work/backend_i7c4_full/backend
zip=$root/outputs/gxb-backend-pass-$generation.0-passmap.zip
phase_workspace=$("$python" -B -c 'import sys; sys.path.insert(0, sys.argv[1]); import state; print(state.facts()["phase_workspace"]["path"])' "$root/ops")
inputs=$root/$phase_workspace/passmap/inputs
mkdir -p "$logs"
if [ ! -d "$authority" ]; then
  previous=$(ls -d "$root"/work/authority_p* | sed 's/.*authority_p//' | sort -n | awk -v g="$generation" '$1 < g' | tail -1)
  [ -f "$root/work/authority_p$previous/hot/GENERATION.json" ] || { echo "previous authority p$previous is not v2" >&2; exit 1; }
  mkdir "$authority"
  cp -a "$root/work/authority_p$previous/hot" "$authority/hot"
  cp -al "$root/work/authority_p$previous/cold" "$authority/cold"
fi
tools=$authority/hot/tools
find "$authority" -name __pycache__ -type d -prune -exec rm -rf {} +
rm -rf "$authority/cache"
"$python" -B "$tools/passmap_maintain.py" sync --authority "$authority" --inputs "$inputs" --phase "$phase" --generation "$generation" --backend "$backend" > "$logs/sync_$generation.log" 2>&1
"$python" -B "$tools/passmap_maintain.py" check --authority "$authority" --backend "$backend" > "$logs/check_$generation.log" 2>&1 \
  || { tail -20 "$logs/check_$generation.log" >&2; exit 1; }
rm -rf "$logs/package_$generation" "$zip" "${zip%.zip}.verification.json" "${zip%.zip}.sha256"
"$python" -B "$tools/passmap_maintain.py" package --authority "$authority" --output "$zip" --verify "$logs/package_$generation" --backend "$backend" > "$logs/package_$generation.log" 2>&1
"$root/ops/package_backend.sh" "$generation" > "$logs/backend_$generation.log" 2>&1 || { tail -20 "$logs/backend_$generation.log" >&2; exit 1; }
"$root/ops/package_virtualclient.sh" "$generation" > "$logs/virtualclient_$generation.log" 2>&1 || { tail -20 "$logs/virtualclient_$generation.log" >&2; exit 1; }
rm -rf "$root/inputs/ops_mirror" && cp -a "$root/ops" "$root/inputs/ops_mirror" && find "$root/inputs/ops_mirror" -name __pycache__ -prune -exec rm -rf {} +
"$python" -B "$root/ops/state.py" --write > "$logs/state_$generation.log" 2>&1 || true
"$python" -B "$root/ops/state.py" --check
echo "SEAL_${generation}_PASS outputs/$(basename "$zip")"
