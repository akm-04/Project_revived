# Pass94 Client Smoke — Player EXP/Level Ownership

Use a fresh or otherwise low-level account whose pre-fight EXP/level/Energy are known.

1. Cold start and capture MID1 `exp`, `lev`, `energy`, and `max_energy`.
2. Clear a normal Campaign stage that grants ordinary Player EXP.
3. Inspect MID114 / ECONOMY behavior:
   - cumulative `exp` increases by the existing source amount;
   - any crossed Academy levels match `player.lua.total_exp` thresholds;
   - each crossed level contributes its source `award_energy`;
   - current Energy may be above the new normal cap after the award;
   - no duplicate EXP/level award occurs on a duplicate/replayed committed result.
4. Cold restart server/client and confirm `exp`, `lev`, Energy, max Energy, and newly eligible/announced Function state persist.
5. Continue one additional ordinary Campaign result and confirm progression continues from the persisted cumulative EXP rather than resetting/reinterpreting it as per-level EXP.

For the canonical level-1 source rows, cumulative EXP 18 reaches level 4 and the crossed levels award 18 Energy total. If the first normal stage also costs 6 Energy, a starting 60 Energy would therefore settle to 72 after the win (`60 - 6 + 18`). Use actual captured pre-fight values rather than forcing this example onto a differently seeded account.

If this smoke is clean, runtime-accept Pass94 and perform a reconciliation pass before implementing RandomOutcomeService.
