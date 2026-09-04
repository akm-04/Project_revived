# Pass297 OTA Compatibility Implementation Report

## Scope
Pass297 implements the explicitly accepted Pass296 MID2 stock-client compatibility design as a bounded extension of the existing Pass294 OTA subsystem. It does not redesign Resource/CDN, does not patch the client, does not implement OBB, and does not begin Identity / Session / Concurrency.

Project cycle followed: research/source exhaustion -> acceptance-contract and modular design freeze -> implementation -> stock-client reconciliation. The final long-run hardening phase remains deferred by project policy while large client systems are still incomplete.

## Source reality cross-check retained during implementation
Current source authority remains `all-assest-rechecked-1.zip`. Current native/smali authority remains `latest_apk-smali-full.zip`; historical v1.164 is corroboration only.

Current `src_64/UpdateScene.lua` SHA256:
`52c78a98002a27532343334360bd264af02700cbbda631d3b0cbf367e55516ac`

Historical v1.164 `UpdateScene.lua` SHA256:
`cd33fb742327b279fc7f5af776994e198170c77b293d80f98d2fa062618ae8a1`

Current ARM64 `libcocos2dlua.so` SHA256:
`c89c33e81466c0453213f65c67e0818a1581756ee0b45b89c0fc89a6d4f8e4c3`

The current and historical Lua both retain the strict MID2 completion condition: all volumes complete AND accumulated finished size equals descriptor size. They also retain `.001..NNN` sequencing and local offset based on accumulated finished size. The current native donor retains `FileDownloader::download(..., int, int, int, int)` and `reportProgress(int,double,double,double)`. Pass296 source research proved the current native progress-to-Lua path narrows relevant byte counters through float32, explaining the repeated one-byte `(7,0)` deficit. Pass297 does not weaken or counterfeit the client contract; it makes the server publisher conform to it.

## Implementation architecture
### 1. Shared compatibility seam
New module: `gxb_backend/updates/mid2_compat.py`

This is the sole shared authority for current stock-client MID2 numeric compatibility. Both publication and runtime verification use it. It provides:
- IEEE-754 float32 exact-size testing;
- deterministic volume-size planning under an operator cap;
- signed-int32 assembled/local-prefix constraints;
- client-accounted total simulation;
- compatibility metadata validation.

Current profile identifier:
`android_app_v_1.631.0_current_native_f32_progress_int32_offset`

This avoids duplicating transport quirks across the publisher and scheduler and provides a reusable seam if future source/native research discovers another compatibility profile.

### 2. Publisher-side planner and fail-closed verification
`update_controller.py` now asks the shared planner for exact shard lengths rather than blindly emitting a fixed-size sequence plus arbitrary remainder. Every built/published release is checked for:
- each shard <= configured operator cap;
- every shard byte length exactly representable through float32;
- exact real shard sum == assembled ZIP size;
- simulated client-accounted sum == assembled ZIP size;
- assembled size / cumulative local offsets within signed int32;
- existing per-volume and assembled hashes remain truthful.

The Git-safe cap remains 99,000,000 decimal bytes. The current known 1,059,535,905-byte payload plans as:
`99,000,000 x10 + 61,147,296 + 8,388,609`
All twelve lengths are float32-exact and sum exactly to the truthful descriptor size.

### 3. Runtime deep verification
`gxb_backend/updates/local_update.py` uses the same compatibility module while deep-verifying published releases. A release whose real shard sizes violate the declared/current compatibility contract is not advertised.

### 4. Required barrier becomes a direct routing anchor
For clients below the configured `required_initial_barrier`, the scheduler now selects that exact published barrier directly instead of walking through older published experiments. The historical failed 1.631.1 and unreachable 1.631.2 rows/bytes may remain immutable provenance, but clean/current clients no longer need to traverse them.

Recommended/current configured recovery chain:
- 1.631.0 base
- 1.631.3 corrected loud `BULK_RESOURCE_BOOTSTRAP`
- restart
- 1.631.4 fresh cumulative silent `CODE_ONLY`

### 5. Persisted deployment policy reconciliation
Implementation cross-check exposed an upgrade edge case: a Pass294 deployment can retain `release_registry.json` with active barrier 1.631.1 even after new settings are installed. Startup now reconciles only the mutable active barrier policy to configured 1.631.3 while preserving published release bytes and history unchanged.

### 6. Existing architecture reused, not replaced
Pass297 extends existing owners:
- `update_controller.py`: build/split/publish/startup maintenance;
- `local_update.py`: exact track selection, runtime verification, MID2 plan projection;
- existing assets/code/catalog lanes and cumulative CODE_ONLY semantics remain intact.

No parallel OTA authority was introduced.

## Implementation-stage anomaly handling
Two issues were discovered and corrected before sealing:
1. The first planner draft used a loop proportional to volume count for unusual tiny caps. It was replaced with quotient/remainder arithmetic so the seam does not assume the current 99 MB cap forever.
2. Persisted active-barrier policy could survive a code upgrade and still point to 1.631.1. Startup reconciliation was added as described above.

Neither discovery invalidated the Pass296 architecture; both were bounded implementation refinements.

## Validation
Passed:
- Python compileall;
- Pass289 Resource/CDN regression selftest;
- Pass291 generic update scheduler regression;
- Pass293 resource bootstrap regression;
- Pass294 auto-update regression;
- Pass297 MID2 compatibility selftest;
- deterministic source examples for known Pass293/294 one-byte deficits;
- exact frozen 1,059,535,905-byte plan check;
- tiny `16,777,217` precision-boundary split/reassembly integration test;
- direct-barrier routing tests with historical 1.631.1/1.631.2 present;
- fail-closed invalid-barrier test;
- persisted Pass294 barrier-policy migration test;
- 20,000 randomized planner cases across realistic caps 1,000,000..99,000,000 and totals up to signed-int32.

## Acceptance boundary
Pass297 is STATIC/REGRESSION ACCEPTED as the current implementation candidate. It is NOT yet stock-client runtime accepted because this backend package intentionally does not contain the external ~1 GiB recovered `local_assets/res` corpus required to build and exercise the full corrected 1.631.3 bootstrap here.

Last runtime-smoked backend remains Pass294.0 for provenance. Pass297 should be the next deployment/test candidate.

## Next gate
Perform one clear-data stock-client reconciliation with the exact current recovered resource corpus. Expected sequence:
1. startup reconciles active barrier to 1.631.3;
2. server builds/verifies/publishes corrected 1.631.3 using float32-exact <=99,000,000-byte shards;
3. MID2 routes 1.631.0 directly to 1.631.3;
4. client downloads all volumes without synthetic `(7,0)`, validates assembled size/MD5, unpacks, restarts;
5. client receives fresh cumulative silent 1.631.4;
6. only after runtime-stable acceptance does project sequencing move to Identity / Session / Concurrency Audit research.

If a new stock-client anomaly appears, stop broad implementation changes and perform targeted source/native/backend research against that exact anomaly before adapting the design.
