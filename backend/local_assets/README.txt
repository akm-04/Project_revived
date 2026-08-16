GXB EOL backend-local writable-game/update store

Normal layout:
  local_assets/res/       runtime lazy CDN source (served through /res/)
  local_assets/src_32/    sparse 32-bit Lua/data hot-update overrides
  local_assets/src_64/    sparse 64-bit Lua/data hot-update overrides
  local_assets/updates/   generated MID2 ZIP volumes
  local_assets/update_manifest.json  generated MID2 advertisement (optional)

RESOURCES
---------
Build recovered runtime resources from community captures with:
  python3 tools/build_static_asset_store.py /path/to/community/archive/parent

Only current-catalog MD5 matches are accepted. Runtime lazy/non-force assets use
AssetDownload -> FileDownloader -> /res/<basename>.<md5>.

LUA / DATA OVERRIDES
--------------------
Force/Lua content uses the separate source-confirmed MID2 UpdateScene ZIP-volume path.
Keep these directories sparse: only intentional overrides belong here.

Stage a recovered source file into BOTH architecture trees with:
  python3 tools/import_lua_override.py \
      --archive /path/to/all-assest-rechecked.zip \
      --layer downloaded \
      --path app/windows/LoginWindow.lua

Build an intentional update:
  python3 tools/build_local_lua_update.py --version <resource-version>

SAFE FIRST PROBE
----------------
Build only two harmless marker modules and enable their MID2 package:
  python3 tools/build_local_lua_update.py \
      --version 1.631.0-local1 \
      --probe-only

The packaged v0.6.4 manifest is disabled by default. After the tablet test, disable an
already-built manifest with:
  python3 tools/set_local_update_enabled.py off

Runtime server evidence:
  runtime_logs/local_update_events.jsonl

Writable src_32/src_64 take priority over APK Lua after UpdateScene unzips and restarts.
Use --silent only when intentionally testing UpdateScene's source-defined is_review path.
