# Pass111.0 Technical Changelog — MID50 RNG Migration

## Scope

Pass111 migrates **repeatable MID50 only** from legacy retry/RNG plumbing onto the Pass109/110 frozen operation-identity, UoW receipt/replay, and RandomOutcomeService architecture. It intentionally leaves Campaign/MID117, MID70 Magic, MID305 Super Summon, and unrelated RNG domains outside scope.

## Source-native OTA identity bridge

Effective `src_64` confirms one direct `Backend.request(xyd.mid.SUMMON_HERO, ...)` choke point: `app/model/SelfPlayer.lua::summonHero()`. Pass111 generates cumulative OTA resource version `1.631.5` from canonical `src_32`/`src_64` source and injects:

```lua
arg_137_1 = arg_137_1 or {}
if not arg_137_1.summon_op_id or arg_137_1.summon_op_id == "" then
    arg_137_1.summon_op_id = "mid50-" .. tostring(xyd.generateUUID())
end
```

The field is never overwritten. Effective `Backend.lua` stores the same params table in `pendingRequests` and passes that same table back to `webRequest_()` on retry. Therefore one legitimate click has one operation identity across transport retries.

The OTA builder verifies all 128 prior sparse overrides remain byte-identical before adding two `SelfPlayer.lua` overrides; the cumulative package contains 130 files.

## MID50 identity and fingerprint

New `gxb_backend/state/mid50_operation_receipt.py` validates strict `mid50-<UUIDv4>` identities. Missing identity remains distinguishable from malformed identity so historical tutorial one-shot handling can coexist with repeatable-ID enforcement.

The canonical request fingerprint is SHA-256 over compact sorted JSON:

```json
{"protocol_mid":50,"schema_version":1,"summon_index":N,"summon_type":N}
```

The operation ID itself is excluded from the fingerprint.

## Durable UoW receipt contract

Repeatable MID50 receipts use:

- domain: `mid50_summon`
- mode: `CLIENT_UUID_V4`
- retention: `CLIENT_UUID_PERMANENT`
- key: normalized `summon_op_id`
- request fingerprint: canonical MID50 tuple digest

A committed receipt is checked before state normalization/mutable eligibility and again inside the `PlayerUnitOfWork` transaction before cost or entropy. Reusing one UUID with another tuple fails closed.

Costs, RNG outcome materialization, Summon counter/pity state, inventory/Hero mutations, replay payload, and receipt commit are staged in the same UoW transaction.

## Static response vs live projection replay

The receipt persists exact committed non-cumulative response fields under `static_response`. `economy_` and `summon_info` are deliberately excluded. `projection` instead records which economy keys were returned and whether `summon_info` was present.

On retry:

1. exact committed static result/reward rows are deep-replayed;
2. entropy is not called;
3. costs and counters are not applied again;
4. current player economy values are attached for the recorded keys;
5. current `SummonStateContract` projection is attached when applicable.

This prevents a lost-response retry from rerolling while also preventing stale absolute economy envelopes from rewinding the client.

## RandomOutcomeService adapter migration

`RequestServices` now binds the existing planners to the Pass110 request-scoped ROS through `NamespacedRandbelowAdapter`:

- Classic Vending pool: `summon.classic.pool`
- Classic Vending balance: `summon.classic.balance`
- Medium Legacy: `summon.medium_legacy`
- SX/Soul Box: `summon.sx`

The underlying policy implementations are unchanged.

## Legacy retry compatibility

`SummonOperationReceiptStore` remains unchanged for historical deterministic tutorial one-shot operations.

`PaidSummonOperationReceiptStore` is no longer used anywhere in repeatable MID50. Its single remaining repository use is MID70 Magic Summon, which has not yet received a source-native operation identity.

## Explicit unchanged-policy proof

Pass111 self-tests pin Pass110 hashes for the Summon policy/catalog/counter/cost/result files and the Classic/Medium/SX policy modules. All remain byte-identical.

## Next

Campaign repeat reward completion / MID117 remains next. It must receive a focused source/policy audit before random dropbox selection is implemented; missing pools and unrecovered official probability normalization remain fail-closed negative memory.
