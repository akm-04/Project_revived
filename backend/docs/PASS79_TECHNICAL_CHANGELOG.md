# Pass 79.0 — Canonical Daily Reset Coordinator

Backend: `gxb-backend-v0.9.9-pass79.0`

## Scope

Pass79 implements only the source-bounded 05:00 GMT+8 daily-reset foundation authorized after Pass78 research. It does **not** implement MID116, MID117, MID118, Daily Mission generation, Sign ownership, ordinary Shop scheduling, Arena reset ownership, card entitlement decrement, Vows, Workshop, or Pet domains.

## Canonical time owner

`ServerDayClock` was added beside the existing epoch `ServerClock`. It is host-timezone independent and implements the recovered client boundary exactly:

`day_id = floor((unix_timestamp + 10800) / 86400)`

The +10800 second shift is equivalent to 05:00 GMT+8 (21:00 UTC on the preceding civil date). The class also exposes the canonical day-start and next-day-start epochs for deterministic tests and future participants.

## DailyResetCoordinator

A new `gxb_backend.state.daily_reset` module contains:

- `DailyResetCoordinator`: lazy, durable, one-player rollover owner.
- `DailyResetParticipantRegistry`: ordered duplicate-safe registry so future source-proven domains can plug in without modifying clock/coordinator logic.
- Typed reset context/outcome/result records.
- A source-bounded response projection merger for the one-shot `economy_` notification.

`StateRepository` owns one shared `ServerClock` and one immutable default reset registry. Every bound gameplay request invokes the lightweight coordinator before response snapshotting and before endpoint logic. The coordinator uses a dedicated `PlayerUnitOfWork`, so every rollover is atomic and crash-safe; participant failure rolls the entire reset back and the next request retries.

The full `RequestServices` graph is deliberately not constructed merely to evaluate the day boundary. RequestServices now accepts the repository's shared `ServerClock` when it is constructed, keeping temporal-resource and day-boundary authority coherent.

## Durable state

`PlayerState.daily_reset_state` is a new server-only persisted control envelope. It records:

- current source `day_id` and source-day start epoch;
- initialization mode and first initialization time;
- the registered participant list;
- the latest rollover audit (from/to day, triggering MID, participant result summaries);
- one-shot notification emission/suppression audit.

It is serialized automatically under the existing forward-compatible `player.domains` persistence section and is never included in `player_info`.

### Upgrade migration safety

Pass75 had no canonical source-day marker. Pass79 therefore avoids a destructive first-run reset unless the existing `persistence_state.last_commit` proves the active UoW-owned daily state was last committed in an older source day. The old Quick-Enchant `day` field is **not** trusted as global stale evidence because it used UTC midnight and is ambiguous during 05:00–08:00 GMT+8.

If stale durable evidence is unavailable, the coordinator seeds the current source day without resetting counters. This deliberately favors temporarily preserving a possibly stale daily use over granting an unintended extra use merely because the backend was upgraded. All later rollovers use the canonical marker and are exact.

## Registered Pass79 participants

### Quick Enchant / Daily Consume

`QuickEnchantDailyResetParticipant` clears `daily_consume_state.counts` once per canonical source day and stamps the state with the source day ID. `HeroAdvancedProgressionRepository._daily_consume_state()` no longer calls `player.now() // 86400`; it owns counters only within an already-materialized day.

### Global purchase counters

`PurchaseCounterDailyResetParticipant` resets exactly:

- `buy_mana_times`
- `buy_energy_times`
- `buy_skill_times`

`buy_spirit_energy_times` is explicitly preserved because the recovered `daily_updates.updates` object does not contain it.

### Super Campaign daily state

`CampaignDailyResetParticipant` reads the Pass75 effective-source ownership catalog once at registry construction. For unlocked `world_map.super` rows with source authority, rollover restores source `daily_limit` (currently 3 for all 155 source Super IDs) and sets `reset_count = 0`. Unknown/non-source rows are not rewritten.

### Task daily cache seam

`TaskDailyCacheInvalidationParticipant` invalidates only server-owned daily cache metadata (`mission_state.daily_cache*`). It deliberately does not generate/reset Daily Mission rows and does not touch Story/Awakening mission ownership.

## One-shot client notification seam

Pass78 proved `daily_updates` and `updates` are siblings inside `economy_`. Pass79 emits exactly:

```text
economy_ = {
  daily_updates = 1,
  updates = {
    buy_mana_times = 0,
    buy_energy_times = 0,
    buy_skill_times = 0
  }
}
```

The notification is emitted only when the request that actually materializes rollover is one of the source-compatible 05:00 reload requests:

- MID229 `ACTIVITIES`
- MID2736 `TASK_LOAD_BY_TYPE` (bounded fallback)

If login/bootstrap or any other MID materializes an overdue reset first, the coordinator resets canonical state but records the notification as suppressed. A later Activities/Task request does **not** emit a stale pulse. This matches the Pass78 offline-login rule and prevents repeated `daily_updates` from repeatedly clearing Sign/cache state in the client.

## Source cross-check retained

The implementation was rechecked against canonical `src_64`:

- `data/tables/misc.lua`: `day_start_time = 18000`.
- `app/common/ServerTime.lua`: at second 18001 the client dispatches `UPDATE_MISSION_ONTIME`, `UPDATE_ACTIVITIES_ONTIME`, and Auction refresh; ordinary Shop events are at 43201/64801/75601 instead.
- `app/model/SelfPlayer.lua`: `params.daily_updates` invalidates Trial/WorldMap/Sign/March and copies only `updates.buy_mana_times`, `updates.buy_energy_times`, and `updates.buy_skill_times`.

## Validation

Pass79-specific self-test covers 11 deterministic checks, including exact 04:59:59→05:00:00 boundary behavior, one-shot notification, non-trigger suppression, migration safety, Super Campaign restore, spirit-counter exclusion, Quick-Enchant removal of local UTC rollover, persistence round-trip, response merge, and request-bound StateRepository integration.

Regression tests for Pass68, Pass69, Pass70, Pass70.1, Pass71, Pass72, Pass73, Pass74, and Pass75 also pass after the coordinator changes. Runtime client acceptance remains open until the Pass79 client rollover plan is executed.
