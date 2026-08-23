# Pass92.0 Client Test Plan

1. Use an account with Super Campaign unlocked. VIP2 is ideal for the cleanest allowance test; the legacy VIP15 account is useful for multi-reset pricing.
2. Clear one Super stage until it reaches `0/3`.
3. Tap the reset/buy button. At reset count 0, the client should display a **20 Crystal** cost.
4. Confirm the purchase. Expected immediate result: stage returns to `3/3`, `reset_count=1`, stars remain unchanged, and Crystal drops by exactly 20.
5. Restart client/backend before consuming those attempts. The stage must remain `3/3` with `reset_count=1`; no second charge occurs.
6. On VIP2, consume the three restored attempts back to `0/3`. A second paid reset must be rejected because source VIP2 has only one daily paid reset.
7. On a higher-VIP account, repeat: second reset should cost **50 Crystal**, third also **50**, then **100**, following `refresh_cost.lua`.
8. If you have an account with `privilege_left_card_day > 0`, verify its paid-reset allowance is VIP allowance +3. Pass92 must not decrement the card-day field.
9. Verify a Normal Campaign stage never exposes/accepts MID116 paid reset behavior.
10. Across the next 05:00 GMT+8 boundary, verify Super attempts restore to the source baseline and `reset_count` returns to 0, so the next paid reset again starts at the 20-Crystal ordinal.
11. Preserve `server.txt` and the player JSON if Crystal, `daily_limit`, `reset_count`, stars, or daily rollover differ.

MID117/118 are not part of this smoke.
