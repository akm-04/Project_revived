# GXB backend v0.15.8 — Pass131.0

Pass131.0 implements **Campaign MID117 player EXP + Mana settlement** from the source-bounded Pass130 design. Effective `src_64` was rechecked before implementation.

Normal/Super sweep responses now emit one source-shaped `economys` row per run (`exp = energy_cost`, `mana = mana_gain`) and settle cumulative account EXP/Mana atomically through the existing canonical owners. `CampaignSweepEconomyPolicy` is deliberately stateless: `PlayerProgressionService` still owns account EXP/level/function unlocks, `EconomyLedger` still owns Mana/Crystal, and the existing PlayerUnitOfWork + MID117 receipt remains the exactly-once transaction boundary.

For low-level sweep compatibility, cumulative account EXP mirrors recovered `SweepWindow` behavior: 1× base while the simulated pre-run level is `<=10`, then 3× for later rows after crossing above level 10. This is a client-backed **compatibility implementation decision**, not recovered official-server settlement code. Mentor/Student bonus EXP is deliberately deferred with the non-core Social vertical.

MID117 receipt replay still freezes static per-run rows while refreshing cumulative fields from their current canonical owners. Reward-plan validation occurs before entropy; forced post-RNG progression failure rolls back tested EXP, Mana, Energy, Crystal, inventory, receipt and persistence state.

No Lua/OTA, persistence schema, MID113/MID114, Campaign access/progression, Super daily-limit policy, Challenge topology, drop pool, or RNG policy was changed. OTA remains **1.631.8**.

Static/focused validation is accepted. A targeted real-client MID117 smoke is required before advancing to **RNG backbone closure**. See `docs/PASS131_CLIENT_TEST_PLAN.md`.
