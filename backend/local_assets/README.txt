GXB EOL backend-local writable-game/update store

Normal layout:
  local_assets/res/       runtime lazy CDN source (served through /res/)
  local_assets/src_32/    sparse 32-bit Lua/data hot-update overrides
  local_assets/src_64/    sparse 64-bit Lua/data hot-update overrides
  local_assets/updates/   generated MID2 ZIP volumes
  local_assets/update_manifest.json  MID2 advertisement (optional)

Read ../UPDATE_README.md for the complete operator workflow and Pass35.1 test package.

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

Build an intentional update with a STRICTLY NUMERIC resource version:
  python3 tools/build_local_lua_update.py --version 1.631.3 --disable

PASS35.1 PREPARED RETEST
------------------------
The backend ships the exact 62 recovered writable overrides mirrored into both
src trees and a prepared 1.631.2 package. Advertisement is disabled by default.

Enable it deliberately with:
  python3 tools/set_local_update_enabled.py on

Disable it after testing with:
  python3 tools/set_local_update_enabled.py off

Do NOT use labels such as 1.631.0-local1. UpdateScene.compareVersion() requires
exactly three numeric components N.N.N.

Runtime server evidence:
  runtime_logs/local_update_events.jsonl

Writable src_32/src_64 take priority over APK Lua after UpdateScene unzips and restarts.
Use --silent only when intentionally testing UpdateScene's source-defined is_review path.
