# Pass131.0 Technical Changelog — Campaign Player EXP + Mana

Pass131.0 implements the source-bounded MID117 Campaign sweep EXP/Mana plane designed in Pass130. It does not change OTA/Lua, Campaign authorization, Campaign RNG policy, drop pools, Super progression, persistence schema, or manual MID113/MID114 settlement.

## Added
- `CampaignSweepEconomyPolicy`: a stateless deterministic policy that plans one wire `economys` row per successful sweep plus cumulative account EXP/Mana totals.
- Pass131 focused self-test covering Normal, Super, multi-sweep, level 10→11 transition, receipt replay, Crystal sweep, fail-before-RNG validation, UoW rollback, and deliberate Mentor/Student exclusion.

## Reused canonical owners
- `RewardTransactionService` remains the typed reward adapter.
- `PlayerProgressionService` remains sole account EXP/level/function-unlock owner.
- `EconomyLedger` remains Mana/Crystal scalar owner.
- `MutationSettlementService` + `PlayerUnitOfWork` remain the atomic cost/drop/reward/receipt boundary.
- Existing MID117 UUID receipt remains exactly-once authority; static per-run `economys` are frozen while cumulative `economy_` is refreshed from current canonical owners on duplicate replay.

## Wire/settlement policy
- Each successful Normal/Super sweep returns `economys[i].exp = energy_cost` and `economys[i].mana = mana_gain`.
- Cumulative account EXP mirrors the client-visible low-level curve: 1× base while the pre-run simulated level is `<=10`; after crossing above 10, subsequent rows use 3×.
- Total Mana is `mana_gain × sweep_num`.
- Mentor/Student bonus EXP remains intentionally deferred with the Social vertical.

## Safety
Reward validation runs before Campaign entropy/cost mutation. EXP/Mana application occurs inside the same active PlayerUnitOfWork as existing MID117 costs, item awards, Super attempt mutation, and receipt staging. Forced post-RNG progression failure restores all tested state and stages no receipt/save.

## Compatibility boundary
The low-level multiplier settlement is an `IMPLEMENTATION_DECISION` supported by recovered client behavior, not a claim about original-server internals.
