# Pass594 — CA7-5 Independent Postimplementation Reality Check

## Authority and scope binding

This review is bound to Pass593 HOT/CURRENT migration authority, sealed Pass592 CA7-5 research, and the accepted Pass591 v0.83.0 CA7-4 backend. Pass593 is an implementation checkpoint rather than acceptance authority. The user explicitly authorized continuing CA7-5 implementation. The frozen contract remains `PASS592_CA7_5_IMPLEMENTATION_CONTRACT.md`; this review re-read that contract, the R2 acceptance matrix/source evidence, CA7-1 ownership/replay/lock rules, CA6 Practice fencing, current `src_64` evidence, and the produced code rather than treating test output as sufficient by itself.

## Source and identity reality

The current source oracle remains SHA-256 `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`; the historical v1.164 differential oracle remains `d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1`. Candidate-bound source guards pin MID1893 `GET_PET_STYLE_FORM_ITEM`, MID1894 `USE_PET_STYLE`, MID1895 `CANCEL_PET_STYLE`, callback state fields, local post-success item removal, Pet-family resolution, style-item identity, Backpack acquisition, and cancel-before-use reachability. No source evidence was found that contradicts the frozen grant-only MID1893 policy or cancel-before-direct-switch compatibility policy.

## Ownership, persistence, transaction and lock reality

Pet remains the sole durable owner of home-style entitlement and active selector. No Cosmetics aggregate, foreign-owner SQL, child-owned revision, or CA7-5 schema migration was introduced. CA7-5 reuses CA7-2 keyed entitlement rows and the Pet `active_style` scalar. `SavePetAppearanceMutationTx` optionally inserts one entitlement, persists the intended selector, then advances the Pet owner `state_version` exactly once through the existing CAS. Transaction rollback protects the child insertion if the owner CAS loses.

All three operations use the ordinary Serializable transaction/retry profile. Same-operation D11 lookup occurs before binding the current appearance revision, then an early in-transaction receipt recheck occurs after actor fencing, and a post-Pet-lock recheck protects the owner-critical section. MID1893 resolves the revision-qualified style item to canonical Pet origin, resolves the unique owned Pet, locks Pet430, revalidates player/origin identity, and only then invokes typed I5 debit for a genuinely first acquisition. Pet430 therefore precedes I5. Select and cancel do not touch I5.

## MID1893 acquisition/convergence reality

The implementation computes `intendedActive` from the pre-operation effective projection, not the raw selector. First acquisition therefore consumes exactly one style item, inserts entitlement and persists `intendedActive` in one owner transition without auto-selecting the newly granted style. If the requested style is already effectively owned, no I5 debit occurs; canonical raw state is a semantic no-op, while stale raw selector state is normalized to the same pre-operation effective selector with one Pet CAS. Post-state and response are rebuilt from keyed durable authority and effective projection, producing only stock `active_style` and sorted `pet_styles`.

A fresh identical stock request receives a fresh operation identity and re-evaluates current locked state. Same-operation replay and UNKNOWN-COMMIT use D11 receipts and never repeat the debit/write. The frozen stale-second-client residual remains explicit: an already-owned fresh request performs no second server debit even if a stale client later removes one local item after its success callback. No invented response discriminator or compensating second debit was added.

## MID1894/MID1895 state-machine reality

MID1894 requires a positive strict Pet/style identity, a present Pet, and an effectively owned revision- and family-qualified style. Effective active zero selects with one owner CAS. Same-style canonical state converges as a successful no-op with no version change. A different effective active style returns the frozen state conflict and writes nothing; after explicit MID1895 cancel, a different owned style may be selected.

MID1895 clears any raw positive selector with exactly one owner CAS, including a stale/unqualified selector that already projects effectively as zero. Raw zero is a successful no-op. Its stock success body remains empty.

## D11, wire and error reality

Replay catalog registration preserves `ca7.pet-style-acquire` as `CURRENT_STATE_CONVERGENCE` and select/cancel as parameter-state assignments with the frozen result schemas. Exact semantic fingerprints bind `{item_id}`, `{pet_id,style_id}`, and `{pet_id}` respectively. Changed parameters under the same operation identity conflict. Explicit UNKNOWN-COMMIT tests now cover acquire, select and cancel.

Dispatcher routes use the established strict integral Pet parser and reject strings, booleans, fractions and invented gameplay parameters. Success projection is exactly `{active_style,pet_styles}` for 1893, `{active_style}` for 1894, and `{}` for 1895. V2 transport decisions remain: malformed/invalid/unqualified/unowned/wrong-family 400 as applicable, missing Pet 404, direct-switch conflict and I5 insufficiency 409, content inactive/unexpected infrastructure 503. No original-server numeric Pet-style error code is claimed.

## Concurrency, reload and CA6 Practice reality

The frozen concurrency matrix is represented by tests for fresh same-item acquire, same-style select, different-style select race, select/cancel ordering, acquire/select ordering, and cross-Pet acquisition lock independence while retaining Pet-before-I5 order. These are local service/transaction-seam proofs, not real PostgreSQL contention proof.

Reload proof exercises acquire, semantic no-op, select and cancel through the existing roster/effective appearance projection. Durable style IDs remain keyed and sorted; effective active style is zero or a qualified member of the effective owned set. Client `pet_styles` arrays are never accepted as durable authority.

CA6 Practice SAVE independently locks the same Pet owner and compares the proposal's captured `ActorStateVersion` with current Pet `state_version` before applying Practice. Therefore every real CA7-5 appearance mutation intentionally stales a pending proposal, while semantic CA7-5 no-ops leave it valid. The dedicated cross-phase test confirms this composition rather than introducing a second invalidation mechanism.

## Testing classification and conclusion

The exact canonical candidate was attempted first, but Go 1.27.1 cannot be downloaded because this sandbox cannot reach `proxy.golang.org`. Canonical `.go-version`, `go.mod`, and `go.sum` remain pristine. Canonical static/source-oracle/query/ownership/cumulative/connected-candidate checks are green.

A fresh disposable clone changed only the three recorded Go/toolchain declaration lines and is therefore `COMPATIBILITY_COPY_ONLY`. Focused tests, focused race, whole-tree vet, the CA7-5/source/static guards, and a bounded 94-of-94 package regression are green. The R4D/R5 failures recorded inside the compatibility validator log are exclusively their deliberate canonical-Go-pin checks; the same validators are green on the pristine canonical tree.

Every frozen CA7-5 local acceptance row A15_01 through A16_11 is supported by produced code plus canonical-static and/or compatibility-executed evidence. This supports **CA7-5 local acceptance only**. It does not satisfy the mandatory CA7-7 exact/native real-PostgreSQL/River accumulated gate and does not satisfy W2 physical unmodified-stock-client proof. CA7-6 may open only after the release identity/local closure is finalized; CA7-7 and W2 remain deferred exactly at their named gates.
