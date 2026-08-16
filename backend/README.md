# GXB Modular Stage 4A.9 Backend — Hot-Asset Installer + Undecoded Request Probe

Stage 4A.9 keeps the confirmed Stage 4A Girls/Campaign/Backpack/Hero-progression
state from Stage 4A.8 and addresses two newly isolated EOL-client problems:

1. Campaign `200002` still shows `NewLoadingWindow` even though all six formerly
   missing `zhuankuai` resources are now available locally with the exact MD5
   expected by the 1.631.0 client.
2. One first-login run showed a persistent generic loading popup immediately
   after lobby entry and contained one `/api/v1` payload the backend could not
   decode.

Payment remains out of scope.

## 1. No hard-coded LAN address

Normal startup does not contain a baked-in private/LAN IP. On Linux the backend
reads the default-route interface from `/proc/net/route` and asks the kernel for
that interface's IPv4 address. It does not use a fixed external probe address.
Portable hostname/address enumeration is the fallback.

For an unusual multi-interface host, `GXB_ADVERTISE_HOST` is still an explicit
operator override.

## 2. Why server-side assets alone did not remove the jellyfish

Authoritative `src_64/app/common/AssetDownload.lua` proves that
`AssetDownload:isFileExist(path)` does **not** call `cc.FileUtils:isFileExist`.
It checks the writable lazy-resource map instead:

```lua
local key = "__lazy__" .. parseXmlPath(path)
return not lazyFileManager:getStringForKey(key)
```

`lazyFileManager.lua` loads that map from:

```text
<xyd.versionUpdatePath>/lazyFile.json
```

Therefore putting an exact resource on the backend does not make the currently
installed APK consider that resource present while its writable `lazyFile.json`
still contains the `__lazy__...` key.

The update source also confirms the writable physical resource mapping used for
preinstalled/recovered resources:

```text
catalog:  res/web/X
physical: res/X
```

For campaign `200002`, Stage 4A.8 runtime audit found all six lazy `zhuankuai`
files present in `local_assets` with exact expected MD5s, while the APK still
made no `/res/` GET. This is now treated as a dead/pre-download client state,
not a missing backend endpoint.

## 3. Operator-run ADB hot-asset installer

New helper:

```text
tools/install_campaign_assets_adb.py
```

The backend never invokes ADB automatically. The user runs the helper after a
campaign asset audit has been generated.

For Chapter 2:

```bash
python3 tools/install_campaign_assets_adb.py --campaign 200002 --dry-run
python3 tools/install_campaign_assets_adb.py --campaign 200002
```

The helper:

1. reads `runtime_logs/campaign_asset_summary.json`;
2. selects only paths marked lazy in the supplied client snapshot and currently
   resolved as `present` by the backend asset audit;
3. re-verifies each local file MD5 before touching the device;
4. force-stops `com.carolgames.gxb`;
5. backs up the device writable `lazyFile.json` into
   `runtime_logs/adb_backups/`;
6. copies `res/web/X` to the client's writable physical `res/X` path;
7. removes only the matching `__lazy__res___web___...` keys;
8. writes an audit record to `runtime_logs/adb_asset_installs.jsonl`;
9. leaves the app force-stopped for the user to launch normally.

Default writable client root:

```text
/data/data/com.carolgames.gxb/files/com.carolgames.gxb
```

The helper supports either an ADB root shell or Android `run-as` for a
debuggable package. It refuses to invent a privilege-escalation method if
neither is available.

This bypass keeps the exact source MD5 requirement; it does not fabricate dummy
Spine files or spoof hashes.

## 4. Static backend asset store remains unchanged

Normal backend resource root:

```text
<backend>/local_assets/res/
```

Build/refresh it from community captures with:

```bash
python3 tools/build_static_asset_store.py /path/to/community/archive/parent
```

The builder reconciles current `res/web/...` and older flat `res/...` layouts,
but only accepts bytes matching the current client catalog MD5.

## 5. First-login loading popup: lossless payload decoding + raw capture

One Stage 4A.8 first-login run had an `/api/v1` request immediately after
MID1056 that appeared as:

```text
source=form-payload decode=undecoded
```

and the backend returned generic OK. The next app launch did not reproduce the
problem, so no MID is guessed.

Stage 4A.9 now caches the raw HTTP body before Flask parses form fields and can
decode:

- ordinary URL-encoded JSON payloads;
- zlib-wrapped JSON;
- raw-DEFLATE JSON;
- gzip-wrapped JSON;
- multipart `payload` bytes.

Any request still undecodable is written to:

```text
runtime_logs/undecoded_engine_requests.jsonl
```

with content type, form/file keys, raw length, and bounded raw hex/base64
prefixes. This is observability only; unknown payloads still receive generic OK
rather than an invented semantic response.

## 6. Existing confirmed gameplay retained

- Aquaris detail, Skin and Affinity.
- Skill upgrades and diamond skill-point purchase interaction.
- Campaign progression and relog persistence.
- Backpack persistence.
- Sweep/Raid Mini Juice rewards.
- EXP consumables and persisted Hero leveling.
- Guide-function completion persistence.
- Conservative first-clear Campaign item awards.

Player DB schema remains **4**.

## Validation policy

Only Python syntax compilation is run before handoff. No Flask, HTTP, APK, ADB,
emulator, or gameplay runtime testing is performed by the assistant.
