# Pass291 MID2 Scheduler / Update Controller Self-Heal

Runtime artifact target: `gxb-backend-v0.47.0-pass291.0`

Status: **IMPLEMENTED / STATICALLY ACCEPTED / RESOURCE RUNTIME SMOKE STILL PENDING**

## Why Pass289 needed self-heal

Pass289 correctly implemented the deny-by-default historical resource whitelist, but its operator update controller still treated MID2 as one mutable latest manifest and always included `src_32/version.json` + `src_64/version.json` in newly built packages. Current stock source proves silent and loud modes share the same installer, so this could let ordinary silent Lua releases acquire unintended lazy-catalog authority. The single-manifest model also could not preserve old-client silent catch-up when a mandatory loud catalog migration was introduced.

## Pass291 runtime scheduling authority

`local_assets/release_registry.json` is now MID2 runtime authority. `update_manifest.json` remains only backward/operator metadata.

Current Android track is exact-gated to:

- `app_v = 1.631.0`
- `platform = 3`

Historical `app_v=1.164.0` receives no modern package.

Initial immutable history:

1. `1.631.24` — **PUBLISHED CODE_ONLY**, silent, cumulative, exact Pass281 package bytes, 148 files, no version.json.
2. `1.631.25` — **CANDIDATE CATALOG_MIGRATION**, loud, cumulative Lua/table payload plus full 43,759-row version catalog carrying the frozen ten-icon overlay. It remains unpublished until donor preflight/publish and stock smoke.

## Scheduler semantics

- Published releases are selected by installed `v`, `app_v`, and platform.
- CATALOG_MIGRATION and future BULK_RESOURCE_BOOTSTRAP releases are barriers and are served alone.
- One MID2 response never mixes silent and loud descriptors.
- Contiguous cumulative CODE_ONLY snapshots can collapse to the newest package; imported/non-cumulative code deltas preserve ordered multi-`res[]` sequencing.
- Missing/corrupt predecessor volume fails closed; scheduler does not skip forward to a newer release.
- Candidate releases are invisible to clients until explicit publish.

Example once 1.631.25 is eventually published:

`1.631.23 -> 1.631.24 silent -> restart -> 1.631.25 loud -> restart`

Future ordinary code release:

`1.631.25 -> 1.631.26 silent`

## Controller version coalescing

The controller answers the operator's double-version concern with a safe rule:

- If a CODE_ONLY release is **unpublished**, a subsequently staged catalog migration may rebuild/coalesce that candidate at the **same version**, absorbing the same cumulative Lua snapshot and adding version.json. No extra version is consumed.
- Once a version is **published**, its bytes/semantics are immutable. A later catalog migration must increment the version. The controller will never publish two different payloads under one installed resource version.

Thus normal operation is still mostly silent CODE_ONLY releases. Loud resource/catalog releases are exceptional and need not remain permanently active as a development focus.

## Multi-volume support

Controller builds can split one assembled ZIP into real `.001..NNN` fragments (`--volume-mib`). Registry `size` and `md5` remain the assembled ZIP identity exactly as stock `UpdateScene.downloadVersion_()` expects. Deterministic split/reassembly testing passed.

## Legacy operator tools self-healed

The old `tools/build_local_lua_update.py` no longer deletes older packages; it delegates to the version-aware CODE_ONLY candidate builder. The old global `set_local_update_enabled.py` is retired with an explicit message because one on/off manifest cannot safely represent immutable release history.

## ResourceGateway behavior retained

Pass289 resource policy is unchanged:

- `local_assets/res` = current authority, optional at startup.
- `local_assets/old_res` = historical donor pool, optional at startup.
- historical donor resolution is exact-whitelist-only and fail-closed.
- CSB cross-version transplantation remains forbidden.
- first runtime catalog migration remains exactly the ten frozen inventory PNGs.

## Static validation

`tools/selftest_pass291_update_scheduler.py` proves:

- exact Pass281 1.631.24 package hash/size/file count and no version.json;
- 1.631.25 remains unpublished loud catalog candidate;
- v1.631.23 receives 1.631.24 silent;
- v1.631.24 receives nothing while 1.631.25 is candidate;
- simulated 1.631.25 publication makes v1.631.24 receive 1.631.25 loud;
- v1.164.0 and wrong platform receive no modern update;
- source-shaped multi-descriptor silent sequencing works;
- cumulative same-mode code releases collapse safely;
- genuine multi-volume split/reassembly works;
- dirty whitelist cannot build CODE_ONLY;
- CATALOG_MIGRATION cannot be silent;
- unpublished CODE_ONLY candidate can be coalesced into catalog migration at same version, but a published version cannot be reused.

Pass289 ResourceGateway selftest continues to pass.

## Runtime gate remains unchanged

Do **not** publish/activate 1.631.25 until `res`/`old_res` are mounted and all ten staged donor hashes validate. Then publish the candidate, restart backend, and run the frozen ten-icon stock inventory smoke. Resource/CDN can close only after that acceptance gate.
