# Pass353 — I10 OTA deployment-topology reconciliation candidate

The Pass352 stock support bundle proves that the static-root correction itself worked: runtime `GXB_STATIC_ASSET_ROOT` is `current_backend/local_assets` and the resource gateway discovers `current_backend/local_assets/res`. OTA still failed for three independent deployment reasons.

First, the live release registry contained no published releases and MID2 logged `required_initial_barrier_unpublished` for canonical 1.631.1. Production starts Gunicorn with `gxb_backend.runtime.wsgi:app`; the previous auto-ensure call existed only in `gxb_backend.run.main()` and therefore was not part of the production start path.

Second, stock `AssetDownload.lua` sends lazy URLs as `/res/<basename>.<md5>`, while the authoritative catalog maps those request assets to nested paths such as `res/web/images/...`. nginx intercepted `/res/` with a flat-file alias, so the three observed stock lazy requests returned nginx 404 before `ResourceGateway` could resolve them.

Third, the release registry and published update volumes were still stored inside disposable `current_backend/local_assets/`, so ordinary code replacement could erase deployment publication state.

Pass353 repairs those boundaries only: `gxb-dev.sh start` runs `update_controller.py ensure` before any client-facing HTTP listener; nginx no longer bypasses the catalog-aware `/res/` route; workspace wrapper v7 persists the update registry/volumes/controller metadata under `runtime/ota/` and symlinks them into each extracted backend. PostgreSQL, legacy migration state, Pass352 gameplay/client changes and zrok remain untouched.

Static validation completed before packaging: I3–I10 218/218, broad non-integration 310/310, Pass294 updater selftest PASS, wrapper-v7 two-extraction persistence probe PASS, shell syntax PASS. Stock runtime remains pending.
