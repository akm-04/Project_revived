# v0.8.3 — Runtime Campaign Level-Up Synchronization Fix

## Scope

This release is a narrow correction derived from the user's v0.8.2 runtime logs. It does not change the Pass 25 architecture or expand Campaign RNG/Missions/PvP.

## What the runtime test proved

The first Campaign transaction itself succeeded. MID114 for Campaign 100001 returned:

- `items=[{item_id=20001001,item_num=1}]`;
- `economy_={mana=495,exp=18,lev=4}`;
- cumulative `exps` of 75 for partners 1, 2 and 3.

The client displayed the level-up state, then failed during `Backend.extraWebResponseCheck_()` while processing the global ECONOMY event.

The uploaded client error identifies the failure as:

`SelfPlayer.lua:1551: attempt to call method 'invitation' (a nil value)`

## Source root cause

Authoritative `src_64/app/model/SelfPlayer.lua`:

1. stores `params.invitation` during player bootstrap;
2. after every ECONOMY response, if `self.invitation` is truthy, it enters the invitation recovery block;
3. that block calls `getInvitationLimit()`;
4. `getInvitationLimit()` calls `xyd.tables.player:invitation(self.lev)`.

Authoritative `src_64/data/tables/player.lua` has only:

`lev, energy, exp, award_energy, total_exp, hero_lev, power, expedition_mana`

There is no `invitation` column, so no generated `player:invitation()` accessor exists.

The same block checks `xyd.FunctionID.ARENA`; the authoritative enum contains `ID_ARENA=4`, not `ARENA`.

This is a shipped-client compatibility defect exposed because v0.8.2 is the first fresh-player slice that emits meaningful `economy_` updates.

## Backend compatibility decision

Arena/PvP is still intentionally deferred. Therefore v0.8.3 omits:

- `invitation`;
- `invitation_time`;
- `max_invitation`

from player-info projection for **all profiles**, including the AdminRoot sandbox. Internal fields remain in PlayerState so competitive restoration can later reintroduce them together with the correct Arena implementation.

Credential state copied from earlier versions is additionally normalized to unavailable invitation state.

## Source-backed Energy correction

The old fresh-player template used `energy=100`, inherited from the established sandbox. Source `player.lua` gives level-1 Energy `60` and `award_energy=6`.

`SelfPlayer:economySyncEvent_()` performs this loop when cumulative `economy_.exp` arrives:

- capture old current Energy;
- while cumulative EXP crosses the current level threshold, add `player:awardEnergy(current_level)` and increment level;
- present the resulting Energy in the level-up window;
- later consume cumulative `economy_.energy` as authoritative state if present.

For EXP `0→18`:

- level 1 threshold 6;
- level 2 threshold 12;
- level 3 threshold 18;
- result level 4;
- award Energy = 6+6+6 = 18;
- fresh Energy 60→78;
- level-4 normal Energy cap from source = 64.

v0.8.3 now performs the same level-crossing Energy award in `EconomyRepository` and returns cumulative `economy_.energy` when player EXP causes a level-up.

This is independent of Campaign stamina spending, whose exact authoritative transaction point remains unresolved and is still deferred.

## Legacy credential migration

v0.8.0-v0.8.2 credential players were created from the known local fresh template with exact `energy=100`, while Campaign stamina spending was not implemented. On load, v0.8.3 treats that exact credential-only signature as the legacy template and migrates:

`energy = 60 + sum(award_energy for levels 1 .. current_level-1)`

It also refreshes `max_energy` from the current source player row.

This lets the already-tested level-4 / EXP-18 account resume with Energy 78 instead of requiring deletion.

## Opening Skip behavior

The separate runtime run where the user pressed Skip/Skip sent MID26 with `story_id=10005`, `guide_id=100262`, `story_state=0`. That is the client deliberately persisting a later guide checkpoint. The absence of the early forced tutorial afterward is therefore not evidence of lost server tutorial state.

## Deferred systems unchanged

- Campaign energy-cost/defeat-cost commit timing;
- random Campaign repeat drops;
- lower-probability first-clear drops;
- Missions and claims;
- equipment mutation;
- contract/stone Hero summon;
- star bonuses;
- general gacha;
- Arena/PvP.
