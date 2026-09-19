# Pass493 I6A Implementation Sequence / Recovery Checkpoint

Base artifact: `gxb-backend-v2-v0.56.0-pass487-r6-phase-accepted-r7-ready.zip`
Base SHA256: `65d5296b033b3c292975648428bf50b2cb7b24662d49e1b3fa45740b9f12a634`
Authority: sealed Pass492 HOT/CURRENT + `PASS492_I6A_IMPLEMENTATION_CONTRACT.json`.

Lifecycle: I6A IMPLEMENTATION in progress. This file is a recoverability checkpoint, not phase acceptance.

Implemented:
- I6A-1: typed GenerationID / OccurrenceID, authority scope, GenerationRef / OccurrenceRef / TransitionRef; no universal phase or gameplay aggregate.
- I6A-1/2: immutable TimedOperation binding preserving operation.Context StartedAt semantics; PostgreSQL `SELECT clock_timestamp()` supplies durable decision time and invalid operations fail before DB time sampling.
- I6A-2: TimedRunner composes authoritative-time binding with the accepted tx.Runner. One TimedOperation is reused across definite-abort retries, UNKNOWN-COMMIT reconciliation, and any explicitly authorized replay after authoritative negative proof. Foundation UNKNOWN-COMMIT policy is not weakened or duplicated.
- I6A-3: application fail-closed obligation dispatch registry. River uses one static mechanism kind `gxb_obligation`; semantic obligation kind/profile remain immutable application evidence. Exact River v0.47 worker/runtime composition is adapter-only behind build tags.
- I6A-4: bounded owner reconcile registry/kernel with one DB-authoritative decision instant per sweep and fail-closed empty/invalid provider behavior. Fixture-owner tests cover early delivery, duplicate convergence, stale generation no-op, restart, missing/discarded wakeup recreation, and no tick replay.
- I6A-5: architecture guards prohibit application generation wall-clock/mechanism imports, universal generation phase type, and nontransactional obligation enqueue.
- I6A-5: narrow candidate-bound source-oracle guard freezes verified current/historical Lua hashes and reload/time source shape without inferring reachability or universal reset semantics.
- I6A-5: kernel time tests explicitly cover backward database-clock discontinuity without silent monotonic clamping; the shared core leaves owner-specific backward/forward policy to the owning milestone.

Current proof state:
- Exact canonical pins remain untouched: go 1.26.0 / toolchain go1.27.1 / .go-version 1.27.1.
- Exact pinned-toolchain execution is environment-blocked in normal chat because the local Go is older and outbound toolchain/module acquisition is unavailable.
- Compatibility-copy evidence must be regenerated from the newest checkpoint after each product change.
- Real PostgreSQL/River gate remains mandatory before I6A phase acceptance.

Still pending:
- fresh checkpoint3 compatibility-copy focused/race/vet/full regression after TimedRunner addition;
- independent candidate reality check against D07/D10/Pass417/Pass465 and source evidence;
- native PostgreSQL/River Work-mode evidence bundle and exact-candidate gate execution;
- evidence classification + PassMap lifecycle sync/seal only after those controlling gates pass.

No GXB migration 00012 has been added. No feature-specific reset/calendar/Activity/Guild mechanic has been implemented.
