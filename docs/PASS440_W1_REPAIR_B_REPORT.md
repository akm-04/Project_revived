# Pass440 — W1 Repair B / Reproducible Connected-Candidate Hardening

Status: **PASS (normal-chat static/source/differential gate); W1 retest still required**
Milestone: I4 repair campaign. I5 remains blocked.

## Purpose

Pass440 closes the reproducibility and preseal-policy gaps exposed by the first Pass438 W1 run. It does not broaden I4 gameplay scope and does not reinterpret V1 architecture as V2 truth.

## Repairs

1. **sqlc generation ownership made explicit**
   - Canonical schema/query SQL remains project-owned.
   - `sqlc generate` now writes to `../gxb-v2-sqlc-generated/{kerneldb,i3db}` rather than creating untracked packages inside the candidate tree.
   - The W1 executable preseal must run sqlc 1.31.1, retain generation evidence, and prove the source tree remains byte-clean.
   - Future milestones that actually import generated packages must explicitly promote and compile them; I4 does not silently treat generated scratch output as source authority.

2. **Resolved Go module closure frozen**
   - `DEPENDENCIES.lock.json` now covers the exact direct + indirect runtime module closure recovered by W1's Go 1.27.1 `go mod tidy`.
   - River is normalized to the actually resolved v0.47.0 family.
   - `go.sum` contains the W1-resolved content hashes required by tagged PostgreSQL/River builds.

3. **SBOM/license evidence upgraded**
   - `SBOM.spdx.json` now includes resolved Go modules and project `DEPENDS_ON` relationships instead of direct-only declarations.
   - `THIRD_PARTY_NOTICES.md` and `docs/I0_DEPENDENCY_REVIEW.md` are synchronized to the resolved closure and River v0.47.0.
   - `tools/generate_resolved_sbom.py --check` and the strengthened dependency-policy guard reject stale or incomplete closure metadata.

4. **Connected-candidate preseal added**
   - `tools/check_connected_candidate.py` has a normal-chat static mode that rejects the exact classes that escaped Pass438: missing sums/closure, missing realtime constructor, Goose compound-statement annotations, River package mismatch, sqlc policy drift, and stale SBOM/dependency state.
   - Its W1 `--execute` mode requires Go 1.27.1 + sqlc 1.31.1 and performs a clean-copy `go mod tidy` byte-stability check, `go mod verify`, PostgreSQL-tagged tests/builds, PostgreSQL+River-tagged tests, and sqlc scratch generation while proving the candidate tree is unchanged.

5. **I4 validator/check gate strengthened**
   - `tools/check.sh` now includes resolved dependency/SBOM, sqlc policy, and connected-candidate static preseal before oracle/source and Go checks.
   - `tools/validate_i4.py` now guards the Pass439 constructor/Goose/River/instrumentation repairs and the connected-candidate preseal itself.

## Evidence run in normal chat

The repaired Pass440 tree passed:

- resolved dependency policy
- resolved SPDX SBOM check
- sqlc generation policy check
- connected-candidate static preseal
- all supplied oracle archive hashes
- I2 current-source/APK wire differential
- I3 current-source bootstrap differential
- I4 current `src_64` + Pass353 Wave-S differential
- MID registry and Pass353 wire fixtures
- schema/query ownership generator/guard
- `GOTOOLCHAIN=local go test ./...`
- `GOTOOLCHAIN=local go vet ./...`
- I1/I2/I3/I4 validators
- selected `go test -race` set covering identity/logicalserver/realtime authority, bootstrap, stockruntime, lobby projection, and transaction runner

The local toolchain is Go 1.23.2 and therefore this evidence is compatibility/static/source/race preparation only. Pass441 will raise the declared module language floor to the W1-resolved Go 1.26.0 while retaining `toolchain go1.27.1`; exact Go 1.27.1 executable proof belongs to W1.

## Authority / scope conclusion

No Pass440 finding collides with current `src_64`, the frozen I3/I4 contracts, or the Pass430/Pass431 design authority. Pass353 was used only as a differential/mechanism oracle. No I5 domain was pulled forward.

**Next:** Pass441 reseal of the same I4 repair line and fresh W1. I5 remains blocked until that W1 is clean.
