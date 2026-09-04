# Pass298 — Post-Bulk Lazy Resource Reconciliation

## Scope
Pass298 is a targeted stock-client reconciliation pass after the successful Pass297 MID2 transport smoke. It does not redesign the updater, Resource/CDN gateway, or legacy fallback. It diagnoses why the client continued issuing `/res/` requests for assets already included in the loud bulk update and implements the smallest source-shaped server-side correction.

## Runtime evidence from debug.zip
Observed debug SHA256: `22f9d0b27940289ed9ab86d7cb3582b6e7f562460bc275c7846ba44234c252be`.

Successful attempt:
- server built/published `1.631.3 BULK_RESOURCE_BOOTSTRAP`, 12 volumes, assembled size `1,059,535,905`, exact assets `25,420`, missing `4,511`, mismatch `0`;
- client requested `.001` through `.012` and advanced to resource version `1.631.3`;
- client then received `1.631.4 CODE_ONLY`, advanced to `1.631.4`, and no further update was advertised;
- afterward 507 normal asset requests occurred: 489 served from current `local_assets/res`, 18 `local_file_missing`.

Therefore the Pass297 numeric/multi-volume transport is runtime-proven through download, assembly, unzip, restart and version advancement. The remaining traffic is post-install asset resolution, not update retry.

## Current-client source root cause
Current source authority remains `all-assest-rechecked-1.zip`.

SHA256:
- current `src_64/UpdateScene.lua`: `52c78a98002a27532343334360bd264af02700cbbda631d3b0cbf367e55516ac`
- current `src_64/lazyFileManager.lua`: `4257bdfbb400417414aff2f138f199c35675c96c56ccdfdfe09a6b0a681e3686`
- current `src_64/app/common/AssetDownload.lua`: `78b5fe69e2989cd976ce1083b29f9679905f4970ea882ad21b38fdb2cc7ea616`
- historical v1.164 `AssetDownload.lua`: `6ef74a258691492b374cd39a30e642412d5959a62644db5d26250ebf54d3bf02`

Current `UpdateScene.lua` initializes `xyd.lazyFileManager` before MID2. Its first catalog initialization creates `__lazy__...` markers for force=0 resources absent from `xyd.versionUpdatePath` under the stock `/web/ -> /` writable alias. It then sets `__version_json_init__=success`, so that full initialization is not repeated on later starts.

Current `AssetDownload:isFileExist()` does not test the writable file bytes. It treats absence of the matching lazy marker as existence. A stale marker therefore wins even when the loud MID2 ZIP has physically installed the file.

Current v1.631.0 `AssetDownload.insertToStack()` immediately schedules the network download. Historical v1.164 had an extra local-alias check: if `xyd.versionUpdatePath + path with /web/ removed` existed and MD5 matched, it deleted the lazy marker and completed locally. That block is absent from current v1.631.0.

This supersedes the narrow Pass293 inference that current `insertToStack()` would self-heal stale lazy keys after a bulk bootstrap. Pass293 remains immutable historical provenance; only that inference is superseded.

## Historical/passmap reconciliation
Pass286 correctly established a different mechanism for CATALOG_MIGRATION: a MID2 package carrying changed full `version.json` lets stock `UpdateScene` merge changed force=0 rows into `lazyFileManager`. Its rule `do not directly replace lazyFile.json` was scoped to catalog-overlay donor migration where the client itself can perform the changed-MD5 merge.

Pass298 bulk baseline is a different case. The 25,420 supplied resources retain their existing catalog paths/MD5s; there is no changed catalog row for `UpdateScene` to merge and no current-client local-alias reconciliation. The stale pre-MID2 markers must therefore be reconciled as baseline state.

Pass290/292 also prove the original Android OBB path runs before lazy initialization. An OBB-populated clean install naturally produces lazy markers only for files still absent. Pass298 makes MID2 bulk bootstrap leave the same logical post-baseline state.

## Existing Resource/CDN / old_res boundary retained
The current bulk collector already uses the correct authority:
- source root: `local_assets/res` only;
- row authority: current base `version.json` force=0 `res/web/...` rows;
- exact byte eligibility: candidate MD5 must equal current advertised MD5;
- physical archive path: `res/web/... -> res/...`;
- historical `local_assets/old_res` is never consulted.

The accepted old_res gateway remains deny-by-default and requires an explicit allowlist keyed by current catalog path + advertised MD5 with donor size/MD5/SHA256 validation. Pass298 does not reopen or broaden it.

## Implementation
New pure module: `gxb_backend/updates/lazy_bootstrap.py`.

For BULK_RESOURCE_BOOTSTRAP only:
1. collect exact-current assets using the existing Pass293 collector;
2. derive the exact supplied catalog-path set from those same archive mappings;
3. regenerate stock-format `lazyFile.json` from the authoritative full base catalog;
4. omit lazy markers for exact force=0 resources supplied in the ZIP;
5. retain stock-format markers for force=0 resources not supplied exactly;
6. never create markers for force=1 rows;
7. archive the generated file at ZIP root as `lazyFile.json` after the asset entries;
8. record marker counts and lazyFile SHA256 in release provenance.

The generated value shape matches current `UpdateScene.lua`: each map value is itself a JSON string containing `size`, `md5`, `path`, and `version` only when present. Key shape is `__lazy__` + path components joined by `___`.

This does not alter descriptor size truth, float32/int32 compatibility, `.001..NNN` framing, Resource/CDN semantics, catalog rows, client Lua or native code.

## Monotonic recovery chain
Published Pass297 test artifacts remain immutable provenance. Pass298 advances the active policy to:
- `1.631.5 BULK_RESOURCE_BOOTSTRAP` loud: exact assets + reconciled root `lazyFile.json`;
- restart;
- `1.631.6 CODE_ONLY` silent cumulative baseline;
- restart;
- no pending update.

Startup reconciles only the mutable active `required_initial_barrier` to 1.631.5. Historical 1.631.1–1.631.4 rows/bytes are not rewritten.

## Validation
Passed:
- Pass289 Resource/CDN regression;
- Pass291 scheduler regression;
- Pass293 bulk bootstrap regression;
- Pass294 auto-update regression;
- Pass297 MID2 numeric compatibility regression;
- Pass298 lazy bootstrap integration selftest;
- Python compileall.

Pass298 integration constructs a synthetic loud bulk release, reassembles its MID2 fragments, opens the ZIP, proves the exact asset is stored at the writable alias, proves root `lazyFile.json` exists, proves the supplied exact resource has no lazy key, proves an absent resource retains its lazy key, and proves force=1 remains outside the lazy map.

## Acceptance boundary
Pass297 updater transport is accepted by the supplied successful runtime trace. Pass298 lazy-state correction is static/regression accepted and requires one stock-client re-test.

Decisive acceptance condition: after installing 1.631.5 and 1.631.6, a resource included exactly in the bulk package must no longer cause a successful `/res/<basename>.<md5>` request. Genuine 4,511 EOL holes may still use the accepted Resource/CDN path when requested.
