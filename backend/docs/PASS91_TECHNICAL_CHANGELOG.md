# Pass91.0 Technical Changelog — VIP Core Finalization

## Scope

Pass91 is a bounded implementation of the effective-source VIP one-time award lifecycle only. It does not implement MID116/117/118, cards, Skin Mall, ordinary Store, or VIP policy for domains that remain stubs.

## Source-backed claim state

`detail[17].vip_awards` is canonicalized to exactly 15 integer entries representing VIP1 through VIP15. `0` means unclaimed and `1` means claimed. Missing/empty legacy state migrates to fifteen zeroes because no earlier backend pass implemented MID657 server claims. Dictionary-shaped legacy state is normalized while retaining explicit claims. Python booleans are converted to literal integers so the persisted/client-visible values exactly match Lua's `== 1` tests.

## MID657 GET_VIP_AWARD

The dispatcher now routes MID657 to `VipAwardService`. The service validates `id` in 1..15 and requires `current_vip >= id`. Already-claimed tiers return `awards=[]` without an additional durable commit, which lets a lost-response retry reconcile the client's local claim marker without granting twice.

Reward policy is generated from effective `data/tables/vip.lua` and `data/tables/gift.lua`. `vip.lua.reward_item` identifies the gift row. The currently referenced VIP1..VIP15 gifts contain Backpack items and Crystal only.

Settlement reuses the established typed reward architecture:

- Crystal -> `EconomyLedger`.
- Item stacks -> typed `RewardTransactionService` / `MutationSettlementService` Backpack mutation.
- `vip_awards[level] = 1` -> VIP lifecycle owner.
- All three planes commit in one `PlayerUnitOfWork`.

A durable-write failure therefore rolls back both the reward and the claim marker.

## Response projection

The MID657 `awards` response is the complete user-visible source gift. Stack rewards use their canonical item IDs. Crystal uses table ID `-1`, the effective `asset.lua` backend ID for Crystal, matching the source gift-formatting conventions. The canonical Crystal balance remains owned by `EconomyLedger`; it is not converted into a Backpack currency stack.

## Generated metadata

`tools/build_commerce_vip_meta.py` now also generates `data/vip_award_meta.json` from effective merged source. Runtime does not execute the Lua tables. The self-test regenerates Commerce/VIP/VIP-award metadata from effective `src_64` and requires byte-for-byte equality with the packaged JSON.

## Transaction/idempotency behavior

MID657 has natural one-time idempotency through the durable claim marker. No synthetic network operation ID is needed: once claimed, the source operation itself is no longer semantically valid as another grant. A duplicate returns an empty award list and does not mutate state.

## Deferred

MID116 remains deferred to the next bounded Campaign/VIP phase. Pass91 does not change Recharge settlement, OTA behavior, VIP thresholds, privilege resolver values, Daily Reset, Campaign, Hero, or temporal-resource behavior.
