# Pass68.1 Runtime Acceptance + Medium Free Hotfix

## Runtime evidence

User smoke on 2026-08-21 preserved the prior `data/server_data` / `data/player_db.json`, copied `res` into `local_assets`, and did not clear client app data. Login/lobby, Girls ownership, three evolutions, skill upgrades, SX/paid Medium/Small summons, Campaign battles/rewards, restart/relogin, and economy changes were observed working. No Python traceback or HTTP 500 appeared.

One request failed:

- `MID50 SUMMON_HERO`
- `summon_type=3` (`CrystalFree`)
- `summon_index=1`
- backend response: `error_code=1, result=[]`

At the request, the server clock was beyond `crystal_free_time + 165600`, so the client's free button was correctly available.

## Root cause

Effective `src_64` proves `SummonWindow:crystalSummon(1)` sends `CrystalFree` type 3/index 1 whenever its projected free timer is ready. `SelfPlayer:getNextFreeCrystalSummonTime()` uses `misc.summon_crystal_free_period=165600` seconds. The backend descriptor, however, routed type3/index1 exclusively through the deterministic Pandaria tutorial handler and rejected established/post-guide players.

## Fix

The tuple is now stateful:

1. Tutorial first pull remains deterministic Pandaria/source milestone 1.
2. Once post-guide, the same tuple is accepted only when the 165600-second cooldown is ready.
3. `summon.lua` row3's recovered milestone topology `1/2/10/30/60 -> 200006/200014/200004/200004/200004` is retained.
4. Because the historical server counter carrier and RNG math are unrecovered, a monotonic `private_medium_free_result_counter_v1` and ordinary selection remain explicitly `PRIVATE_SERVER_POLICY`, not claimed official behavior. Existing Pandaria/tutorial-complete players adopt counter slot 1 so their next free pull reaches source milestone 2.
5. Successful post-tutorial free pulls update `crystal_free_time`, materialize exactly one result through the existing Hero/Backpack/duplicate-conversion seams, and use the existing short retry receipt protection.

Paid Medium, SX, Small, Campaign, and the Pass68 Economy Backbone codepaths are otherwise unchanged.
