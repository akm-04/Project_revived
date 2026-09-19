# Work-mode environment precheck (operator-provided evidence)

Date: 2026-09-06.

The operator reported a separate Work-mode session with the following environment successfully installed/verified before I1 delivery:

- Go 1.27.1
- PostgreSQL/psql 18.6, listening locally on 127.0.0.1:55432 with a `gxb_test` database
- sqlc 1.31.1
- goose 3.27.3
- govulncheck 1.7.0
- Lua 5.4.6
- jq, socat, netcat, GCC, Make, Git and Python
- cached pgx 5.10.0, River 0.45.0, chi, Testcontainers, OpenTelemetry, Prometheus and goAMF3 dependencies

The operator also reported that the Pass433/I0 repository built with Go 1.27.1 and that `govulncheck` found no vulnerabilities. The combined I0 script stopped only because the five large read-only oracle archives were not attached to that separate chat.

This is **operator-provided preflight evidence**, not a Pass434 execution result from this repository snapshot. In particular:

- I1 currently pins River v0.47.0, so the W1 environment must resolve/cache that exact version (or a later explicit reviewed pin) before tagged I1 compilation is considered proven.
- real PostgreSQL/River transaction, locking, unknown-COMMIT, crash/redelivery and Wave-S stock-client tests remain W1 after I4.
- the restricted UID initialization shim reported by the Work environment is acceptable only as an environment bootstrap detail and must not change PostgreSQL transaction/WAL/locking semantics.
