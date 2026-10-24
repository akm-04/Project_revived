# Rebuilding the GXB1 workspace from inputs/ and checkpoints/ alone

For when `work/`, `tmp/` or `outputs/` are lost, or for a new agent (Claude or GPT) taking over. Everything below is in `inputs/` or
`checkpoints/`. Seals refresh these files automatically (see PROJECT_AGENT_RULES.md, "Generated workspace state"). Root: `W=/home/akm/Chatgpt/EOL_Game`.

## What is here and why
| Path | What | Rebuilds |
|---|---|---|
| `inputs/memory_bank/gxb-backend-pass-<G>.0-passmap.zip` | newest sealed PassMap (hard link of outputs/) | all project knowledge: hot/ (current truth, ENTRY.md routes), cold/ (history, evidence, gate dumps) |
| `inputs/backend/gxb-backend-v2-<ver>-p<G>-<sha>-working-with-git.zip` | backend at the sealed commit plus full Git history | `work/backend_i7c4_full/backend` |
| `inputs/backend/...-frozen-candidate.zip` | same tree, no history | reference / diffing only |
| `checkpoints/active/<PHASE>/*-cumulative-checkpoint.zip` | newest working state: phase workspace (plans, evidence, PassMap inputs not yet sealed), `ops/`, workspace tools | `work/<phase>`, `ops/`, `work/workspace_tools`, layout files |
| `inputs/tools/gxb-backend-v2-e2e-tools-r4-go1.27.3-linux-amd64.zip` | portable toolchain: Python 3, Go 1.27.3, PostgreSQL, goose, LuaJIT, zig cc | `.toolchain` and `tmp/tools_r4_accept` |
| `inputs/tools/gxb-virtual-client-kit-p<G>-<sha>.zip` | virtual client binaries, its Go module cache, test scripts, TESTING_GUIDE.md | `tmp/virtualclient/bin`, offline VC builds |
| `inputs/tools/gxb-android-emulator-i8.5-7.zip` | Android SDK (emulator 37.2.12, android-30 x86_64 image), AVD gxb30 definition, the emulator APK, its scripts and README | `tmp/android` (unzip `android/*` into `tmp/`); ops/TESTING_GUIDE.md section 4 |
| `inputs/client_baseline/` | unmodified APK 1.631.0 decoded (apktool) and its decompiled plaintext Lua (needs Wine to redo) | `tmp/virtualclient/src_64`, `apk/res`; the src_64 protocol truth |
| `inputs/Supplimental_Materials/` | user-supplied, read-only: APK, app_repack, V1 backend, asset tarball and lazy catalog | update tree, emulator APK |
| `inputs/assets/` | supplied asset archives | asset evidence |

Not kept, and why: PostgreSQL databases (rebuilt by migrations and the fresh-database recipe), `tmp/virtualclient/runs` (test output),
older PassMap authorities (COLD inside the PassMap zip holds the history), and the AVD's userdata (the emulator recreates it on first boot).

## Second copy: the workshop Git repo (branch v2)
`inputs/Supplimental_Materials/gxb_workshop` (remote akm-04/Project_revived), branch `v2` (v2 only; v1 is on `main`): `backend/` is the v2 backend with its full
history (merge commit; `git log <merge>^2`), `app_repack/patch_game_v2.sh` builds the emulator APK, `tools/parts` holds the r4 toolchain,
virtual client kit, Android bundle and client baseline split into 90 MB parts (the stock APK is user-supplied, app_repack/app/placeholder.txt) (`tools/assemble.sh <dir>` rejoins, checks
sha256 and unzips), and `workspace/` holds an ops/ snapshot and this file. The repo copy is refreshed by hand when those artifacts change
(see its tools/README.md); the files in inputs/ are newer when the two differ.

## Steps (in order)
1. Toolchain: `mkdir -p $W/work/toolchain/r4 $W/tmp/tools_r4_accept`, unzip the r4 tools zip into both, then
   `ln -sfn work/toolchain/r4/gxb-e2e-self-contained $W/.toolchain`. Check with `$W/.toolchain/bin/python3 -V`.
2. PassMap: unzip the PassMap zip to a scratch directory and run
   `.toolchain/bin/python3 -B <scratch>/passmap_maintain.py restore --bundle <scratch> --destination $W/work/authority_p<G>`.
   Then read `work/authority_p<G>/hot/ENTRY.md`. It routes to everything else.
3. Backend: `mkdir -p $W/work/backend_i7c4_full && unzip <working-with-git zip> -d $W/work/backend_i7c4_full`, then
   `git -C $W/work/backend_i7c4_full/backend status` must be clean at the sealed commit.
4. Working state: if `ops/` is lost, copy `inputs/ops_mirror/` (refreshed by every seal) to `$W/ops`. Restore the newest checkpoint over the PassMap:
   `.toolchain/bin/python3 -B ops/checkpoint_archive.py --base work/authority_p<G> --restore <checkpoint zip> --destination <scratch>`.
   The scratch directory then holds `<phase>/` (for example `i8_5/`), `ops/`, `workspace_tools/`, `layout/` (CLAUDE.md, START_HERE.md,
   WORKSPACE_LAYOUT.json) and PROJECT_AGENT_RULES.md. Copy them to `$W/work/<phase>`, `$W/ops`, `$W/work/workspace_tools`, `$W/` and `$W/`.
   Work after the newest checkpoint is lost. `<phase>/CHECKPOINT_BINDING.json` names the backend commit it expects; if that commit is newer than the
   sealed backend zip, it was never zipped. Redo it from the stage PLAN.md "Progress" notes.
   (Drilled 2026-10-24: 769 PassMap restore and r119 checkpoint restore into tmp/recovery_drill; zero diff to the live workspace.)
5. Status: `.toolchain/bin/python3 -B ops/state.py --write`, then open the handoff it names (`work/<phase>/START_HERE.md`).
6. Test runtime (when testing): start a PostgreSQL dev cluster (ops/TESTING_GUIDE.md section 0). Then rebuild the virtual client with
   `GOMOD_DOWNLOAD=<unzipped kit>/go-mod-download ops/testing/setup_virtualclient.sh` (tested 2026-10-24: src_64 4370 files,
   res 5097, display scenario client=0).
7. Prove the rebuild: run the strict gate on the backend HEAD (ops/TESTING_GUIDE.md section 2).

## For an agent taking over
- Rules: `PROJECT_AGENT_RULES.md` (AGENTS.md). Knowledge: PassMap `hot/ENTRY.md`. Current task: the phase handoff and the newest
  checkpoint's stage PLAN.md (`work/<phase>/stages/<stage>/PLAN.md`, "Progress" sections in time order).
- Never hand-edit PassMap `hot/`. Write phase inputs and seal with `ops/seal_passmap.sh <G> <phase>`. The seal also refreshes
  everything in this file.
