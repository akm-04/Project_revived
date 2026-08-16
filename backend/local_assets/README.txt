GXB EOL backend-local recovered asset store

Normal runtime location:
  local_assets/res/

Build it from community captures with:
  python3 tools/build_static_asset_store.py /path/to/community/archive/parent

The builder accepts current res/web/... and older flat res/... layouts but only
keeps files whose MD5 matches the current client resource catalog.

Stage 4A.9 also includes tools/install_campaign_assets_adb.py. That helper is
NOT run by server.py. It is an operator-run EOL repair tool for cases where the
original client remains stuck in AssetDownload before it performs HTTP GETs.
It copies already-verified local assets into the writable Android hot-update
res tree and removes only the matching __lazy__ keys from the device's
lazyFile.json while the app is force-stopped.
