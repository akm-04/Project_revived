# Pass460 R3C Wave-S Evidence Hardening

R3C repairs RF-010 and RF-011 locally without claiming stock-client acceptance.

## What changed

- Ordinary production tracking is aggregate-only: capture-disabled `NewBootTracker` retains no detailed per-event slice.
- Acceptance capture is explicit and finite: run/process identity, maximum event count, bounded ring retention, append-only JSONL and explicit unhealthy overflow/failure state.
- API, realtime and optional client evidence share a path-safe run ID and opaque process IDs. Session/context identifiers are transformed into run-local one-way correlation tags; raw bearers/session/context IDs are not evidence fields.
- Server intent/write, client request observation, client observation/consumption, capture health and client lifecycle are separate evidence phases.
- A server-emitted embedded MID or room-entry acknowledgement can prove only server evidence. It cannot satisfy a client-consumption or Lua-health claim.
- Quiescence requires healthy capture and correlated WORLD/SERVICE connections that remain live for the whole requested interval. Disconnect, stale capture health, overflow/failure or mixed context/run evidence is non-green.
- Client acceptance requires independent CLIENT evidence with current capture health, no Lua exception, and explicit `CLIENT_CONSUMED` records for required embedded/room-entry records.
- `gxb-wave-s-report` exits non-zero unless the full `AcceptanceGreen` condition is satisfied.

## Scope boundary

R3C makes the evidence model incapable of promoting server-side evidence into client acceptance. It does not manufacture the missing real stock-client observer. Comprehensive client-consumption/Lua-health/60-second Wave-S proof remains W2. EX-05 multi-process realtime ownership also remains open.

## Local proof

See `EVIDENCE/PASS460_R3C_LOCAL_VALIDATION.txt` and `docs/PASS460_R3C_STAGE_VALIDATION.json` after final seal validation.

## Final seal verdict

Implementation commit: `76d4b71d205cb5a2b40945be2de06bc3fabd147b`.

R3A/R3B/R3C are GREEN at the local implementation/evidence-model layer. The aggregate foundation intentionally remains RED because RF-015 and R4-R7 work remain. Stock-client acceptance remains W2-deferred and not green.
