# Pass 87.0 — Commerce/VIP Implementation Phase 1

## Scope

Pass87 implements only the first bounded slice of the Pass86 Commerce RFC. The native PurchaseIntent bridge, purchase settlement, MID36857 completion delivery, MID657 VIP award claims, cards, ordinary Store, cash skins, and MID116/117/118 remain deferred.

## Changes

- Added generated `data/commerce_source_meta.json` from effective `src_64/data/tables/charge.lua`.
  - Advertises exactly seven direct Crystal products: `80001002, 80001003, 80001004, 80001005, 80001006, 80001007, 80001030`.
  - Cards/Privilege products are deliberately excluded until their entitlement lifecycle exists.
  - Direct-pack VIP progression uses base `diamond` as a clearly labelled `PRIVATE_SERVER_POLICY_SOURCE_BOUNDED`; first-buy bonus does not implicitly become VIP progression.
- Added generated `data/vip_source_meta.json` from effective `src_64/data/tables/vip.lua`.
  - Preserves all VIP0–VIP15 raw policy rows.
  - Canonical cumulative thresholds: `0,30,300,900,1500,3000,6000,9000,15000,20000,30000,45000,60000,100000,250000,500000`.
- Added `VipProgressionPolicy`.
  - `vip = highest VIP level whose charge_req <= cumulative charge`, capped at VIP15.
- Added `VipPrivilegeResolver` as the single non-Commerce VIP policy facade.
  - Stable semantic accessors exist for Sweep Cards, Energy/Mana purchase limits, Super Campaign paid reset allowance, Skill Point purchase permission/cap, and generic minimum-VIP checks.
- Migrated already-implemented VIP reads:
  - Skill Point purchase permission and natural cap now resolve through `VipPrivilegeResolver`.
  - `TemporalPolicyService` Skill Point regeneration cap now resolves through the same facade.
  - Summon/Soul Box minimum-VIP dispatch validation now uses `VipPrivilegeResolver.meets_level()` instead of direct `player.vip` comparison.
- Added server-only `PlayerState.commerce_state`.
  - Holds schema/version, direct recharge product history, migration markers, and later exactly-once Commerce metadata.
  - It is persisted under `player.domains` and is never projected in MID17/player-info.
- Added `CommerceEntitlementService`.
  - Owns coherence of cumulative `charge`, derived `vip`, and Commerce product history.
  - No purchase mutation API is activated in Pass87.
- Added one-time established sandbox normalization.
  - Exact legacy signature `account_uid=13371337, vip=15, charge=0` becomes `vip=15, charge=500000`.
  - Classified as `STATE_NORMALIZATION_NOT_PURCHASE`.
  - Grants zero Crystal, creates no product history/receipt, consumes no first-buy bonus, and is idempotent.
- Added `RechargeCatalogService` and wired MID354 `QUERY_CHARGE_DATA`.
  - Returns source-known direct Crystal charge IDs plus canonical per-player `charge_count` and `last_buy_time`.
  - New/unpurchased products return `0/0`.
  - `giftbags=[]` remains explicit because activity/card Commerce is not implemented.
  - `server_time` uses the request-scoped authoritative `ServerClock`.
- Added `tools/build_commerce_vip_meta.py` so runtime JSON can be regenerated from effective `src_64` without executing Lua.

## Transaction boundary

Pass87 intentionally does **not** activate purchase settlement. Crystal remains owned by `EconomyLedger`; `charge/vip` remain Commerce-owned. Phase 2 will add the PurchaseIntent/authorization/exactly-once UoW path after this state/catalog foundation passes client smoke.
