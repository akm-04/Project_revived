# Stage 3 Domain Foundation

Date: 2026-08-16

## Decision

Stage 3 stops the single-window/button hotfix strategy. Pass 19 is used as the protocol/domain compass; `src_64` is consulted only where implementation-critical response shapes need confirmation.

## Source-confirmed corrections to old Stage 2 wide hydration

- `115 LOAD_TRIAL_INFOS` now contains `trial_info.trials`, `trial_info.campaigns`, `challenge_info.challenges`, and `challenge_info.campaigns`.
- `336 LOAD_MARCH` now contains `map_info`, `hero_status`, `enemies`, and `rewards`; `map_info` includes numeric reborn/stage/passed fields.
- `2416 GET_ADVENTURE_LIST` now contains `adventure_list.list`.
- `2984 BATTLE_PASS_GET_INFO` now contains initialized `base_info` and `mission_info`.
- `368 LOAD_MAIL_LIST` now uses `mail_list`, `total`, and `new_mail_total`.
- `384 LOAD_INVITE_INFOS` now contains `missions`, `invite_players`, `invite_code`, `invitor_id`, and `invitor_name`.
- `624 WORLD_BOSS` now contains numeric `total_hurt`, ranking/times fields, and `boss_info` with a source-valid world-boss campaign id (`10011`).
- `112 LOAD_WORLD_MAP` now includes concrete `chapter_info` fields and source campaign `100001`.

These corrections are the basis of the new `GXB_BOOTSTRAP_DETAIL_MODE=stage3` mode. `safe` remains the rollback mode.

## Domain ownership added

### Practice
Pass 19 finite dynamic family `124–133` is owned by `PracticeHandlers`.

### Battle
MIDs `208–213` are owned by `BattleHandlers` with canonical formation state and minimal battle-session envelopes.

### Arena
Core `272–300` arena surfaces and Pass 19 dynamic formation/report/pre-fight branches are owned by `ArenaHandlers`.

### Mission/task
Mission bootstrap and action families are owned by `TaskHandlers`; `TASK_LOAD_BY_TYPE` remains supported.

### Social
Friends, requests, blacklist/recommend/search information are owned by `SocialHandlers`.

### Guild/team
Team/drink/rental/guild-campaign surfaces use fields statically consumed by `SelfGuild.lua` where confirmed.

### Pets
Pet base actions, pet practice, and pet-campaign compatibility surfaces are grouped under hero/pet domain handlers.

### Shop/market
Shop list/load/buy plus market cart and skin-shop compatibility surfaces are owned by `ShopHandlers`.

### World
Campaign/trial/march/world-boss/adventure state is owned by `WorldHandlers` and canonical `PlayerState` payload builders.

## Source-valid seed data

Stage 3's established profile seeds partner table id `10001001` (Aquaris), the first real row decoded from `data/tables/partner.lua`, rather than inventing a frontend character table id. The local instance id is `10001`.

## Known limitations

- Full battle simulation/replay is not implemented.
- Event-specific `LOAD_SINGLE_ACTIVITY.details` remains activity-dependent.
- Real gacha probability/pool semantics are not implemented yet.
- Chat TCP is still a boundary/stub, not a full room protocol.
- Many late-game/event-specific MIDs still fall through the compatibility logger.
- Payment remains intentionally unimplemented.
