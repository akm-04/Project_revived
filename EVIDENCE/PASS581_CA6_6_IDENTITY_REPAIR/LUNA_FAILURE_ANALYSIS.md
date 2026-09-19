# Failure and recovered-environment analysis

## ID01 — unresolved exact identity discrepancy

Classification: `FAIL`; evidence class `UNKNOWN / SUPERSEDED_METADATA`.

The handoff identifies the candidate with product-tree digest `f8c0db62554de2e860df9d85d41b8595fc7c18871f7e61db6670cbecae2fd993` and file count 1,431. The clean extraction contains the exact file count and all canonical pins, and `SNAPSHOT_MANIFEST.sha256` verifies. However, the candidate's own checked-in `tools/check_connected_candidate.py` computes `9c4a80134ebc6986394a1e2d2ede9edd7352577db51f43345759d7a4204ff1ba` on the initial tree and the same value on the final tree. The second fresh extraction comparison is byte-for-byte identical.

The report does not infer whether the asserted digest used a different algorithm, stale tree, or stale handoff record. The original archive was not edited, and no metadata was rewritten. GPT-5.6 Sol must adjudicate whether the handoff identity assertion is superseded or whether a new candidate/identity record is required.

## Recovered environment events

1. The first restarted-run checksum command used the wrong working directory. It was rerun from the extracted materials and PassMap directories; both corrected checksum logs pass. This did not test or alter product bytes.
2. The first connected-preseal invocation did not source `.gxb-e2e-tools/activate.sh`, so it stopped at `sqlc not found`. The exact same check was rerun after activation with sqlc v1.31.1 and passed, including disposable SQLC generation and PostgreSQL-tagged tests.
3. One `pg_ctl restart` attempt left the isolated cluster stopped. The server was recovered with explicit `pg_ctl ... start`; reload-only native verification, migration idempotence, and schema high-water 29 then passed. This is `ENVIRONMENT_BLOCKED/RECOVERED`, not a candidate failure.

## Diagnostic script outside this matrix

An unparameterized invocation of the historical `check_ca5_3_source_oracle.py` was captured while checking a broader routing command and reported missing exact CA5-era oracle inputs. That script is not a CA6-6 matrix row, and the CA6-3/CA6-4/CA6-5 source-oracle rows passed with their exact required oracle setup. The CA6 route result is based on the actual `cmd/gxb-api/main_postgres.go` registrations plus affected-package tests, not on promoting that unrelated diagnostic to a pass or failure.

## No product repair

No source, dependency, toolchain, migration, configuration, PassMap, or candidate archive bytes were changed. No modified backend ZIP is therefore returned. Generated binaries and Python bytecode created during diagnostics were moved out of the disposable candidate extraction and excluded from the final identity comparison.

## Remaining unknowns

- `PRACTICE_ROLL_POLICY_V1` is an explicit compatibility implementation decision; this gate does not prove the original server's RNG.
- The physical unmodified stock Android client proof is deferred to W2 as directed by the handoff.
- Local green exact/native/real-PG evidence is not equivalent to final release acceptance; Sol remains the adjudicator.
