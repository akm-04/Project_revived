# Pass131.0 Client Smoke Plan

Use backend **v0.15.8-pass131.0** with existing OTA **1.631.8**. Capture the complete server log around MID117 requests.

1. **Normal 1× sweep, account level >10** — choose any 3-star Normal stage. Record EXP/Mana/Energy before and after, then sweep once. Expect non-zero per-run `economys`: raw EXP equal to the stage `energy_cost`, Mana equal to `mana_gain`; cumulative account EXP should rise by `3 × energy_cost`, Mana by `mana_gain`, and Energy by the existing cost rule.
2. **Normal multi-sweep** — perform the usual 10× sweep if available. Confirm every `economys` row is non-zero/source-shaped and cumulative EXP/Mana move once by the total batch amount.
3. **Super sweep** — sweep a 3-star Super stage with remaining daily attempts (1× or 2×). Confirm the same EXP/Mana behavior and that `daily_limit` decrements exactly once per run.
4. **Optional Crystal sweep** — if convenient, use the Crystal sweep path and confirm Crystal, Energy, EXP and Mana all remain synchronized.
5. **Optional low-level boundary** — only if easy to arrange, use an account near level 10→11 and perform a multi-sweep crossing the threshold. The early row(s) should settle at 1× base, later row(s) at 3×; level-up Energy and Function31/Elite Campaign presentation must remain coherent.

Please return `server.txt` (and any client error/crash log if one appears). Do not force the optional low-level case if it is inconvenient.
