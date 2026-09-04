# v0.18.0 Pass179 — P0 Girls/Gear Economy Foundation

Pass179 implements the approved P0 economy/authority design while preserving the stock client's attribute reconstruction model. The backend does not become a competing aggregate ATK/HP authority; it only completes source-shaped progression/economy inputs.

## Source-derived inputs

Effective source remains `app-assets/output/assets/src_64` (4,370 files). Generated Fumo, ordinary gear, advanced/Inscription and Gift catalogs rebuild byte-identically. Source facts include the Fumo restoration materials and quality coefficients, the MID1407 empty-request exchange surface and material-to-certificate economic mappings, and the 199 deterministic Girl Gear Pack directives.

## Compatibility policies

The original server-side Fumo rounding/decomposition and `gift.equip` expansion parser are absent from recovered client source. Pass179 therefore uses the policies frozen in Pass178:

- `P0_FUMO_RESTORE_V1_AGGREGATE_FLOOR_GREEDY_SOURCE_ORDER`: aggregate exact rational refundable value across lost Fumo, floor once, decompose in source material order 200 → 60 → 10, discard residual below 10.
- `P0_GIFT_EQUIP_V1_CUMULATIVE_SELECTOR_SPECIAL_DEDUP`: materialize cumulative Girl equipment through the source selector, preserve ordinary multiplicity, grant repeated persistent Awakening/Blood-Awakening item identities once.

These are private-server compatibility policy, not claims about unrecovered original-server algorithms.

## Architecture

No new economy or inventory authority is introduced. HeroEquipmentRepository owns ordinary promotion; FumoRestorationPlanner is a pure helper and emits awards settled by the existing UoW. HeroAdvancedProgressionRepository owns MID1407 and uses existing StackMutation/ResourceMutation. GearPackMaterializer is a pure Gift planning helper and emits InventoryGrant objects to the existing RewardTransactionService. RandomOutcomeService is not involved.

## P2 boundary

Effective NormalHero source preserves Awakening/Blood-Awakening equipment selectively across later ordinary promotions. P0 deliberately does not implement that lifecycle. If the current promotion stage contains special persistent gear, MID51/MID57 fail transport-safe with HTTP 409 and no mutation.

## Runtime gate

Static/regression acceptance does not close P0. A stock-client smoke should verify at least one ordinary Fumo-bearing promotion and returned materials, representative MID1407 settlement if materials are available, one Girl Gear Pack, and safe special-stage rejection. OTA remains 1.631.12 / 142 entries.
