# Pass275 / U4B Wave C — Server Hydration + Deferred Adapters + MessagePush Preference Correction

Wave C implements the server-side hydration/status compatibility plane without introducing persistent UI state or weakening deferred gameplay fences.

Implemented:
- registry-driven `HydrationSnapshotAssembler` preserving the accepted exact 22-MID Stage3 set, including MID176 only as the previously accepted bootstrap compatibility extra;
- `HydrationShapeValidator` for MIDs 124/530/816/822/1152;
- exact-MID `DeferredUiStatusAdapterService` with no wildcard fallback;
- MID124 Practice canonical overlay with non-persisted compatibility defaults and a numeric `last_time`;
- source-shaped inactive read-only contracts for Treasure 530, Pet Campaign 816/822, and Guild War 1152;
- startup `DeferredStatusMutationFenceValidator` proving adjacent gameplay mutation families remain explicitly blocked/deferred;
- explicit Hero Practice 125-128 mutation contracts so the fence is audited rather than inferred from handler failure;
- canonical `MessagePushPreferenceService` for 1025/1026 using sorted unique current-source numeric IDs 1..12;
- backward load normalization from old dict-shaped `message_pushes` into the current-source list representation;
- live dispatcher routes for the five deferred status MIDs and MessagePush preference mutations.

Current-source reconciliation:
- `SelfPlayer.checkPracticeRedMark` performs arithmetic on `last_time`, requiring a numeric value;
- MID816 consumes nested `normal`, while MID822 consumes a distinct flat numeric shape;
- Treasure safely accepts empty `teams_info` plus zeroed `sp_info`;
- Guild War accepts inactive `is_enroll=0` while omitted unrecovered `step_id` remains nil and guarded;
- `MessagePush:update` iterates `player_info.message_pushes` with `ipairs`, confirming a list of enabled numeric IDs rather than the old backend dict.

Safety:
- no adapter persists fabricated gameplay state;
- adapter enablement never admits adjacent gameplay mutation routes;
- all five deferred adapter MIDs remain outside Stage3 despite their source-safe inactive shapes;
- MessagePush is treated as a durable preference domain, not a deferred gameplay adapter and not TCP business state.

Not implemented: Wave D/E realtime; full Treasure/Guild War/Pet Campaign/Hero Practice gameplay; client patches.
