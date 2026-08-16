# GXB Modular Stage 3.1.7 Backend — Lobby Persistence Fix

Stage 3.1.7 keeps the Stage 3.1.6 `server_time` breakthrough and fixes two newly source-confirmed post-MainScene contracts that match the user's latest live run:

1. the automatic daily sign-in popup was being opened with an incomplete MID353 response, which can leave MainScene's background UI hidden;
2. MID1056 `GET_BUILDING_LIST` returned the wrong shape, so `ServerTime` retried it every second and `EventCentre` could not hydrate its timer/redmark state.

## Run

```bash
python3 server.py
```

Default services:

- SDK/native compatibility HTTP: `5000`
- engine/game HTTP: `9000`
- minimal chat TCP boundary: `9100`

The Stage 3.1.5 identity/server-selection fixes and Stage 3.1.6 root MID1 `server_time` field are retained.

## Why the lobby vanished after one second

The latest live run now reaches both of the previously missing MainScene milestones:

```text
176   LOAD_FRIENDS
2754  CHECK_GAME_STAT
1302  LOAD_ACHIEVEMENT_INFO
```

Immediately afterward the client automatically walks its ordered popup chain:

```text
pic_notice -> sign_in -> welfare/seven-day/gift popups
```

The current bootstrap supplied `is_signed=0`, so the client automatically sent MID353 `SIGN`. `sign_in` is a `show_background=1` window. When such a window opens, `MainSceneTopWindow:setBgVisible(true)` hides the poster-girl window, middle menu, and most top/player controls while leaving the economy sidebar and bottom strip visible. That exactly matches the latest visual result.

The old MID353 implementation only returned `{"awards": []}` while `SignInWindow` later consumes `is_signed`, `sign_times`, and `award`. Rather than invent a reward/item contract, the established-profile default now reports daily sign-in as already complete (`is_signed=1`) in both boot detail MID352 and explicit `LOAD_SIGN_INFO`. The automatic chain therefore skips `sign_in`.

MID8193 `GET_PIC_NOTICE_INFO` is also corrected to the exact no-popup fields read by `MainScene`:

```json
{"has_read": 1, "contents": []}
```

## MID1056 building/event-centre fix

The previous backend returned:

```json
{"list": []}
```

but `EventCentre:getBuildingList()` directly reads:

```text
building_list
cabinet_info
desk_info
pet_cabin_info
```

and immediately dereferences building rows 1/4/5/6. Stage 3.1.7 now supplies all seven source-defined building rows (`CABINET` through `PETROOM`) with idle compatibility defaults plus complete idle `desk_info`, `pet_cabin_info`, and `cabinet_info` structures.

This should eliminate the one-request-per-second MID1056 loop seen in Stage 3.1.6.

## Next APK test

Expected startup behavior:

```text
176   LOAD_FRIENDS              still appears
2754  CHECK_GAME_STAT           still appears
8193  GET_PIC_NOTICE_INFO       may appear
353   SIGN                      should NOT auto-fire
1056  GET_BUILDING_LIST         may occur once/few times, but should not repeat every second
```

Visually, the poster girl, middle buttons, and top-left/player controls should remain visible after the entry animation. Backpack/chat should remain usable.

Retest **Girls** after this. If it still does nothing, use the request log as the next discriminator:

- MID49 `LOAD_HEROS` appears after the click -> inspect the hero-list payload/window consumer;
- no MID49 -> investigate click/window overlap/function-gate behavior, not the hero response.

## Known deliberate gaps

- MID353 `SIGN` remains an incomplete compatibility stub. It should not be auto-triggered by the established profile in this stage; do not invent reward item IDs.
- Payment remains permanently out of scope.
- TCP chat remains minimal.

## Validation

Only Python syntax compilation is performed before handoff. No Flask, HTTP, APK, emulator, or ADB runtime test is run by the build process.
