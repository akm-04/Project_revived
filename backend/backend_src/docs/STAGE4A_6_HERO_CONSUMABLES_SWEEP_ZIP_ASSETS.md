# Stage 4A.6 — Hero Consumables / Sweep / ZIP Asset Recovery

Implementation evidence summary:

- MID90 live-confirmed request uses item `50001538`; authoritative item table
  gives subtype 19 and `skill_point=10`.
- Common `economy_` response dispatch is source-confirmed in `Backend.lua` and
  `SelfPlayer:economySyncEvent_()` consumes `skill_point`.
- MID55 `AddExpWindow`/`UseExpWindow` consumes `item_id`, `partner_exp`, and
  `total_num`.
- MID63 client computes selected item EXP locally and consumes no response
  fields.
- Hero EXP thresholds derive from `partner_exp.lua`; player hero-level caps
  derive from `player.lua`.
- Campaign Sweep item shape is source-confirmed as nested `items` lists of
  `item_id/item_num`; explicit sweep rewards derive from `campaign.lua`.
- ZIP/APK support indexes central-directory names only and verifies bytes lazily
  on exact lookup.

No lower-rate Campaign RNG, Sweep economy gains, dummy MD5 bypass, or payment
behavior is introduced.
