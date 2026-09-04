# Known Gaps — Stage 1

This server is a modular boot/lobby backend, not a complete Girls X Battle game server.

## Not implemented semantically yet

- full gacha/summon mutations
- hero acquisition, upgrade, equipment, rune, and backpack mutation rules
- campaign/battle validation and battle-result replay persistence
- complete activity/event/minigame details
- shop/market/magic-shop inventories
- guild lifecycle and member state
- full friend/social mutations
- complete TCP chat framing and message semantics
- purchase/payment integration
- anti-cheat/GM/debug paths

## Compatibility fallback

Unknown MIDs return `{"error_code": 0}` plus any warning payload for chat/GM misuse. This is a logging/progress tool, not semantic support.

## TCP chat stub

The stub accepts connections advertised by `LOAD_CHAT_ROOM_INFO` and keeps them from immediately failing. It does not implement the mapped chat protocol yet.

## Persistence

A small JSON-backed state repository exists, but Stage 1 state is still deterministic and minimal. Future gameplay work should promote domain state incrementally instead of adding unrelated canned responses.
