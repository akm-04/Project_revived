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
