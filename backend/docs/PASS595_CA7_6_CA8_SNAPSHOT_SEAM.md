# CA7-6 → CA8 Snapshot Seam Research R1

Status: RESEARCH_DECISION_CANDIDATE / NOT_FROZEN / NO_IMPLEMENTATION_AUTHORIZATION

Authority binding:
- PassMap: gxb-backend-pass-594.0-passmap.zip, SHA-256 `1d946e04f322a272eb79661727a1a6cbd00c5469ec8fbfa46119ee7ae2f55c37`
- Backend: gxb-backend-v2-v0.84.0-pass594-ca7-5-local-accepted.zip, SHA-256 `4f4db4fea63bf7368e3ab8207a0242b002a02ef45b2234a128143f73f4b6d16f`
- Git HEAD: `5807ba882ccfeda2daf0e54966ee5fbed2da86ea`
- Active appearance capability revision bound by current accepted content: `ae577b8c9b9770f1d7a7dcf8335d9d36d27a15a687a12a5e5b01d97eca124116`

## 1. Owning-boundary conclusion

**IMPLEMENTATION_DECISION candidate, constrained by D03/D05/CA7-1:** CA7-6 should add only a typed, read-only Character appearance contribution seam. CA8 owns future aggregate snapshot orchestration and seal. CA7 must not create a second snapshot aggregate, transaction runner, lock-owning read subsystem, scheduler, battle resolver, or mode policy.

Evidence:
- D03: snapshot exporters return immutable typed state and owning revisions; entitlement/selection/derived projection are distinct.
- D05: snapshot orchestration obtains a coherent owner view, records revisions before seal, and resolver accepts only fully materialized immutable input.
- Existing CA6 Practice contribution providers require caller `tx.Queryer` + exact revision and do not own final battle composition.
- Existing MID1 Hero/Pet projections already read owner + child appearance state through one caller-owned queryer and one captured `observedAt` without opening another transaction.

## 2. Proposed contribution values

Exact Go spelling is not frozen yet, but the minimum semantics should be equivalent to:

```text
HeroAppearanceContribution
  OwnerID          partner_id
  TableID          current mutable Hero template/form
  OriginTableID    immutable Hero family/origin used by CA7 qualification
  ContentRevision  exact revision used for CA7 qualification
  Appearance       EffectiveHeroAppearance

PetAppearanceContribution
  OwnerID          pet_id
  TableID          current mutable Pet form
  OriginTableID    immutable Pet family/origin used by CA7 qualification
  ContentRevision  exact revision used for CA7 qualification
  Appearance       EffectivePetAppearance
```

`Effective*Appearance` already carries `OwnerStateVersion` and `ObservedAt`; duplicating these fields in the wrapper is unnecessary. `TableID` and `OriginTableID` are validation/provenance evidence, not new ownership. CA2/CA3 remain canonical roster owners.

Required validation:
- positive owner/current/origin identities;
- exact lowercase 64-hex revision;
- nested effective appearance validates;
- contribution was built from the same owner row whose state_version appears in nested appearance;
- Hero `Kind` remains content-derived internally and need not become a new durable contribution identity.

## 3. Proposed provider surfaces

Equivalent semantic interfaces:

```text
HeroAppearanceContributionTx(ctx, callerQueryer, playerID, partnerID, exactRevision, observedAt)
PetAppearanceContributionTx(ctx, callerQueryer, playerID, petID, exactRevision, observedAt)
```

Provider requirements:
1. require caller-owned non-nil `tx.Queryer`;
2. require exact revision and non-zero captured observation instant;
3. validate `CHARACTER_APPEARANCE_CA7` for that exact revision inside the caller queryer;
4. read canonical owner through the caller queryer;
5. read CA7 child entitlements through the same caller queryer;
6. Hero only: resolve `HeroKind` from the Hero's immutable creation revision, matching accepted `BuildRosterViewsTx` behavior, because paid type-2 LIVE qualification depends on kind;
7. call existing `BuildEffectiveHeroAppearanceTx` / `BuildEffectivePetAppearanceTx` with the caller's exact revision and observation instant;
8. return a newly allocated contribution; no writes, locks, receipts, economy access, clock reads, active-revision rediscovery, mode policy, or battle materialization.

The provider must not call `ActiveRevision`. The caller supplies the exact revision; this preserves R4 content-binding discipline and lets a future CA8 operation bind one revision once.

## 4. Immutability / aliasing

**SOURCE/CODE FACT:** current effective builders allocate new output slices; Hero expiry pointers are copied into new UTC `time.Time` values. They do not expose durable child-row slice backing arrays.

**IMPLEMENTATION_DECISION candidate:** a CA7-6 contribution reader should return a newly built value and not require a second clone API merely for provider-to-CA8 handoff. This follows the accepted CA6 Practice contribution precedent, which also returns freshly materialized slices without a `Clone()` method. CA8 still owns its sealed snapshot value and must not retain mutable aliases supplied by unrelated external inputs.

## 5. Content/time coherence

CA7-6 freezes only these provider obligations:
- exact revision supplied by caller;
- one caller-supplied `observedAt` used for all appearance validity decisions;
- owner state_version returned with the effective appearance;
- no live clock lookup inside provider;
- no active-revision lookup inside provider.

**DEFERRED TO CA8 RESEARCH:** the exact transaction isolation/profile used by aggregate snapshot orchestration. A single read-only PostgreSQL Repeatable Read transaction is a strong candidate because it naturally prevents owner/child torn reads across multiple Character providers, and V2 already uses read-only Repeatable Read projection transactions. However D05 mandates a coherent view, not a specific isolation level, and CA8 has its own mandatory research cycle. CA7-6 must remain isolation-neutral beyond requiring one caller queryer/exact revision/observation instant.

## 6. Battle materialization boundary

CA7 contribution is not a generic `effective_model_id` or battle result.

Current source facts require preserving distinct axes:
- Hero presentation model: illusion-aware `getModelID()`;
- Hero combat skin-skill matching: ordinary-skin `getOldModelID()` via `BaseFighter.getSkillModelID()`;
- dynamic-card/LIVE: current tree shows presentation/UI consumption, no `lib/battle` state consumer;
- Pet home style: current Pet combat/display model derives from Pet table/star, not `active_style`.

CA8/future battle materialization may use the pinned content revision to turn qualified CA7 facts into fully materialized immutable resolver input. CA7 must not absorb D05 battle policy.

## 7. Cross-provider revision check

Because CA2/CA3/CA4/CA6/CA7 all observe the same Hero/Pet aggregate `state_version`, future CA8 orchestration can compare contributions for the same owner. CA7-6 should expose the revision but must not itself decide the aggregate consistency algorithm. Under one coherent caller snapshot, equipment/practice/appearance observations for one owner should naturally carry the same owner version; mismatch is a future CA8 fail-closed signal, not permission to merge mixed revisions.

## 8. Explicitly out of CA7-6

- implementing CA8 aggregate snapshot transaction;
- choosing final CA8 transaction isolation as accepted authority;
- actor-origin owned/borrowed/trial/NPC orchestration;
- final stat merge order / resolver input schema;
- Commerce pricing or settlement;
- Library board-girl/card persistence;
- physical stock-client proof;
- CA7-7 accumulated native PostgreSQL/River proof.
