# v0.17.1 / Pass168 — Horcrux H3 generated reward bridge

Pass168 activates only the source-authorized MID241 generated-Horcrux lane. Ordinary deterministic/random MID241 behavior remains on the existing Gift domain, source package debit still settles in one PlayerUnitOfWork, and Gift/dropbox template selection remains `gift.open` policy. Horcrux generation begins only after a type-24 template intent is selected.

`RewardTransactionService` gains a narrow registered specialized-owner seam. It owns validation routing and outer-UoW atomicity only. `HorcruxGeneratedRewardOwner` owns the SPIRIT route, `HorcruxMaterializer` owns source/policy materialization, and `HorcruxRepository` owns persistent `spirit_id` identity/storage. Type-24 items are now explicitly rejected as ordinary `InventoryGrant`s.

The materializer follows `horcrux_policy_v1`: main candidate selection, positional secondary-count weights, distinct source secondary selectors, exact source base values, and no entropy for forced/single choices. Fresh wire rows include `spirit_id`, `table_id`, `star`, `lev`, `exp`, main/sub selector + materialized attribute/value fields, `is_equip=0`, `is_lock=0`, and `collo_count=0`.

Dropbox 9199043 keeps its malformed recovered rows immutable; only the accepted 12-template 84x4/83x8 compatibility overlay is selectable at runtime. MID241 may cross the 2,000 owned-Horcrux count because that number is a soft Gods Trial entry cap, not a destructive inventory ceiling.

HOTA-001 changes only the SelectEquipWindow reward-forwarding call so `spirit_awards` reaches `SelfPlayer.handleRewards`, matching GiftbagUseWindow. The src_32/src_64 patches are byte-identical. OTA 1.631.12 preserves all 140 Pass167 entries byte-for-byte and adds only those two SelectEquipWindow files, for 142 entries total.

H4 strengthening and H5 Gods Trial gameplay remain disabled.
