# Stage 4A.9 update — hot-asset client repair + undecoded-request probe

Current stage: **Stage 4A.9 Girls-adjacent progression + EOL client-resource repair**  
Date: 2026-08-17

## User-confirmed results entering Stage 4A.9

- Stage 4A.3 Girls detail remains operational: Aquaris detail, Skin, Affinity, skill upgrades, and diamond skill-point purchase interaction.
- Campaign progression/relog persistence remains operational.
- Backpack persistence, Sweep/Raid Mini Juice rewards, EXP consumables, and persisted Hero leveling remain operational.
- Stage 4A.8 login works on the second launch and advertises the current LAN host dynamically; never restore a baked-in LAN address.
- One first Stage 4A.8 login reached lobby and then showed a loading popup that never disappeared. The same run contained one `/api/v1` request immediately after MID1056 that the backend logged as `source=form-payload decode=undecoded`; the second app launch did not reproduce it.
- Campaign `200002` still stalls on `NewLoadingWindow` after successful MID113 and before MID114.

## Chapter 2 resource status is now proven

The user's Stage 4A.8 static-store build recovered **20,499** current-client catalog entries by exact MD5, with 9,437 still absent from the community captures. For campaign `200002`, `runtime_logs/campaign_asset_summary.json` now reports `required_count=16`, `present=15`, one informational non-lazy sound catalog miss, and **zero unresolved lazy paths**.

All six previously suspected `zhuankuai` lazy resources are present in the backend-local static store with the exact MD5 expected by client 1.631.0:

- `res/web/skeletons/npc/zhuankuai/zhuankuai.atlas`
- `res/web/skeletons/npc/zhuankuai/zhuankuai.json`
- `res/web/skeletons/npc/zhuankuai/zhuankuai.png`
- `res/web/skeletons/npc/zhuankuai/zhuankuaidandao.atlas`
- `res/web/skeletons/npc/zhuankuai/zhuankuaidandao.json`
- `res/web/skeletons/npc/zhuankuai/zhuankuaidandao.png`

The APK still issues zero `/res/` GETs at the jellyfish. Therefore this is no longer a server asset-availability problem. Do not change MID113/MID114 or invent another resource endpoint for this symptom.

## Source-confirmed client-side lazy-state cause

Authoritative `src_64/app/common/AssetDownload.lua` proves `AssetDownload:isFileExist(path)` does not stat the filesystem. It converts the catalog path with `parseXmlPath` and checks `xyd.lazyFileManager` key `__lazy__<parsed-path>`; absence of that key means "present".

Authoritative `src_64/lazyFileManager.lua` loads/saves this map at `xyd.versionUpdatePath .. "lazyFile.json"`. `UpdateScene.lua` also proves the writable preinstalled/recovered physical mapping `res/web/X -> res/X` when validating update-tree files.

Thus copying server files alone cannot clear the wait while the installed client's writable `lazyFile.json` still says those resources are lazy. A valid EOL bypass must both install exact bytes into the writable update tree and remove only the matching lazy keys while the app is stopped.

## New operator-run ADB helper

Stage 4A.9 adds `tools/install_campaign_assets_adb.py`. The backend never invokes ADB automatically. The user may run:

`python3 tools/install_campaign_assets_adb.py --campaign 200002 --dry-run`
`python3 tools/install_campaign_assets_adb.py --campaign 200002`

The helper reads `campaign_asset_summary.json`, selects only lazy-snapshot paths currently resolved as exact-MD5 `present`, re-verifies local MD5s, force-stops the package, backs up device `lazyFile.json`, copies each `res/web/X` to writable `res/X`, removes only the exact `__lazy__res___web___...` keys, writes the patched lazy map, logs the install, and leaves the app stopped. It supports root ADB or Android `run-as`; it refuses to guess privilege escalation.

No dummy/hash spoof is used. The client performs its own MD5 verification and the current blocker is a Spine `.json/.atlas/.png` set, so arbitrary placeholder bytes remain invalid.

## No hard-coded network address

Stage 4A.9 further removes the fixed external route-probe address from host detection. On Linux it reads the default-route interface from `/proc/net/route` and obtains that interface's IPv4 via `SIOCGIFADDR`, with local hostname/address enumeration as fallback. `GXB_ADVERTISE_HOST` remains the explicit override for unusual multi-interface hosts.

## Intermittent first-login loading popup

The exact MID of the Stage 4A.8 undecoded request is unknown. Do not invent it. Stage 4A.9 changes transport decoding so raw request bytes are cached before Flask form parsing and adds zlib/raw-DEFLATE/gzip decode attempts. Any still-undecodable request is captured to `runtime_logs/undecoded_engine_requests.jsonl` with bounded raw payload evidence. Generic OK behavior remains until the MID/consumer is source/live identified.

Player DB schema remains **4**.

## Validation

Stage 4A.9 syntax-only validation PASS: **65 Python files compiled successfully** with `py_compile`. No Flask/HTTP/APK/ADB/emulator/gameplay runtime test was performed by the assistant.

---
# Stage 4A.8 update — automatic LAN host + fixed static asset store

Current stage: **Stage 4A.8 Girls-adjacent progression + EOL static resource restoration**  
Date: 2026-08-17

## Immediate regression entering Stage 4A.8 — login failure

The user's Stage 4A.7 startup log proves a configuration regression unrelated to game-state handlers. Flask bound on the machine's current LAN address `172.20.0.15`, but CENTER discovery still advertised the historical hard-coded `172.20.0.21` in both `SELF_URL` and `res_download_url`. The client therefore had no reachable engine endpoint after center/SDK startup and could not complete normal login.

Stage 4A.8 removes `172.20.0.21` as the default device-facing host. Unless explicitly overridden, startup now derives the current LAN IPv4 address from the host routing table and uses it consistently for:

- engine `SELF_URL`;
- `RES_DOWNLOAD_URL`;
- advertised TCP chat host;
- derived client-log URL.

Optional explicit override for multi-interface hosts is `GXB_ADVERTISE_HOST=<device-reachable-ip>`. Existing explicit `GXB_SELF_URL`, `GXB_CHAT_HOST`, and `GXB_RES_DOWNLOAD_URL` overrides remain supported.

This diagnosis is user-log-confirmed; actual Stage 4A.8 login remains to be user-runtime-tested.

## Resource deployment simplified

The user prefers deterministic server-local assets rather than exporting a community archive parent on every run. Normal Stage 4A.8 deployment therefore uses the fixed backend-local store:

`<backend>/local_assets/res/`

No `GXB_ASSET_ROOT` export is required. The gateway accepts both current and legacy extracted layouts under that fixed store:

- `local_assets/res/web/X`
- `local_assets/res/X`

The existing current-client catalog/MD5 remains authoritative; same-name old APK files are not accepted unless their bytes match the expected MD5. If the local static store is absent/unusable, startup prints an explicit warning and the gateway remains audit/log-only. Environment root discovery is retained only as an optional diagnostic/backwards-compatibility override.

New helper: `tools/build_static_asset_store.py`. It discovers extracted `res` directories under one or more community archive parents, checks exact current/legacy catalog candidates, hashes only candidates that actually exist, accepts only exact expected MD5 matches, and builds normalized `local_assets/res/web/...`. Default placement hard-links where possible and falls back to copying; `--mode copy` and `--mode symlink` are supported. It writes `local_assets/static_asset_build_summary.json`.

The user can also bypass the helper and manually copy a preferred `res` tree into `local_assets/res`; runtime MD5 validation remains in effect.

## Chapter 2 status entering this pass

Chapter-2 campaign `200002` still stalls on the jellyfish/NewLoadingWindow after successful MID113. Stage 4A.7 proved the previous multi-root discovery itself was not limited to one tree; the older capture's `res/skeletons/...` layout required the `res/web/X -> res/X` alias. The user's current note confirms the six `zhuankuai` files physically exist in the older capture. Stage 4A.8 does not claim the jellyfish fixed yet because Stage 4A.7 could not reach gameplay after the stale-host login regression.

Next user test should first confirm login with the automatically advertised current LAN host, then retry `200002` using the fixed local asset store and inspect `runtime_logs/campaign_asset_summary.json` for `present` versus `md5_mismatch`.

## Existing confirmed gameplay retained

- Stage 4A.3 Girls detail: Aquaris detail, Skin, Affinity, skill upgrades, diamond MID99 purchases.
- Campaign progression and relog persistence.
- Backpack persistence.
- Sweep/Raid source-defined Mini Juice rewards.
- EXP consumable use and persisted Hero leveling.
- Guide-function completion persistence.
- Conservative first-clear Campaign item awards.

Player DB schema remains **4**.

## Validation

Stage 4A.8 syntax-only validation PASS: **63 Python files compiled successfully** using `py_compile`. No Flask/HTTP/APK/ADB/emulator/gameplay runtime test was performed by the assistant.

---
# Stage 4A.7 update — legacy res alias + MID90 stability fallback

Current stage: **Stage 4A.7 Girls-adjacent progression + EOL resource recovery**  
Date: 2026-08-16

## User-confirmed results entering Stage 4A.7

- Stage 4A.3 Girls detail remains operational: Aquaris detail, Skin, Affinity, skill upgrades, and diamond MID99 skill-point purchases work.
- Campaign progression/relog persistence remains operational.
- Stage 4A.6 Backpack + Sweep + EXP consumable path is now user-confirmed: Sweep granted Mini Juice, MID63 bulk EXP use worked, and the next bootstrap showed Aquaris at level 30 with persisted cumulative EXP.
- Chapter 2 campaign `200002` still stalls on the jellyfish/NewLoadingWindow after successful MID113 and before MID114.

## Resource resolver bug proven by Stage 4A.6 logs

Startup discovery was **not** stopping after one resource tree. It found both extracted roots under the configured community archive parent, including the older `gxb_v1.164.0-assets/.../res` tree and the newer `gxb_new_data_2/.../res` tree, plus ZIP/APK containers.

The false missing result came from layout normalization. Current metadata asks for `res/web/skeletons/npc/zhuankuai/...`, but the user proved the older capture stores those files at `res/skeletons/npc/zhuankuai/...`. Stage 4A.6 only generated `<res>/web/...` candidates, so the six files were reported `local_file_missing` despite existing in the old capture.

Stage 4A.7 adds a legacy alias for both filesystem and ZIP/APK lookup:

`res/web/X` -> `res/X`

MD5 verification remains mandatory and chooses whether an old copy is actually compatible. A same-name old file with the wrong bytes is logged as `md5_mismatch` and later roots are still tried.

The supplied Stage 4A.6 run still contained zero `/res/` GETs from the APK, so even a newly `present` audit result does not yet prove the native downloader will pull it. Fix the false-negative resolver first; if exact-MD5 assets are found but the jellyfish remains with no GET, continue with the pre-download/client-side FileDownloader state rather than inventing another MID.

## MID90 live regression

Stage 4A.6 changed MID90 `USE_SKILL_POINT_ITEM` to persist the item and return the cross-cutting response `economy_={skill_point=...}`. Live evidence shows the request received `error_code=0`, then the client remained on a loading icon and issued no further meaningful request. `Backend:webRequest_()` runs `extraWebResponseCheck_()` before removing its loading proxy, so an exception in the global ECONOMY side-effect path is consistent with that symptom.

The direct source callback in `SelfPlayer:useSkillPointItem()` consumes no MID90 response fields. No official/live MID90 capture proves the `economy_` envelope for this endpoint. Stage 4A.7 therefore removes that unproven global event from MID90 while keeping the source-defined +10-per-item mutation and canonical Backpack consumption. It returns a diagnostic/current `skill_point` scalar; persistence is authoritative and will hydrate on relog. Immediate in-session MID90 UI synchronization is not claimed solved.

Diamond MID99 purchase behavior remains unchanged.

## Other supplied-log lead

The rapid-window-switch run recorded one fallback gap, MID1829 `GET_PLAYER_CARD_INFO`, returning bare success. That run ended with mostly hidden lobby UI. This is a plausible accidental-click lead, but player-card/profile reconstruction remains outside the present pass.

## Schema and validation

Player DB schema remains **4**; no migration is required from Stage 4A.6.

Stage 4A.7 syntax-only validation PASS: **62 Python files compiled successfully**. No Flask/HTTP/APK/ADB/emulator runtime testing was performed by the assistant.

# Stage 4A.5 update — resource discovery + Backpack rewards + guide persistence

Current stage: **Stage 4A.5 Girls-adjacent state completion + EOL Campaign resource diagnostics**  
Date: 2026-08-16

## User-confirmed state entering Stage 4A.5

- Stage 4A.3 Girls detail is now user-confirmed operational: Aquaris detail, Skin tab, Affinity tab, skill upgrades, and the diamond/skill-point purchase interaction all work.
- Normal Campaign Chapter 1 progression and relog persistence remain user-confirmed operational.
- The next blocker is Campaign Chapter 2: MID2768 succeeds, MID113 succeeds for campaign `200002`, then the client remains on the jellyfish/NewLoadingWindow and never sends MID114.
- Workplace/building errors remain explicitly out of scope for this pass.

## Latest Stage 4A.4 debug evidence — no resource HTTP GET

The user ran Stage 4A.4 with two explicit asset roots. Startup showed the resource catalog and advertised:

`RES_DOWNLOAD_URL = http://172.20.0.21:9000/res/`

Center discovery returned that URL, but the supplied `server.txt` contains **zero `/res/` HTTP GETs** before/while campaign `200002` stalls. Therefore the current jellyfish happens before the native FileDownloader reaches Flask. The HTTP resource gateway remains useful, but request logging alone cannot diagnose this particular pre-download wait.

Source-derived dependency comparison using the supplied `version.json` + `lazyFile.json` shows:

- campaign `200001` / fight `20001`: zero dependencies marked lazy in this snapshot;
- campaign `200002` / fight `20002`: exactly six lazy-marked dependencies, all in the `zhuankuai` Spine set:
  - `res/web/skeletons/npc/zhuankuai/zhuankuai.atlas` — `e9c325a375378bf69fcedfd7e1b5f684`
  - `res/web/skeletons/npc/zhuankuai/zhuankuai.json` — `283db29154ad6479d3c9d513f2d0e6f3`
  - `res/web/skeletons/npc/zhuankuai/zhuankuai.png` — `87d6ffe66a54dfd41f7996e2ff47e1c7`
  - `res/web/skeletons/npc/zhuankuai/zhuankuaidandao.atlas` — `6dce446cc828e3c6b3373511c371189b`
  - `res/web/skeletons/npc/zhuankuai/zhuankuaidandao.json` — `93d40485345509bfb54f6a192967fe1e`
  - `res/web/skeletons/npc/zhuankuai/zhuankuaidandao.png` — `4f35a8084831a5896b06be2d747fb143`

These are current blocker candidates, not yet user-runtime-confirmed missing files.

## Recursive multi-archive `res` discovery

Stage 4A.4 supported multiple **explicit** roots through `GXB_ASSET_ROOTS`. Stage 4A.5 adds parent-archive discovery so the user can point once at a tree such as:

`GXB_ASSET_ROOT=/home/akm/Miscallaneus/recovery/gxb/gxb-assets/zips`

Behavior:

- breadth-first walk of directory names only, max depth `GXB_ASSET_DISCOVERY_DEPTH` (default 10);
- a child named exactly `res` is recorded as an effective resource root;
- once a direct `res` child is found, that parent subtree is pruned so sibling `src_32/src_64` trees are not crawled;
- resource files inside `res` are never enumerated/indexed/hashed at startup;
- exact catalog paths are checked lazily only when requested or audited;
- multiple discovered `res` roots are tried, and an MD5 mismatch in one root does not prevent trying later roots.

Startup writes `runtime_logs/resource_root_discovery.json`. If no asset root is configured, startup explicitly warns and remains catalog/audit/log-only.

## MID113 Campaign asset auditor

Because the client can stall before issuing `/res/` GETs, Stage 4A.5 adds `CampaignAssetAuditor`. On every MID113 it uses `data/campaign_asset_requirements.json` (917 source-derived normal-Campaign rows) plus the shared ResourceGateway to check source-derived enemy-model/map/audio paths against all configured/discovered archives.

Logs:

- `runtime_logs/campaign_asset_requirements.jsonl`
- `runtime_logs/campaign_asset_summary.json`

Only paths marked lazy by the supplied snapshot are classified as `unresolved_lazy`; non-lazy/catalog-miss paths remain informational because they may be force-packed/local resources.

## Dummy/hash-spoof rule

Pure server-side hash spoofing is not a viable fallback. `AssetDownload` computes the MD5 of downloaded bytes locally and compares it to the client's own expected MD5. Disabling server-side MD5 verification cannot bypass that check, and generating arbitrary placeholder bytes for a chosen 128-bit MD5 is not practical.

A future placeholder mode would require a controlled client metadata/validation patch **and** format-valid placeholder assets. The current six candidates are a Spine `.json/.atlas/.png` set, so a generic 1x1 PNG would not be a coherent replacement anyway. Do not silently dummy lazy resources.

## Guide-function persistence — source-confirmed shape fix

The repeated forced-click guide after restart is explained by a real wire/state-shape bug. Authoritative `xyd.checkFirstInGuide(window_name)` converts the guide ID with `tostring(id)` and indexes `SelfPlayer.guideFuncList[string_id]`. Therefore MID17/MID2865 `guide_function_ids` must behave as a string-keyed map such as:

`{"13":1}`

Stage 4A.4 persisted a list such as `[13]`, so after relog `guideFuncList["13"]` was nil and the one-time guide appeared again.

Stage 4A.5:

- changes canonical `PlayerState.guide_function_ids` to `dict[str,int]`;
- automatically migrates legacy lists (`[13] -> {"13":1}`) when JSON is loaded;
- MID2865 writes the string-keyed completion map;
- applies generically to these function-guide overlays rather than hard-coding Pet/Skin.

MID26 Story persistence remains unchanged.

## Canonical InventoryRepository + conservative first-clear Campaign items

New `InventoryRepository` owns ordinary Backpack stacks. Canonical Backpack rows remain source-consumed:

`table_id`, `item_num`, `time`

MID81 bootstrap/direct load now serialize from that repository.

Authoritative `BattleCreate` consumes MID114 `items` rows as `item_id` + `item_num` and immediately adds them to the client Backpack. Stage 4A.5 mutates the same canonical server Backpack when committing those awards, so MID114, MID81, JSON persistence, and relog share one state graph.

`data/campaign_reward_meta.json` is derived from authoritative `campaign.lua` + `campaign_dropbox.lua` for all 917 Campaign rows. Current intentionally conservative reward policy:

- first-clear only;
- only source `init_dropbox` rows with `increase_rate == 10000`;
- source item IDs only;
- `campaign_dropbox.lua` has no quantity column, so **one item per selected drop row is an explicit structural inference**, not a source-confirmed quantity rule;
- lower-rate rows (including Chapter 2's 8000 rows) are retained in metadata but are not rolled until RNG semantics are source/live verified;
- MID113 stages eligible guaranteed first-clear rows only for an already-unlocked star-0 campaign;
- successful first MID114 commit adds those rows to InventoryRepository and returns the same award shape;
- replaying an already-cleared stage does not re-grant first-clear items.

No retroactive reward migration is applied to previously cleared stages. To test the reward path, use a fresh/unbeaten Campaign row.

Still deliberately incomplete:

- regular/lower-rate Campaign RNG;
- mana/EXP Campaign economy gains;
- energy consumption;
- Sweep rewards/accounting.

## Player DB schema

Schema is now **4**. Existing Stage 4A.4/4A.3 JSON is accepted and normalized. New first-class conventions in this schema are the string-keyed guide completion map and canonical normalized Backpack stacks.

## Validation status

Stage 4A.5 syntax-only validation PASS: **61 Python files compiled successfully**.

No Flask/HTTP/APK/ADB/emulator/gameplay runtime test was performed by the assistant.

---
# Stage 4A.4 update — EOL lazy-resource gateway

Current stage: **Stage 4A.4 cross-cutting resource restoration while preserving Stage 4A Girls state**  
Date: 2026-08-16

## User-confirmed results entering this pass

- Stage 4A.3 Aquaris detail is operational.
- Skin tab works.
- Affinity tab works.
- Skill-up interaction works.
- The diamond/skill-point purchase interaction is user-confirmed working at the UI/gameplay level. Do not reinterpret that as proof that every crystal economy debit is canonical until state/accounting is separately verified.
- Normal Campaign Chapter 1 progression and relog persistence are user-confirmed operational.
- Chapter 2 Start reaches the jellyfish `NewLoadingWindow`. Debug evidence shows MID2768 then successful MID113 for campaign `200002`, followed by no MID114; there is no new relevant unknown/fallback game MID at the stall.

## Authoritative client resource pipeline

The supplied complete `src_64` confirms:

1. `UpdateScene_64.lua` receives center-discovery `res_download_url` and assigns `xyd.resDownloadUrl`.
2. `version.json` is used to populate `lazyFile.json` for non-force resources that are absent or fail local MD5 verification.
3. `AssetDownload:isFileExist()` treats a matching `__lazy__...` metadata entry as a missing resource.
4. `AssetDownload:getDownloadInfo_()` constructs the HTTP URL as:

   `xyd.resDownloadUrl .. basename .. "." .. expected_md5`

   The original resource directory is NOT sent in the URL.
5. Downloaded bytes go to `<original path>.asset_tmp`.
6. The client requires `MD5File(temp) == expected_md5` before installing the file and deleting the lazy entry. Failure or mismatch is requeued.
7. `preloadBattleInfos()` uses this path before removing `NewLoadingWindow` and entering the battle scene.

Therefore Chapter 2 can stall after MID113 even though the backend battle API is correct.

## Supplied runtime metadata

User supplied `.revision`, `.download_infos`, `version.json`, and `lazyFile.json`. Observed metadata:

- `.revision = 267088`
- `version.json`: 43,764 rows
- 29,936 `res/web/...` resource rows with real MD5 values
- `lazyFile.json`: 10,014 current lazy/missing entries
- `.download_infos`: empty plist in the supplied snapshot

Stage 4A.4 packages a normalized metadata-only catalog:

`data/resource_catalog/resource_catalog.json`

It contains 29,936 entries derived from the supplied version catalog plus lazy snapshot flags. No 1.5 GB resource payload is bundled.

## Stage 4A.4 backend resource gateway

New/changed behavior:

- resource service is advertised by center discovery by default;
- default URL is the backend `/res/` prefix derived from `GXB_SELF_URL`;
- request form `basename.md5` is reverse-mapped to original catalog path(s);
- local resources are checked lazily only for the exact requested catalog entry;
- configured roots support a directory containing `res/`, direct `res/`, or direct `res/web/`;
- matching files are MD5-verified before serving;
- successful files are streamed via Flask `send_file`;
- missing/catalog-miss/mismatch requests return 404 and are logged;
- no full-tree startup scan or hashing is performed.

Configure a large local tree with:

`GXB_ASSET_ROOT=/path/to/assets`

or multiple Linux roots:

`GXB_ASSET_ROOTS=/path/one:/path/two`

Optional zero-config local names are `./asset_store`, `./assets`, and `./res` when they exist. A symlink is sufficient.

Logs:

- `runtime_logs/resource_requests.jsonl`
- `runtime_logs/resource_gateway_summary.json`

Statuses include:

- `served`
- `catalog_miss`
- `asset_roots_unconfigured`
- `local_file_missing`
- `md5_mismatch`

Repeated retries are de-duplicated while the summary tracks counts. Because lookup happens on every retry, a missing file can be copied/symlinked into the configured root while backend/client remain running; the next retry can serve it if MD5 matches.

## Dummy-resource rule

Do NOT silently serve arbitrary dummy images/files for this lazy-download path. The source client MD5-verifies every downloaded lazy resource. A dummy has the wrong hash and will be requeued forever.

A future placeholder mode would require an explicit client patch or controlled expected-metadata rewrite to the dummy's MD5, with format-specific placeholders. That is separate work.

## Catalog maintenance

`tools/build_resource_catalog.py` rebuilds the metadata-only catalog from a local `version.json` and optional `lazyFile.json` without scanning the large asset tree.

## Validation status

Stage 4A.4 syntax-only validation PASS: **59 Python files compiled successfully**.

No Flask/HTTP/APK/ADB/emulator/gameplay runtime test was performed by the assistant.

---
# Stage 4A.3 update — Girls Skin-tab + canonical skill synchronization

Current stage: **Stage 4A.3 Girls detail stabilization**  
Date: 2026-08-16

## User-confirmed results entering this pass

- Stage 4A.2 fixed the Aquaris detail-window open failure; owned Aquaris now opens normally.
- Skin tab still appears to do nothing.
- MID99 BUY_SKILL_POINT was observed three times with Stage 4A.2 compatibility-only bare success, so purchased points did not enter canonical player state.
- MID39 SET_ALL_SKILL_LEVEL was observed repeatedly with Stage 4A.2 bare success, so upgraded skills did not enter canonical hero state.
- Stage 4A.2 Campaign persistence is now **USER-CONFIRMED OPERATIONAL**. Repeated MID113/MID114 clears advanced along source-derived links through at least `100001 -> 100002 -> 100004 -> 100005 -> 100007 -> 100008 -> 100011 -> 100012` during the supplied session.
- Workplace/building errors reported later in that log are explicitly out of scope for this pass.

## Skin-tab source diagnosis and fix

Stage 4A.2 emitted `illusion_skin_id=-1` for Aquaris. `NormalHero:populate_()` stores it directly.

On first Skin click, `HeroMainWindow:clickSkinButton()` enables the Skin cache and calls `updateEquipInfoContainer()`. That function treats values `<=1` as a selector and computes:

`skinSelect = illusionSkinId_ + 1`.

Therefore `-1` becomes selector `0`; later the function reads `skinDatas[skinIllusionEquip].modelID`, so it can dereference `skinDatas[0]` and die synchronously without a network request.

Stage 4A.3 normalizes absent/negative compatibility illusion values to `0`, the source normal-card selector for an ordinary/non-awakened hero. Packaged Aquaris now has `illusion_skin_id=0`.

No skin IDs are invented. Actual skin acquisition/equip semantics remain later work.

## Canonical skill-point and skill-level state

MID99 BUY_SKILL_POINT source callback consumes `buy_skill_times`, `skill_point`, and `skill_time`. The client translation `SKILL_POINT_BUY` explicitly says each purchase grants 10 skill points. Stage 4A.3 persists and returns those fields.

MID39 SET_ALL_SKILL_LEVEL is no longer status-only. HeroMain sends `partner_id`, pipe/int `skill_colors`, and pipe/int `skill_counts`; its callback consumes the full pipe-serialized `skills` vector plus `skill_point` and `skill_time`. Stage 4A.3 routes the mutation through `HeroRepository`, updates the canonical six-slot hero `skills`, deducts canonical skill points when sufficient, saves atomically, and returns the fields HeroMain consumes.

MID53 SET_SKILL_LEVEL is routed through the same state owner for the older single-index path.

Deliberate limit: Stage 4A.3 does **not** yet persist the crystal cost of MID99 or mana cost of skill upgrades. Those economy mutations remain part of the later full Hero/Economy progression pass rather than being half-wired without a proven response-sync contract.

## Campaign status promotion

Stage 4A.2 Campaign world synchronization is no longer "awaiting runtime confirmation". It is user-confirmed working for repeated normal Campaign clears and source-linked unlock persistence.

Still incomplete:

- campaign rewards/drop tables;
- energy accounting;
- sweep currency/ticket accounting;
- stronger MID113/MID114 eligibility/session validation.

These do not block the current Stage 4A Girls pass.

## Aquaris star evidence correction

Earlier memory described owned Aquaris `table_id=10001001` as "source-confirmed initial star 3". Corrected evidence classification:

- authoritative `src_64/data/tables/partner.lua` row `10001001` is Aquaris;
- its `ini_star` is 1, not 3;
- the current backend profile still carries star=3;
- without a located official capture proving that upgraded state, star=3 is **current-profile / unknown provenance**, not source-confirmed initial star.

Do not silently change the user's current star=3 profile merely to match table initial-star data.

## Validation status

Stage 4A.3 was checked with Python syntax compilation only: **57 Python files PASS**.
No assistant-side Flask/API/HTTP/APK/ADB/emulator/gameplay runtime test was performed.

---
# Stage 4A.2 update — HeroMain element slots + persistent Campaign world state

Current stage: **Stage 4A.2 hero/campaign synchronization**  
Date: 2026-08-16

## User-confirmed results entering this pass

- Stage 3 remains the first major milestone: stable login/server picker/lobby/HUD/core navigation.
- Stage 4A is confirmed: Girls/HeroListWindow opens correctly with owned Aquaris.
- Stage 4A.1 did **not** fix owned-girl detail: first Aquaris tap appears to do nothing; second tap hides/freezes the visible UI.
- Both taps emit MID234 activity 1032 and then no further hero-specific request.
- Normal single-player Campaign battle `100001` runs and completes client-side using formation `10001`.
- MID114 currently returns stateless success, so the clear does not persist and the next campaign does not unlock.
- Raid/Sweep was exposed before the first real clear because the old world seed incorrectly advertised `100001 star=3`; MID117 then returned an invalid shallow response and SweepWindow appeared blank.
- MID2768 GET_RENT_HEROS was still compatibility fallback during team selection.

## HeroMain first/second tap diagnosis

`HeroListCell` sends MID234 for HalfPriceSkill then immediately opens `hero_main`; MID234 does not gate the open callback.

`WindowManager:openWindow()` registers the newly constructed window in `windows_` before `loadRes()/willOpen()/layout()` complete. Therefore a synchronous first-open exception can leave an invisible half-open HeroMain registered. A second tap finds that registered window and can apply background/hide-window state even though the first open never became visible. This matches the observed first tap no-op / second tap UI disappearance.

### Source-confirmed element-equipment nil hazard

`HeroMainWindow:layout()` calls `updateElementEquip()` before `didOpen()`.

The guard in supplied Lua is:

```lua
if not xyd.isSuperHero(hero) and not hero:getColor() == xyd.MAX_HERO_COLOR then
    return
end
```

Because of Lua precedence it does not reliably exclude ordinary Aquaris. `NormalHero:populate_()` stores `element_equips` directly. Stage4A/4A.1 sent `[]`. Empty Lua tables are truthy, while `elementEquips[i]` is nil; `nil ~= 0` is true, so HeroMain can execute `tonumber(nil)` and pass nil into element-equip table lookup.

`xyd.MAX_ELEMENT_ITEM_NUM` is source-confirmed as 4. Stage4A.2 normalizes:

```json
"element_equips": [0,0,0,0],
"element_levels": [0,0,0,0]
```

No element item IDs are invented.

If HeroMain still fails, use `tools/adb_stage4a2_hero_probe.sh` after reproducing it. It pulls `log.db` plus targeted hot HeroMain Lua/CSB/effect files. Release logcat remains a poor Lua-crash source.

## Campaign architecture confirmed by live run + source

Normal Campaign combat is client-simulated. Live sequence:

`MID112 -> MID2768 -> MID113 -> local battle -> MID114`.

MID113 only needs to establish authoritative session/start state; SelectTeamWindow consumes optional `items` and builds enemies from local tables. MID114 is the authoritative commit boundary for stars/unlocks/rewards.

New `WorldRepository` owns:

- persisted `world_map`;
- `active_campaign_battle` MID113 session;
- MID114 best-star/update/unlock commit;
- source-shaped MID117 sweep state;
- packaged source campaign links via `data/campaign_meta.json`.

`data/campaign_meta.json` is extracted from authoritative `src_64/data/tables/campaign.lua`, 917 rows, fields only `campaign_id/chapter/next_campaign_id/last_campaign_id`. First chain is `100001 -> 100002 -> 100004`; never guess `+1`.

Player DB schema is now **3**, with:

```text
player.world.world_map
player.world.active_campaign_battle
```

Existing request-scoped RLock + atomic JSON save gives MID113/MID114 the same refresh -> mutate -> save coherence already used by HeroRepository.

## Initial Campaign correction

Fresh state is now accessible-but-unbeaten:

- 100001 star=0
- normal_campaign_id=100001
- normal_stars=0

After a successful 100001 / star=3 MID114, backend persists/returns:

- 100001 star3
- newly unlocked source-next 100002 star0
- chapter_info cursor to 100002
- updated chapter stars
- items=[] until reward/drop contracts are implemented.

Only a newly created next row is returned as star0; replaying an older cleared campaign must not repeatedly trigger the client's new-campaign animation.

## Sweep/Raid MID117

`SweepWindow` consumes `items`, `economys`, `additional`, and `campaign`. Stage4A.2 returns those exact containers. Empty reward economy entries are explicit `{exp:0,mana:0}` because SweepWindow otherwise defaults omitted EXP to 12 client-side. No fake reward XP/mana is introduced.

## Empty rental MID2768

Source-consumed empty shape now includes:

- `guild_rent_heroes.partners=[]`
- `guild_rent_heroes.rent_type`
- `guild_rent_heroes.rent_count=0`
- `tutor_rent_heroes=[]`
- root `rent_count=0`

## Deliberate Stage4A.2 non-goals

- no campaign drop rewards yet;
- no energy/sweep-ticket/crystal accounting yet;
- no hero level/skill/evolution semantics yet;
- no server-side normal Campaign combat simulation;
- no payment.

## Validation rule

Only `python -m py_compile`. **Stage 4A.2 validation PASS — 57 Python files compiled.** No Flask/HTTP/APK/ADB/emulator runtime test by assistant. User performs runtime testing.

---
# Stage 4A.1 update — Aquaris detail-window dependency fix

Current stage: **Stage 4A.1 hero detail hotfix**  
Date: 2026-08-16

## User-confirmed Stage 4A result

- Girls/HeroListWindow now opens correctly.
- Owned Aquaris is visible/selectable in the list.
- Pressing Aquaris freezes/bugs the client.
- The live server log shows MID234 `LOAD_SINGLE_ACTIVITY` with `activity_id=1032` at each click and Stage 4A replies only `{"details":{}}`.

## Source-confirmed MID234 crash path

`HeroListCell` sends `LOAD_SINGLE_ACTIVITY` for `xyd.Activities.HalfPriceSkill` (1032) immediately before opening `hero_main`.

`Activities:onLoadSingleActivity_()` inserts the successful response object into `activities`. Stage 4A boot MID229 is empty, so `#activities == 0`; because the old MID234 response has no `table_id`, no existing row can be replaced and the client can attempt `table.insert(activities, 0, response)`. After insertion, `checkHalfPriceOpen()` also requires numeric `start_time` / `end_time`.

Stage 4A.1 therefore guarantees an inactive 1032 common envelope in MID229 and MID234: `table_id`, `is_open=0`, `start_time=0`, `end_time=0`, `days=0`, `details={}`. This is an inactive compatibility row, not historical event truth.

## Source-confirmed HeroMain scalar hazard

`NormalHero:populate_()` leaves absent house fields nil. `HeroMainWindow:updateFuncBtn()` evaluates `hero:getHouseInfo().house_id > 0`; Stage 4A Aquaris omitted `house_id`. Stage 4A.1 HeroRepository now normalizes explicit non-dorm/default values for house/favor/marriage/dynamic-card/collection-stage fields.

No new hero IDs, activity rewards, or gameplay mechanics are introduced.

## Validation rule

Only `python -m py_compile`. **Stage 4A.1 validation PASS — 56 Python files compiled.** No Flask/HTTP/APK/ADB/emulator runtime tests. User performs runtime testing.

---
# Stage 4A update — canonical Girls/Hero state + request-scoped JSON sync

Current stage: **Stage 4A hero foundation**  
Date: 2026-08-16

## User-confirmed Stage 3 milestone

Stage 3.1.7 is the first major playable-shell milestone. User confirmed:

- anonymous login works;
- server-switch/RegionWindow works;
- stable lobby no longer hides/disappears;
- top economy HUD renders;
- bottom navigation is live;
- Backpack and Chat work;
- MID176 `LOAD_FRIENDS` and MID2754 `CHECK_GAME_STAT` are present.

Stage 3 is considered complete. Subsequent work is gameplay-domain vertical slices.

## Stage 4 dependency order

1. 4A Girls/Hero canonical state.
2. 4B formation + Campaign team selection / MID2768.
3. 4C Campaign fight MID113 -> client-local simulation -> MID114 progression/reward persistence.
4. Hero progression/equipment.
5. Arena.
6. Summon/shop.
7. Activities/Voyage later.

Payment remains permanently out of scope.

## Source-confirmed Girls failure path

The current bootstrap already contains one owned hero in MID49:

- partner/local entity ID `10001`
- source table ID `10001001`
- Aquaris
- star 3
- level 20

`data/tables/partner.lua` contains source row `10001001` for Aquaris with initial star 3. Do not invent additional tutorial girls without source/capture evidence.

Pressing Girls does **not** necessarily send MID49. `MainSceneBottomWindow` calls `SelfPlayer:loadHeros()`, but login bootstrap has already set `herosLoaded_=true`, so `Player:loadHeros()` can call success locally and immediately open `hero_list`.

`HeroListWindow.ctor()` runs before layout and calls:

```lua
self.teams = selfPlayer:getSaveTeams()
```

`SelfPlayer:getSaveTeams()` parses MID17/player fields `save_team`, `save_team_name`, `save_pet` with `xyd.split` / `string.split`. Stage 3 stored these as JSON objects `{}`. Their real client contract is serialized strings. Passing `{}` can synchronously abort HeroListWindow without any new network request.

Stage 4A canonical empty values:

```json
"save_team": "",
"save_team_name": "",
"save_pet": ""
```

The DB loader migrates legacy non-string values automatically and rewrites the JSON atomically.

## Stage 4A HeroRepository

New `gxb_backend/state/hero_repository.py` owns hero-related state.

Responsibilities:

- normalize legacy/current hero JSON to Lua-facing shapes;
- keep `partner_id`, `table_id`, owner `player_id`, collection state and local allocator coherent;
- normalize six-slot skill/equip/fumo arrays and source-consumed optional fields;
- persist hero-list sort type;
- persist serialized preset-team strings;
- persist board/poster selection;
- provide `add_owned_hero()` as the future summon/reward acquisition primitive;
- never invent missing `table_id`, `partner_id`, or star values.

Future summon/reward/battle paths must mutate canonical state through HeroRepository instead of returning isolated MID49 blobs.

Final Stage 4A hardening:

- `add_owned_hero()` allocates around occupied local partner IDs and refuses to overwrite an existing explicit `partner_id`; intentional mutations use `update_owned_hero()`.
- MID835 board state mirrors the client's same-request set/reset behavior: re-sending the active partner/card/model clears the board and returns `board_partner=0`.
- collected-hero serialization is deterministic for easier log/diff comparison.

## Exact Stage 4A hero contracts

- MID49 `LOAD_HEROS`: `sort_type`, `heros` direct partner-id -> hero-record map.
- MID65 `LOAD_COLLECTED_HEROS`: `{"list":[table_ids...]}`.
- MID67 `LOAD_HERO_PIECES`: callback iterates response itself as table-id -> count map. Old Stage3 `{pieces:[],list:[]}` wrapper was wrong.
- MID89 `SAVA_SORT_TYPE`: request `sort_type`; no response fields consumed; now persisted.
- MID1793 `SAVE_TEAM`: request carries `team_str`, `team_name_str` and may omit `pet_str`; absent fields are preserved. Response consumes exact `save_team`, `save_team_name`, `save_pet`; now persisted.
- MID835 `SET_BOARD_HERO`: request `partner_id`, `card_status`, `board_model_id`; detail callback consumes `board_partner`, `board_card`, `board_model_id`; now persisted. Board/poster hero is kept separate from `formation.rep_partner_id`.
- `SET_LOCK_HERO` and `SET_REP_HERO` remain symbolic/unresolved numeric MIDs; do not wire guessed values.

## JSON save/sync boundary

Stage 3.1 used atomic file replacement but request handling only locked individual `refresh()`/`save()` calls. With threaded Flask, another request could refresh/replace `PlayerState` between a mutation and save.

Stage 4A adds `StateRepository.request_scope()` using the existing `RLock`. Engine and SDK stateful requests now keep refresh -> handler -> response on one coherent state snapshot; nested `save()` remains re-entrant. This is intentionally simpler than introducing SQL while gameplay schemas are still changing.

The human-editable DB remains `data/player_db.json`, schema version 2. Unknown/new PlayerState fields continue to persist under `player.domains`, so the JSON structure remains forward-expandable.

## Stage 4A deliberate non-goals

Do not implement in this stage:

- semantic summon reward grants;
- hero powerup/evolve/equipment mutations;
- battle formation semantics;
- campaign result/reward progression;
- Arena/Peak Arena;
- Activities/Voyage;
- payment.

## Next APK test

1. Stable Stage 3 lobby must remain intact.
2. Press Girls. A new MID49 is not required after bootstrap.
3. Hero list should open with owned Aquaris plus client-table-driven uncollected entries.
4. Sort/filter can exercise MID89.
5. Preset save can exercise MID1793 and must survive relog.
6. If list opens but individual girl detail freezes/spins, capture that click's server log and trace the hero-detail window separately; do not widen Stage4A blindly.

## Validation rule

Only run `python -m py_compile`. Stage 4A final validation: **PASS — 56 Python files compiled**. No Flask/HTTP/APK/ADB/emulator runtime test. User performs runtime testing.

Planned Stage 4A handoff artifact:

`gxb-backend-stage4a-hero-foundation-2026-08-16.zip`

---
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
- Added source-valid starter hero: local `partner_id=10001`, source `table_id=10001001` (Aquaris). Historical Stage 3 text originally called star=3 the source initial star; later authoritative re-check corrected `ini_star` to 1. The current profile star=3 is preserved as unknown-provenance profile state.
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
