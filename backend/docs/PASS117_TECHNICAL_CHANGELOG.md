# Pass117.0 Technical Changelog

- Activated source-bounded `campaign_first_clear_bernoulli_v1` for Normal/Super MID113 `init_dropbox` only, through `RandomOutcomeService` namespace `campaign.first_clear.row`.
- Added one `campaign_battle_op_id = mid113-<UUIDv4>` spanning MID113 staging through MID114 result settlement.
- Added permanent UoW stage/result receipts with request fingerprints, exact stage/result replay, supersede protection, and no-reroll/no-double-settlement semantics.
- MID114 commits the frozen MID113 DropPlan on victory only; loss terminalizes without granting it. Staged drops remain absent from MID114 `items` because the client already mirrors `BattleCreate.dropItems` through `BattleWinWindow`.
- Added cumulative OTA 1.631.7 for `SelectTeamNewWindow.lua`, `SelectTeamWindow.lua`, and `BattleCreate.lua` in src_32/src_64; all 132 prior overrides are byte-preserved.
- Added MID113/MID114 application-error guards preventing rejected backend operations from entering local battle/reward success paths.
- Normalized `LOAD_WORLD_MAP.challenge` to the source-required Campaign-row array and synthesize exact Campaign 24111 after canonical clear of Normal 1600016; MID114 emits the same row for immediate unlock.
- Kept MID113 repeat RNG `disabled_unknown`; no Challenge battle/progression implementation was folded into this pass.
