# v0.9.1 Pass69.1 — Item Sale Settlement Hotfix

## Runtime finding
The user Pass69 smoke issued four MID82 `SELL_ITEM` calls. Every response was `error_code=0, awards=[]`; the client removed the sold stacks locally, but server Mana did not increase. No Python traceback, HTTP 5xx, fallback dispatch, or other nonzero engine response occurred.

## Source contract
- `SelfPlayer:sellItem()` / `sellItems()` remove requested Backpack stacks only after backend success.
- `SellDetailWindow` computes generic unit sale value from `xyd.tables.item:mana(item_id)`, falling back to `crystal(item_id)` only when Mana is zero.
- `Backend:extraWebResponseCheck_()` applies `economy_` globally.
- Inscription and Dorm-key items visibly override generic sale with specialized resolve/exchange paths. Horcruxes are generated instances, not ordinary Backpack stacks.

## Fix
Adds `ItemSaleCatalog` (4564 source-derived sale-price rows), `InventorySaleService`, and live MID82/MID86 settlement. Each accepted request becomes one immutable MutationPlan containing STACK debits plus aggregated RESOURCE credits. The active PlayerUnitOfWork preflights the full plan and commits stack/resource state, slice revisions, state_version and semantic `economy_` projection atomically.

The compact runtime GameDataCatalog contains only 428 item rows and does not contain every legitimate persisted Backpack item (for example Cushion 50001012). Pass69.1 therefore permits a debit-only STACK operation for an existing persisted stack when the owning domain supplies separate source-derived authority. Unknown STACK credits remain fail-closed.

## Runtime retest
Preserve existing data. Sell one PSP/Cushion and verify Mana increases by the displayed amount; restart/relogin and verify both the item count and Mana persist. If available, test multi-item Sell (MID86). Return `debug.zip` before Pass70.
