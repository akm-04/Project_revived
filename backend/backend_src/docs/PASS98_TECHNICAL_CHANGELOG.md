# Pass98.0 Technical Changelog

## Scope

Bounded deterministic consumable implementation only. No MID97, RandomOutcomeService, random gift/chest settlement, Monthly Privilege lifecycle, Store expansion, new Campaign repeat RNG/MID117, or Girls/Equipment expansion.

## Source-authoritative ConsumableEffectCatalog

- Added `tools/build_consumable_effect_meta.py` and generated `data/consumable_effect_meta.json` from effective `src_64/data/tables/item.lua`.
- Provenance is pinned to source SHA-256 `59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc`.
- Catalog: 5,838 source item rows, 2,034 consumables, 22 Energy items, 12 magic items.
- Runtime semantics are operation-scoped rather than generic reward-column interpretation.

## MID27 Energy items

- Existing atomic settlement shape is retained: Backpack Stack DEBIT + `TemporalPolicyService` Energy CREDIT in one PlayerUnitOfWork.
- Effect lookup now uses the source-derived catalog rather than the stale generic GameDataCatalog.
- All 22 source Energy consumables work; Kanto Food `50001015` grants 18 each and Tonkatsu `50001016` grants 30 each.
- Source-compatible Energy overflow above the natural regeneration cap remains legal.
- Invalid item IDs/subtypes/quantities fail closed.

## MID87 magic items

- Replaced the prior empty-success response with atomic settlement.
- The full submitted list is validated before mutation.
- Duplicate item rows are aggregated, input stacks are debited, and source magic resources are credited via EconomyLedger in one UoW.
- Resource selection follows `EventCentreSellWindow.lua`: `magic_energy`, else `magic_dust`, else `magic_liquid`.
- Any invalid/non-magic item fails the request without partial debit or credit.

## MID1404 Inscription resolve mapping

- Repaired `tools/build_hero_advanced_meta.py` so concrete item mapping is completed from every positive `item.lua.inscript_id`.
- Mapping expands from 240 to the source-complete 254 items, including the fourteen Honor variants ending 11/12 across levels 1..7.
- `inscription.lua` remains the resolve-policy authority for `resolve_material` and `resolve_num`; existing certificate settlement is unchanged.
- No generic Emblem EXP currency was invented.

## MID134 safety fence

- `PET_USE_EXP_ITEMS` no longer routes to the generic practice success stub.
- It returns fail-closed until canonical Pet EXP + item settlement exists.
- This prevents a successful response from causing source `Pet:selfDrink()` to delete submitted items without server settlement.

## MID241 boundary

- No MID241 gift/chest settlement was added.
- It remains blocked/fail-closed because source gifts include random-drop semantics and incomplete recovered gift definitions.
- Complete support remains downstream of `RandomOutcomeService`.

## Validation

Pass98 focused self-test, Python compileall, and the historical regression spine through Pass96 pass. Runtime client acceptance remains pending.
