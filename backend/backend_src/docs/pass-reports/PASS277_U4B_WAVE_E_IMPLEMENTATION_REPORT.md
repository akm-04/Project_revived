# Pass277 / U4B Wave E — Typed Realtime Publisher + MID192 HTTP Room Directory

Wave E connects the already accepted Wave-A post-commit seam to the authenticated Wave-D realtime runtime without turning the transport into a business-state owner.

Implemented:
- immutable player/room/session realtime audience contracts and typed `RealtimeEventIntent`;
- request-scoped `RealtimeIntentStager` that validates then stages only to `PlayerUnitOfWork` topic `realtime.transient`;
- process-wide `TypedRealtimeEventPublisher` over the transient authenticated session registry, preserving sequence-zero compatibility policy and bounded queue/backpressure behavior;
- `RealtimeEventSchemaRegistry` with fail-closed direction/role/schema validation;
- domain-owned `RealtimeNoticeSchema` seam for generic `PLAYER_NOTICE` / `WORLD_NOTICE`; production Wave E registers zero domain notice schemas, so Mail/Arena/Guild/PvP notices cannot be fabricated;
- `RealtimeRoomDirectory` sharing the exact Wave-D WORLD/SERVICE/GUILD admission policy;
- MID192 authenticated HTTP discovery through the already-bound canonical HTTP identity, returning only `{host, port, room_id}` for admitted rooms;
- AppFactory binds `RealtimeRuntime.handle_post_commit` as the dispatcher sink. Delivery remains after `StateRepository.request_scope()` exits.

Implementation-time current-source refinement:
- frozen planning metadata had treated `FORCE_RELOAD` as broadly role-capable;
- current `Backend.lua` special-cases `FORCE_RELOAD` only in the WORLD socket branch and has no generic mapping entry for it;
- Wave E therefore narrows production `FORCE_RELOAD` publication to WORLD only. This is a bounded current-source correction, not a change to the transport architecture.

Safety boundaries:
- publisher holds no canonical gameplay state and performs no gameplay mutation;
- generic notices require an owning domain's typed notice schema and therefore fail closed in production today;
- a test-only injected Mail notice schema proves that future domains can reuse the generic transport without moving Mail state into realtime infrastructure;
- saturated session queues disconnect the slow consumer rather than blocking or reversing a committed gameplay transaction;
- MID192 reuses the same admission policy as TCP login, eliminating discovery/admission policy drift;
- no durable generic realtime outbox was introduced; Commerce/Mail-style durable delivery remains domain-owned;
- no client runtime bytes changed.

Controlling regression:
- Waves A, B, C, D and E PASS;
- Pass68/68.1, Pass69/69.1, Pass70/70.1, Pass71, Pass79, Pass83, Pass88 + route, Pass91 PASS;
- Pass129 architecture hygiene PASS;
- Pass212 Stage-G PASS;
- Pass227 Blood MID867 PASS;
- Pass248 Emblem I6 11/11 PASS.

Wave F remains responsible for the whole synchronization-foundation integration/regression pass. It has not started.
