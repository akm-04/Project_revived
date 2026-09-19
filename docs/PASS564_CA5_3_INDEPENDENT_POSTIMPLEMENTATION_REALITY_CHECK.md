# Pass564 — CA5-3 Independent Postimplementation Reality Check

## Candidate and authority

The inspected product tree descends from exact Pass562 v0.74.0 (`c357c29f...`). Sealed Pass563 is the CA5-3 source/candidate research, implementation-contract and acceptance authority; the user subsequently explicitly authorized CA5-3 implementation. This review does not infer acceptance from test success alone: it rereads the recovered current/historical source evidence, the Pass563 contract, produced codec/service/dispatcher code, concrete PostgreSQL owner adapters, CA5-2 aggregate/CAS/MID1 projection, D01/D04/D11 transaction/replay foundations and successor guards.

## Source and wire reality

The exact source-oracle guard remains GREEN against the pinned current src archive, v1.164 historical client and frozen V1 differential backend. Current effective create/adjust and modern delete carry `team_str`, `team_name_str`, and `pet_str`; the retained `HeroPresetWindow` delete omits `pet_str`. `Backend.lua` direct JSON encoding preserves absent-versus-present-empty. Historical source corroborates the two-string lineage but does not reveal the later server's Pet resolution. Therefore duplicate Hero/name legacy deletes with divergent Pet outcomes remain `UNKNOWN`; the V2 fail-closed policy is an implementation decision, not an original-server claim.

## Codec and compatibility reality

The full-form parser is strict and projectable: it preserves exact lane ordering, actor-scoped Hero refs, optional Pet refs and wire round-trip, rejects noncanonical/misaligned live commands, and does not import UI-only VIP/name/team-size policy. Legacy omission is resolved only against the locked canonical aggregate. Converged Hero/name state is a no-op; otherwise all matching single-lane deletions are enumerated and accepted only when they yield one identical complete aggregate. Divergent complete results fail closed.

## Transaction, ownership and concurrency reality

Every transaction attempt fences the actor, rereads current saved-preset state, computes old∪desired external references, derives canonical Hero rank410/Pet rank430/root rank440 order, locks and owner-validates the Hero/Pet rows through CA5-1 typed ports, locks the saved-preset root, rereads canonical state and checks `Covers`. An uncovered identity returns `MarkDefiniteAbort` before mutation so the runner retries the entire body and regenerates the plan. Covered drift is re-resolved against the locked state and may proceed. The concrete `characterstore` owner adapters validate exact typed lock keys and exact actor-owned rows; the saved-preset store performs only saved-preset SQL and one expected-version root CAS. No foreign Hero/Pet SQL or parallel durable owner was introduced.

## Revision, receipt and UNKNOWN-COMMIT reality

Semantic convergence performs no saved-preset replacement and leaves root version/timestamp unchanged. Genuine replacement advances `StateVersion` by exactly one and uses the stable operation start only as metadata timestamp. Both mutation and convergence record one same-attempt semantic receipt whose fingerprint preserves `pet_present`. Receipt identity is op-scoped, not a stock nonce. The generic fresh resolver proves ambiguous COMMIT only from matching receipt presence; absence remains UNKNOWN and never authorizes replay. Later stock HTTP retries use a new operation and converge from canonical state, so A→B→A remains two legitimate mutations.

## Stockruntime, reload and successor reality

Production composition registers only MID1793 to the dedicated saved-preset dispatcher. HTTP-200 success returns canonical `save_team`, `save_team_name`, `save_pet`; local failures do not invent a stock `error_code`. CA5-2 MID1 projection reads the same canonical aggregate and calls the same `ProjectWire`, so local reload projection is structurally identical to mutation projection; real reconnect/PostgreSQL proof remains part of the mandatory native aggregate gate. Replay catalog has exactly one CA5 saved-preset mutation family classified `CURRENT_STATE_CONVERGENCE`. CA5-1/CA5-2 milestone guards were successor-qualified only for MID1793/replay; MID208/209, `17.formation`, CA5-4 reverse guards, I9 state and CA8 snapshot remain absent.

## Testing and environment classification

Exact Python/static/query/source-oracle guards are GREEN on canonical. Canonical Go execution is `ENVIRONMENT_BLOCKED` because the local Go toolchain is 1.23.2 while canonical requires Go >=1.26/toolchain 1.27.1. A fresh disposable copy differing only in `go.mod` toolchain/language declarations and `.go-version` passes focused tests, focused race, focused vet, concrete characterstore tests, full `go test ./...`, full `go vet ./...`, and 93/93 package regression. These executable results are `COMPATIBILITY_COPY_ONLY`. PostgreSQL-tag production compilation is separately environment-blocked by unavailable `pgx/v5` with module lookup disabled; real PostgreSQL/River semantics remain mandatory immediately before CA5-E.

## Verdict

`GREEN_LOCAL_CA5_3_ACCEPTED_COMPATIBILITY_COPY_ONLY_NATIVE_AGGREGATE_DEFERRED_PRE_CA5_E`. No demonstrated defect or contract contradiction requires reopening CA5-1, CA5-2 or CA5-3. This is a CA5-3 local checkpoint, not CA5 parent acceptance. After Pass564 HOT+COLD seal, the next permitted work is CA5-4 preimplementation research/reconciliation only.
