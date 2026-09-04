# Pass247.0 — Emblem I5 Reforge Implementation Report

## Scope

Pass247 opens only the sealed I5 Reforge lifecycle: MID1401 proposal generation, MID1405 Save, and MID1406 Abandon. It preserves Pass246 MID1400 Forge and the Pass242 deterministic Emblem routes. No client/OTA payload changes are made.

## Evidence boundary

**SOURCE_FACT:** current effective `src_64` is `all-assest-rechecked-1.zip/app-assets/output/assets/src_64` (4,370 files). `InscriptionWindow.lua`, `InscriptionTenTimesWindow.lua`, `Inscription.lua`, `SelfPlayer.lua`, `inscription.lua`, and `inscription_rate.lua` were re-read during implementation. The generated Emblem source catalog is byte-identical to the packaged catalog.

**SOURCE_FACT:** MID1401 uses `item_id`, `rebuild_num` 1/10 and `cost_type` 1 Crystal / 2 Mana. The cost is `change_crystal` or `change_gold` from the matching ordinary inscription row multiplied by the requested count. The current Crystal-insufficient client branch shows an alert but does not return, so server cost authorization cannot rely on client precheck.

**SOURCE_FACT:** MID1401 returns candidate IDs in `inscript_items`. MID1405 sends only the chosen candidate ID. Its success callback removes the original medal client-side and passes `rebuild_items` through reward handling. MID1406 sends an empty request and clears the local pending candidate. Stock wire exposes no nonce/proposal token.

**STRONG_INFERENCE + COMPATIBILITY_POLICY:** the `emblem-v1` Lv7 Scholarship outer gate and Reforge +100bp miss ladder/hard ceiling at 100 remain the Pass240/244 replaceable server policy. They are not represented as recovered official server math.

## Implementation

- `EmblemService.rebuild()` validates request shape, ordinary non-Scholarship source mapping, source ownership and the entire Mana/Crystal cost before calling the planner. Validation consumes no entropy and mutates no pity/proposal state.
- Accepted MID1401 calls the Pass244 sequential proposal planner inside the same `PlayerUnitOfWork`, then settles the already-authorized cost. Any later settlement failure rolls back cost, pity, pending proposal, state version and journal.
- No idempotency receipt/nonce was added. A repeated accepted wire-identical MID1401 is intentionally another paid proposal and replaces the prior pending proposal.
- `EmblemService.save_rebuild()` only accepts a member of the latest frozen candidate list. It does not call RNG or reinterpret the proposal under the current policy. One atomic settlement debits the original medal, credits the selected medal, then clears pending state.
- If the original source medal disappeared after proposal generation, MID1405 rejects and durably clears the stale pending record. This prevents later reacquisition from resurrecting an old paid proposal.
- `rebuild_items=[{table_id,item_num}]` is returned explicitly. Default response projection does not synthesize stack credits, preventing a double client award.
- `EmblemService.abandon_rebuild()` clears pending state without refund or inventory mutation. No pending proposal is a successful no-op.
- Dispatcher and HeroHandlers now expose only the authorized MID1401/1405/1406 routes; all other route ownership remains unchanged.

## Failure/retry matrix

Pass240 F02–F12 behaviors are covered: insufficient Mana/Crystal and unowned/Scholarship/invalid sources fail before entropy; accepted repeat is new paid latest-wins proposal; superseded Save is rejected; missing source clears stale pending; repeat Save fails; repeated Abandon is no-op; pending survives restart; policy-version changes do not reroll frozen candidates; 10x is sequential and can cross pity reset/hit boundaries.

## Validation

Dedicated `tools/selftest_pass247_emblem_i5_reforge.py`: **12/12 PASS**. Still-controlling regressions: I4 7/7, I3 6/6, I2 7/7, I1 6/6, Pass129 architecture 5/5, Pass110 ROS, Pass212 P2 Stage-G, Pass227 Blood MID867, Pass230 cleanup, Pass231 popup revert, Pass232 recovery/log rollover. Historical route-fence assertions whose sole claim was that newly authorized MIDs must remain disabled are explicitly superseded.

This pass is **static/regression accepted**, not stock-client runtime accepted. I7 remains the runtime acceptance wave after I6 integration/hardening.

## Next

I6 Emblem integration/hardening, then I7 stock-client acceptance.
