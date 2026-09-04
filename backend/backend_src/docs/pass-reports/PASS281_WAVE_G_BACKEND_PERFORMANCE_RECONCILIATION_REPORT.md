# Pass281 — Wave G bounded backend performance reconciliation

Pass280's one-line `Backend.requests_` hypothesis is rejected as the primary lobby fix and is reverted to exact current stock source in cumulative OTA **1.631.24**.

## Implemented backend changes

1. **App-scoped immutable request catalogs.** Thirty source catalog / read-only policy objects that were being rebuilt for every request are constructed once by `StateRepository` and injected into each request-scoped `RequestServices` graph. Player/UoW/domain services remain request-scoped. A static audit found no post-`__init__` `self.*` mutation in these shared classes.
2. **Canonical in-memory player working set.** One `PlayerState` object is reused per `player_id`. Normal UoW persistence writes that same object and updates its durable-file fingerprint. A cheap `(mtime_ns,size)` check preserves historical next-request visibility for out-of-band durable edits; `refresh()` remains an explicit forced reload boundary.
3. **Global request lock intentionally preserved.** This pass does not make mutations concurrent and is not the scheduled Identity / Session / Concurrency Audit.

## Measured local result

The same 23-request startup-like burst used in Pass281 research falls from ~13.83 s on Pass280 to **~2.51 s** on the actual implementation. This is an ~81.8% wall-time reduction while retaining serialized request execution.

## Endpoint topology finding

Current `UpdateScene.lua` proves the center service returns **both** gameplay `url` and independent `res_download_url`; `Backend.lua` uses the former for normal MIDs and `AssetDownload.lua` uses the latter for lazy resources. The uploaded patch script separately rewrites SDK `mhome.*`, engine/update endpoints, and web/CDN domains. TCP remains dynamically discovered by MID192. This strongly supports a multi-front-door original deployment. Physical host/process topology remains unrecovered.

## Remaining structural issue

The repository-wide `RLock` still serializes all authenticated HTTP requests across all players. It is safer to leave that transaction boundary intact for this lobby reconciliation and handle per-player locking / real cross-player parallelism in the formally scheduled Identity / Session / Concurrency Audit.

## Runtime gate

Retest the lobby with **no HTTP-uploading resource probe**. If queue time collapses but MID124/MID1056 still duplicate while an equivalent request is in flight, the next bounded client step is the already-designed HydrationCoordinator. `LoadingProxy` remains last resort. Bag/resource delay remains a separate track.
