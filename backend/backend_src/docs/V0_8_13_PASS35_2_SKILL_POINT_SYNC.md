# v0.8.13 / Pass 35.2 — Explicit MID90 Skill Point Sync

## Scope

Pass35.2 implements the targeted MID90 fix identified by Pass33.2/Pass34/Pass35. It does not widen Campaign, Story Mission, Summon, Hero EXP, Activity, PvP or Guild semantics.

## Source contract

For successful ordinary web responses the recovered client order is:

`extraWebResponseCheck_(response) -> MID event dispatch (if mapped) -> LoadingProxy.removeLoading() -> inline callback`.

`extraWebResponseCheck_()` dispatches `response.economy_` through the global Economy event. `SelfPlayer.economySyncEvent_()` assigns `skillPoint` when `economy_.skill_point` exists. MID90's `SelfPlayer.useSkillPointItem()` callback consumes no direct Skill Point response field; it only removes the submitted Backpack item and forwards callback success.

## Backend change

- Added request-scoped `GlobalResponseSemantics`. It has no gameplay ownership and performs no state-diff inference.
- MID90 item use runs under the shared one-player UnitOfWork when called through RequestServices.
- After successful canonical consume/gain/timer normalization, MID90 stages cumulative `economy_.skill_point`.
- `RequestServices.apply_semantic_deltas()` merges explicitly committed `economy_` semantics before the generic cumulative projector runs.
- The old direct MID90 `skill_point` field is removed.
- `ResponseProjector.ECONOMY_FIELDS` remains unchanged; Skill Points are not globally auto-projected.

## Timer behavior

Pass30.1 SkillPointPolicy is unchanged. Item grants may exceed the natural regeneration cap. At/above the natural cap canonical `skill_time` is normalized to zero; below cap an absent timer starts. The Lua client's next `getSkillPoint()`/`recoverByTime()` also normalizes its local timer when the cumulative point total reaches/exceeds the natural cap.

## Validation boundary

Static/syntax/AST/JSON/hash/archive validation only. Runtime authority belongs to the next user Clear-App-Data natural tutorial test.
