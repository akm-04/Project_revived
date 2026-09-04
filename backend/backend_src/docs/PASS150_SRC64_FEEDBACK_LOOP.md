# Pass150 fresh src_64 feedback loop

Before B3/B4 behavioral work, `all-assest-rechecked.zip` was freshly extracted and verified at SHA256 `89f0f830508b92e5fff6ad53c6a9dae961a14042dbfdf5649008efb8353f5608`. Effective `app-assets/output/assets/src_64` contains exactly 4370 files.

B3 source facts rechecked:
- Recharge page-2 `charge_id=90002112` -> `gift_id=90011123`.
- Gift fixed rewards: item `50001014 x5`, item `50001013 x10`, Crystal 60, Mana 20000, ordered drops `[600002]`.
- Dropbox 600002 contains exactly five source rows, all item `50001043`, quantities `1,2,4,9,17`, relative integer weights `7547,1886,377,125,62`, roll_type=1, total weight 9997.
- `GiftViewWindow.lua` explicitly special-cases charge 90002112 and renders RANDOM_RED_PACKETS / item 50001043 x?.

B3 compatibility decision:
- Preserve source candidate order and use positive `drop_rate` values as relative integer weights; ROS only performs the mechanical weighted draw under namespace `recharge.giftbag`.
- Exactly one ordered drop occurrence means exactly one gameplay entropy draw for this source product.

B4 source/compatibility boundary:
- 262 canonical permanent Girl skins remain source-validated against the Phase-A skin catalog reconstructed from effective src_64.
- 10 accepted EOL elemental package items are source-valid MID241 packages: 2 deterministic select and 8 ordinary random package items.
- Synthetic charge/gift IDs and zero-cost permanent EOL distribution are IMPLEMENTATION_COMPATIBILITY_DECISION, not recovered original store behavior.
- Synthetic products remain unadvertised/unauthorized until OTA 1.631.9 supplies matching client rows.
