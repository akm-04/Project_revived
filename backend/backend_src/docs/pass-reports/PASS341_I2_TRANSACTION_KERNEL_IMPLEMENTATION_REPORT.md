# Pass341 — Implementation Wave I2: PostgreSQL Transaction Kernel

## Result

**PASS / ACCEPTED.** Pass341 implements the frozen Pass337 I2 transaction-kernel wave without wiring PostgreSQL into live gameplay, changing JSON canonical authority, modifying the Pass340 client/runtime authority, retiring the global request RLock, or widening workers.

## Transaction boundary

- Added `ResourceTransactionCoordinator`: exactly one SQLAlchemy connection/database transaction per attempt.
- Operations declare all resources before mutation; the coordinator canonicalizes them using the frozen universal resource order and registry-driven row lockers. No generic lock table was invented.
- Whole-operation retry is bounded and default-deny. Only explicitly retry-safe operations are replayed after PostgreSQL serialization/deadlock classes (`40001`, `40P01`) or configured state-version conflicts. A retry reacquires every lock and opens a fresh transaction.
- Stable semantic inputs (`started_at` and deterministic randomness seed) are retained across internal retries. External effects remain staged until the database transaction commits.

## Durable kernel primitives

- `operation_receipts`: semantic idempotency identity, SHA-256 request fingerprint, result replay, and uniqueness on the semantic receipt key.
- `outbox_events`: durable postcommit intent rows, delivery class/priority/expiry, `SKIP LOCKED` claiming, claim ownership, stale-claim recovery and bounded failure metadata.
- `scheduled_jobs`: deterministic dedupe key, PostgreSQL-clock due selection, `SKIP LOCKED` claiming, lease ownership/expiry, retry/dead/success lifecycle and attempt accounting.
- Reusable `state_version` conditional-update helpers convert zero-row optimistic updates into an explicit conflict instead of a silent overwrite.

## Alembic boundary

Revision `0002_pass341_i2` creates only `gxb.operation_receipts`, `gxb.outbox_events`, and `gxb.scheduled_jobs`, with constraints/indexes supporting their transaction semantics. It does not create I3 identity/session/context/region/player authority or I4 PlayerState tables.

## Validation

- 39/39 I2 tests PASS.
- 34/34 I1 tests PASS.
- 19/19 I0 foundation tests PASS.
- 92/92 combined tests PASS.
- 14/14 unchanged controlling historical regressions PASS using bounded harness segments.
- Pass340 restart/auth replacement regression PASS.
- Pass341 I2 invariant guard PASS.
- `compileall` PASS.
- Exact bundled SQLAlchemy 2.0.52 / psycopg 3.3.5 / Alembic 1.19.1 modules were exercised in the sandbox without opening a database connection; psycopg exception classes confirmed `40001`/`40P01` retry classification and `23505` non-generic retry behavior.
- No PostgreSQL daemon, URL, probe, startup, or connection was attempted.

## Concurrency/fault model

Mocked/process-model tests cover same-player serialization, unrelated-player concurrency, overlapping shared-resource ordering, identical canonical lock plans across processes, transaction retry from the beginning, state-version conflicts, receipt replay/fingerprint mismatch, outbox flush rollback/retry, stale claim recovery, scheduled-job lease reclaim and deterministic dedupe.

## Preservation result

All 495 Pass340 gameplay/client/runtime-authority files remain byte-identical, retaining runtime root SHA-256 `d90e6b6e73bf1bebb760a51762191e04e6d53ff55065e125cd1c989736e176f1`. `StateRepository`, `MultiUserDatabase`, `EngineDispatcher`, the global RLock, and the I1 Lua patch are unchanged.

## Deferred exactly as frozen

I3 owns relational account/session/context/region authority and real credential issuance. I4 owns PlayerState JSONB strangling. I5 owns RealtimeGateway/outbox consumption. I6 owns SchedulerWorker execution. Global RLock retirement and worker widening remain I9.

## Next

Pass342 / Wave I3 — Identity / session / context relational authority — is next and remains separately authorization-gated.
