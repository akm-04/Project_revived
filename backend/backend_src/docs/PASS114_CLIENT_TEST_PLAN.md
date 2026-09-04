# Pass114.0 Client Runtime Test Plan

1. Boot client and confirm silent OTA advances resource version to 1.631.6.
2. On an ordinary Campaign stage with a populated repeat pool, perform ITEM_SWEEP 1x and verify Energy/Ticket decrement once and returned drops appear.
3. Perform multi-sweep and verify each sweep renders its own item group.
4. Perform CRYSTAL_SWEEP and verify Energy + one Crystal per sweep debit.
5. Force-close immediately after pressing Sweep, reboot, and verify committed costs/rewards exist exactly once.
6. Retry/poor-network path must not reroll or double debit.
7. Verify ordinary Campaign stages with `repeat_dropbox_id=0` still sweep normally with deterministic rewards and no repeat RNG.
8. If accessible, attempt one of the 24 missing positive pools (chapters 22/23): server must reject without persistent Energy/Ticket/Crystal loss; OTA callback guard must avoid local Ticket/reward mutation.
9. Smoke MID113 normal Campaign battle result to ensure repeat battle RNG remains disabled/unmodified.
10. Smoke one event-specific sweep (if available) to confirm it did not receive the MID117 UUID bridge.
