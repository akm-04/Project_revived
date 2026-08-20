# GXB backend v0.8.34 — Pass42.14 Small x100 hotfix

Pass42.14 is the final narrow gacha hotfix on top of v0.8.33/Pass42.12. A fresh runtime trace proved that the stock Small result window sends MID50 `summon_type=1, summon_index=4` for the 100x button, while the backend still carried the old Pass41 `deferred_fail_closed` marker. Effective Lua independently confirms `ManaHundred = 4`, cost 900000 Mana, pull count 100, and a dedicated >10-result scroll/aggregation UI.

## Pass42.14 changes

- Activates `small_paid_100` through the same Custom Private Server classic planner already used by Small x1/x10.
- Activates the existing `small_paid_hundred` cost plan: exactly 900,000 Mana for 100 result slots.
- Preserves all classic counter/milestone, duplicate 7/14/30 conversion, explicit Pass42.12 rate overrides, transaction, replay, and result-wire behavior.
- Preserves the Small x10 `at_least_one_item` guarantee by applying it independently to each consecutive 10-result block in an x100 purchase; recovered special milestone slots continue to win and are never replaced.
- Returns 100 ordinary classic result rows; the stock `SummonResultWindow` handles >10 rows by aggregating identical table IDs into its scrolling list.
- Ticket/coupon/discount variants remain fail closed. No Medium/SX/Magic/Gachapon rates or rotation behavior changed.

## Evidence boundary

The 2026-08-20 user debug trace runtime-confirms the x100 request topology and the v0.8.33 rejection. Effective `src_64` confirms enum/index, 900000-Mana cost, 100-pull count, and client >10 display handling. v0.8.34 is repository/static-confirmed here and should receive one final client x100 smoke before being promoted to runtime-confirmed.


Pass42.12 builds on v0.8.32/Pass42.11 and the runtime-confirmed Pass42.10 summon/progression baseline. It adds a separate validated operator utility for Small / Medium / SX / Gachapon configuration and introduces an optional classic Item/Scroll/Girl + native-star balance layer.

## Pass42.12 changes

- Adds root `gacha_control.py` (stdlib only, does not start/import Flask):
  - exact four-machine menu: Small, Medium, SX, Gachapon;
  - validated `startup_debug` / `calendar_deterministic`, debug-seed and timezone controls;
  - name-driven SX Current/Daily and Medium New-Add selection with cohort validation;
  - rate editors for machine-specific supported private balance surfaces;
  - timestamped backups + atomic JSON writes;
  - `--check` and `--summary` modes.
- Shipped development default changes to `selection_mode: startup_debug`, `debug_seed: 0`. Calendar mode remains fully supported and preserves the Pass42.10 deterministic snapshot.
- Adds `data/classic_vending_balance_policy.json`:
  - optional explicit Small/Medium Item / Girl Scroll / Full Girl class split;
  - optional native 1★ / 2★ / 3★ full-Girl split;
  - explicit Girl-scroll classification through effective `partner.stone_id`;
  - flat/equal scroll candidate split when explicit Scroll category tuning is enabled;
  - source/extension weighting preserved within a selected native-star Girl bucket.
- Keeps classic pre-Pass42.12 math exactly active when the new override is disabled.
- Keeps fixed guarantee semantics out of the tool: Small x10 item-class, Medium x10 full-Girl, SX selected-hotspot at 25 purchases.
- Medium New Add remains a separate featured-only56 overlay; the tool can change its chance and target but keeps its 20 eligible-slot pity locked.
- SX and Magic/Gachapon continue using their existing modular override seams rather than being rewritten into a fake universal gacha algorithm.

## Operator use

```bash
python3 gacha_control.py
python3 gacha_control.py --check
python3 gacha_control.py --summary
```

See `docs/GACHA_CONTROL_TOOL.md` and `docs/SUMMON_FEATURED_OPERATOR_README.md`.

## Important maintenance contract

If a later pass changes critical gacha/drop-class topology, private policy schemas/filenames, cohort definitions, fixed guarantees, or candidate classification, that same pass must audit and update `gacha_control.py` and its validation. Do not leave the operator tool stale after a core gacha change.

## Validation

```bash
PYTHONPATH=. python3 tools/validate_pass42_12.py
```

Pass42.12 validation is static/repository/tool validation. The attached user startup trace runtime-confirms the Pass42.11 `startup_debug` boot/fresh-seed/fixed-seed behavior, but v0.8.33 rate edits still require a future client smoke if runtime promotion is desired.

Pass43–45 remain reserved pure cross-mode RNG/drop research/planning.
