# Pass346 I7 Migration/Rehearsal Report

Status: **PASS — I7 complete; I8 remains closed**.

Pass346 implemented the frozen Pass334/337 offline JSON-to-PostgreSQL migration and recovery rehearsal without changing gameplay behavior or runtime authority. JSON remains canonical, the legacy process-global `RLock` remains enabled, one-worker/multi-worker policy is unchanged, and no code path performed `TRAFFIC_OPEN`.

## Implemented

- Strict read-only `server_state` parser with duplicate-key rejection, exact login/ownership index reconciliation, path/metadata/payload identity checks, region-encoded player-ID validation, and source-stability detection.
- Byte-copy immutable snapshot with no symlinks/hardlink shortcut, mode-0600 per-file manifest, SHA-256 content root, and manifest digest.
- Account/password-verifier, region allocator, player JSONB, account-global, receipt, and mail import into an empty disposable PostgreSQL candidate.
- Intentional retirement of every legacy SID/token/session/context credential.
- Forward-only account/region allocator lifts and deterministic missing/colliding mail-ID remaps with audit evidence.
- Pure `PlayerPayloadCodec` extraction/reconstruction validation, including opaque claims and unknown extensions.
- Durable `migration_runs` state machine at Alembic head `0007_pass346_i7`; I7 exposes no traffic-open transition.
- Redacted machine reports, custom-format `pg_dump`/single-transaction `pg_restore` wrappers, and an operator runbook.

## Rehearsal evidence

The release intentionally contains no operator `data/server_state`. Two bounded sources were used:

1. Packaged singleton `data/player_db.json`: 1 account, 1 player, embedded bearer retired, exact migration/adapter validation passed.
2. Representative Pass299-format state generated through the current Pass345 backend: 3 accounts, 4 players, 3 legacy sessions, 2 PBKDF2 verifiers, 1 receipt, and 3 mails across regions 2 and 125. It included unknown nested extensions, opaque claims, duplicate/missing mail IDs, and lagging allocators.

Representative immutable source root: `e4a1ddc82316a79739a50b5619de7447b791f54acff1fcad9cb508883b626620`.

All source/target counts, player semantic round trips, receipt/mail digests, constraints, allocator cursors, and application-adapter reads passed. Two mail rows were deterministically remapped to protocol IDs 42 and 43. Legacy session/context/credential target counts were all zero.

The custom logical archive was 65,825 bytes with SHA-256 `dd6c2bb8c7b0f39a9d4ca09194f4e91ec2263c6e47f8291539143167c356a41d`. Restore into a second fresh database reproduced every count and semantic digest.

On a separate checksummed PostgreSQL 16.15 cluster, pgBackRest 2.50 archived WAL, created full backup `20260902-144420F`, restored to an independent `PGDATA`, and recovered to the requested time. Markers 1/2/3 were present, later marker 4 was absent, and promotion completed on timeline 2.

A bounded failure injection used an over-bound legacy receipt identity. Import exited nonzero, the run became `FAILED`, account/player/receipt row counts remained zero, and `traffic_open_at` remained null.

## Audit repairs

- The I0 live migration probe previously hard-coded revision `0001_pass339_i0`; it now resolves the actual Alembic head.
- `PostgresPlayerAggregateRepository` previously duck-unwrapped a real SQLAlchemy `Connection` to its psycopg DBAPI proxy. Offline fakes masked this I4 defect. The repository now preserves real Core connections while retaining ResourceTransaction compatibility; live adapter coverage was added.

Neither repair changes gameplay semantics. No source/design contradiction was found.

## Validation

- 276 offline tests passed (including 12 I7 tests); 2 live PostgreSQL integration tests passed.
- All 14 frozen legacy regressions passed.
- Pass346 invariant/hash guard and compileall passed.
- Current src_64 identity/context/mail anchors and mature JSON/backend seams remain unchanged.

The next authorized wave is I8 runtime packaging and a deliberately one-way cutover under one Gunicorn worker plus the retained global `RLock`. Actual operator state must be independently inventoried/snapshotted/rehearsed before any I8 traffic-open decision.
