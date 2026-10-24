# CA4-3B Stage 0 Design Checkpoint

Basis: sealed Pass546 CA4-3B research closure and frozen implementation contract.

Status: MECHANICAL DESIGN CHECKPOINT — implementation may proceed under the standing user authorization unless a documented reopen trigger fires.

## Frozen additive seams

1. I5 strict prepared restoration
   - new opaque Prepare/Apply surface; does not change accepted `TxHeroEquipmentResourceDebiter` semantics.
   - nonempty Grant plan only; receipt precheck + under-lock recheck; canonical Grant/Mail/Stack closure; one-shot Apply.

2. I5 Hero promotion resources
   - new Prepare/Apply surface for MID57 only.
   - caller supplies complete potential stack closure plus optional precomputed restoration plan.
   - lock suffix after Hero410: optional Mail610 -> Economy700 -> PlayerProgression710 -> Mana720 -> canonical Stack722.
   - bounded planning snapshot exposes only PlayerLevel, Mana, and prepared stack quantities.
   - Apply requires exact debit subset of prepared closure and may acquire no new lock/content/identity.

3. PlayerProgression max-color preservation policy
   - immutable/nonlocking compatibility provider, value 5, deterministic nonempty revision.
   - same provider feeds MID17 `max_color`, Character value port, and MID57 policy provenance.
   - no persisted max-color column and no MID122 activation.

4. Character promotion receipt
   - branches MID51_PROMOTE, MID57_PROMOTE, MID57_COLLECT.
   - outer Character receipt remains sole ambiguous-COMMIT authority.
   - stores resulting Hero state, restore rows, optional mana_after, state version and relevant policy provenance; does not duplicate I5-owned debit authority.

5. MID49 roster view
   - application read view carries durable Hero + six derived Fumo levels.
   - capture `HeroCoreActive()` once and use exact-revision content lookups.
   - projection stays pure; raw Fumo remains the only durable Fumo authority.

6. CA4-3B restoration content
   - capability `HERO_PROMOTION_RESTORATION_CA4_3B`.
   - source-owned eligible equipment/quality rows, quality fractions, and denomination value/order only.
   - restoration decomposition remains separately versioned compatibility policy.

## Non-negotiable invariants

- Normal Hero only; absolute color ceiling 16.
- MID57 requires at least one missing ordinary slot and complete/all-or-nothing planner success.
- Promotion clears ordinary equipment/Fumo and preserves special equipment/Fumo.
- Hero state version increments exactly once per successful MID51/MID57 operation.
- No foreign-owner SQL, no lock inversion, no late Mail acquisition.
- Nested restoration receipt can never prove the outer Hero transition.
- Activity1016, MID122, MID29, MID54/MID62 production registration, Pet reset, Super, user skill persistence, and I8 durability remain deferred.

## Implementation order

A. immutable restoration content + PlayerProgression max-color policy
B. I5 strict restoration / promotion resource transaction seams
C. Character MID51/MID57 domain/application/receipt/recovery
D. MID49 derived Fumo reload projection + production wiring
E. focused tests, race/vet/static/architecture/oracle checks, bounded regression, independent postimplementation reality check

No product-source implementation changes existed before this checkpoint.
