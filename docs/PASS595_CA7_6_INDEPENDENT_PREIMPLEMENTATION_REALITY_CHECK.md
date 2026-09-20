# CA7-6 Independent Preimplementation Reality Check R1

Status: **GREEN_FOR_RESEARCH_CLOSURE / IMPLEMENTATION_PROOF_STILL_REQUIRED / NO_LOCAL_ACCEPTANCE CLAIM**

Authority reread: Pass594 unified PassMap and accepted v0.84.0 backend; CA7-1 ownership/time/content/revision contract; CA6 Practice accepted code; CA7-5 closure; full current `src_64`; v1.164 differential corpus; R2 source/preservation/acceptance artifacts; CA7-6 contract candidate.

## Independent conclusions

1. **No new durable owner is justified.** Accepted CA7-1 already assigns appearance facts to Hero/Pet and uses the owner `state_version` as the only coherence revision. The proposed contribution seam is read-only and compatible with that model.
2. **The proposed read seam is implementable without a nested transaction.** Character stores already expose `ReadHeroByPartnerIDTx`, `ReadPetByIDTx` and transactional entitlement readers. Content store already exposes `AppearanceRevisionTx`, `HeroKindTx` and exact-revision appearance lookups. Existing `BuildRosterViewsTx` proves the Hero creation-revision/current-revision split in production code.
3. **Hero kind provenance is not optional.** Paid type-2 LIVE qualification depends on Hero kind, while kind is reconstructed from immutable `CreationContentRevision`. Reusing the current appearance revision for kind would contradict accepted bootstrap behavior.
4. **CA8 policy is not prematurely frozen.** Requiring caller queryer + exact revision + observedAt is enough for CA7 composability. Final CA8 isolation/snapshot algorithm remains a later CA8 decision.
5. **Presentation/combat axes must stay distinct.** Current source explicitly routes presentation through illusion-aware `getModelID()` and skin-skill matching through `getOldModelID()`/`getSkillModelID()`. v1.164 differential confirms this is not safe to collapse into one model field.
6. **LIVE and Pet style remain appearance facts.** Full current-tree searches found no `lib/battle` dynamic-card or `active_style` consumer. This constrains current-client compatibility without claiming original-server motive.
7. **The stale Pet ordinary-skin branch is not a current reachability contract.** `PetAttributeWindow0` is unreferenced outside itself while the current window table routes to `PetAttributeWindow`. Re-activating MID60/61 Pet ordinary skins would violate the current source oracle absent new evidence.
8. **CA6 roadmap wording required reconciliation.** Accepted CA6 has only MANUAL/TICKET pending proposals. AUTO has no pending proposal and locks the same owner. The R2 matrix correctly separates stale-proposal and serialization obligations.
9. **TICKET accounting is correctly bounded.** Ticket consumption occurs at generation; stale SAVE after a CA7 mutation must not refund or debit again and must reject before proposal deletion.
10. **Cross-phase preservation is structurally credible but still needs implementation proof.** SQL/query families are narrow and share only owner revision intentionally. Static evidence is sufficient to freeze the test contract, not to mark the future integration rows passed.
11. **Commerce/Library boundaries are implementable without fabricating downstream subsystems.** Existing `TxPermanentSkinMaterializer` is the required Character write seam; Character SQL contains no Library `board_*` ownership.
12. **No schema/MID/receipt/scheduler change is required by the research design.** The expected production footprint is a small typed contribution/read seam plus tests/guards.

## Acceptance-row preimplementation disposition

- A76_01: **GREEN research evidence** — exact artifacts/hashes independently verified.
- A76_02–A76_06: **DESIGN GREEN / implementation proof pending** — existing builders/stores/content seams support the required implementation without ownership change.
- A76_07–A76_09: **GREEN source/design evidence / implementation guard pending**.
- A76_10–A76_14: **CONTRACT GREEN / cross-service implementation tests pending**. A76_14 native PostgreSQL concurrency remains explicitly deferred to CA7-7.
- A76_15–A76_17: **STRUCTURAL GREEN / real preservation tests pending**.
- A76_18–A76_20: **GREEN research evidence / architecture guard pending**.
- A76_21–A76_23: **DESIGN GREEN / implementation tests/guards pending**.
- A76_24: **DEFERRED BY DESIGN** — CA7-7 and W2 remain open.
- A76_25: **PREIMPLEMENTATION HALF GREEN** — this report satisfies the preimplementation reread; postimplementation half remains mandatory.

## Falsification result

Standalone `check_ca7_6_research.py` passes on exact authority/source/backend. Three intentional corruptions were each rejected:
- MID2979 protocol identity corruption;
- CA6 AUTO no-pending contract corruption;
- CA8 isolation-scope fence removal.

This demonstrates that the research checker is not merely a happy-path recognizer.

## Remaining unknowns / limits

- Original-server motive for the current presentation/combat split remains UNKNOWN.
- Original-server numeric error identities remain governed by prior CA7 bounded-unknown policy.
- Exact CA8 aggregate transaction/isolation remains deferred to CA8 research.
- Exact accumulated PostgreSQL/River concurrency remains CA7-7; physical stock-client proof remains W2.

## Verdict

**GREEN to seal CA7-6 preimplementation research.** No discovered contradiction requires reopening CA7-1 through CA7-5. The research design is narrow, implementable from the accepted Pass594 backend, and preserves existing ownership. This does **not** mark any future CA7-6 implementation row passed.
