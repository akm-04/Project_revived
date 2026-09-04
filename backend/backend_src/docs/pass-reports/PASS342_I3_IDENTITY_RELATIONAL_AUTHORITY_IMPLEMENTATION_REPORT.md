# Pass342 — Implementation Wave I3: Relational Identity / Session / Context Authority

## Result

**PASS / ACCEPTED.** Pass342 implements the frozen Pass337 I3 identity/session/context/region authority plane without switching mature PlayerState gameplay persistence away from JSON, wiring the relational adapter into the live dispatcher, retiring the global request RLock, or widening workers.

## Relational authority boundary

- Added relational account, credential, account-session, region allocator, minimal player-directory, gameplay-context, and session-credential repositories/services.
- Account-scope MID18/MID1 authentication uses SID/login-token credentials. Generic gameplay bearer tokens cannot authenticate those transition operations.
- Ordinary selected-player/realtime admission resolves a context-bound gameplay credential directly to one immutable account/session/context/player identity. Caller-supplied region is only a consistency fence and never selects an actor.
- Multiple account sessions remain independent. A successful MID1 rotates only that session's active gameplay context/token; other sessions are not revoked.
- Session revocation ends the active context, revokes every session credential and stages a durable invalidation outbox event.

## Credential model

- New local password credentials use Argon2id; legacy Pass299 PBKDF2 material remains verifiable and is upgraded after a successful login.
- SID compatibility credentials use 128 bits of CSPRNG material; login/gameplay credentials use 256 bits. Only domain-separated SHA-256 bearer digests are persisted.
- Login whole-transaction retry preserves prepared random session/credential material and a successful password verification/upgrade when the underlying credential row has not changed.
- The candidate relational adapter contains no fixed `SANDBOX_SID`, `SANDBOX_TOKEN`, or administrator bypass authority and remains deliberately unwired from `EngineDispatcher` in I3.

## Region/player directory

- I3 creates only the immutable player identity directory: `player_id / account_uid / region_id / created_at`. PlayerState payload/state-version/schema-version fields remain I4 scope.
- Region compatibility seed rows are source/backend-grounded for IDs 1..200; region 125 retains the current "Deep Valley" label.
- Player allocation preserves the current encoded namespace and starts each fresh region cursor at `region_id * 100000 + 1`.
- The allocator locks the region row, enforces capacity, and relies on unique `(account_uid, region_id)` ownership so concurrent first creation converges on exactly one player.
- Existing owners may still select their player when a region no longer allows new allocations.

## Integrity repair discovered during I3

A bounded design-line audit found that the first candidate relied on application code to keep gameplay context/session/account/player bindings coherent. Pass342 strengthened the schema before sealing: composite foreign keys now require a gameplay context's session/account pair and player/account/region tuple to agree, and gameplay credentials require their `(context_id, session_id)` pair to agree. The resolver also fails closed on any observed binding mismatch. This is a bounded integrity adaptation consistent with Pass337; no Design reopening was required.

## Alembic boundary

Revision `0003_pass342_i3` creates `gxb.account_uid_seq` plus only these I3 tables: `accounts`, `account_credentials`, `account_sessions`, `regions`, `players`, `gameplay_contexts`, and `session_credentials`, and seeds the compatibility region directory. It does not create PlayerState JSONB/state-version authority, account-global state, mail, shared-resource, projection, RealtimeGateway, or SchedulerWorker schema.

## Validation

- 48/48 I3 tests PASS.
- 39/39 I2 tests PASS.
- 34/34 I1 tests PASS.
- 19/19 I0 foundation tests PASS.
- 140/140 combined tests PASS.
- 14/14 unchanged controlling historical regressions PASS using bounded harness segments.
- Pass340 restart/auth replacement regression PASS.
- Pass342 I3 invariant guard PASS.
- `compileall` PASS.
- No PostgreSQL daemon, URL, probe, startup, or connection was attempted. SQL/schema behavior was tested with exact bundled libraries where loadable, offline Alembic DDL, mocks/fakes, rollback/retry models and concurrency probes.

## Source/backend reconciliation

Current patched `src_64` remains byte-identical to sealed Pass341. The MID18/MID1 wire contract, SID-only manual path, contextEpoch stale fence, MID1 token installation, and selected-region behavior were re-read during implementation. `StateRepository`, `MultiUserDatabase`, `EngineDispatcher`, and the Pass340 auth perimeter are also byte-identical to Pass341.

All 495 legacy gameplay/client/runtime-authority files retain root SHA-256 `d90e6b6e73bf1bebb760a51762191e04e6d53ff55065e125cd1c989736e176f1`.

## Deferred exactly as frozen

I4 owns PlayerState JSONB plus StateRepository strangler/shared repositories. I5 owns RealtimeGateway/outbox/liveness integration. I6 owns Scheduler/projections/relational mail. Production cutover remains I8. Global RLock retirement and multi-worker expansion remain I9.

## Next

Pass343 / Wave I4 — PlayerState JSONB + StateRepository strangler/shared repositories — is the next frozen wave. The user has already authorized continuation after Pass342 sealing; Pass343 may begin only from the sealed Pass342 artifacts.
