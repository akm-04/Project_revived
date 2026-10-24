# Pass566 — CA5-4 Independent Postimplementation Reality Check

## Candidate and authority

The inspected candidate descends from exact Pass564 v0.75.0 (`c47455fc7c31d4c43fe3c58daf9bd9b8225cc9534cddfcadbee0848b89885448`). Sealed Pass565 is the CA5-4 research, implementation-contract and acceptance authority, and the user explicitly authorized the full implementation sequence. This review rereads the produced DTO/reader/guard code, concrete PostgreSQL saved-preset adapter/query text, CA5-1 typed guard ABI, CA5-3 mutation synchronization, source-oracle evidence and the parent→candidate diff rather than treating tests alone as acceptance.

## Reference-state ownership reality

`SavedPresetReferenceState` contains only player identity, saved-preset root `StateVersion`, ordered HeroRefs and optional PetRef. It deliberately contains no preset name, selected/current formation, battle stats or mode policy. `ReferenceStateReader` reads one canonical CA5-2 aggregate, validates actor identity, deep-copies refs and preserves the root revision. Empty preset sets are valid; missing/corrupt strong references are not silently compacted. This is a CA5 observation for future CA8/I9 composition, not a universal formation owner.

## Reverse guard reality

`SavedPresetReferenceGuard` is actor-bound and identifies itself as `ca5.saved-presets`. Hero/Pet preflight is query-independent and always returns exactly the actor's rank-440 saved-preset-root key. `LockReferenceGuardKeyTx` accepts only that provider-owned actor root and delegates to CA5-2 root locking. Locked validation performs only the saved-preset-owned Hero/Pet reference-existence checks and returns `ErrReferenceInUse` when referenced. It performs no detach, cleanup or source-owner mutation.

## Persistence/query reality

The only SQL additions are two `SELECT EXISTS` queries over `player_saved_preset_heroes(player_id,partner_id)` and `player_saved_preset_lanes(player_id,pet_id)`. They match CA5-2's existing indexes and touch no `player_heroes`/`player_pets` owner tables. No migration 00029 or schema mutation exists. Generated query text is source-hash synchronized and schema/query ownership plus sqlc-generation guards are GREEN.

## Concurrency reality

The test-only future consumer composes the same source-owner Hero/Pet keys and CA5 rank-440 root used by the real CA5-3 mutation service. Add-first commits the reference and later consume rejects under locked CA5 validation. Consume-first removes the fixture source while holding source+root synchronization, and later CA5-3 add fails owner validation without creating a dangling saved-preset ref. Pet rank430→root440 composition is separately asserted. No destructive production endpoint is introduced.

A fresh closure race run exposed an inherited test-only race in `presetFence.calls++` from CA5-3's concurrency fixture. Canonical test instrumentation was repaired to an atomic counter, the diagnostic copy was discarded, and focused tests/race/vet plus broad regression were rerun from a fresh post-repair candidate. This changes no product behavior but is required for honest race evidence.

## Source and negative-scope reality

The exact current/historical/frozen-V1/native oracle guard is GREEN. MID66 and a registered HeroSetting dismissal method are source-present, but reachability and original-server mutation semantics remain unqualified; frozen V1 is only a provisional status acknowledgement. CA5-4 therefore does not activate MID66 or import representative/lock/defense UI policy. MID208/209 remain inactive, `17.formation` remains unclaimed, I9 mode state is absent and CA8 still owns the final composite snapshot.

## Testing/environment reality

Exact canonical static/query/source-oracle gates are GREEN and canonical `go.mod`, `go.sum`, `.go-version` are unchanged. Exact canonical Go execution is `ENVIRONMENT_BLOCKED` because the local toolchain is Go1.23.2 while canonical requires Go>=1.26/toolchain1.27.1. A fresh disposable copy differing only in `go.mod` toolchain/language declarations and `.go-version` passes focused tests, focused race, focused vet, full `go test ./...`, full `go vet ./...`, and bounded package regression 93/93. PostgreSQL-tag compilation is separately environment-blocked by unavailable `pgx/v5` with module lookup disabled. These executable results remain `COMPATIBILITY_COPY_ONLY`.

## Verdict

`GREEN_LOCAL_CA5_4_ACCEPTED_COMPATIBILITY_COPY_ONLY_NATIVE_AGGREGATE_GATE_NOW_DUE_PRE_CA5_E`. No demonstrated product defect or contract contradiction requires reopening CA5-1..CA5-4. CA5-4 local acceptance advances the frontier to CA5-E, where the already-authorized accumulated exact/native PostgreSQL/River gate becomes mandatory before whole-phase exit acceptance. W2 remains separately post-I14.
