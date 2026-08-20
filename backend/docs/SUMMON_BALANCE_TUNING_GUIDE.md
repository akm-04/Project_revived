# Summon Balance Tuning Guide

This file is the practical maintenance guide for changing private-server Summon odds later without mixing balance choices into protocol, transaction, or source-recovery code.

## Non-negotiable separation

1. **Recovered source catalogs are evidence.** Do not edit recovered pool membership/weights merely to rebalance the private server.
2. **Private policy files are balance knobs.** Version policy changes and state clearly that they are not historical official-server math.
3. **Transaction/result code should stay stable.** Costs, mutation, receipts, response rendering, and duplicate conversion should not need a rewrite just because odds change.
4. **Classify IDs through field/table-scoped metadata.** Never create rarity/category rules from numeric prefixes alone.

## Classic Small/Medium

Primary private policy: `data/summon_private_server_policy.json`.

Current high-level item-vs-Girl/super choice is family policy (`ordinary_policy.super_chance_per_10000`). Guarantees/milestones are separate overlays. Once a Hero pool is selected, each Girl currently receives normalized source row weight:

`P(girl_i | selected hero pool) = effective_weight_i / sum(effective weights in that hero pool)`

Today `effective_weight_i` is the recovered row `drop_rate`. If fair-play tuning later needs equal sharing, rarity tiers, per-Girl rates, rotations, or anti-streak behavior, add a **private overlay** keyed by explicit pool row or Hero table ID and apply it in the planner. Do not overwrite the recovered rows in `summon_pool_catalog.json`.

Recommended future classic layers:
1. category mix (item vs Girl);
2. subtype/tier mix (explicit catalog metadata);
3. candidate/Girl weight;
4. guarantee/pity overlay;
5. duplicate conversion after selection.

## Magic/Gachapon

Private policy: `data/magic_summon_private_policy.json`.

### Byproduct odds

`balance_overrides.byproduct_row_weight_overrides` accepts a mapping from recovered pool700008 `row_id` to a private effective weight. Missing keys keep the recovered `drop_rate`; weight `0` disables that row. The planner normalizes all positive effective weights:

`P(row_i) = effective_weight_i / sum(all positive effective row weights)`

This allows future item-category or individual-item tuning without touching MID70 mutation code. If you want category-level knobs (e.g. gear vs consumable), first build an explicit source/catalog classification and then have a private layer allocate category weight before candidate weight; do not infer category from ID prefixes.

### Selected-fragment crit odds

`balance_overrides.fragment_quantity_rate_overrides` may override the weights for quantities `5`, `10`, `25`, and `50`. Missing keys keep source weights 87/10/2/1. The same normalization rule applies. Buy 1 remains fixed x5 unless a deliberately client-divergent future policy is introduced; the recovered rule explicitly says a single purchase does not crit.

### Multiplicity

`operations["1"].byproduct_rolls` and `operations["10"].byproduct_rolls` are private-policy multiplicity choices. Current v1 uses 1 and 10. Keep `selected_fragment_bundles=1` unless a future policy intentionally changes the separate `stick_items` contract.

### Costs are not ordinary balance knobs

The backend validates 500/5000 Crystal against the recovered source catalog. Do **not** change these values as an isolated server tweak: the client displays/assumes those prices. A price change requires a coordinated client-visible policy change and new evidence/override documentation.

### Target availability

The 49-target allow-list is recovered source content, not a balance rotation. A future rotation should be a separate private eligibility overlay layered on top of the source allow-list and owned-Girl requirement.

## Randomness/testability

All planners consume an injected `SummonRandomSource`. Keep this boundary. Future deterministic tests can inject a fake/seeded source without changing production RNG. For balance simulation, operate on policy/catalog data and planner APIs; do not execute reward mutations merely to estimate odds.

## Versioning checklist for a future balance change

- Create a new private policy version/revision; do not rewrite historical policy facts.
- Record exactly which knobs changed and why.
- Keep recovered source catalogs byte-stable unless new source evidence is being corrected.
- Validate that at least one positive effective candidate remains in every active pool/table.
- Validate guarantee ordering separately from base odds.
- Preserve result-channel ownership (`result`, `stick_items`, `reward`) exactly once.
- Record policy version in server diagnostics/receipts where useful, not by inventing new client response fields.


## Pass41.7 recovered duplicate conversion (not an RNG tuning knob)

Duplicate Hero conversion is now centralized in `data/summon_duplicate_conversion_policy.json`. Historical user-observed gameplay recovered native-star quantities 1★=7, 2★=14, 3★=30. The resolver keys on source `partner.ini_star` and credits `partner.stone_id`. Do not change these values as part of ordinary probability balancing; if a future private-server rebalance intentionally diverges, create a separately named/versioned override and preserve the recovered table as evidence. Unsupported native-star classes remain fail-closed until evidence or explicit policy defines them.

Magic selected-fragment crit tuning remains in `magic_summon_private_policy.json -> balance_overrides.fragment_quantity_rate_overrides`. The recovered quantity table 5/10/25/50 corresponds to 1x/2x/5x/10x of the baseline five fragments; override weights may be changed without touching MID70 transaction code.

## Pass42.12 validated operator tool

Use `python3 gacha_control.py` for supported operator changes instead of hand-editing JSON whenever possible. Small/Medium explicit category + native-star tuning lives in `data/classic_vending_balance_policy.json`; recovered `summon_pool_catalog.json` remains immutable evidence. Explicit Scroll selection uses real `partner.stone_id` classification and a flat/equal candidate split.

The tool deliberately locks the fixed Small/Medium x10 guarantee semantics and SX selected-hotspot guarantee=25 while exposing supported balance surfaces. If core Vending/Gacha class topology, policy schemas, cohorts, guarantees, or classification rules change, the same implementation pass must update `gacha_control.py` and its validation. A gacha logic change with an unreviewed/stale operator tool is an incomplete pass.
