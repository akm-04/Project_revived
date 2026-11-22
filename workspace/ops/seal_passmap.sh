#!/usr/bin/env bash
# Seal PassMap v2 generation <N> in one step. Agents never edit hot/ by hand: they write phase inputs and this script applies them.
#   guard (A-012): the canonical backend has no uncommitted tracked change, and GATE_EVIDENCE names either a STRICT_GATE.json
#      whose verdict is GREEN for the backend HEAD, or a COMPOSITE_GATE.json ({"head": <HEAD>, "full_gate": <STRICT_GATE.json>,
#      "reruns": [<STRICT_GATE.json>...], "lead_note": ...}, the user's composite evidence rule) whose head is HEAD and whose
#      reruns are all GREEN or PARTIAL_GREEN at HEAD;
#   0. ops/contract_manifest.py seal-check: the frontier stage's portable contract registry must check clean, everything the
#      canonical backend changed since the stage began must pass the contract merge check, and the registry is exported into
#      the phase inputs. A stage with no registry yet is skipped only when the caller sets GXB_SEAL_STAGE_START=1 (a genuine
#      stage-start seal); without it, a missing registry refuses the seal;
#   1. work/authority_p<N> is created from the previous sealed v2 authority (hot copied, cold hard-linked) unless it already exists
#      (the one-time v1 -> v2 migration builds 764 itself);
#   2. passmap_maintain.py sync applies <phase workspace>/passmap/inputs and regenerates ENTRY.md, ROUTES.json and the generated records;
#   3. check (the seal guard) must be green; package writes outputs/gxb-backend-pass-<N>.0-passmap.zip, restores it into a scratch
#      directory, compares it byte for byte and re-runs the guard on the restored copy;
#   4. ops/package_backend.sh zips the committed backend HEAD into outputs/ (frozen candidate and working copy with Git);
#      ops/package_virtualclient.sh writes the virtual client kit into inputs/tools/ (replacing the previous kit); ops/ is mirrored
#      to inputs/ops_mirror (a checkpoint restore needs ops/checkpoint_archive.py);
#   5. ops/state.py --write then --check (WORKSPACE_LAYOUT.json, CLAUDE.md, START_HERE.md, inputs/memory_bank and inputs/backend hard links).
# Usage: GATE_EVIDENCE=<json> ops/seal_passmap.sh <generation> <phase id, e.g. I8.5> [log directory, default logs/passmap-seal/<generation>]
#   GXB_SEAL_STAGE_START=1 says this is a genuine stage-start seal (the frontier stage has no registry yet); the contract
#   check and the seal round trip are then skipped instead of refusing the seal. Leave it unset for every other seal.
set -euo pipefail
generation=$1
phase=$2
root=$(cd "$(dirname "$0")/.." && pwd)
logs=${3:-$root/logs/passmap-seal/$generation}
python=$root/.toolchain/bin/python3
stage_flag=${GXB_SEAL_STAGE_START:+--stage-start}
authority=$root/work/authority_p$generation
backend=$root/work/backend_i7c4_full/backend
zip=$root/outputs/gxb-backend-pass-$generation.0-passmap.zip
phase_workspace=$("$python" -B -c 'import sys; sys.path.insert(0, sys.argv[1]); import state; print(state.facts()["phase_workspace"]["path"])' "$root/ops")
inputs=$root/$phase_workspace/passmap/inputs
mkdir -p "$logs"
[ -z "$(git -C "$backend" status --porcelain --untracked-files=no)" ] || { echo "seal refused: $backend has uncommitted changes" >&2; exit 1; }
"$python" -B "$root/ops/gate_evidence.py" "$backend" "${GATE_EVIDENCE:?seal refused: set GATE_EVIDENCE to the gate result for the backend HEAD}" \
  || { echo "seal refused: gate evidence does not cover the backend HEAD" >&2; exit 1; }
"$python" -B "$root/ops/contract_manifest.py" seal-check $stage_flag > "$logs/contracts_$generation.log" 2>&1 \
  || { tail -20 "$logs/contracts_$generation.log" >&2; exit 1; }
if [ ! -d "$authority" ]; then
  previous=$(ls -d "$root"/work/authority_p* | sed 's/.*authority_p//' | sort -n | awk -v g="$generation" '$1 < g' | tail -1)
  [ -f "$root/work/authority_p$previous/hot/GENERATION.json" ] || { echo "previous authority p$previous is not v2" >&2; exit 1; }
  mkdir "$authority"
  cp -a "$root/work/authority_p$previous/hot" "$authority/hot"
  cp -al "$root/work/authority_p$previous/cold" "$authority/cold"
fi
tools=$authority/hot/tools
# Sealed tools are immutable; a new authority takes the lead-reviewed tool versions in ops/passmap_tools (audit A-077).
for tool in "$root"/ops/passmap_tools/*.py; do cp "$tool" "$tools/"; done
find "$authority" -name __pycache__ -type d -prune -exec rm -rf {} +
rm -rf "$authority/cache"
"$python" -B "$tools/passmap_maintain.py" sync --authority "$authority" --inputs "$inputs" --phase "$phase" --generation "$generation" --backend "$backend" > "$logs/sync_$generation.log" 2>&1
"$python" -B "$tools/passmap_maintain.py" check --authority "$authority" --backend "$backend" > "$logs/check_$generation.log" 2>&1 \
  || { tail -20 "$logs/check_$generation.log" >&2; exit 1; }
# The next stage opens its registry from this hot: every stage contract must come back with its content, status and ruling semantics (A-077).
registry_json=$("$python" -B -c 'import sys; sys.path.insert(0, sys.argv[1]); import contract_manifest; print(contract_manifest.registry_for() / "registry.json")' "$root/ops")
if [ -f "$registry_json" ]; then
  "$python" -B "$root/ops/contract_manifest.py" seal-roundtrip "$authority/hot" > "$logs/roundtrip_$generation.log" 2>&1 \
    || { tail -20 "$logs/roundtrip_$generation.log" >&2; exit 1; }
elif [ -z "$stage_flag" ]; then
  echo "seal refused: $registry_json does not exist and GXB_SEAL_STAGE_START is not set" >&2
  exit 1
fi
rm -rf "$logs/package_$generation" "$zip" "${zip%.zip}.verification.json" "${zip%.zip}.sha256" "${zip%.zip}.complete.json"
"$python" -B "$tools/passmap_maintain.py" package --authority "$authority" --output "$zip" --verify "$logs/package_$generation" --backend "$backend" > "$logs/package_$generation.log" 2>&1
"$root/ops/package_backend.sh" "$generation" > "$logs/backend_$generation.log" 2>&1 || { tail -20 "$logs/backend_$generation.log" >&2; exit 1; }
"$root/ops/package_virtualclient.sh" "$generation" > "$logs/virtualclient_$generation.log" 2>&1 || { tail -20 "$logs/virtualclient_$generation.log" >&2; exit 1; }
rm -rf "$root/inputs/ops_mirror" && cp -a "$root/ops" "$root/inputs/ops_mirror" && find "$root/inputs/ops_mirror" -name __pycache__ -prune -exec rm -rf {} +
"$python" -B "$root/ops/state.py" --write > "$logs/state_$generation.log" 2>&1
"$python" -B "$root/ops/state.py" --check
# The completion record is the seal's last step: state.py and checkpoint.py trust a generation only when this record
# exists and its sha256 matches the zip, so an aborted seal can never look sealed.
zip_sha=$("$python" -B -c 'import hashlib, sys; print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())' "$zip")
"$python" -B -c 'import datetime, json, os, sys; path=sys.argv[5]; temp=path+".tmp"; open(temp, "w").write(json.dumps(dict(generation=int(sys.argv[1]), zip=sys.argv[2], sha256=sys.argv[3], authority=sys.argv[4], completed=datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")), indent=2) + "\n"); os.replace(temp, path)' \
  "$generation" "outputs/$(basename "$zip")" "$zip_sha" "work/authority_p$generation" "${zip%.zip}.complete.json"
echo "SEAL_${generation}_PASS outputs/$(basename "$zip")"
# The real-client test harness follows the seal in the background; its failure never fails a seal (log in $logs/harness_deploy.log).
setsid nohup "$root/ops/harness_deploy.sh" > "$logs/harness_deploy.log" 2>&1 < /dev/null &
