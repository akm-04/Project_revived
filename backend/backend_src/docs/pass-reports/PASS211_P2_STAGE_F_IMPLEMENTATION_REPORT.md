# Pass211 — P2 Stage F Implementation Report

## Scope
Stage F only, forked from sealed Pass210 v0.24.0. Stages A-E remain authoritative and the broader P2 release remains fenced. Stage G is not started.

## Implemented
- Added an immutable effective-`src_64` Occult/Sorcery War source catalog covering all six chapters and exactly 22 ordinary Awakening Occult routes.
- Added the canonical typed OCCULT/SorceryWar aggregate owner for `occult_ticket` and `occult_state.cost_energy`; no EconomyLedger ownership boundary was weakened and no shadow scalar/state authority was introduced.
- Activated the existing `DerivedMutationRuleRegistry` with its first approved production rule: canonical energy debits accrue Occult stamina progress. At 3,000 spent stamina the aggregate grants one Sorcery Scroll, held cap is 2, progress pauses while capped, and threshold-crossing overflow is discarded under the frozen compatibility policy.
- Added minimal MID2362 `GET_INFO` support. It returns safe idle room/chapter state, canonical progress/ticket state, and exposes a synthetic positive `max_points` only for the chapter matching the currently active ordinary stage-one Occult Awakening mission.
- Added minimal MID2385 `OCCULT_SWEEP` support. The request remains source-exact `{chapter_id}`. It requires a matching canonical active ordinary stage-one Occult Awakening mission, consumes exactly one Sorcery Scroll through the OCCULT owner, credits exactly one matching fragment through canonical Stack settlement, and commits both atomically in the existing Player UoW.
- Full manual/co-op Occult flows remain unrouted and fenced.

## Source reality
Effective `src_64` remains exactly 4,370 files. Pass211 locks nine Stage-F-critical source files. Source confirms:
- Sorcery Scroll threshold = 3,000 stamina;
- held cap = 2 Scrolls;
- MID2385 request contains only `chapter_id`;
- sweep UI availability is gated by `max_points[chapter] > 0`;
- the active Awakening fragment is chosen from the chapter mission/item vectors;
- raw `creats_sweep_reward_rate=0.6` is consumed as UI text;
- raw `awaken_nums=30` has no effective `:awakenNum(...)` caller in the 4,370-file corpus.

Therefore the deterministic server yield remains explicitly COMPATIBILITY_POLICY: one Scroll -> one matching active Awakening fragment. Neither raw 30 nor 0.6 is relabeled as recovered server quantity/RNG.

## Targeted architecture correction
Pass204 contained a stale reuse statement suggesting generic resource mutation for `occult_ticket`. The sealed resource registry already defines `occult_ticket` as `DOMAIN_GUARDED_CREDIT_DEBIT` owned by `SorceryWarAggregate`, while EconomyLedger deliberately does not own it. Stage F preserves that boundary: the pure derived rule detects canonical energy debits, but the OCCULT aggregate owns ticket/progress mutation. This is an architecture correction, not a behavior redesign.

## Evidence boundaries
- SOURCE_FACT: 3,000 stamina threshold, cap 2, MID2362/MID2385 wire/consumer behavior, six chapters, 22 ordinary Awakening Occult routes, raw 0.6 UI rate, raw awaken_nums=30 with no effective caller.
- COMPATIBILITY_POLICY: pause/discard overflow behavior while capped, synthetic active-chapter `max_points`, deterministic one-Scroll/one-fragment settlement.
- IMPLEMENTATION: typed OCCULT owner, stamina derived rule, minimal MID2362/MID2385 services/handlers, existing UoW/settlement integration.
- PROTOCOL_LIMIT: MID2385 is nonce-less; two identical requests with two available tickets are indistinguishable from a transport retry and are treated as two legitimate sweeps rather than claiming universal exactly-once semantics.

## Validation
Dedicated Pass211 Stage-F characterization passes all seven tests: catalog/ownership boundary, idle/synthetic unlock, stamina threshold-cap-pause projection, actual Campaign energy-settlement integration, sweep atomicity/policy/nonce limitation, exhaustive all-22-route/relog behavior, and continued fencing of nonminimal Occult MIDs.

Controlling regressions remain green: Pass206 Stage B, Pass207 Stage C, Pass209 Stage D (11/11), Pass210 Stage E (7/7), Pass205/206/207/209/210/211 source reality locks, Pass129 architecture hygiene, Pass122 Challenge, Pass131 Campaign EXP/Mana, and foundational resource/UoW characterization. The historical Pass205 assertion that the derived-rule registry contains zero rules is intentionally superseded: Stage A created the seam empty and frozen Stage F is the first authorized consumer.

Shipped `data/player_db.json` remains byte-identical to sealed Pass210.

## Release posture / next
Stage F is complete in this backend, but the broader P2 release remains fenced. Stage G is next only after Pass211 backend and HOT/COLD sealing. Stage G is the exhaustive closure/release gate: 164 ordinary + 81 Blood route validation, Give-Up anomalies/no-list cases, event entitlements, retries/relog/state migration, final `src_64` reality rerun, surgical fence retirement, and stock-client smoke/reconciliation including the known Blood MID54 immediate cache risk.
