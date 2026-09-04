# GXB resource / download protocol reverse-engineering map

Backend research version: **v0.6.4-skill-regen-hotupdate-probe**  
Stable gameplay baseline: **v0.6 stable core**  
Date: 2026-08-17

This document separates source-confirmed behavior, user-runtime-confirmed behavior,
inference, and currently unknown native behavior. It is intentionally not a generic
"asset server" design: it maps what this specific 1.631.0 client actually does.

## v0.6.1 runtime result — per-file CDN path confirmed

The user rebuilt the APK with the packaged Lua-only probe and reproduced Campaign
`200002`. The jellyfish displayed a real progress bar and the runtime trace crossed
the full source-defined per-file downloader path.

Latest live capture:

- 739 packaged-probe events;
- 164 `download_file_before_native` events;
- 164 native-call returns;
- 164 native finish callbacks;
- observed native finishes report success (`result=0`, `code=0`);
- 163 HTTP `/res/` requests reached the backend;
- all 163 were recorded as `served`;
- all six `zhuankuai` lazy resources for Campaign `200002` were among those served.

The client then completed the battle and reached `BattleSpecialStory`. A later clear-data
experiment strengthened this further: after restoring only the recovered writable support
metadata/tree, the client progressively downloaded missing resources from the replacement
backend as gameplay reached them. This is the desired EOL behavior: the original lazy
manager repopulates the writable resource cache on demand.

This makes the EOL replacement path user-runtime-confirmed:

```text
CENTER res_download_url
→ local version/lazy metadata
→ AssetDownload queue
→ xyd.FileDownloader
→ GET /res/<basename>.<md5>
→ backend catalog reverse lookup
→ exact-MD5 resource bytes
→ native completion callback
```

Do not resume speculative MID113 download fields. Runtime lazy CDN fetches are not
controlled by a per-battle gameplay response. The packaged probe can remain installed
for observability, but the resource gateway is now a proven functional component.

---

## 1. Executive result

There is no source evidence that Campaign MID113, or any ordinary gameplay MID,
contains an instruction such as "download these files".

The client has **three distinct resource planes**:

1. **CENTER discovery / resource CDN location** — source-confirmed.
2. **Startup full-version updater** — source-confirmed and MID2-controlled.
3. **Runtime lazy/on-demand downloader** — source-confirmed and primarily local-state
   driven; it performs direct file HTTP downloads outside the gameplay MID protocol.

Pass 19 mapped (1) and the UpdateScene network boundary only at a high level because
Pass 19 is predominantly an engine API/MID map. Runtime lazy CDN downloads are not
ordinary `/api/v1` MID calls and therefore need this separate protocol map.

The earlier Chapter-2 `200002` stall was not a missing MID113 field. The packaged
probe has now live-confirmed the Lua → native → HTTP → gateway path and the battle
advances. Resource loading is no longer the current Campaign blocker.

---

## 2. Boot-time network plane: CENTER (MID20480)

Authoritative source: `src_64/UpdateScene_64.lua` lines 151-181.

Client POSTs CENTER:

```text
mid=20480
area="tw"
type=<package mode>
app_v=<APK version>
platform=<target platform>
```

The CENTER response directly assigns:

```lua
xyd.serverUrl      = response.url
xyd.serverID       = response.server_id
xyd.back_domain    = response.back_domain
xyd.resDownloadUrl = response.res_download_url
```

**Important:** `res_download_url` is not a one-time download command. It becomes the
base URL later used by both runtime lazy downloading and the background downloader.

Current backend behavior is structurally correct here: advertise a device-reachable
runtime host and a resource base ending in `/res/`. No private/LAN IP is hard-coded;
the backend derives the current host from the machine routing table unless explicitly
overridden.

---

## 3. Startup update plane: MID2

Authoritative source: `src_64/UpdateScene_64.lua` lines 1019-1082 and 254-520.

Immediately after CENTER discovery the updater POSTs to `xyd.serverUrl`:

```text
mid=2
platform=<platform>
app_v=<APK version>
v=<stored resource version>
clean=<is clean install>
full=<package flag>
```

The response is consumed as a **startup update descriptor**, including:

```text
is_appstore
is_inapp
need_restart
is_review
res
```

When `is_inapp != 0`, `response.res` is passed to `UpdateScene:update_()`.
Each `res` element describes a whole version package with fields consumed later such
as version, size, volume count, MD5 and resource URL. `downloadVersion_()` downloads
volume URLs of the form:

```text
<resource>.<volume-number padded to 3 digits>
```

These are ZIP/update-package downloads, not the jellyfish per-file downloads.

The descriptor fields directly consumed by the source are:

```text
version
volume
size
md5
resource
```

For a descriptor, the client creates `<versionUpdatePath>/<version>.zip`, downloads
`<resource>.001`, `.002`, ... up to `volume`, appends/resumes into that ZIP, validates
the whole ZIP against `md5`, and unzips it into `versionUpdatePath`. This is the
closest source-confirmed server-controlled mechanism to “tell the client to download
resources.”

However, MID2 does **not** bypass the uncertain native boundary: it calls the same
`xyd.FileDownloader:download()` binding. It also does not automatically clear old
lazy keys merely because a package contains matching bytes; the post-update catalog
path adds lazy entries for newly introduced non-force resources, but source does not
show a general pass that removes pre-existing lazy entries based only on package
contents. Therefore fabricating a MID2 package is not a safe substitute for tracing
the downloader.

Current private backend deliberately returns `is_inapp=0`, so it does not ask the
client to perform a full startup version update. We must not invent historical `res`
package descriptors without capture evidence.

---

## 4. How `version.json` becomes `lazyFile.json`

Authoritative source: `src_64/UpdateScene_64.lua` around lines 281-390.

`version.json` is the client resource catalog. On initialization, for each catalog
row whose `force != 1`, the updater checks the writable physical copy using:

```text
catalog path:  res/web/X
validation:    <versionUpdatePath>/res/X
```

If that physical file is absent or its MD5 differs, the updater writes a lazy map
entry:

```text
key   = __lazy__ + path with '/' replaced by '___'
value = JSON {version,size,md5,path}
```

The map is stored by `lazyFileManager` in:

```text
<versionUpdatePath>/lazyFile.json
```

The `__version_json_init__` user-default flag prevents rebuilding the entire initial
lazy map every launch after initialization.

### Critical distinction: startup validation path vs runtime download path

The startup initializer validates `res/web/X` against writable `res/X` using the
`/web/ -> /` alias.

However, **runtime `AssetDownload:downloadFile()` writes the downloaded object to the
original catalog path**:

```text
<versionUpdatePath>/res/web/X.asset_tmp
-> <versionUpdatePath>/res/web/X
```

This distinction was missed by the Stage 4A.9 ADB installer, which copied only to
`res/X`. The boot search path includes both writable `res/web` and writable `res`, so
the old helper was not necessarily fatal, but it did not reproduce the runtime
on-demand downloader faithfully. v0.6.x corrects the helper to install to
`res/web/X` by default.

---

## 5. Runtime lazy/on-demand download plane

Authoritative source: `src_64/app/common/AssetDownload.lua`.

### 5.1 Catalog loading

`AssetDownload:ctor()` loads `version.json`, preferring writable update storage and
falling back to bundled `src_64/version.json`. It builds a directory-indexed
`webSkeletonDict_` for `res/web/...` rows.

### 5.2 "File exists" does not stat the file

`AssetDownload:isFileExist(path)` only checks the lazy map:

```lua
lazyFileManager:getStringForKey("__lazy__" .. parseXmlPath(path))
```

No lazy key => considered present.  
Lazy key exists => considered missing.

This explains why metadata state can disagree with bytes physically present on disk.

### 5.3 Battle preloading and the jellyfish

Authoritative source: `AssetDownload:preloadBattleInfos()` lines 200-368 and
`app/common/utils.lua` `xyd.pushBattleScene()` lines 6828-6974.

After a successful MID113, the client creates its battle actors locally and calls
`xyd.pushBattleScene()`. That derives:

- hero / monster model IDs;
- map images from `battle.lua`;
- battle sound;
- additional preload skeleton dependencies.

It then calls:

```lua
xyd.AssetDownload.get():preloadBattleInfos(...)
```

If no lazy resources are needed, it immediately pushes the battle scene.

If one or more resources are needed, it calls:

```lua
xyd.LoadingProxy.get():addNewLoading(1.5)
AssetDownload:downloadFiles(...)
```

`NewLoadingWindow.lua` is the water/jelly animation the user remembers from the live
game. Its percentage is driven by `AssetDownload` progress callbacks.

Therefore the jellyfish is direct evidence that **some code incremented the generic
new-loading counter**, but it does not by itself prove which exact `AssetDownload`
queue or native request is active. The v0.6.0 Lua probe logs both the preloader and
`LoadingProxy` call sites to settle this.

### 5.4 Exact per-file HTTP URL

`AssetDownload:getDownloadInfo_()` constructs:

```text
xyd.resDownloadUrl + basename + "." + expected_md5
```

The original directory is **not** present in the HTTP URL.

Example:

```text
catalog path:
res/web/skeletons/npc/zhuankuai/zhuankuai.png

HTTP request:
<res_download_url>/zhuankuai.png.87d6ffe66a54dfd41f7996e2ff47e1c7
```

The CDN/server must therefore reverse-map `basename + md5` back to the catalog path.
The backend's resource catalog does exactly this.

### 5.5 Native boundary and integrity check

Runtime call:

```lua
xyd.FileDownloader:download(url, tmp_path, 0, 10, progress_cb, finish_cb)
```

On success Lua independently validates:

```lua
cc.Crypto:MD5File(tmp_path) == expected_md5
```

Only then does it rename the temp file into place and delete the corresponding lazy
key. Otherwise it requeues the file.

This proves arbitrary dummy bytes cannot advance an unmodified client unless their
MD5 matches the expected metadata (or the client metadata/verification logic is also
changed).

---

## 6. Background / silence downloader

Authoritative source: `src_64/app/common/SilenceDownloader.lua`.

This is a separate per-file downloader over the same `version.json`, lazy map,
`xyd.resDownloadUrl` and `xyd.FileDownloader` native wrapper. It assigns priorities
for skeletons, windows, sounds, maps and activities and downloads missing files when
not conflicting with battle or other busy scenes.

Its per-file URL is the same form:

```text
xyd.resDownloadUrl + basename + "." + md5
```

The complete `src_64` contains the downloader class, but no normal Lua callsite was
found that starts it in the inspected 1.631.0 source beyond importing it in
`MainScene.lua`. That means it must not be assumed to run automatically in this
build without runtime evidence. The on-demand `AssetDownload` path remains the
source-confirmed battle path.

---

## 7. Filesystem search paths

Authoritative source: `src_64/boot_64.lua`.

Android search order is:

```text
<versionUpdatePath>/res/web
<versionUpdatePath>/res
APK/package res
```

This is why both modern `res/web/...` runtime downloads and older/startup-mapped
`res/...` files can be loadable. For fidelity, new direct installs should prefer the
exact runtime path `res/web/...`.

---

## 8. What Pass 19 did and did not map

Pass 19's `PRE_UPDATE_SCENE_NETWORK_BOUNDARY_PASS12.md` correctly states that the
first explicit Lua HTTP boot calls are UpdateScene CENTER/version traffic, before the
normal player bootstrap MID1.

Pass 19's transport rewrite recommendation separates `center_http` from engine HTTP
and chat transports. That remains correct.

What Pass 19 did **not** fully model is the later per-file CDN plane because it is not
an engine MID/API call. The resource protocol should now be treated as an independent
transport/domain:

```text
center_http
startup_update_http (MID2 descriptors + package volumes)
engine_http
resource_cdn_http (basename.md5 GET)
client_local_lazy_state (version.json/lazyFile.json)
native_file_downloader boundary
```

---

## 9. Runtime evidence for Chapter 2 / campaign 200002

The investigation has two successive live states.

### Before packaged instrumentation

- MID2768 succeeded.
- MID113 for campaign `200002` succeeded.
- Server-side dependency audit found all six `zhuankuai` lazy resources recoverable
  with exact current-client MD5.
- No `/res/` GET reached Flask, so the failing boundary could not be located from the
  server alone.

### v0.6.1 packaged-probe run

- `preload_battle_enter`, queue and loading events were observed;
- 164 calls reached the Lua-visible native FileDownloader boundary;
- all 164 calls returned to Lua;
- 164 native finish callbacks were captured;
- 163 direct `/res/` HTTP requests reached Flask and every one was served;
- the six `zhuankuai` files were requested and served;
- Campaign `200002` proceeded through the local battle into `BattleSpecialStory`.

Therefore the per-file CDN mechanism is no longer unknown. CENTER's
`res_download_url`, local lazy metadata, `AssetDownload`, native FileDownloader, and
the backend resource gateway have all been observed participating in a successful
runtime sequence.

The next Campaign blocker is the independent MID2064 special-story reward contract.

---

## 10. v0.6.0 probe result and v0.6.1 packaged-Lua probe

### v0.6.0 result: non-evidence at the Lua/native boundary

The first probe attempted to place a plaintext `app/xinyoudi.lua` override under the
writable `src_64` tree. The resulting run created **no**
`resource_pipeline_trace.log`. Therefore it did not establish whether
`AssetDownload` or `xyd.FileDownloader` was reached.

Two corrections matter:

1. The probe helper's `pull` action called `am force-stop` before reading files. The
   app disappearing immediately after `pull` was caused by the tool itself; it is not
   evidence of a Lua/native crash.
2. The APK contains both 32-bit and 64-bit update entry paths. `UpdateScene.lua`
   selects writable/package `src_32`, while `UpdateScene_64.lua` selects
   writable/package `src_64`. The supplied source archive does not include enough of
   the tiny launch selector to prove which one this installation uses. A probe in
   only writable `src_64` was therefore not a reliable test. A root-created override
   can also differ from normal app-created files in Android ownership/SELinux
   metadata, so absence of the trace must not be over-interpreted.

The current device capture still contained all six `zhuankuai` lazy keys and neither
`res/web/skeletons/npc/zhuankuai` nor the legacy `res/skeletons/...` copy in writable
storage. Thus this run tested the failed tracer, **not** a successful direct resource
installation.

### v0.6.1 strategy

The user has an established APK-workshop flow that safely decompiles/repackages Lua
assets. v0.6.1 therefore instruments the already-packaged plaintext files rather
than smali or native libraries. `tools/patch_decoded_assetdownload_probe.py` patches
both source trees:

```text
assets/src_32/app/common/AssetDownload.lua
assets/src_64/app/common/AssetDownload.lua
assets/src_32/app/common/ui/LoadingProxy.lua
assets/src_64/app/common/ui/LoadingProxy.lua
```

It records:

- `assetdownload_module_loaded`;
- `preload_battle_enter`;
- exact `preload_battle_queue`;
- `preload_battle_add_loading`;
- every `download_files_enter`;
- `insert_to_stack`;
- exact URL/path/MD5/temp path immediately before `xyd.FileDownloader:download()`;
- return from that Lua-visible native call;
- native finish callback values if it returns;
- every `LoadingProxy:addNewLoading()` with a Lua traceback;
- every `LoadingProxy:removeLoading()`.

The primary synchronous trace remains:

```text
<versionUpdatePath>/resource_pipeline_trace.log
```

Once MID1 has supplied `log_url`, AssetDownload probe events are also sent through
the source-defined `Backend:log(0, ...)` transport. The private backend recognizes
the marker and writes:

```text
runtime_logs/resource_client_probe.jsonl
```

These records are observability events, not client errors.

This isolates the boundaries without changing MIDs, URLs, lazy keys, FileDownloader
arguments, or gameplay state. If `loadingproxy_add_new` proves a caller other than
`AssetDownload:preloadBattleInfos`, its traceback becomes the new lead.

The decisive trace was obtained and followed the full expected sequence:

```text
preloadBattleInfos
 -> queue
 -> addNewLoading
 -> downloadFiles / insertToStack
 -> download_file_before_native
 -> native call returns
 -> /res/<basename>.<md5> HTTP request
 -> native finish callback result=0/code=0
```

This resolved the v0.6.0 uncertainty. Keep the probe as a reusable observability tool
for future asset gaps, but do not treat the native downloader as the current gameplay
blocker.

## 11. Native layer research

`xyd.FileDownloader` is a native binding; its implementation is not present in the
complete Lua asset source and Pass 19 cannot recover it from Lua alone.

`tools/native_downloader_probe.py` can inspect an APK supplied locally (or pull the
installed APK via ADB) and report native libraries/strings related to downloader,
libcurl/HTTP/range/resume behavior. This is evidence collection only; it does not
patch binaries.

External primary-source context: Cocos2d-x 3.x historically had downloader fixes on
Android, so the native layer is a legitimate boundary to inspect, but that does not
prove a Cocos engine bug in this game.

---

## 12. Server contract to preserve while researching

Do not broaden the backend blindly. Keep these resource responsibilities explicit:

1. MID20480 must advertise a correct dynamic `res_download_url`.
2. MID2 descriptors must remain source-shaped. v0.6.3 may advertise an operator-built
   local ZIP update only when a valid enabled `local_assets/update_manifest.json` exists;
   otherwise MID2 remains a no-update response.
3. `/res/<basename>.<md5>` must log every request, reverse-resolve against the current
   catalog, serve only exact expected bytes, and preserve HTTP range compatibility.
4. The server asset store remains fixed at `local_assets/res` for normal deployment.
5. Resource request logs retain downloader-facing headers such as `Range` so resume
   behavior can be reconstructed if the native request finally reaches HTTP.
6. Missing resources are logged; dummy substitution remains off by default.
7. Campaign MID113/MID114 must not be changed to solve a client-local CDN stall.

---

## 13. Direct-install experiment correction

The Stage 4A.9 ADB helper removed lazy keys but installed `res/web/X` only at the
startup-validator alias `res/X`. Source review now shows the runtime downloader writes
to the original catalog path `res/web/X`. Because `boot_64.lua` searches both
`<versionUpdatePath>/res/web` and `<versionUpdatePath>/res`, the older experiment was
not necessarily invalid, but it was not faithful to the runtime path. v0.6.x changes
`tools/install_campaign_assets_adb.py` to install the exact `res/web/X` path.

This correction is documented rather than treated as proof of the Chapter-2 root
cause; the Lua/native trace remains the next evidence-gathering step.

---

## 14. v0.6.3 backend-local force/Lua update plane

The runtime `/res/` path and Lua updates are intentionally separate. The shipped resource
catalog marks Lua/update-tree files as force/startup content rather than ordinary lazy
resources, while `UpdateScene.lua` / `UpdateScene_64.lua` consume MID2 `res` descriptors.

Source-confirmed descriptor fields:

```text
version
volume
size
md5
resource
```

For each descriptor the client downloads `<resource>.001`, `.002`, etc., assembles and
MD5-verifies the ZIP, unzips it into `xyd.versionUpdatePath`, records the new resource
version, and restarts. `package.path` then puts writable `src_32` or `src_64` before the
packaged tree.

v0.6.3 exposes this as an opt-in operator facility:

```text
local_assets/src_32/       sparse overrides
local_assets/src_64/       sparse overrides
local_assets/updates/      generated ZIP volumes
local_assets/update_manifest.json
```

Build with an explicit operator-chosen version:

```bash
python3 tools/build_local_lua_update.py --version <resource-version>
```

The server then exposes `/updates/<package>.001` and MID2 advertises the matching
source-shaped descriptor until the client reports that target resource version.

Status: the **client MID2 mechanism and writable Lua precedence are source-confirmed**;
the v0.6.3 synthetic local package facility is implemented but still needs one controlled
runtime validation. It is disabled when no valid enabled manifest exists.


## 15. v0.6.4 recovered Lua-layer provenance and safe MID2 probe

The uploaded recovery archive provides direct evidence for the writable Lua precedence model:

- APK baseline: 4,370 files under each of `src_32` and `src_64`; every paired file is byte-identical.
- recovered writable layer: 62 files under each architecture; every paired file is byte-identical.
- all 62 recovered writable files differ from the corresponding APK baseline copy.

`data/lua_asset_catalog.json` records those hashes/sizes. This supports treating the recovered `downloaded-assets` tree as a historical hot-update layer rather than an alternate decompile.

v0.6.4 therefore keeps `local_assets/src_32` and `src_64` sparse and mirrored. `tools/import_lua_override.py` stages one audited file from either the APK baseline or recovered writable layer.

For runtime validation of the MID2 plane, `tools/build_local_lua_update.py --probe-only` generates a package containing only two unreferenced marker modules. Offline validation confirmed the generated volume MD5 and ZIP membership. Runtime events are written to `runtime_logs/local_update_events.jsonl`.

This does not change the already-live-confirmed lazy `/res/` protocol. The two planes remain separate:

```text
Lazy non-force asset: AssetDownload -> /res/<basename>.<md5>
Force/Lua package:     MID2 -> UpdateScene -> resource.001... -> ZIP MD5 -> unzip -> restart
```

---

## 16. v0.7.0 — MID2 transport live-confirmed; version grammar corrected

The first device-side MID2 marker test is now conclusive about the transport itself.
Runtime evidence shows:

```text
MID2 is_inapp=1 + res descriptor
→ user accepts update prompt
→ GET /updates/gxb-local-1.631.0-local1.zip.001
→ HTTP 200
→ UpdateScene verifies/unpacks
→ writable src_64/gxb_hotupdate_probe.lua exists
```

Therefore the backend's package URL/volume schema and UpdateScene install path are
**user-runtime-confirmed**.

The post-update login wedge was caused by the descriptor `version`, not package delivery.
The first probe used `1.631.0-local1`. Authoritative `UpdateScene.compareVersion()` splits
on dots and calls `tonumber()` on the first three components. On the next startup:

```text
APK version      = 1.631.0
resource version = 1.631.0-local1
third component  = "0-local1"
tonumber(...)     = nil
```

`pkgVersionCheck()` then performs arithmetic involving nil before the client reaches the
normal MID2/login sequence. Disabling the server manifest cannot fix this because the
malformed value has already been stored in Cocos UserDefault `__version__`.

v0.7.0 therefore establishes the update protocol invariant:

```text
MID2 resource version ::= DIGITS "." DIGITS "." DIGITS
```

Project release labels and experimental suffixes must never be encoded in that field.
Use monotonic numeric resource versions (`1.631.1`, `1.631.2`, ...) instead.

The backend now validates both generated and manually edited manifests and only advertises
a numeric target when the client's valid current resource version is older. Same/newer
versions get the normal no-update response, so an enabled manifest does not need to be
manually disabled after each successful install.

The recovery helper `tools/recover_resource_version_adb.py` repairs only the stored
`__version__` preference on rooted test devices that installed the malformed first probe.

### 16.1 Updated content-plane model

At v0.7.0 the reconstructed content system has two independently live-confirmed planes:

```text
A. runtime lazy CDN
CENTER res_download_url
→ lazyFile/version metadata
→ AssetDownload
→ native FileDownloader
→ /res/<basename>.<md5>

B. startup package update
MID2
→ res descriptor(s)
→ native FileDownloader <resource>.001...
→ whole-package MD5
→ unzip into writable tree
→ numeric resource version
→ restart
```

The user's subsequent gameplay also shows the practical impact of Plane A: multiple
previously non-responsive Institute-family UI surfaces begin opening once their missing
assets can be fetched on demand. This confirms asset gating was a broad reason for inert
menus, although it does not prove the server logic behind those menus is complete.
