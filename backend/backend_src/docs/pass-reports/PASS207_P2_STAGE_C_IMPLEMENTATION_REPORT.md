# Pass207 — P2 Stage C Implementation Report

## Scope
Stage C only, on top of sealed Pass206 Stage B. Stages A/B remain authoritative. Stage D is not started. Broader P2 public release remains closed.

## Implemented
- `HeroEquipmentRepository` now exposes canonical equipment-operation planning used by both ordinary MID54 and Awakening-special coordination; no second equipment authority was introduced.
- New `AwakeningEquipmentCoordinator` intercepts MID54 only when an active stage-one Awakening/Blood mission authorizes the source-defined exclusive gear for the target Hero/slot.
- Ordinary stage-one MID54 atomically debits the exclusive gear, marks the canonical Hero equipment slot collected, and marks the active ordinary stage-one task complete.
- Blood stage-one MID54 atomically debits the mission-authorized Blood gear, preserves the existing ordinary-Awakening lineage slot, and marks the Blood stage-one task complete while keeping durable `twice_awake_stage=1`.
- Stage-one MID161 now performs the task transition: completed stage one is removed/replaced with its source successor stage two and a generation-aware success replay is retained.
- Blood stage-one MID161 additionally persists `twice_awake_stage=2` and returns exact `twice_awake_stage_={table_id,stage}` projection. MID54 no longer attempts to force stage2.
- MID51/MID57 promotion now source-correctly preserves Awake/Blood special equipment slots and their Fumo/Fumo levels while resetting ordinary equipment/Fumo. The obsolete Awakening-special promotion fence is retired for this implemented path.
- The stable `HeroHandlers._promotion_transport` adapter remains present for backward handler compatibility, although the normal Stage-C path no longer emits the retired Awakening-special rejection marker.

## Source anomalies / runtime risk preserved
- Reo Blood mission `2166001` -> gear `21001080` is the sole recovered Blood stage-one gear lacking the generic `is_bloodline_item` flag. Mission `awake_type`/route authorization is authoritative; noisy item flags are not used to reject the route.
- Stock Blood MID54 has a client cache/backpack anomaly: stage1 display substitutes Blood gear, but the callback can still resolve/remove the canonical ordinary Awakening gear before `EquipConfirmWindow` clears the cached equipment list. No recovered generic negative inventory projection exists. Server durable authority consumes the Blood gear; immediate client-cache behavior remains an explicit smoke-test/reconciliation risk rather than an invented packet.

## Source reality
Effective `src_64` remains exactly 4,370 files. Nine Stage-C-critical files are hash-locked. Source confirms selective MID51/MID57 special-slot preservation, Blood display/canonical stage boundaries, MID54 callback/cache ordering, MID161 stage-one claim path, and the `twice_awake_stage_` consumer. Full route census confirms 164/164 ordinary exclusive routes use slot1 and 81/81 Blood lineages use slot1; Reo is the sole unflagged Blood-gear anomaly.

## Validation / regressions
- Dedicated Pass207 Stage-C selftest: PASS (ordinary/Blood MID54 completion + replay, stage-one MID161 successor + replay, Blood stage2 projection, promotion preservation, normal MID54 regression, Reo anomaly).
- Pass206 Stage-B selftest remains PASS.
- Pass187-190 remain green; Pass192 remains 6/6; Pass193 remains 3/3.
- Pass179 historical P0 suite has one intentionally superseded assertion requiring Awakening-stage promotion to HTTP409. All other Pass179 tests pass individually. The replacement Stage-C test proves the newly authorized source-correct selective-preservation behavior. Historical Pass179 is preserved unchanged as provenance.
- Shipped `data/player_db.json` is byte-identical to sealed Pass206.

## Release posture / next
P2 is still not publicly released. Stage D is next after Pass207 artifact+memory sealing: Campaign Awakening/Blood acquisition overlay and ordinary final-trial completion, using the existing Campaign session/receipt authorities. The Blood MID54 client-cache anomaly is a required later stock-client smoke/reconciliation case.
