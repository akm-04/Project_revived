# Pass476 R4D implementation report

## Outcome

R4D immutable-content consumption/revision pinning is implemented on the exact Pass474 v0.54.4 repair baseline. This is a bounded local closure only. Exact pinned Go 1.27.1 execution and native PostgreSQL 18.6/River proof were unavailable in normal chat and remain separate gates. The mandatory end-R4 real PostgreSQL Work gate remains next before R5.

## Candidate-bound research

Research was completed before coding and recorded in `docs/PASS476_R4D_PREIMPLEMENTATION_RESEARCH_CLOSURE.md`. PASS467/PASS453 remain controlling contracts. Current `src_64` is the active source/effective-client oracle; frozen Pass353 V1 is corroborative/differential only.

## Implemented behavior

- Grant semantic identity v2 is `Domain + Operation + BusinessKey + Occurrence`; content/policy revision is not a business entitlement dimension.
- Exact legacy-v1 Grant identity reconstruction remains available for replay. Lookup is v2 then v1; new writes are v2 only; conflicting terminal v2/v1 receipts fail closed.
- Overflow-mail semantic identity is explicitly versioned for v2 while the historical form remains reconstructable.
- Existing semantic receipts replay before an active-content lookup. Genuinely new work binds the active immutable `content` policy ref exactly once before first mutation.
- The bound operation context is retained across definite-abort transaction retries and nested Mail/Objective/Redeem -> Grant settlement.
- Durable receipts persist `operation_policy_refs`; the content revision is not folded into the business-plan fingerprint.
- Content-owned exact-revision reads cover enabled scalar currency/qualified normal stack resources and objective definitions.
- Legacy temporal state resolves exact persisted `(resource_key, policy_version)` without `active=true`.
- Immutable-content temporal state and Player EXP remain fail-closed behind R5; no R5 temporal/bootstrap mechanics are activated here.
- Legacy objective instances resolve exact persisted `(program_id, objective_id, definition_revision)` without `active=true`; immutable-content objective instances resolve their exact persisted content revision.
- MID1 temporal reload no longer interprets persisted rows through today's active legacy registry row.
- Content SQL remains owned by the content adapter; I5 uses a typed `ContentRuntime` port.

## Preserved foundations

- `go.mod`, `go.sum`, `.go-version` remain canonical and unchanged.
- migration00009 remains byte-identical.
- migration00010 remains byte-identical and is preserved as the Pass474 JSON-null manifest-identity forward repair.
- No new migration is introduced by R4D.
- RF015 economy/temporal bootstrap remains assigned to R5.
- I6 remains blocked until R7 green and sealed.

## Local test gate

The required exact disposable-copy attempt was performed first. It was `ENVIRONMENT_BLOCKED`: installed Go is 1.23.2 and the untouched candidate attempted to fetch pinned Go 1.27.1, but outbound DNS/network is unavailable. This is not product failure and is not exact-toolchain proof.

A fresh disposable compatibility copy changed only Go language/toolchain metadata required to execute with installed Go 1.23.2; `go.sum` and product files were unchanged. Results are `COMPATIBILITY_COPY_ONLY`:

- focused R4D tests: PASS
- full `go test ./...`: PASS
- focused `go test -race`: PASS
- `go vet ./...`: PASS
- R4D static guard: PASS
- generated content query text: PASS
- schema/query ownership: PASS
- dependency/sqlc generation policy static checks: PASS
- R0-R4C and I1-I4 validators: PASS
- current client/source oracle checks: PASS
- Pass353 R4A differential: PASS when invoked with the supplied oracle archive

`validate_i5.py` remains RED only for the two authoritative RF015/R5 requirements: EconomyBootstrapContributor and temporal-resource bootstrap persistence. They were not waived or implemented in R4D.

`sqlc --execute`, exact Go 1.27.1 execution, PostgreSQL-tagged dependency acquisition, native PostgreSQL, Goose, concurrency/crash and backup/restore proof remain `ENVIRONMENT_BLOCKED/NOT_RUN` in normal chat.

## Reality review

A separate post-implementation evidence review by the same agent, not another reviewer, is recorded in `docs/PASS476_R4D_INDEPENDENT_REALITY_CHECK.md`. It found no R4D contradiction requiring code repair.

## Next gate

Do not begin R5. Run the authoritative `R4_EARLY_REAL_POSTGRESQL_DE_RISK` Work gate after this R4D seal and before R5, including migration00010. That gate does not replace R7 or W2.
