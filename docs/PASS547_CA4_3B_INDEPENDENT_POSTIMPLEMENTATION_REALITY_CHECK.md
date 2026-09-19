# Pass547 CA4-3B Independent Postimplementation Reality Check

Status: **GREEN — CA4-3B LOCAL ACCEPTANCE / COMPATIBILITY_COPY_ONLY EXECUTABLE PROOF; CA4 NATIVE AGGREGATE GATE DEFERRED**

Authority parent: sealed Pass546 CA4-3B research/implementation contract, its 70/70 preimplementation independent check, the Stage0 design checkpoint, and the user's standing implementation authorization. Product parent is accepted v0.70.1 archive SHA-256 `439ae89d888bb92abf99d2a7eddaeae0eb086749383049d4d8d4052d7eb30653`, implementation revision `d914e320bfc3e58e9d2ec5b7362d7e7b5ae858d1fb5093285372ecb81263d31c`.

## Independent reread findings

1. Current `src_64` still fixes MID51 POWERUP_HERO and MID57 ONE_CLICK_JINJIE to partner-only requests and the implemented branches reproduce the recovered stock behavior rather than frozen-V1-only predicates.
2. Promotion clears only ordinary equipment/Fumo and preserves qualifying special/Awakening equipment/Fumo. The source topology validation prevents silent identity transfer across colors.
3. MID57 remains all-or-nothing across every missing ordinary current-tier slot; no partial MID62-style success was imported.
4. Below the qualified `max_color` policy MID57 directly materializes the final promoted state; at/above the cap it collects ordinary gear without color/Fumo reset.
5. `max_color=5` remains an explicitly versioned PlayerProgression compatibility decision, not historical server truth. MID122 remains unactivated.
6. Base restoration source facts are immutable/revision-owned. The floor/greedy decomposition remains a named compatibility policy; Activity1016 behavior remains outside CA4-3B.
7. I5 owns resource/Grant settlement and closes one canonical lock union. CharacterHero contains no foreign-owner SQL.
8. Strict restoration rechecks the nested semantic receipt before locking, after waiting under locks, and before Apply; a pre-existing nested receipt without the outer Hero transition fails closed.
9. Hero mutation is cohesive and advances StateVersion exactly once. No intermediate fully-equipped/promotion state is persisted.
10. The outer Character Hero receipt is the sole ambiguous-COMMIT authority. Receipt absence after ambiguous COMMIT remains UNKNOWN and the body is not blindly rerun.
11. Same-operation replay is branch-safe. MID51 cannot consume MID57 receipt branches and MID57 cannot consume MID51 branches.
12. MID49 now projects six derived `fumo_levels` for every Normal Hero from durable raw Fumo using one exact active immutable revision; no second durable Fumo-level authority was introduced.
13. MID57's sparse stock response uses receipt-carried `ManaAfter`; no postcommit scalar read can convert an already-committed action into a projection-read failure.
14. Production activation is exactly MID51/MID57 in addition to previously qualified Hero routes. MID54/MID62 and MID122 remain unregistered.
15. No Activity1016 implementation leaked into CharacterHero; the accepted restoration modifier seam remains the future extension boundary.
16. Migration `00022_ca4_3b_hero_promotion_restoration.sql` and the new immutable content revision are forward-only and registered under existing content ownership.
17. Canonical `.go-version`, `go.mod`, and `go.sum` remain byte-identical to the accepted parent pins.
18. Exact canonical execution is ENVIRONMENT_BLOCKED because the sandbox has Go 1.23.2 and cannot fetch pinned Go 1.27.1. This evidence is not promoted to native proof.
19. Fresh disposable compatibility-copy execution is GREEN for focused tests, race, vet, broad internal regression and PostgreSQL adapter unit packages.
20. The independent postimplementation checker revalidated source hashes, source/content facts, lock/receipt rules, transition semantics, projection/reconnect behavior, production routes, deferrals, no-foreign-SQL boundaries and canonical pins: **143/143 GREEN**.

## Verdict

**GREEN for CA4-3B local phase acceptance under COMPATIBILITY_COPY_ONLY executable constraints.** No source contradiction, ownership violation, replay/recovery defect, content mismatch or unauthorized route leakage was found. CA4-3B may be sealed locally and the next internal frontier may advance to **CA4-4A Pet Equipment (MID783 PET_EQUIP / MID792 PET_ONE_KEY_EQUIP) preimplementation research/reconciliation**.

This does **not** close parent CA4. Exact Go 1.27.1, real PostgreSQL/River accumulated semantics and the already-authorized native CA4 aggregate gate remain mandatory at `CA4_AGGREGATE_PRE_CA4_E_NATIVE_WORK_GATE`. W2 physical unmodified-stock-client proof also remains open.
