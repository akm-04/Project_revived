# Pass92.0 Technical Changelog — MID116 Super Campaign Paid Resets

## Runtime baseline accepted

Pass91 MID657 is accepted from the supplied client smoke. `debug.zip` shows a fresh region-197 account claiming multiple source VIP tiers through real MID657 requests, including an immediate duplicate VIP14 request whose second response contains no economy mutation. A later cold bootstrap persists the claim vector. The user additionally confirmed the reward UI remains greyed after restart. The legacy sandbox MID1 itself already returns fifteen zero entries, so Pass92 does not alter VIP-award migration.

## MID116 implementation

`WorldHandlers.reset_campaign()` now delegates to `WorldRepository.reset_campaign()` rather than returning the entire world-map stub.

The repository requires Super Campaign (`campaign_type=2`), a source-known unlocked stage, exhausted remaining attempts, available paid-reset allowance, and sufficient Crystal. The source baseline `daily_limit` comes from the existing Pass75 campaign ownership metadata.

`CampaignResetPolicy` composes:

- base paid-reset allowance from `VipPrivilegeResolver.super_campaign_paid_reset_limit()` (`vip.lua.num_elite`),
- `+3` only when `PlayerState.privilege_left_card_day > 0`, sourced from `monthly_privilege.lua` row 1,
- nth Crystal cost from `refresh_cost.lua.refresh_elite_cost` at ordinal `reset_count + 1`.

The UoW transaction debits Crystal through `EconomyLedger`, restores the source Super `daily_limit`, increments `reset_count`, preserves `star`/`is_partner_drop`, and persists all changes atomically.

## Lost-response reconciliation

Pass90 correctly observed that source MID116 has no request nonce. Pass92 refines the policy using the source-owned state machine instead of fabricating a dedupe ID.

After a successful paid reset, server `daily_limit` is positive. The client cannot legitimately buy another reset until those attempts are exhausted. Therefore a repeated MID116 arriving while `daily_limit > 0` and `reset_count > 0` is returned as a mutation-free replay of the committed row. This lets Backend.lua recover from a lost successful HTTP response without a second debit. Once attempts reach zero again, the same request shape is once more a legitimate next paid reset and uses the next source cost.

## Boundaries

Pass92 does not implement MID117, MID118, Campaign repeat-drop RNG, Monthly Privilege purchase/decrement lifecycle, ordinary Store, Arena, or new VIP-dependent stub domains.
