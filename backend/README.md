# GXB backend v0.10.2 — Pass89.0

Pass89.0 activates the already source-confirmed MID2/UpdateScene OTA pipeline and activates the cumulative `1.631.3` OTA package (preserving the previously validated 1.631.2 overrides) and adds an `app/common/utils.lua` override that transparently redirects only the seven direct Crystal Recharge SKUs to the Pass88 exactly-once PurchaseIntent bridge. It also hardens the money-like preservation endpoint so the fixed legacy `local_token` cannot silently mutate the legacy account (uid 13371337 / player 12525385) without explicit opt-in.

The OTA package is enabled by default at resource version `1.631.3` and is served from `/updates/` using the existing MD5-verified update transport. No MID657, cards, Skin Mall, ordinary Store, or MID116/117/118 are implemented.
