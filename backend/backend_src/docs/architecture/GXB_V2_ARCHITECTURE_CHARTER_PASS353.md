# GXB V2 Architecture Charter — Pass353 provisional design direction

Status: **PROVISIONAL DESIGN CHARTER — V1 ORACLE REMAINS AUTHORITATIVE UNTIL V2 DIFFERENTIAL/STOCK ACCEPTANCE**

## Why V2 now

Pass352/353 exposed deployment-topology debt rather than a missing campaign rule: PostgreSQL authority was correctly persistent, but OTA publication state still lived below disposable `current_backend/`; production Gunicorn did not execute the development `run.main()` OTA preparation path; nginx bypassed the catalog-aware lazy resource service. These are symptoms of a reconstruction that grew from gameplay-first archaeology into a full server platform.

Python V1 was not a mistake. It remains the executable oracle containing hundreds of recovered protocol and gameplay compatibility decisions. V2 exists to **compress the now-known semantics into intentional boundaries**, not to discard that knowledge or imitate the probable historical physical topology.

## Priority order

V2 implementation priority is deliberately no longer campaign-first:

1. **Control plane / bootstrap** — `/center/v1`, server directory, capacity/status, resource/update endpoints.
2. **Identity and session plane** — account session, selected server/region character, gameplay credential, revocation/context leases.
3. **Server/shard authority** — explicit isolated server/region ownership and player allocation; no device-cached region may become authority.
4. **Canonical persistence and transaction model** — PostgreSQL, resource-scoped transactions, durable outbox/jobs, idempotency.
5. **Global/cross-server plane** — global chat/discovery, profile lookup/comments, cross-server mail/announcements, rankings/competition/event coordination where source evidence requires global scope.
6. **Realtime** — stock framed TCP + AMF3 admission, WORLD/SERVICE/GUILD memberships, liveness; transport remains non-canonical.
7. **Economy and server-side events** — currencies, shops, timed activity state, rewards, scheduler/finalization.
8. **Core game modes** — campaign/PvE plus arena/1v1/other competitive modes. Exact region-local vs cross-server ownership stays evidence-driven per mode.
9. **Long-tail feature domains** — feature-specific handlers after foundational scope/authority is proven.

## Logical topology

```text
Stock client
   |
   +--> /center/v1 ----------------------+
   |                                     |
   |                              Control Plane
   |                     server directory / routing
   |                    account bootstrap / OTA URLs
   |                                     |
   +--> /api/v1 -------------------------+--------------------+
   |                                                          |
   |                                                   Selected Shard
   |                                             gameplay/session authority
   |                                              player + region resources
   |                                                          |
   +--> /res + /updates --> Resource/OTA Plane                 |
   |                                                          |
   +--> framed TCP/AMF3 --> Realtime Plane                    |
                              |                                |
                        WORLD/SERVICE/GUILD                    |
                              +---------------+----------------+
                                              |
                                      Global Service Plane
                              profile/comment/mail/rank/events
                                              |
                                              v
                                         PostgreSQL
                                   sole canonical authority
```

This is a **logical** separation. The first V2 deployment should prefer one small executable/process family and one PostgreSQL instance unless measured operational evidence requires physical separation.

## Identity model

The central invariant is:

```text
Account
  -> authenticated account session
  -> account-owned character directory (MID18 semantics)
  -> explicit selected server/region character
  -> gameplay credential bound to {session, server/region, player}
```

A device preference may suggest a server but cannot select authority without account ownership/context validation. Multiple owned regional characters require explicit choice. Context replacement/revocation must wait for in-flight leases established by authenticated requests.

## Server/shard model

`server_id` / `region_id` is a first-class scope key, not an incidental field on PlayerState. Each server has explicit metadata such as status, capacity, allocation range, endpoints, lifecycle and event calendar. Region-encoded player IDs remain immutable.

Region isolation means ordinary gameplay mutations in one shard cannot implicitly mutate another shard's player state. Cross-server operations go through a separately owned global/cross-server resource boundary and durable transaction/outbox semantics.

A single PostgreSQL cluster may initially host all shards physically. Isolation is **semantic and transactional first**, deployment-level second.

## Global/cross-server model

Global facilities are explicit authorities rather than ad-hoc reads into arbitrary player repositories. Candidate domains include:

- global/service chat discovery and delivery;
- account-wide player/profile directory;
- public profile snapshots and comments;
- cross-server mail/announcements;
- global/cross-server rankings and competition state where proven;
- scheduled global activities;
- guild/global resources where source evidence requires shared authority.

Read-heavy cross-server profile/ranking access should use durable projections/read models. Cross-server writes must use typed commands/transactions rather than directly opening another shard's aggregate.

## Events and scheduler

Every scheduled job/event declares scope explicitly:

- `GLOBAL`
- `SERVER(region_id)`
- `PLAYER(player_id)`
- another named shared resource when source evidence establishes one.

Jobs are durable PostgreSQL records with idempotent execution and at-least-once retry semantics. User-visible durable delivery (mail/reward) commits before transient realtime notification.

## Resource and OTA plane

Published OTA artifacts are deployment state, not application code. They must live outside disposable backend extraction and survive ordinary upgrades. The updater owns immutable release history and exact-current asset provenance. `/res/<basename>.<md5>` remains catalog-aware because stock lazy URLs discard the original directory path.

## Migration

Legacy JSON migration is a **separate one-shot tool**:

```text
preserved legacy evidence -> gxb-migrate -> validate/normalize -> PostgreSQL -> migration sealed
```

The normal V2 server contains no JSON fallback and performs no legacy remigration on update/start/restore. Backup/restore operates on canonical PostgreSQL and independently durable deployment state where needed.

## Implementation language / physical deployment

Recommended V2 core: **Go + PostgreSQL**. nginx/OpenResty may remain an optional edge for TLS/static routing/historical compatibility, but canonical gameplay/state logic should not depend on nginx worker-local Lua memory. The design remains protocol/invariant-driven rather than language-driven until V2 contract extraction is complete.

Initial V2 should be a modular monolith or one codebase with explicit run modes, for example:

```text
gxb serve        # HTTP/control/game API + optional realtime/worker modes
gxb realtime     # optional separate process mode later
gxb worker       # scheduler/outbox mode later
gxb migrate      # one-shot legacy import only
gxb backup
gxb restore
gxb doctor
```

Do not recreate a commercial multi-daemon topology merely because it may have existed historically.

## V1 -> V2 migration strategy

V1 Python is frozen as the behavioral oracle after I10 acceptance. V2 advances by differential contracts:

1. extract request/response/state-transition contracts from Passmap + V1 tests + stock traffic;
2. implement one vertical slice in V2;
3. replay the same inputs into V1 and V2;
4. compare wire output, auth/context transitions and PostgreSQL effects;
5. run stock client;
6. only then mark that domain V2-owned.

Recommended first vertical slice:

```text
center/bootstrap
 -> SDK/account session
 -> MID18 server/character directory
 -> MID2864 public bootstrap
 -> MID1 gameplay context/token
 -> player load/save
 -> MID2 OTA/resource routing
 -> realtime admission/login
```

This proves the **server**, not campaign content, before migrating long-tail gameplay.

## Explicit non-goals

- no big-bang deletion of Python V1;
- no rewrite merely for benchmark speed;
- no assumption that historical OpenResty evidence means all canonical game logic belonged in Lua;
- no physical database-per-region requirement until needed;
- no cross-server mode classification without source/runtime evidence;
- no weakening PostgreSQL sole-authority, auth scope or resource-scoped transaction invariants.
