# GXB backend v0.8.33 — Pass42.12 gacha control + classic balance overlay

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
