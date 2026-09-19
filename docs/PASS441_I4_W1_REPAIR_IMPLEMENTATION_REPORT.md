# Pass441 — I4 W1 Repair Candidate / Reseal Report

Status: **READY FOR FRESH W1 RETEST; I5 BLOCKED**
Version: **v0.40.1**
Pass: **441.0**
Milestone: **I4 repair line**
Candidate source commit: `5708b844f7a41f7f85eb6591332668282773fa8c`

## Why Pass441 exists

The first Work-mode execution of sealed Pass438 correctly returned **W1 RED**. Its evidence archive SHA-256 is
`405e7250f7f5535e152520d33825455cf46e33c90385cbbfe9e6925b27b1e781`.
The failures were not waived and I5 was not opened. Pass439 and Pass440 repaired the reported implementation/reproducibility seams; Pass441 freezes those repairs as a fresh exact candidate for W1.

## W1 findings closed before reseal

### Critical exact-candidate blockers
1. **Incomplete tagged dependency closure / `go.sum`** — repaired with the exact Go 1.27.1 W1-resolved direct+indirect module closure and content sums.
2. **Missing `lobby.NewBootTracker`** — constructor added and guarded.
3. **Goose parsing of migrations 00003/00004** — compound DO blocks are bounded by `StatementBegin/StatementEnd`; migration 00004 has explicit `-- +goose Up`.
4. **River package mismatch** — adapter package declarations consistently use `riveradapter`.

### High release-quality gaps
5. **sqlc generation was not reproducibly clean** — I4 now generates sqlc output only into the sibling scratch artifact directory `../gxb-v2-sqlc-generated`; source/query SQL remains canonical and the candidate tree must remain byte-clean. W1 must execute sqlc 1.31.1 and retain generated evidence.
6. **Dependency/license/SBOM closure stale/incomplete** — the resolved module closure, River v0.47.0 notices/review, SPDX packages and `DEPENDS_ON` relationships are synchronized and mechanically checked.
7. **Pre-W1 validators missed connected candidate blockers** — `tools/check_connected_candidate.py` now rejects the classes above statically and has a W1 `--execute` mode for exact Go 1.27.1/tagged-build/sqlc proof.

### Medium audit/instrumentation gaps
8. **Ambiguous-COMMIT absence→retry discarded reconciliation history** — `tx.Result` now retains reconciliation history across an authorized retry; regression test added.
9. **API/realtime Wave-S trackers were process-local islands** — optional run-scoped JSONL evidence plus `cmd/gxb-wave-s-report` now composes both processes into one boot/quiescence report without changing stock protocol behavior.

## Active-oracle cross-check

The repaired tree was re-run through the pinned current-source/V1 differential suite after the runtime changes. Current `src_64` remained green for I2/I3/I4 facts including MID18/MID1 identity/bootstrap, MID1 stock hydration and sidebands, MID192/TCP login/room-entered/heartbeat/reconnect behavior, MID1304 array semantics and Lua truthiness. Pass353 corroborated only the bounded differential/mechanism facts.

No new implementation evidence conflicts with the frozen Wave-S/I3 authority model. Therefore no design-wave reopening was necessary. If W1 finds a new stock/source contradiction, targeted research remains mandatory before changing a frozen contract.

## Normal-chat evidence boundary

Before raising the module floor, Pass440 passed the full local source/static/ordinary/race gate under Go 1.23.2 compatibility; evidence is preserved in:
- `EVIDENCE/PASS440_REPAIR_FULL_CHECK.txt`
- `EVIDENCE/PASS440_REPAIR_RACE_CHECK.txt`

Pass441 then changed `go 1.23.0` to the W1-resolved `go 1.26.0` and retained `toolchain go1.27.1`. The current normal-chat Go 1.23.2 cannot honestly execute that exact module, so Pass441's post-floor normal-chat checks are deliberately static/source validators only. Exact executable proof is the first step of the fresh W1 retest.

## Scope

No I5 domain was implemented. Player Core, deep Social, Combat, Commerce, gameplay modes and operator-control work remain blocked. V1 remains an oracle only.

## Gate

**Pass441 is not a claim that W1 is green.** It is the repaired exact I4 candidate that must now pass the complete W1 checklist. I5 remains blocked until the returned W1 evidence has zero blocking findings and all frozen Wave-S criteria pass.
