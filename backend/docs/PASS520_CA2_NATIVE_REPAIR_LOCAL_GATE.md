# Pass520 CA2 native-repair normal-chat gate

`RUNTIME_OBSERVED`: The Pass519 pinned-sqlc defect was independently repaired from pristine Pass519 by changing only the Hero expected-CTE projection syntax in `sql/content/content.sql` and regenerating Content query text. The generated query text matches Luna's repaired output byte-for-byte.

`RUNTIME_OBSERVED`: Canonical Pass520 passes dependency/SBOM/sqlc-policy/connected-candidate checks, all exact CA1/CA2 source-oracle checks, deterministic builtin content regeneration, kernel/Character/Content query-text checks, schema/query ownership, cumulative CA2-1/CA2-2/CA2-3 validators, cumulative R5/R6, and current-candidate validation.

`COMPATIBILITY_COPY_ONLY`: A fresh disposable Go-1.23.2 clone changed only `go.mod` and `.go-version`. Focused CA2 tests PASS; focused race PASS; full `go test ./...` PASS; full `go vet ./...` PASS; bounded package regression 89/89 PASS.

`LIMITATION`: Normal chat still lacks pinned sqlc 1.31.1 and PostgreSQL 18.6. The first Work run already proved the proposed SQL repair under pinned sqlc/PostgreSQL, but Pass520 itself requires a second exact-candidate Work gate. Real PostgreSQL Hero mutation/concurrency and forced ambiguous COMMIT remain mandatory gaps. Stock client remains environment-dependent.
