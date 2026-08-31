# Pass297 Stock-Client Reconciliation Gate

Status: **PENDING REAL CLIENT / EXTERNAL RES CORPUS**

Pass297 does not claim a real bulk runtime smoke. The packaged backend does not carry the recovered ~1 GiB `local_assets/res` corpus.

## Deployment test contract
1. Use the exact current recovered `local_assets/res` tree; do not substitute historical v1.164 assets.
2. Start Pass297 with `auto_ensure=true`, `auto_publish=true`, and `max_volume_bytes=99,000,000`.
3. Confirm active `required_initial_barrier` is reconciled to 1.631.3 even if an existing registry still contains immutable 1.631.1/1.631.2 history.
4. Confirm 1.631.3 sidecar and actual shard sizes pass the shared `mid2_compat` verifier; every shard must be float32-exact and all prefixes/total signed-int32-safe.
5. Clear stock-client data and start from current app/resource version 1.631.0.
6. Confirm MID2 advertises only the corrected 1.631.3 barrier for the pre-barrier client.
7. Capture server HTTP requests and client/native diagnostics. Expected `.001..NNN` requests may remain full GETs; do not require `Range` unless new evidence says otherwise.
8. Success criterion for the former defect: all advertised volumes complete, accumulated client byte total equals truthful descriptor size, no synthetic `Failed to load (7,0)`, assembled MD5 succeeds, unzip/restart succeeds.
9. After restart at 1.631.3, confirm MID2 advances to fresh cumulative silent CODE_ONLY 1.631.4 and then reaches no-pending-update state.

If step 8 fails, preserve the exact generated sidecar/shard sizes, server trace, client log/native result tuple, and on-device partial file state. Do targeted research before any further publisher change; do not brute-force shard sizes.
