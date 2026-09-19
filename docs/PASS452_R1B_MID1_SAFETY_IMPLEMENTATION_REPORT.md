# Pass452 R1B MID1 Selection / Hydration / Credential / Server-Lock Repair

Status: LOCAL IMPLEMENTATION GREEN candidate; real PostgreSQL concurrency and final stock-client proof remain explicit later gates.
Parent: sealed Pass451 R1A (`183585c968daeaffdd8a21612dc18c3c62bd61de`).
Scope: RF-001, RF-002, RF-003 only. R2 bootstrap ownership/lifecycle seams remain intentionally open.

## RF-001 — selection receipt vs current hydration
- New MID1 receipts store immutable selection identity only, not a complete mutable stock response.
- A matching prior receipt is selection/effect evidence; the transaction keeps the freshly rebuilt canonical `planned` hydration instead of decoding old Detail/is_new.
- Ambiguous-COMMIT reconciliation opens a new read-only repeatable-read hydration transaction, authenticates the same account/session, verifies the committed context is still the live requested target, re-derives the bearer, rebuilds lobby Detail through current domain contributors, and derives is_new from current `first_entry_pending`.
- A context superseded before recovery fails closed rather than reviving a revoked bearer.

## RF-002 — secret-free new receipts
- New schema: `gxb.mid1.select.v2`.
- Payload fields are region, AccountUID, PlayerID, ContextID, context generation, derivation-key ID and immutable player bootstrap-profile version.
- Raw gameplay bearer, Detail and is_new are never serialized into the new receipt.
- Historical `gxb.mid1.stock.v1` is accepted only as immutable selection evidence. Repair code parses only region/UID and receipt metadata; historical token/detail fields are never returned or logged.
- `SECURITY.md` marks old v1 receipts/backups credential-bearing retention data. Key rotation remains EX-01; R1B does not claim multi-key resolution.

## RF-003 — server admission fence split
- Existing-player path takes `FOR SHARE` on the logical-server row, preserving maintenance/update serialization without globally serializing unrelated existing logins.
- Tentative creation path alone takes `FOR UPDATE` on the allocator row and rechecks account/server player existence after the fence.
- MID1 remains SERIALIZABLE. A concurrent creator may therefore resolve via serialization/unique definite-abort retry rather than visibility inside the first snapshot; duplicate creation is not authorized.
- Session-row transition locking remains independent and occurs before server admission.

## Evidence boundary
Normal-chat proof uses a disposable Go 1.23 compatibility clone only. Canonical module pins stay `go 1.26.0` / `toolchain go1.27.1`. Focused real PostgreSQL tests for shared/exclusive lock behavior, concurrent creation and ambiguous-response hydration remain required before R7; comprehensive stock-client behavior remains W2 under Pass445 unless explicitly rescheduled.
