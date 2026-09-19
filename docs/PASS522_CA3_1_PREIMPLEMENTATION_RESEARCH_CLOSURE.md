# Pass522 — CA3-1 targeted pre-implementation research closure

## Outcome
**GREEN, candidate-bound.** Exact Pass520 backend accepted by Pass521 plus exact current `src_64` are sufficient to implement CA3-1 Pet identity/owner/roster/projection foundation without inventing Pet acquisition, starter-entitlement, hatch-economy, progression, skill, equipment/Fumo, Practice, style, Pet Campaign, rental, or Cabin semantics.

## Candidate identity
- Accepted backend: `gxb-backend-v2-v0.64.1-pass520-ca2-accepted-pass521.zip`
- SHA-256: `58dc3f31d3e8ae82ea302cad4d7dcce2c958d9218c4e423f4af97a5cf018f830`
- Implementation revision: `3813d389f577a90c9771f396a197c8ea926e0a602869e656bed2d557b5c01686`
- Current src_64 archive SHA-256: `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`
- Historical v1.164 archive SHA-256: `d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1`

## SOURCE_FACT — Pet identity and roster
- `Pet` carries an independent `pet_id` and `table_id`; `pet_id=-1` is the uncollected/display sentinel and is not an allocator seed.
- `SelfPlayer` hydrates collected Pets from the MID780-shaped `pets` array both during game-start embedded hydration and explicit MID780 load.
- Explicit MID780 reassigns `player_id` after hydration; MID1 embedded MID780 does the same.
- `Pet:populate()` is the canonical collected-Pet private hydration path. It accepts source-shaped defaults for absent later-domain fields.
- Pet awakening preserves the same owned Pet instance while changing `table_id`; current source exposes `first_table_id`/`awaken_table_id` lineage. Therefore current template identity cannot safely be the durable uniqueness key.
- `Pet:isBorn()` returns `is_show`; `is_born` has no independent gameplay consumer found in current or v1.164 Lua beyond hydrate/serialize compatibility.
- `birthday` and `is_show` are required to reconstruct passive incubation/display state on reload; CA3 roadmap explicitly allows source-qualified Pet display/show state to remain Pet-core.

## STRONG_INFERENCE — durable lineage
Use immutable `origin_table_id` as Pet lineage identity: base row origin is its own table ID; awakened row origin is source `first_table_id`. Enforce one live Pet per `(player_id, origin_table_id)`. Preserve `pet_id` as a distinct opaque owned-instance identity and `table_id` as current form/template.

## IMPLEMENTATION_DECISION — allocator
Original server Pet allocator start is UNKNOWN. Reuse the already-accepted CA2 reconstruction policy: a monotonically increasing positive per-player allocator beginning at `1`, advanced under the PetRoot lock. Do not claim this seed as original-server fact.

## SOURCE_FACT / DISPROVEN — capacity
`MAX_PET_NUMBER=1` is used for formation/team Pet selection, not owned-roster capacity. No source-qualified owned Pet roster capacity was recovered. CA3-1 therefore introduces no capacity field or guessed limit.

## Source-qualified CA3-1 persistence boundary
Required canonical Pet root:
- `player_id`
- `next_pet_id`
- `state_version`
- timestamps

Required canonical Pet instance:
- `player_id`
- `pet_id`
- `origin_table_id`
- `table_id`
- `star`
- `level`
- `exp`
- `color`
- `birthday` as non-negative stock epoch-seconds value
- `is_show`
- `creation_content_revision`
- `state_version`
- timestamps

Explicitly not canonical CA3-1 state:
- `is_born` independent state machine
- skill levels (CA3-3)
- equipment/Fumo (CA4)
- Practice (CA6)
- styles (CA7)
- Pet Campaign/rental/Cabin/event state
- starter entitlement / first-free-hatch occurrence (CA3-2)

## Private projection contract
MID1 embedded `780` and explicit MID780 must project the same canonical Pet roster. Each Pet row must provide core fields `pet_id, table_id, star, lev, exp, color, birthday, is_show`. Stock-compatible neutral later-domain fields may be emitted as source-safe compatibility values (`is_born=0`, `skills=[1,1,1,1,1]`, `equips=[0,0,0]`, `fumos=[0,0,0]`, `practice_attr=[0,0,0]`) without creating canonical ownership. CA7 `active_style`/`pet_styles` remain omitted.

## Public/reference boundary
CA3-1 may expose typed Pet identity/summary/reference interfaces, but no universal public Pet DTO. Existing source consumers often need only `table_id/star/color`; later CA8/mode owners choose profile-specific immutable projections. CA5 owns actual atomic reference fencing; CA3-1 only provides the extension/lookup seam and activates no Pet removal operation.

## Content boundary
Extend the existing deterministic `tools/generate_builtin_content.py` compiler; runtime Lua parsing is prohibited. CA3-1 requires only immutable Pet core identity/content sufficient to validate current table IDs, derive lineage/origin and source initial-star metadata. Acquisition/hatch and progression content may be compiled in the same artifact only if separately capability-gated and unused by CA3-1; CA3-1 must not require their activation.

## Backend reconciliation
RUNTIME_OBSERVED on exact Pass520:
- Character lock band 400–599 exists; HeroRoot=400 and HeroInstance=410, leaving 420–599 unassigned.
- Existing `CharacterBootstrapPersistenceContributor` supports required owner-root creation in the caller-owned MID1 transaction.
- Existing `MID1DetailContributor` supports whole embedded-MID claims and rejects collisions before execution.
- Wave-S baseline currently owns `MID780 -> {pets:[]}` only as unopened-domain compatibility facade.
- Production router currently registers MID780 on LobbyDispatcher; CA3-1 must hand that explicit MID to a Pet dispatcher rather than double-registering.
- Existing content registry/compiler is deterministic and revision/capability-bound.
- No current non-test producer requires speculative Hero/Pet multiplexing of generic `PartnerEntity` grants.

## Lock plan candidate
IMPLEMENTATION_DECISION: allocate `PetRoot=420`, `PetInstance=430`, preserving Hero 400/410 and future Character band 440–599. CA3-1 reads do not acquire gameplay mutation locks. Future CA3-2/3 mutations must obey Character-before-I5 lock order.

## CA3 internal staging disposition
- CA3-1: identity, root, roster persistence, immutable core content, MID1.780 + MID780 private projection, typed reference seam.
- CA3-2: acquisition + starter occurrence + incubation/show lifecycle.
- CA3-3: self-contained base EXP/star/skill progression where qualified.
- MID785/MID790 full activation remains CA4-gated because source resets equipment/Fumo.

## Bounded unknowns preserved
- Original Pet allocator seed: UNKNOWN; explicit V2 reconstruction policy above.
- Owned Pet roster capacity: UNKNOWN/no evidence; no cap fabricated.
- Starter Ross entitlement and one-time free hatch durable occurrence owner: CA3-2 OPEN.
- Original MID782/MID789 server internals: CA3-2 reconstructed only after its own contract.
- `is_born` independent server meaning: UNKNOWN; no independent canonical state in CA3-1.
- Pet skill mutation details: CA3-3, not CA3-1.

## Exit criteria for CA3-1 local checkpoint
- migration/schema/sqlc/query-owner checks;
- deterministic Pet core source compiler/regeneration and relational verification;
- Pet root backfill/bootstrap with no starter Pet fabrication;
- pet_id allocation/origin uniqueness domain tests;
- MID1.780 and explicit MID780 parity/reload tests;
- neutral compatibility projection tests and CA4/CA6/CA7 ownership omission tests;
- route/contributor collision tests;
- source/hash/compiler/architecture guards;
- focused unit/race/vet/static and bounded full regression using exact candidate or explicitly labelled compatibility copy;
- independent post-implementation reality check.

## Next permitted action
Write/freeze the CA3-1 implementation contract and staged plan, perform independent preimplementation reality check, then seal HOT+COLD. Only after a GREEN seal may CA3-1 implementation begin.
