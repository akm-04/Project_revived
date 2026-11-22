# RULING I9-12: seal registry sync (behaviour merged in I9-12, contract text brought in line)

Date 2026-11-22. Lead ruling under the amend-on-evidence policy, from the I9-12 seal audits
(tmp/seal_i912_audit/AUDIT_0N.md). Logged for user review. Each item records behaviour already merged into i9-12 on
user bug reports or I9-11 rulings; the amended text below replaces the conflicting clause.

## 1. Ranking: Blood Awaken and Sorcery War boards are served (BUGS #83)

Amends I9_10D_RANKBOARDS_PRIVATE_POLICY_V1 `unserved` and its N8 basis; I9_OCCULT_V1 C11 ("No ranks") and
I9_OCCULT_POLICY_V1 `rewards.ranks`.

- MID 301 subtype 14 (Blood Awaken) serves girls whose blood awakening is complete
  (private policy I9_12_PRIVATE_BLOOD_AWAKEN_COUNT_V1).
- Subtypes 28/29/35/36/40/41 (Sorcery War chapters 1-6) serve each player's best chapter score
  (I9_12_PRIVATE_OCCULT_CHAPTER_{1..6}_BEST_RANKING_V1, I9_12_PRIVATE_OCCULT_CHAPTER_BEST_V1, the chapter score
  formula in internal/domain/occult/score.go). These boards grant no titles and no Occult reward; Occult itself still
  has no shops or daily counters.
- Purify stays unserved until its owner exists.
- Evidence: the stock RankWindow tabs, the user's BUGS #83 report. Implementation 899b9ce2, merged 1ad63292.

## 2. Campaign assist award is a plain item row (BUGS #118)

Amends POLICY_DECISIONS_FOR_REVIEW L-ASSIST: `assist_awards` rows are `{table_id, item_num}` without `to_stone`.
With `to_stone: true` the client showed a "girl summoned" popup for a trial girl the player never owns; the five scrolls
are granted through I5 as before. User ruling 2026-11-21 (BUGS #118), merged 8be1744c.

## 3. Profile first-time hint (MID 1829)

Amends I7B1_WIRE_PRIVACY_POLICY rule 33 (first-time marker): the first self MID 1829 read claims
`player_public_profile_roots.is_first_time` once and answers 1; later reads answer 0. The stock client has no
acknowledgement MID (PersonDisplay.lua:229-235 `checkIsFirstTime`), so the read is the only point it can be claimed.
Known limit, repair lane: a reply lost after commit loses the one-time hint. Merged 2ebb8c7a.

## 4. AC Bookshop unlimited buys (BUGS #120)

Amends I9_11C_CORE_SHOPS_V2 C7 for shop type 29 only: rows whose source `object_book_shop` row has `is_unlimit` accept
repeated purchases (buy_times counts up, no cap). Every other shop keeps C7. Merged 7eb9e2ed.

## 5. Guild broadcast after a clock rollback

Amends I7A8A_SOURCE_MAIL_CONTRACT and I7A8A_IMPLEMENTATION_CONTRACT where they reject a source whose snapshot is
after the bound decision: I9_11_CLOCK_ROLLBACK_V1 K2' governs, and the source is observed at its stored time
(126495c8). The daily-limit window on a rolled-back clock is a known defect, repair lane (K4).
