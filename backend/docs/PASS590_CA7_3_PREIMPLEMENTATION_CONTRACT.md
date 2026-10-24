# PASS589 CA7-3 Preimplementation Research Gate — GREEN R2

Status: RECOVERY CHECKPOINT / NOT A PASSMAP SEAL
Candidate: gxb-backend-v2-v0.81.1-pass588-ca7-2-accepted-pass589.zip
Candidate SHA-256: ed2898e704d033607e41e3350765b20ba0343057cfe05d980bde774aecd5b685
Git HEAD before CA7-3 implementation: b545f9568ada16183b1de7d13b2cb380815284ed
Parent PassMap: gxb-backend-pass-589.0-passmap.zip SHA-256 adeca7a97ccde4559876ba5148b1526d00a5968c7dd8d8b25407389b5a688be7

## Gate decision
CA7-3 preimplementation research/reconciliation is GREEN. User has explicitly authorized normal-chat implementation after the research gate is sufficient. This checkpoint does not seal implementation or change PassMap authority.

## Frozen scope
- MID60 SKIN_ON — state-dependent acquire or select for Hero/Vow ordinary skin.
- MID61 SKIN_CANCEL — ordinary selector assignment to base (0).
- MID2979 USE_ILLUSION_SKIN_ITEM — independent illusion selector.
- Timed/permanent Hero skin entitlement qualification and promotion.
- Typed future-Commerce permanent-skin materialization seam owned by Character.
- No CA7-4 paid LIVE mutation and no CA7-5 Pet style mutation.

## Frozen owner / lock / revision contract
- Hero is the sole durable owner for Hero/Vow skin entitlement, ordinary selector, illusion selector.
- Hero instance lock rank 410 precedes I5 Economy locks.
- One semantic Hero appearance mutation advances Hero state_version exactly once, regardless of whether it touches selector(s), entitlement, or both.
- No-op assignments store the same-attempt terminal receipt but do not advance Hero state_version.
- CA6 Practice proposals continue to stale naturally when a CA7 mutation advances Hero state_version.
- A narrow Hero-owned composite appearance persistence seam is required because CA7-2 selector and entitlement primitives each independently consume one Hero CAS.

## Time/content contract
- Bind one immutable CHARACTER_APPEARANCE_CA7 content revision per new operation. Same-attempt receipt replay is checked before rebinding current content.
- Use DB-authoritative TimedRunner DecisionAt once per operation, stable across retries/UNKNOWN-COMMIT.
- DecisionAt governs actor fence, entitlement qualification, equality boundary, new timed deadline, and Hero mutation timestamp.
- Valid at DecisionAt <= expires_at; expired only after the deadline.
- Existing I5 MaterialCostDebiter remains valid for skin-card stack debit; stack rows carry no competing entitlement-time semantics.

## MID60 state machine
For a source-qualified skin item matching the locked Hero origin family:
1. absent + permanent item: debit one card, grant permanent, do not auto-equip.
2. absent + timed item: debit one card, grant expires_at=DecisionAt+duration, do not auto-equip.
3. active timed + timed item for same model: select ordinary model, no debit, no extension/stacking.
4. expired timed + timed item: normalize stale selectors, debit one card, replace deadline, do not auto-equip.
5. timed (active or expired) + permanent item: normalize stale selectors, debit one card, promote to permanent, do not auto-equip.
6. permanent + permanent item: select ordinary model, no debit.
7. permanent + timed trial item: reject with recovered stock error_code 35035, no debit.

Before any acquisition/promotion/reacquisition write, normalize stale raw selectors to the effective pre-state at DecisionAt so expired intent cannot resurrect. Selection sets ordinary selector to the qualified model. Acquisition never auto-equips.

## MID61
- Request: partner_id only.
- Desired ordinary selector = 0.
- Preserve illusion selector raw semantics; MID61 does not rewrite illusion as a side effect.
- If already 0: terminal same-attempt receipt, no Hero version bump.
- Success body may be {} because current stock callback ignores it and applies local ordinary=0.

## MID2979
- Request: partner_id + item_id.
- item_id=0 => illusion selector 0 (base).
- item_id=1 => illusion selector 1 (current/awakened presentation sentinel).
- item_id>1 => resolve appearance skin item -> model, require Hero origin-family match and effective entitlement at DecisionAt, then store model ID.
- Negative wire item_id is rejected; -1 remains a durable/effective sentinel and stale-explicit fallback, not a source-proven current request value.
- Preserve ordinary raw selector; MID2979 never affects combat skin-skill axis.
- Same desired selector => terminal receipt, no Hero version bump.

## Effective projection / response
- Reuse characterasset.BuildEffectiveHeroAppearanceTx; do not duplicate qualification rules.
- MID60 success: always current_skin_id + deterministic skin_ids; add remove_item:1 only on consumptive branches. Omit server_time absent stronger evidence.
- MID61 success: {}.
- MID2979 success: illusion_skin_id.
- skin_ids permanent=-1, timed=absolute expiry Unix seconds.
- Ordinary selected qualified skin drives combat skin-skill; illusion is presentation-only.

## Error contract
- 35035 numeric code is SOURCE_FACT for permanent-owned + timed trial card rejection.
- Current client treats HTTP status as callback OK/ERROR; a bare HTTP-200 error body would enter MID60 success code and dereference missing fields. Therefore implementation decision: emit 35035 on non-success HTTP status (400) with JSON error_code=35035.
- Unknown invalid-case stock numeric codes remain UNKNOWN; use existing non-numeric Hero operation rejection rather than inventing codes.
- Translate I5 missing/insufficient skin card into appearance-unavailable application rejection; do not leak it as 503.

## Receipt contract
All three stock operations use OwnerKind=player, Domain=character-hero-appearance and SemanticKey=operation.Context.ID. This is same-attempt recovery only; a fresh identical HTTP packet gets a new operation ID and re-evaluates current canonical state.

Schemas:
- gxb.ca7-3.skin-on.v1: partner_id, current_skin_id, canonical qualified skins [{model_id, expires_at_unix|null}], state_version, mutated, remove_item.
- gxb.ca7-3.skin-cancel.v1: partner_id, current_skin_id=0, state_version, mutated.
- gxb.ca7-3.illusion-select.v1: partner_id, illusion_skin_id, state_version, mutated.

Receipt replay returns the stored committed semantic result even if wall clock/content later changes. Receipt fingerprint is exact stock gameplay request fields.

Replay catalog classifications:
- MID60: CURRENT_STATE_CONVERGENCE, consumptive on acquisition/promotion branches, residual: stock nonce absent; fresh identical packet re-evaluates canonical entitlement/selector state.
- MID61: PARAMETER_STATE_SET, desired ordinary selector 0.
- MID2979: PARAMETER_STATE_SET, desired sentinel/item-derived illusion state.

## Concurrency contract
- All three serialize through the Hero instance lock.
- Same expired timed MID60 concurrently: first reacquires/debits; waiter rereads active timed state and converges to selection/no second debit.
- permanent-item vs timed-trial races are lock-order/current-state semantics: permanent-first makes later trial 35035; trial-first may establish timed then permanent request promotes. No payload-wide replay lease.
- MID60 vs MID61/MID2979 re-evaluate after lock; each touches only its owned semantic axis except MID60 normalization during acquisition/promotion as frozen above.
- Receipt recheck after the blocking Hero lock prevents same-operation waiters from mutating twice.

## Permanent-skin materialization port
Expose a typed Character-owned caller-transaction port for future Commerce. It:
- accepts player/partner/model/content revision and operation decision instant,
- locks/qualifies the Hero through Character-owned ports,
- converges the model to permanent ownership,
- normalizes stale selectors before a real grant,
- never auto-equips,
- advances Hero state_version once only if durable state changes,
- owns no Commerce pricing/settlement and exposes no Character SQL to Commerce,
- records no independent semantic receipt; future Commerce owns its settlement receipt and caller transaction.

## Acceptance matrix required for implementation
- MID60 all seven state branches plus expired+permanent promotion.
- deadline-1 / deadline / deadline+1.
- no auto-equip, no active-timed extension, timed->permanent.
- 35035 transport and no debit.
- missing/insufficient card reject without mutation.
- same-op receipt replay + fresh identical request convergence.
- no-op version behavior for MID61/MID2979.
- concurrent expired reacquisition, acquisition/select/cancel/illusion serialization.
- reload/reconnect stock projection.
- deterministic skin_ids.
- ordinary-only combat skin-skill axis.
- CA6 Practice stale-proposal regression after real Hero appearance mutation.
- source-oracle checks for MID constants, request/response fields, sentinel behavior and client HTTP callback semantics.
- replay catalog / architecture / production registration guards.
- CA7-4 LIVE and CA7-5 Pet route fences remain closed.

## Environment/testing rule
Canonical go.mod/go.sum/.go-version remain pristine. Exact candidate is attempted first. If local Go 1.27.1 is unavailable, create a fresh disposable clone and make only the minimum environment-specific Go/toolchain accommodations there. All such results are COMPATIBILITY_COPY_ONLY and never count as exact canonical-toolchain/PostgreSQL/River proof. Real product defects are fixed separately in canonical and tested from a fresh clone.
