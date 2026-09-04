# Stage 3.1.4 — SDK / game identity coherence experiment

## Why this stage exists

The Stage 3.1.3 resource probe was negative: the client reached the same incomplete lobby without requesting `/res/*`, without posting `/client-log`, and without advancing to MID 176 `LOAD_FRIENDS` or MID 2754 `CHECK_GAME_STAT`.

The ADB filesystem snapshot exposed a stronger source-backed mismatch. The current device's `files/game.db` still contains the same region-125 identity as the known-good pre-EOL client snapshot:

- login/server SID: `1993b58bfd1b93499ae19477b236d4a2`
- region: `125`
- region name: `Deep Valley`
- game player ID: `12525385`
- game player name: `Moppleton`

At the same time the replacement SDK stored/returned:

- SDK account UID: `13371337`
- SDK SID: `13371337`
- SDK username: `AdminRoot`

and the Stage 3.1.3 backend also returned MID17 `player_id=13371337`.

## Source contract

`LoadingScene:showLoginSdkWindow()` receives the Android `xydNewLogin` callbacks separately:

1. token callback -> `LoadingScene.token`
2. SID callback -> `LoginWindow.sid`

`LoginWindow` dispatches that SID in the `LOGIN` event. `LoadingScene:login_()` then sends it as MID1 request field `sid`.

MID1's root `uid` is consumed by `SelfPlayer:loginEvent_()` as `SelfPlayer.uid`. MID1 detail `17` is independently consumed by `SelfPlayer:onPlayerInfo_()` / `Player.populate()` as the in-game `playerID` and `playerName`.

After MID1 succeeds, `LoadingScene:updateMeta_()` stores the login SID plus the hydrated game player identity into `game.db.meta`. If the persisted `meta.playerID` differs from `SelfPlayer.playerID`, the source calls `xyd.db.clearGameData()` before rewriting the meta row.

Therefore account UID, SDK/login SID, and game player ID are not interchangeable fields.

## Stage 3.1.4 defaults

This build deliberately keeps the local SDK account while restoring the known-good region-125 game tuple:

- SDK account UID: `13371337`
- SDK/login SID / `QQWSID`: `1993b58bfd1b93499ae19477b236d4a2`
- SDK username: `AdminRoot`
- game player ID: `12525385`
- game player name: `Moppleton`
- region 125 name: `Deep Valley`

The starter hero remains source-valid but its owner `player_id` is updated to `12525385` for consistency.

No payment behavior, battle behavior, or new numeric MID was added.

## Observability

Every MID1 request now writes:

`runtime_logs/identity_trace.jsonl`

with:

- request SID actually sent by the APK
- SDK SID configured by the backend
- account UID
- game player ID/name
- region ID/name
- whether request SID matches SDK SID

It also prints a compact `[IDENTITY] ...` line to stdout.

The important live success marker is that MID1 itself should now arrive with:

`"sid":"1993b58bfd1b93499ae19477b236d4a2"`

If it still arrives as `13371337`, the native SDK did not accept/replace the session SID and the next work belongs in the SDK compatibility surface rather than MainScene.

## Resource probe

The `/res/` probe is retained but disabled by default after the negative Stage 3.1.3 run. Re-enable only when needed with:

`GXB_RESOURCE_PROBE=1 python3 server.py`

## Next evidence if the lobby is still incomplete

If identity is coherent but MID176/MID2754 are still absent, inspect the client hot-update/download root that the previous ADB script intentionally excluded:

`/data/data/com.carolgames.gxb/files/com.carolgames.gxb`

The authoritative Lua uses direct local loads as well as manifest-based `AssetDownload`, and downloaded Lua/resources can override APK-bundled files. A targeted helper is included at `tools/adb_stage314_probe.sh`.
