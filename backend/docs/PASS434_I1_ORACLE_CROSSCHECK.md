# Pass434 / I1 oracle cross-check

## Current stock `src_64`

The current packaged `Backend.lua` was rechecked from the hash-pinned `all-assest-rechecked-1` archive. Its ordinary retry path re-enters `webRequest_` with the retained MID and params, and ordinary web payload construction still includes `string.urlencode`. No generic stock `client_op_id`, `summon_op_id`, or `contextEpoch` field was found in this transport path.

**Implementation consequence:** I1 does not invent a mandatory client nonce. Semantic receipts are server-side evidence keyed by domain-specific semantic identity. Retry-stable operation context is internal server state and does not alter the stock wire contract.

## Frozen Pass353 / V1

Selected transaction sources from the hash-pinned Pass353 oracle were inspected without copying its application tree.

Useful mechanisms retained conceptually:
- V1's `OperationContext` keeps `started_at` and randomness stable across internal retries.
- `ResourceLockRegistry` explicitly maps typed resources onto actual canonical-row lockers and states that it does not require a generic resource-lock table.
- V1's durable job primitives demonstrate the value of same-transaction durable post-commit work.

V1 policies deliberately **not** inherited:
- generic retry of `StateVersionConflict`;
- the private `client_operation_id` seam;
- a project-owned generic scheduled-job/outbox schema as gameplay truth;
- sorted-JSON-only request fingerprints where dynamic type distinctions matter.

V2 instead uses explicit definite-abort classification, unknown-COMMIT reconciliation, domain-owned facts, River behind a durable-obligation adapter, and type-tagged canonical fingerprints.

## Native/APK and historical inputs

Their hash pins are revalidated by `tools/verify_oracles.py`. I1 adds no client-visible protocol behavior, so no new native or historical-client contradiction was introduced at this milestone.

## Verdict

**PASS.** The implemented foundation mechanisms remain compatible with stock-client behavior and preserve Pass353 only as a bounded mechanism/differential oracle. No V1 private nonce, persistence topology or retry authority leaked into V2.
