# Pass344 — Implementation Wave I5: RealtimeGateway / durable postcommit / liveness

## Result

**PASS / ACCEPTED.** Pass344 implements the frozen Pass337 I5 realtime foundation without switching canonical gameplay persistence, starting SchedulerWorker/mail authority, retiring the global request RLock, widening HTTP workers, or wiring the dedicated gateway into the default runtime before the later packaging/cutover gate.

## Dedicated gateway boundary

- `RealtimeGateway` is a dedicated-process composition candidate owning the custom TCP server, transient authenticated registry, realtime outbox consumer, PostgreSQL LISTEN wakeup adapter, and liveness sweeper.
- Current `app_factory.py` and `run.py` intentionally retain the sealed legacy `RealtimeRuntime`; the new gateway is not default-runtime wired in I5.
- HTTP/domain workers never own socket references. Durable room invalidation is keyed by `context_id + role + room_id`; the gateway resolves the current transient connection locally.
- Raw gameplay bearer material is consumed only during relational TCP admission and is not retained in `RealtimeSession`. Non-secret `session_id` and `context_id` are retained for liveness/invalidation indexing.

## Registry / duplicate ownership

- Registry indexes cover connection, player, account session, gameplay context, `(context_id, role)`, and room.
- WORLD/GUILD/SERVICE roles may coexist for one context.
- For the same `(context_id, role)`, newest admission wins. The old connection is removed from transient authority before a best-effort MID65000 `CONNECTION_SUPERSEDED` frame and intentional close.
- Different contexts remain independent even for the same account/player.
- Control close has a bounded hard-close fallback if the writer cannot drain the final private control frame.

## Durable outbox semantics

- I5 extends the I2 outbox repository with an optional delivery-class filter so the realtime consumer can claim only `TRANSIENT_REALTIME_NOTICE` and `IDEMPOTENT_REALTIME_CONTROL`.
- `DURABLE_USER_DELIVERY` is explicitly excluded and remains for later durable-user/mail ownership.
- Transient notices are marked `DISPATCHED` before socket I/O and then terminally recorded; a post-fence crash cannot replay the notice.
- Idempotent controls are applied locally then marked done; failure releases the row for retry.
- Stale `CLAIMED` rows are recoverable, while `DISPATCHED` transient attempts are never requeued.
- Candidate Alembic revision `0005_pass344_i5` adds only a statement-level `gxb_outbox` wakeup trigger/function. Durable event truth remains `outbox_events`.

## LISTEN/NOTIFY / restart correctness

- Gateway startup establishes LISTEN first, then recovers stale claims, polls durable outbox state, and only then starts the socket server.
- Periodic polling remains the correctness path even when NOTIFY is missed or the listener connection drops.
- Wakeup failure reconnects independently; notification payload carries no durable event data.
- Restart/failure tests cover stale-claim recovery, transient non-replay, listener failure/reconnect, and polling fallback.

## Liveness / invalidation

- Admission uses the I3 context-bound gameplay credential authority and treats caller `region` only as a consistency check.
- Fast-path session/context invalidations are durable idempotent outbox controls.
- Periodic batch liveness validation checks session revocation, absolute/idle expiry, context ending, missing authority, and session/context mismatch.
- Database-unverifiable existing sockets receive only a short configurable grace, then fail closed; new admission already fails closed through the relational authenticator.
- Room invalidation closes only the current matching context/role/room owner and includes the private `ROOM_INVALIDATED` control.

## Pass332 reference reconciliation

The original 13-case `REALTIME_OUTBOX_LIVENESS_STATE_MODEL` is reproduced 13/13: distinct roles coexist; newest same-context role wins; superseded control is delivered; different contexts coexist; room fanout targets active sessions; transient notices become terminal; expired notices are excluded; context invalidation is scoped and controlled; session invalidation closes remaining sockets; liveness fallback closes stale authority; controls are idempotent; and private control MID 65000 fits the u16 wire field.

## Source/backend reconciliation

Current patched `src_64` remains byte-identical to sealed Pass343, including `Backend.lua`, `LoadingScene.lua`, `LoginWindow.lua`, `SwitchItem.lua`, and `mid.lua`. The client continues to send context-bound `token`, supplied region, and role-specific `room_id`; MID65000 remains pre-dispatched before normal realtime processing; intentional closes suppress stock reconnect; heartbeat behavior remains unchanged.

`StateRepository`, `MultiUserDatabase`, `EngineDispatcher`, and the I1 auth perimeter remain byte-identical to Pass343. The global `threading.RLock` remains intact and JSON PlayerState remains canonical.

## Bounded implementation repairs discovered during I5

- Added a bounded hard-close fallback after best-effort private-control drain so invalid authority cannot depend on a healthy writer thread.
- Strengthened `OutboxRepository.claim_available()` with explicit delivery-class filtering and compiled-SQL proof that the gateway cannot steal `DURABLE_USER_DELIVERY` rows.
- Replaced a transient `connection_id` room-invalidation shortcut with durable `context_id + role + room_id` identity, matching the frozen rule that HTTP/domain workers do not know socket references.
- Added explicit restart/failure probes proving stale controls recover while already-dispatched transient attempts never replay.
- Historical I4 Alembic test is pinned to revision `0004_pass343_i4` so a future `head` does not change what the I4 historical assertion means.

None requires reopening Pass337 Design.

## Validation

- 35/35 I5 tests PASS.
- Pass332 13/13 realtime reference probe PASS.
- 27/27 I4 tests PASS.
- 48/48 I3 tests PASS.
- 39/39 I2 tests PASS.
- 34/34 I1 tests PASS.
- 19/19 foundation tests PASS.
- 202/202 combined tests PASS.
- 14/14 controlling historical regressions PASS in bounded segments.
- Pass340 restart/auth replacement PASS.
- Pass344 invariant guard PASS.
- `compileall` PASS.
- No PostgreSQL daemon, URL, startup, probe, or connection was attempted.

The mature 495-file runtime-authority census changes exactly four I5 transport/registry files: `realtime/contracts.py`, `realtime/control.py`, `realtime/server.py`, and `realtime/session.py`. Current runtime root SHA-256 is `4a76b2101a70a5d95f2517496916223b42adf2c922295d968b8bae73ddc86039`. New I5 gateway modules and the I2 outbox-kernel extension are separately implementation-hashed.

## Deferred exactly as frozen

I6 owns SchedulerWorker, global projections, and relational mail. I7 owns full migration rehearsal plus backup/restore. I8 owns runtime packaging and one-way TRAFFIC_OPEN cutover. I9 owns RLock retirement and gradual multi-worker scaling.

## Next

Pass345 / Wave I6 — Scheduler/projections/relational mail — is next after Pass344 is fully sealed.
