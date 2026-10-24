# Pass511 — CA1 Independent Reality Check (PRE-NATIVE, UNSEALED)

Date: 2026-09-11
Scope: current-agent independent reread of authoritative design/source evidence plus direct inspection of the produced CA1 code after local testing. This is not a claim that a second human/model reviewer participated.

## Outcome

**GREEN_FOR_NATIVE_GATE; NOT CA1 ACCEPTANCE.**

No product-code defect was found in this reality-check pass. No new source discovery required reopening the approved CA1 design. Exact-toolchain and real PostgreSQL behavior remain unproven in this environment and are mandatory before CA1 can be accepted/sealed.

## Authority reread

### D01

**SOURCE_FACT:** Pass463 D01 requires complete effect/lock planning before mutation, caller-owned transactions, global lock order, narrow owner ports, and no out-of-order lock discovery after mutation.

**OBSERVATION:** CA1 provider preflight returns its complete Character lock set before `acquireGrantLocksTx`; all returned keys are restricted to 400–599 and merged with the existing canonical Grant plan. Provider locked validation/apply has no API to return additional lock requirements.

**LIMITATION:** an implementation of the future provider could violate its documented contract internally (for example by issuing an undeclared lock query). CA2+ provider acceptance must architecture-test/DB-test the concrete provider; CA1 cannot prove behavior of providers that do not yet exist.

### D03

**SOURCE_FACT:** Pass475 D03 requires typed materializers keyed by semantic Grant + stable line identity and forbids universal Hero/Pet identity collapse.

**OBSERVATION:** CA1 line identity is exactly semantic Grant key + original ordinal; ItemID and Amount are preserved opaque to I5; result payload is provider-owned typed JSON and there is no generic durable `entity_id` field.

### Exact source/client evidence

**SOURCE_FACT:** current `src_64` and v1.164 both distinguish `partner_id`, `pet_id` and `style_pet`; current/historical Pet model exposes separate appearance state and style MIDs.

**OBSERVATION:** produced CA1 code has no Pet routing, no `style_pet` interpretation, no Hero/Pet family inference and no appearance mutation.

## Produced-code review

The Pass509-to-CA1 implementation footprint is intentionally narrow:

- modified `internal/application/i5/grant_lock_plan.go`;
- modified `internal/application/i5/grant_receipts.go`;
- modified `internal/application/i5/service.go`;
- added `internal/application/i5/partner_materializer.go`;
- added `internal/application/i5/material_cost.go`;
- added `internal/application/i5/ca1_test.go`;
- added `tools/check_ca1_source_oracle.py`;
- added `tools/validate_ca1.py`.

No migration was added and no production wiring file was changed.

### Redeem repair

**SOURCE_FACT:** old Pass509 Redeem locked Progression before `SettleGrantTx`, while Grant can require Economy before Progression.

**STRONG_INFERENCE:** this created a possible 710->700 ordering inversion under a competing 700->710 Grant.

**OBSERVATION:** CA1 forces Progression into the preplanned Grant suffix, acquires the suffix, then obtains progression state for eligibility. The eligibility function itself is unchanged.

**LIMITATION:** fake/local tests establish call ordering but do not establish PostgreSQL lock scheduling, SERIALIZABLE snapshot visibility, deadlock behavior, or retry/reconciliation. Real PostgreSQL 18.6 contention testing is mandatory.

### Receipt/replay

**OBSERVATION:** fungible-only results retain v2 and omit `materializations`; entity results use v3; decoder accepts v1/v2/v3. Provider apply is bypassed by a preflight receipt replay.

**LIMITATION:** the post-lock replay lookup is defensive but its visibility under PostgreSQL SERIALIZABLE transactions must not be inferred from in-memory receipt tests. Acceptance relies on authoritative retry/receipt behavior proven in the real-DB gate.

### Material debit

**OBSERVATION:** content qualification happens before locks; Economy/Scalar/Stack ordering matches existing I5 rank order; all next states are computed before first intentional save/delete; caller transaction remains external.

**OBSERVATION:** the port does not expose I5 Store wholesale and cannot debit Temporal, PlayerExp or entity destinations.

## Local evidence classification

- **RUNTIME_OBSERVED / COMPATIBILITY_COPY_ONLY:** fresh adapted copy (`go 1.23.0`, toolchain directive removed; no other compatibility edit) passed `go test ./...`, `go vet ./...`, `go test -race ./...`, and an 84/84 package-by-package regression.
- **RUNTIME_OBSERVED:** source/oracle, schema/query ownership, sqlc-generation policy, dependency policy, I5 and R5 static validators passed against the canonical candidate.
- **RUNTIME_OBSERVED:** exact canonical candidate cannot execute Go tests here because installed Go is 1.23.2 while canonical requires `go >=1.26.0` and pins toolchain 1.27.1.
- **ENVIRONMENT_BLOCKED / NOT_RUN:** PostgreSQL 18.6, sqlc 1.31.1 and exact Go 1.27.1 native gate; `psql`, `postgres`, `pg_ctl`, `sqlc` are absent in this container.
- **SUPERSEDED:** legacy `validate_r6.py` fails on untouched Pass509 for historical no-migration/toolchain assumptions, so it is not CA1 regression evidence.

## Decision

`CA1_IMPLEMENTATION_LOCAL_GREEN_NATIVE_REAL_DB_PENDING`.

Next: run the exact candidate unmodified in the native/real-PostgreSQL environment described by `PASS511_CA1_NATIVE_WORK_PROMPT.txt`. On return, reconcile evidence in normal chat before any seal or CA2 implementation.
