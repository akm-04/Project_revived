# PASS590 CA7-4 Independent Preimplementation Reality Check R1

Verdict: **GREEN FOR IMPLEMENTATION PLANNING; IMPLEMENTATION NOT STARTED**  
Scope: independent reread/falsification of the CA7-4 research contract before any product code is written.  
Authority effect: none. Sealed Pass590 remains operational authority.

## Candidate identity rechecked

- PassMap unified SHA-256: `3b91544a74d177d3d8ca5dacca7e4fb0a6fbdecda5606f4f16d449fe08300431`
- Accepted backend archive SHA-256: `bdbb3c2ec795036e3ec4f97d33d57257133249f73c4f0aa2828de0540adbc9af`
- Git HEAD: `1b40629950996ade1ff0da841c5a53910080a22f`
- Product tree SHA-256: `002fc2a73fdff1866b153028febd32ad52ef7b905dfc5acac0d8756e8dce753c`
- canonical Go/module pins rechecked unchanged:
  - `go.mod` `313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4`
  - `go.sum` `efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d`
  - `.go-version` `a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718`
- migration high-water remains `migrations/00030_ca7_2_appearance_foundation.sql`.
- canonical workspace was clean during this review.
- production dispatcher still contains no MID68/MID69 route: research did not silently begin implementation.

## Authority reread

The review reread and reconciled:

- Pass590 CA7-4 frontier/research checkpoint and task packet.
- Pass585 CA7 internal stage roadmap.
- Pass586 CA7-1 implementation contract.
- Pass586 CA7-1 policy register, especially OWNER_01, LOCK_01, LIVE_01/02/03, REPLAY_01, CONTENT_01, WIRE_02 and CA6_01.
- Pass586 acceptance rows A12_MID68, A13_MID69 and A14_LIVE_LIFETIME.
- current verified src_64 MID definitions, Hero helpers, UI call sites, dynamic-card utility behavior, HTTP retry/economy handling and content tables.
- exact Pass590 CA7-2/3 backend storage, content, projection, I5, replay and HTTP seams.
- old-client v1.164 and frozen-V1 differential limitations.

No current authority requires a different durable owner, current-skin prerequisite, paid Vow state, timer/reset mechanic, or positional-array authority.

## Independent falsification results

### 1. Hypothesis: MID69 is a server-side toggle

**DISPROVEN for implementation contract.**

Stock computes a desired numeric `is_show = 1-current` and sends that value. Its callback applies that requested value. Therefore the server operation is parameter-state assignment. Re-toggling server current state would be wrong under retries/concurrency.

### 2. Hypothesis: MID68 should require current ordinary-skin ownership/selection

**DISPROVEN / unsupported strengthening.**

The parent contract requires only a qualified paid type2 LIVE definition and explicitly makes LIVE lifetime independent of skin entitlement. Current UI also exposes unlock against preview/card-front/skin-library model IDs. Adding a current-skin prerequisite would introduce coupling the accepted CA7-1 contract excludes.

### 3. Hypothesis: all SuperHero helper presence means Vow can own paid LIVE

**DISPROVEN.**

Generic helper methods exist, but current content and accepted policy bound durable paid LIVE to NormalHero type2. Type1/Vow presentation is automatic and does not materialize a paid row.

### 4. Hypothesis: stock positional LIVE arrays should be ingested/repaired as authority

**DISPROVEN.**

The current client parses strings positionally and is not robust to malformed/misaligned forms. V2 already owns keyed Hero+model rows and generates deterministic aligned arrays. No evidence justifies an array-repair mutation path.

### 5. Hypothesis: repeated identical MID68 packets should be permanently payload-deduplicated

**DISPROVEN by D11 plus transport behavior.**

Stock has no nonce, and every HTTP retry receives a new V2 operation ID. Same-operation receipt identity is only for server attempt/reconciliation. A fresh MID68 must re-evaluate current locked state; if ownership now exists, it converges without a second debit.

### 6. Hypothesis: an already-owned fresh MID68 should reset `is_show=true`

**REJECTED.**

`show=true` is the frozen **first acquisition** policy, not a perpetual assignment. Resetting show on a later fresh repeat would undo a legitimate MID69 choice and make delayed/retried unlock traffic mutate reversible state. Existing state must be preserved.

### 7. Hypothesis: Crystal should be stored in the MID68 semantic receipt

**REJECTED.**

I5 explicitly defines current scalar projection as transient owner state outside semantic receipts. Crystal can change independently after the LIVE semantic commit. Receipt stores the Hero/LIVE semantic result; the dispatcher projects current Crystal after execution/reconciliation.

### 8. Hypothesis: Crystal can be omitted on an already-owned successful MID68

**REJECTED for stock compatibility.**

A first acquisition may commit and lose its response. Stock retry is a new operation and correctly sees owned state/no second debit. Because the lost response also lost the generic economy update, the retry success must carry current `economy_.crystal` to repair the client cache. This follows directly from the current retry and economy event order.

### 9. Hypothesis: response should include item balance or `remove_item`

**UNSUPPORTED / rejected.**

MID68 stock callback removes the activation item itself after success. Inventing an additional item-decrement signal risks double local mutation and has no recovered source basis. The parent convergence rule controls server debit; activation-item cache correction after stale cross-client traffic remains a bounded client residual.

### 10. Hypothesis: CA7-4 requires a new schema or composite CAS

**REJECTED.**

The accepted keyed LIVE table already represents all CA7-4 durable facts, and `SaveHeroLIVEEntitlementTx` writes one child plus one Hero owner CAS. A CA7-4 semantic mutation touches at most one LIVE row. CA7-3's composite entitlement+selector write problem does not recur here.

### 11. Hypothesis: CA7-4 needs `TimedRunner`

**REJECTED.**

Paid LIVE has no expiry/reset/duration mechanic. `operation.StartedAt` is sufficient immutable chronology/fence time. Ordinary Serializable transaction/retry/receipt infrastructure matches the accepted Character mutation pattern.

### 12. Hypothesis: READ COMMITTED is safer/equivalent

**REJECTED absent a demonstrated exception.**

Accepted Character+I5 mutations use Serializable bounded retry, and CA7-4 has no known anomaly requiring CA5-style weaker isolation. Keep the standard Serializable contract.

### 13. Hypothesis: malformed/stale unrelated LIVE rows should globally reject MID68/69

**REJECTED.**

Effective projection already filters stale/wrong-origin rows. After the requested model is independently qualified against the locked Hero and pinned revision, an unrelated stale row is not a reason to block a valid mutation. It remains non-projecting provenance until a future explicit migration/repair policy exists.

### 14. Hypothesis: MID69 should accept permissive booleans/strings because shared `requiredInt64` does

**REJECTED for the external CA7-4 wire contract.**

The ordinary HTTP decoder uses `json.Decoder.UseNumber`, and stock sends a JSON number 0/1. Shared permissive parsing is broader than recovered evidence. A command-local exact numeric 0/1 parser is the smallest compatibility surface and prevents invented alternate wire forms.

## Transaction and owner review

The frozen operation shape preserves all accepted ownership rules:

- Character/Hero is the durable owner.
- Hero lock is acquired before any I5 Economy lock.
- MID68 uses typed caller-owned I5 material debit; no foreign-owner SQL.
- actual LIVE change performs exactly one Hero CAS.
- no-op performs zero Hero CAS.
- semantic receipt is stored in the same transaction as the mutation/debit.
- same-operation receipt is checked before work and again after the Hero lock so waiters cannot duplicate a committed operation.
- fresh HTTP retries have new operation IDs and use current-state convergence.
- post-semantic Crystal projection is read-only/current and outside receipt.

No circular dependency or later-stage ownership was introduced.

## Concurrency review

The lock/state model admits deterministic outcomes for all required races:

- same-model first unlock race: one debit/write, waiter no-op;
- distinct-model unlocks: serialized legitimate independent acquisitions;
- show-before-unlock: reject; show-after-unlock: valid;
- same desired show race: at most one change;
- opposite show assignments: serial, final state follows order;
- CA7-3/CA7-4 on same Hero: serialized by same owner lock/version;
- real mutation stales CA6 Practice proposal, no-op does not.

No operation requires a foreign owner to mutate Character state.

## Wire/reload review

MID68 response is frozen to the minimum stock-required semantic surface:

- aligned deterministic `unlocked_dynamic_card`;
- aligned deterministic `dynamic_card_state`;
- generic `economy_.crystal` current projection.

MID69 success requires only `{}` because the stock callback already knows and applies the requested desired bit.

Type1/Vow remains automatic; paid rows are model-sorted and independent of ordinary skin expiry.

## Bounded residuals and unknowns

1. **Stale second-client activation-item cache:** a client that incorrectly still believes an already-owned LIVE is locked can send a fresh MID68; server must not debit twice, but the successful callback can locally subtract the item. No recovered response field safely distinguishes this case from lost-response recovery without risking double local removal. This is documented, not hidden or “fixed” by violating server authority.
2. Original-server numeric error codes/statuses remain unknown.
3. Original-server initial show bit remains unknown; accepted V2 policy is first unlock `is_show=true`.
4. Old client v1.164 predates the feature and cannot prove MID68/69 semantics.
5. Frozen V1 is corroborative/differential only, not original-server truth.
6. Physical stock-client proof remains W2-deferred.
7. Exact accumulated native PostgreSQL/River proof remains CA7-7.

None of these residuals blocks a deterministic V2 implementation under the accepted parent policy.

## Companion research artifacts

- `PASS590_CA7_4_PREIMPLEMENTATION_CONTRACT_R1.md`
- `PASS590_CA7_4_ACCEPTANCE_MATRIX_R1.json`
- `PASS590_CA7_4_SOURCE_ORACLE_R1.json`

## Verdict

The contract now has one coherent implementation path with bounded, explicitly classified unknowns. No material mechanic remains that would require guessing during coding or reopening CA7-1/2/3.

**CA7-4 PREIMPLEMENTATION RESEARCH GATE: GREEN.**

This verdict authorizes **planning readiness only within this research artifact**. It does not claim implementation, executable proof, PostgreSQL proof, stock-client proof, phase acceptance, or PassMap advancement. The exact Pass590 backend remains untouched and MID68/MID69 remain unimplemented at the end of this review.
