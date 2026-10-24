# Pass450 — R0 Foundation Truth / Guard Enforcement Repair

## Verdict

**R0 GREEN. Foundation remains deliberately RED; I6 remains blocked.**

R0 changes no GXB gameplay behavior. It repairs the implementation-verification system so later foundation defects cannot be hidden by incomplete import guards, kernel-only SQL ownership checks, implementation-shaped validators, or a common check entry point that stopped at I4.

## Implemented

- Replaced the implicit architecture switch with an explicit top-level internal dependency matrix. Unregistered layers fail closed. Negative fixtures prove domain→application, protocol→domain, projection→adapter/protocol, application→adapter and foundation→domain rejection; positive fixtures prove legitimate inward/composition dependencies.
- Added `docs/architecture/CANONICAL_TABLE_OWNERSHIP.json` covering every canonical production table created by migrations 00001–00006, including owner, creating migration, operational readers/writers, query-owner markers and narrow explicit exceptions.
- Rebuilt `tools/check_schema_query_ownership.py` to inspect every production migration, owner-scoped SQL query file and inline PostgreSQL adapter SQL. Strict mode fails on known-open defects; `--allow-known-open` exists only for R0 guard self-validation.
- The ownership guard now exposes four RF-007 writes from `internal/adapters/postgres/i4store/bootstrap_runtime.go` into I5 Player Core tables. They remain unfixed until R2; R0 does not waive them.
- Repaired `tools/validate_i5.py`: it no longer requires I5 table mutations in `i4store` and no longer bans source-required temporal bootstrap. It now truthfully reports RF-007 and RF-015 until their owner seams/state are implemented.
- Repaired brittle historical I2/I3 validators so they validate the explicit matrix contract rather than old switch-case source strings.
- Made `tools/generate_kernel_querytext.py --check` non-mutating and deterministic.
- Rebuilt `tools/check.sh` as an aggregating I0–I5 foundation check. It reports all visible failures, runs I5 oracle/validator paths, never `gofmt -w`, and supports an explicit disposable-compiler mode that skips only canonical-toolchain preseal metadata while retaining behavioral/unit/static checks.
- Added `docs/foundation_repair_status.json` and `docs/PASS450_FOUNDATION_TRACE_MATRIX.json`, plus validators, so source/design→owner→production path→persistence→projection→tests→evidence level→extension seam is machine-visible and open RFs cannot disappear behind structural PASS.

## Validation

Canonical `go.mod` remained `go 1.26.0` / `toolchain go1.27.1` byte-stable while testing.

A disposable clone lowered only its own module floor to Go 1.23.0 and removed its toolchain line. In that clone:

- `go test ./...` — PASS
- `go vet ./...` — PASS
- `go test ./internal/archguard` — PASS
- `tools/validate_r0.py` — PASS
- `tools/validate_foundation_trace.py` — PASS
- I2/I3 validators — PASS
- ownership checker self-test and known-open classification — PASS

The aggregate `tools/check.sh` finishes RED only for the intentionally exposed later-repair classes RF-007/RF-015. This is expected and is not a failed R0 implementation.

## Evidence level

R0 is a behavior-neutral local static/tooling repair; no new PostgreSQL/River/client semantic claim is made. Historical live evidence remains qualified exactly as before.

## Next

Proceed to **R1A — transaction finalization and authoritative outcome proof**. Do not start I6.
