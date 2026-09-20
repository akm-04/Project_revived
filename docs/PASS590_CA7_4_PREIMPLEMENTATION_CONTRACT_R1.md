# PASS590 CA7-4 Preimplementation Contract R1

Status: **RESEARCH-FROZEN / PREIMPLEMENTATION ONLY**  
Authority effect: **NONE** — this is a candidate-bound research artifact, not a PassMap seal and not implementation acceptance.  
Current operational authority remains sealed Pass590. CA7-4 product implementation remains unopened in this artifact.

## 1. Candidate binding

- Unified PassMap: `gxb-backend-pass-590.0-passmap.zip`
  - SHA-256: `3b91544a74d177d3d8ca5dacca7e4fb0a6fbdecda5606f4f16d449fe08300431`
- Accepted backend: `gxb-backend-v2-v0.82.0-pass590-ca7-3-local-accepted.zip`
  - SHA-256: `bdbb3c2ec795036e3ec4f97d33d57257133249f73c4f0aa2828de0540adbc9af`
  - Git HEAD: `1b40629950996ade1ff0da841c5a53910080a22f`
  - Product tree SHA-256: `002fc2a73fdff1866b153028febd32ad52ef7b905dfc5acac0d8756e8dce753c`
- Current src_64 oracle archive SHA-256: `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`
- Old-client v1.164 corpus SHA-256: `d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1`
- Frozen V1 differential archive SHA-256: `31729d5c5e4509c2c89eaa1e8203cf1570afe87e18ed2610b944e457a9946b15`

## 2. Authority and scope

CA7-4 title: **Normal-Girl Paid LIVE Entitlement & Show-State Semantics**.  
Owned MIDs: **68 UNLOCK_DYNAMIC_CARD** and **69 SHOW_DYNAMIC_CARD**.

Frozen parent acceptance obligations:

- A12: first qualified type2 unlock atomically debits content Crystal + activation item `50005171`, stores Hero+model LIVE, initializes show=true policy, bumps Hero version once, and records/reconciles the exact semantic operation; an already-owned fresh repeat never debits again.
- A13: MID69 is an explicit `is_show` assignment against an owned/qualified paid LIVE, converges idempotently, and preserves deterministic aligned reload arrays.
- A14: paid LIVE persists independently of timed ordinary-skin expiry; Vow/type1 automatic animation never materializes paid entitlement.

Out of scope:

- CA7-5 Pet style mutation.
- CA7-6/CA8 integration work beyond preserving their accepted seams.
- physical unmodified-stock-client proof (W2).
- accumulated exact/native PostgreSQL/River gate (CA7-7).
- inventing original-server error codes, original initial-show bit, or acquisition order semantics.

## 3. Evidence classifications

### SOURCE_FACT

1. MID68=`UNLOCK_DYNAMIC_CARD`; MID69=`SHOW_DYNAMIC_CARD`.
2. MID68 stock request is `{partner_id, model_id}`. Its HTTP-200 callback replaces both `unlocked_dynamic_card` and `dynamic_card_state` from the response.
3. MID69 stock request is `{partner_id, model_id, is_show}` where stock computes numeric `is_show = 1-current`. Its HTTP-200 callback ignores response data and applies the requested bit locally.
4. Paid LIVE UI is exposed for `dynamicType(model)==2`; type1 is automatic and type0 is not shown.
5. Current paid definitions use content-defined Crystal cost plus activation item `50005171` and count.
6. On MID68 success the UI locally removes the activation item; it does not locally subtract Crystal.
7. Generic successful HTTP handling processes top-level `economy_` before the MID callback, and SelfPlayer assigns `economy_.crystal` to its Crystal cache.
8. On transport failure the client retries by issuing a fresh web request with the same MID/payload; stock supplies no request nonce.
9. The V2 HTTP edge creates a fresh `operation.Context` for every inbound POST, so each stock transport retry receives a new operation ID.
10. Stock LIVE reload is positionally encoded as aligned `unlocked_dynamic_card` / `dynamic_card_state` strings. `splitToNumber` is not a safe durable-state parser for malformed/misaligned arrays.
11. V2 durable paid LIVE is keyed `(player_id, partner_id, model_id)`, and effective projection is NormalHero-only, revision-qualified, wrong-origin filtered, unique, and sorted by model ID.
12. `SaveHeroLIVEEntitlementTx` writes one LIVE child and advances Hero `state_version` exactly once through the Character owner CAS.
13. I5 material debit is a caller-owned transaction seam capable of atomically debiting scalar + stack resources. `CurrentScalarProjectionPort` is explicitly transient current response state outside semantic receipts.

### STRONG_INFERENCE

1. Every successful MID68 response should include current Crystal in generic `economy_.crystal`, including an already-owned fresh convergence response. This repairs a stock Crystal cache after a first committed response was lost and the client retried.
2. A fresh already-owned MID68 request must preserve the existing `is_show` bit rather than reset it to the first-acquisition default.
3. MID68 must not require the requested LIVE model to be the Hero's currently selected/owned ordinary skin. The stock UI can invoke unlock from card-front/skin-library preview paths, and parent policy makes LIVE lifetime independent from skin entitlement.
4. Unrelated stale/wrong-origin durable LIVE rows should be omitted by effective projection rather than globally blocking a qualified request. A row for the requested qualified model is intrinsically qualified after Hero-origin/content validation.

### IMPLEMENTATION_DECISION / ACCEPTED CONTRACT REUSE

1. First paid type2 unlock initializes `is_show=true` (`LIVE_02`). Original-server initial bit remains unrecovered.
2. Hero is the sole durable owner; no Cosmetics aggregate or foreign-owner SQL.
3. Hero lock precedes I5 Economy locks.
4. D11 semantic receipts identify the same **server operation** by `operation.Context.ID`; they are not a permanent payload-deduplication lease.
5. MID68 replay family: `CURRENT_STATE_CONVERGENCE`. Proposed retained catalog identity:
   - name `ca7.hero-live-unlock`
   - domain `character-hero-appearance`
   - operation `live-unlock`
   - receipt schema `gxb.ca7-4.live-unlock.v1`
6. MID69 replay family: `PARAMETER_STATE_SET`. Proposed retained catalog identity:
   - name `ca7.hero-live-show`
   - domain `character-hero-appearance`
   - operation `live-show`
   - receipt schema `gxb.ca7-4.live-show.v1`
7. CA7-4 uses ordinary Serializable `tx.Runner` with bounded definite-abort retry. No timed/reset mechanic justifies a `TimedRunner` or a READ COMMITTED exception.
8. Deterministic semantic rejection uses the established Hero 400-family transport; content/capability outage remains 503. No unrecovered numeric stock error is invented.
9. MID69's external wire `is_show` is accepted only as an actual integral JSON number exactly `0` or `1`. Strings, booleans, fractions, missing values, and other integers are rejected. This is a source-constrained compatibility fence, not an original-server claim.

### UNKNOWN / DEFERRED

- original-server numeric failure codes / exact HTTP statuses for MID68/69.
- original-server initial show bit (V2 policy is show=true).
- physical unmodified-stock-client execution.
- whether a stale second client that sends an already-owned MID68 temporarily under-reports its local activation-item cache after the callback; there is no recovered safe response discriminator. The parent no-second-debit rule remains controlling.

## 4. Storage and owner invariants

- Canonical durable owner: Hero.
- Durable fact: `HeroLIVEEntitlement{PlayerID, PartnerID, ModelID, IsShow}`.
- Identity: `(player_id, partner_id, model_id)`.
- Type1/Vow automatic LIVE never materializes in this table.
- No migration is currently required: migration `00030_ca7_2_appearance_foundation.sql` already supplies the required keyed table and owner FK/CAS infrastructure.
- No new composite Hero persistence primitive is required: a CA7-4 semantic mutation changes at most one LIVE row plus one owner version transition, which is already exactly the contract of `SaveHeroLIVEEntitlementTx`.
- No mutation is allowed on an idempotent no-op; therefore no Hero version bump on already-owned MID68 or already-equal MID69.

## 5. Content qualification

For either MID:

1. Pin the active `CHARACTER_APPEARANCE_CA7` revision once into the immutable operation policy.
2. Revalidate the pinned revision inside the transaction.
3. Lock the requested Hero under canonical Character ordering.
4. Resolve the Hero through its creation-content revision and require `NormalHero`.
5. Resolve `AppearanceLIVETx(pinnedRevision, modelID)`.
6. Require definition validity and `HeroOriginTableID == lockedHero.OriginTableID`.
7. Type1/Vow, unknown model, wrong origin/family, malformed identity, and SuperHero paid-state requests fail closed.

There is **no** ordinary-skin selection/ownership prerequisite.

## 6. MID68 exact candidate state machine

Request: `{partner_id, model_id}`.

1. Validate actor, operation context and strict top-level gameplay parameter set.
2. Parse positive `partner_id` and `model_id`.
3. Bind one appearance content revision to the operation.
4. Build D11 identity using player owner, domain `character-hero-appearance`, operation `live-unlock`, semantic key `op.ID`.
5. Fingerprint canonical `{partner_id, model_id}`.
6. Check same-operation receipt before transaction.
7. Execute Serializable transaction with bounded definite-abort retry and receipt reconciliation.
8. Apply actor fence at immutable operation `StartedAt`.
9. Recheck same-operation receipt inside the transaction, including after waiting for the Hero lock.
10. Validate pinned appearance revision transactionally.
11. Lock Hero.
12. Resolve/qualify NormalHero and paid LIVE definition as section 5.
13. Load durable LIVE rows.
14. If requested qualified row already exists:
    - preserve its current `IsShow` value;
    - perform no I5 debit;
    - perform no Hero/LIVE write;
    - do not advance Hero `state_version`.
15. Otherwise:
    - build one I5 `MaterialCost` containing scalar `crystal = definition.CrystalCost` and stack `definition.ActivationItemID = definition.ActivationItemCount`;
    - debit through the typed caller-owned I5 transaction seam **after** Hero lock;
    - translate deterministic insufficient/missing player resource outcomes to `ErrHeroAppearanceUnavailable` rather than leaking a generic infrastructure failure;
    - create `HeroLIVEEntitlement{..., ModelID, IsShow:true}`;
    - set Hero `UpdatedAt = op.StartedAt.UTC()` and increment state_version exactly once;
    - call `SaveHeroLIVEEntitlementTx` exactly once.
16. Build effective post-state through revision-qualified appearance projection; unrelated stale rows remain filtered.
17. Construct canonical result as model-sorted `{model_id,is_show}` pairs plus current Hero state version and `Mutated`.
18. Store semantic result in the same transaction receipt.
19. After successful execution/reconciliation, use I5 `CurrentScalarProjectionPort.CurrentScalar(...,"crystal",op)` outside the receipt to obtain current Crystal.
20. HTTP-200 body:
    - `unlocked_dynamic_card`: `|`-joined sorted model IDs from semantic LIVE result.
    - `dynamic_card_state`: matching `1|0` sequence in identical order.
    - `economy_`: `{ "crystal": <current scalar> }` on **every** MID68 success.
21. Do not invent `remove_item`, item balance, `server_time`, costs, model metadata, or a bespoke Crystal field.

Receipt result shape frozen for implementation planning:

```text
LiveUnlockResult {
  PartnerID    int64
  ModelID      int64
  LIVE         []LIVEStatePair{ModelID int64, IsShow bool} // strictly model-sorted
  StateVersion int64
  Mutated      bool
  Replayed     bool // not serialized
}
```

Crystal is deliberately excluded from the semantic receipt.

## 7. MID69 exact candidate state machine

Request: `{partner_id, model_id, is_show}`.

1. Validate only stock gameplay keys plus ordinary envelope metadata.
2. Parse positive partner/model IDs.
3. Parse `is_show` from **JSON number only**, exact integral `0` or `1`; convert to desired bool.
4. Bind one appearance content revision.
5. D11 identity: player / `character-hero-appearance` / `live-show` / `op.ID`.
6. Fingerprint canonical `{partner_id, model_id, is_show(0|1)}`.
7. Same pre-transaction and in-transaction receipt checks as MID68.
8. Serializable transaction + actor fence + pinned revision validation.
9. Lock Hero, then resolve/qualify NormalHero and requested paid LIVE definition.
10. Load durable LIVE rows and require the requested qualified entitlement to exist.
11. If `existing.IsShow == desired`, record a terminal no-op receipt with current state version; no Hero write and no version bump.
12. Otherwise update exactly that entitlement's `IsShow`, set Hero UpdatedAt to `op.StartedAt`, increment Hero state_version once, and call `SaveHeroLIVEEntitlementTx` once.
13. Store terminal receipt.
14. HTTP-200 body is `{}`; stock applies the already-requested bit locally. No invented arrays/economy sideband are required for MID69.

Receipt result shape frozen for planning:

```text
LiveShowResult {
  PartnerID    int64
  ModelID      int64
  IsShow       bool
  StateVersion int64
  Mutated      bool
  Replayed     bool // not serialized
}
```

## 8. Retry and UNKNOWN-COMMIT semantics

- Server-side transaction retry / UNKNOWN-COMMIT reconciliation within one HTTP request uses the same operation ID and therefore the same D11 receipt identity.
- Stock transport retry is a **new** HTTP request and receives a new operation ID. It must re-evaluate current durable state.
- Consequence for MID68 lost-response recovery:
  1. first request may commit debit+entitlement but response is lost;
  2. stock has not run success callback, so local activation item and Crystal cache remain stale;
  3. retry has new operation ID;
  4. server sees owned LIVE, performs no second debit/version bump;
  5. success callback removes activation item locally once;
  6. generic `economy_.crystal` refreshes Crystal to current server state before callback.
- A historical receipt must never grant current entitlement after it has ceased to be current authority. Fresh requests are interpreted from locked current state.

## 9. Malformed/stale state policy

- Stock positional arrays are projection only and never mutation input.
- Keyed durable table prevents duplicate identity rows structurally.
- Effective projection filters invalid/wrong-origin/stale definitions and sorts model IDs.
- Do not implement a legacy-array repair mutation.
- An unrelated stale row does not invalidate an otherwise qualified request; it simply does not project.
- The requested row counts as owned only after the request's current Hero/origin/revision qualification succeeds.

## 10. Concurrency contract

Required deterministic cases:

1. **MID68 same model vs same model:** Hero lock serializes; exactly one first acquisition may debit/write; waiter observes ownership and converges without debit/version bump.
2. **MID68 different models, same Hero:** serialize on Hero; each distinct absent qualified model may debit/write once if resources remain sufficient.
3. **MID68 vs MID69 same absent model:** if show locks first it rejects unowned; if unlock commits first, show may then apply its desired state.
4. **MID69 same desired state vs same desired state:** at most one semantic state change/version bump; later waiter is no-op.
5. **MID69 opposite desired states:** serial assignments are both legitimate; final state is determined by lock/commit order.
6. **CA7-3 vs CA7-4 same Hero:** same Hero lock/CAS prevents independent owner races; no foreign-owner SQL.
7. **I5 ordering:** Hero lock is held before any Economy lock acquired by MID68.
8. **CA6 Practice:** real CA7-4 Hero mutation bumps owner version and intentionally stales pending Practice proposal; semantic no-op does not.

## 11. Lifetime/reload contract

- Paid LIVE has no expiry/reset clock.
- Timed ordinary-skin expiry/removal must not delete or mutate paid LIVE.
- Reload/reconnect projects paid LIVE independently from skin qualification.
- Type1/Vow LIVE stays automatic content behavior and absent from durable paid rows.
- Aligned stock strings are regenerated from canonical model-sorted keyed rows every time; acquisition order is not semantic.

## 12. Error/transport contract

External malformed wire:

- MID68 missing/extra/invalid gameplay fields -> HTTP 400 command-local invalid request.
- MID69 missing/extra/invalid fields, including nonnumeric/non-0-or-1 `is_show` -> HTTP 400 command-local invalid request.

Deterministic semantic rejection -> established Hero HTTP 400 `hero_operation_rejected`, including:

- unknown/unqualified/wrong-origin model;
- paid request for SuperHero/type1/type0;
- MID69 on unowned paid LIVE;
- insufficient Crystal / activation item / absent player resource row.

Content/capability inactive -> established Hero 503 `hero_content_inactive`.  
Unexpected storage/reconciliation/infrastructure failure -> established Hero 503 `hero_operation_failed`.

No numeric stock error code is asserted because none was recovered.

## 13. Required later implementation proof

The companion acceptance matrix is `PASS590_CA7_4_ACCEPTANCE_MATRIX_R1.json`. Implementation must not be called complete until all applicable rows are proven against the exact implementation candidate, including behavioral, race/concurrency, receipt/UNKNOWN-COMMIT, architecture/ownership, source-oracle, deterministic reload, lifetime independence, and broader regression gates.

## 14. Research gate conclusion

The CA7-4 mechanic/architecture contract is now sufficiently discriminated for implementation planning. No unresolved question requires inventing gameplay behavior, changing owner identity, changing the CA7-1 LIVE lifetime policy, or reopening CA7-2/CA7-3.

**Research gate: GREEN.**  
**Implementation state: NOT STARTED in this artifact.**
