# Pass 88.0 — Commerce/VIP Phase 2 Writable Direct-Crystal Bridge

## Scope

Pass88 activates only the seven direct Crystal products already advertised by Pass87. MID657 VIP rewards, card entitlements, Skin Mall MID2981, ordinary Store, native Google/Apple receipt validation, historical TCP push framing, and MID116/117/118 remain deferred.

## Implementation

- Added `PurchaseIntent` and the authenticated preservation ingress `POST /preservation/v1/purchase-intents`. This is explicitly a private-server adapter for the unrecovered native purchase callback, not a historical game MID.
- Added `AutoAuthorizePurchaseProvider`; only source-advertised direct Crystal packs can settle. Effective source hides `80001030` on iOS, so the server rejects that platform/SKU pair as defense in depth.
- Added `CommerceProductPolicy`. Crystal payout uses source-generated base + first/repeat bonus. VIP progression uses a separate generated `vip_progression_delta`; for the direct `charge.lua` packs it is the base Crystal quantity and remains labelled `PRIVATE_SERVER_POLICY_SOURCE_BOUNDED`.
- Added `CommerceSettlementService` inside the existing `PlayerUnitOfWork`. One commit atomically credits Crystal through `EconomyLedger`, increments cumulative Commerce `charge`, derives VIP, updates `charge_count`/`last_buy_time`, stages a permanent purchase receipt, and stages a durable completion outbox record.
- Exactly-once identity is the caller-supplied stable `intent_id`. The receipt fingerprint binds authenticated player, region, charge ID and platform. Identical retry replays the committed result without another mutation; incompatible reuse is rejected.
- Permanent receipt replay is checked before current catalog authorization, so a lost response from a committed purchase remains recoverable even if a later build hides that SKU.
- Product history reads are now genuinely read-only. This closes a UoW hygiene hole where a failed commit could previously leave harmless schema scaffolding outside the restored snapshot.
- The PurchaseIntent route participates in Daily Reset before Commerce mutation because it is a player-mutating entrypoint outside `EngineDispatcher`. An undecided reset fails closed.
- Added source-shaped MID36857 completion construction for effective `SelfPlayer:onRecharge_`: `delta`, cumulative `total`, `vip`, cumulative `charge`, `charge_id`, and current card-day fields.
- Historical native/TCP completion framing is not recovered. Pass88 therefore uses `BRIDGE_RESPONSE_POST_COMMIT`: the HTTP response contains the already-committed MID36857 event. `tools/pass88_purchase_bridge.lua` can inject it into `xyd.event.RECHARGE` or temporarily intercept the normal direct-pack Recharge clicks.
- Updated current version metadata to `0.10.1 / Pass88.0`.

## Transaction invariants

1. Never trust client-supplied price, reward, VIP, charge, first-buy state or player ID.
2. Never credit before authorization and authenticated player binding.
3. Crystal remains EconomyLedger-owned; charge/VIP/history remain Commerce-owned.
4. Receipt + outbox + all game-state mutations commit in one PlayerUnitOfWork.
5. A failed durable write restores Crystal, charge, VIP, product history, outbox and receipt state.
6. Delivery may repeat; mutation may not.
