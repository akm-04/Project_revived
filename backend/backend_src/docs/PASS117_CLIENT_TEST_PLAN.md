# Pass117 client runtime smoke plan

1. Confirm OTA resource version 1.631.7 becomes current.
2. On an uncleared Normal stage, enter battle and verify MID113 carries `campaign_battle_op_id=mid113-...`; record the visible staged drops. Win and verify those exact staged drops appear once in Backpack after MID114, while MID114 response `items` remains empty for that channel.
3. Force-close immediately after tapping Normal battle start, reopen/retry, and verify MID113 replays the same staged drops rather than rerolling.
4. Force-close around MID114 victory submission and verify Energy/rewards/progression settle exactly once after retry.
5. Lose an uncleared battle and verify staged first-clear drops are not retained; start a fresh battle and verify it receives a fresh operation ID/new staging roll.
6. Repeat a previously cleared MID113 stage and verify no random battle-drop plane was accidentally activated.
7. Repeat the first-clear + retry checks on Super Campaign; verify daily_limit decreases exactly once on victory.
8. With Chapter 16 terminal stage uncleared, confirm Challenge remains locked. Clear Normal 1600016 and confirm Challenge unlocks immediately without relog; after relog, LOAD_WORLD_MAP.challenge still contains Campaign 24111.
9. Verify existing MID117 1x/10x sweep behavior remains unchanged.
10. Capture server/client logs for reconciliation before resuming later Campaign slices.
