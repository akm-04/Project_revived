# Pass224.0 — Pass212 Control Reset + Minimal Awakening Reconciliation

## Status
IMPLEMENTED / STATIC GATE PASS / CLEAN CLIENT RUNTIME SMOKE PENDING.

## Control decision
Pass212 is the client/runtime control baseline. The post-Pass212 experimental surface (historical CSBs, window/preload remaps, Incubus Blood adapter, TaskAwake art substitution, Backend loading suppression, LazyDownloader behavior changes) is rejected for the next runtime gate.

The cumulative OTA is rebuilt from Pass212 sparse overrides plus exactly two paired effective-current source overrides:

1. `app/windows/TaskAwakeCell.lua` — ordinary terminal Hero Awakening only: retain the exact current local Hero table-ID/skill mutation, but replace `awake_hero_wnd` with stock current `common_alert`. This presentation has already reached `awake_terminal_after_open_result` in runtime smoke and is accepted.
2. `app/model/NormalHero.lua` — Blood MID54 client cache/display reconciliation only. Durable server lifecycle remains source-exact: MID54 completes stage1 but keeps `twice_awake_stage=1`; MID161 advances stage2.

## Runtime evidence from the user smoke
- Blood open MID2738 for mission 2200001 succeeds and grants/projects Blood equipment.
- MID54 for partner 10073 slot1 succeeds twice, while the client redraw still shows unequipped.
- MID161 for mission 2200001 succeeds and returns `twice_awake_stage_`.
- Pass223's Incubus-derived Blood selector loads successfully, proving the weird 4-Hero UI is our substitution rather than a native crash.
- No MID866/MID867 occurs in the contaminated Pass223 Blood selector run.

## Blood MID54 bug — source explanation
Current `NormalHero.getEquipByIndexShow()` replaces the ordinary awaken slot with a freshly-created Blood item whenever Blood is active, but the fresh replacement did not inherit `equips_[slot]` collected state. Current `equipItems()` then marks/removes `getEquipByIndex(slot)` — the canonical ordinary Awakening item — even though the server consumed the displayed Blood substitute.

Pass207 already documented this as the stock Blood MID54 client cache/backpack anomaly. Pass224 fixes only that local projection:
- the Blood display substitute inherits collected state from the canonical slot;
- MID54 captures the displayed item ID before the request and removes that displayed item from local Backpack after success;
- no client code advances `awakeTwiceStage_` during MID54.

## Blood UI/assets — corrected authority
Current `AwakeTwiceSelectTeamWindow.lua` is authoritative. It defines a 16-member team cap and exact MID866/BattleUnlimit semantics. Pass212 has no Blood window/resource override and the user confirms its Blood battle UI worked.

The latest lazy recovery corpus has no `res/web/windows/awake_twice/...` payload, while the old v1.164 manifest contains 22 physical `res/windows/awake_twice/...` files. Pass212 runtime success therefore establishes that the working current-generation Blood layout is supplied by the stock APK physical resource set, outside the lazy corpus. Historical 2.0.8 donor files must not shadow it.

Pass224 therefore ships:
- no Blood window override;
- no `window.lua` or `preload_window.lua` override;
- no historical `res` payload;
- no EOL Blood adapter;
- no TaskAwake art fallback.

## Clean-state requirement
Sparse OTA updates do not delete files installed by previous OTAs. Pass219–223 may have left writable `src`/`res` files which shadow stock APK files even when Pass224 omits them. A clean app-data reset is therefore REQUIRED before the Pass224 runtime smoke. The backend/server player state is unaffected because it is server-side.

Recommended device command before the test:

`adb shell pm clear com.carolgames.gxb`

Then launch the already-prepared APK and allow MID2 to install OTA 1.631.19.

## Blood post-battle gate
The user's Pass212 control reports that the battle UI/fight worked, but the Blood stage sometimes did not complete after battle. Do not change Stage-E MID867 yet. The clean Pass224 stock Blood UI must first capture uncontaminated MID866/MID867 requests. Existing server authority requires successful terminal `num=20`, `npc_ids=[]`, and a matching generation-bound MID866 session. Runtime request evidence will decide whether reconciliation is needed.

## Static validation
- Pass224 dedicated control-reset selftest: PASS.
- P2 Stage C: PASS.
- P2 Stage D: PASS.
- P2 Stage E: PASS (81 Blood rituals, terminal num=20 / npc_ids=[]).
- P2 Stage F: PASS.
- P2 Stage G: PASS.
- Architecture hygiene: PASS.
- `gxb_backend`: 201/201 files same as Pass212 except metadata-only `version.py`.
- OTA 1.631.19: 146 Lua members; zero `res/` members.
