# Pass442 — I4 live-client prelogin repair candidate

Status: LIVE RETEST REQUIRED; I5 remains blocked.

## Trigger
The Pass441 AlmaLinux/tablet S0 run proved zrok SDK and engine routing reachable, while exact Pass441 API/realtime evidence remained empty. Targeted current-source research found that Android `UpdateScene.lua` sends MID20480 center discovery and MID2 version checking before the normal MID18/MID1 bootstrap. Pass441 had not registered those UpdateScene-plane MIDs. PassMap provenance had already classified these as public pre-context surfaces; this was an implementation omission, not a design reopening.

## Repair
- Add source-plane descriptors for MID20480 and MID2 without editing generated `mid.lua` registry data.
- Add bounded read-only prelogin dispatcher:
  - MID20480 -> configured public engine URL, server_id=1, empty back_domain/resource-download URL.
  - MID2 -> honest no-update object (`is_appstore/is_inapp/is_review/need_restart = 0`).
  - MID7 -> `{contents:"{}"}`.
  - MID2864 -> JSON scalar `"B"` for `mtspy`, `"A"` otherwise.
- Permit source-proven scalar JSON at HTTP edge without changing ordinary object response semantics.
- Record prelogin events in Wave-S JSONL evidence.
- Require `GXB_PUBLIC_ENGINE_URL` in the postgres API composition.
- Strengthen I4 validator and oracle cross-check against verified current UpdateScene/Backend/SelfPlayer plus Pass353 corroboration.

## Evidence boundary
Normal-chat exact target Go/PostgreSQL tagged build cannot execute because this environment has Go 1.23.2 and no network/module cache for pgx. A throwaway compatibility copy lowering only go.mod/toolchain metadata compiled and passed focused mids/httpedge/stockruntime/lobby tests. Python I4/oracle/dependency/sqlc/schema checks pass on the real candidate source. Exact Go 1.27.1 tagged build is therefore the first AlmaLinux retest gate.

## Architecture
No Player Core/Social/Combat/Commerce work was pulled into I4. Pass353 is corroborative only. Current `src_64` remains the active implementation oracle. I5 remains blocked until live-client W1 is clean.
