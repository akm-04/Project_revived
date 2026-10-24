# Pass455 R2B — transaction-aware character bootstrap ownership/projection

Status: **LOCAL GREEN; FOUNDATION REPAIR CONTINUES; I6 BLOCKED.**

## Repair

R2B closes RF-007 locally without implementing RF-015. The MID1 creation transaction now inserts the I3 player root/directory projection, runs required owner persistence contributors on the caller-owned `tx.Tx`, then projects current canonical MID1 state before context/credential/receipt completion. I5 owns its Player Core inserts in `i5store`; `i4store` no longer writes I5 canonical tables.

Projection contributors declare owned MID/field paths. Registration names are unique and overlapping parent/child/exact claims fail closed before service execution. Optional persistence contributor failure policy is not invented: non-required registrations are rejected until a frozen policy exists.

## Evidence

Disposable Go 1.23 clone: repository `go test ./...`, `go vet ./...`, targeted race, R0/R1A/R1B/R2A/R2B and I1-I4 validators all pass. Strict canonical table ownership passes with no RF-007 allow-list. The aggregate foundation check remains RED only because RF-015 EconomyBootstrap/temporal bootstrap is intentionally not part of R2B.

R7 retains real PostgreSQL creation rollback/concurrency proof.
