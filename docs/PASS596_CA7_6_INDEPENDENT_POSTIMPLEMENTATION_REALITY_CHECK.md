# Pass596 — CA7-6 Independent Postimplementation Reality Check

## Authority and review posture

This review is bound to sealed **Pass595 HOT/CURRENT** authority, whose unified PassMap SHA-256 is `7c0fedc312c127ea5c53275f58025e3ef25f2abc8d926f067d202e4f66da94c8`. Pass595 seals CA7-6 preimplementation research GREEN and records explicit user authorization for implementation while retaining the accepted product baseline as `gxb-backend-v2-v0.84.0-pass594-ca7-5-local-accepted.zip` SHA-256 `4f4db4fea63bf7368e3ab8207a0242b002a02ef45b2234a128143f73f4b6d16f`, Git HEAD `5807ba882ccfeda2daf0e54966ee5fbed2da86ea`.

The frozen implementation contract is `docs/PASS595_CA7_6_PREIMPLEMENTATION_CONTRACT.md`; the frozen matrix is `docs/PASS595_CA7_6_ACCEPTANCE_MATRIX.json`. This reality check re-read those artifacts, the Pass595 source oracle and preservation matrix, accepted CA7-1/CA6 boundaries, the produced code, and exact current/v1.164 oracle evidence. It does not infer acceptance from a green test summary alone.

## Produced implementation reality

CA7-6 remains an integration/read-contract fence. The produced code adds no schema migration, gameplay MID, replay family, scheduler, Cosmetics aggregate, CA8 aggregate, battle resolver, Library board owner, Commerce pricing path, or foreign-owner SQL. The production addition is limited to:

- self-describing `HeroAppearanceContribution` and `PetAppearanceContribution` values plus provider interfaces in `internal/application/characterasset/appearance_contribution.go`;
- Hero caller-queryer contribution reader in `internal/application/characterhero/appearance_contribution.go`;
- Pet caller-queryer contribution reader in `internal/application/characterpet/appearance_contribution.go`;
- focused contribution/reload/freeze tests;
- real cross-service CA7↔CA6 Practice integration tests;
- bidirectional CA2/CA3/CA4 preservation tests plus real CA5 mutation preservation evidence;
- CA7-6 architecture/static/source-oracle guards wired into the cumulative check surface.

The Hero reader validates the exact caller-supplied appearance revision before owner read, loads the canonical Hero through the caller queryer, fails closed if `PlayerID`/`PartnerID` does not match the request, reconstructs Hero kind from immutable `CreationContentRevision`, then qualifies current skin/LIVE state using the caller-pinned current appearance revision. The Pet reader likewise validates exact revision, fails closed on `PlayerID`/`PetID` mismatch, reads keyed style authority through the caller queryer, and qualifies the effective Pet appearance at the caller-supplied observation instant.

Neither provider contains `tx.Runner`, transaction begin/commit/rollback, owner locking, `ActiveRevision` discovery, receipt/I5 dependencies, live-clock reads, battle-model derivation or Library `board_*` state. Returned contributions contain owner/current-table/origin provenance plus exact content revision, while `EffectiveHeroAppearance` / `EffectivePetAppearance` retain owner `state_version` and observation time.

## Acceptance-row mapping

### A76_01_BINDING — GREEN
Pass595 authority, accepted Pass594 baseline, current source SHA-256 `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`, and v1.164 SHA-256 `d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1` are pinned by the sealed research artifacts and the CA7-6 source-oracle checker. No filename-only promotion occurred.

### A76_02_CONTRIBUTION_IDENTITY — GREEN
Contribution structs carry owner instance, current table, origin table, exact content revision and nested effective appearance. `ValidateExactRevisionID` enforces canonical revision form; contribution validation requires positive identities and valid nested appearance. Hero/Pet readers explicitly reject owner identity mismatches. Unit tests `TestHeroAppearanceContributionReaderRejectsOwnerMismatch` and `TestPetAppearanceContributionReaderRejectsOwnerMismatch` plus `TestCA76ContributionReadSeamAndPreservationFences` enforce this boundary.

### A76_03_CALLER_OWNED_READ — GREEN
Provider signatures require caller `tx.Queryer`, exact revision and `observedAt`. Static and architecture guards forbid nested transaction ownership, `ActiveRevision`, live clocks, I5, receipts, write calls, scheduler/battle policy and owner-lock SQL in the new read seam.

### A76_04_HERO_KIND_PROVENANCE — GREEN
The Hero reader calls `HeroKindTx(..., h.CreationContentRevision, h.TableID)` and separately calls the effective appearance builder with the caller's current exact revision. `TestHeroAppearanceContributionReaderUsesPinnedRevisionAndCreationKindProvenance` and the static/architecture guards prevent revision-axis collapse.

### A76_05_EFFECTIVE_TIME_FREEZE — GREEN
Accepted effective-projection boundary tests remain present, and new Hero/Pet contribution tests prove the caller observation instant is used and that an already-returned contribution remains unchanged after later durable mutation. No live-clock read exists in the provider.

### A76_06_STALE_SELECTOR_EFFECTIVE — GREEN
`TestTimedEntitlementEqualityAndStaleSelectorQualification` continues to prove stale ordinary selector→effective `0` and stale explicit illusion→inherit/default `-1` without read-side durable rewrite. CA7-6 only composes the existing builders.

### A76_07_HERO_AXIS_ISOLATION — GREEN
The exact current source oracle still distinguishes illusion-aware presentation from ordinary-skin battle skill identity, while v1.164 provides the historical differential. The contribution files are guarded against `EffectiveModelID`, `BattleModelID`, `SkillModelID` or `SkinSkillID`, so CA7-6 does not collapse the axes.

### A76_08_LIVE_BOUNDARY — GREEN
The tree-wide current oracle pins MID68 `UNLOCK_DYNAMIC_CARD` and MID69 `SHOW_DYNAMIC_CARD`, qualified LIVE state and deterministic projection, and verifies no `lib/battle` consumer of dynamic-card state. CA7-6 carries the existing qualified appearance state only and adds no combat semantics.

### A76_09_PET_STYLE_BOUNDARY — GREEN
The source oracle pins MIDs 1893/1894/1895 and verifies current Pet combat/model code does not consume `active_style`. Full-tree reachability still finds no external `PetAttributeWindow0` reference; that retained MID60/61 branch remains fenced as unreachable current-client source. The Pet contribution composes the existing family-qualified effective projection.

### A76_10_PRACTICE_HERO_STALE — GREEN
`TestCA76RealHeroTicketStalesAfterActualCA7MutationWithoutRefundOrDeletion` creates a real TICKET proposal, performs an actual CA7 Hero mutation and proves SAVE rejects the stale owner revision before apply/delete.

### A76_11_PRACTICE_PET_STALE — GREEN
`TestCA76RealPetTicketStalesAfterActualCA7MutationWithoutRefundOrDeletion` proves the same real cross-service owner-version invalidation for Pet.

### A76_12_PRACTICE_NOOP — GREEN
`TestCA76SemanticNoopPreservesPendingProposalValidity` drives actual Hero/Pet CA7 semantic no-ops and proves owner version is preserved so a valid pending proposal remains savable.

### A76_13_TICKET_ACCOUNTING — GREEN
The real TICKET stale tests prove the generation debit stays committed, stale SAVE performs no second debit and no refund, and the stale proposal remains present after rejection.

### A76_14_AUTO_SERIALIZATION — GREEN_LOCAL / NATIVE_DEFERRED
The accepted service architecture uses the same Hero410/Pet430 owner authority for CA7 and Practice AUTO. `TestCA76AUTOAndCA7SerializeBySharedOwnerVersionInBothOrders` proves both deterministic serialized orders locally without fabricating an AUTO proposal. This is intentionally **not** evidence of concurrent PostgreSQL row-lock behavior; that exact native proof remains CA7-7.

### A76_15_CA2_CA3_PRESERVATION — GREEN
Real Hero/Pet progression service tests prove unrelated CA2/CA3 mutations preserve CA7 selector/family provenance. `TestCA76AppearanceMutationsPreserveEarlierOwnedFields` proves real CA7 Hero/Pet mutations preserve identity/progression/show/skills fields. Generated-query ownership guards independently enforce narrow SQL writes.

### A76_16_CA4_PRESERVATION — GREEN
Real Hero/Pet equipment service tests prove CA4 mutations preserve CA7 selector/style state. The real CA7 integration test proves CA7 mutations preserve equipment/Fumo. Owner version advances only on actual mutations; semantic no-op behavior is separately tested.

### A76_17_CA5_PRESERVATION — GREEN
`TestCA76SavedPresetMutationPreservesCA7AppearanceState` drives the actual CA5 saved-preset mutation service while Hero/Pet CA7 appearance state remains unchanged. Generated CA5 root/lane/Hero-reference queries are separately checked to avoid `player_heroes`, `player_pets`, skin or style ownership. Conversely, CA7 appearance queries contain no saved-preset root/lane/reference writes.

### A76_18_COMMERCE_BOUNDARY — GREEN
The accepted `TxPermanentSkinMaterializer` remains the single Character-side materializer definition and retains caller-owned transaction semantics. The CA7-6 validator fails if it is duplicated/moved or if a Cosmetics owner appears. No Commerce settlement/pricing implementation was added.

### A76_19_LIBRARY_BOUNDARY — GREEN
Current source still binds MID835 `board_partner`, `board_card`, `board_model_id` to Library presentation behavior. CA7-6 contribution files are explicitly guarded against `board_*` identifiers and add no Character board persistence or universal board-card formula.

### A76_20_FULL_SOURCE_ORACLE — GREEN
`tools/check_ca7_6_source_oracle.py` verifies the exact 4,370-file current `src_64` census, all eight appearance MIDs, pinned source-member hashes, current/v1.164 battle differential, LIVE/Pet-style nonbattle census, Library boundary and `PetAttributeWindow0` reachability classification.

### A76_21_RELOAD_DETERMINISM — GREEN
Hero/Pet reload tests call the readers repeatedly at the same exact revision/instant, prove deterministic sorted effective state, deep independence of returned slices/timed values, and freezing across later durable mutation. Existing projection builders remain the authority and no client projection array becomes durable input.

### A76_22_NO_NEW_AUTHORITY — GREEN
Tree/diff/architecture inspection shows no CA7-6 migration, new MID, new replay family, scheduler, Cosmetics package, CA8 aggregate or foreign-owner SQL. The new production files are read-only contribution seams.

### A76_23_RESIDUAL_ROUTING — GREEN
Pass595 research closure and authority routing retain Stone/capacity/stat-crosswalk/Spirit and unresolved Rune/rep-lock obligations for CA8/CAE/future provider work. No such behavior appears in the CA7-6 implementation footprint.

### A76_24_DEFERRED_GATES — GREEN_CLASSIFICATION
CA7-7 exact/native accumulated PostgreSQL/River proof is still deferred and is the next phase. W2 physical unmodified-stock-client proof remains separate and unclaimed. Compatibility-copy results are not promoted to either gate.

### A76_25_INDEPENDENT_REALITY — GREEN
The Pass595 preimplementation reality check falsified the research contract before coding. This postimplementation review independently re-read the frozen matrix/source/ownership contracts and produced code, found and repaired one real identity-validation gap during implementation, strengthened CA5 and Library/Commerce proof, and now maps all 25 frozen rows without relying solely on test output.

## Test and environment classification

The exact canonical candidate was attempted first after the final code/test changes. The pinned Go 1.27.1 toolchain cannot be downloaded because this sandbox cannot resolve/reach `proxy.golang.org`; the failure is recorded in `EVIDENCE/PASS596_CA7_6/EXACT_CANONICAL_GO_ATTEMPT.log`. Canonical `.go-version`, `go.mod`, and `go.sum` remain pristine.

Canonical static/source/query/ownership evidence is GREEN in `EVIDENCE/PASS596_CA7_6/CANONICAL_STATIC_SOURCE_GATE.log`.

A fresh disposable `COMPATIBILITY_COPY_ONLY` clone changed only:

- `.go-version`: `1.27.1` → `1.23.2`;
- `go.mod`: `go 1.26.0` → `go 1.23.0`;
- `go.mod`: `toolchain go1.27.1` → `toolchain go1.23.2`;
- `go.sum`: unchanged.

On that fresh copy, focused tests, focused race, whole-tree vet, whole-tree `go test ./...`, cumulative CA3-3/CA4-1/CA7-3/4/5/6 validators, exact source oracles, dependency/SBOM/sqlc/query/ownership checks and the bounded 94-of-94 package regression are GREEN.

## Conclusion

Every CA7-6 LOCAL_REQUIRED acceptance row is now supported by produced code plus canonical-static and/or fresh compatibility-executed evidence. A76_14's exact concurrent PostgreSQL lock proof remains intentionally deferred to CA7-7, as frozen. This supports **CA7-6 local acceptance** once release metadata/candidate identity/preseal are finalized. It does **not** satisfy CA7-7 native aggregate proof and does **not** satisfy W2 physical unmodified-stock-client proof.
