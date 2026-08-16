# v0.7.0 — Stable live-assets milestone and safe MID2 hot updates

Date: 2026-08-17

## 1. Milestone status

v0.7.0 promotes the current restoration work from a Stage-4A patch sequence into a
stable baseline. The following have been user-runtime-confirmed together:

- Girls list and Hero detail are usable.
- Skin and Affinity tabs load.
- Hero skill upgrades work against canonical state when the server mirrors timed skill-point recovery.
- Campaign team selection and local Cocos battle simulation work.
- MID113 -> local battle -> MID114 progression persists.
- Campaign 200002 special-story Joan/Geisha claim progresses and persists.
- Backpack state is canonical and persistent.
- Sweep/Raid EXP juice rewards and EXP consumables level Heroes persistently.
- One-time guide-function flags persist.
- Runtime lazy assets are downloaded on demand through the replacement `/res/<basename>.<md5>` gateway.
- After the packaged Lua resource probe / restored lazy-resource state, previously inert asset-gated UI surfaces such as Institute submenus (Institute, Emblem, Vows, Alchemy, Workshop) now open and load assets. Their deeper gameplay APIs are not yet claimed complete.

Payment remains permanently out of scope.

## 2. Two distinct update planes

The client has two different source-confirmed content delivery systems.

### 2.1 Runtime lazy resource plane

```text
CENTER MID20480 -> res_download_url
local version.json/lazyFile.json
AssetDownload
xyd.FileDownloader
GET /res/<basename>.<md5>
backend catalog reverse-map -> exact bytes
native MD5/install callback
```

This path is live-confirmed. It supplies ordinary lazy assets such as images, skeletons,
sounds and windows as gameplay reaches them. It does not require a gameplay MID to list
which assets to fetch.

### 2.2 Startup force/Lua update plane

```text
MID2 version check
is_inapp=1 + res descriptors
UpdateScene
GET <resource>.001, .002, ...
whole-ZIP MD5 verification
unzip to xyd.versionUpdatePath
set Cocos resource version
restart
writable src_32/src_64 take precedence over APK Lua
```

The first device probe live-confirmed the transport/install portion: the update prompt
appeared, the `.001` volume was fetched, and `src_64/gxb_hotupdate_probe.lua` existed in
the writable tree afterward.

## 3. v0.6.4 probe regression: unsafe resource version label

The first probe used:

```text
1.631.0-local1
```

That label is invalid for this client. Authoritative `UpdateScene.compareVersion()` does:

```lua
split(version, "%.")
tonumber(parts[1])
tonumber(parts[2])
tonumber(parts[3])
```

On the next boot it compares APK `1.631.0` to stored `1.631.0-local1`. The third
component becomes `tonumber("0-local1") == nil`, so the subtraction in
`compareVersion()` raises a Lua error before the normal MID2/login sequence.

Runtime evidence matches that exactly:

- MID2 advertised the update.
- `/updates/...001` was served successfully.
- the marker file existed after install.
- after restart, the client stopped at the login background before issuing MID2.
- disabling the server manifest did not repair the already-stored malformed client version.

Therefore the update transport succeeded; the version metadata caused the startup wedge.

## 4. v0.7.0 safe-version rules

`tools/build_local_lua_update.py` now accepts only exactly three numeric components:

```text
N.N.N
```

Examples:

```text
1.631.1
1.631.2
1.632.0
```

Rejected examples include:

```text
1.631.0-local1
1.631.1-test
local1
1.631
```

The server also refuses to advertise a manually edited manifest whose target is not
strictly numeric `N.N.N`.

For valid numeric installed versions, the server compares current and target and does not
advertise the package when the client is already at or newer than the target. Therefore
an enabled manifest may remain enabled after a successful update; disabling it is optional.

## 5. Recovery from the v0.6.4 malformed version

The bad probe Lua module is unreferenced and may remain on disk. Repair only the Cocos
UserDefault resource version while the app is stopped:

```bash
python3 tools/recover_resource_version_adb.py --version 1.631.0
```

The tool:

1. force-stops `com.carolgames.gxb`;
2. locates the shared-preference XML containing `__version__`;
3. creates a one-time `.gxb_v064_bad_version_backup` copy of that preference XML;
4. changes only the `__version__` entry;
5. preserves owner/group/mode and leaves the app stopped.

Then start the v0.7.0 backend with its shipped update manifest disabled and launch the
client. Login should be able to proceed again.

## 6. Safe numeric probe test

v0.7.0 ships a disabled marker update targeting:

```text
1.631.1
```

Enable the already-built manifest:

```bash
python3 tools/set_local_update_enabled.py on
```

Restart the backend and launch the client. Accept the update prompt. The expected volume is:

```text
/updates/gxb-local-1.631.1.zip.001
```

After restart, the client should send MID2 with `v=1.631.1`; the server then returns
`is_inapp=0` without needing a manual manifest-off step.

Verify the marker if desired:

```bash
adb shell su -c 'cat /data/data/com.carolgames.gxb/files/com.carolgames.gxb/src_64/gxb_hotupdate_probe.lua'
```

Expected marker text includes:

```text
gxb_mid2_hotupdate_probe
```

Server evidence is written to:

```text
runtime_logs/local_update_events.jsonl
```

Expected sequence after a successful numeric update:

```text
advertise
serve_volume
version_current_or_newer
```

## 7. Backend-local content layout

```text
local_assets/
├── res/                 # large lazy resource store
│   └── web/...
├── src_32/              # sparse server-managed Lua/data overrides
├── src_64/              # mirrored sparse overrides
├── updates/             # generated MID2 update ZIP volumes
└── update_manifest.json
```

Do not copy all 4,370 APK Lua files into the sparse override trees. The recovered asset
archive established a 62-file historical writable override layer; use the provenance
catalog and import helper when selecting a real override:

```text
data/lua_asset_catalog.json
tools/import_lua_override.py
```

## 8. Versioning policy going forward

- Project/backend version (`v0.7.0`, `v0.7.1`, etc.) is documentation/release identity.
- Client resource version used by MID2 must remain numeric three-component text.
- For this APK baseline, use monotonically increasing numeric resource versions such as
  `1.631.1`, `1.631.2`, ... for local update packages.
- Never encode project labels (`local`, `test`, `v0.7`) into the client resource version.

## 9. Next gameplay roadmap

Competitive/Arena remains last. Recommended order after the update transport is confirmed
with a numeric version:

1. Formation MID208/MID209 canonicalization.
2. Campaign completeness: energy, source-confirmed economy, dropbox RNG, chapter rewards,
   pending-fight/session validation.
3. Hero progression: MID51/MID52, equipment, pieces, collection; awakening only when valid
   source prerequisites can be constructed.
4. Vending/Summon/Shop.
5. Activities.
6. Voyage and its independent subdomains.
7. Competitive/Arena last.

The newly asset-unlocked Institute/Emblem/Vows/Alchemy/Workshop surfaces should be mapped
as their own domains when their backend calls are exercised; UI availability is confirmed,
backend completeness is not.
