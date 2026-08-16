# Stage 2.1 Hotfix Notes

## Problem

Stage 2 booted through SDK login and `RETRIEVE_TOKEN`, then requested `ALBUM_SPECIAL_COLLECT_INFO` (2784) and stopped on the loading UI. The backend saw no unknown MIDs and no fallback responses.

## Diagnosis

The Stage 2 backend widened `RETRIEVE_TOKEN.detail` with many source-recognized optional domain payloads. The client processes `detail` entries through Lua event listeners; optional does not mean safe. If a pushed detail entry has an incomplete shape, its event listener can stop the boot chain before the usual lobby fanout.

Stage 1's proven-good run continued after 2784 into `GET_BOARD_INFO`, chat-room discovery, MainScene windows, summon, illusion, library, and friends. Therefore Stage 2.1 restores the Stage 1 bootstrap hydration shape by default.

## Fix

Default `BootstrapHandlers.build_detail()` now uses safe mode:

- `17` LOAD_PLAYER_INFO
- `49` LOAD_HEROS
- `81` LOAD_BACKPACK
- `836` GET_LIBRARY_INFOS
- `56` LOAD_SUMMON_INFO
- `176` LOAD_FRIENDS
- `229` ACTIVITIES
- `2560` RED_POINT

The widened Stage 2 detail bag is preserved behind:

```bash
GXB_BOOTSTRAP_DETAIL_MODE=wide python3 server.py
```

Do not use wide mode for normal testing.

## What stayed from Stage 2

- Modular handler expansion.
- Runtime JSONL request/fallback/unknown logging.
- Mail/shop/world/guild/rewards domains.
- Extended dispatcher registrations.
- TCP chat stub.

## Test focus

Use default mode. Confirm boot reaches lobby again, then open common UI panels so direct MID handlers are exercised without risking early bootstrap listener aborts.
