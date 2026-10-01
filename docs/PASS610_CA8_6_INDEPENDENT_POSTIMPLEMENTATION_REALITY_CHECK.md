# CA8-6 Independent Postimplementation Reality Check

Status: **GREEN for local-acceptance preparation; exact/native aggregate remains deferred to CA8-9.**

Candidate base: Pass607 Git `12ed1007576e3b5174e32067dfe5f966d5c74762`
Authority: sealed Pass609 CA8-6 research/implementation contract and 36-point acceptance matrix.

## Scope and limitations

- This check independently re-read the sealed Pass609 implementation contract, acceptance matrix, staged plan, preimplementation reality record, additional research integration, CA8 stage roadmap, produced code/tests/guards, and relevant current + V1.164 source-oracle evidence.
- The check was performed by the same agent after implementation; no separate human or independent reviewer is claimed.
- Exact canonical Go execution was attempted first. It is environment-blocked because the sandbox has Go 1.23.2 while the pristine candidate pins `go 1.26.0` / `toolchain go1.27.1`, and the sandbox cannot download the pinned toolchain. Canonical `go.mod`, `go.sum`, and `.go-version` remain byte-identical to Pass607.
- Disposable Go-1.23.2 execution is `COMPATIBILITY_COPY_ONLY`. It does not satisfy CA8-9 exact/native/PostgreSQL/River proof, CA8-E, or W2 stock-client proof.

## Independent code/source findings

1. **Typed owned entry — GREEN.** `PublicShowcaseCharacterReader` accepts only caller-qualified `character.HeroRef`/`character.PetRef` plus `CoherentReadScope`; it does not parse showcase indices, raw table IDs, profile player IDs, rental collections, or wire payloads.
2. **Canonical owner reuse — GREEN.** Hero/Pet reads delegate directly to the accepted `OwnedCompositeBuilder`; CA8-6 introduces no parallel base/equipment/practice/appearance read path.
3. **Ownership/coherence fence — GREEN.** Success additionally requires `ActorOriginOwned` and exact `Base.Ref` equality. Borrowed, trial, NPC/template and synthetic projections have no entry path.
4. **Provider dispositions — GREEN.** Equipment, Practice and Appearance observations are projected without reclassifying consumer requiredness. Existing hard errors/coherence failures propagate. CA8-6 never assigns `ProviderRequiredButUnavailable`.
5. **Hero skills residual — GREEN.** Hero skills are represented only by `HeroSkillsDisposition = UNAVAILABLE_UNQUALIFIED`; no skill values or client defaults are fabricated.
6. **Pet base facts — GREEN.** Pet Skills/Birthday/IsShow remain inside canonical `PetBaseObservation`; no duplicate Pet skill provider is introduced.
7. **Identity preservation — GREEN.** Tests prove distinct persistent Hero/Pet instance IDs remain distinct even when table IDs match.
8. **Defensive-copy behavior — GREEN.** Returned nested Equipment/Practice/Appearance data can be mutated without altering provider fixtures or a later fresh read. CA8-6 relies on the already-accepted `OwnedCompositeBuilder` clone boundary rather than duplicating clone logic.
9. **No mutation/recovery obligations — GREEN/N/A.** CA8-6 is read-only: no write, receipt, queue obligation, recovery state or retry-side effect exists. A reload/fresh read simply re-enters the canonical owned builder under a caller-supplied coherent scope.
10. **Consumer boundary — GREEN.** There is no runtime/public-profile activation in this candidate. I7B still owns showcase selection/index resolution, privacy/publication, public DTO/wire/cache/realtime, later-provider endpoint requiredness and versioned compatibility policy.
11. **Source differential — GREEN.** Current and V1.164 owned-selector evidence, PersonDisplay request continuity, current 5-visible/6-stored versus old 6-visible behavior, current optional-force delta, Bookmark delta, and client model defaults are rechecked without claiming original-server response truth.
12. **Unknown/private-policy discipline — GREEN.** Bookmark/MID3116 ownership remains unresolved and absent. No CA8-6 private-server response policy was added; unrecovered MID1829/MID1838 optional emission remains a future I7B compatibility-policy seam if source recovery is exhausted.
13. **Architecture fence — GREEN.** No SQL/schema/migration, transaction runner, lock, fresh clock, ActiveRevision lookup, MID/protocol/wire handler, public-profile persistence, Guild Girls Offer/Tutor-BFF business logic, final force/stat compiler, CombatSnapshot/hash/RNG/resolver or entity-output ownership appears in the implementation.
14. **Predecessor preservation — GREEN.** Accepted CA8-2/3/4/5 product seams and canonical dependency/toolchain pins are unchanged.
15. **Reopen triggers — NOT FIRED.** Implementation required no raw showcase parsing, borrowed/synthetic acceptance, Hero-skill provider promotion, CA8-6 requiredness assignment, wire/privacy/cache/final-stat logic, or contradiction of `CoherentReadScope` / `OwnedCompositeBuilder` semantics.

## Executed evidence

- Canonical static/source-oracle/policy/query/generation checks: GREEN.
- Exact canonical Go execution: **ENVIRONMENT_BLOCKED**, not a test failure.
- Fresh disposable compatibility-copy focused Character + archguard tests: GREEN.
- Focused compatibility-copy race: GREEN.
- Focused compatibility-copy vet: GREEN.
- Whole-tree compatibility-copy `go test ./...`: GREEN.
- Whole-tree compatibility-copy `go vet ./...`: GREEN.
- Package-by-package compatibility regression: **94/94 packages GREEN**.
- Compatibility-copy `go test -race ./internal/application/...`: GREEN.
- Cumulative validators/source oracles were executed in bounded batches after wall-clock timeouts; every resumed stage was explicitly GREEN. Timeouts themselves are not counted as proof.

## Conclusion

CA8-6 is a narrow Character-owned public/showcase read facade over accepted owned-character truth. It satisfies the sealed Pass609 contract without creating a second owner or leaking I7B/Guild/battle responsibilities into Character Asset. The candidate is eligible for local-acceptance identity freezing and PassMap sync. CA8-9 exact/native aggregate proof, CA8-E whole-phase exit, and W2 unmodified-stock-client proof remain mandatory and unpassed.
