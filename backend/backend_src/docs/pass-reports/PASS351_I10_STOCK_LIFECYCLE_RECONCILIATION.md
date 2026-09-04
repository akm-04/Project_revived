# Pass351 I10 stock lifecycle reconciliation candidate

## Runtime evidence
Pass350 smoke confirmed the migrated AdminRoot player `19425385` in region 194 and durable PostgreSQL persistence across client/backend restart. The next support bundle exposed two independent stock lifecycle defects.

### Exact `payload=nil` sentinel
The undecoded request capture reports an 11-byte raw form body with SHA256 `6eb8670af47d3a5db66170fa08e2514d0e4c3f92ad6256d43e1844f502b4fba0`, which is byte-identical to `payload=nil`. Pass351 recognizes only the extracted raw payload value `nil` as a logged no-dispatch compatibility success. Generic undecodable engine ingress remains HTTP400 `MALFORMED_ENGINE_REQUEST`.

### Re-entrant fresh-account MID1
The new account flow emitted two concurrent MID1 requests. Pass350 could commit player-directory/context state before PlayerState JSONB materialization; the second MID1 could supersede the first context/credential, and the directory stub then produced repeated `PlayerAggregateNotMaterialized`. Pass351 reuses a live same-session/same-region/same-player context and reconstructs the same context-bound gameplay bearer. Player bootstrap now self-heals directory-only rows by materializing JSONB under the canonical player lock.

## Scope fence
No schema change, gameplay change, worker/realtime/scheduler/mail change, JSON fallback, generic malformed-ingress relaxation, or normal-account cross-region cloning. The separate region-197 versus client-selected-region-194 behavior remains open for source-guided I10 reconciliation.

## Validation
Focused I10/I3/I4: **32 passed**. Controlling I3/I4/I10: **83 passed**. After repairing current regression tripwires to accept only the Pass349-recorded Backend.lua/auth-perimeter hashes while leaving historical manifests immutable, the complete non-integration suite is **302/302 passed**. Compileall passes. Stock-client retest remains the acceptance gate.
