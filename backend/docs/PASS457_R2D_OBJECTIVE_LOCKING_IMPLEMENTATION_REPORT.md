# Pass457 R2D — Objective base-row locking correction

Status: **LOCAL GREEN; R2 COMPLETE; FOUNDATION REPAIR CONTINUES; I6 BLOCKED.**

## Repair
RF-022 is locally repaired without changing Objective business semantics. The stock Objective claim lookup now uses a `MATERIALIZED` candidate CTE whose SELECT from `player_mission_instances i` carries `FOR UPDATE OF i` inside the CTE itself. The outer/derived unique-candidate query no longer pretends to lock the canonical base row.

If the stock claim omits a generation hint and more than one active candidate exists, the query still fails closed: candidate rows are locked, but `unique_candidate` returns no row unless exactly one candidate exists. The family+generation `LockObjectiveTx` path already locked `i` correctly and is unchanged.

Claim, same-transaction Grant settlement, Objective state update and semantic receipt remain in the caller transaction through the R2C seam.

## Evidence
Disposable Go 1.23 clone: full repository tests/vet pass; targeted race over I5 store/application/objective passes; R0→R2D validators and strict table ownership pass. A dedicated SQL structural test asserts that `FOR UPDATE OF i` is inside the canonical candidate CTE and absent from the outer derived query. A stock `ClaimObjectiveByID` replay test proves repeated semantic claim grants and saves exactly once.

The aggregate normal-chat foundation check remains intentionally RED only for RF-015 EconomyBootstrap/temporal bootstrap.

## Deferred live proof
R7 retains exact Go 1.27.1 and real PostgreSQL concurrent double-claim/lock-wait proof. Local SQL/string/unit tests are not promoted to PostgreSQL lock proof.

## Next
R2 is complete locally. Proceed to R3 protocol/runtime/evidence hardening from the sealed Pass457 backend.
