# Stage 2.3 MainScene HUD Fix Notes

Date: 2026-08-16

## User-observed blocker

Stage 2.2 boots/login/select-server and reaches the lobby scene, but the visible HUD is incomplete:

- top resource/header bar does not appear;
- common lobby buttons are not visible/usable;
- backend receives no unknown MID and no fallback responses;
- backend receives repeated `LOAD_CHAT_ROOM_INFO` calls but does not receive `LOAD_FRIENDS` or `CHECK_GAME_STAT`.

The Stage 2.2 request log proves the client reaches the early MainScene fanout and receives successful responses for:

- `1537 GET_BOARD_INFO`
- `192 LOAD_CHAT_ROOM_INFO`
- `836 GET_LIBRARY_INFOS`
- `612 GET_SELF_GUILD`
- `1344 ILLUSION_LOAD_INFO`
- `56 LOAD_SUMMON_INFO`

The absence of `176 LOAD_FRIENDS` and `2754 CHECK_GAME_STAT` is therefore significant.

## Source-derived narrowing

`MainScene.lua` opens windows in this order:

1. `main_scene_left`
2. `main_scene_middle`
3. `main_scene_bottom`
4. `main_scene_touch`
5. `main_scene_top`

`MainSceneMiddleWindow` sends `LOAD_SUMMON_INFO` and `ILLUSION_LOAD_INFO`, both of which are observed in the live log.

`MainSceneBottomWindow.willOpen()` performs guild/pet/redmark setup and then unconditionally calls:

```lua
socialSystem:loadFriends(...)
```

which should send `176 LOAD_FRIENDS`.

`MainSceneTopWindow.willOpen()` calls `checkGameStat()`, which should send `2754 CHECK_GAME_STAT` after top/HUD construction starts.

Because Stage 2.2 sees `GET_SELF_GUILD` but not `LOAD_FRIENDS` and not `CHECK_GAME_STAT`, the likely abort window is inside `MainSceneBottomWindow.willOpen()` before the social load, preventing the later top-window/HUD path.

## Risky Stage 2.2 choice

Stage 2.2 advertised every source-derived `xyd.FunctionID` in `player_info.func_ids`. That did unlock many systems, but it also enabled complex boot-time branches before the backend has complete domain state.

Two specific risks were identified from source:

1. `ID_PET` causes `MainSceneBottomWindow` to enter the pet bootstrap branch and schedule `GlobalTimer:checkIsMakingChild()`.
2. `GlobalTimer:onTimer()` iterates `pairs(selfPlayer.collectedPets)` without a nil guard.

`SelfPlayer.loadCollectedPets()` normally initializes `collectedPets = {}` before requesting `PETS_GET`, but Stage 2.2 did not inject `780 PETS_GET` in safe bootstrap detail and the live request log did not show an explicit `PETS_GET` call before the MainScene path stalled.

## Stage 2.3 changes

Stage 2.3 makes the lobby/HUD mode conservative again:

- Default function exposure is now `GXB_FUNC_MODE=core`.
- Core mode exposes only stable lobby/HUD/common-window FunctionIDs.
- Pet, guild, and deep optional systems are not advertised by default.
- Full Stage 2.2 behavior remains available with:

```bash
GXB_FUNC_MODE=all python3 server.py
```

Stage 2.3 also adds source-backed `780 PETS_GET` hydration to safe `RETRIEVE_TOKEN.detail`:

```json
"780": {"pets": {}}
```

This keeps `SelfPlayer.collectedPets` safe as an empty table if any pet-aware code path still executes.

## Test expectation

Default test command:

```bash
python3 server.py
```

Expected improvement:

- `176 LOAD_FRIENDS` should appear after bottom-window construction.
- `2754 CHECK_GAME_STAT` should appear when top-window/HUD construction starts.
- top HUD/resource bar should become visible.
- common core lobby buttons should become visible/usable.

If HUD appears in core mode, Stage 3 can re-enable optional systems one by one, starting with guild and then pet.
