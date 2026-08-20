# v0.8.15 / Pass 36.1 — Campaign Reward Projection Split

## Scope

Implements `PASS36_1_IMPLEMENTATION_PLAN.md` sections 1–3 only.

## Code change

`gxb_backend/state/world_repository.py` now keeps two explicit MID114 concepts:

- `committed_drop_items`: the pending MID113 DropPlan that is applied canonically through `RewardTransactionService` on a successful matching result;
- `result_only_items`: the independent MID114 endpoint item-award channel.

For the currently mapped early Campaign slice, no distinct result-only item award is source-proven. MID114 therefore retains the existing response shape with `"items": []` and no longer serializes the canonical `reward_result.inventory_awards` into that field.

MID113 `items` and the canonical inventory commit are unchanged.

## Explicitly unchanged

No changes were made to GameDataCatalog, RequestServices, UnitOfWork, RewardTransactionService ownership, Inventory/Economy/Hero/Mission repositories, current deterministic first-clear selection, `economy_`, `exps`, `star_crystal`, Mission80001, Function33/tutorial milestone behavior, MID114 committed-receipt idempotency, Pass29 compatibility policy, or any deferred RNG/stamina/sweep/assist/EXP-juice work.

## Validation policy

Static/syntax/JSON/archive validation only. No Flask, HTTP, selftests, ADB, emulator, or gameplay execution was performed.
