# Pass560 CA5-1 Independent Postimplementation Reality Check

Status: **GREEN — CA5-1 LOCAL ACCEPTANCE; COMPATIBILITY_COPY_ONLY EXECUTABLE PROOF; EXACT-NATIVE CA5 AGGREGATE GATE DEFERRED MANDATORY PRE-CA5-E**

Authority parent is sealed Pass559 (`39ea5facec191d7c2a5498e21ecc86953ab10c620f257dc010ffb6ad90d5bfec`) and accepted Pass555 backend (`25b0f55e65432f385171e6108235fa7004e34737421c533b4c6c50ee1381a69f`). No separate human reviewer participated; “independent” means a postimplementation reread against the frozen Pass559 contract, D01/D04/D11, exact candidate diff, and preserved source/roadmap boundaries.

## Exact candidate footprint

The product delta is eight files: two modified (`internal/domain/character/hero.go`, `internal/application/characterasset/contracts.go`) and six added (`reference_owner.go`, `reference_owner_test.go`, `references.go`, `references_test.go`, `ca5_1_contract_test.go`, `reference_test.go`). Canonical `go.mod`, `go.sum`, `.go-version`, migrations, SQL, stockruntime routing, and replay/receipt files remain byte-identical to Pass555.

## Reality findings

1. `HeroRef` is actor-scoped and mutable-state-free, symmetric with `PetRef`; numeric instance IDs are not treated as globally unique.
2. Lock planning preserves established ordering: Hero instance 410, Pet instance 430, CA5 saved-preset root 440. Composite Hero/Pet keys include player + instance identity and round-trip validation rejects family/player/instance mismatch.
3. PostgreSQL adapters require both the planned canonical key and expected typed ref before any owner SQL, preventing a caller from using another player's otherwise-valid key. Missing owner rows map to `ErrReferenceNotFound`; infrastructure errors remain errors.
4. Reference-guard preflight is read-only and must return stable non-empty provider locks. This closes the absence race: a future removal cannot observe “not referenced,” acquire no CA5 lock, and race a concurrent preset insert.
5. Guard canonicalization rejects duplicate provider identities and cross-provider duplicate lock ownership. Locked revalidation controls allow versus `ErrReferenceInUse`. No generic detach/mutation API was invented.
6. CA5-1 intentionally does not create the rank-440 root row. CA5-2 remains responsible for migration/backfill plus required character-bootstrap persistence before CA5-3/4 activation.
7. No MID1793/208/209, MID1 saved-team/`formation`, replay catalog, MID66/removal, I9 mode, schema, or CA8 composite-snapshot activation leaked into this stage.
8. D01 is respected by complete preplanned canonical lock sets; D04 is respected by typed owner-qualified persistent refs and future removal fencing; D11 is not prematurely implemented because CA5-1 activates no stock mutation/replay surface.

## Execution evidence

Exact execution was attempted first and is **ENVIRONMENT_BLOCKED**: the candidate requires Go >=1.26/toolchain go1.27.1, while this sandbox has Go1.23.2 and cannot resolve/download the pinned toolchain. This is not a product failure.

A disposable minimal compatibility copy is GREEN for focused CA5-1 tests/race/vet, related Hero/Pet/I5/bootstrap tests and races, stockruntime regression, all 87 internal packages package-by-package, full `go test ./...`, and full `go vet ./...`. Full-tree `go test -race ./...` exceeded the sandbox window and is **NOT CLAIMED**. All executable results remain `COMPATIBILITY_COPY_ONLY`.

## Deferred gates

Per explicit user direction, dedicated exact/live Work-mode testing is accumulated and remains mandatory immediately before CA5-E. This defers—not waives—the exact Go/PostgreSQL/River gate. Physical unmodified-stock-client proof remains at the separately accepted W2/post-I14 gate.

## Verdict

**GREEN for CA5-1 local acceptance.** The thin shared foundation is coherent and sufficient for CA5-2 research. No evidence supports reopening CA1-CA4 or activating CA5-2/3/4 functionality early. CA5-2 may enter `PRE_IMPLEMENTATION_RESEARCH_RECONCILIATION` only after Pass560 HOT+COLD seal; CA5-2 implementation remains separately unauthorized.
