# Pass205 — P2 Stage A Foundation Implementation Report

## Decision

Pass205 implements **Stage A only** of the Pass204-approved Awakening/Blood-Awakening roadmap. The backend advances to **v0.20.0 / Pass205.0** while externally visible P2 lifecycle behavior remains protected. Stage B is not started.

## Implemented foundation

- Added immutable, recursively frozen `AwakeningSourceCatalog` generated from the effective `src_64` corpus. The shipped JSON is byte-reproducible from source and preserves the approved route census.
- Added `AwakeningStateV2` with lazy v1→v2 migration, per-type activation generations, bounded transition/terminal replay records, event-entitlement storage, and reserved Pet type 3 without implementing Pet gameplay.
- Added pure `AwakeningProjectionBuilder` for source-confirmed `awake_mission_`, `twice_awake_mission_`, `pet_awake_mission_`, `twice_awake_stage_`, and `extra_drops_` response shapes. These remain projections, never persistence authority.
- Added side-effect-free ordered `DerivedMutationRuleRegistry` and wired it exactly once before canonical MutationPlan validation/application. **No rules are registered in Stage A**, so settlement semantics remain unchanged.
- Added canonical whole-dictionary replacement persistence for `awakening_state` and reserved `occult_state`, preventing stale nested state resurrection during generation rollover/clear.
- Kept the existing `AwakeningMissionService` as the sole mission owner and composed the new catalog/state/projection primitives through `RequestServices`; no shadow Awakening state owner was introduced.

## Deliberately unchanged

The known-stale Pass74 outward lifecycle is intentionally preserved in Stage A. Activation/completion/Give Up/composition/equipment/Campaign/Blood/Occult behavior and fence retirement belong to later authorized stages. No Occult derived rule is registered. No Pet implementation is pulled forward.

## Source reality check

Effective source remains `app-assets/output/assets/src_64`, exactly **4,370 files**. Pass205 verifies **26 planning-critical source files** by SHA256 and regenerates `data/awakening_source_catalog.json` byte-for-byte. Census reproduced: ordinary 465 rows (164 stage1, 164 stage2, 137 auxiliary) with 131 Campaign + 22 Occult + 11 event routes; Blood 162 rows (81 stage1, 81 stage2) with 74 Campaign + 7 event routes. No contradiction with the Pass204 architecture was found.

## Regression gate

Pass205 Stage-A selftests and source verification pass. The selected foundation/economy/projection/temporal/Hero/Pass74 regression suites pass, as do Pass179 P0 and Pass187–193 P1 reconciliation suites, including Pass192 6/6 and Pass193 3/3. Historical tests whose embedded expectations already fail on untouched Pass193 remain baseline-stale and are not rewritten to manufacture a green result.

## Next gate

After Pass205 artifact + passmap sealing, the next authorized implementation step is **Stage B — composition + activation/Give Up + event entitlements + Wish Bottle**. Stage B must begin from this sealed artifact and continue cross-checking effective `src_64`.
