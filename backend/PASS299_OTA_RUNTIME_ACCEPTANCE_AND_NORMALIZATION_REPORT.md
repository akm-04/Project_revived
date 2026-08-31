# Pass299 OTA Runtime Acceptance and Canonical Version Normalization

## Result
The current OTA/resource-provisioning phase is **stock-client runtime accepted**. The supplied `debug(1).zip` successful attempt completed the Pass298 loud asset bootstrap and silent cumulative code update, then continued gameplay with no post-update ResourceGateway asset serves.

## Runtime evidence
- Debug SHA256: `78fb3e7ab14017286da2528d95afaadb204ab49c234a5904345cf14e9b5098e7`.
- Loud asset release: 1.631.5, 12/12 volumes served.
- Asset shard sizes: 99,000,000 x10; 62,005,060; 8,388,611 bytes.
- Silent code release: 1.631.6, one 2,411,656-byte volume.
- Version-check sequence: empty/clean -> 1.631.5 -> 1.631.6.
- Later gameplay requests consistently carry `v_=1.631.6`.
- ResourceGateway startup emitted catalog/root configuration only and **zero resource serve events** afterward.
- The resource probe emitted 1,354 local pipeline records and no AssetDownload/lazy/download events.

The logcat contains an `EmulatorCheckService` subprocess crash (PID 11931) due to a missing JNI implementation. The main game process is PID 10506 and continues; this is recorded as unrelated non-OTA noise rather than hidden.

## OTA closure
Pass297's float32/int32 MID2 compatibility implementation and Pass298's generated stock `lazyFile.json` reconciliation are therefore accepted together as the current stock-client OTA/resource provisioning contract. Resource/CDN remains available only for genuine unsupplied holes; it is no longer being triggered for bulk-supplied resources in this trace.

## Canonical version normalization
The recovery ladder used experimental versions 1.631.3-1.631.6 while the updater was being diagnosed. Now that the mechanism is proven, Pass299 resets the **live runtime generation** to the intended stable ordering:

```text
1.631.0 base
 -> 1.631.1 BULK_RESOURCE_BOOTSTRAP loud (assets always first)
 -> restart
 -> 1.631.2 CODE_ONLY silent cumulative
 -> restart
 -> 1.631.3+ later cumulative Lua/table updates
```

Historical experimental bytes and evidence are not deleted; they remain passmap provenance. Runtime ambiguity is prevented by generation ID `OTA_CANONICAL_V1_PASS299`. New sidecars carry `ota_generation`; a persisted older-generation registry is archived/detached, and a same-version sidecar from another generation is archived under `local_assets/updates/history/` instead of being reused.

## Preserved contracts
- <=99,000,000 bytes per Git-safe fragment.
- Every fragment size float32-exact for current native progress reporting.
- Truthful descriptor total and signed-int32 assembly boundaries.
- BULK_RESOURCE_BOOTSTRAP carries exact current assets + root stock-format `lazyFile.json`, no Lua/version.json/old_res.
- CODE_ONLY is cumulative and begins at canonical 1.631.2.
- `old_res` stays deny-by-default and is not bulk authority.
- Resource/CDN architecture remains accepted/closed.

## Passmap retrieval optimization
`PASS299_OTA_MASTER_INDEX.json` is now the first-entry retrieval file for OTA/MID2/resource-provisioning questions. `PASS299_OTA_SEQUENCE_GRAPH.json` links research -> design -> implementation -> runtime validation -> supersession. Older pass files/tables remain intact.

## Next
The OTA updater/resource-provisioning phase is closed for the current target. The next major phase is the dedicated Identity / Session / Concurrency Audit, starting with source/backend research before design or implementation.
