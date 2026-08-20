# v0.8.17 / Pass40.2 — Typed Tutorial MID50 Dispatch

## Scope

This revision implements the Pass40.2 tutorial-only MID50 plan. It does not implement the general Vending/Gacha system.

## Typed operation dispatch

`data/summon_operation_catalog.json` records source-derived/config-corroborated MID50 operation descriptors keyed by `(protocol_mid,summon_type,summon_index)`. `SummonOperationCatalog` is immutable metadata; `SummonOperationRegistry` maps only explicitly supported descriptors to tutorial strategies. Unsupported or unknown tuples remain fail closed.

Active keys:

- `(50,1,1)` — tutorial Small Vending free-first, deterministic Lavia via mapped special pool 200005.
- `(50,3,1)` — tutorial Medium Vending free-first, deterministic Pandaria via mapped special pool 200006.

## Small EXP Juice reward

For `(50,1,1)`, the canonical transaction now includes inventory grant `50001002 x10`. Item identity is from `summon.lua` row1 `summon_reward`; quantity is Pass40's source-corroborated Summer Quiz result. The RewardTransactionService owns the canonical Backpack mutation. MID50 projects the side reward only as:

```text
reward = { item_id = 50001002, item_num = 10 }
```

It is not duplicated into any other client-mutating award channel.

## Exact-once tutorial receipt

The successful one-shot Small tutorial operation stores a complete response receipt under canonical Summon state. While the client is still inside the mapped recovery window, a retry returns that stored response without re-running Hero or Inventory mutation. Guide state bounds replay only; it never grants the operation.

A migration/adoption branch exists only for canonical pre-Pass40.2 state that already has both Lavia and `tutorial_mana_done=1` but lacks the new receipt. Since v0.8.16 never granted this MID50 side reward, the branch atomically grants the missing x10 reward once and creates the receipt.

## Explicit non-scope

No general Mana/Crystal/SX RNG, paid cost spending, free-reset policy, coupon/discount logic, Gachapon MID70/71, MID59 synthesis change, Backpack Ghost Item repair, Campaign RNG change, Function33/TutorialMilestone change, or Pass29 compatibility-policy change.
