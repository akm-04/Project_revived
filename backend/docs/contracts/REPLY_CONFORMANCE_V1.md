Contract-Id: REPLY_CONFORMANCE_V1

# REPLY_CONFORMANCE_V1

Reply conformance seam (CLOSURE_DESIGNS C3, rules 2-5), amended by REPLY_CONFORMANCE_EDGE_V1 rulings 1 and 6.
Scope: every successful stock HTTP reply the gxb-api serves. The stock client
(`tmp/virtualclient/src_64`) decides wire shape; this contract decides the obligations and their enforcement.

## R2 Obligations

- `tools/reply_consumers.py --source-archive ZIP (--write | --check)` extracts, for every MID the client sends,
  each reply callback's field paths (`a.b`, `a.list[].c`), each marked guarded or unguarded. A callback that
  cannot be resolved is listed UNKNOWN with the reason, never guessed.
- Every unguarded path is REQUIRED. A false positive, or a path required only on one client branch, goes in
  `docs/architecture/reply_consumers/WAIVERS.json` with a reason and the client file:line that shows the guard or
  the branch; the tool refuses a waiver without both.
- `--write` regenerates `docs/architecture/reply_consumers/REPLY_CONSUMERS.json` and the go:embed copy
  `internal/protocol/replyconformance/reply_consumers.json`; `--check` fails on drift.
- Every MID the gxb-api dispatcher table serves is present in the generated document. A served MID for which the
  stock client has no request site is a row with `"status": "UNKNOWN"` and a reason.
- Coverage is reported honestly: UNKNOWN rows are reported separately and are never called checked.

## R3 Runtime check

- The check runs at one site: `internal/protocol/httpedge` `Handler`, once per request, after the routed
  dispatcher returns and before the reply is written. It therefore covers every registered MID, including those
  registered before `Router.Wrap` is set. `stockruntime.Decorated` performs no conformance check.
- Only a successful (HTTP 200) reply built from `Body` or `JSON` is checked. A `Raw` reply (R6 replay of committed
  bytes) is not re-checked, and no failure reply is checked.
- A missing or JSON-null REQUIRED path is logged `reply_conformance_violation mid=... path=...` and counted in a
  metric. The reply is never altered: the bytes sent are identical with and without the checker.
- A REQUIRED path under a list is checked on each element present; an absent optional parent follows the parent's
  own requirement. A parent-table guard in the client is not a leaf guard (REPLY_CONFORMANCE_EDGE_V1 ruling 4).

## R4 Test helper

- `replyconformance.Check(t, mid, body)` (package `internal/protocol/replyconformance`) fails the test when a
  successful reply lacks a REQUIRED path or sends JSON null at one.
- A task that adds or changes a MID reply adds `replyconformance.Check` to that MID's test.

## R5 Enforcement for future work

- archguard `TestEveryServedMIDHasReplyConsumers` fails when a MID the dispatcher table serves has no
  REPLY_CONSUMERS row, and when an UNKNOWN row carries no reason. It reports UNKNOWN rows separately and never
  counts them as checked (REPLY_CONFORMANCE_EDGE_V1 ruling 6).
- `tools/strict_gate.py --api-logs DIR` scans the e2e/VC gxb-api logs after the suites. Any
  `reply_conformance_violation` line makes the gate RED; zero lines is required.
- `ops/FLEET_RULES_WORKER.md` (lead edit) carries the standing task rule from R4's second bullet.
