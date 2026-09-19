# Pass451 R1A Transaction Safety Repair

Status: LOCAL IMPLEMENTATION GREEN; real pgxpool/PostgreSQL ambiguity/fault proof retained for R7.
Parent: Pass450 R0 (`01b5348b52c3e986040f91e407cb4f9c1a1e5f11`).
Scope: RF-004 and RF-005 only. MID1 hydration/credential/server-lock semantics remain R1B.

## RF-004
- Installs a transaction finalizer immediately after every successful Begin.
- Panic/error/cancellation paths receive bounded best-effort rollback using an independent cleanup context.
- A failed Commit remains semantic UNKNOWN; later cleanup cannot rewrite it to ABORT.
- Successful Commit marks the handle finalized and suppresses cleanup rollback.

## RF-005
- Generic semantic-receipt absence now resolves to UNKNOWN, never authoritative absence.
- `ResolutionAbsent` is reserved for operation-specific terminal/owner-fence proof.
- MID1 generic receipt miss and empty postcondition evidence likewise remain UNKNOWN.
- Replay-after-authoritative-negative remains explicit policy and activates only after real strong absence proof.

## Evidence boundary
Disposable compatibility clone only: Go directive 1.23/no toolchain pin. Canonical tree remains Go 1.26 + toolchain Go 1.27.1. Unit/vet/race/static proof is local. Real pgxpool/PostgreSQL commit ambiguity, cancellation and fault injection remain R7 live gates.
