# CI-style local gate

Normal chat/offline: `./tools/check.sh`.

Connected Go 1.27.1 environment: `./tools/check_pinned_toolchain.sh`, then resolve the exact modules used by the current implementation wave, regenerate `go.sum` + transitive SBOM/license inventory, and rerun `govulncheck`.

Real PostgreSQL/River behavior is **not** part of I0 and remains scheduled for W1 after I4.
