# Pass523 — CA3-1 independent post-implementation reality check

## Verdict

**GREEN for a local implementation checkpoint; NOT phase-accepted.** The produced CA3-1 code remains inside the Pass522 owner/scope contract and the exact current `src_64` Pet evidence. No contradiction was found that requires reopening CA3-1 research. Mandatory exact-toolchain/sqlc/real-PostgreSQL/native/stock gates remain unresolved and therefore acceptance is not granted here.

## Authority and candidate

- Pass522 HOT authority SHA-256: `695377d5678861b83e9c93a4101d9a67e6469250a590fdd680b80c2eb43affbc`.
- Parent accepted backend: Pass520 bytes accepted under Pass521, SHA-256 `58dc3f31d3e8ae82ea302cad4d7dcce2c958d9218c4e423f4af97a5cf018f830`.
- Parent implementation revision: `3813d389f577a90c9771f396a197c8ea926e0a602869e656bed2d557b5c01686`.
- Current source archive: SHA-256 `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`.
- New immutable content revision: `e9c310ac5a258e49cbf6e0a1a81a55a631706229b179617d66af9af78c225a25`.

## Independent source reread

`RUNTIME_OBSERVED`: `app/model/Pet.lua` re-extracted from the exact current archive hashes to `214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660`; `data/tables/pet.lua` hashes to `bc974045ec92fd7c0ebb2655d635d1b057eee7f74a871cfa2316b511ad55986e`, matching the Pass522 source pins.

`SOURCE_FACT`: collected Pet hydration consumes distinct `pet_id` and `table_id`, supplies defaults for absent `lev/exp/color/birthday/is_born/is_show/skills/equipment/Practice/style` fields, and `SelfPlayer` hydrates the same MID780-shaped roster during explicit load and embedded game-start processing. Both paths overwrite the private roster Pet's player ID with the canonical local player after hydration.

`SOURCE_FACT`: `Pet:toParams()` carries `birthday`, `is_born`, `is_show`, skills/equipment/Fumo/Practice values but not CA7 `active_style/pet_styles`; no independent current/v1.164 gameplay consumer of `is_born` was recovered. Persisting `birthday/is_show` while projecting `is_born=0` therefore remains consistent with the sealed evidence classification.

## Produced owner/schema reality

`RUNTIME_OBSERVED`: migration 00016 creates only `gxb_content_pet_templates`, `player_pet_roots`, and `player_pets`, backfills only empty Pet roots, and creates no starter egg/Pet, capacity, skill, equipment, Practice, style or tutorial entitlement state.

`IMPLEMENTATION_DECISION`: `pet_id` uses a positive per-player monotonic allocator beginning at 1, under future PetRoot lock rank 420; instance lock rank is 430. This remains explicitly reconstruction policy rather than original-server fact.

`STRONG_INFERENCE`: `UNIQUE(player_id, origin_table_id)` matches the source-observed base/awakened lineage while preserving `table_id` as current form and `pet_id` as stable instance identity.

`RUNTIME_OBSERVED`: canonical table ownership assigns Pet content exclusively to Content Registry and Pet roots/instances exclusively to `character/pet-core`; no foreign-owner I5 SQL is present in the Pet owner.

## Projection/router reality

`RUNTIME_OBSERVED`: MID1 detail contributor claims child `780`, verifies the Pet root exists, loads canonical ordered Pet rows and overlays the private stock roster. Explicit MID780 is removed from `LobbyDispatcher` registration and registered exactly once on `PetDispatcher`.

`RUNTIME_OBSERVED`: `PetDispatcher` implements MID780 only. MID781-792 and MID134 are not production-registered or implemented by this dispatcher.

`RUNTIME_OBSERVED`: private projection emits source-safe neutral `skills=[1,1,1,1,1]`, three zero equipment slots, three zero Fumo slots, three zero Practice attributes, and compatibility `is_born=0`; CA7 style fields and internal lineage/content-revision fields are not exposed.

## Content/runtime activation reality

`RUNTIME_OBSERVED`: deterministic generation from the exact source archive produces 54 Pet templates in 27 origin families and advertises `PET_CORE_CA3`. The five pre-existing generated payload files—resources, player progression, function gates, objectives, Hero core—remain byte-for-byte identical to the accepted Pass520 files.

`RUNTIME_OBSERVED`: Content Registry now installs and exact-verifies the Pet payload as part of the immutable revision. `PET_CORE_CA3` is added to the provider capability set.

`IMPLEMENTATION_DECISION`: CA3-1 read-only roster projection does not require the active revision to advertise `PET_CORE_CA3`. This preserves the accepted explicit content activation law for upgraded databases. No CA3-1 operation creates or mutates a Pet, so future CA3-2/3 commands remain responsible for binding a qualified Pet-capable revision.

## Test/reality evidence

Exact canonical static/source checks are GREEN: content regeneration against exact source, generator tests, query-text reproducibility, schema/query ownership, CA3-1 boundary validator, current cumulative validator/R6 cumulative mode, and preserved CA2-1 foundation validator.

`COMPATIBILITY_COPY_ONLY`: a fresh candidate copy changed only `go.mod` from Go 1.26/toolchain 1.27.1 to the available Go 1.23.0 with the toolchain directive removed. On that copy, focused changed-package tests, `go test ./...`, focused `go test -race`, and `go vet ./...` all pass. No assertion, test, package or product file was removed or weakened.

`ENVIRONMENT_BLOCKED`: postgres-tagged build cannot fetch `github.com/jackc/pgx/v5` because the module is not cached and the sandbox has no network. `sqlc 1.31.1` and PostgreSQL server binaries are unavailable. Therefore no real-PostgreSQL, exact canonical-toolchain, pinned-sqlc, River/native or stock-client proof is claimed.

## Scope check

No CA3-2 starter entitlement, MID781 summon, MID782 acceleration, MID789 show mutation, hatch economy, or Function-38 activation logic was introduced. No CA3-3 Pet EXP/evolution/skill mutation was introduced. No CA4/CA5/CA6/CA7 ownership was absorbed.

## Conclusion

The CA3-1 implementation is coherent enough to package as a **local GREEN checkpoint candidate** and to advance to the mandatory exact native/real-PostgreSQL/sqlc gate. It is not yet CA3-1 acceptance. CA3-2/CA3-3 implementation remains unauthorized pending their own targeted research/contract gates and CA3-1 controlling prerequisites.
