# Known Gaps — Stage 2

Stage 2 is a lobby/common-window skeleton, not a complete game server.

## Intentionally ignored

- payment SDK initialization / purchase flows
- real gacha odds and summon inventory mutation
- real battle simulation and verification
- real TCP chat protocol
- event-specific seasonal minigames

## Expected discovery workflow

When the APK opens more windows, unknown or fallback MIDs will be logged in:

`runtime_logs/unknown_mids.jsonl`

Use the exact request payload and MID name from that file to promote the API into a real handler.

## Compatibility behavior

Unknown MIDs still return `error_code=0` with an empty payload unless routed as chat/GM diagnostics. This is deliberate to maximize forward progress, not a semantic-completeness claim.
