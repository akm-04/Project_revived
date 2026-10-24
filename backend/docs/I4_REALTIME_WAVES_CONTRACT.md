# I4 — Minimum Realtime + Wave-S Compatibility Contract

I4 is the smallest runnable stock-lobby candidate between the I2 protocol edge and the I3 identity/session/logical-server authority. It does not pull deep Player Core, Social, Combat, Commerce, Guild War or gameplay modes forward from their roadmap owners.

## Authority and realtime
- WORLD, SERVICE and GUILD are the only physical realtime roles modeled by I4. TEAM remains a logical SERVICE projection.
- `TCP_LOGIN` fields are claims until the gameplay bearer resolves to a live I3 actor and the canonical room is authorized.
- WORLD room is the actor logical server; SERVICE room is `99999`; GUILD requires a guild-authority seam and is not synthesized from client input.
- Successful room admission emits the stock room-entered response. Stock heartbeat is accepted without inventing an echo.
- Authenticated sockets are periodically fenced against canonical session/context liveness without retaining raw bearer material. Newer same-context/same-role admission supersedes older transient connections.

## Bootstrap and lobby compatibility
- MID18/MID1 execute through the I3 PostgreSQL-oriented bootstrap transaction seam.
- MID1 root account `uid` is distinct from nested MID17 `player_id`.
- Empty fresh-character `player_name` is preserved because it is a stock lifecycle signal.
- The minimal bootstrap-owned directory projection prevents a half-character before I5 Player Core takes ownership: level 1, VIP 0, valid initial avatar `110001001`, frame 0, conquer level 0/loop 1 and blank canonical name.
- MID1 preserves the 33 embedded hydration records and current-source structural MID17 fields required by `SelfPlayer.lua`.
- `log_url` is present and defaults to empty; an explicit configured endpoint may override it. `server_time`, `story_type`, `is_debug` and `is_old_top` are preserved.
- MID1304 inactive payload follows current array length semantics. Guild War inactive `is_enroll` is boolean `false`, never numeric `0`.
- I4 exposes only bounded startup facades required by the source-derived Wave-S manifest; inactive responses are structurally honest and never durable fake gameplay state.

## Proof boundary
Normal chat can prove source shape, deterministic pure logic, static ownership, differential fixtures and in-process race safety. It cannot prove PostgreSQL/River semantics or unmodified stock-client stability. W1 after the I4 seal owns those live claims.
