# Pass248 handoff — Emblem I7 stock-client test plan

Status: **I6 static/regression accepted; I7 runtime acceptance NOT YET CLAIMED**.

Authority: current effective `all-assest-rechecked-1.zip/app-assets/output/assets/src_64` (4,370 Lua files). Stock wire has no Forge/Reforge nonce or proposal token. `emblem-v1` Lv7 outer Scholarship rate remains a replaceable compatibility policy, not recovered official server math.

## Capture requirements

For the whole run preserve:
- backend console transcript (`runtime_logs/server*.txt`),
- `runtime_logs/emblem_events.jsonl`,
- `runtime_logs/all_requests.jsonl`,
- client `/client-log` evidence / `debug.zip` if a Lua/resource error occurs,
- screenshots only where visual stat/set behavior is being accepted.

A successful Emblem request must not produce unexpected HTTP 409/5xx, Lua exceptions, restart popups, or duplicate local rewards. `emblem_events.jsonl` intentionally records only aggregate policy/proposal/counter state and must not leak candidate IDs onto the wire.

## Recommended test account setup

Use one Girl at **Blood Awakening stage 3 and Hero level >=100**. Keep a second non-eligible Girl if convenient for a negative equip check. Record initial Crystal, Mana, the three certificate scalars, Heart/fragment/Star counts, Backpack medal counts, and the eligible Hero's `inscript_items` before testing.

For deterministic UI coverage it is acceptable to prepare inventory through the normal debug/test fixture rather than grind random acquisition. In particular, prepare one 2-piece Scholarship set and one 3-piece Scholarship set for the visual set-bonus checks; that does not make any claim about the official outer Scholarship probability.

## I7 test sequence

### T01 — Eligibility and entry
1. Relog with a level-100 Girl that is not Blood-stage-3: Emblem must not become operational merely because Function45/level state exists.
2. Use a Blood-stage-3 level-100 Girl and enter the Emblem UI.
3. Confirm there is no rejected custom Blood-completion `common_alert`; ordinary Function45 behavior may use normal `new_funcs_` semantics only.

Accept when the eligible Girl opens Emblem without Lua error and the ineligible Girl cannot be used to bypass the per-Hero equip gate.

### T02 — Star exchange / acquisition spine
1. Hold each physical Star: `50001343`, `50001344`, `50001345`.
2. Trigger MID1407 exchange.
3. Confirm all held Stars are removed locally by the stock client and the corresponding certificate balances rise by **5 per Star**.

Source acquisition anchors already regression-checked in I6 include Campaign 1700003/1700006/1700009 for the three Stars and chapter-18 rows such as 1800003 for Heart fragment `50001347`.

### T03 — Heart composition
1. Hold `50001347 x60`.
2. Compose Heart `50001346` through stock MID83.
3. Confirm exactly 60 fragments disappear and one Heart appears; no Mana is consumed.

### T04 — Representative Forge, all three slots
Forge one ordinary representative of each family:
- Excellence: source row `10001`,
- Honor: source row `20001`,
- Specialty: source row `30001`.

For each request verify stock MID1400 sends `{inscript_id, make_num=1}`, one matching certificate cost is consumed, exactly one concrete medal appears, and no duplicate reward animation/backpack copy is created by generic projection.

### T05 — Lv7 Forge / Heart consumption
1. Prepare 2130 matching certificate points plus one Heart.
2. Forge representative Lv7 row `10007` (or equivalent Honor/Specialty Lv7).
3. Confirm one Heart plus exactly 2130 matching certificate points are consumed and exactly one medal appears.
4. Do not infer official Scholarship probability from the observed outcome; the outer gate is compatibility policy.

### T06 — Equip / replace / remove all physical slots
1. Equip one Excellence, one Honor and one Specialty medal onto the eligible Girl.
2. Confirm `inscript_items` behaves as a dense three-item array and each medal lands in its source physical position.
3. Replace a medal in each slot. Confirm the replacement costs the stock 20 Crystal and the replaced medal returns to Backpack once.
4. Remove a medal from each slot. Confirm the same 20 Crystal removal cost and one returned medal.
5. Attempt insert on a non-Blood-stage-3 or sub-level-100 Girl: it must fail safely.

### T07 — Scholarship physical positions and 2-piece set presentation
Using prepared source-valid pieces `160400101 + 160400102` (set 1001) or another exact 2-piece set:
1. Equip both pieces.
2. Verify one occupies physical position 1 and the other physical position 2 despite their shared special family row.
3. Verify the stock client visibly recognizes the 2-piece set and updates displayed attributes/power consistently with current source.
4. Relog and confirm the same set remains equipped/presented.

### T08 — 3-piece set presentation
Using prepared `160500101 + 160500102 + 160500103` (set 2001) or another exact 3-piece set:
1. Equip all three pieces.
2. Verify physical positions 1/2/3, set recognition, visible set bonus, and power/stat update.
3. Relog and confirm persistence.

This is a client-stat/presentation acceptance check only; final cross-system Girl-stat authority remains the later Girl-stat capstone.

### T09 — Single Reforge + Save
1. Hold an ordinary medal and enough Mana.
2. Run one MID1401 Reforge with `rebuild_num=1`, `cost_type=2`.
3. Confirm Mana is charged once while the original medal remains until Save.
4. Save the returned candidate through MID1405.
5. Confirm the original disappears exactly once and the selected candidate appears exactly once; no reroll or duplicate reward.

### T10 — Single Reforge + Abandon
1. Run another paid single Reforge.
2. Choose Abandon / MID1406.
3. Confirm the original medal remains, no candidate is awarded, and paid Mana/Crystal is **not refunded**.
4. A repeated empty Abandon should be harmless.

### T11 — 10x Reforge select/save
1. Run MID1401 with `rebuild_num=10` and sufficient Mana or Crystal.
2. Confirm the modal displays ten returned candidates and allows selecting one.
3. Save one candidate.
4. Confirm only that selected candidate replaces the original exactly once.

### T12 — Latest proposal wins
1. Generate a paid single proposal and do not Save.
2. Generate another paid proposal for the same original before committing the first.
3. Attempt to commit the older candidate if the UI permits reaching it; it must not be accepted by the server.
4. Commit a candidate from the newest proposal and verify normal settlement.

No nonce/receipt semantics should appear: every accepted MID1401 is a new paid action.

### T13 — Insufficient Crystal authoritative preflight
1. Set Crystal below the source Reforge cost.
2. Attempt Crystal Reforge (`cost_type=1`).
3. Current stock Lua may show its recharge alert **and still send MID1401**; this is expected.
4. Server must reject safely with no candidate, no pity/proposal mutation, no inventory change and no negative Crystal.

This is a critical I7 acceptance case.

### T14 — Pending proposal across relog/restart
1. Generate a paid MID1401 proposal and do not Save/Abandon.
2. Relog the client. If the stock outstanding-proposal flow appears, verify it refers to the same frozen candidate set.
3. Repeat with a backend restart between proposal and client recovery.
4. Save one candidate after restart.
5. Confirm no reroll, no extra Reforge charge, correct original->candidate swap, and durable proposal generation in `emblem_events.jsonl`.

### T15 — Eligibility loss after paid proposal
1. Generate a paid proposal while eligible.
2. Make the account temporarily non-operational for new Forge/Reforge (for example test copy with the qualifying Hero no longer satisfying stage/level).
3. Confirm new Forge/Reforge fail, but the already-paid pending proposal can still be Saved or Abandoned. This prevents paid state from being stranded.

### T16 — Dissolve and artifact compatibility
1. Dissolve ordinary representatives and confirm the matching certificate scalar rises by the source `resolve_num` while the medal is removed once.
2. If available, equip/remove/dissolve a representative of the 14 source-present Honor artifacts (e.g. `160200111`). It is valid existing content but must never be observed as a Forge/Reforge-generated candidate.

### T17 — Final restart persistence sweep
After the above operations restart backend and client, then verify:
- certificate/Crystal/Mana balances,
- Backpack medal/Star/Heart counts,
- Hero dense `inscript_items`,
- pending proposal state (if intentionally left pending),
- no duplicate Function45 popup,
- no rejected Blood completion `common_alert`,
- no Lua exception or unexpected 409/5xx.

## Acceptance decision

I7 may be marked **RUNTIME_ACCEPTED** only if all critical cases T01, T04-T06, T09-T14, and T17 pass, and the set-display checks T07/T08 are source-consistent. Any Lua exception, duplicate local reward, stale candidate commit, unsafe insufficient-Crystal mutation, or restart loss reopens reconciliation instead of advancing the roadmap.

On acceptance: close Emblem and advance to **Institute Alchemy**. Occult MID2385, Pet Awakening, KongMing Books I-IV/all-skill work, and optional Treasure/Daily Scholarship/Auction integrations remain deferred.
