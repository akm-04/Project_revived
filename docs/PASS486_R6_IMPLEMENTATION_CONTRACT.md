# Pass486 R6 Implementation Contract

The exact phase-accepted Pass484 v0.55.3 tree is the implementation baseline. Preserve canonical `go.mod`, `go.sum`, `.go-version`, migrations00001-00011, R5 temporal/content/replay semantics, and all R5 native-proven behavior.

## R6-A Projection completeness
C01 Backpack: typed owner read + one shared stock projector + MID1/81 + authenticated standalone MID81.
C02 Scalars: add only magic_exp, degree_cer, graduate_cer, patent_cer. Preserve Skill temporal owner.
C04 Region name: canonical selected LogicalServer.Name.

## R6-B Directory
C03 selective canonical reconciliation in one SERIALIZABLE transaction; preserve unowned fields; retain D01 same-transaction level projection.

## R6-C Replay/evidence
C05 machine-readable enabled-family replay registry/static guard; transport write phase corrected without upgrading delivery/consumption claims.

## R6-D Lifecycle/runtime
C06 terminal logical-server retirement.
C07 active + verify-only bearer key resolution keyed by persisted derivation_key_id; no invented rotation schedule/API.
C08 PostgreSQL session advisory single-owner realtime guard; no multi-replica HA claim.
C09 encode JSON before committing success headers; serialization/write failure must never re-execute dispatcher settlement.
C10 bounded configurable transaction evidence sink; full I11 telemetry deferred.

## Test/reality gates
Focused behavioral tests -> fresh disposable compatibility-copy full regression/race/vet/static/oracle -> separate post-implementation reality review against current src_64 + old client + frozen V1 -> evidence classification. R7 remains the real PostgreSQL/River integrated repaired-foundation gate before I6.
