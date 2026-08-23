# Update notes — v0.13.1 / Pass105.0

- Runtime-reconciled Pass104 without reopening Store/Sky Tower UI work.
- Promoted eight session entry contracts from `DEFER_PHASE2` to `BLOCK_PHASE2`.
- `START_FIGHT`, `ARENA_MODE_FIGHT_PRE`, `ARENA_MODE_FIGHT`, `ARENA_PRE_FIGHT`, `MARCH_START_FIGHT`, `WORLD_BOSS_START_FIGHT`, `PET_CAMPAIGN_FIGHT`, and `PEAK_START_FIGHT` now fail closed with canonical HTTP409 before battle/session entry.
- Terminal result contracts remain deferred; no generic 30005 drain was activated.
- No RNG, Summon probability, Campaign reward, Store, Arena, Pet, March, or World Boss feature behavior was implemented.
