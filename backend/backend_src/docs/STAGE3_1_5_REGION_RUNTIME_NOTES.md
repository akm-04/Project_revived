# Stage 3.1.5 — RegionWindow contract and runtime-Lua probe

Date: 2026-08-16

## Live findings entering this stage

- Stage 3.1.4 identity separation worked exactly as designed: native/session SID `1993b58bfd1b93499ae19477b236d4a2` reached MID1; game player identity was `12525385 / Moppleton / Deep Valley`.
- Lobby still stopped at the same post-entry request surface (`612 GET_SELF_GUILD`, repeated `192 LOAD_CHAT_ROOM_INFO`) without `176 LOAD_FRIENDS` or `2754 CHECK_GAME_STAT`.
- Clicking the login-screen region-change button caused repeated MID18 calls and the region window failed to become usable.
- The ADB hot root exists and contains writable `src_32`, `src_64`, `res`, `version.json`, and update metadata.

## MID18 full consumer contract

Pass 19 indexed only the direct `LoginWindow` fields (`regions`, `players`). `RegionWindow.lua` is the downstream consumer and adds required structure:

- response `recall_regions` must be a table because `next(recallRegions)` is called;
- response `players` must be an array because `table.sort(players, ...)` and `ipairs(players)` are used;
- each region must expose numeric `max_player_id` and `cur_id` because the UI compares them with `<=`;
- player rows consume `region`, `lev`, `vip`, `name/id`, avatar fields, and conquer fields.

Stage 3.1.5 fixes this contract from canonical PlayerState. Region capacity numbers are compatibility defaults because exact official values were not captured.

## Runtime override evidence

The supplied `all-assest-rechecked.zip` includes both bundled and downloaded/hot-update code. Their `src_64/app/windows/LoginWindow.lua` files are not identical:

```text
bundled non-debug default region index:   var_2_0[4]
downloaded non-debug default region index: var_2_0[7]
```

This proves hot-update Lua can change runtime behavior and justifies pulling the current writable copies before further MainScene backend guesses.

## Stage 3.1.4 ADB helper defects

The first helper did not provide the intended runtime evidence because:

1. its `find` expression searched lower-case `*main_scene*`, while the actual Lua names are `MainScene*.lua`;
2. `adb shell` inside a `while read` loop inherited the loop stdin, so after the first checksum it could consume the remaining file list;
3. DB queries depended on an Android `sqlite3` binary, producing empty `game_meta.txt`/`xinyd_user.txt` on devices without it.

`tools/adb_stage315_probe.sh` corrects all three and pulls the actual target files plus raw SQLite DBs.

## Next gate

First test the fixed server selection window. For the lobby, do not add another speculative MID/state field until the current hot-update versions of `MainScene*.lua`, `SelfPlayer.lua`, `WindowManager.lua`, and related files are compared against the bundled `src_64` source.
