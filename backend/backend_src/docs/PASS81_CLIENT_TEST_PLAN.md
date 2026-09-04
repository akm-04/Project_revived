# Pass81 Client Test Plan — Quick Enchant + Super Campaign Corrections

- Start from a persisted player state where Quick Enchant has already been used once during the current source day. Confirm a second same-day Quick Enchant is rejected as before.
- Cross the canonical 05:00 GMT+8 boundary naturally or with a deterministic backend clock setup. Reopen Quick Enchant and verify MID28 now reports the Quick Enchant slot as unused and one new Quick Enchant succeeds.
- Restart the backend after that rollover, reload the same player, and confirm the cleared Quick Enchant counter stays cleared until the new day's one use is consumed. This specifically checks that `{}` is no longer resurrected by JSON persistence.
- If a Task daily cache exists in the test player, verify rollover/restart does not resurrect its stale cached payload. Do not expect Pass81 to generate Daily Mission rows; that domain remains unimplemented.
- Open a Super Campaign stage showing `3/3`. Complete a successful battle and confirm the UI becomes `2/3` from the MID114 response.
- Repeat two more successful canonical battles on the same Super stage. Confirm `2/3 -> 1/3 -> 0/3`.
- At `0/3`, try to start another Super battle. The source UI should block it; if the request is forced/direct, MID113 must reject it and no battle session/reward settlement should occur.
- Exercise a duplicate/retried MID114 for a previously committed success if your proxy/test harness allows it. The returned remaining value must be identical to the original committed response and must not decrement again.
- Cross the next 05:00 GMT+8 boundary and verify the depleted Super row restores to its source daily maximum (`3/3`) with `reset_count = 0` under the existing Pass79 coordinator.
- Sanity-check one Normal Campaign battle after the patch; its behavior and response should remain unchanged.
- Do not use MID116 as part of Pass81 acceptance. Reaching `0/3` may expose the reset/buy UI, but that protocol is still intentionally unimplemented.
- Preserve `server.txt`, client error output, and the resulting player JSON if any count diverges from the expected sequence.
