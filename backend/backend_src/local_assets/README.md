# local_assets operator guide — Pass299

`local_assets/` holds deployable client-update artifacts and optional resource trees. Runtime MID2 authority is `release_registry.json`; operator policy is `settings.json`. Current OTA generation: `OTA_CANONICAL_V1_PASS299`.

## Layout

```text
local_assets/
├── settings.json
├── release_registry.json
├── res/                           # optional exact-current recovered resource tree
├── old_res/                       # historical donor tree; dormant/deny-by-default
├── updates/
│   ├── assets/                    # loud BULK_RESOURCE_BOOTSTRAP shards + sidecars
│   ├── code/                      # silent cumulative CODE_ONLY shards + sidecars
│   ├── catalog/                   # rare loud CATALOG_MIGRATION shards + sidecars
│   └── history/                   # detached older-generation runtime artifacts
├── update_staging/
└── update_policy/
```

## Canonical boot/update behavior

With `auto_ensure=true` and `auto_publish=true`:
1. Reconcile the persisted registry to `OTA_CANONICAL_V1_PASS299`; detach/archive older-generation runtime rows if necessary.
2. Verify/import canonical `1.631.1`; a same-number sidecar from another generation is archived, never reused.
3. If canonical 1.631.1 is absent and `res/` exists, build/publish it from exact-current assets + generated root `lazyFile.json`.
4. If the barrier is unavailable, gameplay remains up but MID2 fails closed.
5. Only after 1.631.1 is published, verify/build/publish cumulative silent `1.631.2`.
6. Later Lua/table releases increment from 1.631.3 onward.

## Client flow

```text
1.631.0
  -> 1.631.1 BULK_RESOURCE_BOOTSTRAP (LOUD; assets always first)
  -> restart
  -> 1.631.2 CODE_ONLY (SILENT cumulative Lua/tables)
  -> restart
  -> 1.631.3+ later cumulative code
```

## Asset bootstrap

```bash
python3 update_controller.py build --type asset --version 1.631.1 --loud --volume-mb 99 --bulk-min-files 25000
python3 update_controller.py publish
```

Asset builds use only current `res/`, exact catalog MD5 matches, flattened writable aliases, and a stock root `lazyFile.json`. `old_res` is never used. Every shard is <=99,000,000 bytes, float32-exact, and the assembled/prefix offsets are int32-safe.

## Lua/table updates

```bash
python3 update_controller.py build --type code --version 1.631.2 --silent
python3 update_controller.py publish
```

`CODE_ONLY` is cumulative and cannot contain `version.json`. Change `settings.json -> updates.code_baseline.version` to 1.631.3, 1.631.4, ... for later ordinary Lua/table updates.

## Important files

- `settings.json`: operator policy and canonical generation.
- `release_registry.json`: current-generation scheduler state only.
- `updates/history/`: local archival landing zone when a deployed runtime generation is reset.
- `*.release.json`: immutable current-generation per-release hashes/compatibility metadata.
- `update_manifest.json`: operator summary only.
- `gxb_backend/updates/mid2_compat.py`: numeric stock-client compatibility contract.
- `gxb_backend/updates/lazy_bootstrap.py`: post-bulk lazy-state projection.

Historical experimental update sequences are retained in passmap, not mixed into the canonical live registry.

## Runtime authority tokens

`release_registry.json` remains scheduling authority. Active artifacts live under `updates/assets` and `updates/code`. The Git-safe cap is `99,000,000` bytes. Startup behavior is controlled by `updates.auto_ensure` and `updates.auto_publish`.
