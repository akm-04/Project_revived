# Pass517 CA2-2 independent post-implementation reality check

## Adjudication

**GREEN for the CA2-2 internal local checkpoint only.** Aggregate CA2 remains OPEN. CA2-3 remains NOT STARTED. Exact pinned-toolchain / real PostgreSQL / River / stock-client evidence is not claimed by this local checkpoint.

## Authority reread

The reality check reread the sealed Pass516 CA2-2 research closure and implementation plan, the Pass513 CA2 staged/implementation/native-gate contracts, the exact Pass515 implementation parent, and exact current `src_64` from the authority archive SHA-256 `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`.

## SOURCE_FACT findings reconfirmed

- Stock Hero progression MIDs are 52 `EVOLVE_HERO`, 55 `USE_EXP_ITEM`, 63 `USE_EXP_ITEMS`, and 67 `LOAD_HERO_PIECES`.
- `SelfPlayer.lua` sends the recovered MID55/MID63 request shapes and removes the requested backpack items only after `xyd.error.OK`; MID67 consumes the returned Hero-piece map; MID52 sends only `partner_id`.
- `NormalHero.lua` and `SuperHero.lua` both clamp cumulative EXP with `partnerExp:totalExp(maxLevel)` and derive level from cumulative thresholds.
- The five qualified Hero EXP consumables are 50001001=60, 50001002=300, 50001004=1500, 50001005=7500, 50005182=10000 EXP.
- Normal target-star evolution rows produce 1->2 20 fragments + 35,000 Mana; 2->3 50 + 120,000; 3->4 100 + 300,000; 4->5 150 + 800,000.
- Super/Vows low-star progression uses qualifying five-star prerequisite families without consuming those Heroes. Target 6 uses 80M Mana/no fragment, target 7 uses 90M + 300 fragments, target 8 uses 100M + 800 fragments. Physical rows 6-8 retain `needHeroNum=5`, but the recovered client consults prerequisite counts only through the low-star regime. Effective client ceiling remains 8; physical 9/10 stay dormant.

## Produced-code inspection

The produced candidate was reread along the applicable path: dispatcher/request decode -> operation content binding -> Character Hero lock/mutation -> I5 owner transaction composition -> receipt resolution -> MID49/MID67 projection.

- Character remains sole durable owner of Hero `star/level/exp`; no Character SQL reaches I5 Economy/Progression/Scalar/Stack tables.
- I5 `HeroProgressionDebiter` composes Economy(700) -> Progression(710) -> sorted Stack(722) for EXP and reuses the existing owner-shaped material debit path for Mana/fragments.
- Character Hero locks remain rank 410; Super prerequisite Hero locks are canonical-sorted before I5 locks. No new Character lock ranks were invented.
- The exact progression content revision is bound into `operation.Context.Policies` before retryable transaction execution. Tests show a definite-abort retry continues to use the originally bound revision even if the active revision changes.
- Receipts are keyed by the server-side operation identity and request fingerprint. Matching receipts reconcile committed UNKNOWN-COMMIT outcomes; ambiguous absence is not blind-replayed.
- MID67 reads canonical I5 stack projection and joins revision-qualified fragment->Hero-origin mappings; it does not create a second fragment balance.
- MID49 projection carries the persisted `star/lev/exp` fields after progression.
- Production Hero routes are exactly 49,52,55,63,67,89. MID59/MID64/MID66/MID305 and promotion/equipment/skill routes remain inactive/deferred.

## Coding-time amendment and correction

The Pass516 plan required revision-bound EXP item values but Pass515 did not materialize them. Migration 00015 and `HERO_PROGRESSION_CA2` are therefore retained as an **IMPLEMENTATION_DECISION** to normalize source-qualified values under Content Registry ownership. The same migration stores the source's physical `need_hero_num` field. A Pass516 note that rows 6-8 had zero prerequisite count was corrected: exact source rows retain 5; behavior is unaffected because the later-star client path uses Mana/fragments instead of prerequisite counting.

The R5 validator's strict historical compiler pin remains unchanged; only its explicitly cumulative mode was extended to recognize the legitimate `ca2-2` compiler generation.

## Test/evidence reality

Canonical source/static/content/querytext/ownership checks are green. A fresh copy with only the minimum Go toolchain accommodation passes focused behavior, focused race, `go vet ./...`, `go test ./...`, and 89/89 package tests. This is **COMPATIBILITY_COPY_ONLY**, not exact Go 1.27.1 or PostgreSQL/River proof.

## Boundary

No evidence justifies activating capacity-dependent acquisition. Hero capacity/MID64 remains **UNKNOWN**. The next lifecycle step after sealing this checkpoint is CA2-3 **targeted pre-implementation research/reconciliation**, not CA2-3 coding. The Pass513 aggregate CA2 exact-native/real-PostgreSQL/River gate remains mandatory and unwaived.
