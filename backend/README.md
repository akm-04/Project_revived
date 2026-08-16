# GXB backend v0.7.0 — Stable Live Assets + Safe Hot Updates

Private/local EOL restoration backend for Girls X Battle 1.631.0.

## Stable milestone

User-runtime-confirmed working together:

- Girls list and Hero detail.
- Skin and Affinity tabs.
- Timed skill-point recovery + persistent Hero skill upgrades.
- Campaign team selection, local battle simulation, MID113/MID114 progression.
- Campaign 200002 Joan/Geisha special-story claim and continuation.
- Backpack persistence.
- Conservative first-clear drops.
- Sweep/Raid EXP juice rewards and EXP-item Hero leveling.
- Guide-function completion persistence.
- Live lazy asset downloads through `/res/<basename>.<md5>`.
- Asset-gated UI surfaces that previously did nothing now load on demand, including observed Institute-family submenus such as Emblem, Vows, Alchemy and Workshop. Their deeper server logic is not yet claimed complete.

Payment remains permanently out of scope.

## Critical v0.7.0 hot-update fix

The first MID2 probe proved that the server-driven Lua/data update transport works: the
client showed the update prompt, downloaded the `.001` volume, unzipped it, and the marker
appeared in writable `src_64`.

However, v0.6.4 used the target resource version:

```text
1.631.0-local1
```

That is invalid for this client. `UpdateScene.compareVersion()` calls `tonumber()` on the
three dot-separated version components, so the suffix causes a Lua error on the next boot
**before MID2/login**.

v0.7.0 enforces numeric three-component resource versions only:

```text
1.631.1
1.631.2
1.632.0
```

The server also refuses malformed manifests and never advertises a downgrade to a client
already at a newer numeric resource version.

## Recover a device wedged by `1.631.0-local1`

Use the included rooted-device helper while the v0.7.0 update manifest remains disabled:

```bash
python3 tools/recover_resource_version_adb.py --version 1.631.0
```

It changes only the Cocos shared-preference key `__version__`, preserving the XML file's
owner/group/mode, and leaves GXB stopped. Then start the backend and launch the app normally.

The old unreferenced marker Lua file may remain; it is harmless.

## Safe MID2 probe

v0.7.0 ships a **disabled** prebuilt marker update targeting `1.631.1`.

After recovering normal startup, enable it:

```bash
python3 tools/set_local_update_enabled.py on
python3 server.py
```

Launch GXB and accept the update. The client should fetch:

```text
/updates/gxb-local-1.631.1.zip.001
```

After restart it should report `v=1.631.1` to MID2. Because current >= target, the backend
returns `is_inapp=0`; **manual disabling after every successful update is not required**.
You may still disable it operationally with:

```bash
python3 tools/set_local_update_enabled.py off
```

Update evidence is logged to:

```text
runtime_logs/local_update_events.jsonl
```

Expected successful lifecycle:

```text
advertise
serve_volume
version_current_or_newer
```

## Build a future sparse Lua/data update

Stage only intentional override files under both architecture trees:

```text
local_assets/src_32/...
local_assets/src_64/...
```

Then build with a monotonically increasing numeric resource version:

```bash
python3 tools/build_local_lua_update.py --version 1.631.2
```

Never use suffixes such as `-local1`, `-test`, or project release labels in the client
resource version.

The uploaded/recovered source archive has already been cataloged into:

```text
data/lua_asset_catalog.json
```

Use:

```bash
python3 tools/import_lua_override.py \
  --archive /path/to/all-assest-rechecked.zip \
  --layer downloaded \
  --path app/windows/LoginWindow.lua
```

to stage an audited recovered writable override into both sparse trees. `--layer app`
selects the APK baseline copy instead.

## Backend-local content layout

```text
local_assets/
├── res/                 # large runtime lazy asset store
│   └── web/...
├── src_32/              # sparse Lua/data overrides
├── src_64/              # mirrored sparse overrides
├── updates/             # MID2 package volumes
└── update_manifest.json
```

Runtime lazy assets and Lua/data updates are different protocols:

```text
lazy asset:
CENTER res_download_url -> AssetDownload -> FileDownloader -> /res/<basename>.<md5>

Lua/data force update:
MID2 -> UpdateScene -> <resource>.001... -> ZIP MD5 -> unzip -> resource version -> restart
```

## Carry forward an existing player/resource state

Preserve your progressed state:

```bash
cp /old/backend/data/player_db.json ./data/player_db.json
```

Preserve the large recovered asset store rather than rebuilding it:

```bash
cp -a /old/backend/local_assets/res/. ./local_assets/res/
```

Do not copy an old malformed `update_manifest.json` into v0.7.0.

## Roadmap

See `docs/ROADMAP_V0_7.md`. Competitive/Arena is intentionally last. Near-term order is:
Formation -> Campaign completeness -> Hero progression -> Vending/Summon/Shop ->
Institute-family domains as exercised -> Activities -> Voyage -> Competitive.

## Documentation

Primary milestone notes:

- `docs/V0_7_0_STABLE_LIVE_ASSETS_SAFE_HOTUPDATE.md`
- `docs/RESOURCE_DOWNLOAD_PROTOCOL_RE.md`
- `docs/ROADMAP_V0_7.md`
- root `memory.md`

## Validation policy

Per project rules, assistant validation is Python syntax/offline artifact validation only.
No Flask/HTTP/APK/ADB/emulator/gameplay runtime test is performed unless explicitly requested.
