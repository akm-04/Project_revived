# Known Gaps — Stage 3 Domain Foundation

Stage 3 is a broad domain foundation, not a claim of full protocol completeness.

Known remaining gaps:

- Full battle simulation, damage validation, and battle-result semantics.
- Event-specific activity logic and rotating event registries.
- Real gacha pool configuration, pity, guarantees, and inventory mutation semantics.
- Full TCP chat framing/authentication/heartbeat/message protocol.
- Late-game / seasonal / minigame systems not yet promoted from documentation into domain handlers.
- Dynamic or symbolic-only MIDs that remain unresolved in the supplied client source must not be assigned invented numeric values.
- MainScene still has a key runtime diagnostic: if `CHECK_GAME_STAT` (MID 2754) is never requested, the client likely aborted during `MainSceneTopWindow:willOpen()` before it dispatched the UI action sequence that eventually restores bottom/middle touch.
- Payment is intentionally ignored by project decision.

Fallback logging remains a discovery mechanism, not semantic support. Promote a fallback MID into a domain handler only after the request/response contract is grounded in source, documentation, or capture evidence.
