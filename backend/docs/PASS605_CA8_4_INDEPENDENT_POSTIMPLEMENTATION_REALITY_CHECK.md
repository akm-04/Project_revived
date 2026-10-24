# CA8-4 Independent Postimplementation Reality Check

Status: **GREEN for local-acceptance preparation; exact/native aggregate remains deferred to CA8-9.**

Candidate base: Pass603 Git `76013e467b00ee973e570180cf84114e0d12a88e`
Authority: sealed Pass604 CA8-4 implementation contract/acceptance matrix

## Scope and limitations

- This is an independent reread of the sealed contract plus the produced code/tests and relevant current `src_64` evidence; it is not merely a test summary.
- Exact canonical Go 1.27.1 execution was attempted first but is environment-blocked because the sandbox has Go 1.23.2 and cannot download the pinned toolchain. Canonical pins were not edited.
- Disposable Go-1.23.2 compatibility-copy results are diagnostic only and do not satisfy CA8-9 exact/native/PostgreSQL proof.
- No CA8-5+, CA8-E, W2, GuildRental business integration, or stock-client acceptance is claimed.

## Acceptance matrix

- **A01 — GREEN:** Candidate starts from exact Pass603 Git 76013e467b00ee973e570180cf84114e0d12a88e; verified source oracle archives match sealed hashes c7e987..., d0a481..., 31729d....
- **A02 — GREEN:** QualifiedBorrowedHeroReference contains exact character.HeroRef plus BorrowedCapabilityProvenance.
- **A03 — GREEN:** QualifiedBorrowedPetReference contains exact character.PetRef plus BorrowedCapabilityProvenance.
- **A04 — GREEN:** Borrowed API accepts only typed qualified refs; product file contains no raw rent_* fields or client rental DTO.
- **A05 — GREEN:** BorrowedHeroTx/BorrowedPetTx emit ActorOriginBorrowed and preserve the supplied qualification value exactly; tests cover Hero/Pet.
- **A06 — GREEN:** Borrowed Validate requires Base.Ref == qualified ActorRef; CA8-3 also checks owner read base ref. Negative tests cover mismatch.
- **A07 — GREEN:** Projection delegates to CA8-3 Owned*Tx/Validate; equipment/practice/appearance state-version gates remain active. Negative tests cover mismatches.
- **A08 — GREEN:** Projection reuses same CoherentReadScope and CA8-3 practice/appearance content revision and ObservedAt gates. Negative tests cover content/time.
- **A09 — GREEN:** No CA8-4 reinterpretation of CreationContentRevision exists; accepted base observation is reused unchanged.
- **A10 — GREEN:** Nil optional providers remain UNAVAILABLE_UNQUALIFIED via CA8-3; explicit inactive preserved; hard errors propagate. Tests cover all three.
- **A11 — GREEN:** CA8-4 does not assign REQUIRED_BUT_UNAVAILABLE; architecture fence forbids assignment and CA8-3 validator rejects it.
- **A12 — GREEN:** Scope and qualification are validated before OwnerComposite calls. Spy tests confirm malformed Hero/Pet qualification performs zero owner reads.
- **A13 — GREEN:** Missing lender base/read error propagates and zero borrowed composite is returned; Hero/Pet tests cover fail-closed behavior.
- **A14 — GREEN:** Implementation is read-only wrapper; no borrower identity, roster/inventory write, SQL, persistence, reference rewrite, or ownership-transfer path.
- **A15 — GREEN:** No rental eligibility/membership/cost/mana/use/revocation state or logic; static/architecture fences cover known raw rental identifiers.
- **A16 — GREEN:** No mode HP/MP/total_hp state in implementation; architecture fence covers those identifiers.
- **A17 — GREEN:** No tx.Runner/Begin/Commit/Rollback/retry/receipt/lock code. Same caller CoherentReadScope is passed unchanged to accepted CA8-3 composition.
- **A18 — GREEN:** No migration/schema/MID/wire changes; no foreign-owner SQL. Migration high-water unchanged at 00030_ca7_2_appearance_foundation.sql.
- **A19 — GREEN:** No guild/modes imports or direct dependency. check_dependency_policy.py passes.
- **A20 — GREEN:** No pre-existing tracked product file changed; Super-Hero equipment semantics test passes; whole-tree compatibility regression passes.
- **A21 — GREEN:** Borrowed return path clones equipment/practice/appearance; Hero and Pet mutation tests cover slices/pointers/OwnedStyles.
- **A22 — GREEN:** No tutor/synthetic handling appears in CA8-4 implementation; source evidence keeps tutor rental distinct.
- **A23 — GREEN:** No stock aliases are accepted by API; only owner-scoped HeroRef/PetRef. Source aliases remain edge/mode concern.
- **A24 — GREEN:** Focused behavior/negative/architecture tests plus canonical static policy checks and compatibility race/vet are green.
- **A25 — GREEN_WITH_LIMITATION:** Canonical exact-toolchain execution attempted first and is ENVIRONMENT_BLOCKED (Go 1.27.1 unavailable offline). Disposable Go 1.23.2 compatibility copy passes focused race/vet/test, whole-tree test/vet, 94-package regression, and application race. This is COMPATIBILITY_COPY_ONLY; CA8-9 exact/native proof remains open.
- **A26 — GREEN:** Pass604 sealed authorization record is IMPLEMENTATION_AUTHORIZED_NOT_STARTED and predates this candidate implementation; scope remains CA8-4 only.

## Source-oracle differential

- Exact current/old/V1 oracle archive hashes match the sealed identities.
- CA2-3, CA3-3 and CA7-6 source-oracle checks pass.
- CA4-5 reports `generated content revision drift`; untouched Pass603 reports the exact same output.
- CA6-5 reports `Pet production route family drift`; untouched Pass603 reports the exact same output.
- Therefore neither historical oracle warning is promoted as a CA8-4 regression.

## Independent code conclusion

The implementation adds one typed read-only borrowed projection over accepted CA8-3 owner composition. It preserves lender-scoped `HeroRef`/`PetRef`, opaque qualification provenance, CA8-3 state/content/time/provider coherence and defensive-copy behavior. It introduces no rental-business ownership, borrower state, transaction ownership, SQL, migration, MID/wire, receipt, lock, or guild/mode dependency. The candidate is eligible to proceed to local-acceptance evidence/identity freezing, subject to final candidate metadata and snapshot checks.
