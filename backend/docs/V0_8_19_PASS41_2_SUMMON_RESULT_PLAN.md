# v0.8.19 / Pass41.2 — Typed Summon ResultPlan & Duplicate Conversion Seam

## Scope

Infrastructure only. No general Vending/Gacha RNG activation.

## Added

- `SummonResultKind`: `hero`, `item`, `to_stone`.
- `SummonResultRowPlan` / `SummonResultPlan`.
- pure `SummonResultRenderer` matching the stock MID50 result-row contract.
- `SummonResultPolicyRegistry` with only tutorial deterministic Hero rows active.
- `UnresolvedSummonDuplicateConversionResolver`, which fails closed because duplicate fragment quantities are unrecovered.
- `SummonOperationReceiptStore`, explicitly scoped to one-shot tutorial operations and backward-compatible with schema-1 tutorial receipts.

## Existing behavior routed through the seam

- `(50,1,1)` Small tutorial: deterministic Lavia Hero result + separate `reward={50001002,10}`.
- `(50,3,1)` Medium tutorial: deterministic Pandaria Hero result, no invented side reward.

The new result renderer changes representation internally, not the expected stock wire shape.

## Still deferred

- ordinary Small/Medium paid result generation;
- duplicate-to-fragment activation conditions and quantities;
- SX selected-Hero/25-pull guarantee algorithm;
- counter transitions and paid operation identity;
- Magic MID70/71 result/reward/stick_items ownership;
- all unrecovered summon RNG.

## Validation

Static/syntax/JSON/effective-source/protected-file/archive checks only. No Flask, HTTP, selftests, ADB, emulator or gameplay execution.
