# Player login / boot protocol map

Source-derived from `src_64` on 2026-08-16. Separate native SDK observations are labelled as such.

## Phase A — UpdateScene

1. `boot_64.lua` requires `UpdateScene_64.lua`.
2. `UpdateScene_64:requestServerUrl_()` POSTs a URL-encoded JSON `payload` to the center URL with: `mid=20480`, `area="tw"`, `type=packageInfos.mode`, `app_v=xyd.getVersionName()`, `platform=targetPlatform`.
3. On success it stores `url -> xyd.serverUrl`, `server_id -> xyd.serverID`, `back_domain -> xyd.back_domain`, and `res_download_url -> xyd.resDownloadUrl`.
4. `checkVersion_()` then POSTs MID `2` with: `platform`, `app_v`, `v` (local resource version), `clean`, and `full`.
5. After update handling, `startGame_()` loads `app.Game`.

## Phase B — LoadingScene / native SDK login

1. `app.Game:run()` replaces the scene with `xyd.LoadingScene.new()`.
2. `LoadingScene:showLoginSdkWindow()` calls native Android `AppActivity.xydNewLogin(callbacks...)` (or iOS SDK equivalent).
3. The native SDK returns a SID/token through callbacks and opens the LoginWindow. The Lua login event supplies `sid`, `region.region_id`, and `is_test`; LoadingScene supplies its stored SDK token.
4. Lua constructs the MID `1` request:
   - `sid` = login-window supplied SID
   - `login_token` = LoadingScene token from SDK callback
   - `region` = selected `region.region_id`
   - `is_test` = login-window flag
   - `v_` = `xyd.version()`
   - `app_v` = `xyd.getVersionName()`
   - `platform` = target platform
5. There is **no `player_id` in this request**. The server therefore cannot be expected to receive a pre-existing player ID from this Lua login call.

## Phase C — RETRIEVE_TOKEN response and player identity

`SelfPlayer:loginEvent_()` first sets `SelfPlayer.uid = response.uid`, then consumes `response.detail`. The actual per-region player identity comes from the nested MID `17` payload: `SelfPlayer:onPlayerInfo_()` calls `Player.populate()`, which sets `playerID = tonumber(params.player_id)` and also `playerName` and `lev`.

Therefore the source distinguishes:
- `uid`: account/session identity returned at RETRIEVE_TOKEN root level.
- `player_id`: game-player identity returned by LOAD_PLAYER_INFO (`detail["17"]`).
- `sid`: SDK/server-login identifier supplied to RETRIEVE_TOKEN.
- `login_token`: SDK token supplied to RETRIEVE_TOKEN.

The backend needs a deterministic mapping from `(sid/login_token/region)` to the player state it returns in `detail["17"]`. The source does not show the backend database schema, so persistence requirements beyond the fields consumed by the client cannot be inferred from this asset alone.

## Phase D — synchronous bootstrap state

`SelfPlayer:loadGameStartInfoEvent_()` handles these detail entries in order:
- MID `17` `LOAD_PLAYER_INFO`
- MID `780` `PETS_GET`
- MID `49` `LOAD_HEROS`
- MID `81` `LOAD_BACKPACK`
- MID `112` `LOAD_WORLD_MAP`
- MID `115` `LOAD_TRIAL_INFOS`
- MID `2561` `AWAKE_MISSION_LIST`
- MID `229` `ACTIVITIES`
- MID `289` `LOAD_ARENA_FIGHT_RECORDS`
- MID `336` `LOAD_MARCH`
- MID `352` `LOAD_SIGN_INFO`
- MID `384` `LOAD_INVITE_INFOS`
- MID `2485` `PEAK_RECORDS`
- MID `1408` `REGION_GET_ARENA_INFO`
- MID `368` `LOAD_MAIL_LIST`
- MID `56` `LOAD_SUMMON_INFO`
- MID `624` `WORLD_BOSS`
- MID `612` `GET_SELF_GUILD`
- MID `822` `PET_CAMPAIGN_RED_POINT`
- MID `530` `TREASURE_LOAD_INFO`
- MID `1056` `GET_BUILDING_LIST`
- MID `1152` `GUILD_WAR_RED_POINT`
- MID `1808` `GET_TEA_TALK_INFO`
- MID `1304` `GET_OFFLINE_INFO`
- MID `1856` `GET_CLASS_INFO`
- MID `836` `GET_LIBRARY_INFOS`
- MID `2137` `GET_STUDY_INFOS`
- MID `2139` `GET_GIFT_BOX_INFO`
- MID `2416` `GET_ADVENTURE_LIST`
- MID `2501` `GET_HERO_RECOMMEND_SCORES`
- MID `2560` `RED_POINT`
- MID `2984` `BATTLE_PASS_GET_INFO`
- MID `3101` `HUNQI_START_GAME_GET_INFO`

The first especially important entries are `17`, `49`, `81`, and `836`, because they populate player, heroes, backpack, and library state used during immediate startup. Other entries are optional at this point because their handlers are guarded, but some may be worth adding once the first-scene path is stable.

## Phase E — post-token transition

After MID 1 succeeds, `LoadingScene.login_()` immediately calls native `xydSelectServer(region_id)`, sets player/story flags from the response, calls `updateMeta_()`, restores local StoryData, loads `MESSAGE_MANAGER`, stops music, and then calls `MainScene.new()` (or the new-player story branch).

`MessageManager` itself requests MID `192` to obtain `{host, port, room_id}` before creating its TCP chat socket. This is a separate chat transport and should not be confused with the HTTP MID surface.

## What the backend should store

Source-supported minimum persistent model for a functional logged-in client:
- account `uid`
- SDK/session `sid` and token
- selected region/server ID
- game `player_id`
- player name, level, currencies/energy and other fields consumed by `SelfPlayer:onPlayerInfo_()`
- hero collection (at least an empty collection with correct container shape)
- backpack/inventory (at least an empty collection with correct container shape)
- library background/config state

Exact database/storage semantics are not established by the Lua source; keep the backend state model simple until additional gameplay consumers are promoted.