# Pass434 — Milestone I1: Foundation Kernel & PostgreSQL Schema/Transaction Primitives

## Scope implemented

I1 implements the Wave-A foundation kernel required by later domain milestones while keeping gameplay behavior absent.

### Operation/time/policy primitives
- dependency-free RFC4122-v4 internal UUID implementation;
- injectable authoritative clock primitives;
- immutable, sorted versioned policy references;
- stable `operation.Context` carrying operation ID, canonical start time, 32-byte entropy seed and policy references;
- deterministic HMAC-SHA256 entropy derivation independent of retry attempt.

### Typed locking and creation fences
- typed lock identities for signed/unsigned integers, strings, UUIDs and bytes;
- deterministic total ordering by domain rank → owner kind → identity type → canonical bytes;
- duplicate-key rejection;
- explicit missing-child creation fence requiring an existing parent/directory/generation/allocator lock and a named database uniqueness constraint.

### Transaction runner
- bounded admission before database `Begin`;
- finite acquire/lock/statement/transaction/cleanup/reconcile/operation timeouts;
- transaction-local PostgreSQL timeout configuration through the generic transaction port;
- bounded whole-operation retry only for definite rollback classes (`40001`, `40P01`, or driver-normalized definite abort) when command policy opts in;
- stable operation context/entropy across retries;
- one-shot COMMIT boundary;
- unknown-COMMIT result for unclassified commit errors;
- fresh authoritative reconciliation interface before any replay;
- authoritative-negative replay only under an explicit command policy;
- reconciliation context detached from caller cancellation but still finitely bounded;
- rollback cleanup on an independent bounded context.

### Semantic receipts and atomic work ports
- type-tagged canonical request fingerprinting with deterministic map order and explicit scalar/time/UUID distinctions;
- semantic receipt identity, terminal result payload and replay/conflict behavior;
- receipt unknown-COMMIT resolver requiring a fresh authoritative-writer reader;
- shared `FactAppender[T]` transaction-binding interface while preserving domain-owned fact types/schemas;
- durable-obligation interface carrying semantic key/due time/queue/profile/payload without leaking worker/job identity into domain authority.

### PostgreSQL schema/query ownership
- forward-only goose baseline creating only `gxb_operation_receipts` as GXB-owned kernel persistence;
- no generic lock, state-version, generation, player/account or gameplay outbox table;
- unique semantic identity and 32-byte fingerprint constraints;
- conflict-safe `INSERT ... ON CONFLICT DO NOTHING` followed by canonical stored-receipt comparison;
- one SQL owner source plus deterministic runtime query-text generation and hash guard;
- sqlc configuration prepared for typed generation in the connected toolchain gate.

### pgx/River adapters
- build-tagged pgx/pgxpool adapter so foundation/domain code never imports the driver;
- finite pool-settings validation, UTC runtime parameter, project isolation/access mapping;
- `pgx.ErrTxCommitRollback` normalized as definite-abort evidence rather than ambiguous COMMIT;
- build-tagged River adapter inserts obligations using the same pgx transaction and intentionally ignores River job identity for correctness.

### Audit/observability and architecture enforcement
- secret/content redaction baseline;
- bounded metric-label whitelist that rejects high-cardinality player/account/request identities;
- tracer/metric/transaction-hook ports;
- sanitized audit event/emitter port;
- architecture guard rejects pgx/River imports outside their adapters, network/provider imports in canonical transaction/domain packages, and direct canonical-domain `time.Now` usage;
- Wave-S stock bootstrap-shape fixture remains loadable as an early compatibility guard.

## DRY decisions

I1 intentionally centralizes mechanisms but does not centralize domain truth:
- SQL runtime text is generated from the single owner query file rather than copied manually.
- Direct SPDX inventory is generated from `DEPENDENCIES.lock.json` to prevent version drift.
- transaction, receipt, fact-append and obligation mechanics are reusable ports.
- there is no generic “everything” table/service that would collapse owner boundaries.

## Source/V1 cross-check

Current stock `Backend.lua` still supports same-MID/same-param retry and has no generic stock operation nonce/context epoch. Frozen Pass353 retains useful stable-operation-context and real-row lock-registry mechanisms, but its private operation-ID seam, generic state-version retry and project-owned generic job/outbox design were not adopted. See `PASS434_I1_ORACLE_CROSSCHECK.md`.

## Local verification completed

- dependency policy and direct-SBOM consistency;
- all five oracle archive hashes;
- deterministic query generation and schema/query ownership;
- all Go unit/property tests;
- `go vet ./...`;
- architecture guards;
- receipt replay/conflict tests;
- lock-order permutation/type tests;
- retry-stable operation-context/entropy tests;
- unknown-COMMIT no-blind-replay and reconciliation tests;
- caller-cancellation-safe reconciliation test;
- definite-rollback-at-COMMIT classification test;
- rollback cleanup and bounded admission tests;
- observability redaction/cardinality tests;
- Wave-S fixture shape check.

## Honest deferrals

The normal-chat sandbox has Go 1.23.2, no module/toolchain network access, no `sqlc`, `goose`, `govulncheck`, `docker`, `psql`, PostgreSQL daemon or River runtime environment. Therefore these are **not claimed**:
- exact Go 1.27.1 build of `postgres`/`river` tagged adapters;
- resolved `go.sum`, transitive SBOM/license scan and `govulncheck`;
- sqlc generation/compile against the pinned version;
- goose execution against PostgreSQL 18.6;
- real PostgreSQL isolation/locking/deadlock/serialization/ambiguous-COMMIT behavior;
- River transactional visibility, crash/redelivery or lease behavior.

Per the frozen roadmap, real PostgreSQL/River/stock-client proof remains **W1 after I4**, not an I1 shortcut.

## I1 verdict

**PASS_WITH_LIVE_POSTGRESQL_RIVER_AND_CONNECTED_TOOLCHAIN_PROOF_DEFERRED_TO_THEIR_FROZEN_GATES.**

The normal-chat implementation gate for I1 is green. I2 may build on these interfaces, but PostgreSQL/River semantics remain unproven until W1 and exact connected-toolchain checks remain explicit outstanding evidence.
