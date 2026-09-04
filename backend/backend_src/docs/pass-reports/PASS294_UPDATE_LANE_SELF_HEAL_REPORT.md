# Pass294 — MID2 bulk bootstrap failure self-heal and deployment automation

## Scope

Pass293's 1.631.1 loud bulk asset bootstrap was advertised correctly and the stock client requested all four 256 MiB-class volumes, but the client ended with `Failed to load (7,0)` before successful extraction. The exact native meaning of result code 7 is not recovered, so this pass records the 256 MiB volume size as runtime-rejected without claiming a more specific root cause.

## Runtime design changes

- Asset, code, and catalog releases now use separate `local_assets/updates/assets`, `updates/code`, and `updates/catalog` lanes.
- Maximum generated shard size is `99,000,000` decimal bytes, below GitHub's 100,000,000-byte file limit. `99 MiB` is explicitly rejected because it exceeds that limit.
- Asset bootstrap remains `1.631.1 BULK_RESOURCE_BOOTSTRAP`, loud and a required first barrier.
- Normal cumulative Lua/table baseline remains `1.631.2 CODE_ONLY`, silent and structurally unable to carry `version.json`.
- Historical `old_res` fallback stays disabled/empty.

## Automatic maintenance

`server.py` calls the same controller logic before opening listeners. `local_assets/settings.json` is the operator-facing settings file. With defaults (`auto_ensure=true`, `auto_publish=true`):

1. A valid committed asset release sidecar + shards is deep-verified and reused; no rebuild occurs.
2. If the asset release is absent and `local_assets/res` exists, the server builds exact-current assets into Git-safe shards and publishes 1.631.1.
3. If `res` is absent and no valid committed asset release exists, startup warns and continues; MID2 fails closed at the missing barrier.
4. After the asset barrier exists, the silent cumulative code baseline is similarly verified/reused or built/published.

`auto_publish=false` leaves a newly built asset candidate unpublished and therefore withholds the code baseline until the mandatory barrier is explicitly published.

## Immutable sidecars

Each built release carries a `.release.json` sidecar containing lane, release type, assembled size/MD5/SHA256, volume count, and exact per-shard size/MD5/SHA256. Startup can reconstruct registry authority from committed sidecars/shards when the source `res` tree is not deployed.

## MID2 verification cost

Pass293 rehashed complete release payloads during request-path release validation. Pass294 deep-verifies published release bytes at startup/publish and caches `(path,size,mtime_ns)` fingerprints. Ordinary MID2 checks use only stat fingerprints; a changed shard triggers a one-release deep re-verification before advertisement. This removes ~1 GiB of disk hashing per clean-client MID2 request.

## Validation

Synthetic tests prove:

- asset -> code auto-build/publish ordering;
- second startup idempotent skip;
- sidecar/shard restoration with `res` removed;
- `auto_publish=false` candidate hold;
- required barrier fail-closed behavior;
- lane-safe volume resolution;
- 99,000,000-byte hard cap;
- 205,000,123-byte synthetic payload split to exactly 99,000,000 + 99,000,000 + 7,000,123 bytes;
- unchanged stat fingerprints avoid deep MID2 rehash;
- changed stat fingerprints cause re-verification.

## Runtime gate

Pass294 is statically accepted but its 99 MB stock-client bootstrap retry remains pending. Resource/CDN architecture itself remains accepted/closed; this is deployment refinement before Identity / Session / Concurrency research.
