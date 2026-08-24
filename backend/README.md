# GXB backend v0.16.2 — Pass141.0

Pass141.0 is **Phase 4 client-test preparation**. It does not change the already static/regression-accepted Phase1–3 gameplay policy. The anonymous sandbox UID `13371337` receives a one-shot, non-replenishing, source-stack-bounded QA seed containing every supported Phase3 ordinary-random MID241 source package (100 items covering 96 unique dropbox pools / 134 ordered draw occurrences) plus Orange Gear Pack, Purple Gear Pack and Optional Gift Box. See `docs/PASS141_CLIENT_TEST_PLAN.md`.

Fresh effective `src_64` feedback-loop verification also identifies MID70 in the frontend as the fourth Summon machine / source `魔法販賣機` (Magic Vending Machine), with **Switch / Buy 1 / Buy 10** controls. The 199 `gift.equip` packages remain fail-closed and deferred to Girls/Equipment Economy Closure. Pet-named gift packs test MID241 settlement only, not Pet lifecycle support.

---

Pass140.0 completes **Phase 3 — MID241 Ordinary Random Gifts** from the approved RNG roadmap.

A mandatory fresh check against effective `app-assets/output/assets/src_64` reconfirmed the Phase3 boundary: **100 ordinary random effective `(item_id,gift_id)` operations across 100 source items and 134 ordered drop occurrences**. Seven operations contain multiple/repeated drop occurrences; Daily and Special Magazine each repeat the same pool five times. Recovered positive pool totals are not globally normalized and include 100, 310, 1,000, 1,200, 6,800, 7,150 and 10,000. Ten recovered candidate rows have zero weight; no recovered ordinary pool is all-zero.

The existing immutable `GiftOpeningSourceCatalog` remains byte-identical to a fresh effective-source rebuild. Pass140 adds a thin `GiftRandomOutcomeAdapter` over the request-scoped `RandomOutcomeService` namespace `gift.open`; ROS remains entropy mechanics only. Gift-domain compatibility policy treats positive raw `drop_rate` values as relative integer weights, excludes zero-weight candidates, executes every ordered/repeated `gift.drops` occurrence once, and repeats the whole operation per consumed `num` before aggregating awards in first-seen draw order.

`GiftOpeningService` now preflights exact operation/capability, source quantity, source shape, all possible canonical reward owners, recovered `roll_type=1`, nonnegative weights and at least one positive candidate before any random draw. Source debit and reward settlement still share one existing `PlayerUnitOfWork` through the existing `StackInventory`, `RewardTransactionService`, mutation/economy/progression owners. No parallel backbone or MID241 UUID/receipt was added.

The 199 deterministic raw `gift.equip` operations remain fail-closed and are explicitly deferred into **Girls / Equipment Economy Closure**; generated Hero/HUNQI/unique and other source-incomplete lanes remain fail-closed. Phase3 does not alter them.

Focused Phase3 validation passes 9/9 and exhaustively plans/preflights all 100 ordinary random operations. Phase2 regression remains 13/13. Current Magic, later Campaign, progression and architecture suites pass; the historical Pass113 inert-world-hash harness still fails identically on the unmodified Pass138 baseline and is classified as pre-existing stale-harness debt. Runtime acceptance remains consolidated in Phase4.

OTA remains **1.631.8**. Next roadmap phase: **Phase 4 — client test and debug** for Magic/MID241 runtime acceptance.
