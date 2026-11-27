# Standing rulings

Status: ADOPTED by the lead 2026-11-27 (drafted by a worker from the lead's memory, reviewed by the lead). Add a ruling here the moment the owner gives it. Source: every file in the lead's memory directory
(`~/.claude/projects/-home-akm-Chatgpt-EOL-Game/memory/`, 104 entries) plus `work/LEAD_QUEUE.md`. Layout authority is
`work/i11/WORKSPACE_DESIGN_V2_2026-11-27.md`; where the design changes a workflow, the design wins and the old rule is
marked SUPERSEDED. No secrets, credentials, DSNs or personal addresses appear here.

How to use: this file is the takeover record. A new lead reads RULES.md, then this file, then the lane handoff. Every
bullet is a rule still in force; the appendix classifies every source memory file so nothing is silently dropped.
Dates are the ruling date, not the file mtime. "CONFLICT" marks two sources that disagree; the resolution is named.

## 1. Delegation and models
- Delegate sizeable research, implementation and focused testing to cc-fleet `slim` leaves on DeepSeek Flash; if cc-fleet fails off-peak the lead does the work; Haiku is only for very small searches. (since 2026-11-14, memory: cc-fleet-delegation.md)
- No Sonnet subagents, ever, for implementation or as a fallback; they spend the Claude usage window that delegation exists to spare. (since 2026-10-31, memory: sonnet-leaf-spends-claude-window.md)
- Pause work that spends DeepSeek usage during peak hours 01:00-04:00 and 06:00-10:00 UTC, Monday to Friday, judged by the provider's Date header (real time, not the possibly forwarded system clock), and continue automatically afterwards; Codex routes and local gates do not pause. (since 2026-11-01, memory: cc-fleet-delegation.md, clock-forwarded-1on1-window.md)
- At DeepSeek peak, if only a small fix remains, the lead finishes it and starts the long test; if it is large, the work waits for off-peak. (since 2026-11-02, memory: peak-lead-small-fixes.md)
- The lead keeps decisions, reviews, merges, gates, seals and checkpoints; fixes, tests, wiring, sweeps and docs go to workers to save the Claude window. (since 2026-11-22, memory: lead-critical-only.md)
- The lead designs every foundation repair and its acceptance; workers only execute against that design. (since 2026-11-14, memory: lead-designs-foundations.md)
- There are two worker pools: DeepSeek/OpenCode Flash (default, volume) and Codex (Luna for read-only reviews, Sol for hard work only). Each pool's models are pinned only in `ops/fleet_models.json`. (since 2026-11-14, memory: cc-fleet-delegation.md)
- Luna is paused (use DeepSeek wherever possible); if used, it is for read-only reviews whose deliverable is the reply, sends one tool call per message (`CODEX_RULES`), and a task it fails twice goes on hold for DeepSeek after peak. (since 2026-11-10, memory: cc-fleet-delegation.md, luna-failures-wait-for-deepseek.md, luna-one-tool-call.md)
- Sol is never run through cc-fleet/fleet_queue; it runs only in a manual Codex session the owner starts from a paste-ready prompt, and tasks are batched while Sol is out of usage. (since 2026-11-14, memory: codex-manual-lane.md)
- OpenCode is the default provider for volume; the OpenCode console region must stay "Global"; the official DeepSeek 402 is expected and unused; OpenCode `-free` models are allowed for any work, including project source, with bounded tasks and timeouts. (since 2026-10-31; 2026-11-19; 2026-11-27, memory: opencode-go-after-8d.md, opencode-free-models-allowed.md)
- One `fleet_queue.py` process runs one worker serially; parallelism means separate queue directories, each launched with `--slots 10`; every slim task also needs a test seat, so export `GXB_TEST_SEATS=6` for a burst. (since 2026-11-16, memory: queue-one-worker-per-process.md)
- Going slightly past free RAM for workers is allowed (85 GB swap); dispatch waits for only 1 GB available and takes `WRITERS=n` per route. (since 2026-11-08, memory: swap-headroom-workers.md)
- Build leaves need `--max-turns 300 --timeout 7200s --slots 10` on the primary route; the fallback route is the official DeepSeek account and fails with 402; resume by moving `NN.error.json` aside and relaunching the same queue. (since 2026-11-20, memory: build-leaf-max-turns.md)
- After every queue or gate launch, arm a background `kill -0 <pid>` watcher on the literal pid; never use `pgrep -f`, which matches the watcher itself. (since 2026-11-09, memory: arm-queue-watchers.md)
- Mechanical audits that diff, hash, script or run tests use the `slim` profile with an explicit read-only rule and a scratch report, not `slim-ro`; research tasks that must write use `slim --no-cluster`. (since 2026-11-10, memory: audit-profile-needs-bash.md, i9-11-restart-at-contracts.md)
- Do not use `--max-budget-usd`, and do not trust `total_cost_usd`; both overstate the real DeepSeek bill. (since 2026-11-07, memory: cc-fleet-delegation.md)
- CONFLICT: worker-count limits. `cc-fleet-delegation` sets three writing leaves per pool (2026-11-02/06), while `contract-recovery-hold` allowed up to 10 DeepSeek seats during the repair (2026-11-10). The 10-seat burst was temporary and ended with the repair; the standing pool limit is three, with the queue/slot and test-seat rules above.

## 2. Gates and testing
- Acceptance has three levels: level 1 is the impact preflight (minutes) during development; level 2 is one parallel foundation gate; level 3 is one serial release gate and only it decides the seal. Triggers T1-T4 (schema/migration, transaction-receipt-failure-mapper/httpedge/gate-toolchain, cmd wiring, and the listed equivalents) force a full gate again. (since 2026-11-14, memory: acceptance-v2-three-levels.md)
- After one green level-2 parallel gate, later fixes (product or test) are covered by the level-1 impact preflight on the packages they reach; the serial release gate remains the single final full run. (since 2026-11-17, memory: gate-reuse-policy.md)
- Gate tier follows roadmap level: a leaf closes on the impact preflight plus focused natives; a sub-phase closes on one parallel strict gate; a whole phase closes on one serial strict gate. (since 2026-11-18, memory: gate-tiers-roadmap.md)
- There are no gate qualification chains: the parallel Q1'/Q2'/Q3 checks run once when a sub-phase closes, never as a standalone qualification between leaves; tooling defects are fixed on the side and never delay backend work. (since 2026-11-18, memory: no-qualification-chains.md)
- A rolling fix may close on composite gate evidence: the last full gate plus a rerun of the red tests and every test the diff can affect, with both commits named; full gates stay mandatory at every sub-phase closure and seal. (since 2026-11-09, memory: composite-gate-evidence.md)
- A red full gate caused only by stale tests, where the fix touches only test files (plus the snapshot manifest), gets the whole touched packages rerun natively plus `tools/check.sh`, not another full gate; any product change still needs a full gate. (since 2026-11-02, memory: no-full-gate-for-test-only-fixes.md)
- Before any full or serial gate on a merged head, run the natives of every package touched by either side of each merge on the merged head and grep for cross-branch contract changes; a test-only red from the gate never blocks the next gate step. (since 2026-11-16, memory: no-full-gate-for-test-only-fixes.md)
- Serial gate reds are triaged: TOOLING reds never block; a minor BACKEND red (at most three tests, no migration, reply shape or foundation seam) is fixed, impact-preflighted and rerun natively at the fixed HEAD, and the serial gate counts as passed via composite evidence; larger or non-test reds require a new serial run. (since 2026-11-18, memory: serial-gate-remediation.md)
- Every gate red is classified BACKEND or TEST (stale pin, test bug, fixture collision, load flake, harness); only BACKEND reds block a close, and TEST reds are fixed or carried and logged. (since 2026-11-20, memory: test-defects-never-block.md)
- The legacy VC scenario suite no longer gates a phase close: failing old scenarios are retired or quarantined, never rerun; acceptance is native backend tests for changed code plus the owner's real-client walk on the harness. (since 2026-11-20, memory: test-defects-never-block.md)
- Start long closure proofs (upgrade proof and the planned suites) at the last planned merge of the stage; rolling playtest fixes do not reset closure and are listed in REALITY with their own normal gate. (since 2026-11-08, memory: closure-not-reset-by-bugfixes.md)
- Never run a VC suite beside a strict gate. (since 2026-11-08, memory: closure-not-reset-by-bugfixes.md)
- Latency runs are separate: start only after a manual process scan and five minutes below 1.5 one-minute load and 65 C CPU, sample every 30 s, report a blocker the moment it appears, give up quickly naming it, and ask the owner before sending workers after a latency RED. Budgets and tristate (off/warn/on) guards live in `tools/strict_gate/latency_budgets.json`, never hard-coded in tests. (since 2026-11-18, memory: latency-gate-thermal.md)
- Source `ops/testing/goenv.sh` only after exporting `GXB_BACKEND=<tree>`, and verify the HEAD after sourcing; source it before `gate_preflight.py` so the bundled `pg_dump` is on PATH; never merge into a tree while a preflight runs on it. (since 2026-11-08; 2026-11-20, memory: goenv-cd-trap.md)
- After every lead merge or conflict resolution, run `go vet -tags "postgres river"` on the integration packages and the virtualclient module, not just an untagged vet. (since 2026-11-16, memory: tagged-vet-after-merge.md)
- A phase that adds a content table or revision must build its upgrade proof from the previous frozen product and run `gxb-content-broadcast-deploy` after the migration, so the new revision is active on upgraded data. (since 2026-10-19, memory: i7c-upgrade-proof-content-phases.md)
- `tools/generate_builtin_content.py --check` uses `inputs/assets/Older/all-assest-rechecked-1.zip` as its source archive; the client_baseline plaintext zip is refused. (since 2026-11-09, memory: content-generator-archive.md)
- Keep `tools/system_map.py` accurate and readable: run `system_map.py --check` after a merge, and when a worker reports the map misled it, queue a map fix instead of working around it. (since 2026-11-06, memory: system-map-priority.md)
- Test clusters use the shared developer cluster through `ops/testing/start_cluster.sh`; every native builds its DSN from the queue's `GXB_TEST_PGHOST`/`GXB_TEST_PGPORT`, never a hard-coded port. Layout of that cluster is owned by design v2 section 7. (since 2026-11-27, design: WORKSPACE_DESIGN_V2_2026-11-27.md; memory: queue-one-worker-per-process.md)
- CONFLICT: whether a sub-phase seal may rest on a parallel gate. `acceptance-v2-three-levels` and `composite-gate-evidence` say only the level-3 serial gate decides a seal and full strict gates are mandatory at every seal (2026-11-14/09); `gate-tiers-roadmap` and `i9-close-parallel-gate` say a sub-phase closes on one parallel gate and `ops/gate_evidence.py` was to be changed to accept it (2026-11-18/21). The later owner rulings win for sub-phases, but the tool change was not verified in this draft; the phase-level seal stays serial unless the lead confirms the guard change.

## 3. Merges and branches
- A lead merges only with `--no-ff`, one merge at a time into the integration branch, never `--no-verify`; only a lead merges, and only one lead merges into a branch at a time (merge lock). (since 2026-11-15; 2026-11-27, memory: merge-sequence-ledger.md; design: WORKSPACE_DESIGN_V2_2026-11-27.md)
- Track every merge and branch: the generated branch ledger is rerun after every merge, cherry-pick, accepted worker task and new branch, and a branch is never deleted while `git cherry <integration> <branch>` is non-empty. Design v2 replaces the hand-kept MERGE_SEQUENCE.md with `ops/lane_merge.py` writing the lane's MERGES.md. (since 2026-11-15/16, memory: merge-sequence-ledger.md, branch-ledger.md)
- Always pass an absolute path to `git worktree add`; after creating a worktree, confirm `<tree>/docs/architecture/system_map/systems` exists before launching its queue. (since 2026-11-16, memory: worktree-add-absolute-path.md)
- Commit backend toolchain and dependency pin changes once their checks pass, with a message listing every changed pin and the qualifying tools archive. (since 2026-10-21, memory: toolchain-changes-committed.md)
- A leaf's branch commits plus its task report are the worker's checkpoint; workers do not make zip checkpoints. (since 2026-11-27, design: WORKSPACE_DESIGN_V2_2026-11-27.md)
- Keep `work/REPAIR_LANE_SEQUENCE.md` as the lead's repair queue (tiers: scale, broken gameplay, operator-tool proofs, cleanup); new gameplay defects get a row, DONE items are marked with the merge commit and never deleted. Keep `work/INACTIVE_FUNCTIONS.md` current whenever a mode-surface disposition changes. (since 2026-11-22, memory: repair-lane-sequence.md)
- CONFLICT: `i9-12-tree-and-gate-fix-flow` recorded "only the lead merges; no two running workers on the same system; bug fixes merge first" (2026-11-20), while design v2 allows several leads to share a lane with a merge lock (2026-11-27). The design wins; the "no two workers on one system" practice remains sensible but is not a standing hard rule.

## 4. Checkpoints, seals and resumes
- Checkpoint after each meaningful step (decision, merge, design or research result), not days apart; the tag is `<letters><number>[-slug]`, and design v2 makes the lane checkpoint command number the tag itself (`ops/checkpoint.py <lane> <slug>`). (since 2026-11-17; 2026-11-27, memory: checkpoint-small-steps.md; design: WORKSPACE_DESIGN_V2_2026-11-27.md)
- After any compaction, run `ops/state.py` (design v2: also `workspace_sync.py --doctor`), read the newest phase and lane checkpoints, the newest handoff and the queue/merge tails, then continue without asking. (since 2026-11-17, memory: resume-from-checkpoint-after-compaction.md; design: WORKSPACE_DESIGN_V2_2026-11-27.md)
- Small post-closure decisions do not get their own PassMap sync: record them in a checkpoint plus `work/<phase>/PASSMAP_PENDING_MERGE.json` and merge them at the next PassMap generation. (since 2026-10-20, memory: passmap-merge-small-decisions.md)
- PassMap v2: read `hot/ENTRY.md` first; a phase writes its inputs under `work/<phase>/passmap/inputs/` and runs `ops/seal_passmap.sh <G> <phase>`; never hand-edit `hot/`, generated blocks or layout facts. Design v2 moves phase selection into the lane registry, so the seal reads the registered phase, not the highest `work/iNN` folder. (since 2026-10-23; 2026-11-27, memory: latest-passmap-symlink.md; design: WORKSPACE_DESIGN_V2_2026-11-27.md)
- A seal cannot proceed while an applicable contract is missing, stale, unreviewed or unaccounted for; the seal guard and merge hook are fail-closed. (since 2026-11-10, memory: contract-manifests.md)
- `ops/seal_passmap.sh` auto-runs `ops/harness_deploy.sh` after a seal; the guard skips a non-descendant target (`HARNESS_DEPLOY_SKIP`), and the lead warns the owner before any redeploy that may interrupt play and re-gives the carry list after it. (since 2026-11-21, memory: seal-redeploys-harness.md)
- At each phase close, commit the whole backend (with ops, system map and the OTA HTTP-poll client patch) into the v2 branch of the workshop repo as an online backup; the owner reviews and pushes, and the lead never pushes. (since 2026-11-16; 2026-11-22, memory: online-backup-after-i9-11.md)
- CONFLICT: checkpoint tags. `i7c5a-checkpoint-tag-naming` says pass a short `rNN-...` tag and the prefix is added automatically (2026-10-19/22); design v2 changes the command to `<lane> <slug>` with per-lane auto-numbering (2026-11-27). Design v2 wins.
- CONFLICT: phase discovery and close order. `i11-prep-folder` says state/seal infer the phase from the highest `work/iNN` so the next phase folder may only be created or renamed after the seal (2026-11-22); design v2 reads the phase from `work/lanes.json`, never from folder names, and creates phase folders through `ops/lane.py phase` (2026-11-27). Design v2 wins; the old folder-order hazard disappears.

## 5. Harness, OTA and operator
- The harness is the top-level `test_harness/`, runs as the user service `gxb-test-harness`, and stays on while the laptop is on; no gate launcher, latency included, stops it. (since 2026-11-02; 2026-11-18, memory: real-client-playtest.md, harness-up-during-strict-gates.md)
- The public path is Cloudflare Tunnel (`api.`/`assets.gxbengine.dpdns.org`); zrok is superseded and must not be planned against. (since 2026-11-22, memory: real-client-playtest.md, asset-test-flow-ota.md)
- Harness deploys upgrade in place by default and keep the DB, phone accounts, OTA root and agent; wipe only with `HARNESS_DEPLOY_WIPE=1`; never reset the DB to change assets (`res -s` plus OTA build/publish is enough); if a reset was needed, verify the phone logins own their old player ids, restore the pre-redeploy snapshot or run `ops/reimport_legacy_players.py`, and tell the owner before calling it ready. (since 2026-11-27, memory: harness-reset-needs-seed.md)
- Redeploys and wipes are allowed without asking, but the lead reports afterwards that the DB was reset so the owner knows to recreate accounts. (since 2026-11-07, memory: harness-wipe-approved.md; narrowed by harness-reset-needs-seed.md)
- OTA model: the app is fixed at v1.631.0 forever; a fresh client gets every static asset in one loud update to 1.631.1; `.lua`/tables ship as silent patches; missing or recovered assets load on demand. (since 2026-11-17, memory: ota-operator-events-owner-answers.md)
- OTA rollback is allowed: the operator may publish a lower version after warning that clients must clear app data/reinstall; a forward build never reuses a release number, and a rollback may reuse a used number only if it is not ACTIVE/BUILT (old row kept REPLACED, files never rewritten). (since 2026-11-22; 2026-11-23, memory: ota-operator-events-owner-answers.md)
- OTA stage does not restart or log out; OTA publish runs in-process with no maintenance stop and then forces `logout_all`, so every client logs in again through the OTA check. Content deploys still use a maintenance window. (since 2026-11-27, memory: ota-publish-forced-relog.md)
- OTA owns every client patch: one ABI-neutral source under `client/ota/src/` generates the synced `src_32` and `src_64` trees, the build refuses drift outside listed ABI exceptions, and the APK keeps only origins and splash. A code release cannot change `misc.lua`/`misc1.lua` origins. (since 2026-11-22, memory: ota-owns-client-patches.md)
- OTA release state is independent of the database; releases live in the agent ledger and survive a DB restore. (since 2026-11-23, memory: operator-accounts-snapshots.md, harness-reset-needs-seed.md)
- Operator is one root role, local login now and remote later; every GM-channel message reaches the operator; typed, attributed CLI commands plus the GM inbox are built with the first events, and the GUI comes last and only calls that command layer. (since 2026-11-17, memory: ota-operator-events-owner-answers.md)
- Operator settings need safe fallbacks: events run an automatic built-in cycle when none is set; drop rates/gacha have a one-click factory-default reset plus versioned restore; validate before apply. (since 2026-11-22, memory: ota-operator-events-owner-answers.md)
- The operator tool keeps its own log of every tool-backend exchange with secrets masked, journals long backup/restore/OTA operations as resumable steps with a safety snapshot, and has a Logs tab with live tail, per-player search, level filter and attributed manual deletion. (since 2026-11-22, memory: ota-operator-events-owner-answers.md)
- Events are their own backend management system (definitions, schedule, occurrences, progress, claims, shops, carry-over), deeply linked to the operator tool; gameplay owners expose typed hooks and events never write another owner's tables. (since 2026-11-22, memory: ota-operator-events-owner-answers.md)
- Events default to global scope and newly created servers join running global events; per-server events are the exception. (since 2026-11-23, memory: events-global-default.md)
- The operator can make any event permanent and end it; permanent client rows (`days = -1`, e.g. 1071, 1091, 1044, 1183) are modelled with a NULL end and a far-future client end time. (since 2026-11-22, memory: permanent-events.md)
- Event carry-over is decided per event; the first events come from the E0-1c catalogue, with assets complete and the simplest rule modifiers first. (since 2026-11-17, memory: ota-operator-events-owner-answers.md)
- Operator account passwords stay PBKDF2 hashes and are never readable; the tool lists login names and can set a new password (logged, sessions ended). An account clone copies only the player's own progress (new login, name and chosen server; no guild, friends, chat, mail, rankings or payments), and renames follow the client's name rules. (since 2026-11-23, memory: operator-accounts-snapshots.md)
- Snapshots: pinned named snapshots are never pruned and survive redeploys, with a pinned "v1 import baseline"; automatic snapshots keep the last 5 (options 5/10/15/30, default 5), manual snapshots are never auto-pruned, the total cap is about 50; scheduled default is 1 day (1/7/15/30/off); the GUI has "Back up now", a backup-path field with Browse, per-row delete plus bulk delete, pinned protection, and older snapshots migrate forward on restore. (since 2026-11-23, memory: operator-accounts-snapshots.md)
- Asset testing on the real client: one loud update to 1.631.1 with original official assets, then a silent patch that overwrites only `lazyFile.json`, and the backend `/res` serves the asset lane's current res folder. (since 2026-11-22, memory: asset-test-flow-ota.md)
- The asset experimental worker may publish only through `ops/asset_test_publish.py <task-id>` and `--restore`; one live tree at a time, and the worker never gets the operator password or opens `test_harness/`. (since 2026-11-23, memory: asset-worker-publish-wrapper.md)

## 6. Asset lane
- Asset recovery is its own lane with no gate or seal, checkpointed with `--lane` (prefix `arNN`), one small step per checkpoint; design v2 moves the folder to `work/lanes/asset/`. (since 2026-11-17; 2026-11-27, memory: asset-recovery-lane.md; design: WORKSPACE_DESIGN_V2_2026-11-27.md)
- The csb target is Cocos Studio 2.1.0.0; every 2.0.8.0 file is converted with semantic proof (decode, re-encode, schema check, decoded tree/reference/animation comparison, client behaviour), never byte identity. (since 2026-11-10/17, memory: asset-recovery-lane.md, old-client-csb-assets.md)
- Images (items, avatars, skins) import when width and height match even if MD5 differs; a different size is not a rejection and gets tested too. (since 2026-11-17, memory: asset-recovery-lane.md)
- An asset is official only if its MD5 and size equal an entry in the catalogue inside `inputs/client_baseline/base.apk`; a device cache's own `version.json` proves nothing, and the community 1.631.27 cache is a private-server build, revoked. (since 2026-11-18, memory: official-catalogue-trust-anchor.md)
- The old client dump is the main recovery source; the APK res covers 2,450 files an inventory missed; the community cache adds only about 70 missing files; tables name asset paths explicitly and ids overlap across tables. (since 2026-11-17, memory: asset-recovery-lane.md)
- `inputs/Recovered_assets` is the owner's private git repo of all client assets: one logical change per commit, the owner pushes, it is the one writable place under `inputs/`, never execute from it, and never commit device data (`shared_prefs`, `*.db`, tokens), APKs or files over 100 MB; custom mods live in `gxb_workshop/app_repack/mods`. (since 2026-11-22, memory: asset-repo-git.md)
- The asset experimental worker is an owner-run DeepSeek/OpenCode session: it writes only `work/asset_experimental/`, never commits or checkpoints outside its own `xNN` lane, never touches `test_harness/` or operator/OTA settings; the owner points "Recovered res path" at a task's `res/`, and the lead accepts (asset-repo commit plus `arNN` checkpoint) or rejects. (since 2026-11-23, memory: asset-experimental-worker.md)
- The 2018 legacy asset zip is `inputs/Supplimental_Materials/Game-Assets/gxb_legacy-2018-assets_full.zip`; the `old/` folder beside it is not legacy; a past drop-in crashed the client at launch and the cause remains UNKNOWN. (since 2026-11-10, memory: old-client-csb-assets.md)
- Diagnose assets with an emulator walk plus logcat only when no strict gate runs; the real phone is the fast confirmation, and anything that works ships over OTA, never an APK rebuild. (since 2026-11-10/17, memory: old-client-csb-assets.md, asset-recovery-lane.md)

## 7. Audit lane
- The independent auditor works alone: no cc-fleet, fleet_queue, Codex sub-sessions, DeepSeek or subagents. It starts at `work/audit/START_HERE.md`; its workspace is `work/audit/`, and product trees, the registry, ledger, BUGS.md, PassMap and rules are read-only for it. (since 2026-11-11, memory: independent-auditor-fable.md)
- Auditor fixes go in per-finding worktrees `work/backend_audit_a<NNN>` on branch `audit/A-NNN`; files outside git are proposed as copies plus a diff under `work/audit/proposals/A-NNN/`; it checkpoints only with `ops/checkpoint.py <aNN> --audit` (design v2: the audit lane's own checkpoint directory). (since 2026-11-11; 2026-11-27, memory: independent-auditor-fable.md; design: WORKSPACE_DESIGN_V2_2026-11-27.md)
- The lead verifies every finding and records ACCEPTED, REJECTED or DEFERRED in `work/audit/LEAD_VERDICTS.md`; accepted fixes land through the normal merge-check and gate loop, and policy questions go to the owner through the lead. (since 2026-11-11, memory: independent-auditor-fable.md)
- Fable 5.2 was the first auditor; Sol stands in through a user-run Codex session, never cc-fleet, with the same workspace and rules and with tasks batched in `work/audit/SOL_PROMPT.md` while out of usage. Do not hold the roadmap for the audit. (since 2026-11-15; 2026-11-21, memory: independent-auditor-fable.md, codex-manual-lane.md, i9-close-without-sol.md)

## 8. Contracts and registry
- Contracts reach workers mechanically, never by memory: every task carries a `Contract-Systems:` header, `fleet_queue.py` builds the pinned manifest and refuses a task without it, and the report ends with a `## Contract compliance` row per contract (APPLIED with a non-test file:line and a test, NOT_APPLICABLE with a reason, or CONFLICT). (since 2026-11-10, memory: contract-manifests.md)
- The stage registry is the authority; only the lead changes it (`add`, `accept`, `bind`, `bind-path`, `waive`, `integration`), everything is fail-closed, and the only bypass is a recorded lead waiver with a reason. (since 2026-11-10, memory: contract-manifests.md)
- A contract's identity is the id its document declares (`contract_id`/`policy_id` in JSON, a `Contract-Id:` line in Markdown), never the file name; a Markdown file without that line is research, and registered contract documents are never edited. (since 2026-11-10, memory: contract-manifests.md)
- Merge with `--no-ff` only on a passing merge check; the merge hook and seal check are fail-closed, the independent-audit pool is decided by the trailers of the files' own commits, and `--into` names refs already merged into the integration branch. (since 2026-11-10, memory: contract-manifests.md)
- After any change to the contract tools, run `cd ops && ../.toolchain/bin/python3 -B -m unittest test_contract_workflow` and diff the live corpus; test hooks with a real git merge, never a simulation. (since 2026-11-10, memory: contract-manifests.md)
- Never edit or re-register a contract/design document while a queued task that reads it is running; hold the amendment and register it after the task, then queue a follow-up. The Sol prompt may be updated freely. (since 2026-11-16, memory: no-design-edits-under-running-task.md)
- At every leaf, sub-phase and phase close, sweep PLAN.md, MERGE_SEQUENCE.md, held/released queues, worker prompts and LEAD_VERDICTS for rulings and fold each into a registered contract; write rulings into the contract when given, and require a clean `contract_registry.py check`. (since 2026-11-18, memory: registry-complete-at-close.md)
- The popup catalogue (`tools/popup_catalog.py`, contract I9_11_POPUP_CATALOGUE_V1) binds every current and future build contract and phase close: owed popups must be PRODUCED with a test, WAIVED with an owner phase, or ruled out. (since 2026-11-19, memory: popup-catalogue-binding.md)
- `CONTROL_PLANE_OBLIGATIONS_V1` is registered and bound globally: every owing system lists its operator command/read, OTA content and event hook obligations, and a phase close fails if a row due in that phase is OPEN. (since 2026-11-22, memory: control-plane-obligations.md)
- `CONTRACT_SCOPE_V1` makes no scope left behind: a contract saying "every mode/all shops/every MID" fails `check` until bound, and new mode systems extend the `kind mode` binding. (since 2026-11-16, memory: contract-manifests.md)
- DeepSeek workers use the DeepSeek commit trailer mandated by the delegation rules, with no cc-fleet mention in it. (since 2026-11-14, memory: repair-rulings-u1-u6.md)

## 9. Client and game policy
- The client source under `tmp/virtualclient/src_64` decides wire shapes, units and callbacks; contracts decide policy; never invent a mechanic, formula, ID, owner, wire shape or success reply, and carry an inherited UNKNOWN as UNKNOWN until a source settles it. (since project start, restated 2026-11-10, memory: contract-manifests.md; task rules)
- Client-facing work starts from the whole window, not the server: inventory the window's Lua, sibling/child windows, popups, every request, push, reply field, toast/text key, timer and client table row, then connect each to its producer; an unserved item is a finding, and a window that only refreshes after reopening has a missing push or reply field. (since 2026-11-10, memory: audit-whole-menu.md)
- Before writing any reply, open the Lua callback and list the field paths it indexes; every refusal goes through the R4 mapper in `internal/adapters/stockruntime/failure.go` (permanent 409 + D5 code, transient 503 + 35033, defect 500 + 35028), never a hand-built refusal body. (since 2026-11-11, memory: error-code-classification.md)
- Error codes: use the specific evidence-backed code when the client gives one, a generic fallback only when the mapping is unknown, and never classify a permanent failure (unsupported, inactive, corrupt) as a retryable 503/35033. (since 2026-11-11, memory: error-code-classification.md)
- An expired or invalid session returns 20003 "unstable network, relog in"; an unknown commit outcome or edge reply-encode failure also forces a relog with 20003 rather than 503. (since 2026-11-14, memory: repair-rulings-u1-u6.md)
- A player restore does not roll back purchase, redeem or claim ledgers, and restore skips shared rows (friendships, pending requests); cross-server restore and player moves are out of scope for now. (since 2026-11-14/16, memory: repair-rulings-u1-u6.md)
- Retention: rows not still referenced are kept at most 15 days (tunable, default 15); referenced rows (arena reports, conquest recommendations) live while referenced; a replaced avatar URL works 15 days then 404; guild broadcast mail expires after 7 days; R5D settlement rows purge after 15 days; snapshots and pure caches keep 1 day; event claims are kept forever. (since 2026-11-14/16, memory: repair-rulings-u1-u6.md)
- Capacity target is 1000 simultaneous connections and a 200 login burst, subject to the lead's measured advice; prefer queueing over failing. (since 2026-11-14, memory: repair-rulings-u1-u6.md)
- Chat uses HTTP long polling through the stock HTTP request path behind `Backend.createTCPSocket`; never reintroduce `cc.WebSocket`. (since 2026-11-07, memory: chat-over-websocket.md)
- Multi-battle combat STARTs batch freezes through `combat.StartManyTx`, keep content catalogues memoized per revision, and bound synchronous waits below the client HTTP timeout (20 s urlencoded, 30 s form-data), letting an identical retry or reconcile deliver the result. (since 2026-10-20, memory: combat-start-latency.md)
- No stubs and no pulling systems forward to get the tutorial through; a tutorial blocked by a missing system waits for that system, and the block becomes an obligation on the owning stage. (since 2026-11-02, memory: no-stubs-tutorial-waits.md)
- Shop prices follow the source tables for now, but every price knob stays operator-tunable through the D476 `shop_tuning` overlay (`sell_price`, `item_num`, `max_buys`, `disabled`, `stone_id`). (since 2026-11-18, memory: shop-prices-operator-tunable.md)
- `summon_coin` plus shop type 30 is the candidate for a future custom shop and must not be built before OTA and the operator tool are done; type-30 buys stay refused until then, and option A (backend bonus grant) versus B (OTA Lua item entry) is undecided. (since 2026-11-18, memory: summon-coin-custom-shop-deferred.md)
- The three-level acceptance and gate policy above govern client releases too; content updates other than OTA publish use a maintenance window (stop, deploy, reopen, clients relog and pass the OTA check). (since 2026-11-15, memory: content-update-maintenance-window.md)
- Policy decisions are amended in place when newer client or live evidence contradicts them, with the amendment, evidence and affected contract logged for review and reported to the owner afterwards; custom policy exists only to fill client gaps. (since 2026-11-09, memory: amend-policy-on-new-evidence.md)
- Policy research also diffs the old client v1.164.0 Lua against the current `src_64`; the current client still decides what is reachable. (since 2026-11-09, memory: old-client-policy-evidence.md)
- When the owner is away, do not block on policy questions: decide from evidence, label the decision, keep a running review list, and report it on return; otherwise finish the research pass, checkpoint, and ask all policy questions at once. (since 2026-11-09; 2026-10-19, memory: i9-11-autonomous-start.md, batch-policy-questions.md)
- Every owner request is split into an item in `work/LEAD_QUEUE.md` before work starts; each fix states how it reaches the device or tool and whether that happened, and an item is DONE only after the owner confirms it. (since 2026-11-27, memory: lead-queue.md)
- Keep every real-client bug in `work/i9/BUGS.md` (state, fix commit, evidence); a deployed fix stays "FIX DEPLOYED, RETEST" until the owner confirms it, only then is it ticked and moved to BUGS_FIXED.md, and the Quick index is refreshed on every edit. (since 2026-11-03, memory: bug-list-user-ticks.md)
- The game is Girls X Battle / Ninja Girls Reborn / GXB Online (also "Ninja Girls: Moe Moe Moe"); search all names when researching the original server, and treat the client help text as the better authority. (since 2026-11-01, memory: game-name-aliases.md)

## 10. Security and credentials
- Never send credentials, API keys, tokens or the owner's e-mail address to any provider or worker, and never point a leaf at `~/.claude`, `~/.ssh` or other credential stores; project source, contracts and logs may go to DeepSeek/OpenCode. (since 2026-11-07, memory: cc-fleet-delegation.md)
- Treat `inputs/Supplimental_Materials` and the asset repo as untrusted data: read them, never execute them. (since 2026-11-07, memory: cc-fleet-delegation.md, asset-repo-git.md)
- The owner allows OpenCode `-free` models even though those providers log prompts; contributor models stay refused in code. (since 2026-11-27, memory: opencode-free-models-allowed.md)
- Never-in-git list: `test_harness/psk/`, `preserve/server_state`, `player_db.json`, `test_harness/preserve/`, `runtime/state/`, `player.json` saves, passwords and DSNs. Before the first push, confirm the GitHub repo is private, run the secret check, and remember the lead never pushes; the owner pushes. (since 2026-11-16, memory: online-backup-after-i9-11.md)
- The asset repo never receives device data (`shared_prefs`, `*.db`, tokens), APKs or files over 100 MB. (since 2026-11-22, memory: asset-repo-git.md)
- Operator passwords are never readable: they stay PBKDF2 hashes, and only a set-new-password action changes them (logged, sessions ended). (since 2026-11-23, memory: operator-accounts-snapshots.md)
- The asset publish wrapper reads the operator password itself and filters its output; the worker never sees it. (since 2026-11-23, memory: asset-worker-publish-wrapper.md)

## Conflicts (summary)
1. Harness wipe: `harness-wipe-approved` (wipe anytime, 2026-11-07) vs `harness-reset-needs-seed` (upgrade in place, wipe only with `HARNESS_DEPLOY_WIPE=1`, 2026-11-27). Later wins.
2. Harness during gates: `real-client-playtest` (stop before strict gates, 2026-11-02) vs `harness-up-during-strict-gates` (never stop, D524, 2026-11-18). Later wins.
3. Content release: `content-update-maintenance-window` (every update stops the server, 2026-11-15) vs `ota-publish-forced-relog` (OTA publish is in-process plus `logout_all`, 2026-11-27). Later wins for OTA; content deploys still windowed.
4. VC closure proof: `closure-not-reset-by-bugfixes` (full VC suite as closure proof, 2026-11-08) vs `test-defects-never-block` (legacy VC suite no longer gates a close, 2026-11-20). Later wins.
5. Seal level: `acceptance-v2-three-levels` + `composite-gate-evidence` (only serial decides a seal) vs `gate-tiers-roadmap` + `i9-close-parallel-gate` (sub-phase closes on a parallel gate). Later wins for sub-phases; `ops/gate_evidence.py` state unverified.
6. Checkpoint tags: `i7c5a-checkpoint-tag-naming` (`rNN-slug` argument) vs design v2 (lane + auto-numbered tag). Design v2 wins.
7. Phase discovery: `i11-prep-folder` (highest `work/iNN`; seal before folder rename) vs design v2 (registry-driven phase). Design v2 wins.
8. Merge ledger: `merge-sequence-ledger` (hand-kept MERGE_SEQUENCE.md) vs design v2 (`ops/lane_merge.py` writes MERGES.md). Design v2 wins.
9. Luna: `luna-writes-with-postgres` and the 2026-11-07/08 entries (run Luna workers alongside DeepSeek) vs `cc-fleet-delegation` 2026-11-10 (Luna paused, DeepSeek wherever possible). The pause wins; Luna stays reviewer-only if resumed.
10. Worker counts: `cc-fleet-delegation` (three per pool) vs `contract-recovery-hold` (up to 10 DeepSeek seats during the repair). Temporary burst, ended.
11. Harness topology: `real-client-playtest` (zrok2 names to track) vs `asset-test-flow-ota` (Cloudflare, zrok superseded). Later wins.
12. Lead/merge model: `i9-12-tree-and-gate-fix-flow` (only the lead merges; no two workers on one system) vs design v2 (several leads per lane with a merge lock). Design v2 wins.

## Appendix: classification of every memory file
Classes: RULING (standing rule still in force), SUPERSEDED (replaced; replacement named), HISTORY (past event/phase fact, no standing rule).

| memory file | class | note |
|---|---|---|
| acceptance-v2-three-levels.md | RULING | amended by gate-reuse-policy |
| amend-policy-on-new-evidence.md | RULING | |
| arm-queue-watchers.md | RULING | |
| asset-experimental-worker.md | RULING | folder moves under design v2 |
| asset-recovery-lane.md | RULING | lane path moves under design v2 |
| asset-repo-git.md | RULING | |
| asset-test-flow-ota.md | RULING | harness topology part superseded by upgrade-in-place |
| asset-worker-publish-wrapper.md | RULING | |
| audit-profile-needs-bash.md | RULING | |
| audit-whole-menu.md | RULING | |
| batch-policy-questions.md | RULING | |
| branch-ledger.md | RULING | generated ledger continues |
| bug-list-user-ticks.md | RULING | |
| build-leaf-max-turns.md | RULING | |
| cc-fleet-delegation.md | RULING | Luna/Sol parts superseded by 2026-11-10/14 |
| chat-over-websocket.md | RULING | OTA now owns the patch |
| checkpoint-small-steps.md | RULING | tag numbering moves to design v2 |
| clock-forwarded-1on1-window.md | RULING | |
| closure-not-reset-by-bugfixes.md | RULING | VC-suite closure part superseded by test-defects-never-block |
| codex-manual-lane.md | RULING | |
| combat-start-latency.md | RULING | |
| composite-gate-evidence.md | RULING | conflicts with gate-tiers on seal level (C5) |
| content-generator-archive.md | RULING | reference/tool invocation |
| content-update-maintenance-window.md | RULING | publish half superseded by ota-publish-forced-relog |
| contract-manifests.md | RULING | registry rules continue; tool paths refreshed |
| contract-recovery-hold.md | HISTORY | repair closed 2026-11-18 |
| control-plane-obligations.md | RULING | |
| error-code-classification.md | RULING | |
| events-global-default.md | RULING | |
| freeze-plan-after-sol-t27.md | HISTORY | superseded by repair-closed-freeze |
| game-name-aliases.md | RULING | reference fact |
| gate-reuse-policy.md | RULING | |
| gate-tiers-roadmap.md | RULING | seal-guard change carries into I11 |
| goenv-cd-trap.md | RULING | |
| handoff-to-gpt-5f.md | HISTORY | past handoffs |
| harness-reset-needs-seed.md | RULING | supersedes harness-wipe-approved |
| harness-up-during-strict-gates.md | RULING | supersedes stop-during-gates |
| harness-wipe-approved.md | SUPERSEDED | by harness-reset-needs-seed (2026-11-27) |
| i11-prep-folder.md | SUPERSEDED | by design v2 registry-driven phases |
| i7c5a-checkpoint-tag-naming.md | SUPERSEDED | by design v2 auto-numbered lane tags |
| i7c-upgrade-proof-content-phases.md | RULING | HOT-relocation detail stale |
| i9-11-autonomous-start.md | HISTORY | past owner-away instruction |
| i9-11-next-after-i9-10.md | HISTORY | past phase plan |
| i9-11-one-gate-with-repair.md | HISTORY | phase arrangement, repair closed |
| i9-11-restart-at-contracts.md | HISTORY | past restart |
| i9-12-early-start.md | HISTORY | past phase plan |
| i9-12-tree-and-gate-fix-flow.md | HISTORY | BACKEND/TEST rule carried by test-defects-never-block |
| i9-close-asap-then-i11.md | HISTORY | I9 closed |
| i9-close-parallel-gate.md | HISTORY | rule carried by gate-tiers-roadmap |
| i9-close-without-sol.md | HISTORY | I9 closed |
| independent-auditor-fable.md | RULING | lane rules continue; Fable fact historical |
| latency-gate-thermal.md | RULING | |
| latest-passmap-symlink.md | RULING | phase selection moves to registry |
| lead-critical-only.md | RULING | |
| lead-designs-foundations.md | RULING | |
| lead-queue.md | RULING | |
| luna-failures-wait-for-deepseek.md | RULING | dormant while Luna is paused |
| luna-one-tool-call.md | RULING | |
| luna-writes-with-postgres.md | SUPERSEDED | Luna paused 2026-11-10; reviewer-only 2026-11-08 |
| merge-sequence-ledger.md | SUPERSEDED | by design v2 MERGES.md/lane_merge.py |
| no-design-edits-under-running-task.md | RULING | |
| no-full-gate-for-test-only-fixes.md | RULING | |
| no-qualification-chains.md | RULING | |
| no-stubs-tutorial-waits.md | RULING | |
| official-catalogue-trust-anchor.md | RULING | |
| old-client-csb-assets.md | RULING | crash cause remains UNKNOWN |
| old-client-policy-evidence.md | RULING | |
| online-backup-after-i9-11.md | RULING | 2026-11-22 instance done; repeats each close |
| opencode-go-after-8d.md | RULING | |
| opencode-free-models-allowed.md | RULING | |
| operator-accounts-snapshots.md | RULING | |
| ota-operator-events-owner-answers.md | RULING | rollback/publish amendments folded in |
| ota-owns-client-patches.md | RULING | |
| ota-publish-forced-relog.md | RULING | |
| passmap-merge-small-decisions.md | RULING | |
| peak-lead-small-fixes.md | RULING | |
| permanent-events.md | RULING | |
| phase-i8-5-client-observability.md | HISTORY | phase closed |
| popup-catalogue-binding.md | RULING | |
| power-cut-recovery.md | RULING | recovery procedure |
| queue-one-worker-per-process.md | RULING | |
| real-client-playtest.md | RULING | stop-during-gates and zrok parts superseded |
| registry-complete-at-close.md | RULING | |
| repair-autonomous-policy.md | HISTORY | past owner-away instruction |
| repair-closed-freeze.md | HISTORY | repair closed |
| repair-closure-t19-gaps.md | HISTORY | past closure work |
| repair-lane-sequence.md | RULING | |
| repair-rulings-u1-u6.md | RULING | game/retention/restore rulings |
| resume-from-checkpoint-after-compaction.md | RULING | design v2 adds doctor |
| resume-handoff-2026-11-27.md | SUPERSEDED | by workspace-redesign-hold (LQ-12 HOLD) |
| seal-redeploys-harness.md | RULING | wipe part superseded; descendant guard stands |
| serial-gate-remediation.md | RULING | |
| shop-prices-operator-tunable.md | RULING | |
| sol-t35-first.md | HISTORY | superseded by LQ-16 (T39) |
| sonnet-leaf-spends-claude-window.md | RULING | |
| summon-coin-custom-shop-deferred.md | RULING | deferred decision |
| swap-headroom-workers.md | RULING | |
| system-map-priority.md | RULING | |
| tagged-vet-after-merge.md | RULING | |
| test-defects-never-block.md | RULING | |
| toolchain-changes-committed.md | RULING | |
| use-latest-tools-bundle.md | RULING | use current .toolchain and say so |
| workspace-redesign-hold.md | RULING | current HOLD |
| worktree-add-absolute-path.md | RULING | |

Counts: 81 RULING, 6 SUPERSEDED, 17 HISTORY (104 total).
