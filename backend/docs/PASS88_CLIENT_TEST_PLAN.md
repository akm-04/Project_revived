# Pass 88.0 Client / Manual Purchase Test Plan

## Direct HTTP trigger

The engine HTTP server defaults to port `9000`. For the packaged established sandbox, this manual request uses the known local session token:

```bash
curl -sS -X POST "http://127.0.0.1:9000/preservation/v1/purchase-intents" \
  -H 'Content-Type: application/json' \
  -d '{
    "intent_id": "manual-pass88-001",
    "charge_id": 80001007,
    "platform": "preservation_manual",
    "token": "local_token",
    "region": 125
  }'
```

`80001007` is the 100-Crystal source product. On its first purchase, the source first-buy bonus makes the Crystal delta 200. The Pass88 private policy advances cumulative VIP `charge` by the base 100, not by the 200 Crystal total.

**Idempotency rule:** retrying the exact same `intent_id` is safe and should return `status=REPLAYED` without granting again. To perform a second real purchase, use a new `intent_id`. Reusing an old intent ID with a different SKU/platform/player must be rejected.

A raw cURL call mutates the server but cannot by itself inject the returned event into an already-running Lua client. The client will reconcile durable totals on reload; for live UI testing use the Lua preservation bridge below.

## Lua preservation bridge

`tools/pass88_purchase_bridge.lua` is an explicitly private-server test shim, not recovered historical client code. Load it in the client environment, then either trigger one purchase directly:

```lua
xyd.pass88Purchase(80001007)
```

or temporarily intercept normal direct-Crystal clicks in `VipRechargeWindow`:

```lua
xyd.installPass88PurchaseBridge()
```

After that, click a direct Crystal package normally. The shim POSTs the PurchaseIntent, receives the committed MID36857 event, and dispatches it as `xyd.event.RECHARGE` using the nesting expected by effective `SelfPlayer:onRecharge_`. Non-direct purchase paths fall through to the original native functions. Restore originals with:

```lua
xyd.uninstallPass88PurchaseBridge()
```

## Acceptance sequence

- Prefer a fresh `commerce_lab` account at VIP0/charge0 to test VIP progression. The established sandbox is already normalized to VIP15/charge500000 and therefore cannot visibly level beyond VIP15.
- Query/open Recharge first and confirm MID354 still shows the seven direct packs.
- Purchase `80001007` with a unique intent. On a fresh account expect +200 Crystal first-buy payout, cumulative charge +100, VIP0→VIP1, and MID354 `charge_count=1`.
- Retry the **same** intent ID. Expect `REPLAYED`, no Crystal/charge/VIP/count change, and the same MID36857 completion payload.
- Purchase `80001007` again with a **new** intent. Expect +100 Crystal, charge +100, no first-buy bonus, `charge_count=2`.
- Continue until cumulative charge reaches exactly 300 and confirm canonical VIP2.
- Restart backend/client. Verify Crystal, charge, VIP, product history, permanent receipts and completion outbox survive. Retry a previously committed intent after restart; it must replay without another grant.
- Try an unknown `charge_id`; expect fail-closed.
- Try `charge_id=80001030` with platform `ios`; expect fail-closed because effective Recharge UI hides that SKU on iOS.
- Confirm Daily Reset/Campaign/Skill/Summon behavior remains healthy after purchase activity.
- Preserve `server.txt`, client Lua errors and the affected player JSON if any value diverges.

## Deferred expectations

Do not test MID657 VIP reward claims, monthly/privilege cards, Skin Mall MID2981, ordinary Store, cash skins, native store receipt validation, direct game TCP push framing, or MID116/117/118 as Pass88 functionality.
