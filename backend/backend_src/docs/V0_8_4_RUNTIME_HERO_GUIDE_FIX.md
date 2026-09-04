# v0.8.4 Runtime Hero / Guide Compatibility Fix — 2026-08-17

## Runtime evidence entering this patch

The user's fresh v0.8.3 device run confirms the Campaign economy slice substantially farther than v0.8.2:

- registration and opening tutorial sequence work;
- Campaign 100001 clears without the former loading-overlay freeze;
- cumulative Campaign Mana and player EXP/level-up presentation continue across later stages;
- later Campaign progression and manual naming are reachable.

Therefore v0.8.4 deliberately leaves the v0.8.3 Campaign transaction unchanged.

## Guide 100135 double-overlay

The runtime reaches guide 100134. Source `MapWindow` transitions this to guide 100135 and emits operation log 49; the runtime contains that operation log. Guide 100135 text is `Let's get that letter!` and belongs to the Fight-3 Campaign-node sequence. The later explicit Hero-scroll guide is 100147, `It's a battle girl's scroll!`.

The backend had returned `A` for every MID2864 A/B query. Source `abtest.lua` describes MTSPY as A = weak guide enabled, B = weak guide disabled. At level 7, guide-function 17 is eligible. The runtime later sends MID2865 for guide-function 17 immediately after the user skips the stuck double overlay.

v0.8.4 compatibility policy: return `B` for MTSPY only. This selects the shipped client's source-defined no-weak-guide branch while preserving A for unrelated experiments. It is not claimed as the old production cohort assignment.

## MID119 generated names

Runtime error:

`EditPlayerNameWindow.lua:83: attempt to index field 'nameList' (a nil value)`

Source `EditPlayerName:onGeneratePlayerName_()` assigns `event.params.player_name_list` to the model's name list. v0.8.3 returned the wrong field `{name=...}`.

v0.8.4 returns a non-empty deterministic `player_name_list` using entries derived from source `data/tables/random_name.lua`. The historical server's random selection algorithm is not inferred.

## MID54 / MID62 / MID57

Runtime requests show:

- MID54 `SET_HERO_EQUIP` for tutorial Aquaris equipment;
- repeated MID62 `ONE_CLICK_EQUIP` for Aquaris and Pandaria;
- MID57 `ONE_CLICK_JINJIE` for Lavia.

All three were status-only in v0.8.3.

Source behavior:

- MID54 request: `{partner_id,equip_index}`. On OK, the client sets the slot collected and removes the exact current-color gear from its local Backpack.
- MID62 request: `{partner_id}`. The client changes equipment only when the response includes `equips`.
- MID57 request: `{partner_id}`. On OK, an early NormalHero locally advances color and clears ordinary equipment/Fumo arrays.

Consequently v0.8.3 could show successful MID54/MID57 mutations only locally while leaving canonical state unchanged, whereas MID62 visibly animated but changed nothing.

## Canonical early-Hero transaction

New `HeroEquipmentRepository` owns this narrow mutation boundary while delegating shared state to existing owners:

- `HeroRepository`: canonical Hero record/color/equips;
- `InventoryRepository`: canonical materials and EXP potions;
- `HeroProgressionRepository`: cumulative Hero EXP and source Hero-level cap;
- `EconomyRepository`: compose-Mana spending.

Generated `data/hero_equipment_meta.json` is built without executing Lua from supplied authoritative tables. It currently contains 555 partner rows, 5,838 item rows, 3,469 unique source name entries, and the source ordinary-Hero table boundary.

The one-click planner mirrors the relevant `HeroMainWindow` source behavior:

1. derive the six current-color gear IDs;
2. recursively consume an existing target item when an unreserved copy exists;
3. otherwise recurse through `compose` / `compose_num` and add `compose_mana`;
4. reject gear above the source player-derived Hero level cap;
5. when required, calculate enough EXP juice to reach the highest selected gear level in the source potion order;
6. prevalidate materials and Mana before mutation;
7. consume canonical items/potions, spend canonical Mana, grant canonical Hero EXP;
8. persist equips or next Hero color and save once;
9. return client-consumed response fields (`equips` for MID62, `restore_items=[]` for the safe early MID57 path, cumulative `economy_.mana` when compose Mana changed).

## Boundary

This is not a general Hero advancement reconstruction. Awaken/bloodline/Fumo restoration semantics remain deferred. The repository fails closed outside the source-backed early ordinary NormalHero boundary.

Story Mission MID2736/MID161, MID59 stone summon, MID118 star rewards, Campaign stamina, general Campaign RNG, general Vending RNG, and Arena/PvP remain deferred exactly as documented by Pass 25/26.

## Assistant validation

Only Python static compilation is performed. User-device runtime remains authoritative.
