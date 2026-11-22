# I9_11_TRIAL_SWEEP_V1

Lead contract, 2026-11-19, for Sol T33 A-148 and obligation I9-TRIAL-SWEEP (D472). Amends I9 campaign C7 (MID 117 was defined for campaign_type 1|2 only). Owner system: `campaign`. Evidence: /home/akm/Chatgpt/EOL_Game/tmp/reality_11t33/voyage-raid-sweep-REPORT.md (fleet_11t33v, tree 0b793627).

## Client facts

- Time Travel trials (challenge_config groups 16-21) send MID 117 from PreperationBattlePreWindow.lua:219-258 with sweep_num 1, campaign_id (stage), campaign_type (group 16-21), sweep_type 1 (Raid Ticket 50001013) or 2 (crystal). Client gates: star 3, level >= 70, uses left, energy, ticket or crystal.
- Nation/cloud trials (11-15, 40-42) send the same MID from NewMapDetailWindow.lua:884-941 with sweep_num = remaining uses.
- Challenge 24 never sends 117 (NewMapDetailWindow.lua:366-368 hides the panel).
- Readers: SweepWindow.lua:618-738 read items, economys, additional, campaign, chapter_event, and the group row stored into challengeInfos_ (`challenge` {id,left_times,is_open,max_times,last_id}).

## Rules

T1. Dispatch: MID 117 accepts campaign_type Normal (1), Super (2) or an existing trial group (11-21, 40-42). The domain decides; type 24 and unknown types -> 400.
T2. Admission: the same trial admission 113 uses (group, schedule, level, last_id, cloud previous-node gate) plus star 3 on the stage, sweep_num 1..remaining uses, and the existing VIP/monthly and ClearCountFloor rules.
T3. Debits in one receipt transaction: energy (energy_cost x sweep_num), ticket 50001013 per sweep else crystal per sweep (as Normal sweep), and sweep_num trial uses (TrialWins).
T4. Awards per sweep, the same as a won trial battle without combat: repeat-dropbox roll, mana, exp (energy_cost x 3). No first-clear box, no partner exp, no star gift. The award rule is inferred (sweep_reward is 0 in source) and logged as PRIVATE_POLICY.
T5. Reply: the 119 shape plus the group row with 114's key choice (`challenge` when the group has NextID, else `trial`), so SweepWindow and challengeInfos_ update.
T6. Facts: a trial sweep emits the same objective facts as a won trial battle, once per sweep (PRIVATE_POLICY, recommended: yes).
T7. Replay: same receipt identity as Normal sweep; a fingerprint mismatch is 409. Rule refusals 409/35028; never 500. No migration.
T8. Reply conformance: replace the 117 `UNKNOWN, paths: []` row in reply_consumers.json with the readers above through tools/reply_consumers.py (fix the tool for the indirect xyd.mid.SWEEP_CAMPAIGN reference), so the strict gate checks 117.

## Tests

Dispatcher accepts 16-21/11-15/40-42 and refuses 24. Domain: star 2, zero uses, count above uses, unknown type. Native (postgres): ticket sweep and crystal sweep of a group 16 stage debit energy, ticket or crystal and one use, award drops, reply carries `challenge`; replay returns the stored body; mismatch 409. Update campaign_sweep_test.go:14.
