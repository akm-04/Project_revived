# Pass182 Client Smoke Plan — MID57 / Girl Gear Packs / P2 Fence

Use the established anonymous dev/sandbox account and preserve `debug.zip` after the run. Do not clear server state between the pre/post-restart checks unless a step explicitly says so.

## A. MID57 max_color threshold reconciliation

1. Login and verify the account still reports `max_color=5`.
2. Choose a Normal Girl below color 5 with ordinary promotion gear available. Apply some Fumo to an equipped ordinary item if practical, then use one-click promotion. Expected: MID57 promotes normally; color increments; ordinary current-tier equipment clears; Fumo restoration award UI may appear when refundable value is non-zero.
3. Continue the same or another Normal Girl to color 5. Before promotion, put Fumo on at least one current ordinary equipped item and leave at least one ordinary slot uncollected.
4. Press one-click at color 5. Expected: successful MID57, current ordinary tier becomes fully collected, **color stays 5**, existing Fumo stays visible, and no Fumo restoration award is returned.
5. Press the ordinary Advance/Max button. Expected: MID51 promotes to color 6, current ordinary equipment/Fumo clear, and any refundable Fumo materials are restored here.
6. Repeat one two-step promotion above the threshold (for example color 6→7): MID57 equips-only, then MID51 promotes.
7. If practical, repeat near terminal color 15: MID57 equips-only at 15, MID51 promotes to 16. At color 16 there must be no further successful promotion.
8. Re-check quick/manual Fumo behavior after this synchronized sequence. Record any `getFumoLev` errors only if they still occur after the MID57 fix.

## B. Girl Gear Pack deterministic settlement + persistence

1. Re-login once after upgrading the backend so the Pass182 sandbox migration applies. In Backpack, reverse/sort by quantity as previously used; the 199 Girl Gear Pack stacks should be easy to find around quantity **7**.
2. Open one representative pack whose materialized corpus reaches a Purple target stage. Record pack item id/name and the Girl-specific equipment awards. Expected: pack quantity decreases from 7, deterministic equipment is granted, no ROS/random behavior.
3. Open one representative pack whose materialized corpus reaches Red+1. Record pack item id/name and awards. Expected: same deterministic source-shaped materialization.
4. Restart backend/client and re-login. Expected: consumed pack counts remain reduced (the one-shot fixture does **not** replenish), and awarded equipment remains in inventory.

## C. Awakening/Blood-Awakening P2 fail-closed fence

1. Prepare a **non-Super** Girl at the first ordinary promotion stage whose current equipment list contains an Awakening or Blood-Awakening special item.
2. Before attempting promotion, record/screenshot: Hero color, all six ordinary equip collected states, Fumo values/levels, relevant special-item ownership, and nearby inventory counts.
3. Attempt the promotion path that sends MID57 or MID51 for that stage. Expected: transport-safe HTTP409/error response; no color change; no ordinary/special equip clearing; no Fumo restoration/clear; no item/Mana mutation.
4. Restart backend/client and re-login. Expected: every recorded field/count remains unchanged. This validates only the safety fence; it is **not** an Awakening implementation test.

## Capture

Return `debug.zip` containing server/client request logs after all practical sections. Note which sections/steps were not reachable in the stock client so they are not misclassified as failures.
