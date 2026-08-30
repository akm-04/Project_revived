# Pass248.0 — Emblem I6 Integration & Hardening

## Result

**PASS_STATIC_REGRESSION.** I6 adds no new Emblem feature surface. It closes integration gaps across the already-open MID1400/1401/1402/1403/1404/1405/1406/1407 lifecycle and prepares structured evidence for I7 stock-client acceptance. OTA stays **1.631.22**.

## SOURCE_FACT / sealed-design checks

- Current effective `src_64` remains 4,370 files and regenerates `data/emblem_source_catalog.json` byte-identically at SHA-256 `083f3d70767d5a97e6bdfb2984480658184455d36e5c74e8d44fa2445fd5d6e4`.
- Function45/current Hero source gates Emblem UI by Blood Awakening + Hero level >=100; Function45 is guide-sensitive state, not server authorization.
- Campaign source catalog provides all three Star items and Heart fragment; MID1407 converts Stars at 5 points each; exact MID83 Heart recipe is 60 fragments -> 1 Heart, 0 Mana.
- 254 concrete medals remain partitioned as 210 ordinary forge candidates + 30 Scholarship set pieces + 14 source-present non-forge Honor artifacts.
- Scholarship set pieces use concrete physical positions; the 14 Honor artifacts are valid existing/equip/dissolve content but are absent from generation pools.

## Defect found and bounded correction

Pass240 I2 design required a **global Forge/Reforge operational gate** in addition to per-Girl equip eligibility. I4/I5 had opened MID1400/MID1401 without enforcing it. Reproduction on the sealed Pass247 backend showed a no-Hero account with enough certificate material could successfully Forge.

Pass248 corrects only this gap:
- MID1400 and MID1401 now require at least one canonical Blood-stage-3, level-100 Hero before catalog/cost/entropy/state work.
- Function45 is deliberately ignored as authorization.
- MID1405 Save and MID1406 Abandon are not gated: already-paid pending proposals remain recoverable if eligibility later disappears.

## Hardening

- Player-load maintenance now normalizes server-only `emblem_state` through the same source/policy repository contract as request composition, preserving future-schema fail-closed behavior.
- Hero `inscript_items` is normalized to the current stock dense concrete-ID array; historical position maps are migrated without inventing/deleting source ownership.
- New insertions fail closed if existing equipped Emblems contain unknown or duplicate physical positions. Removal remains available as a recovery path rather than destructively repairing valuable legacy state.
- Runtime domain classification now identifies MIDs 1400-1407 as `emblem`.
- `runtime_logs/emblem_events.jsonl` records only aggregate policy version, proposal generation/pending count and Forge/Reforge miss counters. It never enters protocol responses and intentionally omits candidate IDs/inventory/cost payloads.

## Integration validation

Dedicated Pass248 I6 matrix: **11/11**.

Covered:
- operational gate pre-entropy/pre-economy and Function45 non-authorization,
- Star exchange -> Forge -> equip -> remove -> dissolve loop,
- Heart fragment -> MID83 Heart -> Lv7 Forge loop,
- 2/3-position Scholarship compatibility and all 14 non-forge artifacts remaining out of RNG pools,
- dense equipment migration and malformed-layout fail-closed insertion,
- durable load-time Emblem-state normalization,
- paid proposal recovery after eligibility loss,
- Campaign acquisition anchors,
- bounded runtime logging separated from wire.

Controlling regressions remain green: I5 12/12; I4 7/7; I3 6/6; I2 7/7; I1 6/6; Pass129 architecture 5/5; Pass110 RandomOutcomeService; P2 Stage-G; Blood MID867 `npc_ids={}`; Pass230 cleanup; Pass231 popup-revert; Pass232 recovery/log rollover. Historical fence-only assertions superseded by I4/I5 remain excluded explicitly.

## Negative memory retained

- Rejected Blood-completion `common_alert` remains absent.
- Occult MID2385 remains deferred/fenced.
- `emblem-v1` outer Lv7 Scholarship ladder remains STRONG_INFERENCE + COMPATIBILITY_POLICY, not recovered official server math.
- No Forge/Reforge nonce/receipt is added.
- No final Girl-stat engine is introduced here; client stat/set presentation is accepted in I7 and cross-system stat closure remains the later Girl-stat capstone.

## Next

**I7 stock-client runtime acceptance.** See `PASS248_EMBLEM_I7_STOCK_CLIENT_TEST_PLAN.md` and `PASS248_I7_CLIENT_TEST_CHECKLIST.json`.
