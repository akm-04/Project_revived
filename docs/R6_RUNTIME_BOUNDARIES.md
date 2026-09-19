# R6 Runtime Boundaries

R6 closes only the repaired-foundation operational seams required before R7.
It does not claim full I11 operations, automatic bearer-key rotation, or
multi-replica realtime HA.

## Bearer derivation keys

New MID1 gameplay credentials use the configured active `GXB_DERIVATION_KEY_ID`.
Runtime adapters resolve a persisted `derivation_key_id` through the typed
`BearerKeyResolver`; a retained verify-only key may therefore validate/rederive
an existing credential. Current production wiring remains the single-key
resolver. Rotation schedule, external secret provider and operator rotation API
remain deferred.

## Realtime ownership

The realtime process holds one PostgreSQL session advisory lock for its process
lifetime. A second process fails startup while that lock is held. This enforces
the currently supported single owner; it is not a distributed lease/fencing or
multi-replica failover claim.

## Transaction evidence

Transaction metrics capture is optional and explicitly bounded. Set both:

- `GXB_TX_METRICS_JSONL=/absolute/path/to/tx-metrics.jsonl`
- `GXB_TX_METRICS_MAX_BYTES=<positive byte ceiling>`

The file is forced to mode `0600`. Once the configured byte ceiling would be
exceeded, the sink stops appending. Records contain only the pre-approved
bounded transaction labels (`profile`, `phase`, `outcome`, `sql_class`) and do
not contain player/account/operation/receipt/semantic identities. R6 does not
invent an operator retention size; the byte ceiling must be supplied when the
sink is enabled. Full telemetry export/aggregation remains a later I11 concern.
