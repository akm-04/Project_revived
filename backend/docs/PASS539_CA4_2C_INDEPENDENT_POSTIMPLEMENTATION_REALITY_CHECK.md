# Pass539 CA4-2C Independent Postimplementation Reality Check

Status: **GREEN — LOCAL / COMPATIBILITY_COPY_ONLY EXECUTABLE PROOF; NATIVE AGGREGATE GATE DEFERRED**

Authority parent: sealed Pass536 CA4-2 research/implementation contract plus the user's explicit staged CA4-2A→B→C→D authorization. Parent implementation checkpoint: Pass538 CA4-2B (`dad62051e279a8d766bfa6405db14b401ec1a16b72d91ff58b8d805c38bb3311`).

## Independent reread scope

This check reread the Pass536 CA4-2 contract and acceptance matrix, the current effective-client NormalHero/HeroMainWindow source mechanics previously extracted from the hash-verified src_64 corpus, the CA4-1 equipment primitive/recipe contracts, the Pass538 I5 Prepare/Apply seam, and the produced CA4-2C planner/service code. It did not infer original-server behavior from the frozen V1 backend and did not treat compatibility-copy execution as native PostgreSQL/River or stock-client proof.

## Findings

1. **MID54 boundary preserved.** `Service.EquipItem` accepts only an owned Normal Hero, a valid current-color ordinary slot, and a directly possessed mapped item. It does not compose recipes. An already-collected slot produces a zero-effect semantic receipt/result and no second I5 debit or Hero save. This is suitable for CA4-2D to shape as stock-compatible HTTP-200/body `error_code=30001`.
2. **MID62 planner is deterministic and source-shaped.** It evaluates slots 1→6, skips collected/zero/special/ineligible slots, shares reservations across accepted slots, prefers an available finished item before recursive synthesis, preserves ordered duplicate recipe edges/component multiplicity, charges ComposeMana per synthesized node, applies the player-derived Hero-level cap, uses maximum rather than summed Hero EXP shortfall, and persists actual potion EXP overshoot.
3. **Sealed oracle was not rewritten.** The embedded 15-vector fixture is byte-identical to the sealed Pass536 artifact (SHA-256 `28d08a3346b1c6015a7da3a0e2b442613374d5199fd674d367580b7757f9ae78`) and the Go planner matches all expected vectors.
4. **I5 ownership remains intact.** CharacterHero obtains a prepared canonical player-level/Mana/stack snapshot and applies only a validated debit through the Pass538 I5-owned seam. CA4-2C introduces no foreign-owner economy/stack SQL and no second transaction/receipt framework.
5. **Hero ownership remains intact.** The Hero aggregate is locked by CharacterHero; selected slot bits and actual potion EXP are applied to one Hero value and persisted via one cohesive `SaveHeroStateTx` CAS. The implementation deliberately guarantees a single state-version transition for a successful MID62 state mutation.
6. **Receipts cover effectful and zero-effect outcomes.** Same-operation replay returns the stored semantic outcome without a second debit/save. MID62 no-work is receiptable; MID54 already-equipped is receiptable. Stock-wire cross-request recovery remains state-based because the client supplies no reusable idempotency key.
7. **No response/projection overreach.** CA4-2C does not shape HTTP responses or project `economy_.mana`; that remains CA4-2D. Semantic receipts contain durable semantic state, not transient scalar projection data.
8. **Shared MID activation remains deferred.** No dispatcher `case 54`/`case 62` and no production MID registration were introduced in C. This is required because Super uses the same wires and CA4-5 owns Super base-equipment behavior.
9. **No unrelated family mechanics entered.** No Super, Fumo, Spirit/Horcrux, pet-equipment, promotion/reset, or CA4-3+ mechanics were added.
10. **Canonical pins remained pristine.** `.go-version`, `go.mod`, and `go.sum` retain the Pass535 hashes. Exact Go 1.27.1 execution is ENVIRONMENT_BLOCKED only by unavailable DNS/network access to the toolchain proxy.

## Executable/static evidence

- Exact canonical attempt: ENVIRONMENT_BLOCKED while Go attempted to download `go1.27.1`; no canonical accommodation was made.
- Fresh disposable compatibility clone: focused tests GREEN; focused race GREEN; focused vet GREEN; archguard GREEN; bounded package regression **92/92 GREEN**.
- Canonical generator/query/source-oracle/schema/ownership/dependency/sqlc-policy/cumulative static checks GREEN.
- CA4-2C stage-boundary validator GREEN.

## Verdict

**GREEN for CA4-2C local checkpoint acceptance under COMPATIBILITY_COPY_ONLY executable constraints.** No product defect or contract contradiction was found. This result does **not** satisfy the sealed exact-toolchain/real-PostgreSQL/River CA4 aggregate native gate and does not claim W2 physical stock-client proof.

Next permitted stage under the user's standing authorization: **CA4-2D dispatcher/projection/wiring/local aggregate acceptance**, while keeping production MID54/MID62 registration absent until the CA4-5 Super branch is qualified.
