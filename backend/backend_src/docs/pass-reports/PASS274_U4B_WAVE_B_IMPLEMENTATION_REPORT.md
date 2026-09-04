# Pass274 / U4B Wave B — Typed HTTP Semantics + Mission/BattlePass Projection

Wave B extends the existing request-scoped semantic bus rather than replacing ResponseProjector or introducing persistent UI state.

Implemented:
- typed GlobalSemanticEnvelopeAssembler behind RequestServices.apply_semantic_deltas();
- fail-closed unknown semantic channel consumption;
- profile-gated semantic sidebands while preserving explicit domain fields;
- read-only GenericRedmarkProjectionService for Function 27 Mission and Function 97 BattlePass;
- Mission 2704 Story and 2705 ordinary/twice Awakening derivation; Pet Awakening excluded;
- BattlePass 2801/2802 current-src_64-derived predicates; 2803 not persistent;
- MID2560/bootstrap use derived generic redmarks rather than legacy PlayerState.redmarks authority;
- runtime dirty-family replacement emits empty-list clears;
- current-src_64 generated battle-pass source catalog.

Current-source reconciliation:
- ordinary and twice Awakening share client TaskType.AWAKE / redmark 2705;
- Pet Awakening remains explicitly deferred and cannot contribute;
- BattlePass >=90 awarded-level behavior retains exact 10-level-gap quirk;
- response.redmarks_ uses string keys "27" and "97" for direct current Backend.lua lookup compatibility.

Not implemented: Wave C hydration/deferred adapters/MessagePush mutation; Wave D/E realtime; client patches.
