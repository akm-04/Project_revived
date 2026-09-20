# Pass591 CA7-5 Preimplementation Contract R2 — Research Closure Candidate

Status: RESEARCH_COMPLETE / PREIMPLEMENTATION_CONTRACT_FROZEN / IMPLEMENTATION_NOT_STARTED
Stage: CA7-5 — Pet Home-Style Entitlement, Selection & Cancel Semantics
Backend binding: Pass591 v0.83.0 accepted CA7-4 backend

## 1. Bound authority and evidence

- Unified PassMap: `gxb-backend-pass-591.0-passmap.zip`
  - SHA-256 `957ab9ef7e0570d3344bbc605b070a365fa13cdcf945467021e013c43b088b8b`
- Accepted backend: `gxb-backend-v2-v0.83.0-pass591-ca7-4-local-accepted.zip`
  - SHA-256 `25e9958b956e5be6da45c0c327e457e9dbd096396e7be95cfe19de7d568511a8`
  - Git HEAD `5ba75ec17ba07b585c1fa67ef5b5fb74ef627ef3`
  - Product tree `fa5b89591d1d88f63f7013a0e399bd80a5192a483f488c3a23dfef53f8baf798`
  - Migration high-water `00030_ca7_2_appearance_foundation.sql`
  - `CHARACTER_APPEARANCE_CA7` revision `ae577b8c9b9770f1d7a7dcf8335d9d36d27a15a687a12a5e5b01d97eca124116`
- Current source oracle archive SHA-256 `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`
- Historical v1.164 client oracle SHA-256 `d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1`

This contract is candidate-bound to those bytes. Frozen V1 and APK/native evidence are differential/corroborative only unless explicitly identified otherwise.

## 2. Owned operations

- MID1893 `GET_PET_STYLE_FORM_ITEM` — acquire Pet home-style ownership from one stack item.
- MID1894 `USE_PET_STYLE` — explicitly select an already-owned style.
- MID1895 `CANCEL_PET_STYLE` — explicitly clear the active style.

CA7-5 does not reactivate historical Pet MID60/MID61 ordinary-skin behavior. CA7-6+ remains outside scope.

## 3. Source facts

### 3.1 Wire and stock callback behavior

1. MID1893 request is `{item_id}`. On success the client reads `active_style` and `pet_styles`, removes one local copy of `item_id`, then refreshes Pet-home presentation.
2. MID1894 request is `{pet_id, style_id}`. On success the client reads `active_style`.
3. MID1895 request is `{pet_id}`. On success the client does not require returned state and locally sets `active_style=0`.
4. Current and v1.164 reachable Pet UIs expose CANCEL whenever any style is active; another USE is not reachable until cancellation.
5. Backpack can issue MID1893 independently of current `active_style`.
6. The style consumables are described as obtaining/getting the Pet cabin, while protocol separates GET (1893) from USE (1894).

### 3.2 Identity categories

- `pet_id`: concrete owned Pet instance.
- `origin_table_id`: canonical Pet family/origin.
- `style_item_id`: durable style entitlement identity and value stored in `pet_styles` / `active_style`.
- content `style_pet`: mapping from style item to canonical Pet origin.
- display/model resource identities remain separate and are not durable style ownership identities.

Qualified current mappings are:

- `50001374 -> 10120001`
- `50001376 -> 10030001`
- `50001402 -> 10040001`
- `50001598 -> 10190001`

## 4. Epistemic classifications

### SOURCE_FACT

- MID identities and request/result fields listed above.
- Local MID1893 item removal occurs only after a success callback.
- Current and v1.164 UI reachability enforces cancel-before-another-use.
- Backpack MID1893 path is independent of current active style.
- `pet_styles` / `active_style` use style item IDs and content maps those to Pet origin.
- The four current style-item/origin mappings.
- CA7-2 keyed Pet-style durable rows and effective projection already exist.
- CA7-2 projection normalizes raw positive `active_style` to effective 0 when it is not effectively owned/qualified.

### STRONG_INFERENCE

- MID1893 is grant-only and preserves the pre-operation **effective** active selector; it does not auto-select the acquired style.
- Fresh identical MID1893 packets re-evaluate current ownership and converge without another debit.
- An acquisition performed while another valid style is active preserves that style.
- Different-style direct switching must fail until MID1895 cancel, matching the independently reachable state machine.

### COMPATIBILITY_POLICY / IMPLEMENTATION_DECISION

- Stale/unqualified raw `active_style` is normalized to the pre-operation effective selector during MID1893 convergence/acquisition so granting an entitlement cannot accidentally revive stale state.
- Explicit MID1895 cancel clears any raw positive selector, including one that already projects effectively as 0.
- D11 family names, result schemas, receipt domain/policy version, and HTTP 400/404/409/503 distinctions below.
- Strict numeric request parsing and no invented response fields.

### UNKNOWN / DEFERRED

- Original-server Pet-home-style numeric error codes.
- Physical stock-client behavior on real infrastructure, deferred to W2.
- Exact accumulated PostgreSQL/River semantics for CA7, deferred to the mandatory CA7-7 native aggregate gate.

## 5. Ownership and persistence

Pet remains the sole durable owner. There is no Cosmetics aggregate and no foreign-owner SQL.

Existing CA7-2 persistence primitives each consume one Pet CAS independently:

- `SavePetStyleEntitlementTx` inserts an entitlement and advances Pet `state_version` once.
- `SavePetActiveStyleTx` assigns the scalar and advances Pet `state_version` once.

MID1893 therefore requires a narrow Pet-owned composite mutation seam:

`SavePetAppearanceMutationTx(ctx, tx, pet, optionalEntitlement, oldVersion)`

Semantics:

1. optionally insert the style entitlement;
2. persist the intended `active_style` scalar;
3. advance Pet `state_version` **exactly once** using the owner CAS;
4. all in the caller-owned transaction.

This is necessary even though MID1893 is grant-only: if a stale raw selector equals the newly acquired style, inserting ownership alone would make that stale selector suddenly effective and would silently auto-select the style. The composite instead persists the pre-operation effective selector. No new schema migration is required.

MID1894/MID1895 may use the existing `SavePetActiveStyleTx` assignment seam.

## 6. Time, transaction and lock contract

There is no CA7-5 deadline/reset/expiry mechanic. Do not introduce `TimedRunner` or a gameplay `DecisionAt` requirement.

Use ordinary Serializable `tx.Runner` with bounded definite-abort retry and D11 resolver. `operation.Context.StartedAt` remains retry-stable chronology for actor fencing, owner update timestamps and receipt chronology.

### Common operation sequence

1. validate actor and strict semantic request;
2. compute receipt identity and fingerprint;
3. perform pre-transaction same-operation receipt lookup before requiring the current appearance revision;
4. bind one immutable `CHARACTER_APPEARANCE_CA7` revision into the operation context;
5. begin Serializable transaction;
6. fence actor;
7. perform an **early in-transaction receipt recheck**;
8. validate the bound appearance revision in transaction;
9. resolve the target Pet:
   - MID1893: revision-qualified style item -> canonical Pet origin -> concrete owned Pet instance;
   - MID1894/1895: explicit Pet ID;
10. acquire the canonical Pet430 owner lock and revalidate player/Pet/origin identity;
11. perform the normal **post-Pet-lock receipt recheck**;
12. read current entitlements and build effective Pet appearance using the bound revision;
13. decide the operation branch from locked durable/effective state;
14. only for a genuinely first MID1893 acquisition, invoke typed I5 material debit after Pet430;
15. persist at most one Pet owner transition and the semantic receipt atomically;
16. project terminal result from canonical/effective state.

The two transactional receipt checks are intentional. MID1893 cannot know the Pet owner before revision-qualified content maps `item_id` to an origin, so the early check protects same-operation replay before that discovery work while the post-lock check protects the owner-critical section. This matches the accepted CA7-3/CA7-4 D11 pattern.

Pet430 precedes every I5 Economy/Stack lock. No other CA7-5 operation touches I5.

## 7. D11 receipt/replay contract

Domain: `character-pet-appearance`

Semantic key: `operation.Context.ID`

Policy version: `ca7-5.v1`

### MID1893

- catalog name: `ca7.pet-style-acquire`
- operation: `pet-style-acquire`
- replay class: `CURRENT_STATE_CONVERGENCE`
- consumptive: true on first acquisition only
- result schema: `gxb.ca7-5.pet-style-acquire.v1`
- fingerprint: exact `{item_id}`
- receipt result: resolved `pet_id`, requested `style_item_id`, terminal `active_style`, sorted `pet_styles`, terminal `state_version`, `mutated`, `consumed`.

`consumed` is internal evidence only; it is not a stock response field.

### MID1894

- catalog name: `ca7.pet-style-select`
- operation: `pet-style-select`
- replay class: `PARAMETER_STATE_ASSIGNMENT`
- result schema: `gxb.ca7-5.pet-style-select.v1`
- fingerprint: `{pet_id, style_id}`
- receipt result: `pet_id`, `style_id`, terminal `active_style`, terminal `state_version`, `mutated`.

### MID1895

- catalog name: `ca7.pet-style-cancel`
- operation: `pet-style-cancel`
- replay class: `PARAMETER_STATE_ASSIGNMENT`
- result schema: `gxb.ca7-5.pet-style-cancel.v1`
- fingerprint: `{pet_id}`
- receipt result: `pet_id`, terminal `active_style=0`, terminal `state_version`, `mutated`.

Same operation identity with a different fingerprint is a receipt conflict. Same-operation committed receipts remain authoritative even if current content later changes. A fresh stock request has a fresh operation ID and evaluates locked current state.

## 8. MID1893 acquisition state machine

Input: one positive strict integral numeric `item_id`.

1. Revision-qualify the style item and obtain its canonical Pet origin.
2. Resolve the unique owned Pet instance for that origin, then lock that Pet and revalidate the origin.
3. Load durable style entitlements and build effective pre-state.
4. Let `intendedActive = effectivePre.ActiveStyle`.
5. If requested style is already effectively owned:
   - no I5 debit;
   - if raw `pet.ActiveStyle == intendedActive`, semantic no-op: no Pet version change;
   - otherwise normalize raw selector to `intendedActive` with exactly one Pet CAS.
6. If requested style is not effectively owned:
   - debit exactly one `item_id` through typed I5 material-cost composition after Pet lock;
   - insert entitlement and persist `intendedActive` through the composite Pet mutation seam;
   - exactly one Pet `state_version` transition.
7. Rebuild effective post-state from keyed durable authority.
8. Return stock `{active_style, pet_styles}`.

First acquisition does **not** auto-select the style.

## 9. MID1894 selection state machine

Input: positive strict integral numeric `pet_id` and `style_id`.

The Pet must exist and the style must be effectively owned, revision-qualified and family-qualified for that Pet.

- effective active = 0 -> assign requested style, one Pet CAS;
- effective active = requested style:
  - raw canonical -> successful no-op receipt, no version bump;
  - raw/effective mismatch -> assign requested valid style in one CAS;
- effective active = another positive style -> HTTP 409 state conflict; no write; user must cancel first.

Return stock `{active_style}`.

## 10. MID1895 cancellation state machine

Input: positive strict integral numeric `pet_id`.

- raw active = 0 -> successful no-op receipt; no version bump;
- any raw positive active value -> assign 0 with exactly one Pet CAS, even when effective projection already normalized that raw value to 0.

Return stock `{}`.

## 11. Strict wire and stock projection

Use the established strict integral numeric Pet request parser. Do not accept strings, booleans, fractions or alternate aliases for semantic parameters.

Allowed semantic params:

- MID1893: `item_id`
- MID1894: `pet_id`, `style_id`
- MID1895: `pet_id`

Standard stock envelope metadata remains allowed under the existing dispatcher policy.

Success shapes:

- MID1893: `{active_style, pet_styles}` only;
- MID1894: `{active_style}` only;
- MID1895: `{}`.

Do not invent `remove_item`, remaining item quantity, `economy_`, `server_time`, Pet/style identifiers, or other response fields.

### Bounded stale-client residual

Because stock has no request nonce, a stale second client can believe an already-owned style is unowned, send a fresh MID1893, receive the correct server-side no-debit convergence success, and then locally remove one item in its own callback. There is no recovered stock response discriminator that can safely distinguish this packet from a legitimate lost-response retry: adding a field would invent protocol, and debiting again would corrupt server authority.

Therefore CA7-5 preserves authoritative no-double-debit convergence and records this as a bounded client-cache residual. It is **not** fixed by a second server debit or invented response field.

## 12. Error/transport policy

No recovered Pet-home-style server numeric error codes exist. `HOME_STYLE_NO_PARTNER` and `HOME_STYLE_ALREADYHAVA` are client-side prechecks, not server error identities.

Candidate V2 mapping:

- malformed request -> HTTP 400, stage-specific invalid Pet-style request code;
- missing Pet -> existing HTTP 404 `pet_not_found`;
- invalid/unqualified item/style, unowned selection, wrong family -> HTTP 400 `pet_operation_rejected`;
- different-style direct switch while another effective style is active -> HTTP 409 `pet_operation_rejected`;
- I5 insufficient item on first acquisition -> existing HTTP 409 `pet_operation_rejected`;
- appearance capability/revision inactive -> HTTP 503 `pet_content_inactive`;
- unexpected infrastructure failure -> HTTP 503 `pet_operation_failed`.

These HTTP distinctions are V2 implementation decisions constrained by existing Pet dispatcher conventions, not original-server numeric-code claims.

## 13. Concurrency contract

Mandatory implementation proofs:

1. same-item fresh MID1893 race on same Pet -> one debit/grant/version transition; waiter converges;
2. same-operation MID1893 UNKNOWN-COMMIT -> committed receipt returns without second debit/write;
3. acquisition while another valid style is active -> ownership added, active style preserved;
4. acquisition/convergence from stale raw selector -> raw normalized to pre-operation effective selector with one owner transition;
5. concurrent same-style MID1894 from active 0 -> at most one version bump; waiter no-op;
6. concurrent different-style MID1894 from active 0 -> one winner; waiter observes active conflict;
7. MID1894/MID1895 race -> serialized order defines result: cancel-first can permit selection; select-first then cancel ends at 0;
8. MID1893/MID1894 for initially unowned style -> select-first rejects unowned; acquire-first permits subsequent/waiting select when active remains 0;
9. cross-Pet acquisitions use separate Pet owner locks while each preserves Pet430-before-I5 ordering.

## 14. CA6 Practice and downstream consumers

CA6 Pet Practice proposals capture Pet `state_version`. Practice SAVE locks the Pet and rejects when proposal `ActorStateVersion` differs from current Pet version.

Therefore:

- every actual CA7-5 Pet style mutation intentionally stales a pending Pet Practice proposal;
- a CA7-5 semantic no-op does not change Pet version and must not invalidate an otherwise valid proposal.

Reload and future CA8 consumers use effective Pet appearance projection. They do not receive write authority.

## 15. Reload and malformed-state invariants

- Durable authority is keyed Pet-style entitlement rows plus Pet scalar `active_style`.
- `BuildEffectivePetAppearanceTx` remains the qualification/normalization authority for mutation decisions and response/reload projection.
- Owned style IDs are deterministic ascending item IDs.
- Effective active style is 0 or a member of the effectively owned set.
- Client `pet_styles` arrays are projection-only and are never ingested as durable gameplay authority.
- Duplicate durable style rows are structurally prevented by keyed storage; invalid/wrong-family durable rows are excluded from effective projection.
- No migration is required.

## 16. Expected implementation footprint if later authorized

1. Add a dedicated CA7-5 Pet style application service/tests under `internal/application/characterpet`.
2. Extend only the narrow Pet appearance store interface and Postgres adapter with the one-CAS `SavePetAppearanceMutationTx` composite.
3. Add MID1893/1894/1895 service-port methods, dispatcher cases, strict wire tests and production registration.
4. Register the three D11 replay families and tests.
5. Add candidate-bound CA7-5 source-oracle/architecture guards and evolve prior CA7 successor fences narrowly.
6. Add no migration.
7. Keep canonical `go.mod`, `go.sum`, `.go-version` and toolchain pins pristine. Try exact candidate first; if this sandbox remains toolchain-blocked, execute only a fresh disposable `COMPATIBILITY_COPY_ONLY` clone with minimal environment accommodation.

## 17. Mandatory future implementation gate

Implementation cannot be locally accepted until every row of the frozen CA7-5 acceptance matrix is evidenced and an independent postimplementation reality check re-reads source and produced code for:

- owner/CAS count;
- Pet430-before-I5 ordering;
- early + post-lock D11 checks and UNKNOWN-COMMIT;
- strict wire/error behavior;
- no-op/version semantics;
- stale selector normalization;
- reload/effective projection;
- CA6 Practice invalidation;
- CA7-6+ fences.

CA7-7 exact/native PostgreSQL/River accumulated proof and W2 physical stock-client proof remain deferred at their named gates and must not be marked passed by CA7-5 local evidence.
