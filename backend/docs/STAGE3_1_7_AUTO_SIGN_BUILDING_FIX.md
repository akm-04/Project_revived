# Stage 3.1.7 — automatic sign popup + EventCentre building contract

Date: 2026-08-16

## Live result that motivated this pass

Stage 3.1.6 was the first build to cross the MainScene initialization barrier:

- MID176 `LOAD_FRIENDS` appeared after MID612;
- MID2754 `CHECK_GAME_STAT` appeared;
- MID1302 achievement load appeared;
- top mana/crystal/energy HUD rendered;
- bottom strip rendered and Backpack/Chat were usable.

New symptom: poster girl + middle menu + most top-left/player controls were visible briefly and then disappeared, while economy and bottom remained. Live requests at the disappearance included MID8193 `GET_PIC_NOTICE_INFO`, MID353 `SIGN`, followed by a one-second MID1056 `GET_BUILDING_LIST` loop.

ADB/logcat did not expose a useful Lua traceback at that moment; only normal HTTP completions and bitmap-font warnings were visible.

## Source-confirmed automatic sign-in hide path

`MainScene:openWindowInOrder()` walks:

```text
pic_notice -> sign_in -> walfare_activities -> seven_day_login -> gift_push
```

For `sign_in` it calls `SelfPlayer:loadSignInfo()`. If `SelfPlayer.isSigned == 0`, it sends MID353 `SIGN`, then opens `sign_in` with the response.

`data/tables/window.lua` marks `sign_in` with `show_background=1`.

`WindowManager:setBackground()` recomputes `isShowBackground()` and calls `main_scene_top:setBgVisible(...)`.

`MainSceneTopWindow:setBgVisible(true)` hides:

- `left_container`
- `player_container`
- `extra_container`
- `main_scene_middle`
- `main_scene_left`

but does not hide the economy sidebar or bottom strip. This matches the user's visual symptom exactly.

Stage 3.1.6 boot detail MID352 set `is_signed=0`, and the live server returned MID353 as only `{"awards":[]}`. `SignInWindow:showSignInRes()` instead directly consumes `is_signed`, `sign_times`, and `award`. The Stage 3.1.6 MID353 contract was therefore insufficient for a real sign-in window.

### Stage 3.1.7 behavior

For the established test profile:

```json
{
  "awards": [],
  "is_signed": 1,
  "partner_id": 0,
  "sign_times": 0,
  "month": 1,
  "is_skin": 0
}
```

is now returned both in bootstrap detail MID352 and explicit `LOAD_SIGN_INFO`. This skips the automatic sign-in popup without inventing award/item IDs.

`GET_PIC_NOTICE_INFO` is corrected from `{"list":[]}` to source-consumed no-popup shape:

```json
{"has_read":1,"contents":[]}
```

## Source-confirmed MID1056 contract

`EventCentre:getBuildingList()` requires:

- `building_list`
- `desk_info`
- `pet_cabin_info`
- `cabinet_info`

and immediately dereferences building rows:

- 1 CABINET
- 4 BOOKSHELF
- 5 ADMIN
- 6 BOARD

The enum defines seven building IDs total (1..7).

Stage 3.1.6 returned `{"list":[]}`, leaving `deskInfo` unset. `ServerTime:handleActCentreRedPoint()` calls `getBuildingList()` whenever `deskInfo` is absent. This explains the observed one-second MID1056 request storm after ServerTime began functioning.

Stage 3.1.7 returns an idle/default source-safe structure with all building IDs 1..7 plus:

```text
desk_info: is_making/make_need_time/make_start_time/make_item
pet_cabin_info: same + pet_id
cabinet_info: cur_learn_skill/need_time/start_time/recent_complete_skill
```

Field names are source-confirmed; zero/level-1 values are compatibility defaults.

## Girls button

Do not change hero-list semantics in this pass. `MainSceneBottomWindow` should issue MID49 `LOAD_HEROS` when the Girls button is actually accepted. Stage 3.1.6 server logs did not show an explicit MID49 after the reported failed click, so first remove the broken automatic background window and retest.

## Validation boundary

Only `python -m py_compile` is allowed for handoff validation. Result: **PASS — 55 Python files compiled**. No Flask/HTTP/APK/ADB runtime test was performed here.
