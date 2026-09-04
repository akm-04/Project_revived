# v0.8.27 / Pass42.2 — Private SX / Soul Box

## Purpose
Activate only the source-mapped SX/Soul Box protocol surface while keeping unrecoverable server RNG explicitly private-policy owned.

## Recovered boundary
- MID50 type4 index1/index2 are the two weekly-hotspot selectors.
- MID56 `main_ids` supplies those two targets; `second_ids` supplies three Daily Hotspot display IDs.
- VIP9, 388 Crystal, six results, and static pools 200007–200011 come from effective client/source data.
- `misc.sx_summon_guarantee_times=25` is a recovered constant, but the historical transition algorithm is unavailable.
- APK `soul_casket.lua` has a type6 Hero population totaling 10,000 weight. It has no recovered active client call-site and remains orphan candidate server-config evidence.

## Private policy v1
One SX purchase creates five independent item rows plus one dynamic Hero/to_stone row. Slot6 gives the selected `main_ids` target a 15% rate-up and a 25-purchase guarantee. The streak resets on a selected-target hit and rebinds on a target change. All of that transition math is private-server policy, not an official-server reconstruction.

## Modularity / tuning
`SXSoulBoxSourceCatalog` owns immutable evidence. `SXSoulBoxPrivatePolicy` owns rates/guarantees/overlays. `SXSoulBoxPrivatePlanner` owns pure selection. Existing Economy/Inventory/Hero repositories, `SummonResultPlan`, duplicate conversion, UnitOfWork and paid receipt machinery own mutation/projection.

Tunable fields live in `data/sx_soul_box_private_policy.json`. Per-row item and per-Girl weights are optional overlay maps; empty maps preserve source weights. This is the intended future balancing seam.

## Runtime gate
The next pass is Pass42.3 runtime reconciliation. Validate 388-Crystal debit, six-row result rendering/closing, five item awards plus one Hero/to_stone award, selector1/selector2 hotspot ownership, Buy Again, duplicate fragments, and absence of client exceptions.
