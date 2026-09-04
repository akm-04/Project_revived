# v0.8.8 / Pass 32.6 — Pass 32.5 Infrastructure + Tutorial Ordering Fixes

## Scope

Pass 32.6 is an implementation/maintenance revision under planning lineage 32. It implements the Pass 32.5 architecture blueprint incrementally on top of v0.8.7. No backend rewrite was performed and no new MID was invented.

Implemented structural boundaries:

- shared `EffectiveSourceResolver`;
- immutable typed `GameDataCatalog`;
- memoized request-scoped `RequestServices` composition root;
- one-player `UnitOfWork` with full-PlayerState snapshot/rollback and one persistence commit;
- typed `RewardTransactionService` for supported reward owners;
- `FunctionStateRepository` with eligible vs announced state and explicit semantic announcements.

## Effective-source / catalog policy

The runtime does not parse Lua per request. `StateRepository` loads one immutable `data/game_data_catalog.json` and all request service graphs share it.

The catalog intentionally has no `type_of_id(id)` API. Callers use explicit namespaces/context. `lookup_all(id)` is diagnostic only and can preserve collisions such as `41001` being meaningful in more than one source table.

This release was built from the user-supplied packaged `src_64` snapshot, not a separate recovered writable override tree. Canonical Pass 28/32 provenance proves writable `item.lua` only adds `51100032..51100038`. Therefore the packaged catalog does **not** pretend that all 5,838 APK item rows are a complete effective table. It includes only the 156 item rows reachable from the already-implemented deterministic Campaign first-clear/sweep metadata plus Mission80001's `40001004`. That set does not intersect the seven writable-only additions. Its provenance is stamped `apk_baseline_effective_equivalent_row_subset` with the proof recorded in the JSON. Tables canonically proven to have no writable override are stamped `apk_baseline_effective_equivalent_verified`.

Current catalog coverage:

- item: 156 current reward rows;
- partner: 555;
- super_partner: 14;
- campaign: 917;
- mission: Story80001 only;
- function: 99;
- skill_price: 151 source price rows;
- pet/dropbox/model: deliberately empty in this runtime catalog until a later consumer requires them and effective-layer provenance is available.

`skill_price` is a Pass 32.6 typed config namespace extension used by MID39; it does not alter the Pass 32 ID ownership rules.

## RequestServices / UnitOfWork

`StateRepository.get_*_repository()` compatibility methods remain, but they now delegate to one memoized `RequestServices` object for the bound player. Economy/Inventory/Hero/Function/Mission/World no longer reconstruct separate nested ownership graphs in the same request.

The one-player UoW:

1. snapshots the complete current `PlayerState` before a migrated mutation;
2. lets domain repositories mutate with their existing `persist=False` bridge and shared save callback;
3. stages explicit semantic events separately from cumulative state;
4. performs one `MultiUserDatabase.save_player` at the outer mutation boundary when the domain marked persistence;
5. restores the snapshot if domain code or the persistence callback raises;
6. exposes semantic events only after a successful commit.

The UoW contains no Campaign, Mission, Economy, Hero, or tutorial formula.

## RewardTransactionService migration

MID114 existing reward semantics are unchanged by design. The existing deterministic first-clear item set, Campaign Mana, player EXP, first-3-star Crystal, Hero EXP and Mission80001 progress are staged under the same UoW. Economy/Inventory rewards are represented by typed reward atoms; Hero EXP and Mission progress remain owned by their existing repositories inside that transaction.

Story Mission80001 MID161 keeps its already-mapped source reward and response shape. The reward service grants canonical `15,000` Mana and `40001004 x10` Lightin contracts through Economy/Inventory, while the Mission repository retains receipt/idempotency and mission-state ownership. Mission80003+ is still not created or inferred.

Known `item.lua type=-1` display-only rows are rejected as `InventoryGrant`. Partner-scroll item rows require their explicit `partner_id` cross-reference. Unsupported owner kinds fail closed.

## Function state and Function33

`function.lua` level requirements now mean **eligibility**, not automatic announcement.

Persisted schema:

- `function_state.schema_version = 1`;
- `eligible_ids`;
- `announced_ids`;
- `pending` policy rows;
- legacy `func_ids` mirrors `announced_ids` only.

Migration follows Pass 32.5 exactly: existing `func_ids` are treated as already announced; the backend does not speculate/backfill every currently eligible function.

Non-guide-sensitive level crossings preserve the old announcement behavior through an explicit semantic event. Function33 and Function31 are guide-sensitive. Function33 becomes eligible at Lv7 but is held. Pass 31 proved immediate Function33 `new_funcs_` is wrong because `SelfPlayer:onNewFuncOpen()` dispatches the function guide and skips ahead to the skill tutorial. Pass 32.5 approved guide `100197` as the conservative local compatibility checkpoint while the exact historical server gate remains unresolved. Accordingly, MID26 `SAVE_STORY` releases Function33 only when the persisted guide is at/after `100197`. Function31 remains held/unresolved.

`ResponseProjector` now auto-projects only the established cumulative channels (`economy_`, `exps`) and never synthesizes `new_funcs_` from arbitrary state diffs.

## MID39 source-derived atomic skill upgrade

Source cross-checks used by the implementation:

- `data/tables/skill_price.lua`: level 1 costs 100 Mana, level 2 costs 500, level 3 costs 1000, etc.;
- `app/common/enums.lua`: `SKILL_EXTRA = {0,0,20,40,60,60}`;
- `app/model/NormalHero.lua`: server `skills` values are converted to client-visible skill levels by adding those offsets;
- `app/windows/HeroMainWindow.lua`: each click prices `skillPrice:gold(hero:getSkillLevel(index))`; Super Heroes multiply the price by 10; client Mana and Skill Points are decremented locally before the changes are batched to MID39;
- the same UI exposes a half-price branch through Activity1032.

Pass 32.6 therefore computes each batched click from the canonical stored base plus the source offset, looks up that exact client-visible level in the typed `skill_price` namespace, and uses explicit Partner/SuperPartner catalog membership to determine x1 vs x10. The current backend has no canonical Activity1032 schedule/state, so it uses the ordinary source price and does not invent a half-price activation.

On a valid MID39 transaction, Mana spend, Skill Point decrement, skill-level increments and timer normalization are staged together and committed once. Changed cumulative Mana is attached by the established `ResponseProjector` economy channel. Existing MID39 endpoint-local response fields are preserved.

Example source-backed early batch: two upgrades of the first skill cost `100 + 500 = 600` Mana.

MID53 is deliberately **not** widened by this change. v0.8.7 routed the older single-skill endpoint through the same point/skill helper, but Pass32.6 has source-mapped Mana pricing only for MID39. MID53 therefore retains its prior Skill Point/skill mutation behavior until it receives a separate source pass.

## Explicit non-changes

Pass 32.6 does not implement or alter:

- Campaign stamina reservation/deduction/defeat timing;
- repeat-drop RNG or `increase_rate` semantics;
- sweep economy formulas beyond the existing implementation;
- chapter-star MID118;
- later Story mission chain transitions;
- MID59 Lightin stone summon;
- MID90 endpoint-specific Skill Point projection;
- general Activity1032 scheduling;
- Guild/PvP/shared-world participants;
- payment;
- Pass29 compatibility safe-MID allow-list.

## Validation

Assistant validation is static only: Python compilation/AST-level inspection, JSON/provenance validation, targeted source-contract comparison, and ZIP integrity/hash checks. No Flask/HTTP/selftests/ADB/emulator/gameplay were executed.
