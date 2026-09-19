# Pass502 — I6C Phase Acceptance

I6C Guild/GuildMembership canonical authority is **PHASE_ACCEPTED** after independent Normal-Chat reconciliation of the exact Pass501 native evidence.

- Exact tested Pass501 candidate: `gxb-backend-v2-v0.59.1-pass501-i6c-native-gate-candidate.zip`, SHA-256 `35877fc20fc174854c1395f23f352d18737cbd12731481be1b5b5e5fafd2c156`.
- Pass501 implementation semantic content root: `9b2d81931287d9fa85e801375676f2619785453e95b12f367ac8f72351df0b96`.
- Round-1 native report: SHA-256 `821146ead5c9fd9c1abf75e21060ff504ae13602059b0686a71e0dadb323d8b2`.
- Final native delta report: SHA-256 `0379092e4f33b227fa2c08b81904a4d043fc264d31454d89ac09d4c397dcac8b`, classification `GREEN_I6C_NATIVE_DELTA_COMPLETE`.
- Independent report-manifest verification, embedded-candidate identity verification, exact 717-path tree-manifest verification, and candidate-vs-test-overlay inspection all passed. No diagnostic harness was copied into the candidate.
- No product repair was required after the exact native gate. This Pass502 release changes release/evidence metadata only; gameplay/product Go source, tests, migration `00012_i6c_guild_core.sql`, source-oracle fixtures, generated Guild policy, `go.mod`, `go.sum`, and `.go-version` remain the exact Pass501 bytes.
- Exact Go 1.27.1 / PostgreSQL 18.6 evidence covers module closure, full tests/vet/race, PostgreSQL and PostgreSQL+River tagged composition, migration 00001→00012 fresh/upgrade, schema/ownership/sqlc/SBOM/source oracles, Guild allocator/membership behavior, economy atomicity, UNKNOWN-COMMIT reconciliation, restart and dump/restore.
- Delta evidence closes I6C application races, invitation races, departure races, rolling-window cutoffs/concurrency using PostgreSQL authoritative decision time, and repeated rank-wide lock-contention campaigns with zero PostgreSQL deadlocks and preserved invariants.
- Deliberately pathological contention produced bounded SQLSTATE 40001 exhaustion after `MaxAttempts=3`; this remains a stress/performance observation, not a gameplay correctness defect absent ordinary-gameplay evidence requiring retry-policy change.
- Automatic offline-leader succession remains `PRESENCE_PROVIDER_GATED_AND_SUCCESSOR_SELECTION_POLICY_GATED`. `account_sessions.last_activity_at` is not gameplay presence. The source-proven threshold is 259200 seconds; successor selection remains UNKNOWN.
- Rolling seven-day join and rolling 24-hour invitation limits remain explicit V2 `COMPATIBILITY_POLICY`; no original-server calendar-reset claim is made.

Next lifecycle frontier: **I6D / PRE_IMPLEMENTATION_RESEARCH_RECONCILIATION**. I6D implementation remains blocked until candidate-bound I6D research is GREEN.
