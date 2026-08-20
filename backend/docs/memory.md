# Current backend revision — Pass42.12 / v0.8.33

Canonical predecessor: v0.8.32 / Pass42.11. The user-supplied `startup_debug.txt` confirms Pass42.11 startup-debug fresh-seed behavior and fixed-seed reproducibility in repeated real server starts.

Pass42.12 adds root `gacha_control.py`, a self-contained stdlib operator utility with exactly four machine menus: Small, Medium, SX, Gachapon. It validates all relevant private policy files before writing, selects hotspot/New-Add Girls by canonical name/ID cohorts, creates timestamped backups, and writes atomically.

Shipped development default is now `selection_mode=startup_debug`, `debug_seed=0`; `calendar_deterministic` remains supported and retains the known Pass42.10 calendar snapshot.

New `data/classic_vending_balance_policy.json` is opt-in. Disabled means the exact pre-Pass42.12 classic two-stage math remains active. Enabled allows explicit Item/Girl-scroll/Full-Girl class rates and native 1★/2★/3★ full-Girl rates. Girl scrolls are identified only through effective `partner.stone_id`; explicit Scroll category candidates are flat/equal. Medium ordinary effective pool remains 143 Girls (13 native1★ / 33 native2★ / 97 native3★).

Guardrails stay fixed: Small x10 item-class guarantee, Medium x10 full-Girl guarantee, SX selected-hotspot guarantee=25, Medium New-Add pity=20. The tool can tune Medium New-Add chance/identity, SX private class/hotspot/candidate/static-item weights, and Magic x10 scroll-quantity/byproduct weights.

Critical maintenance contract: any later core gacha drop-class/policy-schema/cohort/guarantee/classification change must update `gacha_control.py`, its docs and validation in the same pass.

Pass43–45 remain reserved pure RNG/drop research.
