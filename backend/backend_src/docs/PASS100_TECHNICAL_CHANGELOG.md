# Pass100.0 — MID97 OTA bridge and exactly-once Energy purchase

Pass99 is runtime accepted from the supplied smoke. Pass100 implements the final mapped stamina-purchase seam without changing Daily Reset ownership, VIP progression, Monthly Privilege lifecycle, Campaign settlement, or consumable behavior.

## OTA preservation bridge

The cumulative MID2 package advances from resource `1.631.3` to `1.631.4`. All 126 Pass99 overrides remain byte-identical; two new files are added: `src_32/app/model/AddEnergy.lua` and `src_64/app/model/AddEnergy.lua`.

The canonical AddEnergy source remains unchanged except for the request body. Each user click captures:

- `expected_buy_energy_times = selfPlayer.buyEnergyTimes`
- `energy_day_id = floor((ServerTime + 10800) / 86400)`
- `energy_op_id = p100-energy-{day}-{expected}-{xyd.generateUUID()}`

`Backend.lua` retries the same params table, so a lost-response retry preserves the UUID. A legitimate later click calls `xyd.generateUUID()` again and therefore receives a different operation identity. Source-day and expected ordinal remain explicit authorization guards; UUID prevents daily/clock-rollback key reuse.

## Backend MID97 settlement

`EnergyPurchaseService` owns the MID97 operation boundary while delegating resources to their existing owners:

- Crystal debit → `EconomyLedger`
- Energy +120 → `TemporalPolicyService`
- purchase allowance → `VipPrivilegeResolver` plus active Monthly Privilege +4
- daily counter → existing `buy_energy_times`, still reset by `DailyResetCoordinator` at 05:00 GMT+8
- retry identity → durable `PlayerUnitOfWork` receipt

For a new purchase the server requires the patched identity, validates source day and expected counter, enforces allowance, materializes Energy and rejects a new purchase at Energy >=500, resolves the nth source Crystal cost, and commits Crystal debit + Energy credit + counter increment + receipt atomically.

A committed receipt is checked before current-day/current-counter guards. Thus a retry of a committed request remains read-only even if it arrives after a reset boundary. Replay projects current cumulative state instead of stale settlement totals. Unpatched empty MID97 remains fail-closed.

## Source-generated purchase metadata

`tools/build_energy_purchase_meta.py` regenerates `data/energy_purchase_source_meta.json` from effective `src_64` and records source hashes. It captures +120 Energy, the 500 pre-purchase threshold, Monthly Privilege +4, and all 20 reachable purchase costs (VIP15 16 + privilege 4).

## Safety invariants

- A network retry can never charge twice for the same UUID.
- A legitimate next click is not swallowed as a retry.
- Daily ordinal reset does not collide with prior-day receipts.
- Current Energy 499 may become 619; current Energy 500+ cannot start another source purchase.
- Durable commit failure rolls Crystal, Energy, counter, and receipt back together.
- MID97 does not decrement Monthly Privilege card days or modify VIP state.
- The existing Daily Reset remains sole owner of the 05:00 `buy_energy_times=0` restoration.
