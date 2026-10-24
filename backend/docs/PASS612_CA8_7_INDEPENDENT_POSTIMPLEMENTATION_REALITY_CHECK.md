# CA8-7 Independent Postimplementation Reality Check

Status: **GREEN for local-acceptance preparation; exact/native aggregate remains deferred to CA8-9.**

Candidate base: Pass610 Git `5b7458afbf75c085363c248831b26476cff99823`
Authority: sealed Pass611 CA8-7 research/implementation contract and 35-point acceptance matrix.

## Scope and limitations

- This check independently re-read the sealed Pass611 implementation contract, acceptance matrix, preimplementation reality record, CA8-7 research closure/source crosscheck, exact Pass610 CA8-1/3/4/5 implementation seams, produced code/tests/guards, and relevant current + V1.164 source evidence.
- The check was performed by the same agent after implementation; no separate human reviewer is claimed.
- Exact canonical Go execution was attempted first and is **ENVIRONMENT_BLOCKED** because the pristine candidate pins `go 1.26.0` / `toolchain go1.27.1` while the sandbox cannot download Go 1.27.1. `go.mod`, `go.sum`, and `.go-version` remain unchanged.
- Disposable Go-1.23.2 execution is `COMPATIBILITY_COPY_ONLY`; it does not satisfy CA8-9 exact/native/PostgreSQL/River proof, CA8-E, or W2 stock-client proof.

## Independent contract/code findings

1. **A01 scope witness — GREEN.** `BattleCharacterScopeWitness` is schema `ca8-7/v1` and carries exactly `OperationID`, `ContentRevision`, and UTC-normalized `ObservedAt` from a validated `CoherentReadScope`.
2. **A02 scope minimization — GREEN.** The witness exposes no Queryer, retry `Attempt`, `EntropySeed`, `StartedAt`, operation policy set, or transaction object.
3. **A03 owned Hero — GREEN.** `OwnedHeroTx` delegates to `OwnedCompositeBuilder`, preserves exact OWNED state and emits only `HeroSkillsDisposition=UNAVAILABLE_UNQUALIFIED` for the unqualified Hero-skill producer.
4. **A04 owned Pet — GREEN.** `OwnedPetTx` delegates to `OwnedCompositeBuilder`; canonical Pet base Skills/Birthday/IsShow and accepted Equipment/Practice/Appearance observations remain intact.
5. **A05 borrowed Hero — GREEN.** `BorrowedHeroTx` delegates to `BorrowedCompositeBuilder`, preserves exact lender `HeroRef` plus opaque capability provenance, and keeps Hero skills status-only unavailable.
6. **A06 borrowed Pet — GREEN.** Borrowed Pet delegation preserves lender/capability provenance and does not transfer ownership.
7. **A07/A08 synthetic Hero/Pet — GREEN.** Synthetic methods delegate to the accepted CA8-5 materializers and preserve TRIAL/NPC_TEMPLATE identity, profile provenance, payload and lineage. Scope witness is cross-checked against synthetic operation/content/time provenance.
8. **A09 typed-state fence — GREEN.** Six distinct origin/family facet types are exposed; no tagged mega-union can encode mixed owned/borrowed/synthetic states.
9. **A10 fail-closed behavior — GREEN.** Invalid scope/ref/spec/dependency fails before success; accepted composite coherence failures propagate; facet validation rejects synthetic scope drift and invalid schema/requiredness.
10. **A11 requiredness ownership — GREEN.** Product code contains no `ProviderRequiredButUnavailable`; unavailable Hero skills do not block consumers inside CA8-7. BattleStatProvider/I8 remains activation owner.
11. **A12 final compiler fence — GREEN.** No final stats/force or client `getTotalAttr()` formula exists in Character Asset. The source oracle uses client formulas only as dependency/freeze evidence.
12. **A13 snapshot/policy fence — GREEN.** No CombatSnapshot construction, aggregate CA8 hash, attrMD5 authority, RNG/rules/trust/entropy policy selection, attempt seal or resolver was introduced.
13. **A14 execution-scope fence — GREEN.** No nested transaction runner/begin/commit/rollback, fresh clock, ActiveRevision lookup, or content rediscovery exists.
14. **A15 persistence fence — GREEN.** No SQL/schema/migration/write/receipt/outbox/queue artifact was added.
15. **A16 foreign-owner fence — GREEN.** No Library/Cabinet/Dorm/Inscription/Course/ConquerSchool/WhiteAlbum/Element/Stone/Spirit final-stat reader is imported or called.
16. **A17 dependency direction — GREEN.** Character exposes a reader/facet and imports no I8/combat stat-provider application package; future consumer -> Character direction is preserved.
17. **A18 Hero Appearance — GREEN.** Accepted Hero Appearance observation remains inside owned/borrowed composites unchanged; current source still demonstrates skin/skin-skill battle semantics.
18. **A19 Pet Appearance — GREEN.** Pet Appearance is preserved without CA8-7 declaring Pet style battle-required.
19. **A20 skills boundary — GREEN.** Pet skills remain canonical base/profile facts; owned/borrowed Hero skill values are never fabricated from static/client defaults.
20. **A21 raw Equipment/Fumo/Spirit — GREEN.** Accepted raw Equipment state is passed through unchanged; CA8-7 performs no final interpretation.
21. **A22 Practice — GREEN.** Accepted Practice observation/disposition and scope content-revision coherence are inherited unchanged from CA8-3.
22. **A23 owned immutability — GREEN.** Focused proof mutates one returned nested Equipment slice and confirms a later materialization is unaffected.
23. **A24 borrowed immutability — GREEN.** Focused proof confirms returned borrowed nested state is copy-isolated and a later lender-fixture edit cannot rewrite an already materialized handoff value.
24. **A25 synthetic immutability — GREEN.** Synthetic feature payload remains deep-copied and opaque; mutation of caller bytes after materialization does not alter the handoff.
25. **A26 rental-policy fence — GREEN.** No rental eligibility, price, usage or borrower/lender mutation logic exists in CA8-7.
26. **A27 synthetic ownership fence — GREEN.** Trial/NPC profiles remain synthetic projections and are not coerced into owned Equipment/Practice/Appearance stacks or a universal stat formula.
27. **A28 source freeze/skills — GREEN.** Current + V1.164 `setupBattleAttrInfo()` freeze-before-global-buffs and Hero skill battle consumption were rechecked without claiming the Lua compiler is historical-server truth.
28. **A29 version boundary — GREEN.** Current-only Element/Spirit/WhiteAlbum/SuperHero producer evidence remains source-version-specific; no V1.164 promotion occurs.
29. **A30 Pet-style/attrMD5 boundary — GREEN.** Pet style remains non-required bounded-negative evidence; client `attrMD5_` stays a client-local integrity mechanism and is absent from product authority.
30. **A31 private-server-policy boundary — GREEN.** No private-server stat formula is introduced in CA8-7. If the official final compiler/order/rounding remains unrecoverable, that future policy remains BATTLE_STAT_PROVIDER_CORE/I8 `IMPLEMENTATION_DECISION` territory.
31. **A32 identity — GREEN.** Owned/borrowed persistent typed refs and operation-scoped synthetic identity remain structurally distinct; CA8-7 adds no table-ID identity shortcut.
32. **A33 focused proof — GREEN.** Character tests, CA8-7 archguard, static validator and exact current+V1.164 source-oracle checker pass.
33. **A34 test protocol — GREEN with limitation.** Exact canonical toolchain was attempted first and environment-blocked. Fresh compatibility copy changed only `go.mod` language/toolchain accommodation; focused test/race/vet, whole-tree test/vet, application race and 94/94 package regression pass.
34. **A35 lifecycle/reality — GREEN locally.** No Pass611 reopen trigger fired. Exact/native CA8-9, CA8-E whole-phase exit and W2 unmodified-stock-client proof remain mandatory/unpassed.
35. **Cross-owner/recovery trace — GREEN/N/A for mutation.** Request/materialization path is caller scope -> accepted Character materializer -> immutable typed handoff. There are no CA8-7 writes, receipts, recovery obligations, queue jobs or reload-owned facts; a fresh materialization re-enters the accepted owner readers under a new caller-supplied coherent scope.

## Executed evidence

- Canonical static/source-oracle/dependency/query/generation checks: GREEN.
- Exact canonical Go execution: **ENVIRONMENT_BLOCKED**, not a product test failure.
- Fresh final compatibility-copy focused Character + archguard test/vet/race: GREEN.
- Whole-tree compatibility-copy `go test ./...`: GREEN.
- Whole-tree compatibility-copy `go vet ./...`: GREEN.
- Compatibility-copy `go test -race ./internal/application/...`: GREEN.
- Explicit package-by-package compatibility regression: **94/94 GREEN**.
- Cumulative source-oracle and historical validators were replayed in bounded batches after command wall-clock timeouts; all resumed stages relevant to the current candidate were explicitly GREEN. Timeouts themselves are not counted as proof.

## Conclusion

CA8-7 is a narrow, typed Character-side battle-contribution handoff over the accepted CA8-3/4/5 materializers. It satisfies the sealed Pass611 contract without becoming a battle-stat compiler, provider registry, rental owner or CombatSnapshot authority. No implementation-time evidence requires reopening the Pass611 design. The candidate is eligible for local-acceptance identity freezing. CA8-9 exact/native aggregate proof, CA8-E and W2 remain mandatory and unpassed.
