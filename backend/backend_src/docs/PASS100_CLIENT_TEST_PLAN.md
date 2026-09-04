# Pass100 MID97 client smoke plan

Pass100 is not runtime-accepted until the patched client has installed OTA resource version `1.631.4` and the following behaviors are observed.

1. Cold start on a client currently at resource `1.631.3`; verify MID2 advertises/install `1.631.4`, then the client restarts normally.
2. With Energy below 500 and sufficient Crystal, press `+` and purchase once. Verify exactly +120 Energy, exact ordinal-1 cost 50 Crystal, and `buy_energy_times=1`.
3. Purchase again on a VIP level with allowance for a second buy. Verify ordinal-2 cost is also 50 and the counter becomes 2.
4. Verify a later ordinal crosses the source cost ladder (ordinal 3 costs 100).
5. Verify the UI refuses a new purchase when current Energy is already >=500. A purchase started at 499 may legitimately end at 619.
6. Verify VIP daily allowance is enforced. If an active Monthly Privilege test profile exists, verify its +4 allowance without modifying card-day state.
7. Simulate/reproduce a transport retry if practical. The repeated MID97 request must carry the same `energy_op_id`; server state must show only one Crystal debit, one +120 Energy credit, and one counter increment.
8. Cold restart after purchases and verify Crystal, Energy, `buy_energy_times`, and receipts persist.
9. Cross the next canonical 05:00 GMT+8 reset boundary. Verify `buy_energy_times` returns to 0 and a new ordinal-1 purchase costs 50 again; yesterday's receipt must not block the new purchase.
10. Confirm older deterministic consumables and Campaign sweep debits remain intact.

If all checks are clean, formally runtime-accept Pass100 before resuming RandomOutcomeService work.
