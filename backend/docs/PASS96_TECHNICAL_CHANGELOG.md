# Pass96.0 Technical Changelog

## Scope

Bounded Global Economy/VIP cleanup only. No RNG implementation, no MID97, no Monthly Privilege lifecycle, no Store expansion, and no new Campaign repeat reward policy.

## Academy authority

- Recovered `player.lua` has levels 1..100 only; Academy max is 100.
- `PlayerState.max_lev` default is 100.
- Player-load maintenance normalizes persisted `max_lev` to 100 and clamps impossible level >100.
- At level100, cumulative EXP is capped at 613614 (`total_exp(100)-1`) because `SelfPlayer.lua` increments the local level before checking `maxTeamLev`.
- Legacy sandbox seed and Pass96 migration target level100, EXP579615, max_lev100, max_energy160.

## Source item stack ceilings

- Added `item_stack_limit_meta.json`, generated from effective `data/tables/item.lua`.
- Catalog contains all 5,838 recovered item rows and their source `stack` / `stack_exceed_mail` values.
- Canonical InventoryRepository/StackInventory rejects a positive mutation when its post-state exceeds a positive source stack ceiling.
- The rejection occurs inside the existing PlayerUnitOfWork so sibling mutations roll back atomically.
- Negative deltas are permitted from a legacy-overfull stack so invalid historical saves can consume/craft downward.
- Source `stack=0` rows are not interpreted as a zero-cap ordinary Backpack rule without storage-plane evidence.
- No overflow-mail settlement was invented.

## UID 13371337 sandbox normalization

New one-shot marker: `pass96_debug_account_normalization_v1`.

- Academy -> lev100, exp579615, max_lev100, max_energy160.
- Existing inventory only; no item additions and no replenishment.
- Source cap >=999 -> lower only if above 900.
- Source cap 99 -> lower only if above 90.
- Other positive caps -> conservative 90% headroom fallback.
- Historical Pass72/73 seed markers remain untouched.

The historical 1,717 seeded IDs resolve to 1,697 cap-999 rows, 18 cap-9999 rows, and two cap-99 rows, with no unknown IDs.

## VIP entitlement cleanup

- Campaign multi-sweep: count >1 requires source VIP `quick_sweep` or `privilege_left_card_day > 0`. `quick_sweep` first becomes true at VIP4. Single sweep is unchanged.
- Hero preset save: serialized team count may not exceed source VIP `preset_num` (VIP0=10, VIP3=12, VIP6=14, VIP9=16, VIP12=18, VIP15=20).
- SX/Soul Box was deliberately not changed; QA confirmed the existing server purchase path already blocks below VIP9.

## Validation status

Static/self-test accepted; client runtime acceptance pending.
