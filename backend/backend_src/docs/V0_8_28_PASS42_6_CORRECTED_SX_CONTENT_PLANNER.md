# v0.8.28 / Pass42.6 — Corrected SX content planner

## Preserved recovered shell
MID50 type4 selector1/2, VIP9+, 388 Crystal, six iterable result rows, static pools 200007..200011, atomic mutation, generic Hero/item/to_stone rendering and replay protection.

## Corrected sixth-slot model
The sixth row is selected from a private top-level reward-class distribution. Current SX full-Hero eligibility comes from `partner.is_sx`, not Soul-Casket type6. Orphan types2/5/6 remain separate candidate classes; types3/4 remain disabled.

## Private v2 default class mix
- SX full Hero: 5%
- normal native-3★ fragments: 55%
- normal native-2★ fragments: 30%
- ordinary full Hero: 10%

Within the SX class, the selected weekly hotspot receives 50% of the class share. A 25-miss private guarantee forces that selected SX Girl. These numbers are intentionally tunable and are not recovered official rates.

## Migration
Any persisted MID56 `main_ids`/`second_ids` containing non-SX IDs is replaced by private source-valid SX defaults at normalization. This specifically heals v0.8.27 state that may contain Geisha/Joan.
