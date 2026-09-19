# Pass486 R6 Pre-Implementation Research Closure

Status: GREEN_CANDIDATE_BOUND
Baseline: Pass484 v0.55.3, backend ZIP SHA256 cc2c0feabeb77b15d3c076043a25f758cd70d45c28a57b8dea92556c21a90538
R5 phase seal: Pass485
R6 lifecycle after this checkpoint: IMPLEMENTATION / NOT_STARTED_AUTHORIZED

## Frozen evidence-bound repairs

- RF-017: project canonical `player_item_stacks` into stock Backpack using `item_id -> table_id`, `quantity -> item_num`, and `acquired_at -> time`. Current `src_64/app/model/Backpack.lua` preserves the first stack timestamp when later quantity is merged; therefore `updated_at` is not the stock item time. Use one projector for embedded MID1/81 and standalone MID81. `spirit_list` remains fail-closed empty.
- RF-018: R5 already owns Skill Point through the temporal/privilege path; that part is SUPERSEDED as an R6 defect. R6 only projects source-proven scalar names `magic_exp`, `degree_cer`, `graduate_cer`, `patent_cer` from existing canonical scalar balances, absent -> numeric 0. No new earning/spending/cap/ID mechanics.
- RF-024: selectively reconcile only canonical name, level, avatar, avatar-frame into I4 directory projection. Preserve VIP/conquest/unowned facts. Reconciliation reads canonical owners and writes I4 in one SERIALIZABLE transaction to prevent stale-snapshot overwrite; PostgreSQL SSI overlap remains an R7 native proof obligation. Do not activate MID23/name/avatar gameplay routes.
- Canonical lobby metadata: project selected `LogicalServer.Name` as MID1 `region_name` instead of synthetic `Server <id>`.
- D11: enumerate every enabled mutating family and its semantic replay identity. No enabled repeatable consumptive stock family currently requires an invented client nonce. SaveStory retains its bounded parameter-derived identity ambiguity. New transport-write evidence is `TRANSPORT_WRITE_RECORDED`; socket write is not client consumption.
- D12 bounded R6 foundation: terminal server retirement, version-aware bearer key resolution, explicit single realtime owner enforcement, encode-before-header HTTP response serialization, and bounded real transaction evidence sink. Full operator rotation procedures, multi-replica serving/fencing, and broad I11 telemetry remain deferred.
- Migration posture: no migration00012 unless implementation discovers a genuinely missing durable fact and research is reopened for that fact.

## Source identity used

Current authoritative source archive SHA256: c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf
Current `src_64/app/model/Backpack.lua` SHA256: 953999f81fc43ecd00e587d884c88b6a1ba066e35ff75a20dd698b6cb950af7a
Current `src_64/app/model/SelfPlayer.lua` SHA256: 163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4

Frozen V1 and old-client evidence remain corroborative/differential only.
