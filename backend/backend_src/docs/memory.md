# Backend machine memory — Pass247.0

Canonical implementation: `gxb-backend-v0.37.5-pass247.0`, OTA `1.631.22`.

- Emblem I5 Reforge is implemented/static-regression accepted. Public MID1400 Forge remains the accepted I4 implementation; MID1401 proposal generation and MID1405/MID1406 Save/Abandon now route to the same `EmblemService`.
- Current authority is `all-assest-rechecked-1.zip` effective `app-assets/output/assets/src_64` (4370 files). Historical v1.164 is reference/explicit donor only. The current-source Emblem catalog rebuild is byte-identical to packaged `data/emblem_source_catalog.json`.
- MID1401 stock shape is `{item_id,rebuild_num=1|10,cost_type=1 Crystal|2 Mana}`. Full source ownership and full source-row cost are validated before RNG, pity, or proposal mutation. Accepted repeats are new paid actions because stock wire has no nonce/receipt.
- 10x proposals use sequential Pass244 planner outcomes and the independent Reforge pity counter. The original medal stays owned during proposal generation. Latest proposal wins; generation, source/candidates and policy_version are frozen durably.
- MID1405 has no RNG: candidate must belong to latest pending, original must still be owned, then one atomic UoW swaps original -> selected candidate and clears pending. Response is explicit `rebuild_items=[{table_id,item_num}]`; generic stack-credit projection stays disabled to prevent duplicate client award.
- Stale original on Save rejects and durably clears pending. Superseded candidate/repeated Save fails. MID1406 clears pending with no refund; repeated empty abandon is success/no-op.
- `emblem-v1` Lv7 Scholarship outer rate and 100bp Reforge ladder remain STRONG_INFERENCE + COMPATIBILITY_POLICY, not recovered official server math. Hard pity consumes no gate RNG.
- P2 Ordinary/Blood Awakening remain runtime accepted; rejected Blood completion `common_alert` must never return. Occult MID2385 remains deferred/fenced.
- Validation: I5 12/12; still-controlling I4 7/7, I3 6/6, I2 7/7, I1 6/6; Pass129 5/5; Pass110; P2 Stage-G; Blood MID867; cleanup; popup revert; Pass232 all green. Historical public-fence assertions superseded by I4/I5 are excluded explicitly.
- NEXT: Emblem I6 integration/hardening -> I7 stock-client acceptance -> Institute Alchemy -> Girl-stat capstone -> client UX/loading/resource cleanup -> Mail/GM transport -> PvP-class systems. Deferred: KongMing Books I-IV/all-skill, Occult MID2385, Pet Awakening, optional Treasure/Daily Scholarship/Auction acquisition integrations.

# Backend machine memory — Pass242.0

Canonical implementation: `gxb-backend-v0.37.1-pass242.0`, OTA `1.631.22`.

- Emblem I1 deterministic ownership is implemented/static accepted. Live MID1402/1403/1404/1407 handlers route to `EmblemService`; HeroAdvanced only has historical direct-call delegation shims.
- Current src_64 `InscriptionTable:getItemPos` is authority: ordinary row `item_pos` first, then concrete Scholarship lookup through `inscription_pos.lua`. Generated `EmblemSourceCatalog.physical_position()` covers all 254 medals and fixes the old Scholarship `item_pos=0` rejection.
- MID1402 empty insert is free; replacing the same physical slot costs 20 Crystal and returns the old medal. MID1403 removal costs 20 Crystal. Dense Hero `inscript_items` remains canonical.
- MID1404 resolves every current-source medal, including 30 Scholarship pieces and 14 Honor artifacts, into scalar certificates 19/20/21 using source `resolve_num`. Scholarship families resolve to Specialty/patent currency.
- MID1407 consumes all held Star items 50001343/344/345 and credits degree/graduate/patent certificates at 5 per item; empty action is successful no-op.
- Stock client callbacks mutate returned/consumed medal Backpack state locally; Pass70 generic response projection must not synthesize STACK awards.
- MID1400/1401/1405/1406 remain fail-closed. Function45/eligibility and Heart composition remain I2; RNG/pending proposal remains I3+.
- Validation: dedicated I1 7/7, source catalog byte-exact rebuild, Pass129 5/5, Pass70, Pass212, Pass227, Pass230, Pass231, Pass232 all green. Old Pass241 route-hash neutrality is intentionally superseded by authorized I1.
- NEXT: I2 eligibility + Function45 reconciliation + exact Heart MID83 provider; keep public RNG fenced.

# Pass241 Emblem I0 foundation

- Executable lineage: Pass232 accepted runtime + Emblem I0 foundation only; OTA remains 1.631.22 and no client payload changed.
- Current-src64 Emblem/Inscription source facts are packaged as `data/emblem_source_catalog.json`, rebuilt deterministically by `tools/build_emblem_source_catalog.py` from exact source-evidence bytes. Census: 23 forge rows, 254 concrete medals, 210 ordinary candidates, 30 Scholarship pieces, 14 Honor non-forge artifacts, 12 sets.
- New domain foundation reuses existing architecture: `EmblemSourceCatalog`, versioned `EmblemPolicyRegistry` (`emblem-v1`), `EmblemOutcomePlanner` over request-scoped `RandomOutcomeService`, durable `EmblemStateRepository`, and cohesive `EmblemService`. No parallel inventory/economy/Hero/RNG authority was introduced.
- `player.domains.emblem_state` is server-only complete aggregate state and a canonical replacement path, so clearing a pending rebuild cannot resurrect nested data during persistence merges. Equipped medals remain only in Hero `inscript_items`; no Hero-state migration.
- I0 deliberately does not activate Emblem server RNG. `scholarship_gate()` is disabled and consumes no entropy. MID1400/1401/1405/1406 remain the existing fail-closed route; MID1402/1403/1404/1407 remain on the accepted Pass232 implementation until I1.
- Current source evidence for the Emblem tables/model/windows is byte-copied from `all-assest-rechecked-1.zip` effective `src_64`; historical corpus is not used as runtime authority.
- Validation: Pass241 I0 self-test, Pass129 architecture hygiene, Pass212 P2 Stage-G, Pass227 Blood MID867, Pass230 sandbox cleanup, Pass231 no-popup corrective OTA, and Pass232 event/log rollover all pass.
- NEXT: Emblem I1 deterministic ownership reconciliation: move MID1402/1403/1404/1407 under `EmblemService`, use concrete dynamic Scholarship positions, preserve accepted dissolve/Star-exchange wire/economy semantics, and keep public RNG MIDs fenced.

# Pass224 current memory

- Pass212 is restored as the clean client/runtime control baseline. Pass219-223 historical-CSB/window/downloader/loading/Incubus-adapter experiments are rejected for the next smoke.
- Ordinary terminal Hero Awakening keeps exact current local Hero mutation but presents stock `common_alert`; runtime accepted (`awake_terminal_after_open_result`).
- Reproduced Blood MID54 UI bug is a current-client cache/projection defect already predicted in Pass207: displayed Blood substitute did not inherit canonical slot collected state and callback removed the ordinary Awake item instead of the displayed Blood item. Pass224 fixes only that local cache/display behavior; server MID54 still keeps durable Blood stage=1 and MID161 advances stage2.
- Stock current `AwakeTwiceSelectTeamWindow` is authoritative and supports 16 total Heroes. Pass212 had no Blood UI/resource override and user confirms its Blood battle UI worked. Historical 2.0.8 Blood CSBs must never shadow bundled stock physical resources.
- Pass224 OTA 1.631.19 is Pass212 cumulative Lua + exactly two paired source overrides (`TaskAwakeCell`, `NormalHero`), 146 members, zero resource members. No LazyDownloader/Backend/window/preload/TaskAwake-art/Blood-adapter hacks.
- CLEAN DEVICE STATE IS REQUIRED before runtime: sparse prior OTAs do not delete stale writable files. Use `adb shell pm clear com.carolgames.gxb`, then relaunch prepared APK and install OTA1.631.19.
- Next gate: verify Blood gear UI, stock 16-Hero selector, MID866 and battle. Capture MID867 after battle before changing Stage E; Pass212 control reported post-battle task completion bug but clean wire evidence is still pending.

# Pass192 current memory

- First P1-I5 stock-client smoke is reconciled, but P1 is **not runtime closed**. Courses core lifecycle, normal White Album, and Common/Element paths produced positive runtime evidence; Workshop mutations were blocked by missing QA materials.
- Runtime-proven backend defects fixed: stage3 omitted bootstrap MID2137 Study-room hydration; Course Shop type29 response lacked fields required by `Shop:onShopInfo_`; Course proficiency rejected the stock client's legal 1650 + 50 crossing of source max 1680.
- Terminal proficiency crossing policy is explicit COMPATIBILITY_POLICY/STRONG_INFERENCE: consume the submitted whole source item and cap durable exp at 1680. Exact original overflow behavior is UNKNOWN. Existing completed-study +20/100 policy remains unchanged.
- Cabinet ordinary-book MID83 composition is now source-enumerated only (40/54 books) and reuses canonical UoW/MutationSettlement/inventory/economy owners. Other MID83 families remain unchanged.
- Anonymous sandbox one-shot Workshop QA fixture raises missing magic_exp to 51390 and fragment140001001 to20 only; it does not advance/replenish progression and never applies to credential accounts.
- Effective source remains app-assets/output/assets/src_64, 4370 files. P2 Awakening/Blood-Awakening HTTP409 fence, Workshop refund compatibility policy, and max_color=5 compatibility value remain preserved.
- NEXT: patched stock-client P1-I5 re-smoke. Verify Electives first-entry/bookstore/terminal proficiency plus Workshop Bookshelf upgrade/speed/confirm/restart and Cabinet craft/learn/speed/cancel/confirm/restart. If clean, close P1 and advance to P2 research/planning only.

# Pass190 current memory

- P1-I4 Workshop is now IMPLEMENTED/static-regression accepted: Pass189 I4A owns Event Centre building lifecycle + Bookshelf; Pass190 I4B owns Cabinet research MID1059/1060/1061/1078/1079. P1-I5 cumulative regression + stock-client smoke/reconciliation is next.
- Cabinet canonical global wire state is nested `workshop_state.book_info[book_id][skill_id].lev`; Hero `skill_book_info` remains only a projection. Legacy flat placeholder/Hero learned levels migrate monotonically.
- Cabinet source gates: book item owned, book star <= Cabinet level, prerequisites at least target level, source target-level resource vector/Skill Page, one active research. Duration is source skill time minus Cabinet cut_time.
- Natural completion is lazy/idempotent server materialization (implementation policy consistent with client timer UI); speed uses source-exact Event Centre Crystal curve. `recent_complete_skill` fences replay until MID1079 confirm.
- Cancellation ordinary-resource refund remains explicit COMPATIBILITY_POLICY `floor(cost * remaining / total)` from immutable cost snapshot; Skill Pages return fully only before READY. Original-server refund formula remains UNKNOWN.
- Dedicated Pass190 I4B suite 7/7; Pass189 I4A, Pass188 Courses, Pass187 Album/Element and current P0/Vows/Horcrux/Gods Trial/architecture gates remain green. Pass186's old flat-book-info/empty-initializer assertions are superseded by Pass189/190 source-shaped state.
- P2 Awakening/Blood-Awakening HTTP409 fence remains untouched. NEXT: P1-I5 cumulative regression + stock-client smoke/reconciliation; do not begin P2 before P1 runtime closure.

# Pass189 current memory

- P1-I4 Workshop is PARTIAL, not closed. I4A Event Centre building core + Bookshelf is implemented/static-regression accepted; Cabinet skill research is the next bounded slice.
- MID1056/1057/1058/1077/1080 now have semantic Workshop ownership. Existing `building_list`, UoW, MutationSettlement, EconomyLedger, typed Hero mutations, DurableTimedJobPolicy and EventCentreAccelerationPolicy remain canonical.
- Supported mutation building types in P1 are Cabinet=1 and Bookshelf=4; other Event Centre building mutations fail closed/deferred.
- Source upgrade semantics: cost/time/prerequisite come from the CURRENT level row; level increments only when the finite job completes; completion sets `new_evolve=1`; MID1080 clears it.
- Bookshelf completion projects to all Normal Heroes. New Normal Hero acquisition inherits current Bookshelf level through the preplanned narrow Hero initializer; Super Heroes remain outside Bookshelf projection.
- Workshop cancellation original formula remains UNKNOWN. Frozen compatibility policy is proportional remaining-time refund using immutable original-cost snapshot.
- Cabinet building source prerequisite remains Trash levels. Do not bypass it or silently implement Trash.
- Dedicated Pass189 I4A suite 7/7; Pass188 Courses and Pass187 White Album/Element regressions 7/7 each; P0/Vows/Horcrux/architecture current regressions remain green. Pass186 foundation's old assertion that initializer registry is empty is superseded by intentional Pass189 activation.
- NEXT: P1-I4B Cabinet skill research (MID1059/1060/1061/1078/1079), then cumulative Workshop/P1 smoke. P2 Awakening fence remains untouched.

# Pass188 current memory

- P1-I3 Courses/Electives is implemented/static-regression accepted on canonical P1-I1 state owners: five Hero Course arrays + `study_infos`; no shadow Course database.
- Effective source facts: 4 subjects / 12 classes / 48 Courses, max four learned Courses per Hero via book-open skills 1–4, fixed Study time 28800s, forget cost 200 Crystal, speed formula `30*ceil(remaining/1800)/2`, proficiency items 10/50/250/1250, six quality thresholds and source-defined forget returns.
- APPLY_COURSE is acquisition-only and consumes one application; first STUDY consumes one application and starts the 8h job; CONTINUE_STUDY resumes known incomplete Courses without another application.
- Course completion is explicit/lazy: GET_STUDYROOM_INFO/GET_STUDY_INFOS preserve READY rows so the client can render ENDED; GET_COURSE_INFO materializes exactly one completion and removes the row.
- Original study-progress formula remains UNKNOWN. Frozen `CourseStudyProgressPolicy` is explicit COMPATIBILITY_POLICY/STRONG_INFERENCE: +20 percentage points per completed study, capped 100.
- Binding is progress=100 only, skill slot 1..4 only, one Course per skill. Proficiency/quality and forgetting/refunds are source-derived and settle atomically through existing MutationSettlement/UoW.
- Recommendation selection remains safe-empty; Gift Box info projects `is_has_gift=0`; Gift Box awards remain HTTP409 fail-closed (`course_gift_box_awards_deferred`) because server reward generation is unrecovered.
- Dedicated Pass188 suite 7/7 plus P1-I1/P1-I2/P0/Vows/Horcrux/architecture regressions pass.
- NEXT: P1-I4 Workshop implementation: shared Event Centre building lifecycle -> Bookshelf -> Cabinet research under Pass185 frozen design.

# Pass187 current memory

- P1-I2 White Album + Element Equipment retrofit is implemented/static-regression accepted.
- White Album normal claims persist source-derived quality/star stages on canonical Hero fields; special claims persist only `white_album_state.special_claims`. Client remains Album stat calculator.
- Effective special corpus is 23/23 deterministic type-1; no Album reward RNG. Awakened Normal lineage collapses to origin; Super IDs remain valid for mixed special sets.
- Normal Common Element gate: player at `max_lev`, Normal Hero color16, all required ordinary slots collected. Slot1 Core/SP-Core; slots2-4 Normal; SP-Core origin restriction. MID2853 remains backpack-only/outside gate.
- Separate Super Element lane preserved; P2 Awakening/Blood-Awakening HTTP409 fence untouched.
- Pass73's old ungated Element test is superseded by source-correct Pass187 gating; current P1-I1/P0/Vows/Horcrux/architecture regressions pass.
- NEXT: P1-I3 Courses implementation under Pass185 frozen policy (`CourseStudyProgressPolicy` compatibility +20 percentage points per completed 8h study; recommendation/Gift Box generation remains deferred/fail-closed).

# Pass182 current memory

- MID57/max_color reconciliation is implemented and statically accepted. Source shape: `color < player.max_color` => real one-click promotion + Fumo restoration; `color >= player.max_color` and `<16` => current-tier ordinary gear collect only, no color/Fumo mutation, MID51 performs actual promotion.
- Numeric `max_color=5` is retained only as inherited `COMPATIBILITY_POLICY`; exact original-server level-100 value/schedule remains UNKNOWN. Do not replace with absolute `MAX_HERO_COLOR=16` without new evidence.
- Pass179 P2 Awakening/Blood-Awakening promotion fence remains HTTP409/no mutation.
- Anonymous sandbox dev fixture normalizes all 199 source Girl Gear Pack item stacks to exactly 7 once, then never replenishes. Credential accounts unaffected.
- Static tests pass; client smoke still required for threshold MID57→MID51/Fumo, representative Purple + Red+1 Gear Pack persistence, and real P2 fence no-mutation/restart before P0 runtime closure/P1.

# Backend machine memory — Pass179.0

Canonical implementation: `gxb-backend-v0.18.0-pass179.0`.

- P0 Girls/Gear research/planning Pass173–178 is now implemented and static/regression accepted; client runtime smoke remains the gate.
- Reuse-only architecture: HeroEquipmentRepository remains ordinary gear/promotion owner; HeroAdvancedProgressionRepository owns MID1407; GiftOpeningService/RewardTransactionService own Girl Gear Pack settlement; PlayerUnitOfWork/MutationSettlementService remain atomic settlement owners. No parallel Girl economy, inventory, aggregate-stat or RNG system exists.
- Fumo source facts: restoration materials 50001007/50001006/50001003 with values 200/60/10 and quality return fractions Green 1, Blue 3/8, Purple 9/50, Orange 9/100, Red 9/200. Exact original-server rounding/decomposition is unavailable; compatibility policy P0_FUMO_RESTORE_V1_AGGREGATE_FLOOR_GREEDY_SOURCE_ORDER is explicit.
- Ordinary promotion with Fumo restores materials and promotes in the same UoW. Existing empty MID51 response remains `{}` when no restoration exists; MID57 retains `restore_items`. Ordinary equip itself is no longer blocked by pre-existing Fumo.
- P2 boundary: if the current ordinary-promotion stage contains Awakening/Blood-Awakening equipment, MID51/MID57 return HTTP 409 with zero mutation. Do not pull selective special-equipment preservation into P0.
- MID1407 empty request consumes all held 50001343/344/345 and credits degree_cer/graduate_cer/patent_cer at 5 per item; empty inventory is successful no-op. No invented durable idempotency receipts.
- All 199 source `gift.equip` operations are active. GearPackMaterializer uses compatibility policy P0_GIFT_EQUIP_V1_CUMULATIVE_SELECTOR_SPECIAL_DEDUP and feeds ordinary InventoryGrant rewards to the existing Gift transaction. No ROS.
- Generated source catalogs rebuild byte-identically from effective 4,370-file src_64. OTA remains 1.631.12 / 142 entries.
- NEXT: targeted stock-client P0 smoke/reconciliation. Suggested focus: ordinary Fumo promotion + returned books, MID1407 with sufficient materials, representative Girl Gear Pack opening, and verify Awakening-stage promotion fails safely rather than clearing special gear. After runtime closure proceed to P1 deterministic missing stat systems (Subjects/Electives, White Album, Workshop Bookshelf/Cabinet, Element preconditions).
- Permanent evidence rule: source facts, runtime observations, compatibility policy and implementation remain separately classified.

# Backend machine memory — Pass171.0

Canonical implementation: `gxb-backend-v0.17.4-pass171.0`.

- H1-H5 Horcrux implementation remains static/regression accepted.
- Pass170 stock-client smoke was broadly positive through generated rewards, Gods Trial manual/auto, equip/collocation and strengthening, but exposed a restart-only Hero/Horcrux crash.
- Debug source fact: KM-Moe partner_id 10073 persisted `spirit_equip=[7,4,12,1,5,15]`; MID81 simultaneously carried complete instances for all six IDs. MID49 also emitted `spirit_item=[]`.
- Recovered `NormalHero.lua` sets `spiritItems_ = hero_info.spirit_item`; a present empty Lua table is truthy, so `getSpiritSuitID()` / `getSpiritEquipsAttr()` select the empty slot cache instead of Backpack fallback and dereference nil after relogin.
- Pass171 fix: canonical self-player `HeroRepository` removes/omits `spirit_item`; unique Spirit objects remain owned only by Backpack `spirit_list`, while Hero `spirit_equip` remains six-slot ID authority. Durable load normalization self-heals stale cache fields.
- Exact smoke fixture is protected by `tools/selftest_pass171_horcrux_restart_reconciliation.py`, including a numeric materialized-attribute lookup after restart.
- Adv. Horcrux Pack `50002168` / gift `90040453` is source-defined Oath-only: six orange Oath position candidates, weights 1666/1666/1666/1666/1666/1670 = 10000. User observation is not an RNG bug.
- OTA remains 1.631.12 / 142 cumulative entries; Pass171 is backend-only.
- NEXT: targeted stock-client restart re-smoke on the preserved player state. H6 remains open; do not declare runtime closure until re-smoke and follow-up reconciliation pass.
- Permanent rule: cross-check effective `src_64` before every backend behavioral modification and preserve source fact vs runtime observation vs compatibility decision.

## Pass225 runtime/logging checkpoint
- Fresh clean-data Pass224 smoke: ordinary Awakening remains runtime accepted.
- Blood MID2738 opened mission 2200001 and granted item 50002078, but **no Blood MID54 was sent** before Awaken Task rejected battle with mission count=0/is_complete=0.
- Root cause: Pass224 falsely treated the already-collected ordinary Awakening equip slot as proof the Blood substitute had been equipped. Reject that projection permanently.
- Correct client rule: Blood substitute appears uncollected until a real MID54 succeeds; after successful MID54 only, mark a transient Blood-specific slot cache and remove the displayed Blood item ID from local Backpack. Do not advance twice_awake_stage_ client-side.
- Pass212 control remains client authority for Blood UI/window/resources and global downloader/loading behavior.
- Operator logging: server.py DEBUG_VERBOSE=1..4; automatic filtered runtime_logs/server.txt; structured JSONL remains unfiltered. Categories: basic/error/missing=1, window=2, http_download=3, full=4.
- Historical root PASS*.json artifacts moved under docs/json; VERSION.json remains operational at root.


## Pass227 Blood MID867 wire reconciliation
- RUNTIME_OBSERVED Pass226: stock Blood victory sends `npc_ids={}` because current Lua supplies an untouched empty table through cjson.
- Pass210 Python `npc_ids=[]` was semantic-empty characterization, not literal stock-wire authority.
- IMPLEMENTATION Pass227: Blood-only validator accepts present empty dict `{}` or empty list `[]`; missing/null/scalar/nonempty remains rejected.
- Do NOT normalize MID867 globally: ordinary Incubus shares MID867 and may send nonempty dead-NPC arrays.
- MID866 generation session, terminal `num=20`, replay/idempotency, and MID161 stage3 ownership remain unchanged.
- OTA remains 1.631.20 because Pass227 changes server behavior only.


## Pass232 P2 edge reconciliation + log preservation
- RUNTIME_OBSERVED: Nikita ordinary+Blood smoke completed through Blood stage3 on OTA1.631.22.
- RUNTIME_OBSERVED: KongMing mission 1144001 first activation grants 50001397, but after Give Up + external sale, Pass231 reopened without regrant and stranded progression.
- COMPATIBILITY_POLICY/IMPLEMENTATION: event activation now restores exactly one intermediate when the entitlement ledger is LIVE but neither the intermediate nor derived exclusive gear is owned/equipped; existing live material/gear still suppresses duplicates. Odin source-Give-Up RESTORABLE policy remains intact.
- IMPLEMENTATION: human console logs are non-destructive across backend restarts: server.txt, then server1.txt, server2.txt, ...; structured JSONL evidence remains unchanged.
- OTA remains 1.631.22; no client payload change.


## Pass243 Emblem I2
- Function45 is guide-sensitive UI state, not authorization. Level100 alone is pending; qualifying Blood-stage3 Hero level100 causes normal `new_funcs_` announcement/maintenance repair.
- Terminal Blood MID161 replay persists `new_funcs_=[45]` when first opened; do not restore Pass228 `common_alert`.
- MID1402 canonical eligibility: twice_awake_stage>=3 and Hero lev>=100. MID1403 recovery-safe removal remains allowed for already-equipped source-valid medals.
- MID83 Heart provider is exact: 50001347 x60 -> 50001346 x1, zero Mana; stock callback mutates Backpack locally so server response stays empty.
- MID1400/1401/1405/1406 remain fenced. Next I3: versioned RNG/policy/proposal internals only.


## Pass244 Emblem I3
- Internal `emblem-v1` outer Scholarship policy is now active but explicitly COMPATIBILITY_POLICY; current `inscription_rate.lua` still has zero client callers and original server math remains unknown.
- Fixed point: Forge +10bp per eligible Lv7 attempt, hard by1000; Reforge +100bp, hard by100. Hard ceiling consumes no gate entropy. Counters are independent and mutate only on eligible Lv7 generated outcomes.
- `EmblemOutcomePlanner.generated_candidate` prevalidates all pools, uses source raw relative weights/70:30 family split, and excludes current ordinary source medal on Reforge.
- `EmblemStateRepository` validates frozen proposal candidates by source tier, preserves pending old policy_version across policy upgrades, and rejects stale counter-result application.
- Internal `EmblemService` proposal staging is latest-wins and UoW-bound. Public MID1400/1401/1405/1406 remain fenced; no costs or medals are publicly generated in I3.
- NEXT I4: MID1400 Forge only. Preflight scalar certificate + optional Heart costs before entropy; then use the tested internal planner/counter machinery atomically. Keep MID1401/1405/1406 fenced.


## Pass246 Emblem I4
- MID1400 Forge is IMPLEMENTED and static/regression accepted; MID1401/1405/1406 remain fail-closed. Runtime acceptance is deferred to I7.
- Current src_64 stock wire: `{inscript_id,make_num=1}` with no nonce; success returns raw `inscript_items` IDs which the client converts to rewards. Source resource IDs 19/20/21 map to degree/graduate/patent certificate scalars. Lv7 source row additionally costs Heart 50001346 x1.
- Complete certificate+Heart affordability preflight uses canonical MutationSettlementService.validate before any EmblemOutcomePlanner entropy/pity mutation. Final debit + generated medal credit settles inside the same PlayerUnitOfWork; rollback restores pity/inventory/journal after downstream failure.
- Repeated accepted MID1400 is another paid Forge; do not retrofit receipt/nonce semantics. Do not double-project the generated medal via generic awards/extra_drops_.
- `emblem-v1` Lv7 outer Scholarship ladder remains STRONG_INFERENCE+COMPATIBILITY_POLICY, not recovered official server math.
- P2 Blood runtime acceptance remains controlling; rejected Blood completion common_alert must not return. Occult MID2385 remains deferred/fenced.
- NEXT I5: MID1401 Reforge proposal + MID1405 Save + MID1406 Abandon using Pass244 frozen/latest-proposal machinery; then I6 hardening, I7 stock-client runtime acceptance.


## Pass248 Emblem I6 integration/hardening
- I6 is STATIC/REGRESSION ACCEPTED; I7 runtime acceptance is next and not yet claimed. Backend v0.37.6; OTA1.631.22 unchanged.
- Defect found against Pass240 design: I4/I5 opened MID1400/MID1401 without global operational eligibility. Fix: Forge/Reforge require any canonical Hero with twice_awake_stage>=3 and lev>=100 before costs/RNG/state. Function45 remains guide-sensitive state, never authorization.
- MID1405 Save/MID1406 Abandon deliberately remain usable recovery paths for an already-paid proposal if qualifying-Hero eligibility is later lost.
- Load maintenance now normalizes emblem_state with EmblemPolicyRegistry/EmblemStateRepository. Future schema remains fail-closed. HeroRepository migrates inscript_items to a dense positive-int list. Emblem insert validates max3 known unique physical positions; malformed imported layouts cannot be worsened, while remove remains recovery-safe.
- RuntimeLogger classifies 1400-1407 as emblem and writes bounded emblem_events.jsonl aggregate evidence: policy version, proposal generation/pending count, forge/reforge miss counters. No candidate IDs or internal state are inserted into wire responses.
- I6 dedicated 11/11 covers: gate pre-entropy/economy; Function45 non-auth; Star exchange->Forge->equip->remove->dissolve; fragment->Heart MID83->Lv7 Forge; Scholarship sets; 14 source-present non-forge Honor artifacts generation exclusion/equip compatibility; dense migration/malformed insert; durable state normalization; paid proposal recovery after eligibility loss; Campaign Star/fragment anchors; bounded runtime logs.
- Current authoritative 4370-file src_64 rebuild remains byte-identical to packaged emblem_source_catalog hash 083f3d70767d5a97e6bdfb2984480658184455d36e5c74e8d44fa2445fd5d6e4.
- Controlling I5 12/12, I4 7/7, I3 6/6, I2 7/7, I1 6/6, Pass129 architecture, Pass110 ROS, P2 Stage-G, Blood MID867, cleanup, popup-revert and Pass232 edge/log tests remain green. Historical route-fence assertions superseded by I4/I5 are non-controlling.
- Permanent negatives unchanged: rejected Blood common_alert stays absent; Occult MID2385 fenced; no Forge/Reforge nonce retrofit; emblem-v1 outer Scholarship math remains STRONG_INFERENCE+COMPATIBILITY_POLICY; no Girl-stat engine inside Emblem.
- I7 operator plan shipped as PASS248_EMBLEM_I7_STOCK_CLIENT_TEST_PLAN.md + PASS248_I7_CLIENT_TEST_CHECKLIST.json. Critical runtime cases include all three Forge families+Lv7, equip/replace/remove, 2/3 piece set display, single/10x Reforge Save/Abandon/latest-wins, insufficient-Crystal request that client may still send, pending proposal relog/backend restart, and final durability sweep.
- NEXT after I7 acceptance: Institute Alchemy -> final Girl-stat capstone -> client UX/loading/resource cleanup -> Mail/GM transport -> PvP-class systems. Deferred: KongMing Books I-IV/all-skill, Occult MID2385, Pet Awakening, optional Treasure/Daily Scholarship/Auction acquisition integrations.
