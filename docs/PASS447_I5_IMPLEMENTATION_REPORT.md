# Pass447 / I5 Implementation Closure Report

## Verdict

**GREEN for the normal-chat I5 implementation gate; real PostgreSQL/River and stock-client mechanism acceptance remains explicitly deferred to W2.** I5 is complete enough to advance to I6 after this backend and PassMap are sealed.

This verdict does not turn deferred client acceptance green. Pass445 sequencing remains controlling: comprehensive stock-client convergence/reconciliation is W2 work after I14.

## Implemented ownership and transaction surfaces

- Canonical Player Core ownership for profile/progression/story/function-unlock/guide-return state.
- TypedEconomy scalar, temporal, stack and PlayerExp owners; no universal wallet or generic gameplay blob.
- Canonical Grant settlement with source-business semantic identity, durable receipts, replay reconstruction, actor fencing for gameplay calls and explicit unsupported-owner fail-closed behavior.
- Stack overflow policy that atomically credits the fit portion and creates durable Mail; Mail claim cannot recursively overflow or burn the entitlement while the stack remains full.
- Durable Mail list/single-claim/one-key orchestration for MID368/MID369/MID370 with `(namespace, wire_id)` identity, deterministic batch identity and stable receipt replay.
- Objective committed-semantic-fact application, completion-vs-claim separation, claim receipt and Grant composition for MID161/MID2736.
- MID230 Redeem as a direct Grant entitlement path with exact-code HMAC lookup, no durable raw code and no Commerce authority.
- Player Core/economy/mail overlay into existing-player MID1 detail through the I5 contributor seam; new-player bootstrap continues to use bounded source-safe compatibility defaults and does not fabricate starter balances/items.
- Canonical AdminOperator Grant/Mail application seam using the same owners, semantic receipts and an audit emitter. Authenticated operator transport, durable control-plane audit storage, recipient search and bulk/cross-server orchestration remain I11 responsibilities.
- Versioned resource and Objective policy registries in forward-only migration `00006_i5_transactional_policies.sql`.

## Source/oracle reconciliation retained during implementation

Current packaged `src_64` remained an active implementation oracle throughout I5. The I5 oracle guard rechecks the current archive hashes and the source surfaces for SelfPlayer/StoryData, Mailbox/MailboxWindow, Backpack/ItemTable, Task, MID230 ExchangeCodeWindow and relevant `mid.lua` assignments. The old-client ExchangeCodeWindow remains corroborative for MID230 stability. Pass353 remains a frozen executable/source differential oracle only; none of its private nonce, synthetic catalog or authority-coupling architecture was copied.

One source-sensitive wire distinction was preserved: MID369 can return a named scalar resource in reward `item`, while MID370/MID230 bulk awards require a numeric `table_id`. I5 therefore refuses to fabricate a numeric identity when the source does not establish one.

No source finding discovered during I5 required reopening Acceptance or Design.

## Targeted MID230 refinement

The stock MID230 request supplies `{code, platform}` and no semantic retry nonce or redemption-slot identifier. Therefore an intentional second use of the same public code by the same subject cannot be distinguished from a retransmission. The stock route is constrained to semantic slot 1 per `(code, subject)`. Multiple intended entitlements can be represented by distinct generated codes. This is a bounded evidence-driven refinement and does not create a client compatibility exception.

## Normal-chat execution evidence

A fresh disposable copy was patched only for local compiler compatibility (`go 1.23.0`, toolchain line removed); the canonical tree stayed pinned to `go 1.26.0` / `toolchain go1.27.1`.

The latest disposable-clone run is green for:

- `go test ./...`
- `go vet ./...`
- architecture guard
- targeted `-race` across I5 application, economy/grant/mail/objective/redeem domains, stock runtime and bootstrap contributor
- semantic Grant replay and fingerprint conflict
- ambiguous-COMMIT reconciliation without Grant replay
- unsupported Partner/Generated owner rejection without mutation or success receipt
- stack overflow -> durable Mail
- recursive-overflow Mail-claim prevention
- committed Objective fact replay prevention
- Objective claim replay -> one Grant
- AdminOperator Grant/Mail canonical-owner and audit/replay tests
- MID369 normal-namespace/named-resource wire behavior
- MID370 compound-address canonicalization and numeric bulk awards

Static/oracle validation is green for I1-I5, src_64/Pass353 differentials, schema/query ownership, sqlc policy, dependency policy, oracle hashes, generated MID registry and Pass353 wire fixtures.

## Seal-time defect caught and repaired

During final closure, migration `00006_i5_transactional_policies.sql` was found to contain a `-- +goose Down` marker even though it had no rollback SQL. The schema ownership guard correctly rejected this because production migrations are forward-only by project law. The marker was removed and the guard chain rerun green. `tools/validate_i5.py` now explicitly rejects a Down marker in either I5 migration so the issue cannot silently regress.

## Wave-E 30-case gate

All 30 frozen Pass415 cases are represented in `PASS447_I5_WAVE_E_EXECUTION_MAP.json`. Normal-chat executable or structural evidence is recorded where that mechanism is actually testable. Cases whose assertion fundamentally requires real PostgreSQL row locking/fault injection, River crash/retry/restart, or an unmodified stock client are explicitly placed in the W2 live bucket and are **not** called green.

This satisfies the I5 roadmap requirement that every named case be represented by executable evidence or an explicit later-live bucket without substituting mocks for PostgreSQL/River semantics.

## Explicit non-proof / W2 boundary

The local sandbox cannot complete `-tags postgres` compilation because pgx v5 module bytes are not present in the local module cache and outbound module resolution is unavailable. This is recorded as **NOT EXECUTED TO COMPLETION**, not PASS.

Consequently Pass447 does not claim fresh I5 proof for:

- exact Go 1.27.1 tagged builds,
- real PostgreSQL 18.6 I5 row-lock/transaction/fault-injection semantics,
- River crash/retry/restart semantics,
- process/database restart reconstruction,
- unmodified stock-client S0/S3/MID18/MID1/realtime/gameplay acceptance.

Those remain W2/Work-mode gates. Historical Pass441 PostgreSQL/River evidence remains valid for the foundations it actually exercised, but it is not misrepresented as proof of newly added I5 tables.

## Bounded unknowns intentionally preserved

I5 does not invent starter balances/items/heroes, hidden mail expiry/purge duration, non-source reward IDs, synthetic logical servers, or a client nonce that does not exist. Temporal resource anchors that need content policy are left for I6 generation/policy activation rather than guessed during Grant settlement.

## Next

After Pass447 backend + HOT/COLD PassMap seal, proceed to **I6 — Generation / Scheduler / Guild / shared foundations**, continuing current `src_64` and Pass353 differential checks. Do not restart I4 tablet debugging.
