# v0.8.34 / Pass42.14 — Small Vending x100 hotfix

## Runtime bug evidence

The fresh 2026-08-20 debug run followed this exact path: guest login → Lobby → Vending → Small → x10 → result-window x100.

The successful x10 request was MID50 `summon_type=1, summon_index=3` and returned ten rewards. The x100 button then sent MID50 `summon_type=1, summon_index=4`; v0.8.33 returned `{"error_code":1,"result":[]}`. A second x10/x100 sequence reproduced the same rejection. This isolates the defect to the server activation boundary rather than the button, transport, or resource layer.

## Effective-source confirmation

Effective `src_64` independently defines:

- `xyd.SummonType.ManaHundred = 4`;
- Small `summon.lua` cost slots `0|10000|90000|900000`;
- Small pull-count slots `1|1|10|100`;
- `SummonTable:manaHundred()` reads cost slot 4;
- `SummonResultWindow:summonAgain(true)` sends `ManaHundred`;
- the result window has an explicit `#results > 10` path which aggregates identical table IDs and renders them in a scrolling list.

The old backend already contained the correct `small_paid_hundred` 100-pull / 900,000-Mana CostPlan, but its operation descriptor and CostPlan execution status were still deliberately fail-closed from Pass41.

## Fix

Pass42.14 activates only that already-modeled topology through the existing classic private planner. It does not invent a new MID or a new RNG family.

Small x100 now:

- spends 900,000 Mana atomically;
- performs 100 Small result-slot transitions;
- uses the exact same current Small ordinary category/star tuning as x1/x10;
- uses the same recovered special milestone counter topology;
- uses the same duplicate native-star 7/14/30 own-scroll conversion;
- returns 100 normal classic result rows for the stock client >10 display path;
- keeps short-window replay/idempotency so an immediate retry is not charged twice.

The existing private Small x10 `at_least_one_item` guarantee is preserved across bulk purchase by applying it independently to each consecutive 10-result block. Recovered special/milestone-selected slots retain precedence and are not overwritten.

No Medium, SX, Magic/Gachapon, featured rotation, Girl cohort, or Pass42.12 gacha-control rate semantics changed. Ticket/coupon/discount paths remain fail closed.

## Validation boundary

`tools/validate_pass42_14.py` verifies the active `(50,1,4)` descriptor, fixed 900,000-Mana / 100-pull cost, 100-row result policy, ten separate x10 guarantee blocks, one atomic request-scoped x100 transaction, +100 counter progression, replay-without-second-debit, x1/x10 regressions, and `gacha_control.py --check` synchronization.

This is repository/static confirmation. A fresh post-fix client x100 run is still required before marking v0.8.34 Small x100 runtime-confirmed.
