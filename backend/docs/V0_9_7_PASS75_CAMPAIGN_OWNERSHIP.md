# v0.9.7 / Pass75.0 — Campaign Ownership Foundation

Status: **STATIC_ACCEPTED_RUNTIME_PENDING**. Pass72.0 remains the last clean runtime-accepted pass. The Pass74 client smoke proved Quick Enchant and major Hero progression healthy, while exposing one TaskWindow bootstrap Lua error, a Stone Evolution persistence-reset bug, and the expected Campaign ownership gap; those are corrected here.

## Scope

Pass75.0 begins general Campaign ownership without leapfrogging unresolved sweep/drop-RNG/reset behavior. It migrates source-complete Normal and Super/Elite fight entry/result settlement onto the existing Pass71 temporal owner, Pass69 MutationPlan/UoW, Pass70 journal projector, and existing Campaign reward/state boundary. It also carries three tightly-bounded runtime-neighbor persistence/UI corrections from the Pass74 smoke.

## Campaign source authority

The effective source contains 917 `campaign.lua` rows across 23 chapters. The live chapter/map graph resolves 429 Normal campaign IDs and 155 Super/Elite IDs. Every Super/Elite node is audited through the source `relate_campaign_id` relationship; the relation mismatch count is zero.

Campaign Energy is **per source row**, not a universal 6. Examples: campaign 100001 costs 6 on victory and 1 on defeat; 100002 costs 9/1; source-related Super campaign 100019 costs 12/2.

## MID113 / MID114 ownership

`MID113` now validates the exact source campaign, wire mode, unlocked state, and full entry Energy availability. It stages a one-player authoritative battle session but does not debit Energy yet, because the actual result cost differs on victory vs defeat.

`MID114` must match that active session. Orphan/spoofed results fail closed before state/resource/version mutation. A valid result atomically settles the source result Energy cost through a typed TEMPORAL MutationPlan together with the already-owned Campaign state/reward transaction. Pass70 projects the cumulative post-commit Energy value. Retry/idempotency behavior remains preserved.

Normal victory unlocks the source `next_campaign_id`. Super/Elite is represented as an independent source-shaped map list rather than the old `{}` placeholder. General repeat-drop RNG remains intentionally disabled where authoritative server/random policy is unresolved.

## Debug Campaign unlock (`PRIVATE_SERVER_POLICY`)

Anonymous QA UID `13371337` receives a one-shot source-graph migration containing all 429 Normal and 155 Super/Elite stages. Missing Normal rows are seeded at 1 star because the client gates Super access on the related Normal stage being cleared. Super rows are seeded present/unbeaten at 0 star with source daily-limit metadata. Existing progress is never reduced. The marker prevents continuous rewrites, and credential accounts are untouched.

## Runtime-neighbor corrections

### Awakening Task window bootstrap

The client really did send MID2738 and Pass74 returned `awake_mission_` correctly. The failure occurred when TaskWindow opened on the DAILY tab: the generic loader omitted `extra_info.huoyue_info`, leaving `dayHuoyue` nil. DAILY task loads now provide a source-shaped zero baseline (`daily_left_time`, day/week huoyue values and award maps), so the window can safely open and then display the Awaken tab.

### Stone Evolution / Breakout persistence

Pass74 could return `evo_stage=2, evo_attr_points={}` correctly but Pass68 merge-preserving JSON persistence recursively retained the old completed stage-1 point map. `evo_attr_points` is now an explicit canonical-replacement dictionary. An authoritative empty map can therefore clear stale points without weakening extension preservation globally.

### Awakening mission deletion persistence

Active Awakening ownership removal now persists an explicit null tombstone so a completed/given-up mission cannot resurrect through nested extension-preserving merge.

### Certificate audit

All genuine Inscription families remain source-mapped: material 19=`degree_cer`, 20=`graduate_cer`, 21=`patent_cer`. The source contains 7 Degree, 7 Graduate, and 9 Patent archetypes. The new runtime trace contains cumulative credits for all three families. IDs `160200711/160200712` are not Inscription-table emblems and remain fail-closed.

## Explicitly deferred

- Campaign Sweep Energy/scalar settlement.
- Super/Elite daily-attempt decrement and daily reset ownership.
- General repeat Campaign drop RNG without authoritative server/random policy.
- Debug 1,225-item bag-cap/mail warning (`PRIVATE_SERVER_POLICY` test side effect).
- Downstream Vows/Workshop/Pet implementation until Campaign ownership is runtime accepted.

## Static gate

The working candidate passes compile, Pass42.12/42.14, every Pass68 through Pass74 self-test, and `selftest_pass75_campaign_ownership.py`. Final acceptance still requires the packaged-byte re-extraction gate and then a fresh user Pass75 client smoke.
