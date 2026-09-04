# Pass152 effective src_64 feedback loop

Before Phase C behavioral edits, effective `src_64` from the uploaded verified asset archive was rechecked. The immutable source archive remains SHA256 `89f0f830508b92e5fff6ad53c6a9dae961a14042dbfdf5649008efb8353f5608` with 4,370 effective files.

## SOURCE_FACT

- `SelfPlayer:queryChargeData()` stores server `giftbags` in `vipGiftBoxData`; Recharge UI renders server-advertised rows using local `giftbag.lua` metadata.
- `GiftViewWindow:purchaseGiftBag()` enters the native `xyd.androidPurchase` / `xyd.sdkPurchase` boundary.
- `xyd.version()` reads the installed writable resource version from `USER_DEFAULTS_VERSION_KEY`, providing an exact OTA version for the preservation bridge.
- `SelfPlayer:onRecharge_()` first handles `items`; when `skin_ids` exists it resolves the skin's Hero, applies the returned ownership vector, then removes `remove_item or 1` from the client backpack. This supports a source-shaped transient item callback for direct permanent ownership.
- `giftbag.lua` and `gift.lua` are the local metadata tables used by Recharge/GiftView; existing cumulative OTA 1.631.8 already overrides both architectures and therefore Phase C must patch the cumulative copies rather than raw source.

## IMPLEMENTATION / COMPATIBILITY DECISION

- Synthetic EOL products are visible/authorizable only for resource version >=1.631.9.
- The OTA bridge intercepts the seven direct products or any charge ID currently advertised in `vipGiftBoxData`; non-advertised purchase paths retain native fallback.
- Synthetic skin acquisition uses `SkinOwnershipService` directly if the matching Girl exists; otherwise canonical RewardTransaction/StackInventory grants the source skin item.
- Ten elemental products grant one source package item and remain repeatable.
- Synthetic products grant zero Crystal, charge and VIP progression.
- Resource version is not included in receipt fingerprint, preserving historical receipt replay compatibility.

## UNKNOWN / intentionally gated

Temporary skin acquisition/expiry/conversion remains unresolved. Three direct-Hero Recharge Packs remain Generated/Unique-gated and fifteen missing-gift Packs remain fail-closed.
