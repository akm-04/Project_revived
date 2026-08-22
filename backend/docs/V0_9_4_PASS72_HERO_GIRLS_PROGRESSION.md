# Pass72.0 — Hero/Girls Progression + Gear/state preservation

Status: **STATIC_ACCEPTED_RUNTIME_PENDING**. Pass71.0 is runtime accepted from the 2026-08-22 user smoke.

## Scope
Pass72 activates the frozen Pass65 `ENTITY` MutationPlan family for the ordinary Hero aggregate. It remains a Strangler-Fig migration: existing protocol/transport/persistence façades stay available, but migrated Hero operations now settle their costs and canonical Hero state inside one `PlayerUnitOfWork`.

## Migrated operations
- MID39 `SET_ALL_SKILL_LEVEL`: RESOURCE Mana + TEMPORAL Skill Point + HERO `UPGRADE_SKILLS`.
- MID51 `POWERUP_HERO`: ordinary color promotion through typed HERO state ownership.
- MID52 `EVOLVE_HERO`: Girl fragment STACK + Mana RESOURCE + HERO `EVOLVE_STAR`.
- MID53 `SET_SKILL_LEVEL`: TEMPORAL Skill Point + HERO `UPGRADE_SKILLS`.
- MID54 `SET_HERO_EQUIP`: equipment/material STACK settlement + HERO `SET_EQUIP_SLOTS`.
- MID55 `USE_EXP_ITEM`: EXP-item STACK + HERO `ADD_EXP`.
- MID57 `ONE_CLICK_JINJIE`: source-derived equipment/composition/Mana/EXP potion plan + HERO `PROMOTE_COLOR`.
- MID62 `ONE_CLICK_EQUIP`: source-derived equipment/composition plan + HERO `SET_EQUIP_SLOTS`.
- MID63 `USE_EXP_ITEMS`: multiple EXP-item STACK debits + one HERO `ADD_EXP`.

## MID52 bug fix
Effective `star.lua`/`StarTable.lua`/`HeroMainWindow.lua` establish ordinary evolution costs. Pass72 now debits both the Girl's own fragments and Mana atomically with the star transition. Cumulative Mana projection is inherited from Pass70; submitted fragments are not projected back because `SelfPlayer:evolveHero` removes them locally after OK.

## ENTITY journal semantics
`HeroEntityMutationService` supports only bounded verbs: `EVOLVE_STAR`, `ADD_EXP`, `SET_EQUIP_SLOTS`, `PROMOTE_COLOR`, and `UPGRADE_SKILLS`. Arbitrary Hero dictionary patches are not accepted. ENTITY journal rows intentionally carry no generic projection tags to avoid double-applying the client-local Hero reconciliation.

## Sandbox inventory seed
For anonymous debug UID `13371337` only, a one-shot PRIVATE_SERVER_POLICY migration raises **839** source-referenced Hero equipment/material/EXP-potion IDs to at least **1000**. The persistence marker `pass72_debug_hero_inventory_seed_v1` prevents replenishment after consumption. Credential accounts are not seeded.

## Deliberate exclusions
- `AWAKE_HERO`: effective `SelfPlayer.lua` references the symbol, but effective `mid.lua` supplies no numeric MID. Fail closed; do not invent protocol.
- SuperHero/post-5 evolution: distinct source semantics; deferred.
- Advanced awakened/bloodline/Fumo restoration: deferred.
- Campaign 6-Energy settlement: belongs to Campaign migration, not Hero progression.

## Source reality check
The effective source remains exactly 4,370 files (62 downloaded winners + 4,308 app winners), hash-identical to the frozen Pass57 fingerprint.
