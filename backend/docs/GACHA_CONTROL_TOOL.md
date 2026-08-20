# GXB Vending / Gacha Control Tool — Pass42.12

Run from the backend root:

```bash
python3 gacha_control.py
```

Validation-only and summary modes:

```bash
python3 gacha_control.py --check
python3 gacha_control.py --summary
```

The tool is a separate, self-contained Python/stdlib operator utility. It does **not** import or start the Flask backend. It edits only private policy JSON files, validates the complete relevant policy set before writing, makes a timestamped backup under `data/operator_backups/`, and uses atomic file replacement.

## Top-level menu

The interactive menu has exactly four machine choices:

1. Small Vending
2. Medium Vending
3. SX Vending
4. Gachapon

Shared featured-rotation controls are intentionally nested under Medium and SX because only those machines consume the Current/Daily/New-Add identity policy.

## Featured identity controls

The tool can switch between:

- `startup_debug` — current Pass42.12 development default; fresh `debug_seed=0` rerolls the automatic 2 Current + 3 Daily SX + 1 Medium New Add selection once per server process;
- `calendar_deterministic` — deterministic calendar-cycle mode using the configured IANA timezone.

It can also set:

- `debug_seed` (`0` = fresh each boot; a string/integer = reproducible);
- IANA timezone such as `UTC` or `Asia/Dhaka`;
- each of the two SX Current slots independently to AUTO or a named SX73 Girl;
- each of the three SX Daily slots independently to AUTO or a named SX73 Girl;
- Medium New Add independently to AUTO or a named featured-only56 Girl.

Girl selection is name-driven. The tool searches the canonical operator catalog, displays name + Hero table ID + native star, and writes the validated ID automatically. It rejects cohort mismatches and duplicate pinned SX hotspots.

## Small Vending controls

Pass42.12 adds an optional classic balance overlay in:

`data/classic_vending_balance_policy.json`

When the Small category override is **disabled**, the exact pre-Pass42.12 two-stage private math remains active. The effective ordinary baseline is approximately:

- non-scroll Item: 64.693%
- Girl scroll: 34.907%
- full Girl: 0.400%

When explicitly enabled, the tool accepts an exact 100.00% split among Item / Girl Scroll / Full Girl.

The Small full-Girl source pool currently contains only native-1★ Girls. The tool therefore rejects nonzero 2★/3★ full-Girl rates.

The Small x10 item-class guarantee remains fixed and is not exposed as a balance knob.

## Medium Vending controls

When the Medium category override is disabled, the exact established ordinary non-special split remains:

- non-scroll Item: 55.600%
- Girl scroll: 30.000%
- full Girl: 14.400%

When enabled, Item / Girl Scroll / Full Girl can be set to any nonnegative exact 100.00% split.

Full-Girl results can additionally be split by native 1★ / 2★ / 3★. The effective ordinary 143-Girl pool contains:

- 13 native-1★ candidates;
- 33 native-2★ candidates;
- 97 native-3★ candidates.

The star layer chooses the native-star bucket first, then preserves source/Legacy-extension candidate weights inside that bucket.

Girl Scroll classification is explicit: an item is considered a Girl scroll only when its item ID equals a real `partner.stone_id` in the effective game-data catalog. Numeric-prefix guessing is forbidden. Under explicit Scroll-category tuning, the 83 eligible scroll rows in pool200003 are split **flat/equally** as requested.

The Medium New Add overlay remains separate from ordinary category rates. The tool can change its per-eligible-slot rate and choose AUTO/a named featured-only56 target. Its 20-eligible-slot pity remains locked in this tool.

The Medium x10 full-Girl guarantee remains fixed and is not exposed as a balance knob.

## SX / Soul Box controls

SX still produces five recovered static item slots plus one dynamic slot per purchase. The tool can change only private balance surfaces:

- dynamic class percentages: full current SX Girl / native-3★ scrolls / native-2★ scrolls / ordinary full Girl;
- selected-hotspot share inside the full-SX class;
- individual current-SX candidate effective weight;
- individual row effective weight inside each of the five recovered static item pools;
- Current/Daily hotspot identities and shared rotation mode/seed/timezone.

The selected-hotspot guarantee remains fixed at **25 purchases**. The tool validates that this guardrail has not drifted.

## Magic Gachapon controls

Magic/Gachapon does not have a random full-Girl result class. It gives:

- random item byproducts from recovered pool700008;
- scrolls for the already-selected eligible Girl.

The tool can therefore change:

- x10 selected-scroll quantity rates for 5 / 10 / 25 / 50 scrolls;
- individual pool700008 byproduct item effective weights.

The x1 selected-scroll quantity remains fixed at 5, and recovered costs remain fixed at 500 / 5000 Crystal.

## Critical maintenance contract

`gacha_control.py` is coupled to the **public private-policy schema**, not to protocol handlers. If a later pass changes any critical Vending/Gacha drop-class topology, policy filename/schema, cohort definition, fixed guarantee, or candidate-classification rule, that same pass **must audit and amend this tool and its validation**. Do not change core gacha/drop logic and leave this operator utility stale.

Recovered catalogs such as `summon_pool_catalog.json` remain evidence and must not be rewritten just to rebalance the private server.
