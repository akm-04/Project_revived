# v0.8.0 CURRENT STATE — MULTI-USER IDENTITY FOUNDATION — 2026-08-17

Read this section first. Pass 22 mapping was considered sufficient; no Pass 23 was needed before the first implementation slice.

## Scope of this release

v0.8.0 rewrites the identity/storage spine only. It deliberately does **not** implement PvP/ranking behavior yet.

Implemented:
- persistent SDK credential accounts for MID65282 registration;
- source-shaped MID65282 success fields `uid` + `login_email`;
- MID65281 credential verification and unique SID/TOKEN issuance;
- consistent QQWSID/QQWTOKEN/QQWUID/QQWUNAME cookies;
- fixed anonymous MID65284 sandbox preserved;
- account-scoped MID18 region/player directory;
- atomic `(account_uid, region) -> player_id` resolve/create in MID1;
- `is_new=1` on first credential character creation;
- conservative level-1/empty-name fresh credential template;
- request-scoped canonical gameplay repositories;
- per-player JSON persistence under `data/server_state/players/<player_id>/player.json`;
- automatic one-time import of the v0.7 `data/player_db.json` into the anonymous sandbox;
- invalid/unknown MID1 sessions are rejected instead of silently falling back to the sandbox.

## Storage

Canonical v0.8 storage:
- `data/server_state/accounts/<uid>.json`
- `data/server_state/sessions/<sid>.json`
- `data/server_state/players/<player_id>/player.json`
- `data/server_state/indexes/account_by_login.json`
- `data/server_state/indexes/player_by_account_region.json`
- `data/server_state/indexes/session_by_token.json`
- `data/server_state/indexes/region_player_serial.json`
- `data/server_state/indexes/counters.json`

`data/player_db.json` is now migration input for the anonymous sandbox only. After the first v0.8 start, `data/server_state` is authoritative.

Passwords are not stored plaintext. v0.8 uses a local PBKDF2-SHA256 verifier. This verifier format/iteration policy is implementation policy, not a recovered original Xinyd credential schema.

## Identity semantics

Durable graph:
`SDK uid -> SID/TOKEN session -> (uid,region) mapping -> stable game player_id -> canonical game state`.

Never key progress by device_id/client_id/SID/TOKEN.

Credential player IDs are allocated with the region encoded in high digits, e.g. first region-197 player `19700001`, matching the client-wide player-id region convention. Creation is retry-safe.

The anonymous sandbox retains UID `13371337`, SID `1993b58bfd1b93499ae19477b236d4a2`, TOKEN `local_token`, and imports the existing established Moppleton state/max-resource profile.

## Fresh credential-player policy

Source-confirmed:
- new character lifecycle is level-1/new-player oriented;
- empty/unset name is valid;
- MID1 `is_new=1` enters opening story;
- StoryScene eventually opens EditNameScene;
- MID23 sets the real name.

Still unknown:
- exact official fresh mana/crystal/other starting numeric amounts;
- exact session expiry policy;
- official duplicate/wrong-password SDK error numbers.

v0.8 therefore uses conservative zero values for unproven fresh currencies and a local generic nonzero SDK error code. Do not present those as official values.

## Offline validation completed

Pure-Python state tests PASS:
- two registrations allocate different SDK UIDs;
- two logins allocate different SID/TOKEN pairs;
- account A and B each create a different region-197 player;
- A mutation does not appear in B;
- repeated MID1 for A resolves the same player;
- MID18 for A lists only A; MID18 for B lists only B;
- anonymous sandbox still resolves existing Moppleton with 999999 mana/crystal;
- MID18 -> MID1 lifecycle produces fresh `lev=1`, `player_name=''`, first `is_new=1`, later `is_new=0`;
- invalid MID1 session is rejected.

Python syntax validation: 83 files PASS via `python3 -m py_compile`. No Flask/HTTP/APK/ADB/emulator/gameplay runtime test was performed by the assistant.

## First user runtime test

Before first v0.8 launch:
1. copy latest v0.7 `data/player_db.json`;
2. preserve/copy `local_assets/res` and any intentional Lua update files;
3. start server once and confirm `[MULTIUSER] importing singleton sandbox ...`;
4. register `testuser01/pass1234`; expected MID65282 -> automatic MID65281;
5. fresh account should reach MID18 with `owned_players=0`, then MID1 region197 and create a new `197xxxxx` player with `is_new=1`;
6. register a second account and verify different UID/session/player;
7. verify anonymous still loads the old established sandbox.

Useful inspection tool: `python3 tools/list_multiuser_state.py`. Offline isolation tool: `python3 tools/selftest_multiuser.py`.

## Not yet implemented

- MID65285 anonymous-to-credential binding: intentionally deferred because the current anonymous identity is a shared fixed sandbox and must not be converted into one user's credential account.
- exact fresh tutorial grants/function unlock progression; runtime test may expose the next new-account tutorial contracts.
- public cross-player MID17/MID49/MID208 projections.
- player-name uniqueness/index semantics.
- social/guild shared entities.
- rankings and PvP mode state.
- immutable PvP report snapshots.

Next coding slice after runtime validation should migrate any tutorial/new-account gaps revealed by the first credential character, then build public cross-player projection + canonical formation before competitive systems. Competitive remains last.

---

# PASS 22 CURRENT STATE — 2026-08-17

Read this section first. It is the final Lua + Android/Smali server architecture synthesis before multi-user backend coding.

Pass 22 is mapping/research only. No backend code was changed.

## New live registration confirmation

User tested source-valid credentials:
- account `testuser01`
- password `pass1234`.

Runtime confirmed:
- MID65282 `register_platform` reached the SDK backend three times.
- Present backend did not complete the register success contract; UI asked to retry.
- Manual MID65281 credential login then occurred.
- Present backend still issued the singleton development UID/session:
  - UID 13371337
  - development SID
  - token `local_token`
- engine MID1 then resolved the same canonical development player:
  - player_id 12525385
  - Moppleton.

Therefore the current backend has SDK-shaped auth routes but **no account/session/player isolation**.

## Final identity model

Keep five layers distinct:

1. SDK Account — UID + credential/anonymous identity.
2. SDK Session — SID/TOKEN/QQW cookies -> exactly one UID.
3. AccountRegionIndex — `(uid, region_id) -> player_id`.
4. Canonical game Player — stable `player_id`, owning/profile-projecting all game progress.
5. Cross-player domains — social/PvP/ranking/report projections over stable player IDs.

Never key progress by device_id/client_id or session ID.

SDK UID is not game player_id.

## Register/login contracts

Pass 21 remains authoritative for Smali details:
- MID65282 Register request: login_email/password/repassword/game_source.
- source-valid local account syntax is alphanumeric 6–50; password alphanumeric 6–15.
- MID65282 success requires `error_code=0`, `uid`, `login_email`; SDK then deliberately performs MID65281.
- MID65281 success requires `error_code=0`, `uid` and session cookies QQWSID/QQWTOKEN/QQWUID/QQWUNAME.
- GXB AppActivity swallows login fail/exception callbacks, which explains visually dead malformed login results.
- SDK MID65288 create-player capability exists but GXB `xydCreatePlayer` bridge is no-op.

## Game player lifecycle

Lua source:
- successful SDK auth gives Lua TOKEN then SID;
- LoginWindow sends MID18 LOAD_USER_REGIONS;
- MID18 owns account-scoped character directory (`regions`, `players`, `recall_regions`);
- if no player exists, LoginWindow immediately sends login for selected region;
- LoadingScene sends MID1 RETRIEVE_TOKEN;
- there is no active Lua CREATE_PLAYER in between.

Strongest backend model:
- MID1 atomically resolves or creates `(account_uid, region_id) -> player_id`.
- fresh create returns `is_new=1`.
- empty/unset player_name is source-supported.
- opening StoryScene ends in EditNameScene.
- MID23 sets player name; MID26 saves story progress.
- `Guestxxx` remains unconfirmed recollection and must not be invented.

One player per account per region is a strong source/UI-supported architecture inference, not a recovered official database constraint.

## Canonical player ownership

SelfPlayer root response consumes 93 mapped player fields plus story fields. The global `economy_` plane consumes 47 fields.

Do not store these as one giant authoritative response blob. Logical owners:

- profile/public identity;
- economy and timers;
- tutorial/function gates;
- Heroes;
- Inventory;
- Pets;
- Formations/presets;
- Campaign/world;
- Social;
- Guild membership reference;
- Mail;
- Dorm/Institute/Activities/other domains;
- per-mode PvP state.

MID1/MID17 should assemble source-shaped projections from repositories.

Regenerating resources include at least energy, spirit energy, skill points, arena invitations; server/client timer parity matters.

Current maxed mana/crystal is an anonymous development-sandbox profile, not a source-valid fresh credential-player template.

## PvP / ranking final architecture

All mapped competitive/social systems pivot on stable game `player_id`.

Generic cross-player `Player.lua` supports:
- MID17 LOAD_PLAYER_INFO;
- MID49 other-player Hero load;
- MID208 LOAD_BATTLE_FORMATION `{type,num,player_id}`, defense consumes `response.params.list`;
- MID209 own formation save.

### Classic Arena
Per-player arena state includes:
rank, best_rank, defense, left_time, buy_num, last_match_time, update_count,
enemies, pet_id, server_time, ban_hero_id, is_ban_open, set_formation_time, fight_times.

PvP result MID279 is zlib/form. Arena should own mode state/rating/tickets/defense/reports, not a cloned player DB.

### Peak Arena
Per-player rank/base state + multi-team serialized defense. Numeric `PEAK_FIGHT_RESULT` remains undefined in supplied source; never invent it.

### Region Arena
Per-player point/star/rank/defense/fight/missions/award/exchange state, with region/global matchup/rank indexes.

### Region Casual and Friend Fight
These prove historical replay records need immutable snapshots:
A/B player IDs, A/B player info, A/B Hero/pet/team snapshots, battle count/report content.

Current opponent views can project current canonical state; historical fight reports must NOT re-read mutable current Hero/profile state.

### RankList
`rank.lua` defines ranking catalog/type/subtype/realtime/show behavior, including:
1v1 global/server, Peak, Arena, practice, AP/team force/Hero star, collection and other ranks.

Rank indexes should reference player_id/guild_id + score/rank/minimal projection, not clone full player state.

## Recommended storage topology (architecture inference)

Suggested JSON-era layout:

- `accounts/<uid>.json`
- `sessions/<sid>.json`
- indexes:
  - account_by_login
  - player_by_account_region
  - player_name
  - region player indexes
- `players/<player_id>/`:
  profile/economy/tutorial/heroes/inventory/pets/formations/campaign/social/mail/domain files
- `guilds/<guild_id>.json`
- `pvp/<mode>/<player_id>.json`
- `pvp/reports/<report_key>.json`
- `rankings/<subtype>.json`

Physical layout is not claimed as original Carol Games schema. Repository ownership and stable IDs are the important part.

## Authorization rule

Self-state:
`SID/TOKEN -> UID -> selected region -> self player_id`.

Normal mutations must use self context, not caller-supplied player_id.

Only source-defined cross-player endpoints may target other player IDs and must return public/battle projections, never private economy/tutorial/account data.

## Two-user implementation exit criterion

User A and User B can register/login on same device or different devices and get:
- different SDK UIDs;
- different sessions;
- independent `(uid,region)->player_id`;
- independent Heroes/Campaign/Inventory/economy/tutorial;
- no cross-account state leakage.

Then A/B can later discover/project each other by stable player_id for social/rank/PvP.

## Implementation order after Pass 22

1. AccountRepository: MID65282/65281/65284, unique UID + credential verifier.
2. SessionRepository: unique SID/TOKEN/QQW cookies.
3. AccountRegionIndex + globally unique player allocator.
4. MID18 account-scoped region/player directory.
5. MID1 atomic resolve-or-create.
6. source-derived fresh-player template (separate from maxed anonymous sandbox).
7. migrate working Hero/Inventory/Formation/Campaign/etc to selected player_id repositories.
8. public cross-player projection.
9. social/guild/ranking primitives.
10. immutable PvP report snapshot primitive.
11. continue noncompetitive roadmap.
12. Competitive/Arena/Top last.

Known unknowns that do NOT change architecture:
- exact official duplicate-account/wrong-password error codes;
- exact fresh-account starting numeric values;
- session expiration policy;
- PvP scoring formulas;
- undefined Peak fight-result numeric MID.

Key Pass 22 docs:
- PASS22_INDEX.md
- PASS22_FINAL_MAPPING_STATUS.md
- LIVE_REGISTRATION_DELTA_PASS22.md
- MULTIUSER_IDENTITY_AND_PLAYER_LIFECYCLE_PASS22.md
- CANONICAL_PLAYER_DATA_MODEL_PASS22.md
- SERVER_STORAGE_TOPOLOGY_PASS22.md
- SERVER_OWNERSHIP_MATRIX_PASS22.md
- REQUEST_AUTHORIZATION_AND_ISOLATION_PASS22.md
- PVP_AND_RANKING_STATE_PASS22.md
- CROSS_PLAYER_PROJECTION_AND_SNAPSHOTS_PASS22.md
- IMPLEMENTATION_READINESS_AND_ORDER_PASS22.md
- PASS22_SOURCE_FACTS.json

---

# Pass 21 — Android/Smali SDK identity/account boundary

Date: 2026-08-17

Pass 21 is mapping/research only. No backend code was changed.

## Source
- `smali-packed.zip`
- decoded workshop APK: `smali/` + `smali_classes2/`
- 9,200 Smali files total (8,715 + 485)
- primary SDK: `com/xyd/platform/android`
- game Java/Lua bridge: `org/cocos2dx/lua/AppActivity`

Important provenance: this decoded tree contains known workshop edits to `Constant.smali` and `XinydUtils.getGoogleDNS()`. Current patched platform/DNS endpoint values are not original-host evidence.

## Registration/login discoveries
- Register account IDs are locally validated by `LoginManager.registerAccount()`:
  - regex `^[A-Za-z0-9]*$`
  - length 6–50.
- Register passwords:
  - `[A-Za-z0-9]{6,15}`
  - length 6–15.
- Therefore email-looking IDs containing `@`/`.` are rejected locally with “Account contains invalid character, please re-enter” and no HTTP request.
- A source-valid registration probe is e.g. `testuser01` / `pass1234`.
- Credential login accepts wider ID syntax: `[A-Za-z0-9]+[A-Za-z0-9-._@]*[A-Za-z0-9]`.

Active Xinyd MID map index 1:
- 65281 platform_user_login
- 65282 register_platform
- 65283 tp_user_login
- 65284 anony_login
- 65285 anony_update
- 65286 tp_anony_update
- 65288 get_create_player
- 65289 update_played_server
- 65305 get_game_package_info
- 65319 is_allowed_upload
- 65323 auto_login
plus other support/social/payment symbols in `SDK_MID_MAP_PASS21.md`.

Credential MID65281 success:
- requires JSON `error_code=0`;
- requires JSON `uid`;
- session is carried by cookies QQWSID / QQWTOKEN / QQWUID / QQWUNAME;
- if `uid` is omitted from a nominal success, `LoginManager$5` throws and GXB AppActivity's `onException()` is empty, explaining a visually dead Login button;
- if SID is absent after otherwise valid auth, `getLoginSession()` can retry login.

Register MID65282 request:
- login_email
- password
- repassword
- game_source
Success requires:
- uid
- login_email
Then SDK intentionally sends MID65281 with login_email/password to acquire session cookies.

Anonymous→normal account upgrade:
- MID65285 anony_update with login_email/password/repassword/current uid;
- success requires uid/login_email;
- then credential-login session acquisition.

## Transport
Xinyd `makeRequest`:
- POST JSON
- normal endpoint suffix `server/mobile_api_new/`
- customer endpoint suffix `server/customer_api/`
- connect timeout 10s
- read timeout 100s
- Keep-Alive
- envelope `{mid, payload}`
- signature: common params + client_secret, sort keys, URL encode, URLDecoder.decode, MD5, remove client_secret, emit digest as `sign`.

Session cache:
- `Xinyd.db`, schema version 17.
- `user` table stores SDK user_id, serialized session, unique_flag, current_user_type, visibility, last_login.
- passwords are not user-table columns.
- UserSession JSON keys: SID, UID, UNAME, TOKEN.
- user types 0 anonymous, 1 Facebook, 2 Google, 3 normal, 4 Weibo, 5 Weixin, 6 Line, 7 Twitter, 8 VK, 9 Amazon, 10 Mobile.

## Java/Lua bridge
`AppActivity` successful SDK login sends Lua:
1. TOKEN
2. SID

`AppActivity.xydSelectServer(serverId)` calls SDK update_played_server with blank player_id.

SDK `XinydUtils.create_player()` exists and can send MID65288 with server_internal_id/uid/player_id/player_name, BUT:
- `AppActivity.xydCreatePlayer(...)` is a literal no-op;
- no Smali call site invokes `XinydUtils.create_player()`.
Therefore current GXB runtime does not use SDK MID65288 as authoritative character creation. Pass 20 MID18→MID1 lifecycle remains the implementation model.

## Additional SDK string-MID surface
Besides the active numeric `XinydMid` map, auxiliary SDK methods call direct string request names through the String overload of `makeRequest`. Identity/recovery examples include `login`, `anony`, `reg`, `tp_login`, `mobile_login`, `mobile_bind`, and email bind/reset flows. See `SDK_STRING_API_SURFACE_PASS21.md`. These are contained SDK paths; reachability varies.

## Architecture consequence
Keep separate:
1. SDK accounts/credentials;
2. SDK sessions/cookies;
3. account↔region player index;
4. canonical game player state keyed by game `player_id`;
5. Hero/Inventory/Formation/Campaign/etc repositories;
6. future PvP/ranking/report snapshots over canonical `player_id`.

Anonymous sandbox should remain distinct and may retain reconstruction-friendly max economy. Fresh credential players need a separate source/live-derived starting template.

Key Pass 21 docs:
- PASS21_INDEX.md
- PASS21_ANDROID_SMALI_MAPPING_STATUS.md
- SDK_AUTH_ACCOUNT_PROTOCOL_PASS21.md
- SDK_MID_MAP_PASS21.md
- SDK_HTTP_TRANSPORT_AND_SESSION_PASS21.md
- SDK_LOCAL_ACCOUNT_DB_PASS21.md
- APP_JAVA_LUA_BRIDGE_PASS21.md
- SDK_STARTUP_PACKAGE_INFO_PASS21.md
- ANDROID_NETWORK_BOUNDARIES_PASS21.md
- PASS21_IMPLEMENTATION_IMPLICATIONS.md
- PASS21_SOURCE_FACTS.json
- SDK_REQUEST_SITE_INVENTORY_PASS21.json

---

# PASS 20 CURRENT STATE — 2026-08-17

Read this section first. It supersedes earlier “current state” assumptions while preserving the older memory below for history.

## Pass purpose

Pass 20 is mapping/research only. No backend code was changed. It folds the runtime reconstruction through v0.7.0 back into the original Pass 19 client map and expands the identity/account/player-state/update planes needed for a later robust multi-player/PvP backend.

## Stable runtime milestone entering Pass 20

User/device confirmed working in the current reconstruction:

- anonymous SDK/login path into the game;
- Girls and coherent owned Hero detail;
- Skin and Affinity;
- skill upgrades, including server/client timed skill-point recovery parity;
- Campaign Chapter 1 and Chapter 2 progression;
- live lazy asset download with visible progress;
- special story partner claim (Joan/Geisha path) and subsequent MID114 progression;
- Backpack persistence;
- Sweep → EXP juice → Hero level progression;
- tutorial function-guide persistence;
- per-file `/res/<basename>.<md5>` resource serving;
- MID2 numeric resource ZIP update through install/restart (`1.631.1` marker deployment).

Asset restoration also made previously inert Institute-family UI surfaces open/load. Their server-side mechanics are not assumed complete.

## Resource/update architecture now confirmed

1. CENTER MID20480 supplies both engine URL and `res_download_url`.
2. Foreground `AssetDownload.lua` uses `version.json`/`lazyFile.json`, native `FileDownloader`, and `<basename>.<md5>` URLs.
3. `SilenceDownloader.lua` is a background prefetch path using the same lazy CDN convention.
4. MID2 is the startup ZIP/volume update path for writable resources/source. Numeric `N.N.N` resource versions are mandatory.
5. Writable `src_64` is ahead of packaged source in package path. A new writable Lua module has been runtime-installed through MID2; a modified-existing-module precedence probe is still worth doing once.
6. Recovered `downloaded-assets/src_64` has 62 files; all differ from APK counterparts. Its `LoginWindow.lua` only changes the default non-debug region index in the inspected diff, not the account lifecycle.

## Authentication findings added in Pass 20

Current credential/register test server log:

- SDK 65305 ×1
- SDK 65319 ×1
- SDK 65284 ×1 (`tp_code=anonymous`)
- SDK 65281 ×5 with `login_email` + `password`
- `query_pay_method_amounts` ×1
- no registration request reaches HTTP.

Therefore:

- credential Login **does reach** the server at SDK MID65281; current generic response does not complete the expected native/UI transition;
- Register “account contains invalid character” is client/native SDK validation before HTTP in this test;
- exact native registration MID and validation rules are still unknown from `src_64`.

## Account → player lifecycle source conclusions

Android `LoadingScene.lua` uses native `xydNewLogin`/`xydAutoLogin`, then Lua `LoginWindow` calls MID18 `LOAD_USER_REGIONS` with SID/token.

MID18 response model:
- `regions`
- `players`
- `recall_regions`

Player briefs include region/vip/level/name/id/avatar/conquer summary. If name is empty, UI displays numeric player ID.

If MID18 reports no players, LoginWindow immediately dispatches LOGIN and LoadingScene sends MID1 `RETRIEVE_TOKEN` for the selected region. No Lua CREATE_PLAYER request exists in between. Strongest source-backed future model: first MID1 for `(account_uid, region)` atomically creates/resolves the game player and returns `is_new=1` if newly created.

For `is_new=1`, opening story eventually enters `EditNameScene`; initial naming uses MID23 `EDIT_PLAYER_NAME`, then MID26 `SAVE_STORY`. No `Guestxxx` pre-name scheme is source-confirmed. Empty `player_name` is supported.

## Player/state contract expansion

`SelfPlayer:onPlayerInfo_()` directly consumes 93 MID17 fields. `StoryData` consumes `story_id/story_state/guide_id` from the same payload. The global `economy_` event can update 47 fields.

Timed client mirrors that a canonical server must keep consistent include at least:
- energy,
- spirit energy,
- skill points,
- arena invitation.

The existing 999999-like mana/crystal development values are sandbox defaults, not a completed economy model. Campaign energy, general spend/reward synchronization, and fresh-account initial economy remain to map/implement.

## Future backend architecture direction

Keep distinct:

1. `accounts` — SDK credential/anonymous identity.
2. `sessions` — SID/token/cookies/session lifetime.
3. account-region player index — `(account_uid, region_id) -> player_id`.
4. canonical player state — stable `player_id`, profile/economy/tutorial.
5. domain repositories — Heroes, Inventory, Formation, Campaign, Social, etc.
6. future PvP/Arena — rankings/reports over stable player IDs and snapshots/projections from canonical Hero/Formation state.

Do NOT equate SDK UID and game player ID.

## Roadmap policy

Competitive/Arena/Top is intentionally deferred until the identity/player/formation/snapshot spine is robust. Payment remains permanently out of scope. Anonymous sandbox behavior should remain available as a privileged reconstruction profile when credential accounts are later added.

## Key Pass 20 docs

- `PASS20_INDEX.md`
- `AUTH_ACCOUNT_PLAYER_LIFECYCLE_PASS20.md`
- `PLAYER_STATE_AND_PERSISTENCE_PASS20.md`
- `UPDATE_DELIVERY_AND_GLOBAL_RESPONSE_PASS20.md`
- `BACKEND_DESIGN_PASS20.md`
- `LIVE_DISCOVERY_DELTA_PASS20.md`
- `PASS20_SOURCE_FACTS.json`

---

# GXB backend working memory / protocol map

Last updated: 2026-08-16 (review pass: backend archives + chat-history.txt + source asset archive)

## Scope

This file is the compact working memory for the backend build. Read it before continuing protocol work, and update it after each backend work pass.

Reviewed artifacts in this pass:
- `all-assest-rechecked.zip` — unpacked and checked for conventional README filenames; none were present in the asset tree.
- `gxb-backend-boot-skeleton-2026-08-16.zip` — unpacked and reviewed, including `AGENT_HANDOFF.md`, `PROTOCOL_NOTES.md`, `BOOT_FIX.md`, `PATCH_STATUS_2026-08-16.md`, `BOOT_MID_MAP.md`, `mids.py`, `game_logic.py`, `server.py`, tests, MID catalog and audit JSON.
- `chat-history.txt` — reviewed through the latest findings, including EventDispatcher tracing, SDK cookie investigation, RETRIEVE_TOKEN/bootstrap fixes, and the post-`xydSelectServer` status.

The source asset archive contains `src_64` with 4,370 Lua files. The backend archive does not contain the original README filenames; its consolidated `PROTOCOL_NOTES.md` replaces the earlier reconstruction READMEs and preserves the older subsystem appendix.

## Source-of-truth hierarchy

1. Decompiled Lua source in `src_64` for actual client behavior and response consumption.
2. `tools/api_audit.json` + `tools/MID_CATALOG.md` for request/response field extraction from all `Backend:request()` call sites.
3. `AGENT_HANDOFF.md`, `PROTOCOL_NOTES.md`, `BOOT_FIX.md`, and `PATCH_STATUS_2026-08-16.md` for prior-agent history and already-applied changes.
4. `chat-history.txt` for live-capture evidence and reasoning history. Treat its `[Inference]` statements as inference unless independently confirmed by source/logs.
5. OpenCode/other agent analysis is useful as a lead only; do not treat its architectural claims as authoritative without source evidence.

## Authoritative client-side facts

- Numeric MID definitions: `src_64/app/common/network/mid.lua`.
- HTTP request/response transport: `src_64/app/common/network/Backend.lua`.
- Boot/login scene: `src_64/app/scenes/LoadingScene.lua`.
- Player bootstrap consumer: `src_64/app/model/SelfPlayer.lua`.
- Library bootstrap consumer: `src_64/app/model/Library.lua`.
- Main scene entry: `src_64/app/scenes/MainScene.lua`.
- Message/chat bootstrap: `src_64/app/model/MessageManager.lua`.
- Event dispatcher: `src_64/framework/cc/components/behavior/EventProtocol.lua` (the reviewed chat trace reports `dispatchEvent` has no `pcall`).
- `tools/api_audit.json` records request sites and response fields consumed by the Lua client.

## Exact boot-critical path mapped from source

1. `UpdateScene` reaches `LoadingScene`.
2. `LoadingScene.login_()` sends MID `1` (`RETRIEVE_TOKEN`).
3. `Backend.lua` dispatches the successful MID 1 response as `xyd.event.TOKEN` before invoking LoadingScene's inline callback.
4. `SelfPlayer:loginEvent_()` receives TOKEN, stores root `uid`, then calls `loadGameStartInfoEvent_()`.
5. `loadGameStartInfoEvent_()` executes `pairs(params.detail)` unconditionally. Therefore `detail` itself must be a table; individual keys are guarded and may be absent.
6. Verified useful `detail` entries:
   - `17` `LOAD_PLAYER_INFO`
   - `49` `LOAD_HEROS`
   - `81` `LOAD_BACKPACK`
   - `836` `GET_LIBRARY_INFOS`
7. `SelfPlayer:onPlayerInfo_()` requests MID `2784` (`ALBUM_SPECIAL_COLLECT_INFO`) asynchronously and consumes `is_award`.
8. LoadingScene's MID 1 callback reaches `selectServer()` / native `xydSelectServer(region_id)`, then proceeds through:
   `updateMeta_()` → `StoryData.updateDataFromStorage()` → `loadModel(MESSAGE_MANAGER)` → `audio.stopMusic(true)` → `MainScene.new()`.
9. `MessageManager.ctor()` enters world/service chat using MID `192` (`LOAD_CHAT_ROOM_INFO`) asynchronously. The response needs `host`, `port`, and `room_id`; TCP chat itself is not implemented in this backend.
10. The reviewed chat history reports that `EventProtocol.lua`'s `dispatchEvent` has no `pcall`, so a listener exception can abort the shared backend success callback. This makes malformed bootstrap state especially important.

## Bootstrap detail contract

`RETRIEVE_TOKEN.detail` is a string-keyed MID batch. The source enumerates roughly 30 possible entries:

`17, 780, 49, 81, 112, 115, 2561, 229, 289, 336, 352, 384, 2485, 1408, 368, 56, 624, 612, 822, 530, 1056, 1152, 1808, 1304, 1856, 836, 2137, 2139, 2416, 2501, 2560, 2984, 3101`.

Do not blindly populate all of them. Missing individual keys are guarded no-ops; an invented malformed payload can create a later nil/type failure.

Current targeted bootstrap:
- `detail["17"]` = valid player payload.
- `detail["49"]` = `{sort_type=0, heros={}}`; needed because `calculateWhiteAlbumAttr()` iterates `heros_` without a nil guard after player bootstrap.
- `detail["81"]` = `{sort_type=0, list={}, spirit_list={}}`; needed because `MessageManager` synchronously reaches `SelfPlayer:getMyCurrentAvatarID()` and may call backpack lookup before `MainScene.new()`.
- `detail["836"]` = valid empty library payload with `bg_main=1`, `bg_room=2`; needed because `MainScene:setupBackground()` reads `Library.bgMain`.

These four are source-derived targeted fixes, not generic guesses.

## Boot sequence observed in supplied live evidence

A successful run progressed through:

`65305 → 65319 → 65284 → GET_PLAYER_GROUP_BY_KEY (2864) → LOAD_ANNOUNCE (7) → RETRIEVE_TOKEN (1) → ALBUM_SPECIAL_COLLECT_INFO (2784) → update_played_server → xydSelectServer SUCCESS`

The backend/chat history also records successful engine handling of `RETRIEVE_TOKEN` with `login_token=local_token`, `sid=13371337`, and the `17/49/836` bootstrap, followed by `xydSelectServer SUCCESS`.

Center discovery `20480`, version `2`, region `18`, and server-time `3` belong to the broader startup contract. Exact ordering should be derived from fresh captures when needed rather than assumed from older analysis.

## SDK/session findings — confirmed history

The supplied SDK smali showed that the session is populated from HTTP cookies named:
- `QQWSID`
- `QQWUID`
- `QQWUNAME`
- `QQWTOKEN`

The backend was patched to emit these cookies. A supplied live capture then showed `cookies size:4`, all four cookie values, and a populated `UserSession` with `SID/UID/UNAME/TOKEN`; no further `no SID.` retry appeared in that successful session. Therefore the original cookie/session problem is considered fixed.

There is a later `cookies size:0` observation around `xydSelectServer`; do not reinterpret that as proof that the original login cookie fix failed. The same capture already shows the engine authenticated and `xydSelectServer SUCCESS`. The empty local `XinydUser` session observed afterward is a separate SDK object in the supplied history.

Engine token consistency was also corrected: SDK `QQWTOKEN` and `RETRIEVE_TOKEN.token` now both use `local_token` instead of the previous backend-only `local_admin_token`. The history explicitly says this mismatch is real but its causal relationship to the current stall is unverified.

## Current post-login status

The remaining problem is **after `xydSelectServer SUCCESS` and before the game is visibly usable**. The supplied history does not prove whether the failure is:
- inside the synchronous `updateMeta_()` / StoryData / MessageManager / audio transition,
- inside `MainScene.new()`,
- a blank/broken scene rather than a failed transition,
- or another missing client-state dependency.

No `LUA ERROR` was found in the supplied ADB capture. The history also notes that the main `com.carolgames.gxb` process did not show the fatal exception seen in the separate `EmulatorCheckService` process. Do not treat that separate native emulator-check exception as the proven cause of the main loading issue.

The client-side `isLoggingIn_` guard is read but, according to the reviewed full-tree grep in chat-history, never set to `true`. Consequently repeated taps can restart `login_()` and produce repeated `xydSelectServer` cycles. This is a client-side diagnostic nuisance, not a server timer.

The payment SDK warning (`query_pay_method_amounts` returning empty methods/amounts and a restart toast) is separate evidence and is not currently proven to block MainScene.

## Backend architecture decision

Keep the current small `server.py` + `game_logic.py` architecture for the boot skeleton. Do not over-engineer into many service modules until the boot path is stable.

Engine responses are flat JSON objects; `error_code=0` is top-level. SDK responses use the SDK envelope plus session cookies.

MID-specific exceptions already implemented:
- `20480` center discovery: flat `{url, server_id, back_domain, res_download_url}`.
- `2` version check: flat update flags with `need_restart=0`.
- `18` regions: `{regions, players}`.
- `7` announce: `contents` is a JSON string.
- `2864` AB-test group: bare scalar `"A"` (not an engine envelope).
- `1` RETRIEVE_TOKEN: root identity/session fields plus non-empty `detail`.
- `2784`: `{is_award=0}`.
- `192`: `{host, port, room_id}` minimal HTTP contract; no TCP chat server.
- `3`: server-time payload.

Unknown engine MIDs remain generic successful responses for now. They are not declared semantically complete.

## Transport / routing facts

There are three request surfaces:
1. SDK Java layer: its own JSON envelope and cookie behavior.
2. Center discovery: form `payload`, flat JSON response.
3. Engine/game API: form `payload`, flat JSON response; a few result MIDs use zlib/multipart.

`UpdateScene.lua` first reaches center MID `20480`; its `response.url` becomes `xyd.serverUrl` for subsequent engine traffic. `server.py` therefore relies on this redirect/trampoline behavior.

`server.py`'s payload decoder intentionally tries plain JSON, URL-decoding variants, and zlib variants because the decompiled client has inconsistent encoding paths.

## Evidence / confidence rules

- **Confirmed/source-derived:** exact field names and control flow when directly read from `src_64` or supported by concrete log output.
- **Supported by supplied history:** findings repeated in `chat-history.txt` that quote concrete logs/source paths, but not independently re-read this pass.
- **Unverified/inference:** any statement about the ultimate post-`xydSelectServer` blocker, gameplay semantics not rechecked this pass, or whether an optional response field is sufficient without a device run.

Never promote the old battle/Arena/March/Treasure appendix from `PROTOCOL_NOTES.md` to confirmed protocol truth without re-reading the relevant Lua consumers.

## Current known boot map

| MID | Name | Phase | Minimal contract | Source consumer |
|---:|---|---|---|---|
| 20480 | center discovery | engine bootstrap | `url`, `server_id`, `back_domain`, `res_download_url` | center/server setup |
| 2 | version check | engine bootstrap | `need_restart=0` plus flags | update/loading path |
| 18 | LOAD_USER_REGIONS | login | `regions`, `players` | LoginWindow |
| 7 | LOAD_ANNOUNCE | login | `contents` as JSON string | LoginWindow |
| 2864 | GET_PLAYER_GROUP_BY_KEY | login | bare `"A"` | SelfPlayer AB-test group |
| 1 | RETRIEVE_TOKEN | critical | token/session fields + `detail` | Backend TOKEN event + LoadingScene |
| 17 | LOAD_PLAYER_INFO | detail | player state | SelfPlayer |
| 49 | LOAD_HEROS | detail | `sort_type`, `heros` | Player/SelfPlayer |
| 81 | LOAD_BACKPACK | detail | `sort_type`, `list`, `spirit_list` | SelfPlayer/MessageManager |
| 836 | GET_LIBRARY_INFOS | detail | library fields + `library_bg_infos` | Library/MainScene |
| 2784 | ALBUM_SPECIAL_COLLECT_INFO | post-player async | `is_award` | SelfPlayer |
| 192 | LOAD_CHAT_ROOM_INFO | MessageManager ctor | `host`, `port`, `room_id` | Backend TCP chat setup |
| 3 | QUERY_SERVER_TIME | startup/support | `server_time` | time consumers |

## What is NOT proven

- This does not prove that every one of the 1,125 unique MID expressions in the audit is implemented.
- This does not prove the exact cause of the post-`xydSelectServer` visual stall.
- This does not implement gameplay/chat/battle semantics.
- The TCP chat server protocol is not mapped.
- The payment SDK warning is not proven fatal.
- The separate EmulatorCheckService native exception is not proven to block the main game process.

## Next work order

1. Read this file before every backend pass and update it after the pass.
2. If a fresh device capture is available, capture the complete main-process Lua output around `LoadingScene.login_()` → `MainScene.new()` before inventing another response.
3. Continue source mapping from `src_64`, prioritizing all requests reachable immediately before/after `MainScene.new()` and any nil-sensitive model initialization.
4. Use `tools/MID_CATALOG.md` / `api_audit.json` to derive exact response fields from consumers.
5. Promote additional MIDs from generic compatibility responses only when their source consumer has been inspected.
6. Keep simple Python syntax checks; do not do extensive testing unless a concrete protocol failure requires it.


## Full src_64 recursive API-surface pass (2026-08-16)

A complete recursive scan of `/app-assets/output/assets/src_64` was performed. Important scope correction: the earlier 62-file `src_64` seen under `downloaded-assets/output/src_64` is only a partial extracted tree. The complete asset tree is `/app-assets/output/assets/src_64` and contains 4,370 Lua files. All recursive API mapping in this pass uses that complete tree.

Generated companion reports in this backend:
- `API_SURFACE_MAP.md` — every statically identifiable `Backend:request()` MID call site, plus unresolved dynamic request sites.
- `PLAYER_BOOT_PROTOCOL.md` — source-derived login/player identity and boot sequence.

Recursive request scan results:
- 4,370 Lua files scanned.
- 1,210 MID definitions in `app/common/network/mid.lua`.
- 1,345 backend request call sites.
- 1,035 unique numeric MIDs have direct/static request call sites.
- 106 call sites select the MID dynamically; these need branch-level resolution before being marked semantically complete.

### Important correction about pre-UpdateScene login

The Lua source does **not** show the game asking the backend for a player ID before `UpdateScene`. The actual Lua startup is:

`boot_64.lua -> UpdateScene_64 -> MID 20480 center discovery -> MID 2 version/resource check -> app.Game -> LoadingScene`.

Only after `LoadingScene` is running does `showLoginSdkWindow()` invoke native `AppActivity.xydNewLogin`. The resulting Lua login event then sends MID `1` `RETRIEVE_TOKEN`. Native SDK traffic can exist outside the Lua asset tree, but this asset does not support a claim that a backend player-ID transaction occurs before `UpdateScene`.

### Player identity distinction

The login request for MID 1 contains `sid`, `login_token`, `region`, `is_test`, `v_`, `app_v`, and `platform`; it does **not** contain `player_id`. `SelfPlayer:loginEvent_()` stores root-level `response.uid` as the account/session UID. The actual game player ID is taken from `detail["17"].player_id` by `Player.populate()`. Therefore backend state should map the authenticated account/session + selected region to a stable `player_id`, rather than expecting the client to provide one in the initial RETRIEVE_TOKEN request.

### RETRIEVE_TOKEN detail is larger than the old four-entry skeleton

`SelfPlayer:loadGameStartInfoEvent_()` explicitly recognizes these detail MIDs:
`17, PETS_GET, 49, 81, 112, 115, AWAKE_MISSION_LIST, 229, LOAD_ARENA_FIGHT_RECORDS, 336, 352, 384, 2485, REGION_GET_ARENA_INFO, 368, LOAD_SUMMON_INFO, WORLD_BOSS, GET_SELF_GUILD, PET_CAMPAIGN_RED_POINT, TREASURE_LOAD_INFO, GET_BUILDING_LIST, GUILD_WAR_RED_POINT, GET_TEA_TALK_INFO, GET_OFFLINE_INFO, GET_CLASS_INFO, 836, GET_STUDY_INFOS, GET_GIFT_BOX_INFO, GET_ADVENTURE_LIST, GET_HERO_RECOMMEND_SCORES, RED_POINT, BATTLE_PASS_GET_INFO, HUNQI_START_GAME_GET_INFO`.

Individual entries are guarded, but the `detail` table itself is required because the handler calls `pairs(detail)`. The backend should therefore treat the batch as a deliberate state hydration mechanism, not just a convenience for MID 17.

### Backend implementation priority from the complete scan

1. Keep 20480/2 correct because they are the only Lua HTTP requests in `UpdateScene` before `app.Game`.
2. Keep SDK cookie/session handling correct for native SDK traffic.
3. Make MID 1 deterministic and populate a coherent player state.
4. Populate shape-correct detail entries for the synchronous player/hero/backpack/library path; then progressively add the other recognized detail MIDs if their consumers need them for first-scene initialization.
5. Keep MID 192 shape-correct for MessageManager's chat-room lookup.
6. Promote the remaining 1,000+ MIDs from generic compatibility responses by subsystem, using the source consumer to derive exact request/response fields.
7. Resolve the 106 dynamic request sites separately; do not label them missing endpoints merely because the call line does not contain a literal MID.

The complete API inventory is documented in `API_SURFACE_MAP.md`.


## Complete app-assets/src_64 mapping pass 2 (2026-08-16)

The complete base-code tree was re-opened from `all-assest-rechecked.zip` at `app-assets/output/assets/src_64`. The user supplied an important runtime asset rule: `downloaded-assets/` is pushed into the game's private files directory and should take precedence over same-named packaged assets because it is treated as newer. This is recorded as a **user-supplied rule; not independently verified in this pass**. Core Lua protocol design continues to use `app-assets/output/assets/src_64`.

### Complete source inventory
- 4,370 Lua files total.
- 2,257 under `app/`.
- 1,241 under `data/`.
- 741 under `lib/`.
- 90 under `framework/`.
- 16 under `cocos/`.
- Remaining 25 are root/bootstrap/support Lua files.
- `src_32` is intentionally excluded per project instruction.

### API audit correction
The bundled `tools/api_audit.json` contains **1,345 request records with zero parser errors** and **1,074 unique numeric MIDs**. **50 records** have unresolved/non-numeric MID expressions. `mid.lua` contains **1,210 numeric MID assignments**. Therefore the current static audit covers most but not all defined MIDs; the 136-definition gap must not be labeled dead code until dynamic/indirect reachability is resolved.

A simple regex scan produced slightly different site counts because of generated/decompiler syntax. For contract mapping, use `api_audit.json` as the primary request-site inventory and the source itself for semantics.

### New documentation added
- `SRC64_COMPLETE_MAP.md` — complete static MID/API matrix plus dynamic sites and model inventory.
- `LUA_FILE_INVENTORY.md` — every one of the 4,370 Lua files, line count, API calls/MIDs where present, role bucket, plus model/window API indexes.
- `BACKEND_DESIGN_FROM_SRC64.md` — backend layering/state architecture and the complete mapping workflow.

### Source-confirmed boot refinement
`LoadingScene.login_()` sends MID 1 with `sid`, `login_token`, `region`, `is_test`, `v_`, `app_v`, `platform`; it does not send `player_id`. `SelfPlayer.loginEvent_()` stores root response `uid`, while `Player.populate()` receives `player_id` from detail[17]. The backend therefore needs account/session -> player-state resolution rather than a client-supplied player ID.

The exact normal-login transition after successful MID 1 is source-confirmed as:
`selectServer(region) -> updateMeta_(sid, region) -> StoryData.updateDataFromStorage() -> loadModel(MESSAGE_MANAGER) -> audio.stopMusic(true) -> MainScene/start-story branch`.
`StoryData.updateDataFromStorage()` is local storage only. `MessageManager.ctor()` synchronously reads SelfPlayer state and initiates MID 192 chat-room discovery. MainScene then reads Library `bgMain` and opens five main-scene windows.

### Mapping priority going forward
1. Finish all `app/common`, `app/model`, `app/scenes`, and `app/windows` request consumers.
2. Resolve the 50 dynamic audit records by following their variable/table construction; several are conditional pairs rather than genuinely unknown MIDs.
3. For each MID record request payload construction + callback fields + model mutation + follow-on requests.
4. Then map feature modules and static data tables used by those consumers.
5. Only after the protocol map is stable should the backend be overhauled into domain handlers/state repositories.

### Backend design rule retained
Keep one canonical player state. `RETRIEVE_TOKEN.detail[17]`, later MID 17, hero state, backpack, library, and other bootstrap/gameplay responses should be projections of that same state. Avoid independent fake payload stores.

### Current confidence
The complete file inventory and audit counts above are directly verified from the supplied archive/backend audit. The downloaded-assets precedence rule is user-supplied and unverified. The exact cause of the post-`xydSelectServer` visual stall remains unverified.

## Event-consumer and bootstrap-contract pass 7 (2026-08-16)

Read this file before continuing. This pass focused on the missing middle of the API dependency graph: MID -> event -> registered consumer -> model/state mutation, plus exact `RETRIEVE_TOKEN.detail` consumer contracts and the API surface reached by MainScene initialization.

### Event system facts
- `Backend.lua` contains 106 explicit numeric MID -> `xyd.event.*` mappings.
- `BaseModel:registerEvent()` delegates to the global `xyd.EventDispatcher`.
- The actual dispatcher implementation is `framework/cc/components/behavior/EventProtocol.lua` and invokes registered listeners synchronously in its `dispatchEvent()` loop.
- A static scan found 198 event-listener registrations in `app/` for the mapped event names. This is a source inventory, not proof that every listener is instantiated in every runtime path.
- New report: `EVENT_CONSUMER_MAP_PASS7.md`.

### RETRIEVE_TOKEN detail is explicitly a state hydration batch
`SelfPlayer:loadGameStartInfoEvent_()` first obtains `arg_221_1.params.detail`, enumerates and sorts its numeric keys, and then processes recognized detail MIDs individually. Each entry is ignored if absent or if it has `error_msg`. This means the root `detail` object is required, while most individual entries are conditionally optional.

The recognized detail entries are:
`17, PETS_GET, 49, 81, 112, 115, AWAKE_MISSION_LIST, 229, LOAD_ARENA_FIGHT_RECORDS, 336, 352, 384, 2485, REGION_GET_ARENA_INFO, 368, LOAD_SUMMON_INFO, WORLD_BOSS, GET_SELF_GUILD, PET_CAMPAIGN_RED_POINT, TREASURE_LOAD_INFO, GET_BUILDING_LIST, GUILD_WAR_RED_POINT, GET_TEA_TALK_INFO, GET_OFFLINE_INFO, GET_CLASS_INFO, 836, GET_STUDY_INFOS, GET_GIFT_BOX_INFO, GET_ADVENTURE_LIST, GET_HERO_RECOMMEND_SCORES, RED_POINT, BATTLE_PASS_GET_INFO, HUNQI_START_GAME_GET_INFO`.

New report: `BOOTSTRAP_DETAIL_CONTRACT_PASS7.md` maps each entry to its exact consumer/model and records fields where the handler was directly inspected.

### Exact source-confirmed critical detail shapes
- `17 LOAD_PLAYER_INFO`: `SelfPlayer:onPlayerInfo_()` directly consumes many fields including `player_id`, `exp`, `boss_incr_exp`, `lev`, `uid`, `mana`, `region`, `region_name`, `crystal`, `lucky_coin`, `arena_coin`, `march_coin`, `top_coin`, `guild_coin`, `region_coin`, `king_coin`, `honor_coin`, `god_war_coin`, `friendship_coin`, `friend_medal`, `summon_coin`, `skin_fragment`, `glue`, `buy_glue_times`, `lvbu_coin`, `paradise_coin`, `team_dungeon_coin`, and many additional `params` consumed by the player model.
- `49 LOAD_HEROS`: `Player:herosEvent_()` expects `params.sort_type` and `params.heros`; each hero entry is passed to `Hero:populate`. Event userdata must contain the correct `player_id` and `conquer_lev` for this path.
- `81 LOAD_BACKPACK`: `SelfPlayer:onBackpackEvent_()` stores `params.sort_type` and passes the complete params object to `Backpack:populate`; earlier source inspection confirms `list` and `spirit_list` are part of the expected structure.
- `112 LOAD_WORLD_MAP`: handler directly expects `normal`, `super`, `challenge`, `chapter_events`, and `chapter_info` structures.
- `352 LOAD_SIGN_INFO`: handler directly consumes `awards`, `is_signed`, `partner_id`, `sign_times`, `month`, and `is_skin`.
- `289 LOAD_ARENA_FIGHT_RECORDS`: handler directly consumes `records` and each record may contain `report_key`.
- `836 GET_LIBRARY_INFOS`: `Library:updateLibraryInfos()` expects `library_infos`, `library_talk_infos`, `library_cg_infos`, and `library_bg_infos`; background data uses `bg_main`, `bg_room`, `has_buy`, `server_time`.
- `GET_OFFLINE_INFO`: response is stored as `newAchievementIds`; non-empty data can trigger main-scene red-mark handling.
- `HUNQI_START_GAME_GET_INFO`: response is stored as `SelfPlayer.spiritCampaignInfo`.

### MainScene reachability
After successful MID 1, `LoadingScene.login_()` does `selectServer()`, `updateMeta_()`, local `StoryData:updateDataFromStorage()`, loads `MESSAGE_MANAGER`, stops music, and conditionally replaces the scene with `MainScene` or opens the story path.

`MessageManager` constructor reads from SelfPlayer: region/player ID/name/avatar/frame/level/player type; it immediately enters the player's chat room and service room `99999`, with guild chat conditional on guild ID. MID 192 therefore remains a real HTTP dependency during the transition, followed by TCP chat setup.

`MainScene.lua` itself and models loaded by it expose a much larger conditional API surface. New report: `MAINSCENE_API_SURFACE_PASS7.md`. Direct MainScene requests observed include `LOAD_ARENA_FIGHT_RECORDS`, `PEAK_RECORDS`, `GET_PIC_NOTICE_INFO`, `SIGN`, and `HUNQI_GET_CAMPAIGN_INFO`; many more calls originate from model initialization (arena, region arena, activities, guild, event centre, anniversary/event models, etc.). These must be mapped by model rather than treating MainScene as a single API domain.

### Important backend design rule strengthened
The backend should not implement `RETRIEVE_TOKEN.detail` as unrelated canned blobs. It should project one canonical `PlayerState` into the detail entries. `detail[17]`, `detail[49]`, `detail[81]`, `detail[836]`, and later standalone MIDs must remain internally coherent.

### What remains unverified
- Static event registration does not prove runtime instantiation order.
- Exact complete field lists for delegated model handlers are not yet extracted for every recognized detail MID.
- The post-`xydSelectServer` visual stall is still not source-proven to be caused by a missing backend response.
- TCP chat wire protocol remains unmapped.
- Conditional MainScene feature calls are not all required for a minimal fresh-player boot; their exact reachability depends on state/config.

### Next mapping priority
1. Finish exact response field extraction for every recognized `RETRIEVE_TOKEN.detail` consumer by opening each target model handler.
2. Build model-method -> MID maps for all `app/model` files, including request fields and callback consumers.
3. Resolve the 50 dynamic MID request sites by tracing the variable/table construction.
4. Continue into `app/windows` and `app/modules`, recording which MIDs each screen can trigger and which model state it requires.
5. Keep all source-derived contracts separate from capture/inference.
6. Only after these mappings stabilize should the backend be substantially rewritten.

## Model/API contract expansion pass 8 (2026-08-16)

Read this file before continuing. This pass moved from the global MID graph into the `app/model` API layer and created per-MID/per-model contract documents.

### New generated documentation
- `MODEL_API_CONTRACT_INDEX_PASS8.md` — index of every `app/model/*.lua` file with at least one audited Backend request.
- `api_contracts/models_pass8/*.md` — one mini-contract file per model source path with audited calls.
- `DYNAMIC_MODEL_API_PASS8.md` — 25 model request sites whose numeric MID could not be resolved by the audit.
- `api_contracts/mids_pass8/*.md` — one mini-contract file for each of the 1,074 numeric MIDs represented in the supplied audit. Each file records audited call sites, explicitly extracted request fields, raw request expressions, and response fields observed being read.
- `api_contracts/windows_index_pass8.md`, `api_contracts/scenes_index_pass8.md`, `api_contracts/common_index_pass8.md` — source-path API indexes for those areas.

### Pass-8 counts
- `app/model`: 98 source files with audited API calls.
- `app/model`: 922 audited request records.
- `app/model`: 25 unresolved/non-numeric MID request sites.
- Numeric MID mini-docs: 1,074, matching the current audit's unique numeric MID coverage.
- `app/windows`: 382 audited request records.
- `app/modules`: no direct `Backend:request` call sites were found by the current audit; modules appear to rely on models/windows/backend callers rather than directly owning the HTTP API surface. This is an audit result, not proof that no indirect network behavior exists.

### Contract interpretation rule strengthened
The per-MID files are protocol evidence, not complete server schemas. A missing request field means the audit could not statically extract it; it does not prove the client sends no field. A response field listed is directly observed by the audit as read by the Lua client. Fields not listed remain unknown until source tracing/capture evidence supplies them.

### High-value model surface now captured
`SelfPlayer.lua` alone has 59 audited request call sites spanning player bootstrap and gameplay mutation APIs. The generated mini-doc records, among others:
- 17 `LOAD_PLAYER_INFO`
- 49 `LOAD_HEROS`
- 81 `LOAD_BACKPACK`
- 112 `LOAD_WORLD_MAP`
- 115 `LOAD_TRIAL_INFOS`
- 2784 `ALBUM_SPECIAL_COLLECT_INFO`
- 2864 `GET_PLAYER_GROUP_BY_KEY`
- 289 `LOAD_ARENA_FIGHT_RECORDS`
- 352 `LOAD_SIGN_INFO`
- 780 `PETS_GET`
- 836 `GET_LIBRARY_INFOS`
- plus player mutations such as hero power-up/evolution, skill changes, item use, summon, team save, etc.

`Activities.lua` has 9 audited request records over 8 MIDs, including activity load/reward/fund/question/award operations. Similar mini-docs now exist for every other audited model file.

### Dynamic model calls still requiring source tracing
The current 25 include `CHECK_ACHIEVEMENT`, `LOAD_DUNGEON`, social friend operations, magic shop/market, peak arena, Ragnarok, rune power-up, Sakura fight, several SelfPlayer mutations, SingleDay, and SocialSystem. These are intentionally left unresolved in `DYNAMIC_MODEL_API_PASS8.md` rather than guessed.

### Important design consequence
The API dependency map should now be assembled from three linked artifacts:
1. per-MID contract (`api_contracts/mids_pass8/`),
2. per-source-path/model contract (`api_contracts/models_pass8/` and window/common indexes),
3. event/state dependency maps from Pass 7.

This gives the backend implementation a stable lookup chain:
`MID -> call sites -> request fields/raw expression -> response fields consumed -> event/model consumer -> state mutation/follow-up calls`.

### Still no backend overhaul
No new semantic backend handlers were added in Pass 8. The purpose remains protocol mapping before implementation, per project instruction.

## Undefined symbolic MID analysis pass 9 (2026-08-16)
Read this before continuing. This pass traced the previously unresolved model request sites and compared every `xyd.mid.<NAME>` use in the complete packaged `src_64` tree against numeric assignments in `app/common/network/mid.lua`.

### New source-confirmed finding: undefined MID symbols
- `mid.lua` has **1,210 numeric MID assignments**.
- Recursive `src_64` scan found **1,236 distinct `xyd.mid.<NAME>` symbols used**.
- **26 symbols have no assignment anywhere in the supplied Lua tree**.
- **24 are model-facing**; 2 are Backend-only special-routing comparisons (`CLOSE_GUILD_CHAT`, `GUILD_ALLY`); all 26 are documented in `UNDEFINED_MID_ANALYSIS_PASS9.md` and individual files under `api_contracts/undefined_mids_pass9/`.
- Do not invent numeric values for these symbols. `tools/MID_CATALOG.md` and `tools/api_audit.json` can record symbolic request sites without supplying numeric assignments.

### Model response contracts refined
- `LOAD_DUNGEON`: `params.list` is required by `Dungeon:dungeonEvent_()`; list entries go to `DungeonItem:populate()`.
- `LOAD_MAGIC_SHOP`: `params.left_time` and `params.items` are directly consumed; each item uses `table_id`.
- `LOAD_MARKET`: `params.list` required; entries use `table_id`, optional `expire_time`.
- `LOAD_SEND_REQUEST_PLAYERS`: `params.list` required; entries go to `NonFriendPlayer:populate()`.
- `SEND_SOCIAL`: no response field read at immediate call site; success mutates target player's `socialTime_` and emits `FRIENDS_UPDATE`.
- `SET_LOCK_HERO`: success mutates hero lock state and emits `HERO_UPDATE`; response fields themselves are not directly read.
- Several symbolic endpoints have callbacks that merely forward `(status,response)`, so their schemas remain unknown until callers/listeners are traced.

### Documentation added
- `UNDEFINED_MID_ANALYSIS_PASS9.md`
- `MODEL_RESPONSE_CONTRACTS_PASS9.md`
- `PASS9_SOURCE_GAPS.md`
- `api_contracts/undefined_mids_pass9/*.md` — one mini-doc per undefined symbolic MID.

### Important implementation rule
Do not assign numeric IDs to undefined symbols based on nearby numeric gaps or naming. We need stronger evidence (another source version, capture, native/resource data, or an authoritative mapping) before routing them numerically.

### Next priority
Continue end-to-end model tracing: for every request, locate all immediate callbacks and registered event consumers, extract direct response fields and state mutations, then resolve window callers. Keep resource/reference gaps separate from API gaps.

## Response-consumer tracing pass 10 (2026-08-16)
Read this file before continuing. This pass moved further from raw request inventory toward source-level callback/response semantics in `app/model` and revisited the previously undefined symbolic MID sites.

### New generated documentation
- `API_CALLBACK_CONSUMER_SCAN_PASS10.md` and `.json` — heuristic source scan of `app/model` Backend request callbacks, recording request expressions, directly visible request keys, directly visible response fields, userdata fields, and source files. This is a discovery aid, not a complete schema.
- `SYMBOLIC_API_CONTRACT_INDEX_PASS10.md` — index of focused symbolic API mini-contracts.
- `api_contracts/symbolic_pass10/*.md` — focused mini-docs for previously undefined symbolic MIDs inspected in this pass.
- `UNDEFINED_SYMBOL_CONTRACT_REFINEMENTS_PASS10.md` — compact index of those source-derived symbolic contracts.

### Pass-10 scan result
- `app/model` request callback scan found **851 request records** across **598 symbolic/numeric MID names with no directly extracted response field in this heuristic** and **253 MID names with at least one directly extracted response field**. These counts are for the heuristic callback scan and must not be treated as protocol completeness.
- The large `598` group is important: many client APIs only branch on `status` or forward `(status,response)` to another caller. Their real response schema must be found by tracing the caller/event/window, not by assuming the response is empty.

### Source-confirmed symbolic contracts refined in this pass
- `LOAD_DUNGEON`: request `{}`; response `params.list` is required and each entry is passed to `DungeonItem:populate()`.
- `LOAD_MAGIC_SHOP`: request `{}`; response requires `left_time` and `items`; each item is indexed by `table_id`. `SHOP_MAGIC_BUY` success consumes `pos` and may consume `rune_id`, `partner_id` depending on item type.
- `LOAD_MARKET`: request `{}`; response requires `list`; entries use `table_id` and optional `expire_time`; state is partitioned into glory/normal/special markets.
- `LOAD_RECOMMEND_FRIENDS`: request `{}`; response requires `list` of `NonFriendPlayer` records.
- `LOAD_SEND_REQUEST_PLAYERS`: request `{}`; response requires `list` of `NonFriendPlayer` records; `REQUEST_FRIEND` success itself returns a `NonFriendPlayer` record to this caller; `CANCEL_REQUEST_FRIEND` only needs success status at this immediate caller.
- `POWERUP_RUNE`: request `{rune_id}`; immediate caller consumes no response fields beyond status.
- `SELL_RUNES`: request `{rune_ids}`; success removes those rune IDs from the local rune bag; no response field is consumed here.
- `AWAKE_HERO`: caller-provided request table; immediate response fields are not consumed; success mutates awakening-essence state and local hero/update state. Exact request keys and response schema remain to be traced.
- `SET_REP_HERO`: request is caller-provided and includes `partner_id`; success updates representative hero and dispatches `HERO_UPDATE` with response params/userdata. Exact nested fields still require `heroUpdateEvent_` tracing.
- `SET_LOCK_HERO`: request `{partner_id,is_lock}`; success changes the local hero lock flag and dispatches `HERO_UPDATE`; response params/userdata are forwarded but no scalar response field is directly consumed here.
- `START_SAKURA_FIGHT` and `SINGLE_DAY_START_FIGHT`: request tables are caller-provided; immediate callers forward status/response and do not directly inspect response fields. Exact request keys and downstream consumers remain to be traced.
- `CHECK_ACHIEVEMENT`: request table is caller-provided; immediate method forwards status/response without inspecting fields.

### Important correction/discipline
The absence of a direct response-field read in a callback is **not** evidence that the server can safely return `{}`. It may be forwarded to a window/caller or used by an event listener. We must trace outward before classifying an endpoint as status-only.

### Next priority
1. Trace all `598` no-direct-field callback APIs into their callers and event listeners.
2. Resolve the exact request tables for symbolic/dynamic model APIs by backwards data-flow from the function arguments.
3. Finish the recognized `RETRIEVE_TOKEN.detail` handlers by opening every delegated model/event target.
4. Continue the same request -> response -> state mutation tracing into `app/windows`.
5. Keep numeric MID gaps and undefined symbolic MIDs separate from actual API contracts.


## Response propagation/state-boundary pass 11 (2026-08-16)
Read this file before continuing. This pass remained protocol mapping only.

### Main finding
A request callback that does not directly inspect response fields is not an empty-response contract. The response may be forwarded to a caller, event, or window. The authoritative tracing chain is:
`MID -> request callback -> caller/event/window -> response consumer -> state mutation`.

### Source-supported immediate success mutations
- SEND_SOCIAL: success updates target player's social timestamp and emits FRIENDS_UPDATE; no scalar response field is read at the immediate site.
- SET_LOCK_HERO: request includes partner_id and is_lock; success changes local hero lock state and emits HERO_UPDATE; response fields are forwarded but not directly consumed at the immediate site.
- SET_REP_HERO: request includes partner_id; success updates representative-hero state and emits HERO_UPDATE; exact nested response fields still require heroUpdateEvent_ tracing.
- POWERUP_RUNE: request includes rune_id; immediate caller consumes no response fields beyond success.
- SELL_RUNES: request includes rune_ids; success removes those rune IDs locally; no response field consumed at the immediate site.
- CANCEL_REQUEST_FRIEND: immediate caller needs successful status; downstream response schema remains unresolved.

### Boot boundary reaffirmed
The supplied project history/capture establishes:
SDK session -> RETRIEVE_TOKEN -> detail hydration -> ALBUM_SPECIAL_COLLECT_INFO -> xydSelectServer success.
The Lua-side transition after server selection is:
selectServer -> updateMeta_ -> StoryData.updateDataFromStorage -> loadModel(MESSAGE_MANAGER) -> audio.stopMusic -> MainScene.new.
This does not imply that every transition is another HTTP MID.

### Identity rule
MID 1 does not take player_id as a request field. Session/login + region/version/platform context lead to response uid and detail[17].player_id. Backend should resolve a canonical account/session + region -> PlayerState and derive later responses from the same state.

### Evidence discipline
SDK cookie success is capture/history evidence, not a new Lua protocol discovery. Resource precedence is documented separately from API completeness. Missing art/resource files must not be treated as missing MIDs without source evidence.

### New documentation
- PASS11_RESPONSE_PROPAGATION_AND_STATE.md

### Next priority
Continue outward tracing of the no-direct-response-field callback set, then dynamic request-table resolution, bootstrap detail delegated consumers, and window-level response consumers. Keep unresolved symbolic MIDs and transport-special APIs separate.


## Complete boot-to-MainScene dependency pass 12 (2026-08-16)

This pass re-opened the actual `app-assets/output/assets/src_64` tree from `all-assest-rechecked.zip` and traced the post-MID-1 synchronous transition plus all `RETRIEVE_TOKEN.detail` consumers. No backend semantic implementation was added.

### New source-confirmed findings
- `LoadingScene.setupModels_()` loads `SELF_PLAYER`, `ARENA`, `TASK`, `ACTIVITIES`, and `INVITE_FRIENDS_INFOS` before SDK login; their inspected constructor/onRegister paths do not automatically send HTTP requests.
- `StoryData.updateDataFromStorage()` is local DB synchronization only; it is not an API dependency.
- `MessageManager` is instantiated synchronously before `MainScene.new()`, reads core SelfPlayer state, then asynchronously requests `LOAD_CHAT_ROOM_INFO` for world/service/guild rooms and attempts TCP sockets.
- `MainScene` ctor synchronously reads `Library.bgMain`; the library bootstrap is therefore a genuine state dependency.
- `MainSceneTopWindow:willOpen()` unconditionally calls `CHECK_GAME_STAT` with `{}`; this is the first clearly unconditional HTTP request after scene creation identified in this pass.
- `MainScene.onEnterTransitionFinish()` opens five windows; many later API calls are feature/state gated and are not mandatory boot APIs without satisfying their conditions.
- `Backend:webRequest_()` runs `extraWebResponseCheck_()` and the MID event dispatch **before** the inline request callback. Backend responses therefore have cross-cutting side-effect fields beyond endpoint-specific payloads.
- Cross-cutting response fields confirmed: `v_`, `economy_`, `new_funcs_`, `flag_`, `server_time`, `gm_url`, `extra_drops_`, `act_item_change_`, task arrays, `redmarks_`, `twice_awake_stage_`.
- `LOAD_CHAT_ROOM_INFO` uses HTTP only to discover a TCP endpoint; world/service/guild sockets are distinct channels.
- MID 17 is substantially larger than the earlier minimal player payload. The source directly assigns dozens of player/economy/progression/session fields; the full list is in `PLAYER_INFO_CONTRACT_PASS12.md`.
- `RETRIEVE_TOKEN.detail` is sorted numerically before consumption. Recognized entries are processed in ascending MID order, which matters when one entry initializes state later consumed by another.

### Documentation added
- `PLAYER_INFO_CONTRACT_PASS12.md`
- `MAINSCENE_ENTRY_DEPENDENCIES_PASS12.md`
- `BACKEND_EVENT_ORDER_AND_SIDE_EFFECTS_PASS12.md`
- `PRE_UPDATE_SCENE_NETWORK_BOUNDARY_PASS12.md`
- `CHAT_ROOM_PROTOCOL_PASS12.md`
- `DYNAMIC_AND_UNRESOLVED_PASS12.md`
- `api_contracts/boot_detail_pass12/*.md` — one mini-contract for every recognized RETRIEVE_TOKEN detail entry inspected in this pass.

### Confidence
All findings above are source-derived from the supplied `src_64`. Claims about the ultimate visual boot failure remain unverified because the current objective is protocol mapping, not device diagnosis.

## Pass 13 — MainScene first-entry dependency graph (2026-08-16)

Re-opened the complete `app-assets/output/assets/src_64` source and traced the boundary from successful MID 1 through `MainScene.new()` and the five MainScene windows.

### Source-confirmed immediate first-entry graph
- `MessageManager` starts `LOAD_CHAT_ROOM_INFO` MID 192 for `region`, `99999`, and `guildID` when applicable. Response fields consumed: `host`, `port`, `room_id`. This is HTTP discovery for a separate TCP chat connection.
- `MainSceneLeftWindow` has no automatic HTTP request found in its open path.
- `MainSceneMiddleWindow:didOpen()` unconditionally calls `LOAD_SUMMON_INFO`; response fields consumed include `mana_free_time`, `crystal_free_time`, `second_ids`, `main_ids`, `mana_id`, `pet_id`, `partner_id`, optional `directional_show_id`.
- `MainSceneMiddleWindow:didOpen()` also unconditionally calls `ILLUSION_LOAD_INFO`; response fields consumed include `paradise_info.paradise_id`, `paradise_info.count`, `challenge_times`, `buy_times`, `hurt`, `rank`.
- `MainSceneBottomWindow:willOpen()` unconditionally calls `LOAD_FRIENDS`; response fields consumed include `server_time`, `blacklist`, `friend_list`, `notice_list`, `request_list`, `offline_msg_list`, `send_gift_count`, `receive_gift_count`.
- `MainSceneBottomWindow:willOpen()` conditionally calls `GET_SELF_GUILD` when the guild function is open; it consumes nested guild/self fields.
- `MainSceneBottomWindow:willOpen()` conditionally calls `PETS_GET` when the pet function is open and local pets are not already loaded; it consumes `pets` and passes each record to `Pet:populate()`.
- `MainSceneTouchWindow` has no automatic HTTP call; `FIRST_MAIN_TOUCH` is gesture-triggered when `firstMainTouch == 0`.
- `MainSceneTopWindow:willOpen()` unconditionally calls `CHECK_GAME_STAT` with `{}` and no callback; immediate response fields are not consumed.

### Optional post-entry APIs
`MainScene` can enter `openWindowInOrder()` depending on guide state. This may invoke `GET_PIC_NOTICE_INFO`, `LOAD_SIGN_INFO`, `SIGN`, and activity-model APIs. Retained-window restoration can also invoke arena/peak/hunqi/etc. These are not part of the unconditional first-entry graph.

### Important protocol distinction
`StoryData.updateDataFromStorage()` between `xydSelectServer` and MainScene is local storage, not a backend dependency. Do not add a fake API for it.

### Documentation
- `PASS13_INDEX.md`
- `MAINSCENE_FIRST_ENTRY_PROTOCOL_PASS13.md`
- `api_contracts/pass13_main_scene/*.md`

### Confidence
All findings in this section are source-derived from the complete src_64 tree. The causal relationship between any of these requests and a visual startup stall remains unverified without a fresh device run.

## Pass 14 — MainScene runtime, redmark, and conditional API surface (2026-08-16)
Read this file before continuing. Protocol mapping only; no new backend semantic implementation.

### Main findings
- After MainScene opens its five windows, source-confirmed immediate network calls are: MessageManager `LOAD_CHAT_ROOM_INFO` (192) for region and 99999 plus guildID when applicable; middle-window `LOAD_SUMMON_INFO` (56) and `ILLUSION_LOAD_INFO`; bottom-window `LOAD_FRIENDS`, conditional `GET_SELF_GUILD`, conditional `PETS_GET`; top-window `CHECK_GAME_STAT` (2754). MainSceneTouchWindow has no automatic network request; `FIRST_MAIN_TOUCH` (1864) is user gesture triggered.
- `LOAD_SUMMON_INFO` is duplicated: bootstrap detail hydration, MainSceneMiddleWindow.didOpen, and middle-window redmark checking can all invoke it. Backend should make this read endpoint idempotent and derive all instances from canonical state.
- MainScene's ordered popup flow is conditional on guide/activity/local state. It can call `GET_PIC_NOTICE_INFO`, `LOAD_SIGN_INFO`, `SIGN`, `LOAD_SINGLE_ACTIVITY`, and `QUERY_CHARGE_DATA`. These are reachable immediately after login for eligible states but are not unconditional boot dependencies.
- `GET_PIC_NOTICE_INFO` consumes `has_read` and `contents`.
- `LOAD_SIGN_INFO` consumes `awards`, `is_signed`, `partner_id`, `sign_times`, `month`, `is_skin`; SelfPlayer caches the result.
- `LOAD_SINGLE_ACTIVITY` receives caller-provided `{activity_id=...}` in the ordered popup path and source-confirmed fields are `is_open` and `details.award_id/details.login_day` depending on activity.
- `QUERY_CHARGE_DATA` consumes `charges[]` (`charge_id`, `charge_count`, `last_buy_time`), `giftbags`, and optional `server_time`.
- `CHECK_GAME_STAT` (2754) is an unconditional first-entry request with `{}` and no callback; response schema is not inferable from source.
- Backend `extraWebResponseCheck_()` handles top-level `redmarks_` before event dispatch. `Redmark:onUpdate()` expects entries containing `function_id` and `redmark_list`; `BACKEND_REDMARK` is then dispatched. MID 2560 (`RED_POINT`) is also consumed from RETRIEVE_TOKEN.detail using the same Redmark model.
- Several MainScene timers/random/live2d routines are local-only and must not be mistaken for backend dependencies.

### Documentation added
- `PASS14_INDEX.md`
- `MAINSCENE_RUNTIME_API_PASS14.md`
- `REDMARK_PROTOCOL_PASS14.md`
- `PASS14_SOURCE_GAPS.md`
- `api_contracts/pass14_main_scene_runtime/*.md`

### Next priority
1. Trace the full `LOAD_SINGLE_ACTIVITY` response into every relevant activity window/model.
2. Map the automatic timers/event listeners that can trigger backend calls after MainScene entry, distinguishing local timers from network-triggering timers.
3. Continue outward from `LOAD_FRIENDS`, `ILLUSION_LOAD_INFO`, guild/pet reads, and redmark consumers.
4. Resolve remaining symbolic/dynamic request tables and numeric MID gaps without guessing.

## Pass 15 — MainScene indirect API fan-out and server-time runtime mapping (2026-08-16)

The complete `app-assets/output/assets/src_64` was re-opened for another source-only pass.

### New source-confirmed finding: ACTIVITIES bootstrap has an HTTP fan-out

`SelfPlayer:loadGameStartInfoEvent_()` can feed `RETRIEVE_TOKEN.detail[ACTIVITIES]` directly into `Activities:onLoadActivities_()`.
`Activities:onLoadActivities_()` assigns `params.list`, sorts/recomputes local state, and then calls `loadBoardInfoList()`.
`loadBoardInfoList()` sends `GET_BOARD_INFO` with no request payload and consumes `contents`, sorting the entries by descending `notice_id`.

Therefore:

`MID 1 detail[229] ACTIVITIES -> Activities:onLoadActivities_ -> GET_BOARD_INFO`

This is a real secondary backend dependency. It is not safe to assume that the ACTIVITIES bootstrap entry is passive data.

The directly inspected ACTIVITIES fields include `list`, with activity entries using `table_id`, `is_open`, `start_time`, `end_time`, and `details`. Activity-specific `details` fields remain a large separate tracing surface.

### New source-confirmed finding: LOAD_FRIENDS initializes global server time

`SocialSystem:loadFriends()` sends `LOAD_FRIENDS` and, on success, immediately calls `ServerTime:resetServerTime(response.server_time)`. It then stores `blacklist`, `friend_list`, `notice_list`, `request_list`, `offline_msg_list`, `send_gift_count`, and `receive_gift_count`.

Therefore first-entry `LOAD_FRIENDS.server_time` can start the global server-time ticker. MID 3 (`QUERY_SERVER_TIME`) remains an explicit refresh path, but it is not the only way the ticker can be initialized.

### New source-confirmed finding: server_time is a cross-cutting response field

`Backend:extraWebResponseCheck_()` resets `ServerTime` whenever any successful response contains top-level `server_time`. This means the backend should treat `server_time` as a cross-cutting state field rather than an endpoint-specific field.

### New source-confirmed finding: server-time ticker creates later API dependencies

Once initialized, `ServerTime:start()` schedules once per second and dispatches timing events at fixed server-of-day values:
- `UPDATE_MISSION_ONTIME` at 18001, 43201, 50401, 64801, 72001, 75601, 82801.
- `UPDATE_ACTIVITIES_ONTIME` and `AUCTION_REFRESH_ONTIME` at 18001.
- `UPDATE_SHOP_ONTIME` at 43201, 64801, 75601.
- `AUCTION_REFRESH_ONTIME` at auctionEndTime + 1.

`Task` listens to `UPDATE_MISSION_ONTIME` and loads tasks. `Activities` listens to `UPDATE_ACTIVITIES_ONTIME` and reloads activities. Other shop/auction listeners exist elsewhere in the source tree.

This means a coherent server timestamp affects future API reachability even when the user performs no explicit action.

### New source-confirmed conditional first-scene API: SET_BG

`MainScene:setupBackground()` can call `Library:setLibraryBG()` -> `SET_BG` when a limited library background (`limit == 2`) has a timestamp newer than local `BGCanLoadTime`.
Request shape is `{_type=1, bg_id=<selected id>}`. The caller consumes status only. This is conditional and not boot-critical.

### MainScene first-entry window order

`MainScene:onEnterTransitionFinish()` source order is:
`main_scene_left -> main_scene_middle -> main_scene_bottom -> main_scene_touch -> main_scene_top`.

The left window's first-entry work is local/live2d selection and no direct HTTP request was found in its `willOpen/didOpen`.
The middle window refreshes summon info and redmark state.
The bottom window's `didOpen` calls local hero-equipment/summon checks and mailbox redmark checks; these functions do not themselves issue HTTP.
The top window issues `CHECK_GAME_STAT` with `{}` and no callback.

### Documentation added in Pass 15

- `PASS15_INDEX.md`
- `ACTIVITY_BOOTSTRAP_FANOUT_PASS15.md`
- `SERVER_TIME_RUNTIME_PROTOCOL_PASS15.md`
- `MAINSCENE_WINDOW_ORDER_PASS15.md`
- `api_contracts/pass15_runtime/GET_BOARD_INFO.md`
- `api_contracts/pass15_runtime/LOAD_FRIENDS_server_time.md`
- `api_contracts/pass15_runtime/ACTIVITIES_bootstrap.md`
- `api_contracts/pass15_runtime/SET_BG.md`

### Next mapping priorities

1. Trace every automatic listener of `UPDATE_SHOP_ONTIME`, `AUCTION_REFRESH_ONTIME`, and `UPDATE_MISSION_ONTIME` to enumerate the subsequent API fan-out.
2. Trace all activity-specific `details` consumers because `ACTIVITIES` is now known to be a high-fan-out bootstrap object.
3. Continue mapping first-entry redmark consumers and any API requests they initiate.
4. Continue unresolved/dynamic MID resolution and caller-to-response propagation.
5. Keep source-confirmed, capture-confirmed, inferred, and unknown protocol facts separate.

## Pass 16 — timed-event fan-out and refresh semantics

Read memory first and traced the actual src_64 source for the four ServerTime events.

### Source-confirmed timed graph
- UPDATE_MISSION_ONTIME is emitted at 18001, 43201, 50401, 64801, 72001, 75601, 82801 seconds-of-day.
- Task model listens and calls loadTaskByType(). Normal types issue TASK_LOAD_BY_TYPE with `{mission_type}` unless cached; challenge delegates to BattlePass.loadInfo().
- TaskWindow also listens and forces DAILY task reload through the Task model.
- UPDATE_ACTIVITIES_ONTIME is emitted at 18001 only. Activities listens; if logged in it calls ACTIVITIES `{}`. Its handler consumes `params.list`, performs activity/redmark work, then calls GET_BOARD_INFO.
- UPDATE_SHOP_ONTIME is emitted at 43201/64801/75601. Shop only clears `statuses_`; it does not issue an immediate HTTP request.
- AUCTION_REFRESH_ONTIME is emitted at 18001 and `auctionEndTime + 1`. AuctionRoomWindow listens and calls GET_AUCTION_INFO_BY_TYPE with `auction_type` when the window is open.
- SelfPlayer's APP_ENTER_FOREGROUND_EVENT path separately calls QUERY_SERVER_TIME `{}` and dispatches UPDATE_MISSION_ONTIME when `playerID > 0`.

### Important backend-design consequence
Timed events are not equivalent to timed HTTP endpoints. Some only invalidate local caches; some fan out to one or more APIs; some are window-conditional. The backend should expose correct state so that later model calls succeed rather than inventing unsolicited server pushes.

### Response contracts strengthened
- TASK_LOAD_BY_TYPE: `mission_list`; partner task type is hero-keyed and assigns `hero_id` from the key.
- ACTIVITIES: `params.list`; generic activity fields consumed include `table_id`, `is_open`, `start_time`, `end_time`, `details`.
- GET_BOARD_INFO: `contents[]`, sorted by `notice_id`.
- GET_AUCTION_INFO_BY_TYPE: `auction_list`; auction window consumes `is_done`, `now_buyer`, `now_price`, `item_id`, `currency_type`, `buyer_info`.
- QUERY_SERVER_TIME has no callback at this call site and participates in the normal server-time response side-effect mechanism.

### Explicit non-inferences
- No new numeric MID was invented.
- No assumption that UPDATE_SHOP_ONTIME itself requires a server request.
- No claim that the observed auction fields constitute the complete original server response.

## Pass 17R — recovery from trusted Pass 16 and high-fanout transport/API refinement (2026-08-16)

This pass intentionally ignores the lost/invalid Pass 17 artifact and re-derives findings from the trusted Pass 16 archive plus freshly unpacked `all-assest-rechecked.zip` at `app-assets/output/assets/src_64`.

### Process/state
- Read this `memory.md` before working.
- Audited the Pass 16 documentation tree: 1336 non-cache files, 1323 markdown docs, 1074 per-MID mini-contracts, 98 per-model mini-contracts.
- Preserved the current backend implementation; no semantic handler rewrite was attempted.
- Generated 33 high-fanout mini-contracts in `api_contracts/pass17r_high_fanout/`.

### New source-confirmed transport finding
`SEND_CHAT_MESSAGE` (`32782`) is not ordinary game HTTP despite appearing in many `Backend:request()` call sites. `Backend.request()` routes it to `tcpRequest_()` because `xyd.isChatRoomMessage(32782)` is true under the `bit.band(mid, 36864) == 32768` rule in `mid.lua`. Therefore the Flask rewrite should not spend time adding a normal HTTP handler for `32782`; it should keep HTTP `LOAD_CHAT_ROOM_INFO` (`192`) shape-correct and later implement/stub the TCP chat room protocol.

### High-fanout API design warnings re-derived from source/audit
- `LOAD_SINGLE_ACTIVITY` (`234`) has 11 call sites and is an activity-specific read surface. It needs an `activity_id` keyed registry and common activity envelope; `details` is per-activity.
- `GET_ACTIVITY_REWARD` (`231`) has 8 call sites. Request fields include `activity_id`, `award_id`, and optionally `sub_award_id`; response can include `awards` and `exchange_stone_num`.
- `LOAD_ARENA_FIGHT_RECORDS` (`289`) has 8 call sites across SelfPlayer/MainScene/MessageManager/Arena/Social/Jigsaw consumers and exposes `records`.
- `TAKE_MISSION_AWARD` (`161`) has 6 call sites. It uses `table_id` and sometimes `hero_table_id`; response can include `awards`; model state mutates locally on success.
- `DAILY_CONSUNME_LOAD` (`28`) and `DAILY_CONSUNME` (`29`) are shared daily-counter surfaces, not single-window endpoints.

### New docs added
- `PASS17R_INDEX.md`
- `PASS17R_SOURCE_DERIVED_FINDINGS.md`
- `TRANSPORT_ROUTING_REFINEMENT_PASS17R.md`
- `HIGH_FANOUT_API_PROTOCOL_PASS17R.md`
- `api_contracts/pass17r_high_fanout/*.md`

### Next mapping priority
1. Continue with high-fanout state families: activities/rewards, mission/task, arena/social records, daily counters, market/cart, fight/battle result surfaces.
2. Resolve remaining dynamic/unresolved request expressions, but keep symbolic-only APIs numerically unresolved unless `mid.lua` assigns them.
3. Map TCP chat socket payloads separately from HTTP endpoints.
4. Only after this mapping phase, rewrite the backend around transport routers and canonical state services rather than the current outdated flat skeleton.



## Pass 18 — completion assessment, transport matrix, and window API surface (2026-08-16)

Read before pass: existing `memory.md`, Pass 17R docs, `tools/api_audit.json`, and fresh `app-assets/output/assets/src_64/app/common/network/Backend.lua` + `mid.lua` from `all-assest-rechecked.zip`.

Conclusion: the full codebase/protocol is **not analyzed enough to start the backend rewrite safely**. The current backend structure is still considered outdated and will need to be rewritten, but the rewrite should wait until dynamic/window/high-fanout APIs are classified more completely.

Pass 18 added:
- `PASS18_INDEX.md`
- `PASS18_COMPLETION_ASSESSMENT.md`
- `TRANSPORT_MATRIX_PASS18.md`
- `WINDOW_API_SURFACE_PASS18.md`
- `HIGH_FANOUT_COMPLETION_PASS18.md`
- `DYNAMIC_REQUEST_SITES_PASS18.md`
- `api_contracts/pass18_windows/`
- `api_contracts/pass18_high_fanout/`

Source-derived metrics from this pass:
- Parsed 1210 numeric MID definitions from supplied `mid.lua`.
- Existing audit contains 1345 request records: 922 model, 382 window, 37 scene, 4 common.
- 50 audited records remain dynamic/unresolved.
- 36 MID groups have 3+ audited call sites and need canonical-state handlers, not one-off stubs.
- 18 numeric MIDs satisfy the chat/TCP bitmask. These are not ordinary Flask HTTP game endpoints.
- `Backend:sendAsFormData_()` zlib/form MIDs: ARENA_FIGHT_RESULT=279, PEAK_START_FIGHT=2484, TREASURE_SAVE_BATTLE_RESULT=535, REARENA_END_FIGHT=774, REGION_FIGHT_RESULT=1412, CONQUER_SCHOOL_FIGHT_RESULT=1570, SAVE_FURNITURES=2515.
- `Backend:isUpload()` recognizes upload MID 1844.

Important Pass 18 transport correction/refinement:
- `LOAD_CHAT_ROOM_INFO` (MID 192) is ordinary HTTP discovery and returns `host`, `port`, `room_id`.
- MIDs where `bit.band(mid, 36864) == 32768`, including `SEND_CHAT_MESSAGE=32782`, are TCP/chat-routed by `Backend:request()` and should not be implemented as ordinary `/api/v1` Flask handlers unless deliberately adding diagnostics.
- `Backend:isGMOperation()` exists for `bit.band(mid, 36864) == 36864`; no numeric MID assignments in supplied `mid.lua` matched that exact GM route in this pass.

Window-layer finding:
- The audited window layer has 382 request records across 192 window files. Many are user-interaction or conditional feature paths, but they expose nested response contracts and high-fanout shared APIs. Continue mapping windows before the rewrite.

Next pass recommendation:
1. Resolve `DYNAMIC_REQUEST_SITES_PASS18.md` by opening each source file and tracing local MID variables/tables.
2. Continue window subsystem mapping by domain: arena/battle reports, activity rewards, market/shop, hero wash/skin/summon, chat/social invites.
3. Only after those are classified should the backend be rewritten into transport + canonical `PlayerState` services.


## Pass 19 — dynamic request resolution and rewrite gate (2026-08-16)

Read baseline `memory.md` first, then re-opened the complete `app-assets/output/assets/src_64` tree from `all-assest-rechecked.zip`. This pass continued documentation only; no backend rewrite or semantic handlers were implemented.

Pass 19 added:
- `PASS19_INDEX.md`
- `PASS19_CLIENT_MAPPING_STATUS.md`
- `DYNAMIC_REQUEST_RESOLUTION_PASS19.md`
- `UNDEFINED_MID_SYMBOLS_PASS19.md`
- `FINITE_DYNAMIC_DISPATCH_PASS19.md`
- `DOMAIN_REWRITE_GATE_PASS19.md`
- `api_contracts/pass19_dynamic_resolution/` mini-docs and JSON

Conclusion: the frontend client is **not yet completely mapped** for a full backend rewrite. The boot/first-entry path is strong, but full gameplay/domain coverage still has gaps. Continue mapping rather than rewriting the whole backend.

Important Pass 19 findings:
- Recomputed undefined MID symbols: **26 `xyd.mid.*` names are referenced but not assigned in `mid.lua`**. These include `LOAD_DUNGEON`, `LOAD_MAGIC_SHOP`, `LOAD_MARKET`, `LOAD_RECOMMEND_FRIENDS`, `LOAD_SEND_REQUEST_PLAYERS`, `SEND_SOCIAL`, `CANCEL_REQUEST_FRIEND`, `AWAKE_HERO`, `SET_REP_HERO`, `SET_LOCK_HERO`, `POWERUP_RUNE`, `SELL_RUNES`, several `SINGLE_DAY_*` names, and `START_SAKURA_FIGHT`. Do not invent numeric IDs for them.
- Resolved multiple finite dynamic branches:
  - wash/practice: `GET_PRACTICE_INFO`/`PET_GET_PRACTICE_INFO`, `PRACTICE_SAVE`/`PET_PRACTICE_SAVE`, `WASH_BY_TICKET`/`PET_WASH_BY_TICKET`, `PRACTICE`/`PET_PRACTICE`, `PRACTICE_AUTO`/`PET_PRACTICE_AUTO`; auto-wash consumes `add_attrs[]` and `is_adds[]` in `WashProcessWindow`.
  - arena/rank/records: `query_arena_formation`/`ARENA_MODE_QUERY_FORMATION`, `ARENA_GET_RCORD_PLAYER_INFO`/`ARENA_MODE_RECORD_PLAYER_INFO`, `LOAD_ARENA_FIGHT_REPORT`/`ARENA_MODE_RECORD_DETAIL`, `ARENA_PRE_FIGHT`/`ARENA_MODE_FIGHT_PRE`, `ILLUSION_RANK_HEROS`, `CHAMPIONS_GET_FIGHT_RECORD`.
  - fishing equipment: `ACTIVITY_FISHING_CHANGE_ROD`, `ACTIVITY_FISHING_CHANGE_HOOK`, `ACTIVITY_FISHING_CHANGE_BAIT`.
  - activity map star award: `CHOCOLATE_STAR_AWARD`; sweep path is campaign-type dependent and includes `CHOCOLATE_SWEEP`, `FOURTH_ANNI_MAP_SWEEP`, `POLAR_NIGHT_SWEEP` among others.
- `ChatWindow` has a debug/runtime numeric command path that can call arbitrary numeric MIDs parsed from chat-like input. Treat it as developer/GM/debug behavior, not ordinary gameplay API architecture.
- `PEAK_FIGHT_RESULT` is referenced via `var_0_7.mid.PEAK_FIGHT_RESULT` but remains undefined in supplied `mid.lua`; the call uses special battle/result request flags. It must not be assigned a guessed numeric MID.

Next mapping priority:
1. Continue with activity-specific `details` consumers and `LOAD_SINGLE_ACTIVITY` payload variants.
2. Trace battle/result MIDs and compressed/form-data endpoints.
3. Investigate whether undefined symbolic MIDs have numeric assignments in any downloaded override, capture, or non-Lua native table.
4. Build domain-owned response contracts for practice, arena, activity, social/friends, shop/market, and battle-result before coding the backend rewrite.
