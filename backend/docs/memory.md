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

# Backend machine memory — Pass152.0

Canonical implementation: `gxb-backend-v0.16.7-pass152.0`. Phase C is static/regression accepted with cumulative OTA 1.631.9 and resource-version-gated 272 synthetic EOL Recharge products. Pass151 MID2979 is runtime accepted. Next gate is Phase D client smoke/reconciliation; then Generated/Unique and Girls/Equipment. Existing canonical Commerce/Reward/Inventory/Skin/UoW owners are reused and ROS is unchanged.

---

# Backend machine memory — Pass137.0

Canonical implementation: `gxb-backend-v0.15.9-pass137.0`.

Pass137 completes Phase 1 of the approved Pass136 RNG roadmap. A fresh effective `src_64` check reconfirmed MID70 as the Magic buy/random-result path (`partner_id` + `summon_time` 1/10) and MID71 as deterministic player-selected target switching. Production `RequestServices` now injects `NamespacedRandbelowAdapter(self.random_outcomes, "summon.magic")` into the existing `MagicSummonPrivatePlanner`. No Magic probability/policy, planner algorithm, MID70 wire/cost/byproduct/fragment/receipt behavior, MID71 semantics, persistence schema or OTA was changed.

Validation: Pass137 focused suite 5/5 PASS; production adapter shares the request ROS identity; MID71 consumes 0 gameplay draws; MID70 x1 consumes 1 `summon.magic` draw; MID70 x10 consumes 11 under the unchanged private Magic policy. Pass110 ROS foundation and current Campaign/architecture neighbor suites pass. Historical Pass111/Pass114 contain superseded OTA/receipt assertions and are retained as historical harness debt. OTA remains 1.631.8.

PHASE 1 STATUS: STATIC/REGRESSION ACCEPTED AND COMPLETE. NEXT: Phase 2 MID241 foundation + deterministic ordinary gifts. Phase 4 remains the consolidated client runtime acceptance gate for Magic/MID241.

---

# Backend machine memory — Pass131.0

Canonical implementation: `gxb-backend-v0.15.8-pass131.0`.

Pass131 implements the previously deferred Normal/Super MID117 account EXP + Mana plane. Effective `src_64` was rechecked first. Per-run wire rows are `exp=energy_cost`, `mana=mana_gain`; cumulative account EXP uses the selected client-backed compatibility policy (1× while simulated pre-run level<=10, then 3× on later rows after crossing), while Mana is `mana_gain*sweep_num`. Mentor/Student bonus is deferred with Social.

Architecture remains reuse-first: `CampaignSweepEconomyPolicy` is pure/stateless; `RewardTransactionService` delegates Mana to `EconomyLedger` and player EXP/level/function unlocks to `PlayerProgressionService`; `MutationSettlementService` + `PlayerUnitOfWork` + existing MID117 UUID receipt remain the atomic exactly-once spine. Replay freezes static per-run rows and refreshes cumulative owner-backed fields. No new ledger or persistence schema exists.

Validation: focused Pass131 suite 10/10 PASS, including level10→11, Super exactly-once, replay freshness, Crystal projection, fail-before-RNG validation and forced post-RNG rollback. Pass117/121/122 neighbors PASS; later Campaign/progression/architecture suites were already exercised during implementation. Pass113/114 contain historical assertions intentionally superseded by this semantic pass and are not rewritten. `local_assets` remains byte-identical; OTA 1.631.8.

RUNTIME GATE: targeted MID117 client smoke. NEXT after acceptance: RNG backbone closure against the Pass108 matrix; then Generated/Unique, Girls/Equipment, deferred source-bounded verticals.

---

# Backend machine memory — Pass129.0

Canonical implementation: `gxb-backend-v0.15.7-pass129.0`.

Pass129 is behavior-neutral architecture hygiene. Effective `src_64` was rechecked first; client-visible Campaign contracts are unchanged. `CampaignComposition` centralizes Challenge/Super construction across RequestServices and PlayerMaintenanceServices without merging authorities. Live WorldRepository roots now receive explicit Challenge/Super collaborators and set `strict_campaign_collaborators=True`; identity mismatch or omission fails fast. Legacy non-strict WorldRepository construction remains for direct compatibility/tools during strangler migration.

Validation: Pass129 identity/acyclicity 5/5 PASS; Pass128 12/12; Pass128.2 4/4; Pass123 6/6; Pass122 5/5; Pass121/94/92/96 PASS; compileall PASS. Known campaign_economy and multiuser legacy harness failures reproduce unchanged on frozen Pass128.2. OTA remains 1.631.8.

RUNTIME GATE: one client smoke/reconciliation before gameplay-semantic work. NEXT after acceptance: Campaign Player EXP + Mana sweep economy; then RNG closure, Generated/Unique, Girls/Equipment, deferred verticals. Do not split MID113 from MID114 during future extraction; move them together behind one Campaign battle boundary.

---

# Backend machine memory — Pass128.2

Canonical implementation: `gxb-backend-v0.15.6-pass128.2`.

Pass128.0 progression architecture is retained, but its runtime acceptance remains revoked until a fresh-account smoke accepts this hotfix. Runtime root cause was not progression logic: explicit MID112 on Function31-closed accounts omitted mandatory zero-valued Super chapter fields. Effective `src_64` directly assigns these fields and numerically compares `super_chapter_id`, so missing is not equivalent to zero.

Pass128.2 changes only `SuperCampaignProjectionService.recompute_cursors()` semantics: write a cursor key if it is absent OR if the normalized numeric value differs from the desired value. Mandatory Super wire keys are `super_chapter_id`, `super_campaign_id`, `super_stars`, `super_bonus_id`. Keep projection ownership here; do not restore competing cursor ownership to WorldRepository. Existing normalization/save persists the repair once and must not ghost-save canonical state.

Validation: dedicated fresh level1/level10 MID112 wire test 4/4 PASS; Pass128 progression suite 12/12 PASS; Pass121/122/123/94/92/81/79/75 neighbors PASS; compileall PASS; OTA1.631.8 unchanged.

NEXT: mandatory fresh/new-account Campaign client smoke. Pass129, Campaign EXP/Mana, RNG and all later roadmap work remain halted until runtime acceptance.

---

# Backend machine memory — Pass128.0

Canonical implementation: `gxb-backend-v0.15.5-pass128.0`.

## Pass128 current authority

Effective source authority remains `app-assets/output/assets/src_64`. Fresh pre-implementation checks reconfirmed FunctionID31 level condition `1|11`, immediate `LOAD_WORLD_MAP` reload on `NEW_FUNC_OPEN(31)`, direct `CampaignTable.relateCampaign()` lookup, materialized-row-before-click behavior, and `checkNomalCampaignThrough()` as a separate Normal-clear gate.

Runtime architecture is four bounded responsibilities: `SuperCampaignCatalog` (source facts), `SuperCampaignAccessPolicy` (pure authorization), `SuperCampaignProjectionService` (world_map/frontier), and `EliteCampaignUnlockCoordinator` (Function31/projection ordering). Function31 level-11 bootstrap projects Super100019/cursors first, announces Function31 second, and commits atomically. Legacy level>=11 unresolved accounts self-heal once on player load.

MID113: existing same-stage STAGED replay remains first. New Super staging requires Function31 + exact Super row + related Normal star>0 before attempts/Energy/RNG/session replacement. MID117: committed UUID receipt replay remains first; a fresh UUID then runs the same bouncer before attempts/cost/RNG/receipt. Denial uses compatibility error 1; never repurpose 30005.

Super progression remains sequential: a successful Super clear materializes raw next Super immediately at star0/source daily limit; the next Normal anchor gates entry rather than visibility. Terminal2300024 produces no successor. Pass75 QA row preseed remains visibility/test policy only and has no authorization exemption.

Focused Pass128 suite passes 12 checks, including atomic level11 ordering/rollback, legacy self-heal idempotency, MID113/MID117 pre-mutation denial, receipt/staged replay precedence, sequential exposure, terminal behavior, and QA decoupling. Neighbor Pass121/122/123/94/92/81/79/75 regressions pass. OTA/local_assets is byte-identical to Pass123 at 1.631.8.

NEXT: Pass129 client smoke/debug/reconciliation. After runtime acceptance: Campaign Player EXP + Mana sweep economy, RNG closure, Generated/Unique, Girls/Equipment, deferred verticals.

---

## Historical memory retained below

# Backend machine memory — Pass123.0

Canonical implementation: `gxb-backend-v0.15.4-pass123.0`.

## Runtime evidence entering Pass123

Pass122 Challenge smoke from `debug.zip` is accepted. The observed stock-shaped Challenge sequence was MID113 `campaign_id=24111, campaign_type=24` -> deterministic first-clear items `[50001121, 50001125, 50001129]`, then MID114 victory -> `campaigns=[24111(star=3),24112(star=0),24121(star=0)]`, `items=[]`, `economy_.energy=62`. No Campaign Lua crash or malformed result was observed. This confirms the Pass122 branch projection and deterministic first-clear delivery path from the client side.

## Pass123 src_64 feedback loop

Effective source authority remains `app-assets/output/assets/src_64` from `all-assest-rechecked.zip`.

Fresh source checks before implementation confirmed:
- stock SelectTeam Campaign MID113 sends `campaign_id`, `campaign_type`, `formation` (+ source-native optional pet/rent fields) and no operation UUID;
- stock BattleCreate MID114 sends `campaign_id`, `star`, `campaign_type`, `formation` (+ optional source-native fields) and does not echo MID113 `battle_id`;
- `BattleCreate.campaignResult()` accepts either transport OK or body `error_code == battleConst.errorIdFightExist`;
- `lib/battle/battleConfig.lua` defines `errorIdFightExist = 30005`;
- Challenge result uses the same family-compatible 30005 terminal handling;
- the six Pass117 Campaign battle OTA files can therefore be restored to effective-stock-shaped bytes without removing MID50/MID117 bridges located in other files.

## Implemented manual battle authority

Pass117 Campaign battle UUID/receipt coordination is retired as authority. The compatibility module/file remains in-tree for one migration pass, but `WorldRepository` no longer imports it or writes `mid113_campaign_battle_stage` / `mid114_campaign_battle_result` receipts.

Canonical state is `player.active_campaign_battle` schema v2:
- `STAGED`: campaign/type, formation audit snapshot, started_at, frozen battle-visible items, drop_plan, reward_plan, exact stage_response.
- `SETTLED_WIN` / `SETTLED_LOSS`: retains frozen audit/reward plans plus terminal_static_response and terminal_projection descriptors.

MID113:
- validates source mode/unlock/Super-attempt/Energy entry guards first for a new stage;
- if STAGED for the same campaign/type, returns the exact persisted stage_response and consumes no RNG, regardless of formation or legacy `campaign_battle_op_id`;
- a different campaign/type only supersedes after the new request passes source guards;
- terminal state is replaced by the next valid MID113.

MID114:
- matches only source-visible campaign_id + campaign_type; formation is not correlation authority;
- consumes one matching STAGED session inside the existing PlayerUnitOfWork transaction;
- victory/loss settlement behavior remains domain-owned and frozen from MID113;
- matching terminal duplicates return `error_code=30005` with static terminal outcome plus current live chapter/campaign/economy projections, performing zero mutation;
- unmatched/stale Campaign-family MID114 returns a shape-preserving `30005` terminal drain with no rewards/progression/cost;
- legacy `campaign_battle_op_id` from an already-installed 1.631.7 client is accepted/ignored and cannot gate settlement.

Known protocol limitation remains explicit: without a wire token, an extremely late old MID114 after a new same-campaign battle has begun is indistinguishable from the current result. Stock src_64 has the same limitation; do not recreate a hidden UUID system.

## OTA

Current resource update: **1.631.8**, package `gxb-local-1.631.8.zip`, one cumulative 138-entry volume.

Exactly six entries differ from 1.631.7:
- src_32/app/windows/SelectTeamWindow.lua
- src_32/app/windows/SelectTeamNewWindow.lua
- src_32/app/scenes/BattleCreate.lua
- src_64/app/windows/SelectTeamWindow.lua
- src_64/app/windows/SelectTeamNewWindow.lua
- src_64/app/scenes/BattleCreate.lua

Those six are byte-equal to effective source. All other cumulative entries are byte-preserved from 1.631.7. MID50 `SelfPlayer.lua` and MID117 `SweepWindow.lua` UUID bridges remain present.

## Validation

PASS: Pass123 manual session/OTA focused suite; Pass122 Challenge; Pass121 Super MID117 atomicity; Pass117 historical non-identity subset; Pass75 Campaign ownership; Pass81 Campaign/reset corrections; Pass79 Daily Reset; Pass92 MID116 reset; Pass114 MID117 activation; Python compileall.

Historical/stale harness notes:
- `selftest_campaign_economy.py` currently fails in unrelated summon setup before Campaign assertions.
- Pass99 sweep QA predates mandatory MID117 UUID and sends no operation identity.
- Pass113 intentionally pins the pre-Pass114 WorldRepository hash and therefore must fail after later Campaign implementation passes.
Do not reinterpret these as Pass123 regressions.

## Architectural inference — original Campaign persistence

Do NOT claim an unrecovered official database schema. Client/server evidence supports a mixed persisted projection model: the server returns per-player Campaign rows carrying clear/star/attempt state, while `chapter_info` also carries frontier/cursor summaries (`normal_campaign_id`, `super_campaign_id`, chapter/star totals). A lone pointer cannot represent Challenge branching or per-stage stars/limits. Most plausible reconstruction is durable per-player Campaign state (database/document rows or equivalent) plus cached/frontier pointers for navigation and aggregation.

## Roadmap

NEXT: Pass124 client smoke/debug/reconciliation of OTA 1.631.8 and manual battle session behavior. After Campaign structural runtime acceptance:
1. Reconcile Campaign Player EXP + Mana sweep economy (`economys` / cumulative `economy_`; Juice stays ordinary `items`; do not misuse `additional`).
2. Finish RNG backbone via Pass108 matrix reality/self-heal and remaining prioritized CORE RNG integrations.
3. Generated/Unique Instance settlement.
4. Girls/Equipment economy closure.
5. Resume deferred Store/Battle Pass/Arena/Pet/Guild/March/World Boss/Task-Sign/Monthly Privilege/etc. source-bounded verticals.
