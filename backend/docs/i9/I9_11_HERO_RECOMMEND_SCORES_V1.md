# I9_11_HERO_RECOMMEND_SCORES_V1

Lead contract, 2026-11-19. Owner system: `herorecommend`. Closes MID 2501 GET_HERO_RECOMMEND_SCORES under RULING_I9-11_UNSERVED_MIDS (addendum: "served as a MID 1 detail by a named owner"). Evidence: work/i9/stages/I9-11/fleet_11rs/01-research-recommend-scores.md (tree 1cb74072).

## Client facts

- The stock client never sends 2501. It reads MID 1 `detail["2501"]` (SelfPlayer.lua:4199-4202) and stores that value itself as the score map (HeroRecommend.lua:210-212).
- Lookup is `scores[tostring(table_id)]` by origin hero table id (HeroRecommend.lua:214-220; awakened ids map back through NormalHero/SuperHero/ActivityHero `beforeAwakenID`). Shop stone details look up the stone item's `partner_id` (ItemTable.lua:244,532-534).
- ShopDetailWindow.lua:56-59 concatenates `"Score:" .. score` with no nil guard: an absent key is a Lua error. TuJian hides the row on nil; HeroMainWindow uses `or 0`.
- Label RECOMMEND_SCORE_TEXT "Score"; the rules text says the server recalculates each girl's rating weekly from mode data.

## Rules

R1. Shape: `detail["2501"]` is a flat JSON object `{"<origin_table_id>": <int64>, ...}`. No wrapper key (the recovered v1 `{"scores": ...}` wrapper made every lookup nil and is rejected).
R2. Coverage: every origin hero table id in the pinned content hero catalogue (read through the content owner's origin catalogue, `contentstore` HeroOriginCatalogTx), so no lookup the client can make returns nil.
R3. Value: the hero's `recommend_score` in the latest current-or-legacy-week snapshot's `Overview.TotalRankList` for the player's logical server, the same number MIDs 2497/2498 show. A hero absent from that list (including rank 51+ under the 50-hero total cap) gets 0. PRIVATE_POLICY: 0 is the default; the client shows "Score:0" in the library for such heroes.
R4. No snapshot, or a snapshot outside the generation rule `ensureSnapshot` applies: every catalogue id gets 0. Login never builds a snapshot (the 30 s reconciler owns building).
R5. Wiring: a `herorecommend` MID 1 detail contributor (`appboot.MID1DetailContributor`) claims key `"2501"`, reads through a read-only owner method taking the login transaction's queryer and decision time, and is registered in the production composition's DetailContributors. The lobby projection stops emitting its empty `zeroMap()` for 2501 so exactly one owner claims the key.
R6. No direct 2501 dispatcher: the client has no request site; a direct 2501 stays refused by the shared dispatcher. No migration.

## Tests

- Contributor with no snapshot: every catalogue origin id present with 0.
- With a snapshot: `detail["2501"][id]` equals that hero's TotalRankList `recommend_score`; a hero not in the list is 0.
- MID 1 golden (logincapacity mid1_two_step_reply_golden.json) updated; a reply-shape test pins the flat map (reply_consumers has no 2501 row, so the strict gate would not catch a wrapper).
