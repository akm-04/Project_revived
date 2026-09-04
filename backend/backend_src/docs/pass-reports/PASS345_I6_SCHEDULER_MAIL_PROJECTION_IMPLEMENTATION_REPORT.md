# Pass345 — Implementation Wave I6: Scheduler / projections / relational mail

## Result

**PASS / ACCEPTED.** Pass345 implements the frozen Pass337/Pass333 I6 foundation while preserving JSON PlayerState as the default canonical gameplay store, retaining the process-global request RLock, leaving the dedicated I5 RealtimeGateway unwired from default runtime, and deferring migration/cutover to I7/I8.

## SchedulerWorker / autonomous work

- `SchedulerWorker` consumes only durable `scheduled_jobs` using the I2 short-claim / execute-outside-queue-transaction / short-settle pattern.
- PostgreSQL clock remains the due authority through the I2 repository; overdue `SCHEDULED/RETRY` work and expired `RUNNING` leases are reclaimable.
- A `SchedulerProcess` candidate composes scheduled-job and derived-projection lanes in one baseline Python process while keeping their claim transactions independent.
- Projection stale claims are recovered on process startup; repeated application remains idempotent through source-version/snapshot semantics.
- No per-player regeneration or daily-reset jobs are created. Player-local time materialization remains lazy as frozen by Pass333.

## Generation lifecycle / finalization

- Generic typed lifecycle covers `PLANNED -> OPEN -> FROZEN -> FINALIZING -> FINALIZED -> CLOSED` over domain-owned repositories; no universal generation/EAV table is invented.
- `FROZEN` is the authoritative write fence. Finalization requires FROZEN/FINALIZING and a permanent semantic receipt.
- Final snapshot/delivery work executes under the caller's ResourceTransaction and can safely replay after uncertain execution because generation state, receipts, snapshot uniqueness, and mail delivery keys are deterministic.
- New generations are independent identities; finalized history is retained.

## Relational mail authority candidate

- Candidate `mail_items` is normalized durable mailbox authority with deterministic `delivery_key`, explicit read/claim state, attachments JSONB, source identity, expiry and metadata.
- Direct current `src_64` proves the protocol identity is `(is_region,id)` and `MAIL_ONEKEY` sends independent `normal_ids` and `region_ids`. I6 therefore refines the earlier draft uniqueness to `UNIQUE(player_id,is_region,protocol_mail_id)` instead of inventing hidden account/global ownership.
- `MailDeliveryService` writes durable mail before any optional realtime notification. Reusing the same deterministic delivery key with different semantic content fails closed.
- Mail claim declares PLAYER before deterministic mail CHILD resources, locks rows, validates unclaimed/unexpired state, delegates attachments to the existing reward/player sub-UoW owner, marks claimed, and records the I2 semantic claim receipt in the same outer transaction.
- Matching logical retry replays the one-shot awards from the committed receipt before touching an already-claimed row; reusing that operation ID with a different mail set is rejected by request fingerprint.
- Retention/expiry deletion policy remains injectable/uninvented because current source proves client presentation behavior but not official server retention policy.

## Projections / snapshots / consumer partition

- I6 adds the frozen fourth outbox class `DERIVED_PROJECTION_WORK` and extends only the I2 delivery-class constraint.
- `ProjectionOutboxWorker` claims only `DERIVED_PROJECTION_WORK`; I5 realtime remains restricted to its two realtime classes and cannot steal projection or durable-user rows.
- Live rank projections are derived/rebuildable and use `source_version` so stale async updates cannot overwrite newer rows. Destructive full-scope rebuild requires an explicit quiesced canonical-source boundary.
- Final rank snapshots are insert-only through the repository: exact replay is idempotent, conflicting replay raises, and historical generations are not deleted.
- `DURABLE_USER_DELIVERY` remains canonical-domain/mail work, not socket authority.

## Candidate schema revision 0006

Revision `0006_pass345_i6` extends the outbox delivery-class check and adds only:

- `gxb.mail_items`
- `gxb.rank_projection_live`
- `gxb.rank_snapshots`
- `gxb.mail_protocol_id_seq`

It creates no universal generation table, generic shared/EAV table, scheduler-state table, realtime-session table, PlayerState cutover table, or later-wave packaging/cutover authority.

## Pass333 reference reconciliation

The original Pass333 14-case scheduler/projection/mail model is reproduced **14/14**: early jobs are not claimable, overdue jobs are catch-up claimable, expired leases recover, dedupe keys are stable, freeze fences writes, finalization is idempotent, historical snapshots remain, generation rollover is independent, mail delivery identity is idempotent, first claim settles atomically, duplicate grant is blocked through semantic receipt replay, projection rebuild remains derived, per-player regen jobs are absent, and durable mail precedes notification.

## Source/backend reconciliation

Current patched `src_64` remains byte-identical to sealed Pass344 for `Backend.lua`, `LoadingScene.lua`, `LoginWindow.lua`, `SwitchItem.lua`, and `mid.lua`. Direct mail evidence is re-hashed from current source: `Mailbox.lua`, `MailboxWindow.lua`, and `MailItem.lua` match the research hashes used to derive the compound mail identity and response shapes.

All 495 Pass344 mature runtime-authority files remain byte-identical, preserving runtime root SHA-256 `4a76b2101a70a5d95f2517496916223b42adf2c922295d968b8bae73ddc86039`. `StateRepository`, `MultiUserDatabase`, `EngineDispatcher`, the I1 auth perimeter, current realtime transport changes, and global `threading.RLock` are unchanged.

## Bounded repairs discovered during I6

- Added semantic mail-claim receipts in the same outer transaction so lost-response retries replay awards without duplicate grant or false already-claimed failure.
- Refined mail protocol uniqueness to include `is_region`, following exhausted current source instead of the earlier draft schema shorthand.
- Added `DERIVED_PROJECTION_WORK`, which Pass336 froze but the earlier I2 enum could not know until this consumer wave.
- Added projection stale-claim recovery and one-process scheduled/projection composition.
- Added full generic generation open/close fences around the already present freeze/finalize path.
- Hardened `is_region` parsing against Python string truthiness, deterministic delivery-key semantic collisions, and destructive projection rebuild races.

None requires reopening Pass337 Design.

## Validation

- 59/59 I6 tests PASS.
- Pass333 14/14 reference probe PASS.
- 35/35 I5, 27/27 I4, 48/48 I3, 39/39 I2, 34/34 I1 and 19/19 foundation tests PASS.
- **261/261 combined tests PASS.**
- 14/14 controlling historical regressions PASS in bounded segments.
- Pass340 restart/auth replacement PASS.
- Pass345 invariant guard PASS.
- `compileall` PASS.
- No PostgreSQL daemon, URL, startup, probe or connection was attempted.

## Deferred exactly as frozen

I7 owns full migration rehearsal and backup/restore validation. I8 owns one-way runtime packaging/TRAFFIC_OPEN cutover. I9 owns global RLock retirement and gradual multi-worker scaling. This Pass is intentionally dedicated solely to closing I6 and its Passmap.
