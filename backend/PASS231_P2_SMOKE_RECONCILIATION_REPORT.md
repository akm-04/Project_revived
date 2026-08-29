# Pass231 — P2 Smoke Reconciliation

## Classification
BOUNDED IMPLEMENTATION / RUNTIME TEST ENABLEMENT. P2 acceptance is not yet claimed.

## Backend authority
This pass is rebuilt from the user-supplied sealed Pass227 executable (`gxb-backend-v0.35.0-pass227.0.zip`, SHA-256 `0f2a69aa5139613fa909329414f8bc35534016a5a070d77dc346dbba1d6443ac`). Pass228 server/client presentation work is not used as an implementation base.

The only server-state behavior imported after Pass227 is the already-reviewed Pass230 sandbox one-shot cleanup for UID 13371337: `gxb_backend/state/multiuser_database.py` plus `data/debug_guest_p2_smoke_cleanup_pass230.json`. The Pass227→Pass230 diff was verified to contain no other runtime code delta.

## Runtime evidence reviewed
- `event-debug.zip`: KM-Moe ordinary and Blood lifecycle completed. Core requests include MID2738, MID83, MID54, MID161, MID113→114, MID866, stock MID867 `npc_ids={}`, and terminal MID161. No nonzero engine error responses were observed. User reports the Blood stage-one "awakening skill" popup as incorrect.
- `odin-event-debug.zip`: Odin ordinary and Blood lifecycle completed through stock MID867 `npc_ids={}` and terminal MID161 stage 3. No nonzero engine error responses were observed.
- `occult-debug.zip`: Karaxes route activation reached MID2362 GET_INFO successfully, but no MID2385 sweep occurred. Stock/stub UI stopped at Sorcery War Scroll requirement. Occult runtime acceptance remains fenced/deferred rather than being emulated in this pass.
- Missing `/res/` requests in these bundles are non-blocking presentation/resource gaps observed alongside otherwise successful tested flows; they are not used to reopen accepted server mechanics.

## Blood popup diagnosis and correction
The debug bundles identify the client resource version as `1.631.21`, while Pass227/Pass230 target `1.631.20`. The local updater records `version_current_or_newer`, so rolling the backend back cannot downgrade the already-installed rejected Pass228 Lua.

Pass229 provenance proves Pass228 added a `common_alert` directly inside generic `TaskAwakeCell.finishHeroTwiceAwake()`. That callback runs after both Blood stage-one and terminal MID161, hence the rejected duplicate/incorrect popup.

Pass231 therefore advances the resource version to `1.631.22` and republishes the complete accepted Pass227 local override tree. `src_32/app/windows/TaskAwakeCell.lua` and `src_64/app/windows/TaskAwakeCell.lua` are byte-identical to Pass227 and contain no `common_alert` inside `finishHeroTwiceAwake()`. This is a forward corrective rollback; no Pass228 popup code is retained.

## Occult disposition
Do not block the remaining P2 smoke on Occult. The current stock/stub Occult surface loads and MID2362 is healthy, but the client cannot presently perform the required MID2385 raid without Sorcery War Scroll progression and the wider Occult page remains intentionally fenced. Full Occult development is deferred.

## Next runtime gate
After installing Pass231 and allowing OTA 1.631.22 to apply, continue:
1. Aquaris ordinary Campaign Awakening, including manual fragment acquisition and sweep where available.
2. Aquaris Blood Campaign Awakening where eligible.
3. Nikita ordinary/Blood paths as applicable, with emphasis on the anomalous Give-Up delete list.
4. Representative ordinary and Blood Give-Up/reopen checks and remaining practical edge cases.
5. Confirm the erroneous Blood popup no longer appears.

Return the new debug bundle before P2 fence closure.
