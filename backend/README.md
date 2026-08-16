# GXB Modular Stage 1 Backend

This archive replaces the outdated flat `server.py + game_logic.py` boot skeleton with a modular backend designed for extension as more MIDs are promoted from documentation into semantic handlers.

## Run

```bash
python server.py
```

The launcher starts:

- SDK/native compatibility HTTP on `GXB_SDK_PORT` / default `5000`
- engine/game HTTP on `GXB_ENGINE_PORT` / default `9000`
- optional minimal TCP chat stub on `GXB_CHAT_PORT` / default `9100`

Important environment variables:

```bash
GXB_BIND=0.0.0.0
GXB_SDK_PORT=5000
GXB_ENGINE_PORT=9000
GXB_SELF_URL=http://172.20.0.21:9000/api/v1
GXB_CHAT_HOST=172.20.0.21
GXB_CHAT_PORT=9100
GXB_ENABLE_CHAT_STUB=1
```

`GXB_SELF_URL` and `GXB_CHAT_HOST` must be reachable from the Android device/emulator, not just from the host Python process.

## Stage 1 goal

Stage 1 targets:

```text
SDK login
 -> center discovery
 -> version/update check
 -> RETRIEVE_TOKEN
 -> bootstrap detail hydration
 -> xydSelectServer
 -> MessageManager
 -> MainScene first lobby windows
```

This is not gameplay-complete. Unknown MIDs are logged and acknowledged to help client-side testing reveal the next missing contracts.

## Structure

```text
gxb_backend/
├── app_factory.py
├── config.py
├── run.py
├── transport/      # payload decoding, SDK routes, engine routes, response builders
├── protocol/       # MID table and transport classification
├── state/          # canonical account/player state
├── handlers/       # domain-owned MID handlers
├── dispatch/       # MID -> handler map
└── chat/           # minimal TCP socket stub
```

## Validation performed

Only simple syntax compilation was run:

```bash
find . -name '*.py' -print0 | xargs -0 python -m py_compile
```

No APK/client runtime testing was performed in this environment.
