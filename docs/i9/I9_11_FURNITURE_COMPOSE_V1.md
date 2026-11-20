# I9_11_FURNITURE_COMPOSE_V1

Lead contract, 2026-11-19, for Sol T33 A-147. Closes the I9_DORM_SOCIAL_GLUE_RANKING_V1 row "Furniture crafting MID83 routing and recipe/glue debit" (OPEN_REQUIRED_FUTURE_INTEGRATION, D494). Owner system: `dormhouse`. Evidence: /home/akm/Chatgpt/EOL_Game/tmp/reality_11t33/workroom-furniture-REPORT.md (fleet_11t33w, tree 0b793627).

## Client facts

- MID 83 COMPOSE_ITEM is sent by FurnitureFactoryWindow.lua:120-129 with a blueprint id (no item_num, compose the blueprint from pieces) and by ProduceConfirmWindow.lua:101-123 with a furniture id and item_num. Reply reader is the OK check only (SelfPlayer.lua:740-765); glue updates through the global economy hook.
- item.lua: furniture row `compose`/`compose_num` = materials, `glue` = glue cost, `formula` = blueprint; blueprint row holds its piece recipe. Blueprint desc1 "Permanently unlocks the method to craft" -> a blueprint is never consumed.
- 53 furniture ids, 53 blueprints, 53 piece ids, 11 materials. Glue is the scalar currency `glue`, not an item.

## Rules

F1. Content: extend dorm_input_catalog to schema v3 with `furniture_recipes` generated from item.lua (furniture id, materials and counts, glue, blueprint id; blueprint id, pieces and count, level). v1/v2 still decode. No new table, no SQL migration; a new content revision is generated and pinned (counts 53/53 pinned in validation).
F2. Dispatch: compose_dispatcher order Book -> Furniture -> Equipment. Furniture claims an id only by membership in the recipe set (furniture id or blueprint id), never by item type. Book and equipment behaviour is unchanged.
F3. Furniture target: in one Serializable transaction and one I5 MaterialExchange, debit materials x amount and scalar glue x amount (glue floor respected), grant furniture x amount. The blueprint must be owned (count >= 1) and is not debited.
F4. Blueprint target: debit pieces x amount, no glue, grant blueprint x amount. amount defaults to 1 when item_num is absent.
F5. Level gate (PRIVATE_POLICY, recommended): player level >= the blueprint's level, matching the client list filter. No function-70 gate.
F6. Receipt identity and replay follow equipment compose (plan.ReceiptIdentity, receipt resolver): a replay returns the stored reply and settles nothing twice.
F7. Reply 200 `{}`. Refusals: not a recipe, blueprint absent, level too low, insufficient materials or glue -> 409/35028; malformed params (amount < 1, non-integer) -> 400; transient -> 503/35033; never 500.
F8. TestA128ComposeRefusesUnqualifiedCategory stops using 50020001 (a real blueprint) as "unqualified"; pick an id in no recipe set.

## Tests

Dispatcher routing (book, furniture, blueprint, equipment, unqualified). App unit: amount scaling, blueprint not consumed, level refusal, blueprint missing, replay. Native (postgres, production constructor): debits stacks and glue, grants furniture, replay no double settle, each refusal code.
