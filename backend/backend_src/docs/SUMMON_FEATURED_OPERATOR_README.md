# GXB Vending / Gacha Operator Guide — v0.8.33 Pass42.12

This is the operator-facing guide for the private-server Vending/Gacha implementation.
It separates **recovered client/source facts** from **explicit private-server balancing policy**. Do not present private rates below as historical official GXB server rates.

Pass42.12 added the standalone validated `gacha_control.py` operator utility and an optional classic Item/Scroll/Girl + native-star balance overlay. Existing private math remains unchanged when the new classic override is disabled. Fixed Small/Medium x10 guarantees and the SX 25-purchase selected-hotspot guarantee are preserved.

## Pass42.12 operator tool (preferred)

Run `python3 gacha_control.py` from the backend root. The four machine choices are Small / Medium / SX / Gachapon. It validates cohorts, percentages, fixed guarantees, timezones, and policy references; name-based hotspot selection writes the correct Hero ID automatically; every write receives a timestamped backup. See `docs/GACHA_CONTROL_TOOL.md`.

For this development/debugging stage, the shipped default is now `selection_mode: startup_debug` with `debug_seed: 0`. Use the tool to switch to `calendar_deterministic` when production-like calendar cycling is desired.

## 1. Featured rotation configuration

Edit:

`data/summon_featured_rotation_policy.json`

The important fields are:

```json
{
  "schema_version": 2,
  "selection_mode": "startup_debug",
  "rotation_seed": "gxb-private-server-featured-v1",
  "debug_seed": 0,
  "timezone": "Asia/Dhaka",
  "sx": {
    "week_manual_ids": [0, 0],
    "day_manual_ids": [0, 0, 0]
  },
  "medium": {
    "manual_hero_id": 0
  }
}
```

After changing this file, restart the server. The policy is read once at process startup.

### Mode A — `calendar_deterministic`

Normal/release-like calendar mode. It remains fully supported but is no longer the shipped Pass42.12 development default.

- SX Current Hotspots: 2 SX Girls per ISO week.
- SX Daily Hotspots: 3 other SX Girls per calendar day.
- Medium `SUMMON_LIST_NEW_ADD`: 1 Girl per day from the 56-Girl featured-only Legacy cohort.
- The cycle is deterministic from `rotation_seed`, calendar bucket, and configured timezone.
- Restarting within the same day/week keeps the same automatic choices.
- Use an IANA timezone name. `UTC` is recommended for hardware-neutral deployment.
- The host machine's locale is not auto-detected. The machine supplies the current absolute clock; `ZoneInfo(timezone)` defines day/week boundaries.

Example portable normal mode:

```json
{
  "selection_mode": "calendar_deterministic",
  "rotation_seed": "gxb-private-server-featured-v1",
  "debug_seed": 0,
  "timezone": "UTC",
  "sx": {
    "week_manual_ids": [0, 0],
    "day_manual_ids": [0, 0, 0]
  },
  "medium": {
    "manual_hero_id": 0
  }
}
```

### Mode B — `startup_debug`

Fast QA/debug mode. **This is the shipped Pass42.12 development default.**

At server process startup the backend chooses and freezes:

- 2 unique SX Current Girls from the canonical 73 SX cohort;
- 3 additional unique SX Daily Girls from the same 73 cohort;
- 1 Medium New Add Girl from the 56 featured-only Legacy cohort.

The same frozen selection is shared by request services **and player-load/maintenance normalization** for the lifetime of the process. It is not rerolled on every request or every policy lookup.

#### Fresh debug selection every restart

```json
{
  "selection_mode": "startup_debug",
  "debug_seed": 0
}
```

`0`, missing, or an empty debug seed means: generate fresh boot entropy. Startup logs the generated seed and a short run ID.

Example log shape:

```text
[SUMMON ROTATION] mode=startup_debug debug_seed=<generated-seed> debug_run_id=<id> date=... week=... sx_week=[...] sx_day=[...] medium=... timezone=...
```

Copy the logged `debug_seed` into the policy if you want to reproduce that exact automatic debug selection later.

#### Reproducible debug selection

```json
{
  "selection_mode": "startup_debug",
  "debug_seed": "qa-kongming-sx-cycle-01"
}
```

The same `rotation_seed` + explicit `debug_seed` + unchanged cohorts produces the same automatic boot selection across restarts.

`startup_debug` changes **featured identities only**. It does not make pulls deterministic and does not alter any gacha rate.

## 2. Manual featured overrides

Use **Hero table IDs**, never runtime owned-instance `partner_id` values.

Example:

```json
{
  "selection_mode": "startup_debug",
  "debug_seed": "qa-01",
  "timezone": "UTC",
  "sx": {
    "week_manual_ids": [10001045, 10001100],
    "day_manual_ids": [10001218, 10001228, 0]
  },
  "medium": {
    "manual_hero_id": 10001144
  }
}
```

Rules:

- `0` is automatic **for that individual slot**.
- A valid nonzero SX weekly/daily ID must be in `docs/GIRLS_SX_73.txt`.
- All five resolved SX IDs are kept unique.
- A valid nonzero Medium ID must be in `docs/GIRLS_MEDIUM_FEATURED_56.txt`.
- Invalid JSON, malformed values, ineligible IDs, or duplicate SX overrides warn and fall back instead of crashing.
- Fallback uses the active automatic mechanism: calendar selection in `calendar_deterministic`, frozen boot selection in `startup_debug`.

Therefore these are valid mixed configurations:

```json
"day_manual_ids": [10001218, 10001228, 0]
```

and:

```json
"day_manual_ids": [0, 10001228, 0]
```

Only the zero positions are auto-filled.

## 3. Girl/cohort reference files

All are in `docs/`:

- `GIRLS_SX_73.txt` — exact 73 canonical SX Girls.
- `GIRLS_MEDIUM_FEATURED_56.txt` — exact New Add/rate-up cohort.
- `GIRLS_MEDIUM_EXTENDED_58.txt` — exact Soul-Casket-backed Legacy ordinary extensions.
- `GIRLS_MEDIUM_ORDINARY_143.txt` — full effective ordinary Medium Hero set: 85 recovered + 58 extensions.
- `ALL_GIRLS_ID.txt` — all 291 canonical Girls in one merged table.
- `GIRL_IDS.txt` — compatibility alias of `ALL_GIRLS_ID.txt`.

Runtime featured validation uses `data/summon_featured_catalog.json`, not the text files.

`tools/generate_summon_girl_docs.py` regenerates the sheets from:

- runtime authority `data/summon_featured_catalog.json`;
- recovered pool authority `data/summon_pool_catalog.json`;
- compact operator projection `data/girl_reference_catalog.json`.

The Pass42.11 Girl-reference validation cross-checked the 291-row operator catalog against the canonical Pass42.10 Girl database and effective Lua source: all 277 normal Partner IDs occur in effective `partner.lua`, and all 14 Vow IDs occur in effective `super_partner.lua`.

## 4. Current Vending/Gacha behavior and rates

### Important provenance rule

There are two kinds of numbers below:

1. **Recovered/source-backed facts** — client-visible costs, pool membership/row weights, some guarantee constants, Magic fragment crit table, duplicate conversion, etc.
2. **Private-server policy** — unrecovered EOL server RNG reconstructed for this hobby server. These are intentionally configurable and are not historical-rate claims.

### Small Vending

Active paid operations:

- Paid x1: `10,000 Mana`.
- Paid x10: `90,000 Mana`.
- Paid x100: `900,000 Mana` for 100 results (activated in Pass42.14 from the stock `(type=1,index=4)` client path).

Post-tutorial free Small:

- source-backed timer period: 600 seconds;
- uses the normal private Small result planner;
- `mana_free_num` is not automatically replenished because the historical reset calendar is unrecovered.

Ordinary private rate:

- Full-Hero/super-pool chance: `40 / 10,000 = 0.40%`.
- Otherwise the configured base item pool is used.
- x10 private guarantee: at least one item-class result, without overriding a recovered milestone/special slot.
- x100 preserves that guarantee independently across each of its ten consecutive 10-result blocks.

Small counter special milestones are source topology at result slots:

`1, 2, 5, 50, 150, 300`

Private v1 advances the persistent result-slot counter by one per result and does not invent a reset.

### Pass42.12 classic explicit category/rarity overlay

Preferred operator path: `python3 gacha_control.py`. The new `data/classic_vending_balance_policy.json` is opt-in per Small/Medium family. With category override disabled, the exact earlier two-stage policy remains active. With it enabled, the planner chooses explicit `item` / `scroll` / `girl` categories; scroll rows are identified only through real `partner.stone_id` values and are flat/equal within the Scroll category. Full-Girl native-star override chooses 1★/2★/3★ first, then source/extension weighting within that star.

Medium's established ordinary baseline resolves exactly to 55.6% non-scroll Item / 30.0% Girl Scroll / 14.4% full Girl. Small's established private baseline resolves to approximately 64.693% / 34.907% / 0.4%.

**Change the Small top-level Hero chance:**

Edit:

`data/summon_private_server_policy.json`

Path:

`small.ordinary_policy.super_chance_per_10000`

Example: `100` means 1.00%; `250` means 2.50%. Restart after editing.

Do not casually rewrite `data/summon_pool_catalog.json`; it preserves recovered source pool rows/weights.

### Medium Vending

Active paid operations:

- Paid x1: `288 Crystal`.
- Paid x10: `2,590 Crystal`.
- Ticket and discount variants remain deferred/fail-closed in this backend revision.

Ordinary private class rate on non-special slots:

- Ordinary full-Hero pool chance: `1,440 / 10,000 = 14.40%`.
- Otherwise the ordinary item pool is selected.
- x10 private guarantee: at least one Hero-class result, replacing only a replaceable ordinary slot if needed.

Medium paid counter special topology occupies slots `1..11` with recovered special dropboxes. A special/milestone slot takes precedence over both the New Add overlay and ordinary class selection.

#### Medium New Add / featured-only 56

Policy file:

`data/medium_legacy_private_policy.json`

Current private policy:

- target cohort: `GIRLS_MEDIUM_FEATURED_56.txt`;
- chance: `500 / 10,000 = 5.00%` per eligible **non-special paid Medium result slot**;
- pity: force the current New Add target on the 20th eligible miss slot;
- pity target/counter rebind when the featured target changes.

This overlay is evaluated before the ordinary 14.4%-Hero-vs-item decision on eligible non-special slots. Therefore a successful featured overlay directly returns the displayed New Add Girl.

**Change the New Add rate:**

`featured_daily_overlay.chance_per_10000`

Examples:

- `250` = 2.5%
- `500` = 5%
- `1000` = 10%

**Change pity:**

`featured_daily_overlay.pity_eligible_slots`

Example: `10` forces on the 10th eligible miss slot.

#### Medium Soul-Casket-backed 58 extension

The 58 IDs in `GIRLS_MEDIUM_EXTENDED_58.txt` are merged only into the ordinary recovered Medium Hero pool after the ordinary Hero class has already been chosen.

- recovered ordinary Hero candidates: 85;
- Legacy extension candidates: 58;
- effective unique ordinary Hero candidates: 143.

This 58-Girl extension **does not increase Medium's top-level ordinary Hero-vs-item probability**.

Current default extension candidate weight: `118`, matching the common recovered pool200004 Hero-row weight.

Change default/per-Girl extension weighting in:

`data/medium_legacy_private_policy.json`

Paths:

- `ordinary_hero_extension.default_candidate_weight`
- `ordinary_hero_extension.hero_weight_overrides`

Example override:

```json
"hero_weight_overrides": {
  "10001249": 236
}
```

This doubles that extension Girl's candidate weight relative to the default 118, but only inside the already-selected ordinary Hero pool.

### SX / Soul Box

Recovered operation contract:

- MID50 type4;
- selectors 1/2;
- cost: `388 Crystal`;
- minimum VIP: `9`;
- exactly 6 result rows per purchase;
- five static item slots + one dynamic reward slot.

The five static slots independently roll recovered pools:

`200007, 200008, 200009, 200010, 200011`

Current private dynamic-slot class rates:

- Full current SX Girl: `500 / 10,000 = 5%`.
- Normal native-3★ Girl fragments (Soul-Casket type2): `55%`.
- Normal native-2★ Girl fragments (Soul-Casket type5): `30%`.
- Ordinary full Girl (Soul-Casket type6): `10%`.

Inside the 5% full-SX class:

- selected hotspot share: `50%`;
- baseline selected-hotspot probability is therefore `2.5% per SX purchase` before pity;
- the other 50% is weighted across the other current SX candidates.

Selected-hotspot pity:

- recovered constant: `guarantee_times = 25`;
- private interpretation: after 25 consecutive purchases without producing the selected full SX hotspot, force it;
- counter resets when selected hotspot is produced and rebinds/reset when hotspot target changes.

The automatic Current/Daily rotation only determines which SX Girls are advertised/selectable. It **does not change** the 5/55/30/10 dynamic class rates.

**Change SX class rates:**

Preferred private override location:

`data/sx_soul_box_private_policy.json -> balance_overrides.class_weight_overrides`

Example:

```json
"class_weight_overrides": {
  "sx_full_hero": 1000,
  "normal_three_star_fragments": 5000,
  "normal_two_star_fragments": 3000,
  "ordinary_full_hero": 1000
}
```

Effective positive weights are normalized by the planner. Keep the intent documented because these are private balance values.

Other SX tuning seams:

- `balance_overrides.static_item_row_weight_overrides`
- `balance_overrides.sx_candidate_weight_overrides`
- `balance_overrides.soul_casket_row_weight_overrides`
- `hotspot_policy.selected_hotspot_share_within_sx_class_per_10000`
- `hotspot_policy.guarantee_purchases`

Do not put non-SX event Girls into the SX cohort. SX identity remains current `partner.is_sx` authority.

### Magic Gachapon

Magic is a separate MID70/MID71 plane.

Recovered/client-visible costs:

- x1: `500 Crystal`;
- x10: `5,000 Crystal`.

Private operation behavior:

- x1: one recovered pool700008 byproduct + exactly 5 selected-target fragments;
- x10: ten recovered pool700008 byproducts + one selected-target fragment bundle using the recovered crit table.

Recovered selected-fragment x10 quantity weights:

- 5 fragments: `87%`
- 10 fragments: `10%`
- 25 fragments: `2%`
- 50 fragments: `1%`

Tuning file:

`data/magic_summon_private_policy.json`

Private override seams:

- `balance_overrides.byproduct_row_weight_overrides`
- `balance_overrides.fragment_quantity_rate_overrides`

Magic target eligibility and costs are source-backed contracts and should not be casually changed as ordinary balance knobs.

## 5. Duplicate Girl conversion

Recovered historical/user-observed duplicate conversion is centralized in:

`data/summon_duplicate_conversion_policy.json`

Based on the Girl's **native/initial star**, not her evolved current star:

- native 1★ duplicate -> 7 own fragments/scrolls;
- native 2★ duplicate -> 14;
- native 3★ duplicate -> 30.

The item ID comes from the Girl's canonical `partner.stone_id`.

Unsupported native-star classes fail closed rather than guessing.

## 6. Retry/replay safety

Repeatable private summon operations use a short 1500 ms replay window where defined. This protects against immediate duplicate transport retries so the same request is not charged twice.

Tradeoff: an intentionally repeated identical purchase inside that very short window can be treated as a replay.

Pass42.12 does not change this replay behavior.

## 7. Safe operator workflow for changing rates

1. Prefer `python3 gacha_control.py` for supported changes; make one policy change at a time.
2. Keep recovered source catalogs unchanged unless you are correcting source evidence.
3. Prefer the explicit private `balance_overrides` sections when available.
4. Keep all active weights nonnegative and ensure each active pool/class still has positive total weight.
5. Restart the server so JSON policy changes are reloaded.
6. Read the startup `[SUMMON ROTATION]` line to verify featured mode/IDs.
7. `startup_debug` is the Pass42.12 shipped development default; use `calendar_deterministic` when production-like calendar behavior is desired.
8. Record intentional private-rate changes separately from recovered historical/source facts.

## 8. Files to inspect when debugging a pull

Featured identity:

- `data/summon_featured_rotation_policy.json`
- `data/summon_featured_catalog.json`
- `docs/GIRLS_SX_73.txt`
- `docs/GIRLS_MEDIUM_FEATURED_56.txt`

Classic Small/Medium:

- `data/summon_cost_policy.json`
- `data/summon_private_server_policy.json`
- `data/summon_counter_policy.json`
- `data/summon_pool_catalog.json`

Medium Legacy:

- `data/medium_legacy_private_policy.json`
- `docs/GIRLS_MEDIUM_EXTENDED_58.txt`
- `docs/GIRLS_MEDIUM_ORDINARY_143.txt`

SX:

- `data/sx_soul_box_private_policy.json`
- `data/sx_soul_box_source_catalog.json`

Magic:

- `data/magic_summon_private_policy.json`
- `data/magic_summon_source_catalog.json`

Duplicate conversion:

- `data/summon_duplicate_conversion_policy.json`

All-Girl ID lookup:

- `docs/ALL_GIRLS_ID.txt`

## Pass42.12 control-tool maintenance contract

If a future pass changes critical gacha drop-class topology, private policy schema/filenames, cohort definitions, fixed guarantees, or candidate classification, that same pass must audit and update `gacha_control.py`, `docs/GACHA_CONTROL_TOOL.md`, and Pass42.12-style validation. The tool must never silently lag behind core gacha behavior.
