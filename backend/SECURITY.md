# Security policy

- No secret values in logs, metrics, traces, receipts, fixtures, or committed configuration.
- PostgreSQL is the sole gameplay authority. SQLite is never gameplay persistence.
- No provider/external-network calls while canonical gameplay database locks are held.
- Unknown COMMIT outcomes are reconciled; never blindly replay a value mutation.
- Run `govulncheck ./...` after dependencies are resolved in a connected Go 1.27.1 environment.
- Dependency updates require version, security, license, SBOM, and compatibility review.

## Historical MID1 v1 receipt retention (Pass452 R1B)

Pass452 stops creating `gxb.mid1.stock.v1` receipt payloads containing raw gameplay bearer material. New MID1 receipts use `gxb.mid1.select.v2` and store immutable non-secret selection metadata only; current bearer/detail/is_new are reconstructed from canonical identity/player owners. Existing v1 rows and backups may still contain historical bearer material and MUST be treated as credential-bearing retention data: do not print/log/export their payloads, do not use them as current hydration truth, and apply normal protected-backup retention/destruction controls. Pass452 accepts their immutable selection metadata for compatibility but never materializes their token/detail fields. Versioned retained-key rotation remains EX-01 and is not silently claimed solved here.
