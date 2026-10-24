# Pass515 CA2-1 independent post-implementation reality check

Status: GREEN_FOR_CA2_1_LOCAL_CHECKPOINT_ONLY
Phase: CHARACTER_ASSET_CORE / CA2 / CA2-1
Aggregate CA2 phase status: OPEN; not accepted/sealed as a Character Asset phase.
Authority parent: sealed Pass513 CA2 research/implementation contract.

## Evidence reread
The reality check reread the sealed Pass513 CA2 implementation contract and research checkpoint 2, the Pass513 CA2 native/real-PostgreSQL gate plan, the Pass465 Work Place time contract, exact current src_64, and the produced CA2-1 code. It did not treat tests as a substitute for source/contract reread.

## Migration-candidate defects found and repaired
1. Removed duplicate `gxb_content_hero_acquisition_items`; exact Hero acquisition mapping is verified against the existing revision-qualified `gxb_content_resource_definitions.partner_id` owner.
2. Corrected durable Hero star ceiling from 1..10 to the sealed/effective-client 1..8.
3. Removed speculative durable `skill_levels`; MID49 emits the exact neutral six-one skill shape while skill mutation remains deferred.
4. Removed the CA2 MID1 Hero roster detail contributor; MID49 alone owns the roster projection.
5. Corrected `player_heroes.player_id` to reference `player_hero_roots(player_id) ON DELETE CASCADE`; restored sealed root defaults.
6. Removed durable `hero_kind`; Super/Normal kind is resolved through an exact creation-content-revision Content port before projection.
7. Aligned the revisioned Hero relational decomposition with the sealed contract while preserving the deterministic `hero_core_catalog.json` payload and content revision `e8061a82658033813ee1c182f0f3b062cb0af5b43e21acea7b905e713ad0e964`.
8. Repaired inherited release SBOM version drift with the repository deterministic resolved-SBOM generator.
9. Added explicit cumulative mode to the historical R5 validator so the CA2 compiler generation can be validated without weakening the standalone historical R5 compiler pin; strict R5 mode still rejects `ca2-1` as expected.

## Exact src_64 corroboration
- MID49=`LOAD_HEROS` and MID89=`SAVA_SORT_TYPE` remain source-confirmed.
- `Player.herosEvent_` consumes `sort_type` plus `heros` and gates the private roster by returned userdata player identity.
- NormalHero/SuperHero defaults corroborate six skill levels of 1, six equipment/fumo zeros, six skill-id zeros and three practice zeros when absent.
- SuperHero consumes `partner_type or 0`; the CA2 projection emits `partner_type=2` only for revisioned-content-resolved Super/Vows Heroes.
- `SUPER_HERO_TOTAL_STARS=8` remains the effective-client ceiling; physical Super star rows 9/10 remain dormant content evidence only.

## Local test evidence
All Go execution in normal chat is COMPATIBILITY_COPY_ONLY because exact pinned Go 1.27.1 is unavailable. A fresh copy changed only the Go/toolchain declarations to local Go 1.23.2.
- focused Character/projection/application/contentstore tests: PASS;
- focused race: PASS;
- full `go vet ./...`: PASS;
- bounded package-by-package regression: 89/89 PASS;
- full `go test ./...`: PASS;
- CA2-1 static validation: PASS;
- schema/query ownership: PASS;
- sqlc generation policy: PASS;
- Character and Content querytext freshness: PASS;
- exact-current-src_64 CA2 source oracle: PASS;
- deterministic builtin content regeneration/check: PASS, revision e8061a82658033813ee1c182f0f3b062cb0af5b43e21acea7b905e713ad0e964;
- R5 cumulative guard: PASS while strict historical R5 compiler pin remains intact;
- current cumulative candidate validator: PASS.

## Evidence limitations / deferred proof
NOT_RUN/ENVIRONMENT_BLOCKED in normal chat: exact Go 1.27.1 execution, native sqlc 1.31.1 regeneration, Goose, PostgreSQL 18.6 migration/query/concurrency/restore checks, River semantics, and stock-client/live proof. Pass513 explicitly assigns the exact native/real-PostgreSQL gate to the final aggregate CA2 candidate after CA2-1/2/3 local checkpoints. These missing dimensions therefore do not become evidence for CA2-1 and are not waived; they remain mandatory at the named aggregate CA2 gate.

## Adjudication
CA2-1 is locally checkpoint-acceptable after repair. This is an internal implementation checkpoint, not CA2 phase acceptance. CA2-2 becomes the next permitted internal stage only after this checkpoint is recorded. CA2-3 production activation remains blocked by UNKNOWN Hero capacity/MID64 policy. CAE, W2 and later Character Asset stages remain unclaimed.
