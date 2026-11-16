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

## R6 undelivered-reply replay

Amends this contract with the operation/receipt-adjacent edge cache approved by the user on 2026-11-11
(`work/i9/stages/I9-11/contract_recovery/D2_PROPOSAL.md` sections 4 and 6; design
`work/i9/stages/I9-11/contract_recovery/R6_UNDELIVERED_REPLAY_DESIGN.md`). The transactions and receipts themselves
do not change; the cache only lets the edge answer a resend with a reply that already committed.

> 1. **Marking.** When a state-changing operation commits but its reply is not delivered, the edge marks that operation's receipt UNDELIVERED. Not delivered means the request context was cancelled before the write finished, or the write returned an error. The mark is a separate small write after the commit. If it fails, behaviour falls back to today's.
> 2. **Replay.** The next request from the same player and session token is answered with the stored reply, and no new operation runs, when:
>    - it has the same mid and the identical canonical params fingerprint;
>    - it arrives within `UNDELIVERED_REPLAY_WINDOW` (a tunable, default 10 minutes);
>    - no other state-changing request from that player came in between.
>
>    The replay consumes the mark.
> 3. **Otherwise the request runs as a new operation,** exactly as today. A deliberate repeat after a delivered reply never finds a mark, so it is never swallowed.
> 4. **No change to transactions or receipts:** they are written in the committing transaction as now, and natural-key replays stay. The replay only ever answers with a reply that was already committed.
> 5. **Counters:** replays and marks are counted, and a replay is journalled with its mid.
>
> **Limits:**
> - A reply lost after the server's write succeeded, for example dropped in transit with no disconnect seen by the server, is not detected. It falls back to today's behaviour.
> - The signal depends on the deployment passing a client disconnect through to the backend. zrok, and any reverse proxy, must be tested for this. If it does not pass through, the mark is never set, and behaviour stays as today.
> - **Original server: UNKNOWN.** The client gives no evidence that it deduplicated. This proposal adds safety on top of stock behaviour and changes nothing the client can observe on the success path.

Policy `UNDELIVERED_REPLAY_WINDOW_V1` is a PRIVATE_POLICY (`GXB_UNDELIVERED_REPLAY_WINDOW`, default 10m, refused
outside 1m..30m at startup). The mark stores the exact encoded reply bytes, keyed by player, with the resolved
session, the MID, a sha256 of the canonical JSON of the decoded params, and the mark time (migration 00166). The
single check runs before every gameplay MID handler through the one dispatcher decorator; `read` MIDs never touch it
and an `unknown` MID counts as state-changing.

## Proof boundary

Normal-chat I1 proves Go-level semantics, architecture, deterministic SQL ownership and offline tests. It does **not** prove PostgreSQL lock/commit behavior, goose/sqlc execution, River visibility/redelivery or failover semantics. Those remain W1 after I4 using real PostgreSQL/River and the stock client.
