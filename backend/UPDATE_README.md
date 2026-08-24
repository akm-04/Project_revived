# Update notes — v0.15.8 / Pass131.0

- Implemented Normal/Super MID117 per-run `economys.exp` and `economys.mana`.
- Added cumulative player EXP + Mana settlement through existing `RewardTransactionService` owners.
- Added source-bounded low-level sweep EXP compatibility policy (1× through simulated level 10, then 3×).
- Preserved Mentor/Student EXP as deferred non-core Social scope.
- Extended MID117 replay projection to refresh PlayerState-owned EXP/level/Energy and EconomyLedger-owned Mana/Crystal from current canonical state.
- Preserved existing UoW/UUID receipt exactly-once behavior and Super daily-limit semantics.
- No OTA/Lua, schema, MID113/MID114, Campaign RNG/drop or authorization changes. OTA remains **1.631.8**.
- Static/regression accepted; targeted client MID117 smoke required before RNG roadmap work.
