# Pass276 / U4B Wave D — Realtime Codec + Canonical Identity/Admission + Authenticated Session Runtime

Wave D replaces the old byte-draining chat stub lifecycle with the minimum authenticated realtime transport foundation while preserving business-domain fences.

Implemented:
- exact recovered 10-byte Xinyoudi frame header (`u32_be payload length | u16_be MID | u32_be sequence`) with a 65,536-byte payload ceiling;
- bounded AMF3 Params codec for the recovered subset: undefined/null/bool/integer/double/string/dense array/dynamic anonymous object, with unsupported markers/shapes failing closed;
- incremental stream decoding for arbitrarily fragmented or coalesced TCP reads;
- immutable `AuthenticatedPlayerIdentity` resolution through the existing canonical token -> session -> uid -> `(uid,region)` -> player indexes under `StateRepository._lock`, without touching request-local `threading.local` bindings or constructing `RequestServices`;
- pure room admission: SERVICE=99999, WORLD=authenticated region, GUILD=canonical nonzero `guild_id`;
- process-transient multi-session registry indexed by connection/player/uid/role+room, storing no canonical gameplay state;
- one listener thread, one reader worker per connection, and serialized bounded per-session outbound writer queues;
- state machine: first application frame must be TCP_LOGIN 32771; successful admission registers immutable session and emits minimal CHAT_ROOM_ENTERED 32779 `{room_id}`; authenticated SOCKET_HEARTBEAT 32797 refreshes session health with no required echo; malformed/unowned feature MIDs fail closed;
- operational policies frozen in R4: preauth 15s, idle 1320s, queue 256 frames / 4 MiB, sequence 0 for current outbound foundation frames;
- app-scoped non-listening `RealtimeRuntime` constructed by `AppFactory` and injected into `EngineDispatcher`; `run.main` starts/stops the already-validated runtime.

Current-source/native verification:
- current `Backend.lua` still proves token/region/room_id login for world/service/guild, 10s client auth timeout, 5s reconnect delay and 600s heartbeat interval;
- exact current-generation `libcocos2dlua.so` remains the native wire authority;
- implementation reproduces the Pass259 golden login, minimal entered and heartbeat frame vectors byte-for-byte.

Safety boundaries:
- no socket/session lock is acquired while `StateRepository.resolve_realtime_identity()` holds the repository lock;
- realtime sessions store identity/admission snapshots only, never `PlayerState`, Mail, Guild, Arena, PvP or Commerce business state;
- multiple authenticated sessions for one account/player are allowed; no unsupported eviction policy is invented;
- no HTTP MID192 behavior is changed in Wave D;
- no typed domain event publisher or post-commit realtime topic binding is enabled yet;
- chat gameplay and domain notices remain unimplemented/fail-closed;
- no client runtime bytes changed.

Wave E remains responsible for typed realtime publication plus MID192 HTTP room-directory validation/integration.
