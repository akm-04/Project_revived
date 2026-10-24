# I1 foundation contract — implementation-facing summary

Pass434/I1 implements the reusable transaction/persistence kernel frozen by Wave A and integrated by Wave L. It is infrastructure, not gameplay authority.

## Canonical invariants

1. **One semantic operation, disposable transaction attempts.** `operation.Context` is created once. Internal retries reuse its start time, entropy seed, operation ID and policy references.
2. **Only definite aborts are ordinary retry candidates.** SQLSTATE `40001` and `40P01`, plus driver evidence normalized as a definite rollback, may consume the bounded whole-operation retry budget when the command opts in.
3. **COMMIT transport failure is UNKNOWN.** Never rerun the command body until a fresh authoritative-writer resolver proves committed or proves absence and that command's policy explicitly allows replay after that proof.
4. **Unknown-COMMIT reconciliation survives caller cancellation.** It runs with a separate bounded context because safety reconciliation must not disappear when a client disconnects.
5. **Source effect + receipt/fact/obligation share the same PostgreSQL transaction.** `receipt.Store`, generic `tx.FactAppender[T]`, and `obligation.Queue` all accept the same `tx.Tx`. Domain facts remain typed and domain-owned; there is no generic fact table.
6. **Lock ordering is typed and total.** `lockkey.Canonical` sorts by domain rank, owner kind, identity type and canonical identity bytes. Missing-row creation requires an existing parent/directory/generation/allocator fence plus uniqueness; locking an absent child is never treated as protection.
7. **No generic gameplay lock/version/outbox tables.** I1 owns only `gxb_operation_receipts`. Later domain owners add their own canonical rows/version/fence fields. River and goose own their mechanism tables behind adapters.
8. **No network/provider I/O in canonical transaction packages.** Architecture guards reject external `net/*` and provider adapters from `internal/foundation/tx` and `internal/domain`.
9. **Finite transaction profiles and bounded admission.** Pool admission happens before `Begin`; canonical transactions apply local lock/statement/transaction timeouts and use independent bounded rollback cleanup.
10. **Observability is non-authoritative.** High-cardinality player/account/request identifiers are rejected from metric labels. Secrets, auth tokens, provider raw receipts and message contents are redacted.

## PostgreSQL adapter boundary

`internal/foundation/tx` and domain packages do not import pgx. The build-tagged PostgreSQL adapter maps project isolation/access options onto pgx and normalizes pgx-specific terminal signals. The receipt repository depends only on the project transaction/query interfaces.

Pool configuration must provide a positive finite maximum, valid min/max bounds, and positive lifetime/idle/health periods. Long-lived sockets never own database connections.

## River boundary

River is available only behind `internal/adapters/river` and `obligation.Queue`. A durable obligation is inserted with the same canonical PostgreSQL transaction. River job IDs, leases and worker identities are execution mechanics, never gameplay/domain identities or idempotency authority.

## Proof boundary

Normal-chat I1 proves Go-level semantics, architecture, deterministic SQL ownership and offline tests. It does **not** prove PostgreSQL lock/commit behavior, goose/sqlc execution, River visibility/redelivery or failover semantics. Those remain W1 after I4 using real PostgreSQL/River and the stock client.
