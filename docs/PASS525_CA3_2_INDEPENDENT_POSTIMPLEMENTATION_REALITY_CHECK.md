# Pass525 — CA3-2 independent post-implementation reality check

## Verdict

**GREEN for a local CA3-2 implementation checkpoint; NOT CA3 aggregate acceptance.** The produced code remains within the Pass524 CA3-2 contract and current/v1.164 Pet evidence. No contradiction was found requiring CA3-2 research to reopen. Exact pinned-toolchain/sqlc/real-PostgreSQL/stock-client proof remains deferred to the combined CA3-1/2/3 Work gate.

## Authority and candidate

- Pass524 HOT authority SHA-256: `26fe758049bdbe362215873dee32e135c5cbe13bfb115f13339f3d538f259547`.
- Parent backend: exact Pass523 CA3-1 ZIP SHA-256 `ce8d11be20ed7cbdec327f739ed50625980fea7e06d1c3de29405de27ffd3352`.
- Parent implementation revision: `c0ac6d25a7c05d2607519a16bd47b6d6afd9a249194f1437d23c7dd4ce91d501`.
- Current source archive SHA-256: `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`.
- CA3-2 immutable content revision: `5870441b5d4ee46391629613d46d20bdd0301d7fe856667b076bfb110d97e5ac`.

## Independent source reread

`SOURCE_FACT`: current `app/common/network/mid.lua` maps `PETS_GET=780`, `PET_SUMMON=781`, `PET_CLEAN_CD=782` and `PET_SET_SHOW=789`.

`SOURCE_FACT`: current `Pet:stoneSummonHero` sends only `{table_id}`, hydrates the returned full Pet record, then removes one egg when present; otherwise it removes the source `TotalStarSuipian[star]` essence count. It reconstructs incubation from returned `birthday + hatch_time - server_time`.

`SOURCE_FACT`: current `Pet:clearCD` sends `{pet_id}` and, on OK, immediately sets local `is_show=1` before issuing `PET_SET_SHOW`. Natural timer completion uses the show transition without a preceding clean-CD request.

`SOURCE_FACT`: current Function-38 guide code checks the backpack for `misc.firstEgg` and inserts one locally only when absent. Backend response processing handles `extra_drops_` before `new_funcs_`, so a committed server starter stack delta can be visible before `onNewFuncOpen(38)` runs.

`SOURCE_FACT`: current Traditional Chinese localization contains `寵物立即孵化，首次免費` (Pet hatches immediately; first time free). `misc.pet_hatch_cost_param` remains the source hatch-formula coefficient. The deterministic CA3-2 compiler pins the exact current Pet/Misc/enums source hashes and emits 27 base-lineage acquisition rows.

## Produced ownership and transaction reality

`RUNTIME_OBSERVED`: migration 00017 adds only `player_pet_roots.first_free_hatch_used` plus immutable Pet acquisition/policy content tables. It performs no gameplay starter, inventory, Pet-instance or function-unlock backfill in SQL.

`RUNTIME_OBSERVED`: Function-38 starter reconciliation is implemented through I5-owned stack/function ports. It locks the economy owner, Ross egg stack and function state, inserts Function-38 eligibility/unlock, and ensures one starter egg only when the unlock is newly inserted and authoritative quantity is zero. An already-existing unlock cannot regrant the egg.

`RUNTIME_OBSERVED`: the ordinary Pet acquisition debiter is I5-owned. Character supplies only source-qualified egg/essence identifiers and fragment count; I5 locks both candidate stacks and applies egg-first precedence atomically. Character does not issue foreign-owner I5 SQL.

`RUNTIME_OBSERVED`: MID781 binds an immutable `PET_ACQUISITION_CA3` revision, locks the Pet root, treats an already-owned origin lineage as successful recovery without another debit, otherwise debits I5 and creates exactly one canonical Pet with `birthday=operation.StartedAt.Unix()`, source initial star and stable creation content revision.

`IMPLEMENTATION_DECISION`: same-lineage MID781 after a lost response returns the existing Pet rather than double-debiting or creating a duplicate. This is compatibility/recovery policy, not claimed original-server truth.

`RUNTIME_OBSERVED`: MID782 locks Pet root/instance and settles the show transition atomically. An already-shown Pet is idempotent. A naturally elapsed deadline is free. Otherwise the first unused player-wide acceleration consumes `first_free_hatch_used`; later acceleration recomputes crystal cost from authoritative remaining time and the immutable source coefficient, debits I5 in the same caller transaction, then persists `is_show=true`.

`IMPLEMENTATION_DECISION`: the player-wide first-free acceleration fact lives on PetRoot rather than transient tutorial state. Source proves “first time free” but not original server storage layout.

`RUNTIME_OBSERVED`: MID789 is idempotent for already-shown Pets and fails closed before the authoritative natural deadline. It therefore cannot be used to bypass incubation cost/timing.

## Projection/router reality

`RUNTIME_OBSERVED`: production `PetDispatcher` owns only MIDs `780, 781, 782, 789`. Deferred MIDs `783-788`, `790-792` and MID134 remain unregistered. CA3-3 progression and CA4 equipment/advance behavior have not been activated.

`RUNTIME_OBSERVED`: successful MID781 returns the full CA3 private Pet projection including owning `player_id`; MID782 and MID789 return empty OK bodies matching their mutation-style client callers.

`RUNTIME_OBSERVED`: I5 settlement projection emits only actually committed starter stack deltas as `extra_drops_`, and emits newly inserted function IDs as `new_funcs_`; recognized receipt replay does not resend historical starter drops/function announcements.

## Content/activation reality

`RUNTIME_OBSERVED`: exact source regeneration produces content revision `5870441b5d4ee46391629613d46d20bdd0301d7fe856667b076bfb110d97e5ac`, 54 Pet templates, 27 base acquisition rows, `starter_egg_item_id=50001050`, `hatch_cost_param=12960000`, source fragment schedule `{1:10,2:30,3:80,4:180,5:330}`, and Function 38 alone with `PET_STARTER_CA3` announcement capability.

`RUNTIME_OBSERVED`: registry installation and exact verification include the Pet acquisition artifact/policy. Runtime Pet mutations bind only an active or operation-pinned revision advertising `PET_ACQUISITION_CA3`.

## Local test/reality evidence

Exact canonical deterministic source/query validators are GREEN, including the cumulative-aware preserved CA3-1 guard and dedicated CA3-2 negative-boundary guard.

`COMPATIBILITY_COPY_ONLY`: a fresh copy changed only the Go/toolchain declaration to available Go 1.23.2. With `GOTOOLCHAIN=local` and no product/test weakening, full `go test ./...`, full `go test -race ./...`, and full `go vet ./...` all pass. Targeted Pet tests additionally prove lineage retry without double debit, first-free then paid acceleration, early MID789 fail-closed, egg-first acquisition and no starter regrant for an existing Function-38 unlock.

`ENVIRONMENT_BLOCKED/NOT_RUN`: exact canonical Go 1.27.1, pinned sqlc 1.31.1 generation, real PostgreSQL migration/query/concurrency execution and unmodified stock-client E2E are not claimed in this sandbox. Per the approved execution strategy these are carried to the combined CA3-1/2/3 Work gate.

## Scope check

No Pet EXP/feed/evolution/skill mutation is implemented. MID783-788, MID790-792 and MID134 remain closed. MID785/790 equipment-reset interactions remain CA4-gated. Pet Campaign, Practice, styles and formation/reference fencing retain their approved owners.

## Conclusion

CA3-2 is coherent enough for a **local GREEN checkpoint seal** and the project may advance to **CA3-3 / PRE_IMPLEMENTATION_RESEARCH_RECONCILIATION**. This does not grant CA3 aggregate/native/stock acceptance.
