# GXB backend v0.8.14 — Pass 35.3 MID90 Duplicate Guard

Pass35.3 is a narrow runtime hotfix on top of Pass35.2. The Pass35.2 explicit `economy_.skill_point` synchronization is runtime-confirmed by the first successful MID90 use. This revision does **not** change Skill Point cap/timer semantics or the amount granted by item `50001538`.

The clean Pass35.2 device trace proved Campaign100004 granted exactly one `50001538`, but the client submitted two MID90 requests back-to-back. The first request consumed the canonical item and projected Skill Points 0 -> 10. The second request found no canonical item; v0.8.13 returned an empty dict which the dispatcher wrapped as `error_code=0`, so the client treated the duplicate as success and locally removed another item.

Pass35.3 changes only that validation boundary: invalid/insufficient MID90 requests return the source-defined generic `xyd.error.ERROR = 1`. The client removes Backpack items only on `xyd.error.OK`, so duplicate/insufficient requests no longer receive fabricated success.

Stacking remains supported. `BuyTiLiWindow.lua` can batch multiple items into one MID90 request through `item_num`, and the backend adds `10 * item_num` without clamping to the natural regeneration cap. The natural VIP cap remains a regeneration cap, not an absolute stored-point cap; 20/10, 30/10, etc. remain valid when the canonical Backpack actually owns the corresponding items.

All Pass35.1 update/operator hardening, Pass33.1 tutorial authority, Campaign/Mission/Summon/MID39 behavior, ProtocolRegistry and the Pass29 compatibility boundary remain unchanged.
