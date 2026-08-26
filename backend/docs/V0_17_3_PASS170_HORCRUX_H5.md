# v0.17.3 / Pass170 — Horcrux H5 Gods Trial

Pass170 activates the Gods Trial/HUNQI campaign state machine on the accepted H1-H4 foundation. It reuses `PlayerUnitOfWork`, `TemporalPolicyService`, `RewardTransactionService`, the H3 `SPIRIT` generated-reward owner, `HorcruxRepository`, `ServerDayClock`, and policy-free `RandomOutcomeService`; no parallel campaign, energy, reward, or RNG framework is introduced.

The fresh `src_64` reality check corrected one planning assumption before implementation: the actual campaign wire value is **`xyd.CampaignType.HUNQI = 79`**. The earlier value 57 belongs to another enum family and is not the `campaign_type` carried by `SelectTeamNewWindow`/`BattleCreate`. Pass170 therefore records 79 as a source fact and rejects 57 on the Gods Trial wire.

`HorcruxSourceCatalog` advances to schema v4 and now includes all 84 Trial first/repeat pools referenced by 42 `spirit_campaign` rows, totaling 3,672 `campaign_dropbox` rows, plus source timing limits (Spirit Energy recovery every 360 seconds, natural cap 180, auto limit 10, five minutes per auto attempt). First-clear pools are source-guaranteed and consume no entropy. Repeat pools use the frozen Pass164 compatibility rule in stable source order: `rate // 10000` guaranteed copies plus one Bernoulli for `rate % 10000`, under `horcrux.trial.repeat.residual`.

MID3097 projects current weekday `campaign_infos`, `base_info`, `day`, and conservative empty `day_info`. MID3092 stages a server-owned Trial battle after weekday/level/previous-clear/capacity/energy/team validation. MID3093 settles exactly once: wins debit 20 Spirit Energy, grant first-clear or repeat rewards, and advance `win_count`; losses debit source `lose_cost_num=2` and grant no Trial reward. Matching terminal retries replay the stored result with error code 30005, which the recovered client explicitly accepts as a completed fight-result condition.

MID3099 starts auto fight only on a cleared/open stage, validates the soft 2,000-instance entry cap and `times` 1..10, debits the full Spirit Energy cost up front, and persists server-only run identity/timing. MID3100 is read-only before maturity; at maturity it evaluates exactly `times` repeat attempts, settles ordinary and unique rewards atomically, increments progression, clears running state, and stores a terminal replay payload until the next auto start.

The 2,000 limit remains a soft Gods Trial **entry** guard, not a destructive storage ceiling. A valid 1,999-instance manual entry can settle first-clear rewards and cross to 2,001. Weekend first-clear gift-pack rows settle through ordinary InventoryGrant; type-24 rows settle through the existing H3 generated `SPIRIT` owner.

H5 requires no client patch. OTA 1.631.12 remains unchanged at 142 cumulative entries. MID3096 Spirit Energy purchase stays inactive because the recovered frontend is disabled; MID3088 and MID3098 also remain inactive. Coherent stock-client Horcrux smoke/reconciliation remains H6.
