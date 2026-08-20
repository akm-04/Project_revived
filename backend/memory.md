# Current backend revision — Pass42.14 / v0.8.34

Pass42.14 is a narrow Small Vending x100 hotfix. Fresh runtime evidence showed the client sends MID50 `(summon_type=1,summon_index=4)` after pressing the result-window 100x button; v0.8.33 returned `error_code=1,result=[]` because the operation remained `deferred_fail_closed`. Effective Lua confirms `ManaHundred=4`, Small cost slot4=900000 Mana, pull slot4=100, and a >10-result scrolling/aggregation UI.

The operation is now active under the existing classic private planner. Small x100 spends 900000 Mana atomically, produces 100 standard result rows, advances the same `small_classic` counter one slot per result, uses the same Pass42.12 configurable category/star rates, and preserves duplicate 7/14/30 conversion. The Small `at_least_one_item` x10 guarantee is applied separately to each consecutive 10-result block in the x100 purchase; special milestone slots are never replaced.

No Medium/SX/Magic/Gachapon behavior changed. Ticket/coupon/discount paths remain fail closed. Pass42.14 implementation is static/repository-confirmed; a final live x100 client smoke remains the only runtime promotion gate.
