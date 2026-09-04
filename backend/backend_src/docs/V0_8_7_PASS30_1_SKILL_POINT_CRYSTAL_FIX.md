# v0.8.7 / Pass 30.1 — Skill Point + MID99 Crystal Fix

## Scope

This is a narrow runtime patch on top of v0.8.6. No new MID is mapped and no integer planning pass is created.

## Runtime-confirmed defect

Fresh credential progression reached FunctionID33/Skill Upgrade with zero Skill Points, forcing the client into a VIP2 purchase path before the tutorial could continue. A separate established VIP15 probe showed MID99 changing `buy_skill_times` and Skill Points without decrementing Crystal.

## Source contracts used

Effective-source resolution is writable hot-update over APK baseline for each path independently.

- `app/model/SelfPlayer.lua:getSkillPoint/recoverByTime/buySkillPoint`
  - `skill_time=0` is the no-regeneration sentinel;
  - timed recovery uses the source natural cap;
  - MID99 direct callback consumes `buy_skill_times`, `skill_point`, `skill_time`.
- `data/tables/misc.lua`
  - Skill Point recovery interval = 300 seconds.
- `data/tables/vip.lua`
  - `skill_max` defines the natural timed-recovery cap;
  - `skill_buy` defines whether MID99 purchase is available.
- `data/tables/monthly_privilege.lua`
  - privilege row 1 adds its `skill_max` bonus to the natural cap while active.
- `data/tables/refresh_cost.lua` + `RefreshCostTable.lua:buySkillCost`
  - purchase N uses `buy_skill_cost[N]`, falling back to the final configured row above maxTimes.
- `data/tables/translation.lua:SKILL_POINT_BUY`
  - one purchase grants 10 Skill Points.
- `app/windows/HeroMainWindow.lua:addSkillLevel`
  - source UI pre-checks VIP purchase permission and Crystal balance before MID99.

## Server behavior

### Fresh credential player

`MultiUserDatabase.create_fresh_player()` initializes the canonical Skill Point pool to `SkillPointPolicy.max_points()` for the player's current VIP and sets `skill_time=0`. For VIP0 this is 10.

This starting-pool choice is a runtime-informed compatibility policy, not a claim that the original server's account-creation database row has been recovered. The value itself comes from effective source.

### Natural cap versus absolute points

The source cap controls timed regeneration only. Purchase/item grants may leave `skill_point > natural_cap`.

- at/above natural cap: `skill_time=0`;
- below cap with no timer: start `skill_time=server_now`;
- spending from full/over-cap to below cap starts recovery;
- timed recovery stops again at the natural cap.

### MID99

The server:

1. applies legitimate elapsed timed recovery;
2. validates current VIP `skill_buy` permission;
3. derives purchase number from `buy_skill_times + 1`;
4. derives Crystal cost from effective `refresh_cost.lua`;
5. validates/spends Crystal through `EconomyRepository.spend_crystal(..., persist=False)`;
6. increments `buy_skill_times`;
7. grants source-derived +10 Skill Points;
8. normalizes the timer against the natural cap;
9. saves once.

`ResponseProjector` captures the Crystal mutation and attaches cumulative `economy_.crystal`. Skill Point remains a direct MID99 field, not a generic projected economy field, preserving the known MID90 compatibility boundary.

Current source purchase examples: #1=10 Crystal, #2=20, #3=20, #4=40.

## Effective-source metadata

`tools/build_hero_skill_regen_meta.py` now requires `--apk-root` and optionally `--writable-root`, resolves every consumed path using writable precedence, and writes `_meta.source_resolution=effective_merged`. `SkillPointPolicy` refuses unstamped metadata.

## Boundaries

No changes to Campaign rewards/stamina/RNG, Story Mission semantics, Skill level formulas/costs, Institute, Guild or PvP.
