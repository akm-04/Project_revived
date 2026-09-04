# Stage 3.1 — Human-editable player database

## Purpose

Stage 3.1 converts the backend's canonical account/player state into a small JSON text database. It is intentionally simpler than SQLite because the current reverse-engineering workflow benefits from being able to edit a value, relog the client, and immediately compare behavior.

Default file:

```text
data/player_db.json
```

The repository reloads this file before every client request and writes handler mutations atomically (`.tmp` + replace).

## Why this is useful

The game client maintains separate models, but their server state must be coherent:

- `SelfPlayer` owns currencies, level, VIP, FunctionIDs, story/guide state and formation.
- hero model hydration comes through MID 49.
- backpack hydration comes through MID 81.
- library/background hydration comes through MID 836.
- later domain handlers consume social, campaign, shop, mission, arena, pet, etc. state.

All of these now derive from one persisted `PlayerState` instead of unrelated response literals.

## Source / Pass 19 cross-checks

Pass 19 `17_LOAD_PLAYER_INFO.md` confirms MID 17 includes the fields used here, including `mana`, `crystal`, `energy`, `lev`, `vip`, `func_ids`, `formation`, `story_id`, `story_state`, `guide_id`, `guide_function_ids`, and `guide_return_id`.

`SelfPlayer:onPlayerInfo_()` assigns those values directly and calls `StoryData:onDataFromBackend()` for the story/guide triplet.

`EcoSidebar.lua` displays:

```text
SelfPlayer.mana
SelfPlayer.crystal
SelfPlayer.energy / energy limit
```

So the top wallet is sourced from MID 17; it is not populated from MID 81 backpack data.

`Backpack.lua` expects each inventory entry to contain at least `table_id`, `item_num`, and `time`, then performs local item-table lookups. This is why the default JSON leaves inventory empty rather than fabricating item IDs.

## Tutorial/guide finding

Stage 3's established response still used:

```text
guide_id = 0
```

This was not an established account state.

Source `MainScene:onEnterGuide()` checks:

```text
if StoryData.getGuideID() < GUIDE_START then
    open guided summon-hero flow
end
```

Relevant source constants:

```text
GUIDE_START = 100101
GUIDE_END = 100197
GUIDE_PET_ONE = 100501
GUIDE_PET_THREE = 100503
GUIDE_CONQUER_SCHOOL_END = 101001
```

The default Stage 3.1 JSON therefore uses:

```json
"guide_id": 101001
```

This is a test-profile choice derived from source behavior: it places the local established account beyond the known later guide families instead of leaving it at tutorial start.

MID 26 `SAVE_STORY` is source-confirmed to send `story_id`, `story_state`, and `guide_id`; Stage 3.1 persists those values back to the JSON file. The guide-function and guide-return handlers are also persisted.

## Function gates

There are two related client gates:

1. `SelfPlayer:isFuncOpen(id)` uses the server-provided MID 17 `func_ids` map.
2. global `xyd.isFunctionOpen(id)` compares local `StoryData.stageID_` and player level against the function table.

`StoryData.stageID_` starts at zero and the supplied Lua only advances it from battle-ended state; it is not populated by MID 17. This distinction should be remembered if a later subsystem uses the global helper even after its FunctionID is present in the server record.

For MainScene's principal lobby buttons, the source commonly uses `SelfPlayer:isFuncOpen`, so the JSON profile keeps the source-derived FunctionIDs enabled.

## File layout

The nested sections are organizational only. They deserialize into the existing `PlayerState` dataclass.

```text
account
player.identity
player.progression
player.economy
player.heroes
player.inventory
player.library
player.lobby
player.domains
```

New `PlayerState` fields not yet assigned to a section are automatically preserved under `player.domains`.

## Hot editing

Example: change currency while the server is running:

```json
"economy": {
  "mana": 500000,
  "crystal": 123456,
  "energy": 80,
  "max_energy": 100
}
```

The backend will read those values on the next request. The already-running Android client will only update when an appropriate response/event is received. For MID 17 fields, relog/reselect the server after editing.

An invalid JSON edit does not terminate the backend: the repository logs the load error and keeps the last known-good in-memory state until the file is corrected.

## Hero test record

The default roster contains a source-valid partner table row:

```text
table_id = 10001001 (Aquaris)
partner_id = 10001 (local deterministic entity id)
star = 3
level = 20
```

MID 49 serializes the `heroes` map. MID 65 `LOAD_COLLECTED_HEROS` is adapted to the client consumer's `params.list` representation, while the JSON file keeps a richer collected-hero map for future extension.

## Next live-test markers

The strongest markers remain:

```text
176  LOAD_FRIENDS
2754 CHECK_GAME_STAT
```

No MID 176 means `MainSceneBottomWindow.willOpen()` still did not reach its late social initialization. No MID 2754 means `MainSceneTopWindow.willOpen()` still did not reach the end of its initial construction chain.

If both remain absent after the established guide state is applied, the next pass should trace the exact synchronous Lua operation immediately before those boundaries instead of adding arbitrary inventory/currency values.
