# Pass99.0 Technical Changelog

## Scope

Bounded Global Economy cleanup: reconcile Pass98 runtime evidence, repair only the proven MID117 sweep input-cost leak, source-bound a one-shot QA consumable seed for UID `13371337`, and finish the MID97 retry-safety research. No RandomOutcomeService, random gift settlement, Monthly Privilege lifecycle, Store expansion, or new Girls/Equipment behavior.

## Runtime reconciliation

The Pass98 smoke proves MID27 Kanto Food and MID1404 certificate settlement are functioning. It also corrects the reported Campaign diagnosis: normal battle MID114 already spends Energy. The trace shows Kanto Food responses at cumulative Energy 105, 123, 141, and 159, followed by MID114 stage `1300016` returning cumulative Energy 148. Backend source metadata gives that stage `energy_cost=12`; the battle settlement already goes through `TemporalPolicyService`.

The actual leak is MID117. Both 10× and 1× `SWEEP_CAMPAIGN` calls returned successful reward arrays without any persisted Energy input cost.

## MID117 Campaign sweep cost closure

Effective source establishes:

- `MapDetailWindow.lua` / `NewMapDetailWindow.lua`: require `player.energy >= campaign:energyCost(campaignID) * sweepNum`.
- `enums.lua`: `ITEM_SWEEP=1`, `CRYSTAL_SWEEP=2`.
- `SweepWindow.lua`: after successful ITEM_SWEEP, remove Raid Ticket `50001013` × `sweep_num` locally.
- Map detail code falls back to CRYSTAL_SWEEP only after checking `sweep_num <= player.crystal`, proving one Crystal per sweep.

Live MID117 now runs in one `PlayerUnitOfWork` and submits one `MutationPlan` containing:

1. `TemporalTransition("energy", "DEBIT", campaign.energy_cost * sweep_num)`;
2. either `StackMutation(50001013, "DEBIT", sweep_num)` or `ResourceMutation("crystal", "DEBIT", sweep_num)`;
3. the already-existing deterministic source sweep reward Stack CREDITs.

If any input is insufficient, the entire transaction rolls back. Response projection publishes cumulative Energy/Crystal from the committed semantic journal. The normal MID114 path is intentionally untouched.

The existing multi-sweep entitlement from Pass96 is retained: more than one sweep requires source VIP `quick_sweep` or active Monthly Privilege. This pass does not change Campaign repeat reward RNG or claim complete MID117 architecture; retry-safe random outcomes remain downstream of `RandomOutcomeService`.

## Developer QA seed

Added data-driven one-shot migration `pass99_debug_qa_consumables_seed_v1`, only for account UID `13371337`.

Targets:

- Raid Ticket `50001013`: 900 (source cap 9999)
- Fries `50001014`: 90 (source cap 99)
- Kanto Food `50001015`: 90 (source cap 99)
- Tonkatsu `50001016`: 90 (source cap 99)
- magic consumables `50001120..50001131`: 900 each (source cap 999)

The migration may add/raise only those explicitly authorized rows on first application. Once its marker is committed it never replenishes consumed inventory. `ItemStackLimitCatalog` remains the hard upper bound.

## MID97 ADD_ENERGY research decision

MID97 is **not implemented** in Pass99.

Source contract is clear:

- `AddEnergy.lua` sends `ADD_ENERGY` with `{}`.
- Successful response supplies `buy_energy_times`.
- nth price = `refreshCost:buyEnergyCost(buyEnergyTimes + 1)`.
- purchase allowance = VIP `num_energy` plus Monthly Privilege row1 `num_energy=4` while privilege is active.
- each purchase grants 120 Energy (source VIP/add-energy UI contract).
- client prevents purchase above global `energyMaxLimit=500`.
- Pass79/83 Daily Reset already resets `buy_energy_times` at 05:00 GMT+8.

But source networking can retry the same request. Since the MID97 request contains no operation ID, nonce, expected ordinal, or other distinguishing state, after purchase N commits an identical next request is ambiguous between:

1. replay of purchase N after its response was lost; and
2. the user's legitimate purchase N+1.

A permanent request receipt cannot solve this because there is no request identity; time-window/state dedupe would suppress legitimate sequential purchases. Pass99 therefore fails closed rather than introducing a double-charge or false-deduplication bug.

Recommended next design: a narrow source-preservation OTA bridge that supplies an operation identity/expected purchase ordinal, followed by an exactly-once UoW settlement using EconomyLedger Crystal debit, TemporalPolicyService +120 Energy, `buy_energy_times`, VipPrivilegeResolver, and DailyResetCoordinator ownership.

## Validation status

Focused Pass99 tests, Python compileall, and the historical regression spine through Pass98 pass. Exact packaged-artifact/fresh-extraction validation is performed before release. Client runtime acceptance remains pending.
