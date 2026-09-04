# GXB update/resource operator notes — Pass299

Runtime: `gxb-backend-v0.52.0-pass299.0`

Runtime MID2 scheduling authority is `local_assets/release_registry.json`. Operator knobs are in `local_assets/settings.json`. The current OTA generation is `OTA_CANONICAL_V1_PASS299`. Passmap—not the live registry—is the authoritative provenance record for the earlier experimental 1.631.1-1.631.6 sequences.

## Accepted lane architecture

```text
local_assets/updates/assets/   loud BULK_RESOURCE_BOOTSTRAP
local_assets/updates/code/     silent cumulative CODE_ONLY
local_assets/updates/catalog/  rare loud CATALOG_MIGRATION
local_assets/updates/history/  detached older-generation runtime artifacts
```

## Canonical version contract

```text
APK/resource baseline 1.631.0
  -> 1.631.1 BULK_RESOURCE_BOOTSTRAP (LOUD; mandatory first version)
  -> restart
  -> 1.631.2 CODE_ONLY (SILENT cumulative Lua/table baseline)
  -> restart
  -> 1.631.3+ later cumulative Lua/table changes
```

`1.631.1` is permanently reserved for the asset bootstrap in this reconstructed track. Normal Lua/table OTA begins at `1.631.2`. Future ordinary Lua/table releases increment monotonically from there. Rare catalog migrations remain loud barriers and must preserve the scheduler's ordering/transaction rules.

## Runtime acceptance

The supplied Pass298 stock trace is accepted as closure evidence:
- 1.631.5 loud bulk bootstrap downloaded all 12 advertised volumes and advanced cleanly;
- 1.631.6 silent cumulative code update completed;
- the client settled at v_=1.631.6 with no further MID2 response;
- the server observed zero post-update `/res/` asset requests;
- resource probes continued loading local CSB/window resources.

Those version numbers were experimental recovery numbers. Pass299 keeps their evidence in passmap but resets the live runtime generation to the canonical 1.631.1/1.631.2 sequence.

## Canonical-generation migration safety

On startup, `update_controller.py` compares the configured OTA generation with the persisted runtime registry. If they differ, the old registry is archived under `local_assets/updates/history/registry/`, its active release rows are detached, and the canonical barrier is installed. Before building/importing canonical 1.631.1 or 1.631.2, any same-version sidecar from another generation is moved under `updates/history/artifacts/`; it is never silently reused. New release sidecars carry `ota_generation`.

## Asset bootstrap contract

`BULK_RESOURCE_BOOTSTRAP` reads only exact-current `local_assets/res` bytes matching the authoritative catalog. It maps `res/web/...` to writable `res/...`, writes a generated root `lazyFile.json`, includes no Lua or `version.json`, and never reads `old_res`. Supplied force=0 resources are removed from the lazy map; genuinely unavailable force=0 resources remain lazy.

Every shard must be <=99,000,000 bytes and exactly representable through the current native float32 progress bridge. The client-simulated total must equal the truthful descriptor size; assembled size/local prefixes must remain <=2,147,483,647. MD5/SHA256 remain mandatory.

Manual canonical asset build:

```bash
python3 update_controller.py build --type asset --version 1.631.1 --loud --volume-mb 99 --bulk-min-files 25000
python3 update_controller.py publish
```

Canonical Lua/table baseline:

```bash
python3 update_controller.py build --type code --version 1.631.2 --silent
python3 update_controller.py publish
```

Later code updates use 1.631.3, 1.631.4, ... as cumulative CODE_ONLY versions unless a source-driven catalog barrier occupies the next version.

## Preserved boundaries

- no client patch;
- no descriptor-size lie/tolerance workaround;
- Resource/CDN request/fallback architecture remains accepted/closed;
- `old_res` remains dormant/deny-by-default except explicit future catalog migration;
- passmap provenance is not deleted during canonical normalization;
- OBB remains an optional future bulk baseline, not required for the now-accepted MID2 path;
- Identity / Session / Concurrency is the next major research phase after this OTA closure.
