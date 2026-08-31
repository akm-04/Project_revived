# Pass289 Resource/CDN Compatibility Implementation

Status: **STATIC ACCEPTED / STOCK-CLIENT RUNTIME SMOKE REQUIRED**

Runtime artifact: `gxb-backend-v0.46.0-pass289.0`

## Implemented

- Current asset role is exactly `local_assets/res` by default.
- Historical asset role is exactly `local_assets/old_res` and is never included in generic current-resource discovery.
- Added `data/resource_catalog/legacy_fallback_allowlist.json` runtime policy. It is deny-by-default and keyed by exact `(current_path, advertised_md5)`.
- Added strict old donor verification: exact allowlisted relative path, size, MD5, SHA256; mismatch fails closed as `legacy_whitelist_mismatch`.
- Resource request logs/header include `source_role=legacy_whitelist` / `X-GXB-Resource-Source: legacy_whitelist` when a donor is served.
- Missing `res` or `old_res` only warns at server startup; the backend remains runnable for future external asset-server deployments.
- Added `update_controller.py` interactive/CLI operator workflow with staged whitelist edits, full version.json overlays, reverse resource catalog generation, stock MID2 ZIP-volume builds, version incrementing, loud/silent selection, activation and advertisement controls.
- Whitelist changes categorically refuse silent OTA builds.
- Catalog-overlay candidates categorically refuse generic `enable` before transactional `activate`.
- `activate` validates old_res donors and promotes allowlist + resource catalog + active full version catalog, then enables MID2 last. Explicit `--allow-external-assets` exists only for a future externally served resource deployment.
- Historical `.csb` is not supported by whitelist-add tooling. Pass289 `add-icon` intentionally accepts only standalone 100x100 `res/web/images/icon/*_icon.png` donors.

## First rollout candidate

A loud OTA `1.631.25` is prebuilt but **disabled** because the distribution intentionally does not embed the 800MB historical resource tree.

Candidate package:

`local_assets/updates/gxb-local-1.631.25.zip.001`

It contains the complete cumulative sparse src_32/src_64 override set plus byte-identical `src_32/version.json` and `src_64/version.json` generated from the exact Pass287 device full catalog.

Only 10/43,759 catalog rows differ from the 1.631.24 base, and only `md5` + `size` differ. All ten are force=0 inventory icons. Zero force rows change.

The live runtime policy remains the 1.631.24 catalog with an empty active historical whitelist until the operator runs:

```bash
python3 update_controller.py activate
```

Activation is intentionally refused unless all ten exact old_res donors validate, unless the operator explicitly declares an external asset-server deployment.

## Stock-source reality check

Current authoritative `src_64/UpdateScene.lua` was rechecked during Pass289. It:

- consumes `is_review` to choose silent vs visible `UPDATE_PROMPT`;
- reads `src_32/version.json` from the extracted update;
- writes that full catalog to writable `version.json`;
- merges changed non-force rows into `lazyFileManager`;
- restarts after successful in-app update.

Current authoritative `AssetDownload.lua` still constructs `/res/<basename>.<md5>` and validates downloaded bytes. Pass289 does not bypass client MD5 verification.

## Static validation

`tools/selftest_pass289_resource_cdn.py` proves with synthetic assets that:

- exact approved historical donor serves when current bytes are absent;
- current resource wins when present;
- unapproved historical bytes never serve;
- tampered approved donor fails closed;
- missing old_res does not prevent gateway construction and returns a bounded unavailable response;
- candidate 1.631.25 has exactly ten non-force md5/size changes;
- candidate is loud and disabled before activation;
- silent build is refused while staged whitelist differs from active policy.

## Runtime smoke gate

1. Place or symlink latest `res` to `local_assets/res`.
2. Place or symlink historical v1.164 `res` to `local_assets/old_res`.
3. Run `python3 update_controller.py status`.
4. Run `python3 update_controller.py activate`; all ten donors must validate.
5. Restart backend.
6. Launch stock client at resource version 1.631.24 and accept visible update to 1.631.25.
7. Confirm restart and inventory scrolling.
8. Require all 10 target requests to log `source_role=legacy_whitelist`.
9. Require zero non-whitelisted `old_res` serves, zero target MD5 mismatch/missing, and no new loading/Lua error.

Do not begin Identity/Session/Concurrency implementation until this Resource/CDN runtime gate is accepted.
