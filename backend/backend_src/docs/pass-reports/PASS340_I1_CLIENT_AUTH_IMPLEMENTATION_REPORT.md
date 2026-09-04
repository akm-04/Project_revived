# Pass340 — Implementation Wave I1: Client Compatibility + Ingress/Auth Perimeter

## Result

**PASS / ACCEPTED.** Pass340 implements the frozen Pass337 I1 wave without opening PostgreSQL gameplay authority, retiring the global request RLock, widening workers, or starting I2/I3 early. JSON remains canonical.

## Client compatibility patch

- Added a `contextEpoch_`/`contextReady_` fence to the current Lua backend. Every web completion captures its epoch and stale completions are discarded before global response checks, event dispatch, callback handling, or retry processing.
- Manual retry preserves the original parameter table and therefore one logical `client_op_id`; retry records also preserve the captured epoch and stale retry entries are discarded.
- MID1 is now single-flight through the source-proven `isLoggingIn_` guard.
- Manual server switching begins a context transition before listener/model/server-time reset.
- Added private realtime control MID 65000 and handlers for `CONNECTION_SUPERSEDED`, `ROOM_INVALIDATED`, and `AUTH_CONTEXT_INVALIDATED`; intentional socket closes suppress the stock reconnect timer.
- The patch is sparse and SHA-identical between packaged `src_32` and `src_64` for all four touched client files.

## Ingress/auth perimeter

- Added explicit scopes: PUBLIC_BOOTSTRAP, ACCOUNT_SESSION, CONTEXT_SELECTION, SELECTED_PLAYER, REALTIME_ADMISSION, ADMIN_OPERATOR. Unknown engine MIDs default deny.
- MID18/MID1 authenticate only from account-session fields (`sid`/`login_token`); ordinary gameplay no longer gains actor authority from them.
- MID1 records a temporary selected player/region binding in the still-canonical legacy JSON session. Later HTTP/TCP requests resolve that bound player first; caller `region` is only a consistency assertion and cannot choose another actor. This is a temporary I1 seam, not the future I3 relational context authority.
- Invalid credentials/context are rejected before mutation firewall/handler/domain execution. Malformed engine payloads fail closed with HTTP 400 and unmatched undecodable routes with HTTP 404.
- Request/SDK/undecoded logging now routes credential-bearing values through centralized redaction; undecodable payload capture stores length/hash rather than raw body prefixes.

## Source-boundary findings

Current `UpdateScene.lua` keeps MID2 and MID20480 on its separate pre-context update/bootstrap web path. Their server-side public classification remains source-grounded; they are not emitted by normal `Backend.request()` selected-player traffic. No source/backend fact required a Design loopback.

## Validation

- 34/34 I1 tests PASS.
- 19/19 Pass339 foundation tests PASS.
- 53/53 combined tests PASS.
- 14/14 unchanged controlling historical regressions PASS.
- Pass278's final restart shortcut is intentionally superseded: fresh SDK login -> direct gameplay now returns `CONTEXT_STALE`. The Pass340 replacement regression proves fresh login -> MID1 context bind -> gameplay, plus region-mismatch rejection.
- Deterministic runtime delta PASS: 486 Pass339 runtime-authority baseline files -> 495 current; 474 unchanged, 12 modified, 9 added, 0 deleted; root SHA-256 `d90e6b6e73bf1bebb760a51762191e04e6d53ff55065e125cd1c989736e176f1`.
- `compileall` PASS.
- No PostgreSQL daemon/connection was attempted. DB-facing Wave-I1 validation used pure logic/mocking per user instruction.

## Deferred exactly as frozen

ResourceTransaction/receipts/outbox/scheduled-job tables remain I2. Durable relational account/session/context credential authority remains I3. RealtimeGateway remains I5. The process-global request RLock remains in place until I9's concurrency proof gate, and worker widening remains forbidden before that gate.

## Next

Pass341 / Wave I2 (PostgreSQL transaction kernel) is the next frozen wave and requires separate explicit authorization.
