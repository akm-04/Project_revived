# v0.9.1 / Pass69.0 — Economy Backbone Part 2

Pass69 installs the generalized scalar and Backpack settlement layer underneath the runtime-accepted Pass68.1 foundation.

## Added
- `EconomyLedger`: canonical owner for all 30 `scalar_ledger` ResourceRegistry descriptors while retaining existing PlayerState storage.
- `StackInventory`: signed, preflighted Backpack stack mutations with `backpack_stacks` slice ownership.
- frozen-contract `MutationPlan` dataclasses and Pass69 executable RESOURCE/STACK leaf operations.
- `MutationSettlementService`: full preflight across scalar + stack owners, UoW journaling, and cumulative economy compatibility projection.
- `RewardTransactionService` now adapts legacy `RewardPlan` scalar/stack grants into typed `MutationPlan` operations.

## Compatibility retained
- `EconomyRepository` remains the public five-field façade. Mana/Crystal now delegate to `EconomyLedger`; Energy stays temporal-compatibility owned and EXP/level stay progression owned until later waves.
- `InventoryRepository` remains the public import and now subclasses `StackInventory`.
- `PlayerState`, JSON persistence, engine/SDK routes, dispatcher, global response semantics and existing ResponseProjector are unchanged from Pass68.1.
- No Campaign/Vows/Workshop/Pet/Store feature implementation was added.

## Validation boundary
Static/offline characterization is complete. Client runtime acceptance remains pending a new user `debug.zip` smoke before moving to the next backbone wave.
