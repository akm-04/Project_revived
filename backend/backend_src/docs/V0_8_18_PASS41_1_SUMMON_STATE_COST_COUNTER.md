# v0.8.18 / Pass41.1 — Summon State, CostPlan & Counter Framework

## Scope

Infrastructure only. No new paid/free/SX/Magic result operation is activated.

## Added

- Authoritative `SummonStateContract` for MID56/MID50 `summon_info` projection.
- Typed `SummonCostPlanRegistry` for source-mapped Mana/Crystal/item/coupon/SX costs.
- Typed `SummonCounterPolicyRegistry` preserving Small/Medium/SX milestones and raw pity parameters.
- `UnresolvedSummonCounterEngine`, which intentionally rejects execution until transition math and persistence identity are proven.
- Richer immutable MID50 operation descriptors referencing state/cost/counter policies.
- Second dispatch safety gate requiring tutorial-active/free CostPlan + deterministic-only RNG status before the two existing tutorial handlers can run.

## Preserved

- `(50,1,1)` tutorial Lavia + `50001002 x10` receipt-safe reward flow.
- `(50,3,1)` tutorial Pandaria flow with no invented Medium Juice quantity.
- All paid/discount/SX/Magic operations fail closed.
- MID59 synthesis unchanged.
- Pass40.1 Campaign planner, UoW, RewardTransactionService, economy/inventory owners, FunctionState/TutorialMilestone, and Pass29 allow-list unchanged.

## Validation

Static/syntax/JSON/archive/source/protected-file comparison only. No Flask/HTTP/selftests/ADB/emulator/gameplay executed.
