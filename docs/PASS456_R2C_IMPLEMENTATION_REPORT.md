# Pass456 R2C — caller-owned Grant composition and creation fencing

Status: **LOCAL GREEN; FOUNDATION REPAIR CONTINUES; I6 BLOCKED.**

## Repair

R2C closes RF-020/RF-021 locally without implementing RF-015 or R5 economy behavior.

The canonical I5 Grant owner now exposes a narrow `TxGrantSettler` / `SettleGrantTx` seam that receives the caller-owned `tx.Tx`, ActorContext, operation.Context and Grant plan. It never begins, commits, rolls back or retries an inner transaction. Standalone `SettleGrant` remains a wrapper around the same transaction-scoped implementation. Mail, Objective and Redeem same-transaction settlement use that public seam.

Before the first entitlement mutation, Grant preflights the entire plan: validates every line, resolves every resource policy, rejects unsupported owner destinations, derives the complete I5 lock requirement set, canonicalizes/deduplicates typed LockKeys and acquires the required locks in deterministic order. Potential stack-overflow Mail allocation prepares/locks the NORMAL mail namespace before TypedEconomy locks, avoiding a resource->mail suffix that would invert Mail-claim -> Grant ordering.

Migration 00008 adds `player_economy_owners`, a per-player synchronization/creation-fence row containing no gameplay balance or content. Existing players are backfilled and fresh characters receive the row through `EconomyOwnerBootstrapContributor`. Scalar/stack absent-child creation therefore occurs only while an existing per-player owner fence is held; child uniqueness remains the second fence. Required temporal rows are deliberately not fabricated and still fail closed until the R4/R5 source-policy/bootstrap repair.

## Evidence

Disposable Go 1.23 clone: repository `go test ./...`, `go vet ./...`, targeted race, R0/R1A/R1B/R2A/R2B/R2C and I1-I4 validators all pass. Strict canonical table ownership, dependency policy, sqlc policy and resolved-SBOM checks pass. R2C tests prove the caller-owned transaction is not nested or finalized by Grant, the exact caller tx reaches owner operations, and permuted Grant line order yields the same canonical lock prefix.

The aggregate foundation check remains RED only because RF-015 EconomyBootstrap/temporal bootstrap is intentionally not part of R2C.

## Deferred live proof

R7 retains real PostgreSQL first-use scalar/stack creation races, different-player independence, lock-wait/deadlock behavior and pgxpool transaction integration. Mocks are not promoted to PostgreSQL proof.
