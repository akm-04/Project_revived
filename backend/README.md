# GXB backend v0.37.6 — Pass248.0

Pass248 completes **Emblem I6 integration/hardening** static/regression acceptance and prepares the exact I7 stock-client test plan. No new Emblem feature route is introduced. A sealed-design gap is corrected: MID1400 Forge and MID1401 Reforge now require at least one canonical Blood-stage-3, level-100 Hero before any catalog/cost/RNG/state work, while Function45 remains guide-sensitive state rather than authorization and already-paid MID1405/MID1406 proposal recovery remains available. OTA remains **1.631.22**.

## Pass248.0 — Emblem I6 Integration & Hardening

- Current effective 4,370-file `src_64` remains authoritative and regenerates `emblem_source_catalog.json` byte-identically (`083f3d70767d5a97e6bdfb2984480658184455d36e5c74e8d44fa2445fd5d6e4`).
- Fixed the Pass240 global operational-gate requirement omitted by I4/I5: Forge/Reforge require at least one Blood-stage-3 Hero at level >=100. Function45 is not authorization. Save/Abandon stay recovery-safe for already-paid pending proposals if eligibility later disappears.
- Durable player-load maintenance now normalizes server-only `emblem_state`; Hero `inscript_items` is normalized to the current dense concrete-ID array, historical position maps migrate without inventing ownership, and new inserts fail closed on unknown/duplicate physical positions while removal remains a recovery path.
- Structured `runtime_logs/emblem_events.jsonl` records only aggregate policy/proposal/counter evidence for I7 and never leaks internal state into stock response payloads. MIDs 1400-1407 are classified as the `emblem` runtime domain.
- Integration loops cover Campaign Star/Heart-fragment acquisition anchors, MID1407 exchange -> Forge -> equip -> remove/dissolve, exact Heart MID83 compose -> Lv7 Forge, Scholarship physical positions/set compatibility, and all 14 source-present non-forge Honor artifacts remaining excluded from generation pools.
- Dedicated I6 validation is 11/11; controlling I5 12/12, I4 7/7, I3 6/6, I2 7/7, I1 6/6, architecture/ROS/P2/Blood/cleanup/popup-revert/edge regressions remain green. Historical route-fence assertions superseded by I4/I5 remain explicitly non-controlling.
- Rejected Blood completion `common_alert` remains absent; Occult MID2385 stays fenced; no nonce/receipt retrofit is added; `emblem-v1` outer Lv7 Scholarship rate remains **STRONG_INFERENCE + COMPATIBILITY_POLICY**, never official-server math.
- **Runtime status:** I6 is static/regression accepted. I7 has not been executed. See `PASS248_EMBLEM_I7_STOCK_CLIENT_TEST_PLAN.md`.
- **Next:** I7 stock-client Emblem acceptance; after success, Institute Alchemy.

# GXB backend v0.37.5 — Pass247.0

Pass247 completes **Emblem I5 Reforge** static/regression implementation. Stock MID1401 proposal generation, MID1405 Save, and MID1406 Abandon now use the Pass244 `EmblemOutcomePlanner`, independent Reforge pity counter, frozen/latest-proposal state, canonical `MutationSettlementService`, and one `PlayerUnitOfWork`. Current effective `src_64` remains authoritative; the `emblem-v1` Lv7 Scholarship outer gate remains an explicitly replaceable **STRONG_INFERENCE + COMPATIBILITY_POLICY**, not recovered official server mathematics. OTA remains **1.631.22**.

## Pass247.0 — Emblem I5 Reforge

- **SOURCE_FACT:** MID1401 sends `{item_id, rebuild_num=1|10, cost_type=1|2}`; `cost_type=1` is Crystal and `cost_type=2` is Mana. Costs are the source row's `change_crystal` or `change_gold`, multiplied by the requested count.
- Server preflights source-medal ownership and the complete Mana/Crystal cost before any RNG, Reforge pity mutation, or proposal replacement. This is authoritative even for the stock Crystal branch, whose client-side insufficient-funds alert does not prevent the request from being sent.
- Accepted MID1401 is nonce-less: every repeated accepted request is another paid proposal. Generation is sequential for 10x, Reforge pity evolves across all ten outcomes, and the latest proposal atomically replaces the previous pending proposal. The original medal remains owned until Save.
- MID1405 accepts only a candidate from the latest frozen proposal. It performs no entropy and does not reinterpret the candidate under a newer policy; it atomically debits one original medal, credits the selected candidate, clears pending state, and returns stock-shaped `rebuild_items=[{table_id,item_num}]` without generic stack-credit double projection.
- If the original medal disappears before MID1405, the server rejects the Save and durably clears the stale proposal so reacquisition cannot resurrect it. Superseded candidates and repeated Save after success fail closed.
- MID1406 clears the current pending proposal with no refund or inventory mutation; repeated abandon with no pending proposal is a successful no-op.
- Current-source Emblem catalog rebuild remains byte-identical (`083f3d70767d5a97e6bdfb2984480658184455d36e5c74e8d44fa2445fd5d6e4`) across all 4,370 effective `src_64` files.
- Static/regression validation: dedicated I5 12/12; still-controlling I4 7/7, I3 6/6, I2 7/7, I1 6/6; Pass129 architecture 5/5; Pass110 ROS; P2 Stage-G; Blood MID867; cleanup; popup-revert; Pass232 edge/recovery. Historical route-fence assertions superseded by I4/I5 are excluded explicitly, not reinterpreted as failures.
- **Runtime status:** I5 is static/regression accepted only. Stock-client runtime acceptance remains I7 after I6 integration/hardening.
- **Next:** I6 Emblem integration/hardening, then I7 stock-client acceptance.

# GXB backend v0.37.3 — Pass244.0

Pass244 completes **Emblem I3 RNG/policy/pending-proposal foundation**. The internal `emblem-v1` compatibility ladder, source-weighted generated-candidate planner, independent Forge/Reforge miss counters, reforge current-result exclusion, strict frozen-proposal validation and latest-proposal-wins persistence are active internally. Public MID1400/1401/1405/1406 remain fail-closed until I4/I5. OTA remains **1.631.22**.

# GXB backend v0.37.1 — Pass242.0

Pass242 completes **Emblem I1 deterministic reconciliation**. MID1402/1403/1404/1407 now route through the single `EmblemService` owner and use the current-source concrete medal position map, fixing Scholarship equip/remove while preserving existing ordinary dissolve/Star-exchange behavior. MID1400/1401/1405/1406 remain fail-closed. OTA remains **1.631.22**.

# GXB backend v0.20.0 — Pass205.0

Pass205 begins **P2 Awakening/Blood-Awakening implementation** with the planning-frozen Stage A foundation only. It introduces an immutable effective-`src_64` Awakening source catalog, generation-aware `awakening_state` schema v2, pure stock-response projection helpers, bounded transition/terminal replay memory, canonical whole-aggregate persistence semantics for Awakening/future Occult state, and a generic side-effect-free derived-mutation-rule registry wired into canonical settlement. **No derived rules are registered and no P2 endpoint lifecycle is opened or corrected in this stage**; the old Pass74 outward behavior and existing mutation fences remain unchanged until their authorized implementation stages. OTA remains **1.631.12 / 142 entries**.

## Pass205.0 — P2 Stage A Foundation

- `data/awakening_source_catalog.json` is reproducibly generated from effective `src_64` and preserves the exact 465 ordinary / 162 Blood mission corpus plus the 131 Campaign + 22 Occult + 11 event ordinary and 74 Campaign + 7 event Blood route partitions.
- `AwakeningSourceCatalog` recursively freezes all source rows and metadata; compatibility policy and mutable player state are deliberately excluded.
- `AwakeningStateV2` lazily migrates Pass74 schema-v1 state, reserves Pet type 3 without implementing Pet behavior, allocates activation generations, and retains bounded recent transition/terminal replay payloads.
- `awakening_state` and reserved `occult_state` are complete server-owned JSON aggregates with canonical replacement semantics, preventing stale nested state resurrection.
- `AwakeningProjectionBuilder` centralizes the source-confirmed `awake_mission_`, `twice_awake_mission_`, `pet_awake_mission_`, `twice_awake_stage_`, and `extra_drops_` wire shapes without becoming persistence authority.
- `DerivedMutationRuleRegistry` is invoked exactly once before MutationPlan validation/application. Stage A registers zero rules, so canonical settlement behavior is unchanged; the future Occult stamina rule is not activated early.
- The existing `AwakeningMissionService` remains the single mission owner and now consumes the new source/state/projection foundation. Its known-stale Pass74 lifecycle is intentionally preserved for Stage A and will be corrected only in the authorized later stages.
- `tools/verify_pass205_src64.py` validates all 4,370 effective-source files by census, the 26 planning-critical source/protocol hashes, and byte-equivalent regeneration of the source catalog. `tools/selftest_pass205_p2_stage_a_foundation.py` covers source immutability, state migration/generations/replay, persistence replacement, projection shapes, empty derived-rule wiring, and outward behavior neutrality.

# GXB backend v0.19.6 — Pass193.0

Pass193 reconciles the second **P1-I5 stock-client smoke**. Courses, Bookshelf progression, and restart persistence are runtime-clean after Pass192. Cabinet research itself persisted correctly, but MID1078 returned only learned sparse skills while the stock client dereferences every skill in the completed book. Pass193 fixes that wire contract only: durable Cabinet storage remains sparse, but MID1078 now returns the complete per-book skill map with explicit zero levels for unlearned nodes. P1 remains runtime-open for one focused Cabinet re-smoke. OTA remains **1.631.12 / 142 entries** and P2 Awakening/Blood-Awakening stays HTTP409 fail-closed.

## Pass193.0 — P1-I5 Cabinet Wire Reconciliation

- **RUNTIME_OBSERVED:** the second stock-client smoke produced exactly two Cabinet Lua errors and two subsequent HTTP409 retries for skills already persisted by the server; Courses and restart state were otherwise clean.
- **SOURCE_FACT:** `EventCentre:speedUpSkill()` iterates every skill returned by `cabinetBookTable:skillId(book_id)` and directly reads `response.book_info[tostring(skill_id)].lev`. A missing zero-level entry therefore crashes the stock client.
- MID1078 now emits the complete skill map for the affected book, including `{lev=0}` for unlearned nodes; replay uses the same complete wire shape.
- Canonical `workshop_state.book_info` remains sparse and authoritative. GET_CABINET_INFO remains source-shaped/sparse, so no shadow persistence representation was introduced.
- The observed `JunkChestWindow.lua` failure is a cascade from the same incomplete MID1078 response, not a second persistence defect.
- Effective source also confirms the Workshop dependency spine observed at runtime: Bookshelf is Cabinet-gated, Cabinet is Recycle-Bin-gated, and Recycle Bin reciprocally gates on Cabinet. That broader building dependency chain is recorded for later research/design rather than silently expanded inside this bugfix.
- `tools/selftest_pass193_p1_i5_cabinet_wire_reconciliation.py` covers complete-book MID1078 wire shape, idempotent replay, and preservation of sparse durable/GET state.

# GXB backend v0.19.5 — Pass192.0

Pass192 reconciles the first **P1-I5 stock-client smoke**. It fixes three runtime-proven Course/Shop compatibility defects, adds source-generated Cabinet ordinary-book composition needed for Workshop testing, and gives only the anonymous sandbox a one-shot source-bounded Workshop QA material seed. P1 remains runtime-open pending the patched Workshop/Course re-smoke. OTA remains **1.631.12 / 142 entries** and P2 Awakening/Blood-Awakening stays HTTP409 fail-closed.

## Pass192.0 — P1-I5 Runtime Reconciliation

- Stage3 bootstrap now includes MID2137 `GET_STUDY_INFOS`, matching `SelfPlayer.loadGameStartInfoEvent_()` → `Course:setStudyInfos()` and preventing first-entry `roomInfo.study_infos` nil crashes.
- Shop payload now supplies the fields `Shop:onShopInfo_()` consumes for Course Shop type 29 while retaining legacy aliases.
- Course proficiency keeps source max 1680. Stock runtime can submit a final whole item crossing the cap; compatibility policy now consumes it and clamps the durable result to 1680 instead of HTTP409. Exact original overflow semantics remain unrecovered.
- The Workshop source catalog now reproducibly includes all 40 Cabinet ordinary-book fragment recipes extracted from effective encoded `item.lua`.
- MID83 composition has a bounded Cabinet-book path through existing UoW/settlement/inventory/economy owners; Introduction is source-exact `140001001 x20 -> 130001001`, with no broad MID83 rewrite.
- Anonymous sandbox only receives a one-shot minimum of 51,390 Magic EXP plus 20 Introduction fragments for P1-I5 Workshop QA. No building/research level is spoofed and consumed material is never replenished.
- Existing P1/P0/Horcrux architecture regressions remain green. P1 runtime closure still requires stock-client re-smoke of the corrected Course entry/bookstore/proficiency surfaces and Workshop upgrade/research lifecycle.

# GXB backend v0.19.4 — Pass190.0

Pass190 completes **P1-I4 Workshop** by adding the Cabinet research lifecycle on top of Pass189's Event Centre building/Bookshelf foundation. MID1059/1060/1061/1078/1079 now use source-shaped nested Cabinet state, existing PlayerUnitOfWork/MutationSettlement/Economy/Inventory/Hero owners, and the Pass186 finite-job/acceleration utilities. No scheduler, parallel Workshop database, or new transaction framework is introduced. OTA remains **1.631.12 / 142 entries**.

## Pass190.0 — P1-I4B Cabinet Research

- `workshop_state.book_info` is normalized to the effective-client wire authority `book_info[book_id][skill_id].lev`; the unused older flat placeholder is migrated monotonically rather than shadowed.
- MID1059 returns all 54 Cabinet book keys and canonical `cabinet_info` (`cur_learn_skill`, `need_time`, `start_time`, `recent_complete_skill`) while private cost snapshots remain server-only.
- MID1060 validates source book ownership, book-star ≤ Cabinet level, target level bounds, the exact prerequisite graph, source cost family/target-level vector, Skill Page costs, and the one-running-research invariant.
- Research duration comes from the source target-level time vector minus the current Cabinet `cut_time`; zero/negative duration completes immediately, otherwise the existing `DurableTimedJobPolicy` owns RUNNING/READY math.
- Natural READY jobs are lazily materialized exactly once, then project the new level to an owned matching Girl through the existing typed `SET_CABINET_SKILL_LEVEL` Hero mutation. `recent_complete_skill` remains until MID1079 confirmation.
- MID1078 uses the shared source-exact Event Centre acceleration curve, returns book-specific nested `book_info`, and uses state-based replay protection against duplicate Crystal charge while completion is pending confirmation.
- MID1061 preserves the frozen Workshop compatibility policy: ordinary resources refund `floor(original_cost * remaining / total)` from an immutable start-time snapshot; a Skill Page is fully returned only when cancelling before completion. READY/completed work receives no refund.
- The Skill Page refund is persisted through canonical inventory ownership while the response exposes `return_skillpage`, matching the client's explicit Backpack update path and avoiding generic reward projection.
- Global Cabinet learning remains authoritative even if its Girl is not currently owned; Hero `skill_book_info` is only the projection. Existing flat/Hero state migrates monotonically into the nested global authority.
- Effective-src_64 reality check found no architectural contradiction. The exact original ordinary-resource cancellation formula and original server timer-expiry materialization timing remain unrecovered and explicitly compatibility/implementation policy.
- `tools/selftest_pass190_p1_i4b_cabinet.py` covers source catalog/wire shape, learn/prerequisite/single-job rules, speed, cancellation/Skill Page returns, READY completion, Hero projection, migration, restart persistence, building payload reconciliation and all five Cabinet routes.

# GXB backend v0.19.3 — Pass189.0

Pass189 begins **P1-I4 Workshop** with a deliberately bounded first slice: the shared Event Centre building lifecycle and Bookshelf projection. MID1056/1057/1058/1077/1080 now reuse the existing `building_list`, `PlayerUnitOfWork`, `MutationSettlementService`, scalar economy owner, typed Hero mutations, `DurableTimedJobPolicy`, and `EventCentreAccelerationPolicy`. Cabinet skill research MIDs remain deferred to the next Workshop pass. OTA remains **1.631.12 / 142 entries**.

## Pass189.0 — P1-I4A Event Centre Buildings + Bookshelf

- Mutable P1 building types are bounded to Cabinet (1) and Bookshelf (4); other Event Centre building mutations fail closed as deferred rather than receiving invented logic.
- Upgrade costs, timers and prerequisites are read from the **current** source level row exactly as `EventCentreUpgradeWindow.lua` does. Building `lev` remains unchanged while a timer is running.
- Natural READY completion is lazy on MID1056: level increments once, timer clears, `new_evolve=1`, and the persisted cost snapshot is retired. MID1080 confirms/clears `new_evolve`.
- MID1077 uses the recovered Event Centre three-band Crystal acceleration curve and completes immediately. Replay against already-completed/pending-confirm state does not charge twice.
- MID1058 uses the frozen Workshop cancellation compatibility seam `floor(original_cost * remaining / total)` against an immutable start-time cost snapshot. READY/completed jobs are not refundable.
- Bookshelf completion projects the new level to every owned Normal Girl through existing typed Hero mutations. A newly acquired Normal Girl inherits the account Bookshelf level through the Pass186 ordered Hero-creation initializer; Super Girls do not.
- Cabinet building upgrades honor the recovered Trash prerequisite exactly. Because Trash implementation is outside current P1 scope, the default account can source-correctly progress Cabinet 1→2 but further upgrades remain gated until the prerequisite exists.
- `tools/selftest_pass189_p1_i4a_workshop_buildings.py` covers source rows, wire shape, cost/timer lifecycle, replay, speed, proportional cancellation, prerequisites/deferred building types, Bookshelf projections, restart persistence and routing.

# GXB backend v0.19.2 — Pass188.0

Pass188 completes **P1-I3 Courses/Electives** on top of the Pass186/187 P1 foundation. All deterministic Course lifecycle MIDs now use the existing Hero Course arrays, `study_infos`, PlayerUnitOfWork and MutationSettlementService. The unrecovered original study-progress formula remains isolated behind the frozen +20 compatibility policy; recommendation selection is safe-empty and Gift Box awards fail closed instead of inventing server RNG. OTA remains **1.631.12 / 142 entries**.

## Pass188.0 — P1-I3 Courses

- Source-generated Course data now also captures the effective 8-hour timer, 200-Crystal forget cost, 30 speed coefficient, four proficiency-item values, six quality thresholds and exact source-defined forgetting refunds.
- MID2128 APPLY_COURSE consumes the class application item once and acquires the Course without starting a room timer. Duplicate retries are no-op successes.
- MID2131 STUDY is the first-time acquire+8h study path; MID2142 CONTINUE_STUDY resumes an existing incomplete Course without a second application-item spend.
- READY study jobs are lazily materialized by MID2129 GET_COURSE_INFO (or explicit completion action): exactly one +20 compatibility-policy increment, then the room row is removed. MID2130/2137 polling does not auto-complete.
- MID2132 SPEED_STUDY uses the exact client Crystal formula `30 * ceil(remaining/1800) / 2`; replay after completion does not charge twice.
- MID2133 binding enforces the source-open Course skill slots 1–4 and one Course per skill slot. MID2140 consumes source proficiency items and derives quality from recovered thresholds.
- MID2134 forget charges 200 Crystal and returns the exact source `object_book_color.lua` book items atomically; duplicate forgetting is a no-op.
- MID2135/2136/2138 room enter/leave/cancel and VIP `num_study` capacity are durable and restart-safe.
- MID2500 recommendation returns a deliberate safe-empty list because original server selection is unrecovered. MID2139 exposes `is_has_gift=0`; MID2141 Gift Box award generation returns HTTP409 `course_gift_box_awards_deferred`.
- `tools/selftest_pass188_p1_i3_courses.py` covers source constants, acquisition, five-step completion, speed/cancel/capacity, binding, proficiency/quality, forgetting/refunds, replay semantics, persistence, routing and safe unknowns.

# GXB backend v0.19.1 — Pass187.0

Pass187 completes **P1-I2 White Album + Element Equipment retrofit** on top of the Pass186 shared foundation. White Album MID72/2784/2785 now has durable source-shaped ownership without server-side stat invention; Normal-Girl Element Equipment now enforces the recovered Common gate, slot-type rules and SP-Core lineage while reusing the existing HeroAdvancedProgressionRepository/UoW implementation. The separate Super Element lane and the P2 Awakening/Blood-Awakening HTTP409 fence remain untouched. OTA remains **1.631.12 / 142 entries**.

## Pass187.0 — P1-I2 White Album + Element Equipment

- MID72 validates owned Hero lineage and monotonically persists all currently satisfied `collect_quality_stage` / `collect_star_stage` thresholds through the existing typed Hero mutation/UoW path. Duplicate retries are successful no-ops.
- MID2784 returns the durable 23-slot special-collection vector; MID2785 validates all required owned Girl IDs and persists effective type-1 claims. Effective `collect_special.lua` has 23/23 type-1 rows, so no reward RNG is introduced.
- Awakened Normal Girls resolve to their source origin for Album claims; Super IDs remain themselves so mixed special sets remain claimable.
- Normal-Girl Common eligibility now requires player level at server `max_lev`, Hero color 16, and every ordinary non-Awakening/non-Blood-Awakening promotion slot collected.
- Element slot 1 accepts Core/SP-Core only; slots 2–4 accept Normal only; SP-Core partner restriction resolves against the Girl's first/origin table ID.
- MID2853 backpack decomposition remains outside the Hero/Common gate. The separate source Super Element path is preserved rather than narrowed in this Normal-Girl retrofit.
- MID72's old mutation-firewall block is retired because the endpoint now has durable ownership.
- `tools/selftest_pass187_p1_i2.py` covers Album lineage, special sets including Super IDs, restart persistence, Common gating, slot/SP-Core invariants, Super-lane preservation, dispatcher routes and firewall state.

# GXB backend v0.19.0 — Pass186.0

Pass186 begins the approved P1 implementation roadmap with **P1-I1 Shared foundation only**. It adds effective-`src_64` generated immutable source catalogs for Courses, White Album, Workshop and Element Equipment; shared finite-job and Event Centre acceleration policies; the semantic VIP Study-room limit; additive P1 state normalization/migration; typed Hero P1 mutations; and a deliberately narrow ordered Hero-creation initializer seam. Existing PlayerUnitOfWork, MutationSettlementService, HeroRepository and canonical wire-facing fields remain authoritative. No P1-I2/I3/I4 business lifecycle is activated yet, no new RNG/transaction framework is introduced, and the P2 Awakening/Blood-Awakening HTTP409 fence is untouched. OTA remains **1.631.12 / 142 entries**.

## Pass186.0 — P1-I1 Shared Foundation

- Four generated source-only JSON catalogs reproduce Pass184's effective-source corpora exactly: 4 subjects / 12 classes / 48 Courses / 6 quality rows; 132 normal + 23 special White Album rows; 100 Bookshelf / 6 Cabinet / 54 books / 399 Cabinet skills; and 80 Element Equipment rows / 11 strengthening rows.
- `DurableTimedJobPolicy` provides stateless IDLE/RUNNING/READY, elapsed/remaining/progress mechanics for finite P1 jobs; no scheduler or persistence authority is introduced.
- `EventCentreAccelerationPolicy` mirrors effective `EventCentre.getUpgradeCost()` exactly.
- `VipPrivilegeResolver.study_room_limit()` exposes source `vip.lua.num_study` semantically.
- `P1FoundationStateNormalizer` repairs the old `GET_STUDY_INFOS` compatibility shape to `study_infos`, adds only missing server-only White Album/Workshop slices, monotonically reconciles Bookshelf authority, and derives Cabinet global learned state only from source-valid Hero `skill_book_info`.
- `HeroCourseStateAdapter` plus eight bounded Hero ENTITY verbs establish typed P1 mutations without arbitrary dictionary patching.
- `HeroCreationInitializerRegistry` is an ordered new-Hero projection seam attached to `HeroRepository.add_owned_hero()`; it is intentionally not an event bus and has no registered domain initializer until the Workshop wave.
- `RequestServices` and maintenance composition now share the P1 catalogs/state contracts. Business handlers remain deferred to P1-I2/I3/I4.
- `tools/selftest_pass186_p1_i1_foundation.py` validates source census, finite-job math, VIP room limits, legacy migration idempotence, typed mutations, initializer behavior and request composition.

# GXB backend v0.18.1 — Pass183.0

Pass183 is the runtime-acceptance and release-identity closure for Girls/Gear P0. Stock-client smoke against Pass182 completed without observed gameplay issues: deterministic Girl Gear Pack settlement worked, MID57/MID51 promotion stayed synchronized at/above the server `max_color` boundary, Fumo persistence/restoration behaved correctly across restart, and Awakening/Blood-Awakening promotion attempts hit the intended HTTP409 fail-closed fence. No gameplay behavior changes are introduced in Pass183. The only backend edit is correcting the stale runtime version banner from Pass179 identity to this Pass183 artifact identity. OTA remains **1.631.12 / 142 entries**.

## Pass183.0 — Girls/Gear P0 Runtime Closure

- Runtime evidence SHA256: `3c79bf1d6cc2639060bc296b77d8623290f078c6d42c2fea72666d2385ed4bec`.
- User smoke notes report Tiffany Gear Pack deterministic awards, further pack openings, synchronized two-step promotion when the client exposes Max, successful Fumo enhancement persistence across restart, and restoration on MID51.
- Server logs show repeated successful MID57/MID51 sequences plus repeated HTTP409 `awakening_equipment_promotion_deferred` blocks for both MID57 and MID51 at the special-equipment boundary.
- P0 is runtime accepted/closed. Next work is P1 research only: Subjects/Courses → White Album normal claim/persistence → Workshop Bookshelf/Cabinet → Element Equipment preconditions/runtime closure.
- Runtime banner identity self-healed; gameplay code remains byte-identical to Pass182 outside `gxb_backend/version.py` and release documentation/metadata.

Pass182 implements the source-shaped MID57/max_color reconciliation authorized after Pass181 research. Effective `NormalHero.oneKeyPowerUp` has two successful transitions: below server-fed `maxHeroColor`, MID57 performs the real promotion and bounded Fumo restoration; at/above that boundary, MID57 consumes/composes the same required ordinary gear atomically but only marks the current tier collected, preserving color/Fumo so MID51 performs the actual promotion. The inherited `max_color=5` remains an explicit compatibility value because the original numeric server policy is still unrecovered; the separate absolute Hero color ceiling remains 16. Pass179's Awakening/Blood-Awakening P2 HTTP409/no-mutation fence is preserved.

For client QA only, the anonymous sandbox receives a one-shot exact-quantity normalization of all 199 source-derived Girl Gear Pack item stacks to quantity 7. This runs after older broad QA seeds and never replenishes consumed packs on later logins. No credential/production-account economy semantics are changed. OTA remains **1.631.12 / 142 entries**.

## Pass182.0 — MID57/max_color Runtime Reconciliation

- `HeroEquipmentRepository.one_click_promote()` now branches on `hero.color < player.max_color`. Below threshold it retains the existing `PROMOTE_COLOR` + Fumo restoration settlement. At/above threshold it uses the existing `SET_EQUIP_SLOTS` mutation for the current missing ordinary slots, returns successful `restore_items=[]`, leaves color/Fumo untouched, and relies on MID51 for the real promotion.
- The existing absolute `MAX_COLOR=16` rejection and P2 special-equipment fence remain unchanged. No Awakening implementation was pulled forward.
- `debug_guest_girl_gear_pack_seed_pass182.json` + `MultiUserDatabase._apply_pass182_debug_girl_gear_pack_seed()` implement the dev-only 199-pack quantity-7 convenience as a one-shot sandbox migration.
- `tools/selftest_pass182_mid57_reconciliation.py` covers below/threshold/above MID57 branches, threshold MID51 restoration, 15→16 terminal behavior, color16 no-mutation rejection, P2 HTTP409 preservation, and exact/non-replenishing 199-pack dev normalization.

Pass179 implements P0 of the Girls/Gear economy foundation after the Pass173–178 research/planning cycle. It extends existing canonical owners rather than creating a parallel Girl economy: ordinary NormalHero promotion can now restore source-shaped Fumo materials through the existing MutationSettlementService/PlayerUnitOfWork transaction; MID1407 exchanges all held Emblem materials into the existing certificate ledgers; and all 199 deterministic `gift.equip` Girl Gear Packs materialize into ordinary InventoryGrant rewards through GiftOpeningService → RewardTransactionService. Awakening/Blood-Awakening promotion remains explicitly deferred and is transport-blocked with HTTP 409 when the current stage contains persistent special equipment. OTA remains **1.631.12 / 142 entries**.

## Pass179.0 — P0 Girls/Gear Economy Foundation

The Fumo restoration source catalog is generated from effective `src_64` and keeps source facts (200/60/10 materials plus quality return coefficients) separate from compatibility policy. `FumoRestorationPlanner` applies the frozen V1 aggregate-rational → floor-once → source-order greedy decomposition policy. Ordinary equip is no longer incorrectly fenced merely because a Hero has nonzero Fumo; promotion itself performs restoration atomically with the Hero color transition.

MID1407 `EXCHANGE_MATERIALS` is owned by the existing advanced/Inscription repository. It consumes all held source materials 50001343/50001344/50001345 and credits `degree_cer` / `graduate_cer` / `patent_cer` at the source-shaped 5-per-item mapping in one UoW transaction.

The former 199-operation `SOURCE_INCOMPLETE_EQUIP_FIELD` Gift lane is now a deterministic compatibility-materialization seam. `GearPackMaterializer` builds the Girl-specific cumulative equipment corpus through the recovered selector, preserves ordinary multiplicity, deduplicates repeated persistent Awakening/Blood-Awakening item identities, and emits standard InventoryGrant objects. No ROS, new inventory ledger, or new reward authority is introduced.

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

## Pass225 operator logging

Run `python3 server.py`. Console output is automatically captured in `runtime_logs/server.txt`. Set `DEBUG_VERBOSE` near the top of `server.py` (1 basic/errors, 2 + window probes, 3 + successful resource HTTP, 4 all), or override once with `--debug-verbose`. Structured JSONL logs are never filtered. See `docs/OPERATOR_LOGGING.md`.


## Pass227 Blood MID867 wire reconciliation

Pass227 is a server-only compatibility correction based on clean stock-client runtime evidence. Blood MID867 now accepts the stock empty-Lua-table wire encoding `npc_ids={}` and the prior semantic-empty `[]` characterization, while still rejecting missing/null/scalar/nonempty values. The rule is scoped to Blood Awakening; ordinary Incubus shares MID867 and is not globally normalized. OTA remains `1.631.20`.

## Pass241.0 — Emblem I0 Foundation

Pass241 starts the sealed Pass240 Emblem implementation roadmap without activating public forge/reforge RNG. It packages a deterministic current-src64 Emblem source catalog and composes `EmblemSourceCatalog`, `EmblemPolicyRegistry`, `EmblemOutcomePlanner`, durable `EmblemStateRepository`, and a cohesive `EmblemService` inside the existing `RequestServices`/`PlayerUnitOfWork` graph. `player.domains.emblem_state` is a canonical-replacement server-only aggregate; Hero `inscript_items` remains the sole equipped-medal authority. Public MID1402/1403/1404/1407 routing remains on the accepted Pass232 owner for I0, while MID1400/1401/1405/1406 remain fail-closed. OTA remains `1.631.22`.


## Pass243.0 — Emblem I2 Eligibility + Function45 + Heart

Pass243 adds source-correct Emblem eligibility and Function45 reconciliation without opening Forge/Reforge RNG. MID1402 Insert now requires canonical Blood stage3 + Hero level100; MID1403 Remove remains recovery-safe. Function45 is announced through normal `new_funcs_` only when a qualifying Hero exists and is repaired on maintenance for historical accounts. MID83 gains the exact source Heart recipe `50001347 x60 -> 50001346` with zero Mana through the existing provider seam. MID1400/1401/1405/1406 remain fail-closed. OTA remains 1.631.22.


### Pass246 Emblem I4
MID1400 Forge is now implemented server-side with source-defined certificate/Heart cost preflight before RNG/pity mutation and atomic UoW settlement. MID1401/MID1405/MID1406 remain fail-closed. OTA remains 1.631.22.
