# Pass210 — P2 Stage E Implementation Report

## Scope
Stage E only, forked from sealed Pass209 v0.23.0. Stages A-D remain authoritative and broader P2 release remains fenced. Stage F is not started.

## Implemented
- Blood ritual MID866 now creates a generation-bound canonical trial session for the active Blood stage-two mission. The request contract remains source-exact `{twice_awake_mission, incubus_id}`; no roster field or server-invented roster validation was added.
- Blood ritual MID867 now accepts only the recovered successful terminal envelope `num=20, npc_ids=[]`, requires the matching generation-bound MID866 session, completes the canonical Blood mission, and retains replay through `AwakeningStateV2` transition receipts.
- Blood terminal MID161 now atomically persists `twice_awake_stage=3`, clears the canonical active Blood mission, emits exact `twice_awake_stage_`, and supports bounded terminal replay.
- Ordinary terminal MID161 now atomically transforms the durable Hero `table_id` using the source `awaken_table_id`, clears the canonical active mission, and retains bounded terminal replay. It deliberately does not project a premature Hero table mutation because the stock callback resolves the pre-transform Hero identity before locally switching its table ID.
- KongMing ordinary terminal Awakening implements the frozen EOL compatibility policy: grant exactly one of each missing persistent Book-V ownership token (50000005/10/15/20/25) in the same terminal UoW. Existing tokens are not duplicated and only newly granted tokens are exposed via `extra_drops_`.
- MID2144 `CHANGE_PARTNER_SKILL` is now wired through a dedicated `KongMingAwakeSkillService` reusing canonical Hero/Inventory/UoW/settlement owners. It requires awakened KongMing, slot 5, a supported owned Book-V token, persists the raw skill ID, and never consumes the Book-V token.
- `LOAD_MISSION` now overlays Awakening task channels from `AwakeningMissionService`, preventing stale generic mission shadow state from resurfacing on relog. MID2561/TASK_LOAD_BY_TYPE remains the authoritative full-replacement Awake task hydration path.
- `HeroEntityMutationService` adds the generic typed `SET_SKILL_ID_AT_INDEX` mutation primitive; no parallel Hero persistence authority was introduced.

## Source reality and correction
Effective `src_64` remains exactly 4,370 files. Pass210 locks 15 Stage-E-critical source files. Source confirms 81 Blood ritual configs, 1,620 ritual wave rows (20 each), the MID866 two-field request with no roster, and successful MID867 terminal shape `num=20,npc_ids=[]`.

KongMing has five source-valid raw battle/book mappings and five persistent Book-V ownership tokens. However the effective stock `partner1.lua` slot-5 picker currently exposes only three choices (Wind/Dark/Water: 60010144/60020144/60030144). Fire/Thunder (60040144/60050144) remain source-valid battle/book mappings and possible persisted values, but are not presently exposed by that picker. The approved five-book EOL ownership grant is therefore retained without mislabeling the stock UI as five-choice.

## Evidence boundaries
- SOURCE_FACT: MID866/MID867 wire shape, 81 rituals, 20 waves, terminal `num=20,npc_ids=[]`, KongMing slot index and recovered skill/book mappings, client callback/bootstrap ordering.
- COMPATIBILITY_POLICY: grant all missing KongMing Book-V ownership tokens at successful ordinary terminal Awakening because the recovered historical ZhugeFestival acquisition path is dead in EOL operation.
- IMPLEMENTATION: generation-bound ritual session/replay, terminal Hero/Blood mutation, MID2144 persistence, and bootstrap canonical overlay using existing owners.
- PROTOCOL_LIMIT: MID161 remains nonce-less; bounded mission/generation replay cannot manufacture universal exactly-once identity for arbitrary wire-identical future requests.

## Validation
Dedicated Pass210 selftest passes all seven characterizations: Blood trial terminal/replay/claim, KongMing terminal books and MID2144, ordinary non-KongMing terminal/replay, stale Blood generation rejection, pre-Awakening MID2144 fence, bootstrap/relog authority, and exhaustive 81 Blood stage-two ritual binding.

Controlling regressions remain green: Pass206 Stage B, Pass207 Stage C, Pass209 Stage D (11/11), Pass205-209 source verifiers, Pass129 architecture hygiene, Pass122 Challenge, and Pass131 Campaign EXP/Mana. Historical Pass74/Pass186 assertions previously identified as superseded remain baseline issues rather than Stage-E regressions.

Shipped `data/player_db.json` is byte-identical to sealed Pass209.

## Release posture / next
Stage E is complete in this backend but broader P2 release remains fenced. Stage F is next only after Pass210 backend and HOT/COLD memory-bank sealing: minimal Occult/Sorcery War dependency using the frozen Pass204 compatibility policy and existing `DerivedMutationRuleRegistry`/Inventory/UoW authority. Full manual/co-op Occult remains deferred.
