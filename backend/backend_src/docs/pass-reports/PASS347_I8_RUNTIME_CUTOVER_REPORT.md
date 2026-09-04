# Pass347 I8 Runtime/Cutover Report

Status: **PASS — I8 implementation complete; I9 remains closed**.

Pass347 packages and proves the frozen single-host production runtime. Plain
nginx fronts exactly one Gunicorn `gthread` worker; dedicated Python processes
own realtime sockets and scheduled/projection work. PostgreSQL owns relational
identity/session/context/region/account-global/mail/receipt/outbox/job state and
the mature PlayerState aggregate as versioned JSONB. The mature Python gameplay
core remains intact and the process-global request `RLock` remains enabled.

## Runtime authority and cutover

Alembic head `0008_pass347_i8` adds a singleton `runtime_authority` row. Cutover
preparation requires a `VALIDATED` migration run, non-empty accounting,
credential retirement, an immutable JSON archive, I7 backup/restore/WAL/PITR
evidence, source/client readiness, maintenance mode, stopped JSON writes, one
HTTP worker, and the retained lock. Opening traffic requires the exact phrase
`OPEN POSTGRESQL TRAFFIC PERMANENTLY`.

Database triggers forbid reverting either the runtime authority or its migration
run after `TRAFFIC_OPEN`; Alembic downgrade also refuses. The legacy JSON app
launcher refuses to start after open and also refuses when PostgreSQL is
configured but unavailable, preventing an outage from becoming authority
rollback. There are no dual canonical writes.

## Runtime wiring

- Account MID18/MID1 uses account session credentials; ordinary HTTP and raw
  TCP admission use the context-bound gameplay credential. Caller region is a
  consistency fence, never actor selection.
- One outer `ResourceTransaction` holds deterministic session/context/account-
  global/player/mail locks while the mature `PlayerUnitOfWork` mutates one
  hydrated JSONB aggregate. Optimistic `state_version` is preserved.
- Committed gameplay realtime intents are translated into the PostgreSQL outbox
  before the outer transaction commits. LISTEN/NOTIFY is wakeup only; polling is
  the correctness path.
- Relational mail preserves source compound `(is_region,id)` identity and the
  separate `normal_ids`/`region_ids` one-key contract. Only validated positive
  item attachment rows are settled; unknown shapes fail closed.
- Scheduler and projection lanes are supervised now. No autonomous gameplay job
  type is active in this bounded foundation, so unknown rows follow existing
  retry/dead or release policy rather than receiving invented handlers.

## Validation

The complete offline suite passed 280 tests with five PostgreSQL tests skipped;
the full live suite passed all 285 tests. A freshly rebuilt PostgreSQL 16.15
candidate upgraded through all eight revisions, imported and validated the
packaged representative state, then exercised irreversible cutover. Stock-like
SDK anonymous, MID18, MID1, MID17, relational mail list/read/claim, health,
actual Gunicorn startup, RealtimeGateway bind/start/stop and Scheduler/Projection
idle startup all passed. Database reversal and post-open legacy JSON restart
were both blocked.

The provided archive contains no actual operator `data/server_state`. The live
cutover proof therefore used the packaged representative singleton, with source
content root `62370df8770eea6883f6670470dd47067c03bf8a20aa27a367f0bc6e63628116`.
An actual deployment must repeat inventory, immutable snapshot, I7 migration,
backup/restore and cutover evidence against its own quiesced state. This is an
operator precondition, not a hidden claim that a production database was opened.

## Coherence repair

Pass346's stage-validation JSON recorded 273 offline tests, while one prose line
said 276. Recounting the unchanged Pass346 baseline produced 273; the prose
number was a clerical typo. Pass347 records the correction without changing I7
technical evidence.

Next is Pass348 I9: prove concurrency and crash semantics first, then retire the
global `RLock`, then widen Gunicorn workers gradually. I8 itself does not claim
that multi-worker safety has been proven.
