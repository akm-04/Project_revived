# Pass438 — Milestone I4 Minimum Realtime + Wave-S Candidate

## Implemented
- PostgreSQL-oriented executable MID18/MID1 bootstrap orchestration over the sealed I3 account/session/context model, including receipt-backed reconciliation and generation-scoped receipt identity.
- Distinct account UID and player ID propagation through persistence and MID1 projection.
- Atomic minimal player-directory bootstrap projection needed to avoid a stock-visible half-character before I5 Player Core.
- Honest MID192 discovery and WORLD/SERVICE/GUILD role authorization; TEAM remains a SERVICE projection.
- TCP_LOGIN authentication only after bearer resolution and canonical room authorization; room-entered response, stock heartbeat acceptance, bounded pre-auth timeout, canonical liveness fencing and same-context/role reconnect supersession.
- Source-derived 33-record MID1 hydration, complete directly consumed MID17 structural fields, and bounded Wave-S lobby facades.
- 60-second quiescence/request-storm tracker that distinguishes expected heartbeat and legitimate timer surfaces from unexpected repeated traffic.
- Runnable PostgreSQL-tagged `gxb-api` and `gxb-realtime` composition for W1.

## Implementation-time oracle repairs
Continuous current `src_64` cross-checking changed the preseal candidate in narrow compatibility seams without reopening architecture:
1. MID1 root `uid` is account identity; nested MID17 `player_id` is character identity.
2. Empty `player_name` must remain empty for the stock naming lifecycle rather than being synthesized.
3. MID18 existing-character rows require a minimal directory/profile projection; a character root without it is invalid/half-created.
4. Current `SelfPlayer.lua` directly consumes a wider MID17 structural field set than the first hand-maintained list; I4 now guards the mechanically extracted required keys.
5. MID1304 inactive data is array-shaped because current source applies `#` length semantics.
6. Guild War inactive `is_enroll` is boolean `false`; Lua numeric `0` would be truthy.
7. MID1 `log_url` is preserved with honest empty default; stock disables upload for nil/empty values.
8. `server_time`, `story_type`, `is_debug` and `is_old_top` sidebands are retained.

## Explicit non-goals
I4 does not implement deep Player Core/economy, full Social/Profile/Chat, combat, gameplay modes, commerce/gacha or operator control. Compatibility facades do not become canonical state owners.

## Normal-chat result
`tools/check.sh` and the selected I4 race suite are green with local Go 1.23.2 compatibility execution. This is not Go 1.27.1/PostgreSQL/River/stock-client proof.

## W1 boundary
The exact sealed I4 candidate must be tested in Work mode with Go 1.27.1, clean PostgreSQL 18.6 migrations, real transaction/locking and River probes, and the unmodified stock client across Wave-S S0-S3 plus all fourteen frozen done criteria. Any runtime contradiction returns as evidence for targeted repair in normal chat before I5 begins.
