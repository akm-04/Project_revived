# Pass114.0 Technical Changelog — Campaign MID117 Activation

Pass114 moves the Pass113 MID117 foundation from inert to live ordinary-Campaign settlement.

## Wire identity / OTA
OTA 1.631.6 adds `campaign_sweep_op_id=mid117-<UUIDv4>` in `SweepWindow.willOpen()` only after the window has resolved the actual request MID and only when that MID is `SWEEP_CAMPAIGN`. Existing IDs are preserved. Event-specific sweep MIDs are untouched. The override also guards ordinary MID117 local callback mutation when the JSON response carries a nonzero `error_code`.

## UoW lifecycle
`WorldRepository.sweep()` now requires the source-native identity on live request-scoped settlement. It performs committed receipt lookup/replay before mutable gates, source missing-pool preflight before transaction/entropy, a second receipt lookup inside the UoW, VIP/type/cost validation, then one `plan_repeat_sweep()` per requested sweep. All source/operation gates and scalar/stack cost eligibility are validated before Campaign entropy is consumed. Costs, deterministic `sweep_reward`, repeat stacks, and the permanent receipt commit atomically.

## Replay
Receipt domain is `mid117_campaign_sweep`, mode `CLIENT_UUID_V4`, retention `CLIENT_UUID_PERMANENT`. Static authority is exact `items` array-of-arrays, zeroed `economys`, `additional`, and optional `chapter_event`. Current Energy and (for CRYSTAL_SWEEP) Crystal are rendered on replay; Campaign is re-read from current canonical state. No retry consumes entropy or mutates state.

## Policy / missing source
The Pass113 Campaign policy and planner code are unchanged. Positive repeat pool IDs without rows fail with `campaign_repeat_pool_unavailable` before cost/entropy. Zero pool ID is valid. MID113 remains on the unchanged disabled repeat policy.

## Deferred
Campaign EXP/Mana `economys`, awakening `additional`, event sweeps, MID113 repeat RNG, and unrelated RNG domains remain separate.
