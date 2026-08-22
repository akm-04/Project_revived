# Pass79 Client Test Plan — Daily Reset Rollover

The canonical reset is **05:00 GMT+8**. In Asia/Dhaka (UTC+6) this is **03:00 local time**.

## Preferred real-boundary smoke

- Keep the client logged in across the boundary; do not relog between the pre-reset setup and 05:00 GMT+8. This specifically exercises the one-shot `daily_updates` notification path instead of the intentional offline-login suppression path.
- Before the boundary, use Quick Enchant once on a valid ordinary Girl equipment slot. Confirm a second use is rejected by the daily limit.
- Before the boundary, buy Skill Points at least once and note that `buy_skill_times` is non-zero. If Mana/Energy purchase UIs are currently available in your build, note those counters too; their handlers remain otherwise out of scope.
- Open/inspect Super Campaign and note a representative unlocked Super stage. Natural Pass75 gameplay does not yet exercise every attempt mutation, so the important client check is that the map remains healthy after rollover; backend logs/state can confirm source `daily_limit=3` and `reset_count=0` restoration.
- At 05:00:01 GMT+8, watch the backend log. The client's timer should generate the Daily Mission/Activities reload fanout. The first MID229 `ACTIVITIES` or MID2736 `TASK_LOAD_BY_TYPE` that materializes the new day should carry the reset; no server restart should be required.
- Immediately retry Quick Enchant. It should be available once again for the new source day, and a second same-day use should again be blocked.
- Buy Skill Points again and confirm the daily purchase ordinal restarted from the first purchase of the new day rather than continuing yesterday's `buy_skill_times`.
- Reopen Campaign/World Map and confirm it loads cleanly. Inspect persisted state/logs if desired: source-owned Super rows should have `daily_limit=3`, `reset_count=0`.
- Open the Daily Task window and Activities/Sign-facing UI once. Confirm there is no Lua crash and no malformed Task bootstrap. Pass79 does not generate Daily Mission rows or implement Sign; this is a cache-invalidation/shape-safety check only.
- Continue making normal requests for several minutes and reopen Activities/Tasks. `economy_.daily_updates` must **not** repeat during the same source day; Sign/cache state should not be repeatedly cleared.
- Restart the backend/client after the rollover and verify state remains on the new day. Restart alone must not grant another Quick Enchant or reset `buy_skill_times` again.

## Offline-login suppression check

- Stop using the client before a source-day rollover, then log in only after 05:00 GMT+8.
- The first player-bound bootstrap request may materialize the overdue reset before MID229/MID2736. This is intentional: canonical counters/world state should already be current in later loaders, and Pass79 should **not** fabricate a stale `daily_updates` pulse merely because the player was offline.
- Verify Quick Enchant and Skill Point daily counters are reset once, but repeated Activities/Task requests after login do not trigger another reset.

## Deterministic backend check (no waiting)

Run:

```bash
PYTHONPATH=. python3 tools/selftest_pass79_daily_reset.py
```

Expected final status: `PASS`, 11 checks, boundary `05:00 GMT+8`, notification MIDs `[229, 2736]`.
