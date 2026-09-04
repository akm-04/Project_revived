# Pass75.0 Client Test Plan

- Login as anonymous debug UID `13371337`; confirm later Normal chapters and Elite/Super nodes are accessible.
- Normal Campaign Energy: record Energy, clear campaign `100001`, verify exactly **6 Energy** is consumed and cumulative Energy is reflected.
- Different source cost: clear `100002` and verify **9 Energy**, proving the server is not hardcoded to 6.
- Defeat cost: if convenient, lose campaign `100001` and verify only **1 Energy** is consumed.
- Elite/Super: run one accessible Super/Elite stage and verify its source-specific Energy cost is deducted (for source row `100019`, victory is **12**, defeat **2**).
- Campaign rewards: verify deterministic Mana/Crystal/player EXP/Hero EXP and unlock state still arrive together with Energy settlement.
- Result authority: do normal client play only; any duplicate/retry should not duplicate settlement.
- Awakening Task: click Awakening gear, then open Lobby -> Missions -> Awaken Task. TaskWindow should no longer crash on the DAILY bootstrap and the Awaken mission should be visible.
- Awakening stage 2: use the unlocked map to run the exact required Campaign stage and satisfy the Girl-specific objective; verify completion/final claim if practical.
- Breakout/Stone Evolution: complete a Stone stage, advance to the next tier, relog, then add a point in the new tier. Old stage points must not resurrect.
- Certificate audit: dissolve one genuine Degree, Graduate, and Patent inscription/emblem if convenient; verify `degree_cer`, `graduate_cer`, and `patent_cer` respectively increase. IDs outside the Inscription catalog may correctly reject.
- Quick Enchant regression: one same-day use should still work without freeze; second same-day use should remain rejected/no-op.
- Persistence: record Energy, Mana, Crystals, map progress, certificate balances, and the modified Hero state; relog and verify exact persistence.
- Not a Pass75 failure: the 1,225-item debug seed can still trigger the bag-capacity/mail warning.
- Not yet a Pass75 acceptance requirement: Campaign Sweep and Super/Elite daily-attempt/reset ownership remain explicitly deferred.
