# Pass232 — P2 Edge Reconciliation & Non-destructive Server Log Rollover

## Runtime evidence reviewed
- `nikita-normal_debug.zip`: Nikita ordinary Awakening and Blood Awakening complete successfully through terminal Blood stage 3 on OTA `1.631.22`.
- `kingMing-stress_debug.zip`: repeated ordinary Give Up/reopen state remains coherent across Girls and relog. KongMing mission `1144001` exposes one EOL compatibility dead-end: first open grants event intermediate `50001397`, but after Give Up and MID82 sale of that item, reopening returns the mission without `extra_drops_`, leaving no normal navigation/source for replacement.
- The Nikita bundle contains one client-side `ItemComposeWindow.lua:388` nil-comparison and the previously known `SelfPlayer.lua:4643 last_time=nil` practice-redmark issue. Neither blocked the later successful Blood compose/equip/ritual/terminal flow. A second MID83 `50005001` request returned `error_code=1` only after an earlier `50005001` compose had already succeeded.

## Compatibility correction
Current-source event/no-navigation route identity is unchanged. The server still grants at most one live route intermediate at activation and replays the same-generation response without duplicate credit.

On a *new activation generation*, if the entitlement ledger says `LIVE` but both of the following are absent:
1. the mission-specific intermediate in Backpack; and
2. its derived exclusive Awakening gear in Backpack or equipped on the relevant Hero,

the server treats the ledger as stale versus player-visible reality and restores exactly one intermediate through canonical settlement plus `extra_drops_`. The entitlement remains `LIVE`; `restoration_count` increments and `last_restore_reason=MISSING_LIVE_ENTITLEMENT` is recorded.

This general recovery seam does not change Odin's source-specific `RESTORABLE` Give-Up behavior and does not grant while the intermediate or derived gear still exists.

## Non-destructive human server logs
Pass225 introduced filtered console teeing but opened `runtime_logs/server.txt` with truncation. Pass232 changes only the human transcript allocation:
- first launch: `runtime_logs/server.txt`
- next launch: `runtime_logs/server1.txt`
- then `server2.txt`, `server3.txt`, ...

The first unused suffix is selected and files are opened in exclusive-create mode. Existing transcripts are never overwritten. Structured JSONL evidence is unchanged and continues to be authoritative/unfiltered.

## Release effect
- Backend: `0.35.3` / Pass232.
- OTA: remains `1.631.22`; no Lua/resource update.
- Accepted ordinary/Blood mechanics remain frozen except the bounded event-entitlement recovery described above.
- Occult MID2385 remains fenced/deferred from stock-client smoke.
