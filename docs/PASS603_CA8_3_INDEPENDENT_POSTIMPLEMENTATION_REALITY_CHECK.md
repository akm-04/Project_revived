# Pass603 CA8-3 Independent Postimplementation Reality Check

Result: **GREEN for local CA8-3 acceptance; exact/native accumulated proof remains deferred to CA8-9.**

## Contract trace

- I0 ownership remains unchanged: CA2/CA3 own base Hero/Pet state, CA4 owns equipment, CA5 owns saved reference aggregates, CA6 owns Practice, and CA7 owns appearance facts. CA8-3 owns only immutable composition values.
- I1 is preserved: `OwnedCompositeBuilder` accepts the caller-provided `CoherentReadScope` and never opens, commits, retries or nests a transaction.
- I2 is preserved: no MID/wire contract changed.
- I3 is preserved: CA8-3 emits only `OWNED`; borrowed/trial/NPC-template business behavior remains future CA8-4/5 scope.
- I4 is preserved: no realtime/publication authority was added.
- I5 is preserved: no cross-owner write or foreign-owner SQL exists in the new composition layer.
- I6 is preserved: local provider disposition reports observed readiness only and never replaces canonical capability authority or assigns consumer requiredness.

## Predecessor trace

- CA2/CA3 base observations remain canonical identity/progression readers and provide the exact actor `StateVersion`.
- CA4 raw equipment remains owner-qualified. CA8-3 adds only the previously deferred Super-Hero read adapter: fixed pinned slot mapping, raw `0` uncollected, raw `N>0` -> enhancement `N-1`, `RawFumo=0`, and caller-queryer capability validation.
- CA5 `SavedPresetReferenceState` remains an independent ordered reference aggregate. CA8-3 does not resolve it eagerly, deduplicate it, compare its root version to actor versions, or reinterpret it as selected formation.
- CA6 Practice and CA7 appearance are composed only when their actor/table/revision/time provenance agrees exactly with the base observation and caller scope.

## Falsification / diff review

The complete Pass602->CA8-3 product diff contains no migration, schema, durable Character row, receipt, scheduler, MID, final stat compiler, borrowed/rental policy, synthetic actor policy, selected-formation authority or dependency/toolchain change. `characterasset` does not import Hero/Pet application owners and contains no transaction runner or raw SQL. Owner packages provide thin adapters to the package-neutral observation interfaces, preventing an ownership/import cycle.

Provider handling was checked specifically: only the accepted explicit content-inactive sentinels are normalized to `EXPLICITLY_INACTIVE_OR_LEGITIMATELY_ABSENT`; database/query/integrity errors propagate. A nil optional provider is `UNAVAILABLE_UNQUALIFIED`. CA8-3 rejects `REQUIRED_BUT_UNAVAILABLE` because consumer profiles own requiredness.

## Source / preservation evidence

Exact current, old-client and frozen-V1 source archives were hash-matched. The CA4-5 Super raw-slot/source facts are present. The historical CA4-5 source checker still reports only its pre-existing generated-content-revision drift and CA6-5 reports only its pre-existing Pet route-family drift; both failures reproduce identically on the untouched Pass602 baseline. Current cumulative/static ownership validators and affected CA5/CA6/CA7 source oracles are otherwise GREEN.

## Execution evidence and limitations

The canonical Go 1.27.1 toolchain cannot be downloaded in this environment, so all Go execution is `COMPATIBILITY_COPY_ONLY` on a disposable Go 1.23.2 copy; canonical `go.mod`, `go.sum`, `.go-version` are unchanged. Whole-tree `go test ./...` and `go vet ./...` are GREEN. Race coverage is GREEN across every repository package family; `internal/content/registry` would not reliably terminate as one aggregate race process, but all nine of its tests pass individually under `-race`. This limitation is not promoted to native proof. CA8-9 remains responsible for exact-toolchain/native PostgreSQL accumulated qualification. No W2 stock-client claim is made.
