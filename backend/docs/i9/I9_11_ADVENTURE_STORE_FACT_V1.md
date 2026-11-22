# I9_11_ADVENTURE_STORE_FACT_V1

Lead contract, 2026-11-19, for Sol T33 A-144. Owner systems: `shop` (producer) and `adventure` (consumer through the objective catalogue). Evidence: /home/akm/Chatgpt/EOL_Game/tmp/reality_11t33/adventure-store-REPORT.md (fleet_11t33a, tree 0b793627).

## Rules

S1. Fact kind: add `objective.ShopPurchaseKind = "SHOP_PURCHASE"`. The objective catalogue maps it (EventForFactKind) to the Adventure event profile for event 10003 (Adventure Store), so the task row the client shows advances.
S2. Producer: the shop Service receives an `ObjectiveFacts` port in its composition (shop_composition.go, cmd/gxb-api/main_postgres.go). Its purchase settlement records exactly one SHOP_PURCHASE fact through RecordTx in the same transaction, only when the purchase debits more than 0 crystal and only on the first settlement (never on a receipt replay, never on a refused purchase).
S3. PRIVATE_POLICY (logged for review, recommended): every shop counts; purchases only (refresh is not a purchase); no minimum spend; one fact per purchase command whatever the quantity.
S4. Docs: I9_ADVENTURE_POLICY_V1 lists SHOP_PURCHASE as the 10003 producer and removes 10003 from never_before_producer; I9_ADVENTURE_V1 C2/C4 name the shop producer. Both edits are made by the build task through contract_registry absorb, not by hand.
S5. No migration. No new MID. Refusal codes unchanged.

## Tests

- Unit: catalogue maps SHOP_PURCHASE to event 10003.
- App: crystal purchase records one fact; coin-only purchase, refused purchase and receipt replay record none.
- Native (postgres): a production-constructor crystal purchase advances the 10003 task; update i9_8d_adventure_native_test.go:218-228 (never_before_producer expectation) and the i9_11c core shops native.
