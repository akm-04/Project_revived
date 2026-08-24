# Pass122.0 Technical Changelog — Challenge Mode

## Pass121 runtime acceptance

`debug.zip` confirms the Super MID117 daily-limit fix is behaving cleanly at runtime. The observed sequence for Super Campaign `1600017` was: manual MID114 victory -> `daily_limit=2`; MID117 `sweep_num=1` -> `1`; a second independent MID117 `sweep_num=1` -> `0`; no MID117 was emitted while the client was at `0/3`; MID116 reset -> `3`; MID117 `sweep_num=3` -> `0`; again no post-zero MID117 was emitted. All three MID117 requests used distinct operation UUIDs. The log contains no receipt conflict, rollback, Campaign Lua error, or duplicate sweep request. The recurring `clock_regression_ignored` line is the expected DailyResetCoordinator fail-safe and did not restore or ghost attempts.

The trace therefore proves client-side zero-attempt blocking and exact committed decrements. The backend's direct `0/3`/over-limit rejection is additionally covered by `selftest_pass121_super_mid117_daily_limit.py`, because this runtime trace contains no deliberately modified-client MID117 sent after a zero response.

## Effective src_64 feedback loop

Before Challenge behavior was modified, Pass122 re-read the effective source at `app-assets/output/assets/src_64`. Source confirms `CampaignType.CHALLENGE = 24`; stock Challenge MID113/MID114 carry campaign id/type/formation without the Pass117 Campaign battle UUID; `BattleCreate.campaignResult()` separately processes returned `campaigns` and result `items`; and `MapWindow.getTrueCampaignInfo()` directly dereferences successive Challenge variants, making absent branch children a real nil-crash risk.

A non-executing static table parser regenerated the Challenge authority from `campaign.lua`, `chapter.lua`, and `campaign_dropbox.lua`. The result is exactly 144 Challenge rows, 137 raw edges, seven roots, 22 fan-out nodes, and 539 deterministic first-clear award rows. Every recovered positive Challenge init rate is divisible by 10,000. All Challenge rows have `daily_limit=0`, repeat `dropbox=0`, and `sweep_reward=0`.

## Implementation

- Added `ChallengeCampaignCatalog`, a source-generated read-only raw graph catalog. It validates topology counts, parent/child backlinks, seven roots, fan-out count, no sweep/repeat plane, deterministic init rates, and source provenance.
- Added `ChallengeProjectionService`. It preserves only source-known Challenge rows, keeps the best star for duplicate legacy rows, normalizes daily/reset fields to zero, seeds all seven roots behind the bounded Normal `1600016` clear gate, and reaches a fixpoint by materializing every source child of every cleared row. Star-zero nodes never open grandchildren. Rows remain in source order.
- `LOAD_WORLD_MAP` now persists a Challenge repair when normalization changes state and becomes no-op on an already canonical reload.
- Removed the old one-root `24111` synthesis from the fallback `PlayerState.world_map_payload()` path so projection has one authority.
- Challenge MID113 now validates a source-known unlocked Challenge row, preflights source Energy, stages deterministic first-clear awards using `quantity = increase_rate // 10000`, and never invokes CampaignDropPlanner or RandomOutcomeService.
- Challenge MID114 now requires the matching server-side staged session, settles source Energy (`24` victory / `2` defeat), commits staged first-clear items on victory only, returns `items=[]` for that first-clear plane to avoid duplicating the MID113/BattleWin delivery channel, updates best star, and returns the current node plus all newly materialized raw children.
- Challenge MID117 is explicitly rejected; Challenge has no sweep plane.
- The generic normalized `campaign_meta.next_campaign_id` path is not used for Challenge.
- Existing Pass117 Normal/Super MID113/MID114 UUID behavior is intentionally untouched in Pass122. Pass123 owns its retirement.
- OTA bytes are unchanged at cumulative version `1.631.7`.

## Validation

Pass122 focused tests cover catalog invariants, fan-out preservation, fixpoint projection, persisted self-heal/no ghost save, deterministic first-clear staging, zero RNG consumption, victory commit, loss discard, source Energy costs, terminal duplicate no double-settlement, locked/arbitrary result fail-close, and explicit no-sweep behavior. Pass121 MID117 and the superseded-but-updated Campaign reconciliation suite remain green; Pass92 MID116 and Pass79 Daily Reset neighbor suites also pass. The source catalog regenerates byte-for-byte from effective `src_64`.

## Next

Pass123 is the accepted manual Campaign battle simplification: retire the Pass117 cross-request MID113/MID114 UUID authority, restore server-owned `active_campaign_battle` state, and build cumulative OTA `1.631.8` replacing the six Pass117 Campaign battle files with pre-Pass117/source-shaped behavior while preserving MID50 and MID117 UUID bridges.
