# Pass519 CA2-3 independent post-implementation reality check

## Adjudication

**GREEN / ACCEPTABLE for the CA2-3 internal local checkpoint.** This does **not** accept aggregate CA2. CA2-1 and CA2-2 remain accepted internal local checkpoints; CA2-3 now joins them as locally acceptable. The aggregate CA2 exact pinned-toolchain / real PostgreSQL 18.6 / applicable River / stock-client gate remains mandatory before CA2 phase acceptance or CA3 advancement.

## Authority reread

This reality check reread the sealed Pass518 CA2-3 source evidence, research closure, implementation plan and independent preimplementation reality check; the sealed Pass513 whole-CA2 contract/native-gate plan; the exact Pass517 implementation parent; and exact current `src_64` from authority archive SHA-256 `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`.

The produced code was then inspected backward across CA2-1 -> CA2-2 -> CA2-3 instead of treating CA2-3 tests as proof that the earlier stages remained sound.

## CA2-1 connected reality

**RUNTIME_OBSERVED:** the Pass514 drift repairs remain present in the current candidate.

- `player_hero_roots` remains the Character-owned Hero root/allocator owner and `player_heroes` remains the single durable Hero-instance owner.
- `(player_id, partner_id)` remains the primary identity and `(player_id, origin_table_id)` remains unique, preserving one live Hero per origin family.
- persisted stars remain bounded to the effective 1..8 range.
- no speculative skill persistence or durable `hero_kind` has reappeared.
- Hero roster state remains on MID49 rather than being injected into MID1.
- MID89 sort state remains root-owned.
- Hero kind is recovered from immutable content using each Hero's persisted `creation_content_revision`; the added reload test proves MID49 can rehydrate kind while preserving partner ID, table ID, star, level and EXP.
- production route registration still includes the CA2-1 routes but does not activate the capacity-dependent CA2-3 routes.

**Adjudication:** CA2-1 internal local checkpoint remains GREEN; no superseding drift found.

## CA2-2 connected reality

- Character remains sole durable owner of Hero `star`, `level` and `exp`; Character SQL does not reach I5 Economy/Progression/Scalar/Stack tables.
- the exact `HERO_PROGRESSION_CA2` content revision is bound into `operation.Context.Policies` before retryable transaction execution and reused across definite-abort retries.
- MID55/MID63 progression uses the five source-qualified EXP consumables and cumulative EXP/level rules; MID52 uses source-qualified Normal and Super/Vows progression rules; MID67 projects canonical I5 fragment stacks rather than duplicating inventory state.
- operation receipts remain same-attempt UNKNOWN-COMMIT witnesses. Receipt absence after an ambiguous commit does not authorize blind replay.
- the CA2-3 implementation exposed a real extension defect in CA2-2 prerequisite locking: Hero partner IDs were sorted lexically by decimal string. This has been repaired to numeric same-rank ordering, with explicit `2` versus `10` regression coverage.
- Super low-star MID52 now stabilizes roster membership by locking HeroRoot rank 400 before target/prerequisite HeroInstance rank 410 locks. This preserves the previously sealed mechanic while making the extension seam safe once acquisition can exist diagnostically.

**Adjudication:** CA2-2 internal local checkpoint remains GREEN after the bounded concurrency repair; no gameplay-contract regression found.

## CA2-3 produced-code reality

### CA1 PartnerEntity -> Hero materialization

- provider implementation metadata is `character.hero` / `ca2-3.v1` with result schema `gxb.ca2.hero-materialization.v1`; these names are **IMPLEMENTATION_DECISION**, not source facts.
- the provider uses the batch's already-pinned exact Content revision, rejects unsupported amount != 1 and duplicate origin families, and declares the Character HeroRoot rank-400 lock before future Hero IDs exist.
- after root locking it re-evaluates current roster/origin uniqueness and diagnostic capacity, allocates opaque positive partner IDs in original Grant line-ordinal order, and inserts Heroes at the exact revisioned template `initial_star` (including item 40001062 -> Hero 10001062 -> star 5), level 1, EXP 0, color 1.
- no secondary materialization ledger was introduced. `gxb.i5.grant.v3` remains semantic replay authority; replay returns the stored typed materialization result without invoking Character creation again.

### MID59 Normal fragment summon

- diagnostic MID59 strictly validates the recovered `{table_id, stone, stone_num}` request shape and returns the Hero payload directly.
- authoritative fragment identity/count and Mana cost are resolved from the pinned Content revision rather than trusted from client fields.
- lock/order composition is HeroRoot 400 -> I5 Economy 700 -> Mana Scalar 720 -> fragment Stack 722, followed by Character insert/allocator advance and operation receipt in one caller transaction.
- duplicate origin, insufficient material, capacity denial, mismatched client cost and unsupported target all fail before partial success.
- matching UNKNOWN-COMMIT receipt reconciles without a second debit/insert; absent receipt remains UNKNOWN and is not blindly replayed.

### MID305 Vows creation

- diagnostic MID305 strictly accepts `{table_id}` and returns `{partner_info:<Hero>}`.
- it requires an unowned Super/Vows origin, all five configured prerequisite origin families, at least one prerequisite exactly five-star, and the Function88/player-level-100 requirement.
- prerequisites are not consumed; initial Vows star is the count of exactly-five-star prerequisites (1..5).
- lock order is HeroRoot 400 -> numerically sorted prerequisite HeroInstance 410 -> I5 PlayerProgression 710, with eligibility re-evaluated while locks are held.
- no extra currency/item debit was invented.

### Capacity / production activation boundary

Hero capacity remains **UNKNOWN** for initial capacity, absolute maximum and MID64 price schedule. Exact current and historical v1.164 corpora recover only consumers plus the +5 expansion increment.

CA2-3 therefore uses a diagnostic/test-only pure `CapacityAuthorizer`. Nil capacity authority fails before lock/mutation and is never interpreted as unlimited.

**RUNTIME_OBSERVED production boundary:**

- production Hero MIDs remain exactly 49,52,55,63,67,89;
- MID59 and MID305 handlers exist only behind diagnostic dispatch paths and are not production-registered;
- I5 production wiring does not install the Hero PartnerEntity provider;
- MID64 remains absent/deferred.

Thus the mechanics can be tested without fabricating capacity or silently activating unsupported success.

## Immutable content / migration reality

CA2-3 adds query surfaces only. There is no migration 00016, no new immutable capability and no generated Hero-content change. Schema remains version 1, compiler remains `ca2-2`, and deterministic content revision remains `e5a7c922fd40d42a4354f6200c7e3ea0ca9f00d666527df1b5915b083e0e49fb`.

## Source/static reality

The final canonical tree passes all five external oracle hash checks, CA2-1/CA2-2/CA2-3 exact-source oracle checks, cumulative CA2-1/CA2-2 validation, CA2-3 static validation, R5/R6 cumulative validation, current-candidate validation, schema/query ownership, sqlc generation policy, Character/Content/Kernel querytext checks, deterministic builtin-content regeneration, dependency policy, resolved SBOM and connected-candidate preseal.

## Go/test reality

A brand-new disposable copy of the frozen source/test tree changed only `go.mod` and `.go-version` to accommodate local Go 1.23.2. It passes focused CA2 tests (including reload/kind rehydration), focused race, `go vet ./...`, `go test ./...`, and bounded 89/89 package tests.

These results are **COMPATIBILITY_COPY_ONLY**. They do not establish exact Go 1.27.1, sqlc 1.31.1, Goose, PostgreSQL 18.6, River or stock-client behavior.

## Aggregate CA2 boundary

No normal-chat evidence justifies aggregate CA2 acceptance. The next controlling action after the immutable Pass519 local checkpoint is the Pass513/Pass518 aggregate CA2 native gate on the exact candidate, covering CA2-1 through CA2-3 together. CA3 must not start before that gate is reconciled and aggregate CA2 is explicitly accepted/sealed.
