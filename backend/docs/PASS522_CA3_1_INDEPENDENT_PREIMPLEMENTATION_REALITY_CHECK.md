# Pass522 CA3-1 independent pre-implementation reality check

## Verdict

**GREEN.** The CA3-1 implementation contract is consistent with sealed Pass521 HOT/CURRENT authority, D03/D04 design authority, exact current `src_64`, historical-client differential evidence, and the exact Pass520-accepted backend. CA3-1 implementation may begin only after the Pass522 research/contract HOT+COLD seal.

This check independently reread authority/source/backend rather than treating the implementation plan as proof.

## Authority reread

Pass521 keeps `CHARACTER_ASSET_CORE` open, accepts CA1/CA2, and places CA3 at `PRE_IMPLEMENTATION_RESEARCH_RECONCILIATION`. CA3 requires a distinct Pet aggregate with durable `pet_id`, roster owner/root/allocator, narrower public projection, and a reference-guard extension seam. It explicitly excludes Pet Campaign, rental, Cabin/Event Centre, equipment/Fumo, Practice, styles and unqualified cross-owner advance behavior.

D03 requires Hero `partner_id` and Pet `pet_id` to remain distinct persistent identities, separate from template IDs; materialization/capacity/progression commands require command-specific evidence; bootstrap must reuse R2B contributor ports; no universal consume/transfer operation may be inferred. D04 requires typed persistent Pet references and forbids a universal busy flag; actual reference fencing belongs to the later formation/reference owner. The CA3-1 contract preserves all of these constraints.

## Source/effective-client reread

Exact current `Pet.lua` still separates `pet_id` from `table_id`, hydrates `birthday` and `is_show`, and uses `is_show` as the effective born/display fact. No independent gameplay consumer of `is_born` was found in either current or v1.164 Lua. Awakening preserves the Pet instance while changing current `table_id`; source `first_table_id`/`awaken_table_id` therefore supports an immutable lineage/origin key. MID1 embedded MID780 and explicit MID780 both hydrate the owned Pet roster through `Pet.populate()`.

The current Pet table parses to 54 rows in 27 base/awakened families. Source initial stars include both 1 and 3, so CA3-1 must compile source values rather than fabricate a universal initial star. `MAX_PET_NUMBER=1` remains formation/team selection evidence, not owned-roster capacity.

No original-server populated Pet payload fixture was recovered. That limits claims about optional wire-field presence, but it does not block the scoped projection because `Pet.populate()` supplies neutral defaults and CA3-1 activates no Pet mutation.

## Backend architecture reread

The exact Pass520 backend already provides the required architecture:

- Character lock ranks 400/410 belong to Hero; 420-599 remain unassigned within the CA1 Character band.
- `CharacterBootstrapPersistenceContributor` is caller-transaction-aware, required/fail-closed, and suitable for creating an empty Pet root without a second character initializer.
- `MID1DetailContributor` supports whole embedded-MID claims and rejects duplicate claims before execution.
- production currently routes explicit MID780 through `LobbyDispatcher`, while Wave-S projection returns the intentional unopened-domain `pets=[]` facade.
- immutable content uses deterministic source hashing, generated artifacts, revision/capability verification and explicit activation; startup installs a builtin but never switches an existing active pointer.
- Hero storage already demonstrates separate `sql/character` ownership, per-player root allocation, origin-family uniqueness and creation-content revision binding without foreign-owner SQL.

CA3-1 therefore reuses existing owners/ports rather than adding a second bootstrap system, a second content authority, or foreign-owner SQL.

## Content activation reality check and correction

The initial CA3-1 draft needed one explicit rollout clarification: a newly generated `PET_CORE_CA3` revision is installed but is not automatically activated on an upgraded database. This is intentional and matches the accepted CA2 activation law.

The final contract now states that CA3-1 roster reads do **not** require `PET_CORE_CA3` to be the active revision. CA3-1 creates only an empty Pet root and no Pet instances; MID1.780/MID780 merely project persisted rows and do not consult the current active Pet template catalog. Future CA3-2/3 creation or mutation must bind a qualified Pet-capable content revision and fail closed otherwise. Explicit host CAS remains the activation mechanism.

This avoids an accidental boot dependency on a capability the currently active Pass520 content revision does not contain.

## Identity/schema/lock reality

The proposed `player_pet_roots` + `player_pets` structure is consistent with accepted Hero ownership without conflating the two aggregates. `UNIQUE(player_id, origin_table_id)` follows the observed awakening lineage; `table_id` remains mutable current form and `pet_id` remains the stable instance identity.

Original Pet allocator seed is unrecovered. Reusing the explicit CA2 reconstruction policy—positive per-player monotonic IDs starting at 1 under the root lock—is acceptable as an `IMPLEMENTATION_DECISION`, not a source claim.

`PetRoot=420` and `PetInstance=430` fit the reserved Character band and preserve Hero 400/410. No current owner conflict was found. Future cross-owner CA3-2/3 operations still obey Character-before-I5 lock order.

The owner does not contain capacity because owned Pet capacity remains UNKNOWN and no source evidence requires one.

## Projection/reload reality

A CA3-1 detail contributor can own MID1 child `780` and an explicit Pet dispatcher can own MID780. Production must remove MID780 from `LobbyDispatcher` before registering the Pet dispatcher; duplicate routing/claims remain fail closed.

Core private projection is bounded to `pet_id, table_id, star, lev, exp, color, birthday, is_show`. Neutral compatibility values for later-domain arrays are projection-only facts and do not establish CA3 ownership. CA7 style fields remain omitted. CA3-1 exposes only typed Pet identity/summary lookup seams; CA5 later owns reference fencing and no Pet removal operation is activated here.

## Scope isolation reality

The following research remains intentionally outside CA3-1 and cannot leak into implementation:

- Function-38 activation/starter Ross occurrence and one-time free hatch;
- MID781 summon, MID782 acceleration and MID789 show mutation;
- Pet EXP/evolution/skill mutations;
- equipment/Fumo, formation fencing, Practice and styles;
- generic PartnerEntity production routing.

Thus unresolved CA3-2/3 mechanics cannot corrupt the foundation stage.

## Modularity question

If future evidence changes Pet acquisition, hatch timing, skills, equipment or public-mode projections, it can be added through the Pet owner/content capability, typed transaction ports, CA4/CA5/CA6/CA7 owners or profile-specific projection adapters. No unrelated Hero/I5/bootstrap foundation must be rewritten. This satisfies the lifecycle modularity requirement.

## Remaining bounded unknowns

- original Pet allocator seed;
- owned Pet roster capacity, if any;
- starter occurrence/function activation owner;
- first-free-hatch durable/reconnect semantics;
- independent original-server meaning of `is_born`;
- CA3-3 skill/progression details.

All are isolated from CA3-1 activation.

## Conclusion

No source/backend/authority conflict requires reopening exploratory CA3-1 research. The next permitted action is to seal Pass522 research/contract state, then implement **CA3-1 only**. Any implementation-time discovery contradicting this contract must reopen targeted research before affected code advances. CA3-2 and CA3-3 remain research-active and are not implementation-authorized by this verdict.
