# Pass83.0 Technical Changelog

Backend: `gxb-backend-v0.9.12-pass83.0`

## Scope

Pass83 is the bounded correction authorized from the Pass82 diagnostic. It changes only MID1 daily-reset ordering, temporal future-anchor hygiene, authoritative bootstrap clock projection, and DailyResetCoordinator observability. MID116/117/118 and all deferred gameplay domains remain unimplemented.

## MID1 reset ordering

MID1 is account/session-scoped at dispatcher entry, so the generic Pass79 pre-handler reset seam cannot see a canonical player. After `resolve_or_create_player()` binds the game player, `BootstrapHandlers.retrieve_token()` now calls `evaluate_daily_reset(1)` before constructing RequestServices, before `TemporalPolicyService.materialize_all()`, and before `build_detail()`.

This guarantees the bundled login snapshots are already current:

- `detail[17]` contains reset purchase counters and hygienic temporal anchors;
- `detail[112]` contains restored Super Campaign daily limits;
- Quick Enchant DailyConsume state is durably cleared before any later MID28 load.

MID1 does not fabricate `economy_.daily_updates`. When MID1 materializes rollover, the full bootstrap detail is the initial-state projection, preserving the Pass79 one-shot notification boundary.

If the bound-player daily-reset evaluation fails, MID1 now fails closed before temporal materialization. This prevents a temporal UoW from stamping a new-day `persistence_state.last_commit` before reset migration has made its stale/current decision.

## Authoritative bootstrap server clock

MID1 now projects `StateRepository.server_clock.now()` rather than `PlayerState.now()`. Production behavior remains wall-clock based by default, while deterministic/injected server-clock operation now gives DailyResetCoordinator, temporal materialization, and the client `xyd.ServerTime` exactly the same epoch source.

## Temporal future-anchor hygiene

For each enabled Pass71 temporal pool (Energy, Spirit Energy, Skill Point):

- if balance is at/above the natural cap, the existing source zero-anchor sentinel remains authoritative;
- if balance is below cap and anchor is missing/zero, the existing behavior rearms at `now`;
- **new:** if balance is below cap and `anchor > now`, only the anchor is rebased to `now`.

A future-anchor rebase changes no resource balance. It neither grants offline recovery nor subtracts resources. It exists because effective `src_64` `SelfPlayer:recoverByTime()` computes `floor((serverTime-anchor)/interval)` without clamping negative elapsed time.

Arena Invitation remains disabled/fail-closed exactly as in Pass71.

## High-water anti-cheat observability

The `stored_day > observed_day` rule is unchanged. Clock rollback still performs no reset and grants no daily entitlement.

Pass83 adds explicit diagnostics containing:

- player;
- triggering MID;
- server epoch;
- stored high-water day;
- observed source day;
- epoch at which the high-water day begins.

Actual initialization/rollover also emits a compact materialization log containing previous/current day, mode, reset/emission flags, and participant names.

## Validation

`selftest_pass83_mid1_temporal_hygiene.py` proves:

- stale no-marker migration is decided/reset before MID1 temporal persistence;
- an existing previous-day durable marker rolls during cold MID1 and the following MID229 does not duplicate/reset or emit a stale pulse;
- an injected bound-player reset failure makes MID1 fail closed while preserving `last_commit` and skipping temporal persistence;
- Quick Enchant, purchase counters, and Super Campaign are current before login detail is built;
- MID1 does not fabricate `daily_updates`;
- injected `ServerClock` is the MID1 `server_time` authority;
- future Energy/Spirit/Skill anchors rebase to `now` with zero balance delta;
- natural-cap zero-anchor sentinel remains intact;
- clock rollback remains no-grant and visibly logged;
- catch-up to an already-materialized high-water day is inert;
- crossing `high_water + 1` resets exactly once.

Pass68, Pass68.1, Pass69, Pass69.1, Pass70, Pass70.1, Pass71, Pass72, Pass73, Pass74, Pass75, Pass79, and Pass81 regression self-tests all remain green.
