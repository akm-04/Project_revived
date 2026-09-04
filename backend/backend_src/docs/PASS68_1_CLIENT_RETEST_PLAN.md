# Pass68.1 Client Retest Plan

**Goal:** verify the isolated Medium/CrystalFree hotfix and confirm Pass68 Economy Backbone Part 1 remains runtime-stable.

## Preserve state

- Keep your current `data/server_state` / legacy `data/player_db.json` exactly as they are. This continuity is desirable for migration testing.
- Do **not** clear Android app data for this retest.
- Continue copying the same `res` tree into `local_assets` as you did for Pass68.0.
- Restarting the backend and client is sufficient. Clear app data only if the client itself becomes stuck for an unrelated cache/UI reason.

## Targeted sequence

1. Start `gxb-backend-v0.9.0-pass68.1` and confirm the banner says `Pass68.1 Economy Backbone Part1 + Medium free runtime hotfix`.
2. Login with the same existing account and verify lobby/Girls open normally.
3. Open Vending Machine → **Medium**. The failed Pass68.0 free request should not have consumed the cooldown, so the free single should still be ready unless some other successful free pull occurred.
4. Tap **Medium Buy 1 (Free)** exactly once.
   - Expected request: MID50 `summon_type=3`, `summon_index=1`.
   - Expected response: `error_code=0` and exactly one result.
   - Expected cost: **no Crystal debit**.
   - Expected: result window opens normally; no empty popup/stuck state.
5. Close/reopen Medium immediately. The free pull should now be on its rolling **46-hour cooldown** rather than still ready.
6. Restart the client, login again, return to Medium, and confirm that cooldown remains. Do not wait 46 hours. This is the persistence/replay check.
7. Perform one **paid Medium x10** if affordable and confirm Crystal decrements once and results display normally.
8. Perform one **Small** summon (x1 or x10) to guard the neighboring classic route.
9. Perform one small economy mutation such as a Girl skill upgrade/Mana spend and verify the displayed balance changes correctly.
10. Complete one Campaign battle and confirm the reward/balance response still behaves normally.
11. Stop the server cleanly and send the new `debug.zip` including `server.txt` and request/client logs as before.

## What not to reset

Do not delete existing server/player data and do not clear app data merely for this test. We specifically want to prove that Pass68.1 works across the same persisted player created before the new persistence envelope.

## Acceptance rule

Pass68.1 closes only if the free Medium request returns successfully, the cooldown persists across restart, there are no new traceback/HTTP-500 errors, and the neighboring economy/gacha/Campaign probes remain clean.
