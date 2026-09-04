# Pass113.0 Technical Changelog — Campaign MID117 RNG Phase C1 Inert Foundation

## Scope

Pass113 implements only the inert Campaign repeat-RNG foundation authorized from Pass112. Live `WorldRepository.sweep()` settlement, MID117 operation receipts, and the client OTA bridge remain disabled.

## New Campaign repeat policy surface

A new dedicated data file `data/campaign_repeat_rng_policy.json` carries `campaign_repeat_rate_decomposition_v1` as explicit `private_server_compatibility_source_bounded_not_recovered_official_server_code` policy. The legacy `data/campaign_drop_policy.json` is byte-identical to Pass111 so MID113 battle staging remains unchanged.

`CampaignDropPlanner` now exposes a separate `plan_repeat_sweep()` entry point. It is intentionally not the existing `plan(first_clear=False)` path used by MID113. For each preserved source row it performs `guaranteed,residual = divmod(increase_rate,10000)`, grants the guaranteed quantity, consumes exactly one `campaign.repeat.residual` draw only when residual is nonzero, and grants one additional unit iff `draw < residual`.

`repeat_dropbox_id == 0` produces a valid empty random plan. A positive pool id with no recovered rows raises `CampaignRepeatPoolUnavailableError` before entropy. Negative rate/source corruption fails before entropy. Materialized occurrences aggregate duplicate item IDs in first-source-occurrence order.

## RandomOutcomeService integration

`CampaignRandomOutcomeAdapter` binds Campaign mechanics to the request-scoped Pass110 `RandomOutcomeService` namespace `campaign.repeat.residual`. `RequestServices` composes both the dedicated repeat policy registry and adapter. The live MID117 repository does not call `plan_repeat_sweep()` in Pass113.

## MID117 identity and replay helpers

New `gxb_backend/state/mid117_operation_receipt.py` implements inert helpers only:

- validates `campaign_sweep_op_id = mid117-<UUIDv4>` when present;
- normalizes the frozen semantic tuple `(117,campaign_id,campaign_type,sweep_num,sweep_type,awake_mission-or-0)`;
- produces canonical SHA-256 fingerprints while excluding UI compose hints;
- serializes exact static `items` array-of-arrays, `economys`, `additional`, and optional `chapter_event`;
- records live projection descriptors for cumulative `economy_`, `campaign`, `trial`, and `challenge`;
- records repeat-policy/source-catalog audit metadata;
- validates replay payload shape without performing any UoW receipt lookup or mutation.

## Explicit inert boundary

The following remain byte-identical to Pass111:

- `gxb_backend/state/world_repository.py`;
- legacy `data/campaign_drop_policy.json`;
- cumulative OTA manifest/version 1.631.5;
- Summon probability/pool/pity policy files.

No `SweepWindow.lua` OTA override exists in the backend. No live request contains or requires `campaign_sweep_op_id` yet. Pass114 remains responsible for OTA 1.631.6 and atomic UoW activation.
