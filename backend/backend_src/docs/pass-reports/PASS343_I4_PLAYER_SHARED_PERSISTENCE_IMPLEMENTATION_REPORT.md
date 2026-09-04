# Pass343 — Implementation Wave I4: Player/shared persistence strangler

## Result

**PASS / ACCEPTED.** Pass343 implements the frozen Pass337 I4 PlayerState/shared persistence strangler without switching canonical gameplay authority away from the mature JSON runtime, wiring the PostgreSQL player store into the dispatcher, retiring the global request RLock, or widening workers.

## PlayerState persistence boundary

- Alembic revision `0004_pass343_i4` extends the existing I3 `gxb.players` directory row with nullable-as-a-group `schema_version`, `state_version`, `payload JSONB`, and `updated_at` columns. I3 directory rows may therefore exist before the later offline migration materializes their aggregate.
- The compatibility codec reuses the mature `JsonPlayerDatabase` serializer/hydrator instead of inventing a second gameplay schema.
- Typed `account_uid/player_id/region/state_version` leave the JSONB body and are supplied relationally. The raw gameplay bearer token is intentionally retired and is never stored/reconstructed from PostgreSQL.
- Unknown top-level, identity, domain and mail extensions are preserved. Opaque `persistence_state.claims` remain inside the aggregate because no equivalent normalized owner has been proven.

## Receipt/mail/account-global extraction paths

- Embedded `persistence_state.receipts` are removed from the JSONB payload and exposed as typed extraction rows with the frozen deterministic migration identity `player:<player_id>:<domain>:<key>`.
- Embedded mail is removed from JSONB and receives a deterministic bounded delivery identity derived from player, source ordinal/id and canonical row digest.
- Exact receipt/mail count, identity and semantic SHA-256 accounting is available so migration validation can detect missing or altered unknown extensions rather than silently dropping them.
- `account_global_state` is introduced as an explicit empty aggregate keyed by account. I4 does not infer account-global VIP/progression by merging region-player state.
- Live relational mail authority remains I6, and bulk import/cutover remains I7/I8; I4 does not create `mail_items` or dual-write embedded mail.

## StateRepository strangler and sub-UoW

- `StateRepository` now delegates canonical player load/save/fingerprint calls through a `PlayerStateStore` seam while defaulting to `LegacyJsonPlayerStateStore(MultiUserDatabase)`.
- The candidate `TransactionBoundPostgresPlayerStateStore` is explicitly unwired and unusable without an outer `ResourceTransaction` binding.
- Existing `PlayerUnitOfWork` executes as a player sub-UoW. A relational sub-UoW refuses to load a player unless the matching PLAYER resource was declared in the outer transaction resource set first.
- Expected state versions are tracked independently per player inside one outer transaction; cross-player operations cannot overwrite one player's expected version with another's.
- PostgreSQL save requires exactly one state-version increment and an identity tuple + expected-version predicate; a zero-row update is a conflict, never a silent overwrite.

## Shared-resource boundary

I4 adds explicit repository Protocols for guild authority, finite-claim resources, shared encounters and competition generations. No generic `shared_resources`/EAV table is introduced. Concrete shared domains remain responsible for their own typed canonical rows when their implementation wave arrives.

## Alembic boundary

Revision `0004_pass343_i4` creates `gxb.account_global_state` and only extends `gxb.players` with aggregate columns. It does not create relational mail, realtime gateway state, scheduler/projection tables, a second PlayerState table, or generic shared-resource storage.

## Validation

- 27/27 I4 tests PASS.
- 48/48 I3 tests PASS.
- 39/39 I2 tests PASS.
- 34/34 I1 tests PASS.
- 19/19 foundation tests PASS.
- 167/167 combined tests PASS.
- 14/14 controlling historical regressions PASS using bounded segments.
- Pass340 restart/auth replacement PASS.
- Pass343 invariant guard PASS.
- `compileall` PASS.
- No PostgreSQL daemon, URL, probe, startup or connection was attempted.

The runtime-authority census remains 495 files. Exactly one existing runtime file changes in I4: `gxb_backend/state/repository.py`, the frozen strangler target. The other 494 remain byte-identical to sealed Pass342. Current runtime root SHA-256 is `acf9220097059037be2699dac33640757dd1a853fadb10df9e7b99c427a70eaa`.

## Source/backend reconciliation

Current patched `src_64` remains byte-identical to sealed Pass342, including `Backend.lua`, `LoadingScene.lua`, `LoginWindow.lua`, `SwitchItem.lua`, and `mid.lua`. `MultiUserDatabase`, `EngineDispatcher`, and the I1 auth perimeter also remain byte-identical. The global `threading.RLock` remains present in `StateRepository`.

## Bounded implementation repairs discovered during I4

- Pass334 deterministic receipt/mail migration identities and exact semantic accounting were made explicit rather than leaving extraction as unkeyed blobs.
- The relational store binding was strengthened from one expected-version slot to a per-player map after audit showed a cross-player transaction could otherwise bleed player B's expected version into player A's save.
- The historical I3 migration test was pinned to revision `0003_pass342_i3`; using Alembic `head` would make a historical I3 assertion depend on future migrations.
- Pass343's combined pytest gate uses importlib mode because I3 and I4 legitimately both contain a `test_locking.py` module.

None of these repairs changes the frozen architecture or requires Design reopening.

## Deferred exactly as frozen

I5 owns RealtimeGateway/outbox/liveness integration. I6 owns Scheduler/projections/relational mail. I7 owns full migration rehearsal and extraction/import. I8 owns the one-way canonical cutover. I9 owns global-RLock retirement and gradual multi-worker scaling.

## Next

Pass344 / Wave I5 — RealtimeGateway / durable postcommit / liveness integration — is next and is already authorized to start after Pass343 is fully sealed.
