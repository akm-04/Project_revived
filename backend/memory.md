# Stage 3.1.7 update — automatic sign popup + EventCentre building contract

Current stage: **Stage 3.1.7 auto-sign/building-fix**  
Date: 2026-08-16

## User-confirmed Stage 3.1.6 breakthrough

Stage 3.1.6 root MID1 `server_time` was the correct MainScene prerequisite and produced a major improvement:

- MID176 `LOAD_FRIENDS` now appears after MID612.
- MID2754 `CHECK_GAME_STAT` now appears.
- MID1302 `LOAD_ACHIEVEMENT_INFO` appears.
- top mana/crystal/energy HUD renders.
- bottom strip renders and Backpack + Chat are usable.
- the lobby is no longer globally touch-locked.

New symptom: poster girl, middle menu, and most top-left/player controls appear briefly, then vanish after roughly one second. Economy HUD + bottom strip remain. Girls button still does not work. Treat poster-girl randomization itself as low priority; functional lobby remains primary.

## Source-confirmed reason the visible lobby hides

`MainScene:openWindowInOrder()` automatically walks:

`pic_notice -> sign_in -> walfare_activities -> seven_day_login -> gift_push`

after the established guide threshold is met.

Stage 3.1.6 bootstrap detail MID352 reports `is_signed=0`. Because that detail hydrates `SelfPlayer.signInfoLoaded_`, the later `loadSignInfo()` callback does not need another LOAD_SIGN_INFO request; it sees `isSigned == 0`, sends MID353 `SIGN`, and opens `sign_in` on success.

The live Stage 3.1.6 trace confirms this timing: MID8193 `GET_PIC_NOTICE_INFO` and MID353 `SIGN` are emitted immediately after MainScene finishes its primary loads. MID353 currently returns only `{"awards":[]}`.

`data/tables/window.lua` marks `sign_in` with `show_background=1`.

`WindowManager:setBackground()` calls `main_scene_top:setBgVisible(isShowBackground())`. `MainSceneTopWindow:setBgVisible(true)` hides:

- `left_container`
- `player_container`
- `extra_container`
- `main_scene_middle`
- `main_scene_left`

but leaves the economy sidebar and bottom strip. This exactly matches the user's visual report.

`SignInWindow:showSignInRes()` consumes `is_signed`, `sign_times`, and `award`; the current MID353 `{"awards":[]}` is not a complete real sign result. Do not invent an award/item ID just to fill it.

### Stage 3.1.7 sign strategy

The established-profile default now returns `is_signed=1` in both:

- boot detail MID352;
- explicit `LOAD_SIGN_INFO`.

This makes the ordered popup chain skip `sign_in` instead of opening a malformed automatic modal. MID353 remains an intentionally incomplete compatibility stub for later deliberate sign-in work.

MID8193 `GET_PIC_NOTICE_INFO` is also corrected to the exact fields MainScene consumes for a no-popup result:

`{"has_read":1,"contents":[]}`.

## Source-confirmed MID1056 request storm

After the Stage 3.1.6 clock fix, the live server receives MID1056 `GET_BUILDING_LIST` approximately every second. The old backend responds `{"list":[]}`.

Pass19 and `EventCentre.lua` prove the client expects:

- `building_list`
- `cabinet_info`
- `desk_info`
- `pet_cabin_info`

and immediately dereferences building rows 1/4/5/6. `xyd.EventCentreBuildingType` defines IDs 1..7:

1 CABINET, 2 DESK, 3 TRASH, 4 BOOKSHELF, 5 ADMIN, 6 BOARD, 7 PETROOM.

`ServerTime:handleActCentreRedPoint()` calls `EventCentre:getBuildingList()` when `deskInfo` is absent. Because the Stage 3.1.6 response never populates `deskInfo`, the now-working one-second ServerTime tick continually requests MID1056.

Stage 3.1.7 `building_list_payload()` therefore returns all seven building rows with source-consumed fields `lev`, `need_time`, `start_time`, `new_evolve`, plus idle `desk_info`, `pet_cabin_info`, and `cabinet_info`. Field names are source-confirmed; values are compatibility defaults (level 1 / zero timers/items). Compatible persisted custom rows are merged onto these defaults when present.

Expected result: one/few MID1056 loads are acceptable, but the one-request-per-second loop should stop after a valid response hydrates `deskInfo`.

## ADB/logcat classification for this run

The supplied full.log does not show a useful Lua traceback or native crash at the ~17:53:39 disappearance point. It shows normal HTTP completions and repeated bitmap-font warnings for letters `M`/`q`. Use the exact source/UI state transition plus matching MID353 timing as the diagnosis; do not claim an ADB-visible Lua exception.

## Girls button next discriminator

Do not change hero-list logic in Stage 3.1.7. Source says an accepted Girls-button click calls `SelfPlayer:loadHeros()` and should send MID49 `LOAD_HEROS`, then load Backpack if needed and open `hero_list`.

Stage 3.1.6 live request log did not show explicit MID49 after the reported failed click. First remove the broken automatic sign/background state and retest.

After Stage 3.1.7:

- if Girls works: continue per-window Stage 3 completion;
- if Girls fails and MID49 appears: inspect hero response / `HeroListWindow` narrowly;
- if Girls fails and MID49 does not appear: investigate click/window overlap/function gating, not backend hero payload.

## Stage 3.1.7 expected markers

Preserve:

- MID176 `LOAD_FRIENDS`
- MID2754 `CHECK_GAME_STAT`
- top economy HUD
- functional Backpack/Chat
- working MID18 server picker

New expectations:

- MID353 `SIGN` should **not** auto-fire at login/lobby entry.
- poster girl + middle + top-left/player lobby controls should remain visible after entry.
- MID1056 should not repeat every second after a successful corrected response.

## Validation rule

Only run `python -m py_compile`. Stage 3.1.7 validation result: **PASS — 55 Python files compiled**. No Flask/HTTP/APK/ADB/emulator runtime test was run. User performs backend/APK/ADB runtime tests. Payment stays permanently out of scope. TCP chat stays minimal unless it becomes a proven blocker.

---
# Stage 3.1.6 update — bootstrap `server_time` MainScene fix

Current stage: **Stage 3.1.6 bootstrap-server-time**  
Date: 2026-08-16

## User-confirmed Stage 3.1.5 result

- MID18 `LOAD_USER_REGIONS` / server-switch is now working correctly in the APK. The user can open the server picker and sees the generated local placeholder regions plus region 125 `Deep Valley`.
- Normal login still reaches the lobby, but the same MainScene failure remains: bottom menu/buttons and the top economy/player HUD do not complete and touch-driven lobby actions do not work.
- Live request boundary remains MID612 `GET_SELF_GUILD`, with MID56/836/1344 around the same point, followed by repeating MID192 chat discovery. MID176 `LOAD_FRIENDS` and MID2754 `CHECK_GAME_STAT` are still absent.
- Keep the Stage 3.1.5 RegionWindow contract fix. The placeholder `Local-*` regions are compatibility data and are not a priority while the lobby is locked.

## Runtime probe result

The Stage 3.1.5 ADB probe successfully pulled current writable state from `/data/data/com.carolgames.gxb/files/com.carolgames.gxb`.

Current identity is coherent on-device:

- SDK/account UID: `13371337`
- SDK/login SID: `1993b58bfd1b93499ae19477b236d4a2`
- game player: `12525385 / Moppleton`
- region: `125 / Deep Valley`

The writable tree contains `src_32`, `src_64`, `res`, and version manifests, but the targeted pull found no hot-update copies of `MainScene*.lua`, `SelfPlayer.lua`, `ServerTime.lua`, `BattlePass.lua`, or the other files involved in the new diagnosis. It did find hot `LoginWindow.lua` and `eco_sidebar.csb`. Therefore the bundled complete `src_64` remains the best available runtime source for the specific MainScene/ServerTime path below.

The current `game.db` still contains historical region-125 formations with partner IDs not present in our one-hero server state. Preserve this as a later consistency issue, but it is not on the synchronous pre-MID176 path and is not the current root-cause candidate.

## Source-confirmed missing bootstrap clock

`app/common/ServerTime.lua` initializes with:

- `canGetServerTime_ = false`
- `serverTime_ = 0`
- `getServerTime()` returns `nil` until `resetServerTime()` is called.

`app/common/network/Backend.lua:extraWebResponseCheck_()` calls `xyd.ServerTime.get():resetServerTime(response.server_time)` whenever a successful **top-level** response contains `server_time`. This happens before the MID event/callback dispatch.

Stage 3.1.5 MID1 had no top-level `server_time`. Its boot detail does contain `detail[176].server_time`, but `SelfPlayer:loadGameStartInfoEvent_()` has no `LOAD_FRIENDS` boot-detail branch. The embedded 176 payload therefore does not run `SocialSystem:loadFriends()` and cannot initialize the global ServerTime clock.

This creates two source-confirmed nil-clock failures that match both missing MainScene MIDs:

1. **MainSceneBottomWindow**
   - Guild-open path sends MID612 `GET_SELF_GUILD` first, matching live logs.
   - Then `updateBackendRedmark()` loads `BattlePass`.
   - `BattlePass:isOpen()` performs `season_start <= ServerTime:getServerTime() < season_end`.
   - With ServerTime uninitialized, the comparison uses `nil` and can abort synchronously **before** unconditional `socialSystem:loadFriends()` (MID176).

2. **MainSceneTopWindow**
   - `willOpen()` calls `addEcoBar() -> regLeftButtons() -> updatePlayerInfo() -> initActList() -> onEnterAction() -> checkGameStat()`.
   - `initActList()` reaches `updateButtonTable()`, which evaluates `adventureEventEarliestTime - ServerTime:getServerTime()`.
   - With ServerTime uninitialized, subtraction uses `nil` and can abort **before** `onEnterAction()` and `checkGameStat()` (MID2754).

This is the first single source-backed dependency found that explains **both** the exact live MID612→no-176 boundary and the independent no-2754/top-HUD failure.

## Stage 3.1.6 implementation

MID1 `RETRIEVE_TOKEN` now includes top-level:

```json
"server_time": <current unix seconds>
```

The value comes from canonical PlayerState `player.now()`.

This field is intentionally added to authenticated MID1 only, not globally to all responses. Initializing ServerTime on pre-login MID2/center traffic would start its one-second scheduler before player/model hydration and could create unrelated early events. MID1 is the earliest safe authenticated response and `extraWebResponseCheck_()` initializes the clock before its TOKEN/bootstrap event is dispatched.

Existing MID176 `server_time` remains and should refresh the clock again once the bottom window reaches `LOAD_FRIENDS`.

No new MIDs, no payment changes, no fabricated formations, and no client patch are included in this stage. The Stage 3.1.5 RegionWindow and identity fixes are retained.

## Stage 3.1.6 success markers

On the next APK run:

1. MID1 console response must show top-level `server_time` alongside `token` / `region`, not only nested inside detail payloads.
2. After MID612, MID176 `LOAD_FRIENDS` should appear if the bottom window now gets past `updateBackendRedmark()`.
3. MID2754 `CHECK_GAME_STAT` should appear if the top window now gets through `initActList()`.
4. The top mana/crystal/energy + player HUD and bottom buttons should render/finish entry animation and become interactive.

If both 176 and 2754 appear but a specific button/window later fails, handle that window one at a time using its exact request/consumer. If either remains absent, inspect the next synchronous source instruction after the newly crossed boundary rather than resuming broad mapping.

## Validation

Only `python -m py_compile` was run for this handoff. Result: **OK — 55 Python files compiled successfully**. No Flask, HTTP, APK, emulator, or ADB runtime test was run. User performs backend/APK/ADB runtime tests.

---
# Stage 3.1.5 update — RegionWindow contract + runtime hot-Lua probe

Current stage: **Stage 3.1.5 region-contract/runtime-probe**  
Date: 2026-08-16

## User-confirmed Stage 3.1.4 result

- The identity-coherence experiment worked as designed: SDK/login SID `1993b58bfd1b93499ae19477b236d4a2` reached MID1; MID17 returned game player `12525385 / Moppleton`, region `125 / Deep Valley`.
- This did **not** change the locked-lobby boundary. The run still reaches MID612 `GET_SELF_GUILD` and repeating MID192 chat discovery, but no MID176 `LOAD_FRIENDS` and no MID2754 `CHECK_GAME_STAT`.
- Therefore SID/account/game-player identity mismatch is no longer the leading explanation for the missing HUD/bottom controls.

## New server-selection bug is source-confirmed

Clicking the login-screen region-change button sends MID18 `LOAD_USER_REGIONS` twice. Stage 3.1.4 returned `regions:[...]` and `players:{}` and the client window did not render/usefully respond.

Pass 19 only indexed the immediate `LoginWindow` response fields (`regions`, `players`). Downstream `app/windows/RegionWindow.lua` proves a larger exact field contract:

- `userRegions.recall_regions` is read and passed to `next()`, so it must be a table (empty array is safe).
- `userRegions.players` is passed to `table.sort()` and `ipairs()`, so it must be an array, not an object/map.
- each region row is later compared with `region.max_player_id <= region.cur_id`; both fields therefore must be numeric.
- character rows consume `region`, `lev`, `vip`, `name`/`id`, `avatar_id`, `avatar_frame_id`, `conquer_lev`, `conquer_loop_id`.

Stage 3.1.5 `SystemHandlers.load_user_regions()` now serializes that complete RegionWindow-safe shape from canonical PlayerState. Region field names are source-confirmed. Unobserved region capacity numbers remain compatibility defaults, not recovered official values.

## Hot-update runtime tree is now first-class evidence

The user's targeted ADB probe confirmed the writable root exists:

`/data/data/com.carolgames.gxb/files/com.carolgames.gxb`

with `.download_infos`, `.revision`, `lazyFile.json`, `res/`, `src_32/`, `src_64/`, and a ~4.9 MB `version.json`. Current `Cocos2dxPrefsFile.xml` only showed `__version_json_init__=success` and `__version_json_init_web_windows__=success`; it did not show the old official `__version__=1.667.0` value.

Do not call this directory unrelated. Runtime writable Lua can override APK-bundled source.

Strong archive proof: `all-assest-rechecked.zip` contains both bundled and downloaded copies of `src_64/app/windows/LoginWindow.lua`, and they differ. The bundled copy uses non-debug default region index `var_2_0[4]`; the downloaded copy uses `var_2_0[7]`. Thus hot-update Lua materially changes runtime behavior.

## Stage 3.1.4 probe defects found

The previous helper under-collected evidence because:

1. it searched `*main_scene*`, but real Lua filenames are `MainScene*.lua`;
2. `adb shell` inside the checksum `while read` loop inherited stdin and could consume the remaining filenames after the first iteration;
3. `game_meta.txt` / `xinyd_user.txt` depended on Android having a `sqlite3` binary, which the target device apparently does not.

Stage 3.1.5 adds `tools/adb_stage315_probe.sh` which:

- matches/pulls CamelCase runtime Lua and targeted resources;
- redirects ADB command stdin so the whole file list is processed;
- pulls raw `game.db`, `Xinyd.db`, and `log.db` and queries them with host sqlite3;
- captures `game_meta`, story-guide rows, formations, SDK session, and client errorlog;
- pulls current `LoadingScene`, `LoginWindow`, `RegionWindow`, `SelfPlayer`, `Backend`, `AssetDownload`, `StoryData`, `WindowManager`, `MainScene*.lua`, `eco_sidebar.csb`, `skill_full*`, and targeted version manifests when present.

## Next test priority

1. Confirm clicking the server-change button now opens a usable RegionWindow and that selecting region 125 updates the login screen.
2. Normal login/lobby should remain at least as stable as Stage 3.1.4.
3. If lobby remains locked/no 176/no 2754, run `tools/adb_stage315_probe.sh` and compare the pulled hot/runtime Lua against complete bundled `src_64` before changing more backend state.
4. Do not resume broad mapping. Narrow source/runtime-diff checks only around current MainScene failure.

## Validation rule

Only run `python -m py_compile`. User performs backend/APK/ADB runtime tests.

---
# Stage 3.1.4 update — SDK / game identity coherence

Current stage: **Stage 3.1.4 identity-coherence experiment**  
Date: 2026-08-16

## User-confirmed Stage 3.1.3 result

- Client still logs in, enters region 125, and reaches the same incomplete/non-pressable lobby.
- Live engine boundary remains MID612 `GET_SELF_GUILD`, then only repeating MID192 chat-room discovery; no MID176 `LOAD_FRIENDS`, no MID2754 `CHECK_GAME_STAT`, no unknown/fallback MID.
- Stage 3.1.3 advertised `/res/`, but the supplied server trace contains no `/res/*` request. Treat the manifest-based resource probe as a negative result for that run.
- Stage 3.1.2/3.1.3 also received no `/client-log` POST. Do not infer a missing `skill_full` resource without direct evidence.

## New ADB filesystem evidence

The user supplied both a known-good pre-EOL official-client dump and a fresh dump from the current reconstructed-client run.

Both `files/game.db` dumps contain the same `meta` row:

- `sid = 1993b58bfd1b93499ae19477b236d4a2`
- `regionID = 125`
- `regionName = Deep Valley`
- `playerID = 12525385`
- `playerName = Moppleton`

The common client-side DB dumps (game/defaults/chat/friend/state/message DBs) are effectively the old official data. The fresh current tar includes `files/game.db`, so this row is likely a real current-device observation rather than only stale host extraction data. Still use `rm -rf gxb_app_data` before future extracts as hygiene.

The fresh current native SDK DB instead shows local replacement identity:

- SDK user/account UID `13371337`
- session `SID=13371337`, `UID=13371337`, `UNAME=AdminRoot`, `TOKEN=local_token`

ADB logcat independently shows native SDK response/session cookies using `QQWSID=13371337` and `QQWUID=13371337`.

The official AppsFlyer prefs contain an `af_login` event value with `uid=1901244323`; preserve that as a possible historical SDK/account UID lead, but do **not** promote it to the backend default yet because it is indirect analytics evidence rather than an SDK session dump.

## Authoritative Lua identity contract

`LoadingScene:showLoginSdkWindow()` receives Android `xydNewLogin` token and SID callbacks separately. The SID callback is passed to `LoginWindow.sid`. `LoginWindow` dispatches that same SID in its LOGIN event. `LoadingScene:login_()` sends it unchanged in MID1 `RETRIEVE_TOKEN` request field `sid` and later `updateMeta_()` persists it to `xyd.db.meta.sid`.

MID1 root `uid` is separately consumed by `SelfPlayer:loginEvent_()` as `SelfPlayer.uid`. MID1 detail `17` is consumed by `SelfPlayer:onPlayerInfo_()` / `Player.populate()` as the in-game `playerID`/`playerName`.

Therefore SDK/account UID, SDK/login SID, and game player ID are distinct concepts. Stage 3.1.3 incorrectly collapsed all three to `13371337`.

`LoadingScene:updateMeta_()` calls `xyd.db.clearGameData()` when persisted `meta.playerID` differs from hydrated `SelfPlayer.playerID`. `clearGameData()` deletes/reset formations, story guide rows, missions, view state, local guides, chat/friend caches and related per-player state before meta is rewritten. The fresh current dump still contains the old region-125 formation/state rows, so that clear path did not visibly persist during the run. This is a source-vs-live inconsistency and increases the value of matching the known-good identity before pursuing more MIDs.

Do not overstate why the clear did not happen. APK-bundled `src_64` does not initialize SelfPlayer.playerID from meta before MID17, but downloaded/hot-updated Lua may differ and the current ADB script excluded the writable hot-update root.

## Java/payment trace classification

Current logcat has a Java stack ending at `AppActivity.java:658`, but the stack is `XinydPay.initXinydPay -> PayRequestUtils.initWXPay` failing to reflect `com.tencent.mm.opensdk.modelpay.PayReq` after login succeeds. It then continues to the already-known `query_pay_method_amounts` flow. Payment remains out of scope; do not treat this stack as the MainScene blocker.

## Stage 3.1.4 implementation

Default canonical identity now deliberately separates:

- SDK account UID: `13371337` (kept as the already-working local SDK identity for isolation)
- SDK/login SID / QQWSID: `1993b58bfd1b93499ae19477b236d4a2`
- game player ID: `12525385`
- game player name: `Moppleton`
- region: `125`
- region name: `Deep Valley`

Starter hero ownership is updated to game player ID `12525385`. Do not copy official local formation rows into backend hero state: formation partner IDs are not sufficient to reconstruct source table IDs safely.

`PlayerState.set_region()` now preserves a configured region name when the numeric region is unchanged, and knows observed region 125 as `Deep Valley`. `LOAD_USER_REGIONS` also names region125 `Deep Valley`; all unobserved region names remain compatibility placeholders.

MID1 writes backend-only `runtime_logs/identity_trace.jsonl` and prints `[IDENTITY] ...`; no diagnostic protocol field is added.

Stage 3.1.3 `/res/` probe is retained but disabled by default (`GXB_RESOURCE_PROBE=1` re-enables it).

## Hot-update/download directory is now relevant

The user's broad ADB script intentionally excludes `files/com.carolgames.gxb`. Do not call it unrelated anymore. Writable downloaded Lua/resources can affect the runtime source/search-path behavior and direct local loads that do not hit the `/res/` probe.

Official `Cocos2dxPrefsFile.xml` snapshot shows:

- `__version_json_init__ = success`
- `__version_json_init_web_windows__ = success`
- `__version__ = 1.667.0`
- `skill_point = 10`
- `skill_point_time_count = 300`

The current client's Cocos prefs contents were not printed by the user's script (it only prints `.txt` dumps), so current `__version__` remains unknown. A targeted helper `tools/adb_stage314_probe.sh` now captures current Cocos prefs plus targeted hot-update/MainScene paths without pulling the whole asset tree.

## Next APK test priority

1. MID1 request itself should contain `sid=1993b58bfd1b93499ae19477b236d4a2`.
2. `runtime_logs/identity_trace.jsonl` should show request SID matching SDK SID, account UID `13371337`, game player `12525385/Moppleton`, region `125/Deep Valley`.
3. Watch for first appearance of MID176 and MID2754.
4. Fresh ADB dump after the run: inspect `game.db.meta` and `Xinyd.db.user.session`.
5. If lobby still locks with coherent identity and no 176/2754, run `tools/adb_stage314_probe.sh` and inspect the excluded hot-update/download root next. Do not resume broad MID waterfall.

## Final Stage 3.1.4 validation

- Code defaults were aligned with the packaged JSON identity tuple so regeneration does not silently fall back to SID/player `13371337`.
- `JsonPlayerDatabase.serialize()` now labels regenerated files as Stage 3.1.4 and preserves the identity-separation note.
- Final `python3 -m py_compile` succeeded for 55 Python files after these changes.
- No Flask server, HTTP endpoint, APK, emulator, ADB command, or client runtime test was run by the assistant.

## Validation rule

Only run Python syntax compilation before handoff. User performs APK/runtime testing.

---

# Stage 3.1.3 update — resource/preload probe

Current stage: **Stage 3.1.3 MainScene resource preload probe**  
Date: 2026-08-16

## User-confirmed Stage 3.1.2 result

- Login and server selection still work and the client reaches the lobby.
- Top HUD and bottom menus remain absent/non-pressable.
- Live request boundary still reaches MID612 but not MID176 or MID2754.
- Stage 3.1.2 advertised a non-empty `/client-log`, but the user left the client running and **no `/client-log` POST and no client-error runtime file appeared**. Treat that as a negative diagnostic result; do not claim a missing `skill_full` resource is confirmed.

## Corrected MainScene window-order fact

The previous memory entry overstated that a synchronous bottom-window abort necessarily prevents the top window from opening. Source `WindowManager:openWindow()` constructs each requested window and then starts an independent asynchronous `AssetDownload:preloadWindowsByName()` callback. `MainScene:onEnterTransitionFinish()` calls left -> middle -> bottom -> touch -> top quickly; bottom and top can therefore independently fail/wait during preload/loadRes/willOpen.

Source-confirmed boundaries remain useful:
- bottom `willOpen()` dispatches MID612 conditionally, later constructs `skill_full` SpineEffect, updates backend redmarks, optionally handles pets, then unconditionally calls MID176 LOAD_FRIENDS.
- top `willOpen()` runs `addEcoBar -> regLeftButtons -> updatePlayerInfo -> initActList -> onEnterAction -> checkGameStat`; MID2754 is last in that chain.

## Resource-preload hypothesis and probe

`AssetDownload:preloadWindowsByName()` uses the local `version.json`-derived manifest. Missing manifest-listed files are downloaded from `(xyd.resDownloadUrl or "") .. basename .. "." .. md5`. Until Stage 3.1.3 the backend returned `res_download_url=""`, making this path invisible/unusable if a MainScene resource were locally missing.

Stage 3.1.3 defaults `res_download_url` to `<GXB_SELF_URL origin>/res/` and logs first-seen requests plus retry summaries:
- `runtime_logs/resource_requests.jsonl`
- `runtime_logs/resource_probe_summary.json`

The probe returns 404 deliberately; it never fabricates resource bytes. Disable with `GXB_RESOURCE_PROBE=0`. Override with `GXB_RES_DOWNLOAD_URL`.

Important direct resources not guaranteed to pass through this preload probe:
- `windows/common_widgets/eco_sidebar.csb` from MainSceneTopWindow -> EcoSidebar/BaseWidget.
- `skeletons/ui_effect/skill_full/skill.json/.atlas` from MainSceneBottomWindow.
Their absence remains unconfirmed.

## Android rList warning

Latest logcat contains `Resources$UpdateResourceList` EACCES for `/data/user/0/com.carolgames.gxb/files/rList` during SDK/login startup. This stack is Android framework resource bookkeeping, not the Lua `AssetDownload` implementation. Record it as observed noise unless stronger evidence links it to GXB window resources.

## Stage 3.1.3 validation

`python3 -m py_compile` succeeded for 55 Python files. No Flask server, HTTP endpoint, APK, emulator, or client runtime test was run.

## Validation rule

Only run Python syntax compilation. User performs APK/runtime testing.

---

# GXB Backend Runtime Memory

Current stage: **Stage 3.1.2 client error capture**  
Date: 2026-08-16

## User-confirmed Stage 3.1.1 status

- Stage 3.1.1 fixed the malformed MID49 regression and the user again reaches the lobby.
- The locked/incomplete MainScene symptom is unchanged: top economy/header and bottom menus do not complete.
- Live request boundary is still 612 GET_SELF_GUILD followed by no 176 LOAD_FRIENDS and no 2754 CHECK_GAME_STAT.
- No unknown/fallback engine MIDs appear.

## Stronger MainScene ordering diagnosis

- Source `MainScene:onEnterTransitionFinish()` opens windows in order: left -> middle -> bottom -> touch -> top.
- `MainSceneBottomWindow:willOpen()` dispatches GET_SELF_GUILD when guild is open, then performs synchronous local setup, and only later unconditionally calls `socialSystem:loadFriends()` (MID176).
- Therefore reaching 612 but never 176 points to a synchronous client-side abort inside bottom-window setup. Because bottom is opened before top, the same abort also explains why top never reaches MID2754.
- Bottom controls begin touch-disabled. Top's entry action eventually dispatches `MAIN_SCENE_ACTION_END`; if top never opens, the lobby remains globally locked-looking.
- Do not respond by inventing more backend MIDs or currencies. Trace local dependencies between 612 dispatch and MID176.

## Hidden client error-log transport — Stage 3.1.2

- Source `app/xinyoudi.lua` starts `ErrorLogPoster` automatically.
- Engine/Lua errors are stored in `xyd.db.errorLog`; missing assets recorded through `xyd.assetDownloadErrorLog(path)` go to the same database.
- ErrorLogPoster polls every 30s and uses `Backend:log(0, json_logs, ...)`.
- `Backend:log` only runs when RETRIEVE_TOKEN `log_url` is non-empty. Stage 3.1.1 returned an empty URL, which hid these errors from the backend.
- Type-0 client logs are zlib-deflated JSON posted as multipart field `payload`; HTTP 200 causes the client to delete those local rows.
- Stage 3.1.2 advertises `<GXB_SELF_URL origin>/client-log` by default and captures these uploads. Override with `GXB_CLIENT_LOG_URL`.
- Output files: `runtime_logs/client_error_logs.jsonl`, `client_error_uploads.jsonl`, fallback `client_error_raw.jsonl`, and optional `client_crash_uploads/`.
- The first upload may include historical rows accumulated from earlier runs. Preserve and inspect all rows; prioritize errors timestamped around MainScene entry and asset paths such as `skeletons/ui_effect/skill_full/skill.*`.
- The supplied `all-assest-rechecked.zip` / extracted source tree does not contain `skeletons/ui_effect/skill_full/skill.*`; this does **not** prove the installed APK/OBB lacks it, so wait for client error evidence before classifying this as a resource problem.

## Current source candidate between MID612 and MID176

`MainSceneBottomWindow:willOpen()` unconditionally constructs and plays a `SpineEffect` from `skeletons/ui_effect/skill_full/skill.json/.atlas` before calling LOAD_FRIENDS. `SpineEffect` invokes `xyd.assetDownloadErrorLog` on a missing resource. This is a **candidate**, not yet a confirmed root cause. Stage 3.1.2 is specifically designed to capture the hidden client evidence needed to confirm or reject it.

## Validation rule

Only run Python syntax compilation. User performs APK/runtime testing.

## Stage 3.1.2 syntax validation

`python3 -m py_compile` succeeded for 54 Python files. No Flask, endpoint, APK, or client runtime test was performed.

---

Current stage: **Stage 3.1.1 JSON player database hotfix**  
Date: 2026-08-16

## User-confirmed Stage 3.1 regression and root cause

- Stage 3.1 reaches MID1 RETRIEVE_TOKEN and MID2784 ALBUM_SPECIAL_COLLECT_INFO, then stalls before GET_BOARD_INFO/MainScene fanout.
- The live MID1 response proves detail["49"] was malformed: `heros` contained the entire JSON organizational hero section (`heroes`, `collected_heros`, `formation`, etc.) instead of the direct partner-id -> hero-record map.
- Root cause: `JsonPlayerDatabase.load()` checked `PLAYER_FIELD_NAMES` before nested section names. Because the organizational section is also named `heroes`, the whole section was assigned to `PlayerState.heroes`.
- Source `Player:herosEvent_()` iterates every value under `params.heros` and calls `Hero:populate()` on it, so this malformed nesting can abort bootstrap before later detail keys and MainScene.
- Stage 3.1.1 fixes loader precedence and adds a defensive one-level `heroes` unwrap in `heroes_payload()`.
- Keep the player DB architecture. Do not roll it back because of this regression.
- `guide_id=101001` remains the established-profile experiment; it was not actually tested in MainScene by Stage 3.1 because the MID49 shape aborted first.

## Stage 3.1.1 validation rule

Only run Python syntax compilation. User performs APK/runtime testing.

---


Current stage: **Stage 3.1 JSON player database / established-profile correction**  
Date: 2026-08-16

## User-confirmed live status entering Stage 3.1

- Anonymous SDK login, server selection, RETRIEVE_TOKEN, and lobby entry remain functional.
- Stage 3 improved lobby character behavior: changing/tapping the visible character now changes dialogue.
- Top HUD (mana/crystal/energy/header) and most bottom/middle lobby buttons still do not become usable/visible.
- Latest Stage 3 request trace still reaches 192/56/1344/836/612 but **does not reach MID 176 LOAD_FRIENDS or MID 2754 CHECK_GAME_STAT**.
- Latest live MID17 already returned mana=999999, crystal=999999, energy=100, level=99, VIP=15, all source FunctionIDs, and a starter hero. Therefore do not reduce the diagnosis to “currencies are zero/missing.”

## Stage 3.1 architecture committed

The canonical state is now persisted in a small human-editable JSON database rather than only an in-memory object:

```text
data/player_db.json
```

Override path with `GXB_PLAYER_DB_PATH`.

Implementation:
- `gxb_backend/state/player_database.py` — nested JSON serializer/loader.
- `gxb_backend/state/repository.py` — canonical repository, atomic writes, legacy migration.
- repository `refresh()` re-reads JSON before every engine and SDK request.
- handler mutations persist back to JSON.
- malformed hand-edited JSON keeps last known-good in-memory state and logs an error.

JSON sections:
- account
- player.identity
- player.progression
- player.economy
- player.heroes
- player.inventory
- player.library
- player.lobby
- player.domains

Protocol ownership:
- progression/economy -> MID17 LOAD_PLAYER_INFO / RETRIEVE_TOKEN detail 17.
- heroes -> MID49 LOAD_HEROS.
- inventory -> MID81 LOAD_BACKPACK.
- library -> MID836 GET_LIBRARY_INFOS.
- story/guide mutations -> MID26 SAVE_STORY; guide function/return handlers also persist.

The text DB is authoritative for explicit values. In particular, an explicitly empty `func_ids` list remains empty instead of silently restoring defaults.

## Source-confirmed tutorial correction

This is the strongest new behavioral finding.

Stage 3 live MID17 sent `guide_id=0`. Source `MainScene:onEnterGuide()` treats any guide ID below `GUIDE_START=100101` as tutorial state and opens the guided summon-hero path.

Relevant source constants in `app/common/enums.lua`:
- GUIDE_START = 100101
- GUIDE_END = 100197
- GUIDE_PET_ONE = 100501
- GUIDE_PET_THREE = 100503
- GUIDE_CONQUER_SCHOOL_END = 101001

Default established Stage 3.1 profile therefore uses:

```text
guide_id = 101001
```

Reason: 100197 ends the base tutorial but later pet/cloud/chapter/conquer guide families continue. 101001 is the end of the known conquer-school guide family and is safer for the intentionally established local test profile. It is user-editable in JSON.

MID26 SAVE_STORY source contract is `story_id`, `story_state`, `guide_id`; Stage 3.1 persists all three.

## Function gates — remember the distinction

- `SelfPlayer:isFuncOpen(id)` uses the server MID17 `func_ids` map.
- global `xyd.isFunctionOpen(id)` checks `StoryData.stageID_` plus player level against `functionOpen` table.
- `StoryData.stageID_` starts at 0 and supplied Lua only advances it via BATTLE_ENDED; it is not populated by MID17.

Most principal MainScene button gates use `SelfPlayer:isFuncOpen`, so the established profile keeps all source-derived FunctionIDs. If a later subsystem still appears locked, check which helper it uses before changing server fields.

## Economy / hero / inventory facts

- `EcoSidebar.lua` reads `SelfPlayer.mana`, `SelfPlayer.crystal`, and `SelfPlayer.energy` directly. These are MID17 values.
- Hero model is separately hydrated from MID49 but now shares the same JSON record.
- Backpack is separately hydrated from MID81 but now shares the same JSON record.
- Backpack items require source-valid IDs; consumer uses at least `table_id`, `item_num`, `time` and immediately performs local table lookups. Do not invent item IDs.
- Default inventory remains empty intentionally.
- Default source-valid starter hero remains `table_id=10001001` (Aquaris), local `partner_id=10001`.
- MID65 LOAD_COLLECTED_HEROS serializer now emits source-consumer shape `{"list":[table_ids...]}`.

## MainScene diagnostic invariant

Keep the previous invariant:
- `MainSceneBottomWindow.willOpen()` reaches `socialSystem:loadFriends()` late in setup -> MID176.
- `MainSceneTopWindow.willOpen()` runs `addEcoBar -> regLeftButtons -> updatePlayerInfo -> initActList -> onEnterAction -> checkGameStat` -> MID2754.
- Entry controls are re-enabled on `MAIN_SCENE_ACTION_END`.

Next live test should specifically report whether guide_id=101001 causes MID176 and MID2754 to appear. If not, stop adding arbitrary state and trace the exact synchronous Lua line before those two boundaries.

## Validation rule

Only run Python syntax compilation before handoff. Do not run Flask/APK/runtime tests here unless user explicitly asks.

---


Current stage: **Stage 3 domain foundation**  
Date: 2026-08-16

## Stage 3 directive

User explicitly ended isolated Stage 2 lobby-button hotfixing. Do not restart full waterfall/static-analysis passes. Use Pass 19 as the protocol/domain compass and consult `all-assest-rechecked.zip -> src_64` only for implementation-critical response/consumer cross-checks. Build domain-owned backend state incrementally and let APK runtime traces drive later promotions.

User-confirmed baseline remains: anonymous SDK login -> server selection -> RETRIEVE_TOKEN -> lobby. Stage 2.3 additionally allowed the visible lobby character to be changed, but most HUD/buttons remained absent/inert.

## Stage 3 implementation committed

- Default profile: `GXB_PROFILE=established`.
- Default FunctionIDs: all source-derived IDs (`GXB_FUNC_MODE=all`).
- New corrected bootstrap mode: `GXB_BOOTSTRAP_DETAIL_MODE=stage3`.
- Proven minimal rollback remains `GXB_BOOTSTRAP_DETAIL_MODE=safe`.
- Added source-valid starter hero: local `partner_id=10001`, source `table_id=10001001` (Aquaris, first row in `data/tables/partner.lua`, initial star 3).
- Campaign state uses real source campaign `100001`.
- Added canonical/domain handlers for practice 124-133, battle formation 208-213, arena 272-300 family, missions/tasks, social, guild/team, pet/pet-campaign, march/world-boss, market/cart/skin shop, and battle pass.
- Added `runtime_logs/domain_gaps.jsonl` classification for future fallback promotion.

## Corrected bootstrap contracts

Old Stage 2 `wide` mode must remain experimental/deprecated because several payloads were malformed. Stage 3 source cross-check corrected these before broad hydration:

- MID 115 trial: `trial_info.{trials,campaigns}` + `challenge_info.{challenges,campaigns}`.
- MID 336 march: `map_info`, `hero_status`, `enemies`, `rewards`.
- MID 2416 adventure: `adventure_list.list`.
- MID 2984 battle pass: `base_info` + `mission_info`.
- MID 368 mail: `mail_list`, `total`, `new_mail_total`.
- MID 384 invite: `missions`, `invite_players`, `invite_code`, `invitor_id`, `invitor_name`.
- MID 624 world boss: numeric hurt/rank/times and nested `boss_info`; source-valid boss id 10011.
- MID 112 world map: complete chapter-info scalar fields and source campaign 100001.

Stage 3 bootstrap currently hydrates the safe baseline plus selected corrected domain entries: 112, 115, 289, 336, 352, 368, 384, 612, 624, 2416, 2485, 2984. If boot regresses, switch only the bootstrap mode back to `safe`; keep Stage 3 direct handlers.

## MainScene diagnostic invariant

Do not forget this when interpreting “buttons locked.” Source confirms MainScene bottom/middle controls are explicitly touch-disabled in their entry animation and only re-enabled on `xyd.event.MAIN_SCENE_ACTION_END`. MainScene top `willOpen()` runs:

`addEcoBar -> regLeftButtons -> updatePlayerInfo -> initActList -> onEnterAction -> checkGameStat`

`checkGameStat()` sends MID 2754. User Stage 2.3 logs never reached MID 2754. Therefore a top-window construction abort before `checkGameStat()` can globally leave the rest of the lobby touch-disabled even when their backend handlers exist. Do not fake `MAIN_SCENE_ACTION_END` server-side; keep correcting coherent model initialization and use client logs to identify the first failing local dependency.

## Transport invariants

- HTTP chat-room discovery is MID 192 and returns host/port/room_id.
- 327xx / selected 3685x chat messages are TCP/chat-routed by Backend bitmask; do not expose them as ordinary Flask engine handlers.
- zlib/form result MIDs remain handled by transport classification.
- Payment initialization is intentionally ignored and will not be implemented unless user changes scope.

## Validation rule

Only run Python syntax compilation before handoff. Do not run Flask/APK/runtime tests in this environment unless user explicitly asks.

## Next Stage 3 APK feedback priority

1. Confirm `stage3` bootstrap still reaches lobby; if not, retest with `GXB_BOOTSTRAP_DETAIL_MODE=safe` and compare.
2. Look specifically for MID 2754. Its appearance is a useful marker that MainSceneTopWindow finished initial construction.
3. Exercise Girls/Hero, Backpack, Campaign, Vending/Shop, Missions, Arena, Social, Guild, Pet.
4. Send `all_requests.jsonl`, `unknown_mids.jsonl`, `fallback_responses.jsonl`, `domain_gaps.jsonl`, and logcat around any failed window.
5. Promote failures by domain, not by isolated UI call site.

---


Current stage: **Stage 2 modular lobby backend**  
Date: 2026-08-16

## Confirmed Stage 1 status

User confirmed Stage 1 boots the APK successfully:

`login popup -> anonymous login -> click to start -> lobby`

The server log showed successful handling of center/version, SDK cookies, `RETRIEVE_TOKEN`, `ALBUM_SPECIAL_COLLECT_INFO`, `GET_BOARD_INFO`, `LOAD_CHAT_ROOM_INFO`, `ILLUSION_LOAD_INFO`, `GET_LIBRARY_INFOS`, and `LOAD_SUMMON_INFO`.

Payment initialization warnings are intentionally ignored. No real purchase system will be implemented.

## Stage 2 implementation goal

Do not return to waterfall static analysis. Stage 2 extends the backend so common lobby windows/panels can open without hard crashes and unknown MIDs are captured cleanly for future promotion.

## Stage 2 additions

- Root `memory.md` added as quick operational context.
- Detailed docs remain in `docs/`.
- Runtime JSONL logging added under `runtime_logs/`:
  - `all_requests.jsonl`
  - `unknown_mids.jsonl`
  - `fallback_responses.jsonl`
- Canonical `PlayerState` expanded with mail, tasks, shops, world/campaign, guild, inventory/runes, hero extras, battle-pass, study/gift/adventure, and auction skeleton state.
- `RETRIEVE_TOKEN.detail` expanded with additional source-recognized safe hydration entries.
- New domain handlers:
  - `mail.py`
  - `shop.py`
  - `world.py`
  - `guild.py`
  - `rewards.py`
- Existing handlers expanded for heroes, inventory, social, arena, tasks, and system/profile actions.

## Design rules

1. All endpoint responses should serialize from `PlayerState` where possible.
2. Unknown MIDs remain successful but are logged in JSONL.
3. Payment is ignored unless it blocks boot/lobby.
4. TCP chat remains a keepalive/acceptor stub; real chat protocol is not implemented.
5. No runtime APK testing is performed here; user runs the client.
6. Only simple Python syntax checks are required before handoff.

## Next likely work after Stage 2 client test

- Review `runtime_logs/unknown_mids.jsonl` from the user's run.
- Promote the most common unknown lobby MIDs into domain handlers.
- If a UI panel crashes, identify its MID and exact request payload from `all_requests.jsonl`.
- Start Stage 3 around whichever subsystem user opens first: heroes/backpack, mail, shop, world, arena, guild, etc.

## Stage 2.2 hotfix — bootstrap detail reverted to safe set

Live Stage 2 client run regressed: login and RETRIEVE_TOKEN succeeded, then the client requested ALBUM_SPECIAL_COLLECT_INFO (2784) and stopped on the loading window. Backend runtime logs showed no unknown MID or fallback, which means the blocker happened inside client-side bootstrap/event processing before the usual MainScene fanout.

The likely cause is Stage 2's widened RETRIEVE_TOKEN.detail bag. Optional detail entries are not harmless unless their event listener contracts are verified. A malformed early detail key can abort the Lua listener chain before GET_BOARD_INFO / chat / MainScene fanout.

Default boot detail mode is now `safe` and returns the Stage 1 proven hydration set only:

- 17 LOAD_PLAYER_INFO
- 49 LOAD_HEROS
- 81 LOAD_BACKPACK
- 836 GET_LIBRARY_INFOS
- 56 LOAD_SUMMON_INFO
- 176 LOAD_FRIENDS
- 229 ACTIVITIES
- 2560 RED_POINT

Stage 2 domain handlers remain wired for direct/later UI calls, but they are no longer injected into RETRIEVE_TOKEN.detail by default.

Experimental wide bootstrap remains available only with:

```bash
GXB_BOOTSTRAP_DETAIL_MODE=wide python3 server.py
```

Do not use wide mode as the default until every added detail key has been verified by a client run.


## Stage 2.2 lobby UI completion

User confirmed Stage 2.1 reaches lobby again, but top HUD/resources/buttons are absent or inert. Runtime request logs show successful boot fanout through 1537/192/56/836/1344 and no unknown/fallback MIDs, while CHECK_GAME_STAT is absent, indicating the MainScene top-window path likely does not complete.

Stage 2.2 keeps safe bootstrap detail, changes the default avatar from 0 to source avatar 110001001, advertises all known source FunctionID values in player_info.func_ids by default, and adds achievement handlers for LOAD_ACHIEVEMENT_INFO/GET_ACHIEVEMENT_AWARD.

## Stage 2.3 MainScene HUD completion attempt

User confirmed Stage 2.2 still reaches lobby but has no visible top HUD/resource/header bar and no usable lobby buttons. Runtime logs show no unknown/fallback MIDs. The important request pattern is:

- middle-window APIs fire: `LOAD_SUMMON_INFO`, `ILLUSION_LOAD_INFO`;
- bottom-window guild branch fires: `GET_SELF_GUILD`;
- bottom-window social branch does **not** fire: no `LOAD_FRIENDS`;
- top-window status check does **not** fire: no `CHECK_GAME_STAT`.

Source review narrowed the likely abort to `MainSceneBottomWindow.willOpen()` before `socialSystem:loadFriends()`, preventing later `main_scene_top` HUD construction.

Stage 2.3 changes:

- Default `GXB_FUNC_MODE=core` now exposes only stable core lobby/HUD FunctionIDs instead of every source FunctionID.
- `GXB_FUNC_MODE=all` restores Stage 2.2's full FunctionID list for experiments.
- Safe `RETRIEVE_TOKEN.detail` now includes `780 PETS_GET` as `{"pets": {}}` to initialize `SelfPlayer.collectedPets` and avoid pet/global-timer nil hazards.
- Previous persisted `state/gxb_state.json` no longer pins all FunctionIDs; repository reapplies the selected function mode on load.

Next client test should delete old `state/` and `runtime_logs/`, run default `python3 server.py`, and verify whether `LOAD_FRIENDS` then `CHECK_GAME_STAT` appear.
