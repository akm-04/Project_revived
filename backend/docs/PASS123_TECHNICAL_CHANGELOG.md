# Pass123 Technical Changelog

## Runtime evidence

The user-supplied Pass122 Challenge smoke is accepted. The trace shows stock-shaped MID113 for Challenge `24111`, deterministic first-clear items `50001121`, `50001125`, and `50001129` at quantity 1, followed by MID114 victory projecting `24111` star 3 plus both raw children `24112` and `24121` at star 0. Energy is returned as 62. No Campaign/Challenge nil crash or decoded Campaign client error is present. Repeated `clock_regression_ignored` lines are the existing DailyResetCoordinator fail-safe and did not mutate Campaign state.

## `src_64` architectural feedback loop

Pass123 was re-checked against effective `app-assets/output/assets/src_64` before behavioral modification. Stock SelectTeam Campaign start sends campaign id/type/formation plus optional native rent/pet fields and no operation UUID. BattleCreate sends MID114 with campaign id/type/formation/star and does not echo MID113 `battle_id`. Its Campaign result callback accepts `errorIdFightExist`, and `lib/battle/battleConfig.lua` defines that value as 30005. This directly supports retirement of the Pass117 cross-request UUID bridge.

## Manual battle session rewrite

Campaign MID113/MID114 now use server-owned `player.active_campaign_battle` schema v2. MID113 stages and freezes the outcome after source guards. Repeating MID113 for the same campaign/type while STAGED replays the same frozen stage response without RNG or state mutation. Formation remains an audit snapshot, not a correlation key, and legacy 1.631.7 `campaign_battle_op_id` input is ignored. A different valid Campaign/type may supersede the staged session only after its guards pass.

MID114 consumes a matching STAGED session exactly once. A matching terminal duplicate renders the stored terminal/static response against current live projections and returns source-family 30005 without another cost, reward, attempt, RNG, or receipt mutation. An unmatched Campaign MID114 is also drained with family-bounded 30005 and no mutation. Existing historical Campaign battle receipt rows remain inert; no destructive migration was added.

The source protocol cannot distinguish an extremely late old MID114 from a newly staged battle for the same campaign/type because it carries no operation token. Pass123 records this as an unrecovered protocol ambiguity rather than inventing another hidden UUID.

## OTA 1.631.8

The cumulative OTA contains 138 entries. Exactly six Campaign battle Lua files were restored to byte-identical effective-source behavior in both src_32 and src_64: SelectTeamWindow, SelectTeamNewWindow, and BattleCreate. The MID50 UUID bridge in SelfPlayer and MID117 UUID bridge in SweepWindow are preserved. Volume: 2,303,136 bytes; MD5 `234fd4add049bf29d1f663bee6ba74d2`; SHA256 `825e2064d139ac13dd343a1b5231c67767028e33eb9c64d2e69e849d1afe438c`.

## Original-server persistence inference

The recovered client shape argues against a single cleared-stage pointer as the only authoritative Campaign state. `SelfPlayer` hydrates per-campaign rows into `worldMaps_` with star/dailyLimit/resetCount while also retaining summary cursors such as normal/super campaign and chapter ids. Challenge branching further requires multiple independently materialized cleared/unlocked nodes. The safest reconstruction is therefore durable per-player Campaign projection records (database/document state keyed by stage) plus cached/frontier summary pointers. The exact official database engine/schema is not recovered and is not asserted.

## Validation

Focused Pass123 tests and the current Campaign regression spine pass: Pass122 Challenge, Pass121 MID117 atomicity, Pass75 ownership, Pass81 Daily Reset Campaign corrections, Pass79 Daily Reset, Pass92 MID116 reset, Pass114 MID117 activation, the still-valid Pass117 reconciliation subset, and Python compileall. Three older scripts are retained as historical/stale harnesses for documented reasons rather than rewritten to pretend they represent current architecture.

## Next

Pass124 is the client smoke/debug/reconciliation pass for the server-owned MID113/MID114 flow and OTA 1.631.8. After Campaign structural runtime acceptance: reconcile Campaign Player EXP + Mana sweep economy, then finish the RNG Backbone, then Generated/Unique, Girls/Equipment economy closure, and deferred vertical slices.
