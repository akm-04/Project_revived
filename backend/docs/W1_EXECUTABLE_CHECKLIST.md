# Pass441 / v0.40.1 — Fresh W1 Retest Checklist

**W1 is testing-only. Do not begin I5 or unrelated implementation work in Work mode.**
Use only the exact sealed Pass441 backend candidate after verifying its SHA-256 from the handoff manifest.

## A. Exact artifact and connected-candidate preseal

1. SHA-256 verify backend, HOT/COLD PassMap, current `src_64`, Pass353, old-client, APK/native and Pass222 archives.
2. Extract the backend into a fresh directory. Do not reuse the Pass438 diagnostic copy.
3. Record:
   - `go version` — expected Go 1.27.1
   - `psql --version` — expected PostgreSQL 18.6 client
   - `sqlc version` — expected 1.31.1
   - `goose -version`
   - `govulncheck -version`
   - `lua -v`
4. Run **before PostgreSQL/client testing**:
   - `python3 tools/check_connected_candidate.py --execute`
   This must prove in a clean copy that `go mod tidy` leaves committed `go.mod` and `go.sum` byte-identical, `go mod verify` passes, PostgreSQL-tagged tests/builds pass, PostgreSQL+River-tagged tests pass, and sqlc generation creates the intended sibling scratch artifacts without dirtying the candidate tree.
5. Run `govulncheck ./...` against the resolved closure and retain output. If a tag-aware invocation is supported in the installed version, additionally cover the PostgreSQL/River tagged surface and record the exact command.
6. Run the repository/static/oracle gate with the supplied oracle root and retain its output.

Any failure in A is W1 RED. Do not patch the Work copy into a replacement candidate; preserve diagnostics and return to normal chat.

## B. Clean PostgreSQL 18.6 foundation

1. Create a new disposable database/application role from empty state.
2. Apply all migrations in order with Goose. The exact committed migrations must parse cleanly; no manual SQL editing.
3. Verify canonical logical servers are exactly Server 1 and Server 2. Never manufacture Server 3/4 to satisfy client cache observations.
4. Use `tools/w1_seed_identity.py` only for explicitly labeled W1 fixture accounts/sessions; never substitute `player_id` for account UID.
5. Exercise MID18 returning/fresh paths, same-session observation, new-character admission, existing-character capacity exemption and Server 1↔2 selection.
6. Exercise MID1 first creation, same-target replay, Server 1→2→1, failed-target preservation and fresh blank-name lifecycle.
7. Prove player root + bootstrap directory/profile + context + gameplay credential + receipt commit atomically. Kill/abort selected transactions and prove no half-character.
8. Exercise real lock contention, final-slot race, serialization/deadlock retries and cancellation cleanup. Record SQLSTATEs and canonical rows.
9. Exercise both ambiguous-COMMIT branches, including **authoritative absence → authorized retry → commit**, and assert the returned/audit evidence retains the reconciliation history introduced in Pass439.
10. Restart the API/realtime processes and prove live canonical state reconstructs from PostgreSQL rather than process memory/device cache.

## C. River / durable-obligation boundary

1. Instantiate River only through the V2 durable-obligation adapter.
2. Prove enqueue is transactionally coupled to its source effect/receipt where applicable.
3. Prove rollback on aborted source transaction.
4. Interrupt/restart workers and prove redelivery without duplicate canonical effect.
5. River job IDs, leases and delivery state must never become gameplay truth.

## D. Wave-S backend evidence stream

For each S0-S3 run use a unique safe run ID and one evidence directory shared by API and realtime processes:

- `GXB_WAVE_S_EVIDENCE_DIR=<absolute evidence dir>`
- `GXB_WAVE_S_RUN_ID=<run id>`

Retain `<run-id>-api.jsonl` and `<run-id>-realtime.jsonl`.
After at least 60 seconds of the required lobby observation window, run:

`go run ./cmd/gxb-wave-s-report -dir <evidence dir> -run-id <run id> -required 60s`

Retain the JSON report. Backend evidence supplements, never replaces, packet capture/client logs/source differential evidence.

## E. Unmodified stock-client S0-S3

Run the **unmodified stock client** against the exact Pass441 candidate and capture HTTP/TCP traffic, client logs/Lua exceptions, backend logs and database assertions.

### S0 minimal returning-player lobby
MID1 + 33 embedded records, MID2784, WORLD/SERVICE MID192→TCP_LOGIN→room-entered/heartbeat, MID56, MID1344, MID176, MID2754 and MID1302.

### S1 foundation-rich lobby
Only bounded fixtures necessary for Guild/Pet/EventCentre/Practice surfaces. Include MID612, GUILD admission when a guild ID exists, and gated MID780/MID1056/MID124 only when current-source predicates fire.

### S2 logical-server/cache compatibility
Server 1/2 characters, valid remembered region, stale remembered region and account switch with installation cache from another account. Device cache is never authority. Do not invent Server 3/4 for the packaged-client `[4]` seam.

### S3 fresh character
Absent directory entry → atomic bootstrap creation → first MID1 hydration → blank-name lifecycle → stable lobby.

## F. Fourteen frozen Wave-S done criteria

Record PASS/FAIL + evidence for each:
1. boot manifest coverage;
2. embedded hydration distinguished from explicit calls;
3. exact stock-consumed response semantics;
4. honest inactive shapes, no shapeless crash stubs;
5. zero client Lua modifications/private V1 compatibility nonces;
6. clean real PostgreSQL migrations;
7. WORLD+SERVICE realtime and GUILD in S1;
8. no request storm/retry loop;
9. >=60 seconds source-level quiescence excluding expected heartbeat/legitimate timers/external events;
10. zero Lua exceptions/malformed recovery loops/unhandled applicable traffic;
11. HTTP retry/TCP reconnect/repeated bootstrap duplicate no durable effect;
12. backend restart recovers solely from PostgreSQL canonical state;
13. captured-client differential evidence maps traffic/effect to current-source manifest;
14. S0-S3 pass repeatedly, not once.

## G. Return rule

Package exact commands, environment/tool versions, connected-preseal output, sqlc generation evidence, govulncheck, PostgreSQL/River probes, DB assertions, packet captures, backend JSONL/report output, client logs and every failure reproduction into a fresh W1 evidence ZIP.

**Do not begin I5 in Work mode.** Any failed criterion returns to normal chat and reopens only the affected seam. Any new `src_64` contradiction triggers targeted research before changing frozen design.
