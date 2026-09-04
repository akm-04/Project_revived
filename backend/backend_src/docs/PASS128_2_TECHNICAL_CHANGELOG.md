# Pass128.2 Technical Changelog — MID112 New-Account Wire Hotfix

## Runtime rejection carried forward
Pass128.0 was runtime-rejected because an explicit MID112 on Function31-closed/new accounts omitted `super_chapter_id`, `super_campaign_id`, and `super_stars`. Stock `SelfPlayer.worldMapEvent_()` directly overwrote those client fields with nil, and `MapWindow` then evaluated `maxSuperChapter > 0`, causing a hardlock.

## Source feedback loop
Effective `src_64` was rechecked before the backend change. `SelfPlayer.lua` assigns all four Super chapter fields directly from `chapter_info`; `MapWindow.lua` has no nil guard around the Super chapter comparison. Numeric zero is therefore a mandatory wire value for a closed Elite Campaign.

## Bounded implementation
`SuperCampaignProjectionService.recompute_cursors()` now distinguishes field absence from numeric zero. A cursor is written when the key is missing or when its numeric value differs from the desired canonical value. Cursor ownership remains exclusively in the projection service; `WorldRepository` is not made a second authority. The existing normalization/payload persistence path saves the repair once and subsequent canonical MID112 loads do not ghost-save.

## Validation
New Pass128.2 MID112 wire-contract tests pass 4/4. The original Pass128 progression suite remains 12/12, and Pass121/122/123/94/92/81/79/75 neighbors pass. Python compilation passes. OTA/local-assets is unchanged at 1.631.8.

## Runtime gate
This release requires a real fresh-account client smoke before Pass128 is runtime-accepted again. Pass129, Campaign EXP/Mana and RNG work remain halted until that smoke succeeds.
