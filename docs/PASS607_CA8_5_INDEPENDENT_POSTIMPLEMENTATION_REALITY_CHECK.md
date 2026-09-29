# CA8-5 Independent Postimplementation Reality Check

Status: **GREEN for local-acceptance preparation; exact/native aggregate remains deferred to CA8-9.**

Candidate base: Pass605 Git `e2e2ed48e694f74d02e8e1b78aa7557dab186ff0`
Authority: sealed Pass606 CA8-5 implementation contract/acceptance matrix

## Scope and limitations

- This check independently re-read the sealed Pass606 CA8-5 contract/policy/acceptance matrix, Pass600 origin/consumer matrices, D03/D05, the Work Place time contract, the produced code/tests, and the relevant current `src_64` evidence.
- Exact canonical Go 1.27.1 execution was attempted first but is environment-blocked because the sandbox only has Go 1.23.2 and cannot download the pinned toolchain. Canonical `go.mod`, `go.sum`, and `.go-version` were not modified.
- Disposable Go-1.23.2 compatibility-copy results are diagnostic `COMPATIBILITY_COPY_ONLY` evidence and do not satisfy CA8-9 exact/native/PostgreSQL/River proof.
- No CA8-6+, CA8-E, W2, mode activation, or stock-client acceptance is claimed.

## Independent code/source findings

1. **Origin/identity — GREEN.** The product seam accepts only `TRIAL` or `NPC_TEMPLATE`, preserves them distinctly, and constructs operation-scoped identity from caller-qualified `LocalKey` plus the caller operation ID. The local key is only blank/bounds checked and is not normalized or inferred from `table_id`, `partner_id`, `pet_id`, or mode `init_id`.
2. **Qualification coherence — GREEN.** `SyntheticProfileProvenance` requires provider/profile revision, exact content revision, operation ID, and UTC qualification instant; materialization requires exact equality to `CoherentReadScope.ContentRevision`, `Operation.ID`, and `ObservedAt`.
3. **No hidden reads/ownership — GREEN.** `MaterializeSyntheticHero`/`MaterializeSyntheticPet` validate `CoherentReadScope` but never call `Queryer()`, discover ActiveRevision, open a transaction, sample a clock, acquire locks, write SQL, or create receipts.
4. **Typed base boundary — GREEN.** Hero/Pet base facts are explicit and owner-free. No fake `PlayerID`, `PartnerID`, `PetID`, `StateVersion`, `RawEquipmentState`, `PracticeContribution`, or appearance contribution is created merely to reuse owned-state validators.
5. **Payload boundary — GREEN.** Optional schema/revision/canonical bytes are cloned and preserved as an in-memory Character contribution envelope; CA8-5 does not interpret a universal feature formula, stock wire format, or final battle-stat blob.
6. **Lineage boundary — GREEN.** Optional owned source ref + StateVersion or template-only lineage is validated, cloned, and never dereferenced. This preserves Ragnarok/Tutor-style clone provenance without transferring ownership.
7. **Pet skill boundary — GREEN.** A qualified profile may omit typed base Pet skills; when present, the accepted `PetSkillLevels` validator applies. This avoids inventing one universal Pet formula while retaining typed facts where the profile owner supplies them.
8. **Battle boundary — GREEN.** No `CombatSnapshot`, `content_hash`, RNG, resolver, producer merge order, or battle admission ownership appears in CA8-5. Those remain downstream `BATTLE_STAT_PROVIDER_CORE`/I8 responsibilities.
9. **Source differential — GREEN.** Academy and Two Years remain template-ID oriented; Zhuge uses mode-local `init_id`; Sakura combines server START with content-derived synthetic opponents; Tutor clones owned/template state; Ragnarok copies owned `toParams()` into feature-local objects before normalization. These differences still support the sealed qualified-profile seam and contradict a universal historical synthetic-ID/formula contract.
10. **Accepted predecessor preservation — GREEN.** No tracked CA8-2/3/4 product file, migration, MID, adapter, query owner, or dependency pin is modified by the CA8-5 implementation.

## Executed evidence

- Focused compatibility-copy `characterasset` + `archguard` test: GREEN.
- Focused compatibility-copy race: GREEN.
- Focused compatibility-copy vet: GREEN.
- Whole-tree compatibility-copy `go test ./...`: GREEN.
- Whole-tree compatibility-copy `go vet ./...`: GREEN.
- Package-by-package compatibility regression: **94 packages GREEN**.
- Compatibility-copy `go test -race ./internal/application/...`: GREEN.
- Static dependency policy: GREEN.
- Schema/query ownership: GREEN.
- SQLC generation policy: GREEN.
- Reproducible postimplementation reality checker: **47/47 GREEN**.

## Conclusion

The implementation is a narrow, read-only synthetic Character projection seam over already-qualified inputs. It preserves the sealed operation/content/time provenance and `TRIAL` versus `NPC_TEMPLATE` distinction, performs defensive copies, and introduces no feature business ownership, durable synthetic owner, live owner/content lookup, persistence, transaction ownership, or final combat-stat authority. It is eligible for local-acceptance identity freezing and PassMap acceptance sync, while CA8-9/CA8-E/W2 remain open exactly as sealed.
