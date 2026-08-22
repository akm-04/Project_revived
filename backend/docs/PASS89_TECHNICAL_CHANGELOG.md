# Pass 89.0 Technical Changelog — OTA Purchase Bridge + Token Safety

## Status

Pass89 is a bounded correction/integration pass over the already-committed Pass88 direct-Crystal settlement plane. It does **not** change Commerce payout math, first-buy policy, VIP thresholds, permanent receipt semantics, or UoW settlement ownership.

The supplied Pass88 smoke (`debug.zip`, SHA-256 `fd6b98e2b5cf6e9828d5a79a03e473ad0eed94c6d57584e7839151f4d3368baa`) runtime-accepts the server settlement itself: the cURL transaction committed `crystal_delta=200`, `vip_progression_delta=100`, and the expected first-buy state. No client reaction occurred because the cURL process had no client event-injection path.

## Token/session hardening

`local_token` is not a wildcard. It is the fixed compatibility token belonging to legacy account uid `13371337`, whose in-game player id is `12525385` in the established sandbox. The new account in the supplied smoke was uid `20000002`, region `197`, and logged in with its own token (`yKqj...`). The cURL explicitly supplied `local_token` / region 125, so the backend correctly bound the legacy account.

Pass89 makes this money-like footgun fail closed:

- `local_token` or the fixed legacy SID requires explicit `allow_legacy_sandbox=1` on `/preservation/v1/purchase-intents`.
- Optional `expected_player_id` must match the authenticated/bound player or the route returns `AUTH_PLAYER_MISMATCH`.
- The route logs `[COMMERCE AUTH] uid=<account> player=<player_id> region=<region> legacy=<0|1>` before mutation.
- Normal OTA purchases use the currently logged-in `xyd.Backend.get().token_` and `.region_`, not the compatibility token.

## Source-confirmed OTA activation

The backend already contained the source-confirmed MID2 update server (`gxb_backend.updates.local_update`, `/updates/<volume>`), but its Pass88 manifest was disabled. Pass89 activates it rather than inventing a new client patch protocol.

Target client resource version: `1.631.3`.

The OTA package is **cumulative**, not destructive:

- all 124 existing Pass88/1.631.2 local override files are preserved byte-for-byte;
- `src_32/app/common/utils.lua` is added;
- `src_64/app/common/utils.lua` is added;
- total update entries: 126;
- update volume: `gxb-local-1.631.3.zip.001`;
- volume MD5: `d883c1fabfd1ff46d6561be62d996787`;
- volume SHA-256: `317f2bd816ff42dd611dd24568d07f1c570fc70d52731aae3f95616d81dae6e0`;
- manifest is enabled and silent (`is_review=1` projection), so source `UpdateScene` downloads/restarts without asking the user.

Each new `utils.lua` override is the effective canonical Lua file byte-for-byte as a prefix, followed only by the preservation bridge. Unsupported native purchase paths therefore retain the original implementation.

## OTA purchase bridge

`tools/pass89_purchase_bridge.lua` is appended to both architecture variants of `app/common/utils.lua`.

The bridge intercepts only the seven server-supported direct Crystal products:

`80001002, 80001003, 80001004, 80001005, 80001006, 80001007, 80001030`.

Everything else calls the original `xyd.androidPurchase` / `xyd.sdkPurchase` unchanged.

For an intercepted direct pack it:

1. obtains `xyd.Backend.get():getWebAPIURL_()` and derives `/preservation/v1/purchase-intents` on the same backend host;
2. reads the live client token and region;
3. reads the current SelfPlayer `playerID` and supplies it as `expected_player_id`;
4. creates a persistent per-SKU intent id in `cc.UserDefault`;
5. POSTs the intent using source-existing `network.createHTTPRequest` / `addFormContents` APIs;
6. retains the same intent id after an indeterminate transport failure so the next tap replays the same permanent server receipt identity;
7. after HTTP 200 COMMITTED/REPLAYED, clears the pending id and injects the already-committed source-shaped MID36857 event into `xyd.event.RECHARGE`;
8. on explicit 4xx policy/auth rejection, clears the pending id so corrected input may start a new intent.

The bridge never computes Crystal, VIP, charge, first-buy status, or product price locally.

## Explicit scope boundary

Pass89 does not implement MID657, card entitlements, Skin Mall MID2981, ordinary Store, native receipt verification, historical TCP push framing, MID116, MID117, or MID118.
