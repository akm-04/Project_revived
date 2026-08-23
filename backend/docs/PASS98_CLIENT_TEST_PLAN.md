# Pass98.0 Client Test Plan

Pass98 is not runtime accepted until this focused smoke is reconciled.

1. On an account holding Kanto Food (`50001015`), record Backpack count and Energy; use one item and verify exactly +18 Energy and exactly -1 item. Repeat with multiple quantity if the UI permits.
2. Use Tonkatsu (`50001016`) and verify exactly +30 Energy per item. If current Energy is near/above max, confirm consumable Energy can exceed the ordinary regeneration cap as the source allows.
3. Cold restart and verify Energy and Backpack counts persist.
4. Use representative MID87 Event Centre consumables for `magic_energy`, `magic_dust`, and `magic_liquid`; verify exact resource deltas, exact item debits, and restart persistence.
5. Where available on the sandbox, dissolve one of the formerly unmapped Honor Inscription variants (`160200111/112` through `160200711/712`) and verify the source certificate currency is granted.
6. Attempt Pet EXP item use (MID134). It should fail rather than report success/delete the item; verify Backpack persistence after restart.
7. Do not use random gift/chest items destructively for acceptance; MID241 remains intentionally fail-closed until shared RNG exists.

If this smoke is clean, formally runtime-accept Pass98 and reconcile before the next implementation slice. The strongest immediate QA-unblock candidate is bounded MID97 stamina purchase.
