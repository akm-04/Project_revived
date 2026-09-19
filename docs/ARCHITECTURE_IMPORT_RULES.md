# Import and canonical-ownership rules

The executable top-level dependency matrix is `internal/archguard/archguard_test.go`; this document is explanatory, not a substitute for that guard.

- `internal/foundation/*` → foundation only.
- `internal/domain/*` → domain + foundation only. Domain must never point outward to application, protocol, projection, adapters or persistence mechanisms.
- `internal/protocol/*` → protocol + foundation only.
- `internal/projection/*` → projection + domain + foundation only; never adapters/protocol.
- `internal/application/*` → application + domain + foundation only; orchestration cannot import concrete adapters.
- `internal/adapters/*` is the composition edge and may depend inward on registered layers/sibling adapters.
- pgx/sqlc integration remains in PostgreSQL adapters; River packages remain in River adapters.
- current source/domain code cannot read wall-clock time directly where an authoritative operation clock is required.

Canonical SQL ownership is separately executable through `docs/architecture/CANONICAL_TABLE_OWNERSHIP.json` and `tools/check_schema_query_ownership.py`. Every production-created table must have a registered owner and creating migration. Operational reads/writes—including inline SQL in Go—must originate from allowed paths. Cross-owner mutations require a narrow explicit exception or an application-owned composition seam; simply importing no forbidden Go package is not proof of storage ownership.

Strict ownership validation intentionally fails while known RF-007 I5 bootstrap writes remain in the I4 PostgreSQL adapter. Do not weaken the guard to regain green; R2 removes the underlying leak.
