# CA7-6 Preimplementation Contract R1 — Pass594-bound research closure candidate

Status: **RESEARCH_COMPLETE_CANDIDATE / PREIMPLEMENTATION_CONTRACT_FROZEN_CANDIDATE / IMPLEMENTATION_NOT_STARTED**

Stage: **CA7-6 — Effective Appearance Contribution & Cross-Phase Integration Fence**

This contract is candidate-bound to Pass594 and does not alter Pass594 authority by itself. It authorizes no product acceptance. User implementation authorization is external and may be exercised only after this research package survives falsification and an independent preimplementation reality check.

## 1. Exact authority binding

- Operational PassMap: `gxb-backend-pass-594.0-passmap.zip`
  - SHA-256 `1d946e04f322a272eb79661727a1a6cbd00c5469ec8fbfa46119ee7ae2f55c37`
- Accepted backend: `gxb-backend-v2-v0.84.0-pass594-ca7-5-local-accepted.zip`
  - SHA-256 `4f4db4fea63bf7368e3ab8207a0242b002a02ef45b2234a128143f73f4b6d16f`
  - Git HEAD `5807ba882ccfeda2daf0e54966ee5fbed2da86ea`
  - product tree `2fba04ab6d0cb8159e46d1d0fd30ca9b29e2435cf2cf92eb856b6fbbd38b4b45`
- Current client/source oracle: `all-assest-rechecked-1.zip`
  - SHA-256 `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`
- Historical v1.164 differential oracle: `gxb-old-client-v1.164.0-research-corpus.zip`
  - SHA-256 `d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1`
- Accepted CA7 content capability remains `CHARACTER_APPEARANCE_CA7`; exact revision is caller-supplied to contribution readers. No CA7-6 API may rediscover `ActiveRevision` internally.

Companion frozen research artifacts:
- `CA7_6_SOURCE_ORACLE_R2.json`
- `CA7_6_CROSS_PHASE_PRESERVATION_MATRIX_R2.json`
- `CA7_6_ACCEPTANCE_MATRIX_R2.json`
- `CA7_6_CA8_SNAPSHOT_SEAM_R1.md`

## 2. Scope and non-scope

CA7-6 is an **integration/read-contract fence**, not a new gameplay mechanic or durable owner.

Owned work if implementation is entered:
1. introduce typed, read-only Hero/Pet appearance contribution values and provider interfaces;
2. implement caller-queryer/exact-revision/caller-observation-time contribution readers by composing existing canonical owner + entitlement reads and existing effective appearance builders;
3. add candidate-bound source/architecture guards for the frozen CA7-6 boundaries;
4. add integration tests that prove CA7↔CA6 Practice version semantics and CA1–CA5 preservation using real services where locally feasible;
5. preserve all CA7-1 through CA7-5 mutation/wire/replay semantics unchanged unless a demonstrated defect requires reopening them.

Explicitly out of scope:
- no new gameplay MID or stock wire field;
- no schema migration;
- no Cosmetics aggregate or child `state_version` owner;
- no CA8 aggregate snapshot implementation, battle resolver or mode policy;
- no new scheduler/expiry job;
- no new receipt family or economy owner;
- no Commerce pricing/settlement implementation;
- no Library/I9N `board_*` persistence/policy implementation;
- no reinterpretation/reactivation of unreachable `PetAttributeWindow0` ordinary-Pet MID60/61 code;
- no claim that CA7-7 native PostgreSQL/River or W2 stock-client gates passed.

## 3. Canonical ownership and revision contract

CA7-1 ownership remains authoritative:
- Hero owns ordinary/current skin selector, illusion selector, skin entitlements and Normal-Hero paid type-2 LIVE state.
- Pet owns active home style and owned home styles.
- Hero/Pet owner `state_version` remains the only Character coherence revision for these facts. CA7-6 MUST NOT create a parallel child revision.
- CA8 is a future immutable composite snapshot consumer only.
- I5 owns balances/stacks; Commerce is a caller/settlement owner only; I9N owns Library board presentation persistence.

CA7-6 contribution reads are observations. They do not mutate the owner and therefore do not advance `state_version`.

## 4. Frozen contribution semantics

The minimum semantic values are equivalent to:

```go
type HeroAppearanceContribution struct {
    OwnerID         int64 // partner_id
    TableID         int64 // current Hero table/form
    OriginTableID   int64 // immutable appearance-family origin
    ContentRevision string
    Appearance      EffectiveHeroAppearance
}

type PetAppearanceContribution struct {
    OwnerID         int64 // pet_id
    TableID         int64 // current Pet table/form
    OriginTableID   int64 // immutable appearance-family origin
    ContentRevision string
    Appearance      EffectivePetAppearance
}
```

Exact identifier spelling may vary during implementation only if semantics remain equivalent and the acceptance matrix/architecture guard is updated consistently.

Validation requirements:
- positive owner/current/origin identifiers;
- exact lowercase 64-hex content revision;
- nested effective appearance validates;
- nested `OwnerStateVersion` is the same owner row used to populate identity fields;
- nested `ObservedAt` is the caller-supplied observation instant normalized by existing effective builders;
- contribution identity is validation/provenance only; CA2/CA3 remain roster authority.

No separate clone API is required solely for the provider handoff because existing effective builders allocate new slices and copy timed expiry values. The provider returns newly materialized values. A later CA8 seal owns the immutable copied value it stores.

## 5. Frozen provider contract

Semantically equivalent provider methods:

```go
HeroAppearanceContributionTx(ctx, q, playerID, partnerID, exactRevision, observedAt)
PetAppearanceContributionTx(ctx, q, playerID, petID, exactRevision, observedAt)
```

Requirements:
1. caller supplies non-nil `tx.Queryer`;
2. caller supplies exact lowercase 64-hex revision and non-zero observation instant;
3. provider validates `CHARACTER_APPEARANCE_CA7` capability for that exact revision through the caller queryer;
4. read canonical owner through the caller queryer;
5. read CA7 child entitlements through the same queryer;
6. Hero: resolve `HeroKind` from the owner's immutable `CreationContentRevision` before qualifying paid LIVE; do **not** reinterpret kind from the current appearance revision;
7. call existing `BuildEffectiveHeroAppearanceTx` / `BuildEffectivePetAppearanceTx` with the caller exact revision and observation instant;
8. return a newly allocated validated contribution.

Forbidden inside the provider:
- `ActiveRevision` rediscovery;
- `tx.Runner` or nested transaction creation;
- owner locks or writes;
- receipt reads/writes;
- I5/economy calls;
- live clock reads;
- scheduler registration;
- battle/mode materialization;
- Library or Commerce policy.

The exact CA8 aggregate transaction/isolation level is deliberately **not frozen by CA7-6**. CA7-6 guarantees composability with one caller queryer, one exact revision and one caller observation instant. CA8's own research must choose the final coherent aggregate-snapshot orchestration.

## 6. Content/time and malformed-state semantics

Existing CA7-1/2 rules remain unchanged:
- timed entitlements are qualified at one stable caller observation instant;
- permanent dominates timed; expired timed facts are ineffective without requiring physical deletion;
- stale ordinary selector projects effective `0` without a read-side write;
- stale explicit illusion selector projects `-1`/inherit without a read-side write;
- effective Pet style is `0` or a qualified owned style;
- output skin/LIVE/style ordering remains deterministic;
- returned projection arrays are never ingested as durable authority.

A contribution is a frozen observation value. Later durable mutation or wall-clock expiry cannot mutate an already-returned value in memory.

## 7. Presentation versus combat boundary

Current source oracle requires preserving distinct axes:
- current Hero presentation model is illusion-aware through `getModelID()`;
- current battle skin-skill selection uses ordinary-skin/base identity through `getOldModelID()` / `getSkillModelID()`;
- v1.164 did not have the same split, making this a meaningful current-client differential;
- paid type-2 LIVE/dynamic-card state has no discovered current `lib/battle` consumer;
- Pet home-style state has no discovered current battle/model consumer.

Therefore CA7-6 MUST NOT expose or derive one universal `effective_model_id`, illusion-derived skin-skill identity, LIVE combat modifier, or Pet-home-style combat modifier. Future CA8/battle materialization may use the pinned content revision to materialize resolver input while preserving these axes.

## 8. CA6 Practice reconciliation and cross-service proof

Historical roadmap wording referring to a pending MANUAL/TICKET/AUTO proposal is superseded for CA7-6 interpretation only:
- accepted pending kinds are MANUAL and TICKET;
- AUTO explicitly creates no pending proposal.

MANUAL/TICKET:
- proposal captures owner `ActorStateVersion`;
- SAVE locks Character owner first and rejects if the locked owner version differs before Practice apply/proposal deletion;
- an actual state-changing CA7 mutation therefore stales a pending proposal;
- a genuine CA7 semantic no-op does not advance owner version and must not invalidate an otherwise valid proposal.

TICKET accounting:
- ticket debit occurs during proposal generation;
- if CA7 later stales the proposal, rejected SAVE performs no second debit, no refund of the committed generation ticket and no proposal deletion.

AUTO:
- no pending proposal exists;
- AUTO and CA7 both compose through the same Hero410/Pet430 owner lock/CAS authority;
- local CA7-6 proof is limited to architecture plus deterministic serialized-order harness behavior;
- exact concurrent PostgreSQL row-lock behavior remains deferred to CA7-7 and MUST NOT be claimed from local mocks.

Cross-service integration tests should live in a neutral/external test package or another layering-safe surface that can compose Character Hero/Pet and Practice services without introducing reverse production dependencies.

## 9. CA1–CA5 preservation contract

CA7-6 must prove rather than merely assume the accepted narrow-write architecture:
- CA2 Hero core/progression mutation preserves CA7 selectors/child entitlements; CA7 mutation preserves Hero identity/progression fields;
- CA3 Pet core/progression/show mutation preserves CA7 style state; CA7 mutation preserves Pet core/progression/show fields;
- CA4 equipment/Fumo mutation preserves CA7 state and CA7 mutation preserves equipment/Fumo;
- CA5 saved-preset/reference state remains a separate owner; CA7 mutation does not rewrite preset roots/lanes/references and CA5 changes do not rewrite CA7 durable state;
- shared Hero/Pet `state_version` is the intentional coherence/invalidation coupling, not permission for foreign-owner field writes.

Static SQL/query guards remain required in addition to real locally feasible integration tests.

## 10. Commerce and Library boundaries

Commerce:
- preserve the accepted `TxPermanentSkinMaterializer` Character-side seam;
- caller owns transaction/retry/receipt and future Commerce settlement/pricing;
- Character alone validates/grants the skin entitlement and advances Hero owner CAS;
- CA7-6 adds no second materializer or foreign-owner SQL.

Library/I9N:
- MID835 `board_partner`, `board_card`, `board_model_id` remain separate Library persistence/policy facts;
- CA7 contribution exposes qualified Hero appearance provenance/state only;
- do not add `board_*` durable Character ownership or invent a universal board-card formula.

## 11. Full source-oracle fence

The frozen source oracle covers all eight current appearance MIDs: 60, 61, 68, 69, 1893, 1894, 1895, 2979, plus bounded presentation/battle/Library/Pet consumers across the full 4,370-file current tree.

`PetAttributeWindow0.lua` classification remains **STRONG_INFERENCE: unreachable retained source** because current route registration selects `PetAttributeWindow` and tree-wide search found no external reference to the `0` file. This is not a claim that original-server Pet ordinary skins never existed; it is a fence against reactivating unreachable current-client behavior without new evidence.

## 12. Expected implementation footprint

If this research closes GREEN, the expected implementation is deliberately small:
1. add contribution structs/provider interfaces near existing `characterasset.PracticeContribution` downstream contracts;
2. add Hero/Pet contribution readers reusing existing transactional stores/content and effective builders;
3. add focused unit tests for validation, provenance, exact revision, observedAt, malformed selectors, expiry freeze and deterministic ordering;
4. add neutral cross-service CA6 Practice integration tests plus preservation/query guards;
5. add candidate-bound CA7-6 architecture/source-oracle validator(s) and narrow successor fences;
6. no migration, new MID, receipt family, scheduler or production battle/Commerce/Library subsystem.

## 13. Mandatory implementation gate

CA7-6 cannot receive local acceptance until every LOCAL_REQUIRED row in `CA7_6_ACCEPTANCE_MATRIX_R2.json` is evidenced and an independent postimplementation reality check rereads the accepted authority/source plus produced code.

CA7-7 exact/native accumulated PostgreSQL/River proof and W2 physical unmodified-stock-client proof remain deferred and must not be marked passed by CA7-6 evidence.
