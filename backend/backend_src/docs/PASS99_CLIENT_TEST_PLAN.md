# Pass99.0 Client Test Plan

Pass99 is not runtime accepted until this focused smoke is reconciled.

1. Cold-start UID `13371337` and verify one-shot QA inventory: Raid Ticket 50001013 near 900; Fries/Kanto/Tonkatsu near 90; each magic consumable 50001120..50001131 near 900. Existing larger valid quantities may remain larger; the seed never exceeds source stack caps.
2. Record Energy and Raid Ticket quantity. Run a **1× ITEM_SWEEP** on a known Normal Campaign stage. Verify Energy decreases by that stage's `campaign.energy_cost`, Raid Ticket decreases by exactly 1, rewards appear, and all values survive restart.
3. Repeat with **10× ITEM_SWEEP**. Verify Energy decreases by exactly `energy_cost × 10`, Raid Tickets by 10, and deterministic rewards persist. If any required input is insufficient, the request must fail without partial mutation.
4. Where the UI offers **CRYSTAL_SWEEP** because Raid Tickets are insufficient, verify Energy decreases by `energy_cost × sweep_num` and Crystal decreases by exactly `sweep_num`.
5. Confirm an ordinary MID114 battle still consumes the source Energy cost. This is regression coverage only; Pass99 intentionally did not change MID114.
6. Use representative newly seeded MID87 items for magic_energy, magic_dust, and magic_liquid. Verify exact resource and item deltas plus cold-restart persistence, closing the direct runtime gap carried from Pass98.
7. Verify the QA seed is non-replenishing: consume some seeded items, cold restart, and confirm they do **not** jump back to their initial seed target.
8. MID97 remains intentionally unsupported in Pass99. Do not treat its failure as a regression.

After a clean smoke, reconcile Pass99 before deciding whether Pass100 should add a preservation operation-ID bridge for MID97 or resume the shared RandomOutcomeService roadmap.
