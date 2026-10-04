# Pass624 I7A-2 independent postimplementation reality check

## Result

**GREEN for local implementation completeness. Exact canonical-toolchain acceptance is not claimed.**

I independently re-read the eight selected Pass622 I7A-1 contracts, the Pass623 I7A-2 implementation contract/acceptance matrix, exact Pass618 parent identity, and exact current `src_64` evidence before judging the implementation. All eight selected I7A-1 contract hashes still match their sealed index. No superseded I7A draft was used as authority.

## Candidate/ownership reality

- I4/`stockruntime` remains the realtime connection owner. Each admitted socket still has one `connWriter`; only `realtime_writer.go` contains production `conn.Write`.
- `SessionHandle` exposes immutable admission/liveness metadata and writer-backed publication only. Raw `net.Conn` remains private teardown state. Replacement is generation-fenced by ContextID+PhysicalRole and secondary player/role + room/role indices preserve multiple contexts.
- During WP5 a genuine defect was found in the first implementation: the session lifecycle mutex was held while waiting for network completion, which prevented retirement from closing a blocked old socket. Canonical code was corrected by splitting bounded writer enqueue from completion wait. The lifecycle mutex now serializes only queue admission versus retirement; it is released before network wait, so private socket close interrupts a blocked old writer. Fresh compatibility-copy tests/race prove the corrected behavior.
- Numeric MIDs remain in protocol/adapter layers only. MID514/516 now override the numeric-plane heuristic to TCP/AMF3/S2C, selected direct-event roles are source-bound, generic notice schemas key parent MID + namespace + notice_type, and zero production direct/notice producers are activated.
- I5 alone reads `player_profiles.player_type`; application presentation composes I4 directory facts + the narrow I5 reader. Query ownership tooling is GREEN and no PlayerType range was invented.
- MID17 title/bubble changes are compatibility projection only: title 0/0/0 and content-pinned bubble 10001/end_time 0. Exact current `src_64` oracle is GREEN 38/38. No I7B entitlement/equipped ownership was introduced.
- Wakeup payloads are bounded, versioned references only. Route handlers are explicitly `ReloadAndDeliver`; the registry starts empty and production contains zero route registrations. The dependency-free reconnect/loss state machine is locally exercised. The concrete pgx listener acquires its own pool connection and never uses `RealtimeOwnerGuard` state. Real PostgreSQL listener proof remains activation-gated NOT_RUN.

## Defect/proof reconciliation performed during implementation

1. **Session retirement lock/I/O defect — fixed in canonical.** Fresh candidate testing was restarted after the fix.
2. **Reconnect unit tests initially sat behind the pgx build tag — corrected.** The pgx-independent listener state machine and transaction-bound `pg_notify` emitter were split into untagged code so the frozen contract's local reconnect/lifecycle proof executes without pretending to prove real pgx/PostgreSQL semantics.
3. Test-only helper/timing defects found by early compatibility copies were corrected in canonical and each diagnostic tree was discarded before fresh retest. No compatibility-only toolchain edit was copied into canonical.

## Proof classification

Canonical dependency pins are byte-identical to Pass618. Canonical static/query/ownership checks and exact source oracle are GREEN. A fresh disposable Go1.23.2 compatibility copy passes focused tests, focused race, full `go vet`, and 96/96 package-by-package default regression. `staticcheck`, `sqlc`, `golangci-lint`, and `govulncheck` are unavailable in this environment; repository-native SQLC-generation/query ownership checks are GREEN.

Exact canonical execution is **ENVIRONMENT_BLOCKED** because canonical requires Go >=1.26 with pinned Go1.27.1 while the sandbox has Go1.23.2 and cannot fetch the pinned toolchain. Concrete `-tags postgres` compilation is separately environment-blocked because pgx is not cached and GOPROXY is intentionally off. Compatibility-copy results are diagnostic only and are not exact-canonical or PostgreSQL proof.

## Reopen/exit verdict

No sealed I7A-2 reopen trigger fired: no migration/schema need, no second writer/raw feature socket, no unsupported producer role/schema, no application MID dependency, no authoritative NOTIFY payload, no cosmetic entitlement ownership, and no source contradiction. I7A-3+ were not implemented. I7A-10, I7A-E and W2 remain mandatory and unpassed.
