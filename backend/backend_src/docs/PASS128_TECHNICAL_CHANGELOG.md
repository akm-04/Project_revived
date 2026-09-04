# Pass128.0 Technical Changelog — Super Campaign Progression Gates

## Source feedback loop
Effective `src_64` was rechecked before backend behavior changed. Function31 is server-issued Elite Campaign with source level condition `1|11`; its new-function handler immediately reloads world-map state. Super relation authority is direct `relate_campaign_id`, and a materialized Super node is still independently subject to `checkNomalCampaignThrough()`.

## Implementation
- Added `SuperCampaignCatalog`, validating 155 source Super rows, 155 unique Normal anchors, bidirectional relation metadata and the exact raw previous/next chain.
- Added `SuperCampaignAccessPolicy`, a pure non-mutating bouncer used by MID113 and MID117.
- Added `SuperCampaignProjectionService`, owning source-shaped first/next row materialization and Super cursor derivation.
- Added `EliteCampaignUnlockCoordinator`, ordering Function31 eligibility/projection/announcement and performing legacy player-load reconciliation.
- Level-11 transition now projects `100019` at star0/daily_limit3 and its cursor before staging `new_funcs_=31` in the same UoW.
- MID113 preserves Pass123 same-stage STAGED replay first; new Super stages are gated before attempts, Energy, RNG or session replacement.
- MID117 preserves Pass121 committed UUID receipt replay first; fresh UUID requests are gated before attempt/cost/RNG/receipt mutation.
- Super success exposes raw N+1 immediately. Related Normal clearance controls entry, not visibility.
- Terminal `2300024` remains terminal.
- Pass75 QA preseed remains intact and cannot bypass authorization.

## Compatibility
Prerequisite denial uses application `error_code=1` with an internal reason. `30005` remains limited to its source-proven fight-exists/result family. OTA/local_assets remains byte-identical to Pass123 at 1.631.8.

## Validation
Focused Pass128 suite: 12/12. Neighbor Campaign/reset suites Pass121, Pass122, Pass123, Pass94, Pass92, Pass81, Pass79 and Pass75 pass. Python compileall passes. Client smoke remains the next pass.
