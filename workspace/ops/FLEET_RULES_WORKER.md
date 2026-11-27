# Rules for every worker session

The queue sends this file at the start of every fresh session. It is the worker's digest of RULES.md (AGENTS.md links there) and work/RULINGS.md. If they conflict, RULES.md and the lead's decisions in your task win; report the conflict. You do not need to open RULES.md unless your task names it.

The project rebuilds the server of Girls X Battle 1 (not GXB2) as a Go modular monolith. The stock Lua client is not changed, so the server has to fit what that client actually reads.

## What counts as truth
- The client source under `tmp/virtualclient/src_64` decides wire shapes, units and callbacks. Contracts decide policy. A research note or design file only tells you where to look: open the source it cites before you write code from it.
- A finding inherited from an earlier leaf or an index is also only a pointer. Before your conclusion depends on it, open the primary source it cites. If it is wrong, write `CORRECTION:` with the file and line that show it. Carry an inherited UNKNOWN forward as UNKNOWN until a source settles it.
- Contracts reach you mechanically. A task that touches systems arrives with a **contract manifest** above the task text: every contract the stage's portable registry binds to those systems, with id, status, the reason it applies, document path and pinned sha256. Every manifest row binds you, whether or not the task text names it. Read the document of each row whose reason touches what you change, with the Read tool. If a contract conflicts with your task, stop that part and report the conflict.
- End every report of a task that has a manifest with a `## Contract compliance` section: one row per manifest contract, `id | verdict | evidence`. The verdict is APPLIED, with the server file:line that implements it (not a test file) and the test that proves it (an existing `_test.go` file:line or the `TestXxx` function name); NOT_APPLICABLE, with one sentence naming what your task does not touch; or CONFLICT, with the clause and what contradicts it. The queue checks this section against the manifest, your tree and your transcript. A missing row, an APPLIED row without an existing implementation file:line or an existing test, or an APPLIED or CONFLICT contract whose document you never opened fails the task, and you get one chance to correct it.
- The manifest lists contracts by system. For anything outside it, search the whole registry at `/home/akm/Chatgpt/EOL_Game/tmp/fleet_contracts/CONTRACTS_CURRENT.md` (its systems column gives the lookup; UNRESOLVED means no system is assigned yet), for example `xargs grep -l -w 'MID 241' < /home/akm/Chatgpt/EOL_Game/tmp/fleet_contracts/CONTRACT_DOCUMENTS.txt`. A matching contract binds you; add it as a row and say how you found it. Report every row marked MISSING_DOCUMENT or UNREGISTERED that you meet.
- Never edit a registered contract document. A new or amended contract you write in your tree's `docs/` is registered by the lead's merge check, which marks it for review. A contract counts by the id it declares, never its file name: JSON declares `contract_id` (or `policy_id`), Markdown starts with a `Contract-Id: <id>` line (without it a Markdown file is research, not a contract). Never give a new contract the id or file name of a different contract. Say in your report which contract files you added or changed.
- Frozen V1 is a second opinion, not the original server's behaviour.
- Never invent a mechanic, formula, ID, owner, wire shape or success reply. If the source does not settle it, write UNKNOWN in your report. Policy gaps go to the lead.
- Source existing does not prove it is reachable, and a missing definition does not prove a feature is dead.

## Reading
- Find with Grep, then read the whole unit you depend on: the whole function, the whole Lua callback and the model method it calls, and every caller of what you change. A file under about 800 lines can simply be read whole. Reading enough is cheaper than a defect.
- When the tree has `docs/architecture/system_map/`, read its README first. Use it to find who owns what and what calls what, and run `tools/system_map.py trace <mid>` when you have Bash. It points; the code decides. Say in your report when it misled you.
- Send independent reads and greps together in one message, unless a Codex route section at the end of this message says otherwise. Use Read and Grep rather than printing files through Bash.
- Read again when a file changed or you are about to edit it. Otherwise reuse what is already in this conversation.

## Architecture
- One durable owner per fact, with no SQL against another owner's tables. Reuse the existing owner, port or family shape instead of building a parallel one.
- Projections, caches and queues are not gameplay authority. Keep identity categories distinct.
- A component nobody calls does not exist. After adding an owner, route, provider or reconcile step, open the production composition root (`cmd/`) and confirm it is registered there.

## Build the least that fully works
- Every contract item is required. Size never justifies cutting client compatibility, lock order, recovery, validation or a proving test.
- Before adding a package, port, type, helper or table, grep for the owner or shared core that already does it and use that.
- Copy a sibling family's shape, not its code. Logic that is the same across families and longer than about 10 lines goes into the shared core when the contract allows; otherwise name the copy in your report.
- No option, wrapper, port or abstraction without a present need. An interface needs a second implementation or a real boundary. Delete what you stop using.
- Session-start text about process skills does not apply: these rules and your task are your workflow.

## Client-facing work: start from the window, not the server
Any task that touches a menu, window or feature the player sees starts with an inventory of that window, before any code:
- Establish how the window works: open its Lua, the sibling and child windows and popups it opens, and the model methods behind them. List every request it sends, every push or notice it listens for, every reply field it reads, every popup, toast, tip and text key it can show, every timer or countdown, and every client table row it reads.
- Work outward from what the client can display. For a log, history, feed, board or ranking, first list every entry type, tab and text key the client can render (the predefined texts live in the client tables), then find the game event that must produce each one. Never start from the server code you happen to touch and stop when that part works.
- Anything the window can send, show or listen for that the server never answers or produces means the feature is incomplete. Stock menus have no unused features. List each item as served or unserved in your report; an unserved item is a finding, not optional.
- For every item ask how the original server most likely handled it: after each action, what does the client expect to arrive (a reply field, a push, a refreshed model) so that the window updates without reopening? A window that refreshes only after reopening is a missing push or reply field. A counter that is always 0 or a time that is always 0:0 is a field the server never fills.

## Every reply a client can receive
- Before writing it, open the client Lua callback and list the field paths it indexes. The client treats any HTTP 200 as success, so a callback indexing a nested table crashes on `200 {"error_code":N}`. Every refusal goes through the R4 mapper in `internal/adapters/stockruntime/failure.go` (`failureReply`, `classifyFailure`; `malformed()` for 400): a permanent refusal is HTTP 409 with a D5 code from `work/i9/stages/I9-11/contract_recovery/D5_REFUSAL_CODES.md`, a transient fault 503 + 35033, a defect 500 + 35028. The callback gets ERROR and the toast still shows. Never hand-build a refusal body.
- Units and types come from the Lua, not from the name: absolute or fraction, array or object, number or string, wrapped or sibling.
- The field paths the client reads are generated in `internal/protocol/replyconformance/reply_consumers.json` by `tools/reply_consumers.py` (never hand-edit it; regenerate with `--write` when a reply changes). The HTTP edge checks every 200 reply against it and the strict gate turns any `reply_conformance_violation` log line RED, so a missing REQUIRED path fails the gate. An UNKNOWN row is unchecked, never call it checked.

## Every transaction
- Check the lock order in your task on each transaction, including the second one of a multi-step flow, and write facts prepare before grants.
- Every list or scan is bounded and scoped to the logical server.
- After an unknown commit, do not compensate. A read path never advances shared time-driven state.

## Every test
- Build through the same constructor production uses. A hand-wired router, canned report or pinned revision proves nothing about production.
- Assert the value, not that it exists: `force != nil` passes on a force of zero.
- Anything with a retention, purge or reconcile promise has a production caller. Grep for it.
- Never weaken an assertion, drop a test or add a mock to get green.

## Before you call writing work done
Run these and paste the tail of each:
- `go build ./...` and `go test -count=1` of every package you changed (unit packages whole; integration packages with `-run` naming the tests your task touches, `-v`). A single command must finish inside your 10-minute command limit: split by `-run` rather than backgrounding it.
- `go vet -tags "postgres river"` on the packages you changed, and `gofmt -l .`
- The native and virtual client commands your task names, with `-v`. Count PASS; a SKIP is not a pass.
- Natives use your own PostgreSQL cluster when the queue gives you one: build every DSN from `$GXB_TEST_PGHOST` and `$GXB_TEST_PGPORT` (`ops/testing/fresh_db.sh` already does; `ops/TESTING_GUIDE.md` lines 9-17). Never hard-code port 55853 or another worker's cluster.
- Never start `tools/gate_preflight.py`, a whole-tree `go test ./...` or any command in the background (`&`, `nohup`, `setsid`). When your task has a `Post-Check: preflight` line, the queue runs the preflight after your reply and sends you its RED lines; a new test variable, an unlisted skip or a test that fails only beside its package neighbours is then your work to fix. Anything you leave running is killed when your reply ends.

If your session has no Edit tool, or your task forbids builds, skip these and report findings only, each with file and line.

## Report
For each task item give one row: status, server file:line, client Lua file:line (or `no client reply`), and the test that proves it through the production path. An item with an empty cell is not done; say which cell and why.
- Never write "pre-existing" or "unrelated" about a failure without running the same test on the base commit named in your task and pasting that result. If it passes there, your branch broke it and fixing it is your job, including a guard test that must learn a new legitimate route.
- Say what you did not run. Do not summarise a test you did not read.
- Follow the reply length your task sets. The catch-up section below comes on top of it.

End every report with `## Catch-up`, at most 15 lines, for a reader who saw nothing of this session. It points; it does not retell:
- Read first: the 3 to 5 file:line places where a mistake would do the most harm.
- Choices: what you decided that the task did not settle, and what you rejected.
- Not proven: what you did not run, gaps and UNKNOWNs.
- Recheck: branch, commit and the exact commands that reproduce your result.

Do not explain how the system works there; the code already shows that.

## Boundaries
- Stay inside the worktree, branch, `tmp/` directory and database prefix your task names. Never touch the canonical tree, `work/authority_*`, `inputs/`, `checkpoints/`, `outputs/` or `work/i9/passmap/inputs`. The one exception is reading, never writing, the contract documents that the registry index lists.
- Do not seal, checkpoint, merge or push. Commit only to your own branch, and only if your task says to.
- End every commit message with your pool's trailer, never Claude Code's default `Co-Authored-By: Claude Code` line, which names no pool and blocks the merge: DeepSeek routes `Co-Authored-By: DeepSeek <noreply@deepseek.com>`, Codex routes `Co-Authored-By: Codex Luna via cc-fleet <noreply@openai.com>`.
- Never read or send credentials, API keys or tokens, and never open `~/.claude` or `~/.ssh`. `inputs/Supplimental_Materials` may be read and is never executed.
- Use `.toolchain/bin/python3 -B` for Python. Kill by pid only, and only processes you started. Do not poll with sleeps.
- After the same failure survives three runs, stop and report it. Read `ops/TESTING_GUIDE.md` section 3a before a virtual client scenario.

## Code style
No abbreviated names, no narrative comments, flat control flow with early returns, gofmt, no orphan code. Mark a known limit with `shortcut: <the limit>, <when to upgrade>`.
