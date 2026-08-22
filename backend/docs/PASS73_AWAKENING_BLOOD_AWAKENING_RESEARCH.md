# Awakening / Blood Awakening source deep dive — research only

**Status:** research complete enough to blueprint a dedicated implementation pass; no Awakening code is installed in Pass73.

## Key correction
The missing `xyd.mid.AWAKE_HERO` is real, but it is **not the active mission completion path**. The wired flow uses `TASK_AWAKE_OPEN` (2738), qualifying Campaign/special-battle result signals, and `TAKE_MISSION_AWARD` (161). `SelfPlayer.awakeHero()` should be treated as stale/version-drift unless runtime evidence proves otherwise.

## Ordinary Awakening
- `465` source mission rows cover `164` Heroes: `164` stage-1 rows, `164` stage-2 rows, and `137` auxiliary stage `-1` records.
- Opening is initiated from the Hero awaken-equipment slot. Effective open level is 90 and only one active HERO awake mission is allowed.
- Stage 1 is the exclusive-awaken gear/material requirement.
- Stage 2 is a Hero-specific Campaign objective. Objective distribution: SELF_KILL `20`, DAMAGE_ACHIEVE `3`, ALONE_KILL `15`, ALL_ALIVE `126`.
- `SelectTeamWindow` preselects the required Hero. `BattleCreate:getAwakeMissionResult()` validates the special condition. Only on success does `FIGHT_RESULT` include `awake_mission=<mission_id>`.
- The final task is claimed via MID161; on OK the client locally changes the Hero table ID from before-awaken to after-awaken and unlocks the Awake skill. The future server must persist the same canonical Hero state atomically.

## Blood Awakening
- `162` source rows cover `81` awakened Heroes: 81 stage-1 and 81 stage-2 rows.
- Requires the Hero already awakened, level 100, quality/color 15, source `isCanAwakeTwice`, and `twice_awake_stage == UNSTART`.
- Stage 1 is bloodline-exclusive gear.
- Stage 2 opens `awake_twice_select_team`, requires at least two selected Heroes, then calls `UNLIMIT_START_FIGHT` with `twice_awake_mission` and `incubus_id`. A win later sends `UNLIMIT_FIGHT_RESULT` with the mission ID; loss does not.
- Final MID161 claim unlocks AwakeTwice; canonical server state must progress `twice_awake_stage` to COMPLETE (3).

## Current private-server gap proven by Pass72 runtime
The Pass72 smoke issued five real `TASK_AWAKE_OPEN` requests for mission IDs `1067001` and `1001001`. They currently route to `TaskHandlers.mission_status`, return empty superficial success, and create no mission state. This exactly explains the observed failed Awaken test.

## Recommended next architecture
Use a dedicated Awakening mission aggregate/service coordinated with Hero ENTITY and battle-result handling. Do **not** treat awakening as one Hero mutation MID. The durable seams are open/give-up, Campaign `FIGHT_RESULT`, Bloodline `UNLIMIT_FIGHT_RESULT`, and claim/final Hero mutation.
