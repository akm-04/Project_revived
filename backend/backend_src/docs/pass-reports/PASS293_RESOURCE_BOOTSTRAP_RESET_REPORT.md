# Pass293 — Resource/CDN Closure Reset + Bulk Bootstrap Operator Path

Runtime artifact target: `gxb-backend-v0.48.0-pass293.0`

## Scope

Pass293 does not reopen Resource/CDN compatibility research. Pass292 already runtime-accepted the deny-by-default historical fallback architecture. Pass293 prepares a cleaner pre-concurrency deployment baseline:

1. Historical fallback remains implemented but is disabled by default and both active/staged allowlists are reset empty.
2. The modern Android resource-version track is deliberately reset to APK baseline `1.631.0`; devices previously on higher resource versions must clear app data.
3. The update controller now builds `BULK_RESOURCE_BOOTSTRAP` releases directly from exact-current `local_assets/res` bytes.
4. Intended sequence is `1.631.1` loud exact-current asset bootstrap, then `1.631.2` silent cumulative Lua/table CODE_ONLY, then ordinary silent increments.
5. OBB remains the preferred future Asset Rebuilding bootstrap because it runs before lazy initialization and does not consume update-server bandwidth.

## Why bulk MID2 is valid

A bulk package carries exact-current bytes only, with no `version.json` and no direct `lazyFile.json` mutation. Current catalog path `res/web/...` is archived to writable `res/...`, matching stock `/web/ -> /` lookup semantics. Even if a lazy key already exists when the loud update finishes, `AssetDownload.insertToStack()` checks the writable target first; matching local MD5 clears the stale lazy key and completes without network download.

## New release type

`BULK_RESOURCE_BOOTSTRAP` is a source-shaped loud barrier supported by the Pass291 scheduler foundation. Pass293 adds controller construction for it:

- loud-only;
- barrier served alone because `is_review` is top-level;
- no Lua/table payload;
- no `version.json`;
- no historical `old_res` reads;
- only force=0 current `res/web/...` rows;
- physical source must match current expected MD5;
- archive target uses `res/web/... -> res/...`;
- ZIP_STORED payload for already-compressed assets;
- real `.001 ... .NNN` split volumes from one assembled ZIP;
- default minimum exact-current count 25,000 to fail closed on a wrong/missing asset root.

Known current expectation from Pass283/292 is 25,420 exact recovered current lazy resources out of 29,931 catalog rows. The remaining 4,511 EOL holes are intentionally not fabricated.

## Required initial barrier

Pass293 release registry declares `1.631.1 BULK_RESOURCE_BOOTSTRAP` as a required initial barrier. Scheduler and controller publication both fail closed if a later release would otherwise bypass it. Therefore an accidentally published `1.631.2 CODE_ONLY` cannot be advertised to a clean `1.631.0` client until 1.631.1 is valid/published.

## Legacy fallback dormant state

- config default `GXB_LEGACY_FALLBACK=0`;
- active whitelist entries = 0;
- staged whitelist entries = 0;
- active/current resource catalog restored to the base current catalog with no donor MD5 overlay.

The exact fallback seam remains regression-tested and can be re-enabled only during a future explicit asset-rebuild cycle.

## Operator flow

After workspace setup/symlinking:

```bash
python3 update_controller.py status
python3 update_controller.py build --type asset --version 1.631.1 --loud --volume-mib 256 --bulk-min-files 25000
python3 update_controller.py publish
python3 update_controller.py build --type code --version 1.631.2 --silent
python3 update_controller.py publish
```

Then clear client data. Expected MID2 sequence:

- 1.631.0 -> 1.631.1 loud only;
- restart;
- 1.631.1 -> 1.631.2 silent only;
- restart;
- 1.631.2 -> no update until a later code release.

## Validation

- Python compileall: PASS.
- `tools/selftest_pass293_resource_bootstrap.py`: PASS.
- Pass291 generic scheduler/multivolume regression: PASS under superseding Pass293 live-history reset.
- Pass289 legacy fallback regression with explicit enable: PASS.
- Controller baseline: 43,759 full catalog rows, 29,931 lazy rows, 148 cumulative Lua/table override files.
- Stock server process was not launched in the artifact environment because the local runtime lacks Flask; this is an environment dependency, not a backend test failure. Static/import-targeted tests above pass.

## Status

Resource/CDN architecture remains **ACCEPTED/CLOSED**. Pass293 is a deployment/bootstrap refinement to protect the upcoming Identity/Session/Concurrency measurements from ordinary asset traffic. Actual 1.631.1 bulk package bytes must be built on the user's machine because the ~1 GiB resource tree is intentionally not bundled into the chat artifact.
