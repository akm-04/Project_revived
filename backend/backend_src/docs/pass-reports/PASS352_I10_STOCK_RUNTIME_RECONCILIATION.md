# Pass352 — I10 stock-runtime reconciliation candidate

## Runtime evidence

The supplied support bundle shows one migration run already at `TRAFFIC_OPEN`. `alpaca123` entered region 194/player 19425386 while the preserved migrated mapping remains region 197/player 19700001. A fresh registration returned MID1 detail 49 with an empty Hero map; the tutorial source contract requires Aquarius to be owned before the Lavia/Pandaria guide pulls. Resource discovery was configured as `.../local_assets/res/res` with no effective roots, and the required 1.631.1 initial update barrier remained unpublished.

## Candidate repairs

- Shared durable PlayerState normalization is now used by PostgreSQL fresh aggregate materialization and load-time repair. Fresh skill points are initialized before materialization; Aquarius is seeded by the existing SummonRepository tutorial normalizer.
- Portable static root is `local_assets`; backend config derives current resources as `local_assets/res` and old donor resources as `local_assets/old_res`.
- SDK login re-runs account-scoped MID18 even when the device has a cached region. One owned character is unambiguous; multiple regional characters require explicit selection. No cross-region move, clone, merge, or payload rewrite is performed.
- Workspace wrapper v6 clears operational logs on update and adds manifest-verified PostgreSQL backup/restore. Legacy JSON migration remains explicit one-shot history and is never invoked by update/restore.

## Validation

- controlling I3/I4/I10: 88/88 PASS
- broad non-integration: 307/307 PASS
- compileall: PASS
- Pass352 invariant verifier: PASS
- portable package verifier: PASS
- stock runtime: PENDING

## Stock gate

Update the preserved TRAFFIC_OPEN workspace without wipe/remigration. Verify OTA after clearing client data, explicitly select region197 for `alpaca123` if MID18 reports multiple regional characters, verify migrated progress, verify Aquarius exists immediately on a genuinely fresh account, and re-run the Pass351 `payload=nil` / overlapping-MID1 lifecycle smoke. Capture a fresh support bundle on any contradiction.
