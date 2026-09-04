# Stage 2 Implementation Notes

Stage 2 builds directly on the user-confirmed functional Stage 1 modular backend. The goal is not full gameplay emulation; it is a safer lobby/common-window backend plus better request discovery.

## Confirmed baseline

The user confirmed Stage 1 reaches lobby without issue:

- backend starts SDK server on port 5000
- backend starts engine server on port 9000
- chat stub listens on port 9100
- anonymous SDK login works
- click-to-start reaches lobby

The supplied backend log showed the expected boot/lobby requests and no backend-side blocker.

## Stage 2 code changes

### Observability

Added `gxb_backend/observability/runtime_logger.py`.

Runtime logs are written to `runtime_logs/` by default:

- `all_requests.jsonl` — every decoded game API request and selected handler
- `unknown_mids.jsonl` — fallback/unknown MIDs only
- `fallback_responses.jsonl` — fallback response records

The environment variables are:

- `GXB_RUNTIME_LOG_DIR`
- `GXB_LOG_ALL_REQUESTS`
- `GXB_LOG_UNKNOWN_MIDS`

### Canonical state

`PlayerState` now includes skeleton state for:

- heroes / collected heroes / hero pieces
- backpack / runes / scrolls / essences
- mail
- missions/tasks
- shops
- world map / campaign / trials / march
- guild/social
- arena / peak records / auction
- activities / sign / boards
- building/offline/class/study/gift/adventure/battle-pass/Hunqi stubs

### New handlers

Added:

- `handlers/mail.py`
- `handlers/shop.py`
- `handlers/world.py`
- `handlers/guild.py`
- `handlers/rewards.py`

Expanded:

- `handlers/heroes.py`
- `handlers/inventory.py`
- `handlers/social.py`
- `handlers/arena.py`
- `handlers/tasks.py`
- `handlers/system.py`
- `handlers/bootstrap.py`
- `dispatch/engine_dispatcher.py`

## Important non-goals

- no payment implementation
- no real battle simulator
- no real gacha probability table
- no full TCP chat protocol
- no exhaustive test harness

## Syntax check

Only Python syntax compilation is performed before handoff.
