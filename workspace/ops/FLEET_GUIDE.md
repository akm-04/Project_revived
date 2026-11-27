# Worker queue: DeepSeek Flash and Codex (stage lead only)

`.toolchain/bin/python3 -B ops/fleet_queue.py <queue dir> [--route primary|fallback|codex|codex-strong] [--profile slim-ro|slim] [--max-turns 80] [--timeout 1800s] [--rotate-context 150000] [--allow-peak]`, or `--wait peak|off-peak` alone

Tasks are `NN-name.prompt`; the answer is `NN-name.md`; failures land in `NN-name.error.json`. Each pool has three slots: DeepSeek (`primary`, `fallback`) and Codex (`codex`, `codex-strong`) are separate pools, so up to six queues run at once, one per stream of work (a fourth in a pool waits; a second run of the same queue is refused). `--slots N` (at most 10) lets one queue take a pool slot past the third; it is only for a burst of independent read-only tasks the user approved, such as the 2026-11-10 contract-recovery audits, and normal work goes back to three. A rerun skips answered tasks. Launch it in the background if your shell wakes you on exit; otherwise in the foreground with a long timeout.

## Leaf loop (from I9-8 results, `work/i9/stages/I9-8/USAGE_REPORT.md`)
The worker writes a lot of plausible code and does not prove it holds. Being told a rule was not enough: 8D's RULES.md named lock order, real-path tests, server scoping and one-shot notices, and 8D broke all four. The same model, doing nothing but checking, found 24 real defects for $0.26. So implementing and checking are separate tasks.

1. Research: `slim-ro`, one narrow task per family, one fresh session per leaf (`NN-name.fresh.prompt`), run one at a time. Start with a shared task when leaves share code. After each leaf the lead samples its citations, adds the findings that held to `EVIDENCE_INDEX.md` in the queue directory, and only then adds the next prompt, naming the index sections that leaf needs. Workers cannot write there, so the index holds only lead-checked findings, with their citations, UNKNOWNs and corrections.
2. Lead writes the contract, then the dangerous boundaries itself: migration and lock keys, transaction order in multi-step flows, composition root registrations, settlement and debit paths, F4 mapping. Commit before the worker starts.
3. Ledger task, before any code: the worker writes `LEDGER.md` in the queue directory with one row per MID and push: client Lua file and line of the callback, every reply field path it reads, what it does on a refusal, then blank columns for server function and proving test. A later or rotated session reads the ledger instead of rereading Lua.
4. Implementation: `slim`, parts of about 2000 lines, the worker fills the ledger's blank columns. Name the client Lua files to open, not only a research note: 8D made 691 tool calls from `research/adventure.md` without one Read of a Lua file, and its reply shapes were wrong. A replay of one 8D part with the Lua files named opened 16 of them and got the 2416 shape right, but still broke lock order and F4 drain handling, so step 5 stays.
5. Check, in a fresh `slim-ro` session after each part, no implementation context: every reply against the ledger and Lua; every transaction against the lock order; every new owner against the real composition root. Findings only. This session's only job is finding faults.
6. Fix: `slim`, from the findings list. Report each as fixed, wrong or left.
7. Lead: starts from the report's `## Catch-up` to aim the review, then reads the diff of `cmd/`, migrations, settlement and anything a finding touched; runs Layer 1 itself; decides. Catch-up is a claim like the rest of the report, so it never replaces the diff.

Skip 2's lead work and 5 only for a leaf with no shared state.

At the stage close, run one read-only simplification review before the freeze, so accepted findings are tested with the stage. It costs about $0.05. Copy the prompts and `duplication_scan.py` from `work/i9/stages/I9-8/fleet_volume` and change the package list. A size review changes no behaviour and never touches lock order, settlement, recovery or reply shapes.

Monitoring: after each queue run `.toolchain/bin/python3 -B work/i9/lead_tools/fleet_usage.py <queue dirs>` for turns, cache hit and context per task, and tune prompts or rotation if the numbers justify it (user request).

## Worker rules
The queue sends `ops/FLEET_RULES_WORKER.md` at the start of every fresh session, on every profile and route, and `usage.jsonl` records the file's `rules_sha256`. Prompts add only what is specific to the task: paths, base commit, lock order, lead decisions. Before this, 2 of 23 I9-8 sessions read that file, the only 2 told to. A session told by name to open a file did so on its first turn every time (10 of 10), so reading was never the weak point. Keep the file short and limited to rules every leaf needs; it is about 1,400 tokens and costs under $0.002 for a 300-turn session, because later turns read it from cache.

## Which provider
Both run DeepSeek Flash with cached sessions and resume. Same 8B client review, one sample (`work/i9/stages/I9-8/fleet_provider_test`, USAGE_REPORT.md):
- Official API: 58 turns in 395 s, 6.8 s per turn, $0.077 at list price. All 8 findings held, including the worst one.
- OpenCode Go: 40 turns in 396 s, 9.9 s per turn, $0.057 of allowance. 7 of 8 held; its one "crash" was unreachable. It obeyed "no rereading" less well in a short test.
Default OpenCode for volume, because the $10 plan carries $100 a month of Flash usage. Peak hours double its Flash price too, so the queue waits out peak on both. Use `--route fallback` if OpenCode fails or its allowance runs out. The two found different faults, so a high-risk review is worth running on both.

## Contract registry, manifests and merge check (user, 2026-11-10)
The rules are in ops/CONTRACT_RULES.md. The working loop:
- Stage start: `ops/contract_registry.py open <stage>` (once). It copies every contract document with its sha256 and inherits the lead's system and path bindings from the previous registry. Once the integration worktree exists, record it with `contract_registry.py integration <stage> <worktree> --base-commit <canonical HEAD>`; from then on its merge hooks refuse a merge that fails the check. Then run `ops/contract_manifest.py coverage` and work down `REGISTRY/COVERAGE.md`: bind each unresolved contract with `contract_registry.py bind <stage> <id> --system <name> ... | --kind <kind> ... | --global | --no-code --reason ...`. Define a kind once with `contract_registry.py kind <stage> <kind> --system <name> ... --reason ...` when many contracts reach the same set of systems.
- During the stage: register a new or amended contract with `add` the moment it is decided, not at close (an amendment re-adds the same id; every version stays under `documents/<id>/`, content-addressed). A ruling that changes a contract is registered with `add <stage> <file> --id <ID> --title <T> --kind ruling --amends <CONTRACT_ID>[:<clause>]`; `amend <stage> <ID> --amends ...` replaces that list. Run `check <stage> --tree <worktree> ...` whenever you want the drift picture: it flags an altered copy, an UNREGISTERED contract document (JSON with a contract or policy id, or anything in the stage's `contracts/`), a DIVERGED one, a live contract whose text claims "every mode"/"all shops" scope but has no binding (SCOPE_ALARM), a ruling amending an unregistered id, and a `WARNING AMENDED_OLDER` contract the lead must re-add. A `WARNING` line does not fail the check; the rest do. `COVERAGE.md` lists scope contracts with the number of systems they reach.
- Every prompt: the first lines are `Contract-Systems: <system>, ...` (system names from the tree's system map; `none - <why>` for work that touches no system, such as research on assets) and `Contract-Tree: <worktree>` (default: the canonical backend). A system the task creates is `<name> (new)`; add `Contract-Ids: <id>, ...` for the contracts it is built on, which the map cannot place before the system exists (the lookup adds the rest). The queue refuses a prompt without it (`CONTRACT_HEADER_MISSING`, `CONTRACT_SYSTEM_UNKNOWN`, `CONTRACT_REGISTRY_NOT_OPEN` in the error file). Name every system the task may change; the merge check catches a system the leaf changed but the header left out. Look up what a system brings with `contract_manifest.py system <name> --tree <worktree>`.
- After the answer: the queue checks the `## Contract compliance` section, sends one corrective follow-up if it fails, and stops the queue on a final FAIL or a CONFLICT (`CONTRACT ...` line in the log). A manifest row is `binding` when a MID, a MID name, an owned table, its id, a lead binding, the task header or a ruling places it, and `index` when only a package path or the system's source cites it; the worker owes a row for every binding row, an index row is optional and is checked like a binding row when written, and APPLIED on a binding row must cite a non-test file changed since the manifest's base commit, plus its proving test. A manifest written before tiers keeps the older rule (a row for every contract). `usage.jsonl` rows carry `contract_systems`, `contract_revision` and `contract_status`; `REGISTRY/dispatches.jsonl` keeps every outcome with its manifest path.
- Audit verdicts: `ops/contract_manifest.py record-verdicts <file> --by <pool> [--reviewed]` pins each verdict to the contract's sha256, the integration worktree's HEAD and the blob id of every file:line it cites; `matrix` reports STALE when the document or a cited blob changed and UNPINNED (not STALE) for a verdict recorded before that pinning, reading the tree's blobs with one `git ls-tree -r` per run.
- Preview: `merge-check --dry-run` checks a leaf without absorbing anything; a check without it writes the leaf's contract amendments into the stage registry, so run it only on the leaf you are about to merge.
- Shared history: `--into <ref>` (repeatable) names refs already merged into the integration branch; files their commits changed are not charged to the leaf. The I9-11 leaves share history (criss-cross merge bases), so pass each earlier-merged leaf (or the integration HEAD, which the merge hook does itself).
- Merge: first `ops/contract_manifest.py merge-check --tree <leaf> --base <branch point> --revalidation-queue <leaf queue>` in the leaf, then `git merge --no-ff <leaf>` in the integration worktree, whose hook reruns the check and refuses the commit on a failure (never `--no-verify`). Settle each problem: read every ABSORBED contract and `accept` it (or `add` a corrected version); settle each CONFLICT or DUPLICATE; `bind` each COVERAGE contract; fix or rebind each STALE_BINDING; `bind-path <stage> '<glob>' --system <name> | --no-code --reason ...` each UNMAPPED file (generated files, locks, generators, shared content plumbing); queue the written revalidation task; dispatch a manifest task for each UNCOVERED or CHANGED_AFTER_CHECK system; and for INDEPENDENT_AUDIT run a read-only manifest audit on the other pool (template: `work/i9/stages/I9-11/fleet_compliance_11c/01-audit-11c.fresh.prompt`). Only when a problem cannot be settled that way: `waive <stage> "<KIND> <subject>" --reason ...`, and list it in the handoff.
- Stage close: `ops/seal_passmap.sh` runs `contract_manifest.py seal-check` first (registry check, merge check of the canonical backend since the base commit, export); the seal stops on any failure.
- After changing any `ops/contract_*.py`: run each tool's `--check` and `cd ops && ../.toolchain/bin/python3 -B -m unittest test_contract_workflow`. Prove a new rule against the live registry too (for example old vs new placements), not only against fixtures.

The queue also regenerates `tmp/fleet_contracts/CONTRACTS_CURRENT.md` (one line per contract with its systems column; UNRESOLVED marks a contract nothing places) and `CONTRACT_DOCUMENTS.txt` before every task, from the portable registry plus any UNREGISTERED canonical backend document. Workers search it for anything outside their manifest. Luna's broken calls are counted per task as `invalid_tool_calls` in `usage.jsonl`, with a WARNING line when nonzero, and `compactions` counts the worker's context compactions. Observed 2026-11-10 (session 517f63fc, the 11C audit): no empty-argument calls in the first 47 calls, then 21 of the 42 calls after a compaction failed with `{}` arguments (14 Read, 7 Glob), none grouped. The one-call rule does not prevent this; size Luna tasks to finish without compacting, and treat a task with `compactions` > 0 and invalid calls as suspect.

## Codex routes (user, 2026-11-06)
Codex workers draw on the user's ChatGPT login (cc-fleet provider `codex`), a separate allowance from OpenCode Go: a 5-hour window (about 15% of the weekly limit each) and a weekly limit. No peak hours, so the queue never waits for peak on these routes.
- `codex` = GPT-6 Luna: the extra-throughput worker. Use it for independent audits, checks of a DeepSeek part, and for any work while DeepSeek is at peak. Flash stays the default for volume: the user's measurements put Flash ahead on value.
- `codex-strong` is paused (user, 2026-11-06) until the user says the ChatGPT allowance has reset; use Luna for everything meanwhile. Luna is cheap: five minutes of a Luna worker spent about 2% of a 5-hour window.
- `codex-strong` = GPT-6.1 Sol: only for hard work (a lock-order or transaction design draft, a tangled defect). It spends a 5-hour window in 1.5-2 hours, so one queue at a time, and never routine work.
- Never use Astra (spends a window in 10-15 minutes) or Terra (no better than Sol for more usage).
- One tool call per message (measured 2026-11-10): cc-fleet 0.4.5's codex conversion delivers `{}` as the arguments of every tool call that shares a response with another (5493 of 5493 across 87 Luna sessions; 0 of 11625 single calls; DeepSeek 0 of 32796). Before the fix, 25-55% of Luna's calls in failed runs were these, and that is why its runs hit the turn and time caps. `fleet_queue.py` appends `CODEX_RULES` to the worker rules on codex routes; a probe after the fix made 4 calls with 0 errors. Do not remove it until a cc-fleet upgrade passes the same probe without the rule (`tmp/fleet_probe_onecall`). Size Luna caps for serial calls: about 1.5 times DeepSeek's turns for the same task.
- Effort is set on the provider (`cc-fleet edit codex --effort / --strong-effort`; currently xhigh), not by the queue. cc-fleet writes one profile file per provider, so a Luna and a Sol queue share whatever effort it holds.
- A spent window looks like `RATE_LIMITED` (HTTP 429) after claude's ~180 s of retries, not like a balance error. On a codex route the queue then sleeps 20 minutes and retries the same task, for up to `limit_wait_hours` (6) in a row, then fails with the error file. A task cut off mid-run by the limit restarts on retry; its prompt must tell it to check the worktree for its own earlier edits.
- These leads draw on the same ChatGPT allowance as a Codex lead session, so a Codex lead should run fewer codex queues.

## Flash only for DeepSeek routes (user, 2026-11-01)
DeepSeek routes run DeepSeek Flash and nothing else. The pins live only in `ops/fleet_models.json`; do not copy a model id anywhere else. The queue always passes its pin explicitly, so a cc-fleet default or TUI change cannot move a worker, and it stops if a transcript shows another model answered. Change a pin only on the user's word: `.toolchain/bin/python3 -B ops/fleet_models.py set <route> <provider> '<model>'` probes the model first and refuses contributor and free models. `ops/fleet_models.py check [route]` probes the pins. Optional pin keys: `peak` (false for Codex), `pool`, `limit_wait_hours`. The docs give each OpenCode model a monthly limit but never say whether use of one model draws down another's, so do not try other models to find out. Long sessions make them poor value anyway: 8D read 189M cached tokens, which is $0.57 on Flash and $36 on Kimi K2.7 Code. Never send project source to OpenCode's contributor models; they train on prompts.

## Which profile
- `slim-ro` (default): research, checking and anything during a strict gate. No Bash, Write or Edit, so it cannot build, test or wander. Does not load CLAUDE.md; the queue still sends the worker rules.
- An audit that must compare files (git diff, sha256), inventory a tree with a script or run the tests it cites needs `slim`, not `slim-ro`: the queue removes Bash on `slim-ro` (fleet_queue.py), and a `slim-ro` worker cannot write a report file either (the I9-10 registry scan, 2026-11-10, did 25 turns, no git, no REPORT.md). Give such a `slim` audit an explicit read-only rule, a scratch directory under `tmp/` for its script and a report file it updates after each item, record `git status` of the trees it reads before launch, and check them again when it exits.
- `slim`: implementation and focused tests, in the leaf's own worktree. Runs with skills and MCP off. It receives CLAUDE.md and the worker rules.
- `full` is not needed. It adds Claude Code's session prompt and no project contract. Thinking is already on in `slim` at effort high.
- Changing profile starts a new session by itself.

## Sessions
Tasks in one queue resume one session. Keep related tasks together; name a task `NN-name.fresh.prompt` when its sources are unrelated to what came before. A session never spans two leaves: each leaf's first task is `.fresh`, and written, cited findings carry forward instead of conversation. Inside a leaf, ledger, implementation and fix tasks resume, because that is where the cache pays; the check task is `.fresh`. Above `--rotate-context` tokens the next task starts fresh anyway. Use 150000 for research and 350000 for implementation: 8D's 712k cost 50% more per line than 8B's 313k with no visible quality gain.

Measured 2026-10-31: resume hits at once (7424 of 7602 tokens cached); a fresh session hits nothing, even seconds later with an identical prompt. DeepSeek documents unused cache as cleared "within a few hours to a few days", so no idle timeout is needed.

## Turn limits
80 for routine research. Raise it only for a complex task: about 300 for an implementation leaf, 400 for a wide research sweep. A task that hits the limit fails with `SUBAGENT_MAX_TURNS` in its error file.

## Peak hours (user, 2026-11-01)
Default: everything that spends model usage pauses during DeepSeek peak, 01:00-04:00 and 06:00-10:00 UTC, Monday to Friday by real time, and continues by itself afterwards. Time is not a constraint. Do not switch to Haiku or the lead session to keep moving.
- The queue waits by itself before each task on a DeepSeek route. A task already running finishes first. If the clock lookup fails it keeps waiting (it used to fail open: a 2026-11-03 check started at peak that way).
- Codex routes ignore peak. At DeepSeek peak, move independent audits and checks to `--route codex` instead of idling.
- Lead: run `.toolchain/bin/python3 -B ops/fleet_queue.py --wait off-peak` in the background and end the turn; its exit wakes you. Before long work near a peak, run `--wait peak` in the background the same way so its exit tells you to stop.
- Local jobs that spend no model usage, such as a strict gate, keep running. Still answer the user during a pause.
- `--allow-peak` runs a queue at peak; use it only when the user asks.

## Reading usage
`usage.jsonl` totals come from the worker's transcript, because the cc-fleet envelope covers only its last wake-up: one research task reported 2 turns and 194 thousand cached tokens where the transcript showed dozens of turns. Background commands are disabled in workers so the final answer is always the whole reply.

`turns` counts model replies; the envelope's `envelope_turns` runs about three times higher and does not fit the token totals, so ignore it.

Cost driver is turns times context, not cache misses. Five parallel fresh leaves, no limits (I9-8 research): 957 turns, 77.1 million cached, 1.03 million uncached, 284 thousand output. Five narrow tasks, one session, no Bash: 100 turns, 15.4 million cached, 234 thousand uncached, 93 thousand output, with 3.3 tool calls per turn. The last task alone read 6.1 million cached in 21 turns because it inherited 260 thousand tokens of unrelated context, so rotation dropped from 300 to 150 thousand. In order: narrow tasks with exact files and facts in the prompt, a word limit on the reply, `.fresh` when sources change, then rotation.

## Codex completion delivery (verified one-shot experiment, 2026-11-04)

For a Codex lead, add `--notify-codex-thread "$CODEX_THREAD_ID"` to the existing `ops/fleet_queue.py` command. After a nonempty queue finishes or fails, it releases its locks and sends one `codex queue --thread <exact UUID> --message <completion> --resume`. No model polling, new daemon or provider/model change. Empty queues send nothing, preventing empty-run wake loops. Leave the flag off for Claude leads; this does not change their workflow.

Installed Codex0.166.0 and its existing daemon delivered both a queued probe and a real two-queue batch completion to the same chat after the previous lead turn ended. This is observed support in this workspace, not a guarantee for a closed app/stopped daemon/other machine. The sidecar `codex_completion.json` records submission and warnings, never proof of delivery: CLIresume may warn while returning0. A notification failure does not change the worker result or retry the task. Read reports/errors and current lead state; a worker exit does not mean acceptance. Do not simultaneously start an external callback for a run already using this flag.

The queue remains the existing file-backed project scheduler around `cc-fleet subagent`, not a native cc-fleet workflow. In ccf AgentsBoard, this Codex session currently appears under `(no project)`; user confirmed its logs are visible there. No dispatch-method change required.


## Preserve Claude’s leaf workflow (user instruction, 2026-11-04)

Use the established leaf loop above and HANDOFF_LEAD_I9-9_ONWARD.md. Optimise lead attention as well as worker cache reuse. The user explicitly directs Sol and future continuations to preserve this workflow.

- Research and ledger first. Reuse accepted findings; investigate only real gaps. The lead resolves contracts, policy and dangerous boundaries, and commits the required foundation before runtime implementation is released.
- Delegate a coherent behavioral part, including the permitted owner adapters, handlers, projection/reload and focused proof. Avoid a separate job for each helper, DTO, compiler function or small test file. Small pure components can be reviewed together within the coherent part.
- Put multiple known-ready parts in the same stream queue when their prerequisites are already satisfied. Reuse the session and established context rotation. The queue finishes those tasks before delivering one completion notification; the lead reviews the batch. Do not queue implementation across an unresolved lead decision.
- Use realistic turn/time budgets for the scope. Historical complete parts often used 100–300 turns and 30–60 minutes. These are observations, not a required duration: do not pad work, delay completion or increase context merely to keep a worker busy.
- Use a fresh independent review for a coherent implementation part or batch, not automatically for each small pure helper. The lead verifies the report and handles small understood corrections directly; delegate substantial fixes with a concrete accepted findings list.
- The lead advances its own contract, transaction, lock, migration and composition work while workers run. Do not let a sequence of tiny delegated tasks substitute for completing those prerequisites.
- Keep the existing maximum of three independent streams. Do not parallelise closely related leaves or duplicate research. Preserve own worktrees, model pins, peak scheduling, context rotation and the three-failed-run stop rule.
- Keep exact evidence, focused native/VC requirements and stage gates. Batch dispatch does not batch-approve work. Only the lead accepts work or closes a leaf, and explicitly reports the leaf name when closed.
- Checkpoint at meaningful recovery and leaf milestones, following the standing research/checkpoint rules. Do not add a checkpoint for every routine edit or queue item. Existing mandatory checkpoints still apply.

Evidence comparison: work/i9/stages/I9-10/evidence/lead_onboarding/FLEET_BATCHING_ASSESSMENT.md. Operational task state stays in the existing LEAD_STATE.json, not in this guide or a new index.

## Lead-owned prerequisites must advance (user correction, 2026-11-05)

After adjudicating a worker, implement the highest-priority actionable lead prerequisite or release a ready dependent batch. A reserved idle slot is not progress. Do not replace transaction/contract/composition work with repeated research, status checks or checkpoints. Make authorized decisions, write production code, verify focused regressions, then delegate the coherent remaining work. Keep independent review and mandatory qualification; use the existing completion callback. A concrete unresolved protected decision may pause only its affected path.

## OpenCode one-shot (ops/opencode_dispatch.py)

A second, simpler dispatch path: one prompt file, one native `opencode run` (CLI v2.4.2 at
`/home/akm/.opencode/bin/opencode`). No queue, slots, sessions, contract manifest or compliance check. Use it for
self-contained tooling or research where the caller already owns the prompt and reads the result itself; the queue
(`ops/fleet_queue.py`) remains the path for contract-bound product work.

```sh
.toolchain/bin/python3 -B ops/opencode_dispatch.py \
  --model <provider/model> --cwd <dir> [--label <text>] [--timeout 3600] \
  [--out <dir>] [--background] [--allow-free] [--ignore-peak] <name>.prompt
.toolchain/bin/python3 -B ops/opencode_dispatch.py --status <name> [--out <dir>]
```

- The prompt file is sent as the message with `ops/FLEET_RULES_WORKER.md` prepended, exactly as a fresh queue
  session receives it. The model is `--model` in `provider/model` form (see `opencode models`); `--cwd` is required
  and must be inside the workspace.
- Output lands beside the prompt (or in `--out`): `<name>.result.md` is the final assistant message,
  `<name>.events.jsonl` the raw `--format json` events, and on failure `<name>.error.json` with `error_code`
  `TIMEOUT`, `EXIT_NONZERO`, `NO_RESULT` or `MODEL_REFUSED`. Exit 0 only on success, 1 on task failure, 2 on a usage
  error (missing prompt, missing `--cwd`, cwd outside the workspace).
- `--timeout` is wall-clock (default 3600 s); on expiry the whole process group is killed.
- `--background` detaches, writes `<name>.pid` and returns at once. `--status <name>` reports `running`, `done` or
  `failed` from the pid/result/error files.
- Model policy is enforced in code: ids containing `contributor` are always refused (they train on prompts); ids
  ending in `-free` require `--allow-free` and print that free tiers may log prompts; a DeepSeek model is refused
  during peak hours (01:00-04:00 and 06:00-10:00 UTC, Monday-Friday) unless `--ignore-peak`. Peak time comes from the
  `Date` header of a HEAD request to `https://api.deepseek.com`; if that is unavailable the system clock is used with
  a warning, because it may be forwarded.
- This path does not check `Contract-Systems`, build or verify a contract manifest, resume a session, rotate context
  or run `Post-Check`. Those stay with `ops/fleet_queue.py`.

Regression tests: `cd ops && ../.toolchain/bin/python3 -B -m unittest test_opencode_dispatch`.

OpenAI models (`openai/gpt-6.x-*` in `opencode models`) draw on the owner's ChatGPT/Codex usage window, which Sol shares. Use them only for hard review or design work, or while DeepSeek is at peak. Never use them for volume work. Owner note, 2026-11-27: OpenCode's event-driven completion avoids the shell-polling waste seen under the official Codex CLI.
