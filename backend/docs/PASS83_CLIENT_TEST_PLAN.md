# Pass83 Client Test Plan — Cold MID1 Rollover + Temporal Hygiene

- Prefer a clean monotonic player baseline for the primary acceptance run. If the player previously visited a future source day through OS time travel, either reset that test state or advance beyond the persisted `daily_reset_state.current_day_id`; merely catching up to the same high-water day must not reset again.
- During source day N, consume Quick Enchant once, deplete a Super Campaign stage to `0/3`, and make at least one Skill Point purchase so `buy_skill_times > 0`.
- Close the client and backend before the next 05:00 GMT+8 boundary.
- Advance to source day N+1 (or naturally wait past 05:00 GMT+8), start the backend, then cold-start/login the client. The first MID1 should itself materialize the daily reset.
- In `server.txt`, look for `[DAILY_RESET] materialized ... mid=1 ... reset=1 ...` before the first post-login temporal/bootstrap state is returned.
- Immediately open Quick Enchant. MID28 should show consume slot 2 unused and exactly one Quick Enchant should succeed.
- Immediately open Super Campaign. The depleted stage should already be `3/3` from MID1 `detail[112]`; it should not require a later MID112 reload to become current.
- Inspect Skill Point purchase pricing/ordinal. `buy_skill_times` should already be reset in MID1 `detail[17]` and the first purchase should use the source first-purchase cost.
- Verify Energy, Spirit Energy (if visible), and Girl Skill Point timers/balances behave normally after login. No pool should drop because its projected anchor is ahead of MID1 `server_time`.
- For an adversarial rollback test, move the host clock backward while retaining a future `daily_reset_state.current_day_id`. The log should show `[DAILY_RESET] clock_regression_ignored` with `stored_day_id` and `observed_day_id`, and no daily entitlement should reopen.
- Move forward only until the observed day equals the saved high-water day: still no reset is expected. Then cross into high-water+1 and confirm exactly one reset occurs.
- Restart again within the same source day and verify Quick Enchant/Super/purchase counters do not reset twice.
- Do not exercise MID116/117/118 as part of Pass83 acceptance; they remain intentionally unimplemented.
- Preserve `server.txt`, client errors, and the resulting per-player JSON if any bootstrap value differs from the expected state.
