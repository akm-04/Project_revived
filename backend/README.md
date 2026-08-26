# GXB backend v0.17.5 — Pass172.0

Pass172 records the successful Pass171 stock-client Horcrux restart re-smoke and marks the current Horcrux scope **runtime accepted / closed**. The backend remains authoritative for unique Horcrux identity/storage plus rolled/materialized main/sub stat IDs and values; the stock client consumes those persisted values for Hero attribute/UI calculations, while future authoritative server combat should consume the same values rather than treating them as client-invented. The same smoke sequence exposed a clean Vows gap: Institute → Vows sent source-correct MID305 for Balder and the backend blocked it only because no semantic handler existed. Pass172 adds source-generated Vow acquisition metadata plus MID305 summon and MID306 Vows Essence exchange, reusing HeroRepository, StackInventory and PlayerUnitOfWork. No prerequisite Girls are consumed on summon; initial Vow star equals the number of the five source prerequisites that resolve to a currently exactly-5-star Girl. Existing Vow MID52/MID54/MID304 progression/equipment remains unchanged. OTA remains **1.631.12 / 142 entries**.

## Pass172.0 — Vows Acquisition/Tab Closure

Institute/Vows acquisition now has semantic MID305 and MID306 owners. MID305 returns full `partner_info`, preserves prerequisite Girls, supports awakened counterparts for prerequisite ownership, and is naturally retry-safe by returning an already-owned Vow. MID306 consumes source Vows Essence item 50001666 at 100 per selected Vow scroll and returns ordinary `awards`. A dedicated 8/8 suite covers source facts, Balder dynamic stars, awakened prerequisite semantics, failure atomicity, duplicate retries, durable persistence, essence exchange, and fail-closed dispatcher routing.

## Pass166.0 — Horcrux H1 Foundation

Pass166 begins the accepted Horcrux implementation roadmap without activating
random acquisition, strengthening, equip protocol mutations, or Gods Trial
battle/auto settlement. H1 adds the source-derived `HorcruxSourceCatalog`, the
explicit `horcrux_policy_v1` compatibility registry, unique-instance
`HorcruxRepository` over existing `PlayerState.spirit_list`, server-only
`player.domains.horcrux_state`, six-slot Hero reconciliation, shared service
composition, and a source-shaped MID3101 startup projection. Existing
PlayerUnitOfWork, HeroRepository, TemporalPolicyService, GameDataCatalog and
JSON persistence remain the canonical owners; no parallel inventory/economy/RNG
framework was introduced. OTA remains 1.631.10.

## Pass167.0 — Horcrux H2 Deterministic Lifecycle

Pass167 activates deterministic unique-instance lifecycle operations: lock/unlock,
direct equip/unequip, one-key unequip, and saved collocation CRUD/apply. Hero
`spirit_equip` remains positional authority; Horcrux `is_equip` mirrors the owning
`partner_id`. HOTA-002 corrects client collocation edit bookkeeping. OTA 1.631.11
contains the preserved cumulative client layer plus that bounded patch.

## Pass168.0 — Horcrux H3 Generated Rewards

Pass168 activates source-authorized MID241 type-24 Horcrux rewards without
turning Horcruxes into ordinary stack inventory. `RewardTransactionService` now
contains a narrow registered specialized-owner routing seam; `HorcruxMaterializer`
owns generated-instance schema and `HorcruxRepository` remains the persistence/ID
authority. Gift/dropbox template selection stays Gift-domain owned under
`gift.open`, while Horcrux generation uses only the frozen `horcrux.generate.*`
namespaces. The malformed 9199043 source remains immutable and is resolved only
through the accepted compatibility overlay. HOTA-001 forwards `spirit_awards`
through `SelectEquipWindow`. OTA 1.631.12 contains 142 cumulative overrides.
Horcrux strengthening is activated in Pass169 H4; Gods Trial settlement remains disabled for H5.
## Pass169.0 — Horcrux H4 Strengthening

Pass169 activates MID3089 strengthening without creating a parallel strengthening authority. Fodder validation, source-derived EXP/Mana calculation, level/materialized-main progression, milestone ADD/IMPROVE policy, persistent target replacement, fodder deletion, Mana debit, and permanent exactly-once receipt replay all execute inside the existing PlayerUnitOfWork. Fodder must be owned, distinct, unlocked, unequipped, and absent from saved collocations; the target itself may remain locked/equipped because the recovered client source does not forbid that. Full selected-fodder EXP/Mana cost is honored even when stored target EXP clamps at the level-15 cumulative maximum. Forced/single milestone choices consume no entropy. OTA remains 1.631.12 / 142 cumulative overrides. Gods Trial remains disabled for H5.

## Pass170.0 — Horcrux H5 Gods Trial

Pass170 activates Gods Trial manual and auto state machines, source-day progression and Trial drop settlement. `CampaignType.HUNQI=79` is now a source fact; repeat drop rows use the frozen independent 10,000-scale residual policy; Spirit Energy remains TemporalPolicyService-owned; rewards remain RewardTransactionService-owned. H5 adds no OTA patch. H6 remains the next Horcrux reconciliation/client-smoke phase.

## Pass171.0 — Horcrux H6 Restart Bootstrap Reconciliation

Pass171 removes `spirit_item` from ordinary owned-Hero persistence and MID49 projection. In the recovered client, `spirit_item` is optional semantic cache data: if absent, equipped `spirit_id` values resolve through Backpack; if an empty table is supplied, the cache path is selected and nonzero slots dereference nil after restart. Durable load maintenance now self-heals stale self-Hero cache fields without changing six-slot equipment or unique instances. The regression reproduces KM-Moe's smoke fixture `[7,4,12,1,5,15]`, verifies all six IDs resolve through MID81 `spirit_list`, and verifies a materialized attribute sum remains numeric after restart. No OTA change is required.

