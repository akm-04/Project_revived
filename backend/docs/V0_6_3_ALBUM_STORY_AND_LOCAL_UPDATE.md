# v0.6.3 — Album/story recovery and backend-local Lua hot updates

Date: 2026-08-17

## Scope

This pass fixes two Lua-state contract errors exposed only after Campaign 200002 became playable, hardens MID2064 recovery after a client callback failure, and separates the two source-confirmed EOL update planes:

1. runtime non-force resources via `res_download_url` + `/res/<basename>.<md5>`;
2. startup force/Lua updates via MID2 ZIP-volume descriptors.

No Campaign battle, formation, arena, payment, or ordinary Hero progression behavior is intentionally broadened here.

## Live failure: MID2784 had the wrong type

The latest runtime log proves MID2064 itself returned a coherent Joan/Geisha Hero reward. The failure occurred while `SelfPlayer:handleRewards()` added that Hero:

```text
BattleSpecialStory MID2064 callback
→ SelfPlayer:handleRewards()
→ SelfPlayer:addHero()
→ SelfPlayer:checkAlbumSpecial()
→ #albumSpecialCollect
→ Lua error: albumSpecialCollect is a number
```

Authoritative `SelfPlayer.lua` establishes:

```lua
self.albumSpecialCollect = response.is_award
...
for i = 1, #self.albumSpecialCollect do
```

The old compatibility response was:

```json
{"is_award": 0}
```

That shape is invalid. `collect_special.lua` contains contiguous collection rows 1..23, so a fresh-account response is represented as a 23-slot zero array:

```json
{"is_award":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]}
```

Generated evidence is packaged at:

```text
data/album_special_collect_meta.json
tools/build_album_special_collect_meta.py
```

## MID2064 recovery-idempotency

v0.6.2 persisted the selected Hero and Campaign `is_partner_drop=1` before the client finished its reward callback. That is correct for durability, but a Lua callback crash could leave the special-story choice UI open.

v0.6.3 treats the first recorded pending claim as authoritative. While the matching MID113 session remains pending, any retry of MID2064 returns the already-owned Hero, even if the user taps the other choice. It does not mint a second Hero or silently switch the original choice.

This is a recovery behavior for a failed client callback, not a second-choice mechanic.

## LOAD_FRIENDS recall-array correction

The same runtime capture exposed:

```text
SocialSystem.lua getRecallFriendNum
→ #socialSystemInfo.done_recall
→ nil length error
```

`LOAD_FRIENDS` now includes fresh-account empty arrays for the source-consumed recall fields:

```text
got_recall
doing_recall
done_recall
recall_awarded
```

## Resource plane A: runtime lazy `/res/`

This path is now live-confirmed:

```text
CENTER res_download_url
→ local version.json/lazyFile.json
→ AssetDownload
→ xyd.FileDownloader
→ GET /res/<basename>.<md5>
→ backend catalog reverse lookup
→ exact-MD5 bytes
→ native callback
```

Use:

```text
local_assets/res/
```

for the static recovered resource store. The static-store builder reconciles current `res/web/...` and older `res/...` layouts but accepts only files matching the current catalog MD5.

## Resource plane B: MID2 startup ZIP updates for Lua/force files

Authoritative `UpdateScene.lua` / `UpdateScene_64.lua` show that MID2 can instruct the client to download an in-app resource update. When `is_inapp != 0`, the client consumes `response.res` entries with:

```text
version
volume
size
md5
resource
```

For each descriptor it downloads:

```text
<resource>.001
<resource>.002
...
```

assembles `<version>.zip`, verifies the ZIP MD5, unzips it into `xyd.versionUpdatePath`, stores the new resource version, and restarts.

Writable Lua wins after restart because the source sets `package.path` to the writable `src_32`/`src_64` tree ahead of packaged Lua.

### Backend-local sparse override layout

v0.6.3 reserves:

```text
local_assets/
├── res/                 # runtime lazy assets
├── src_32/              # sparse 32-bit Lua/data overrides
├── src_64/              # sparse 64-bit Lua/data overrides
├── updates/             # generated MID2 ZIP volumes
└── update_manifest.json # generated only when operator builds an update
```

The MID2 facility is disabled when `update_manifest.json` is absent or has `enabled=false`.

### Build an operator-chosen Lua update

Place only the files to override, preserving their writable paths. Example:

```text
local_assets/src_64/app/model/SelfPlayer.lua
local_assets/src_32/app/model/SelfPlayer.lua
```

Then choose an explicit resource-version label and build:

```bash
python3 tools/build_local_lua_update.py --version <resource-version>
```

The tool creates one ZIP volume and `local_assets/update_manifest.json`. Restart the backend. MID2 advertises the update until the client reports `v=<resource-version>`.

`--silent` maps to the source-observed `is_review=1` path that skips the UpdateScene confirmation dialog. It is opt-in and should not be used casually during reconstruction.

The server exposes generated volumes at:

```text
/updates/<package>.001
```

using dynamic host derivation. No LAN IP is hard-coded.

### Provenance status

- MID2 descriptor fields and client ZIP/install/restart behavior: **source-confirmed**.
- Writable `src_32/src_64` precedence: **source-confirmed**.
- v0.6.3 backend serving/building this synthetic local update package: **implemented but not runtime-confirmed yet**.
- Runtime `/res/` lazy asset gateway: **user-runtime-confirmed**.

## Suggested current validation

The story fix itself does not require a Lua hot update. Preserve the progressed `player_db.json` and recovered `local_assets/res`, run v0.6.3, and retry the Campaign 200002 story choice.

Expected:

```text
MID2064
→ non-empty story_drop_awards
→ SelfPlayer adds Hero without albumSpecialCollect type error
→ reward presentation completes
→ special story advances
→ MID114
```

If the prior failed v0.6.2 claim is still pending, v0.6.3 should return the already-recorded Hero on either choice button instead of creating another Hero.
