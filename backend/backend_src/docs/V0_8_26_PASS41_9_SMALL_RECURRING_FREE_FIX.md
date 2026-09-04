# v0.8.26 / Pass41.9 — Small recurring-free compatibility fix

## Runtime regression proved

The 2026-08-19 debug bundle shows a registered tutorial account completing the deterministic first Small free pull, leaving `mana_free_num=4`, then returning after more than the recovered 600-second Small-free interval. The stock client sends the same MID50 `(summon_type=1, summon_index=1)` tuple for free pull #2. v0.8.25 incorrectly treated that tuple as tutorial-one-shot-only and returned `{error_code:1,result:[]}`, which the HTTP-200 callback rendered as an empty non-dismissible Summon result window.

## Fix

- Pull #1 is unchanged: deterministic Lavia plus the one-time `50001002 x10` tutorial reward.
- After the tutorial one-shot is complete, the same MID50 `(1,1)` tuple is accepted when `mana_free_num>0` and the recovered 600-second interval has elapsed.
- Later free pulls use the normal Small Custom Private Server Policy planner, cost no Mana, advance the shared Small result-slot counter, decrement `mana_free_num`, and update `mana_free_time`.
- No free-count replenishment/reset calendar is invented.
- Repeatable free requests use the existing 1.5-second private replay protection to avoid double mutation on transport retry.
- No Small/Medium paid RNG rates were changed. No SX behavior was activated.

## Duplicate smoke evidence in the same bundle

The run also runtime-confirms all three recovered global duplicate quantities: Lavia/native 1-star -> 7 fragments, Blowie/native 2-star -> 14 fragments, and Yukimura/native 3-star -> 30 fragments.

## Remaining balance note

The user's repeated Medium 10x test visibly produced many native 3-star Girls. This is a private-policy balance observation, not a protocol regression. The active rate tables are intentionally left unchanged in this maintenance pass; future tuning should use the documented category/tier/candidate weighting seams.
