# Stage 3.1.6 — bootstrap `server_time` MainScene fix

## Live boundary

Stage 3.1.5 still reached the lobby, but MainScene remained incomplete:

- MID 612 `GET_SELF_GUILD` appeared.
- MID 176 `LOAD_FRIENDS` did not appear.
- MID 2754 `CHECK_GAME_STAT` did not appear.
- Bottom buttons remained absent/disabled and the top economy/player HUD did not render.

The Stage 3.1.5 server trace also showed that the root MID1 response had no top-level `server_time`.

## Source-confirmed root cause

`app/common/ServerTime.lua` starts with `canGetServerTime_ = false`. Until reset, `getServerTime()` returns `nil`.

`app/common/network/Backend.lua:extraWebResponseCheck_()` resets the clock whenever a successful response contains top-level `server_time`. This hook runs before the MID event/callback.

The existing MID1 detail entry `176` does **not** solve this: `SelfPlayer:loadGameStartInfoEvent_()` has no LOAD_FRIENDS boot-detail consumer, so it does not call `SocialSystem:loadFriends()` and does not reset ServerTime.

Two independent MainScene paths then use the nil clock synchronously:

1. `MainSceneBottomWindow:willOpen()`
   - sends `GET_SELF_GUILD` when Guild is open;
   - calls `updateBackendRedmark()`;
   - `BattlePass:isOpen()` compares configured season times with `ServerTime:getServerTime()`;
   - with an uninitialized clock, this comparison can abort before the unconditional `socialSystem:loadFriends()` (MID176).

2. `MainSceneTopWindow:willOpen()`
   - enters `initActList()`;
   - `updateButtonTable()` evaluates `adventureEventEarliestTime - ServerTime:getServerTime()`;
   - with an uninitialized clock, this can abort before `onEnterAction()` / `checkGameStat()` (MID2754).

This explains the observed pair of missing MIDs and why the entry-action touch unlock never completes.

## Fix

MID1 `RETRIEVE_TOKEN` now includes a top-level:

```json
"server_time": <current unix seconds>
```

This is intentionally attached to authenticated bootstrap MID1 rather than every engine response, avoiding a pre-login ServerTime scheduler while still guaranteeing the clock exists before MainScene construction. Existing `LOAD_FRIENDS.server_time` remains unchanged and will refresh the clock again once MID176 runs.

## Scope

No new MIDs, no payment changes, no fake formations, no client patching. Stage 3.1.5 region-contract and identity fixes are retained.
