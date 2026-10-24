# CA8-8 Independent Postimplementation Reality Check — Pass614

Status: **GREEN for local-acceptance preparation; exact/native aggregate remains deferred to CA8-9.**

Candidate base: Pass612 locally accepted Git `ad01fd6d9c99b7c02f8bff3b13501b69d60654c5`.
Produced implementation commit before metadata seal: `1529fb6beac331179664363e7917dd2a9fb66408`.
Authority: sealed Pass613 CA8-8 contract / acceptance matrix / foundation-impact audit / source cross-check.

## Scope and proof limitations

- This reality check was performed by the same agent after implementation; no independent human reviewer is claimed.
- It re-read Pass613's CA8-8 implementation contract, acceptance matrix, foundation audit and preimplementation reality record, then inspected the produced `mode_guild.go`, focused tests, architecture guard, source-oracle guard, CA5 `SavedPresetReferenceState`/`OwnedCompositeBuilder`, CA8-4 `BorrowedCompositeBuilder`, CA8-1 `CoherentReadScope`, and the exact discriminating current + V1.164 Lua paths.
- Exact canonical Go execution was attempted first. It is **ENVIRONMENT_BLOCKED**: canonical source still requires Go >=1.26 and pins Go1.27.1; the sandbox has Go1.23.2 and cannot reach `proxy.golang.org` to fetch Go1.27.1.
- Go1.23.2 execution used a disposable copy with only `go.mod` language/toolchain accommodation. Those results are `COMPATIBILITY_COPY_ONLY` and do not satisfy CA8-9 exact/native/PostgreSQL/River proof, CA8-E or W2.

## Request/owner/provider trace

1. A future mode/Guild/rental owner interprets its own stock request family and durable business state.
2. If lender-owned borrowing is valid, that owner qualifies the exact lender `HeroRef`/`PetRef` plus opaque `BorrowedCapabilityProvenance` inside its caller-owned coherent transaction. CA8-8 does not parse or qualify stock rental fields.
3. The caller supplies the already-existing `CoherentReadScope` to `ModeGuildCharacterReader`; CA8-8 neither begins a transaction nor discovers clock/content revision.
4. Saved-reference reads delegate to CA5 `OwnedCompositeBuilder.SavedPresetReferencesTx`; borrowed reads delegate to CA8-4 `BorrowedCompositeBuilder`.
5. CA8-8 revalidates exact owner/origin/reference coherence and returns a defensive copy. No selected/current formation or rental business fact is created.
6. A future mode/Guild consumer composes those Character-owned facts with its own mode/rental facts. CA8-8 has no mutation, receipt, queue, recovery or reload-owned state; a later read simply re-enters accepted owner readers under a fresh caller scope.

## Acceptance-matrix findings

1. **A01 candidate binding — GREEN.** Implementation began from exact Pass612 archive SHA-256 `0be3877b...907a4`, Git `ad01fd6...`, with clean canonical pins.
2. **A02 coherent scope — GREEN.** Every method validates/reuses `CoherentReadScope`; no nested transaction, clock or revision discovery was added.
3. **A03 saved-reference semantics — GREEN.** `SavedPresetReferencesTx` delegates to CA5 and preserves PlayerID, StateVersion, ordered loadouts, duplicates, optional Pet and accepted empty whole-state semantics.
4. **A04 saved-reference copy isolation — GREEN.** Focused test mutates returned Hero/Pet refs and verifies provider state and a later read remain unchanged.
5. **A05 borrowed Hero provenance — GREEN.** Exact lender `HeroRef`, BORROWED origin and complete opaque capability provenance survive delegation and reader revalidation.
6. **A06 borrowed Pet provenance — GREEN.** Pet path has the same exact lender/provenance guarantee.
7. **A07 invalid qualification — GREEN.** Invalid ActorRef or missing capability provenance fails before any lender base read; zero-value success is not fabricated.
8. **A08 unavailable lender/provider — GREEN.** Hard CA5/CA8-4/provider errors propagate and return zero projections.
9. **A09 Tutor/synthetic boundary — GREEN.** Product code contains no Tutor coercion. Current `Tutor.lua` still clones/constructs feature-qualified actors; `SelfGuild.setUseRent` excludes `tutorInfo` from ordinary Guild rental-use marking. Pass604 synthetic classification remains intact.
10. **A10 raw wire boundary — GREEN.** `mode_guild.go` contains none of `tutor_rent_hero`, `rent_player_id`, `rent_formation`, `rent_hero_player`, `rent_hero_id`, `rent_pet_player_id`, or `rent_pet_id`.
11. **A11 durable-owner boundary — GREEN.** No selected/current formation, mode/season, Guild membership, offer/listing, eligibility, cost, use, recall, revocation, reset or settlement state was added.
12. **A12 persistence/side-effect fence — GREEN.** No SQL/schema/migration/write/lock/receipt/cache/realtime/network artifact or import was introduced.
13. **A13 stable-ref decision — GREEN.** `ModeGuildCharacterReader` has exactly three methods. There is no speculative `OwnedHeroTx`/`OwnedPetTx`; existing `HeroRef`/`PetRef` remain the stable identities.
14. **A14 delegated coherence revalidation — GREEN.** Reader verifies BORROWED origin, exact `QualifiedReference`, exact base ActorRef and composite validity after CA8-4 delegation; saved state owner/validity is rechecked after CA5 delegation.
15. **A15 regression — GREEN.** Existing CA5 and CA8-3/4/5/6/7 package tests plus full tree remain green in the compatibility copy.
16. **A16 test protocol — GREEN with limitation.** Canonical static/exact source-oracle checks are green; exact Go execution is environment-blocked; disposable compatibility test/race/vet, whole-tree test/vet, application race and 94/94 package regression are green.
17. **A17 internal provider only — GREEN.** No protocol/stockruntime route or stock-wire claim was added.
18. **A18 independent postimplementation reality — GREEN.** This record re-read controlling evidence and inspected the produced code/owner trace rather than restating tests.
19. **A19 source-oracle pin — GREEN.** Exact current member hashes for `SelectTeamNewWindow.lua`, `Tutor.lua`, `SelfGuild.lua` and V1.164 `SelectTeamWindow.lua` are pinned. The guard states explicitly that these are client/source facts, not original-server rental business truth.
20. **A20 lifecycle separation — GREEN.** CA8-8 local acceptance does not accept parent CA8. CA8-9 exact/native accumulated proof and CA8-E remain mandatory; W2 physical stock-client proof remains deferred/unpassed.

## Source cross-check repeated during implementation

**SOURCE_FACT:** current `SelectTeamNewWindow.handleRentParams` still has distinct Tutor (`tutor_rent_hero`), fourth-anniversary (`rent_hero_player` + `rent_hero_id`) and ordinary Guild-style (`rent_player_id` + `rent_formation`) Hero request families, with separate Pet lender/actor fields.

**SOURCE_FACT:** current `Tutor.getRentHeros` still clones borrower Hero parameters or constructs a Hero and attaches `tutorInfo`; `SelfGuild` keeps `guild_rent_heroes` and `tutor_rent_heroes` distinct and does not mark a `tutorInfo` actor as ordinary Guild-rental use.

**SOURCE_FACT:** V1.164 `SelectTeamWindow.lua` corroborates ordinary lender+actor pairs for Hero/Pet rental identity.

**STRONG_INFERENCE preserved from Pass613:** therefore Character Asset should receive owner-qualified typed refs rather than own a universal stock rental parser. No new implementation evidence contradicts that contract.

## Executed evidence

- Canonical CA8-8 static validator/source-oracle/query ownership/sqlc/querytext/gofmt/diff checks: GREEN.
- Exact canonical Go execution: **ENVIRONMENT_BLOCKED**, not counted as a product pass.
- Disposable compatibility-copy focused test/race/vet: GREEN.
- Compatibility whole-tree `go test ./...` and `go vet ./...`: GREEN.
- Compatibility `go test -race ./internal/application/...`: GREEN.
- Explicit compatibility package-by-package regression: **94/94 GREEN**.
- Dependency/content/SBOM/oracle/generation and retained I/R/CA validators were replayed; command-wall-clock wrappers expired twice, and the remaining exact commands were resumed in bounded batches. All executed resumed validators were GREEN; timeouts themselves are not evidence.

## Conclusion

CA8-8 implements exactly the sealed Pass613 three-method read-only provider boundary. It reuses CA5 and CA8-4 without acquiring a new owner, wire parser, transaction, time source, selected-formation state or rental business policy. No implementation-time evidence fired a Pass613 reopen trigger. The candidate is eligible for **local CA8-8 acceptance only**. CA8-9 exact/native/PostgreSQL/River accumulated proof, CA8-E whole-phase exit and W2 unmodified-stock-client proof remain mandatory/unpassed.
