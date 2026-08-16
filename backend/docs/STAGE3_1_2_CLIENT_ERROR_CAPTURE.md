# Stage 3.1.2 — Client Error/Resource Log Capture

Date: 2026-08-16

## Why this pass exists

Stage 3.1.1 is user-confirmed to restore login -> server selection -> lobby, but the MainScene still stops before its normal bottom/top completion boundary:

- `GET_SELF_GUILD` (612) is sent.
- `LOAD_FRIENDS` (176) is never sent.
- `CHECK_GAME_STAT` (2754) is never sent.

Source order matters: `MainScene` opens `main_scene_bottom` before `main_scene_top`. A synchronous bottom-window error can therefore explain both missing MIDs and leave controls touch-disabled because the top window never dispatches `MAIN_SCENE_ACTION_END`.

`MainSceneBottomWindow:willOpen()` performs an unconditional `SpineEffect` construction/play for:

```text
skeletons/ui_effect/skill_full/skill.json
skeletons/ui_effect/skill_full/skill.atlas
```

before its unconditional `socialSystem:loadFriends()` call. `SpineEffect` calls `xyd.assetDownloadErrorLog(path)` when a resource is absent. Engine/Lua exceptions are likewise written into `xyd.db.errorLog` by `Game:registerEngineEvents_()`.

Normal Android logcat does not expose those stored rows reliably.

## Source-confirmed client upload protocol

`app/xinyoudi.lua` starts `ErrorLogPoster` automatically.

`ErrorLogPoster` wakes every 30 seconds and reads `xyd.db.errorLog:getAll()`. It calls:

```lua
xyd.Backend.get():log(0, json.encode(logs), callback)
```

`Backend:log()` only uploads when `RETRIEVE_TOKEN.log_url` is non-empty.

For type 0 logs it:

1. zlib-deflates the JSON array;
2. posts it as multipart form field `payload`;
3. considers any HTTP 200 a success;
4. deletes the uploaded local rows after success.

Stage 3.1.1 returned `log_url=""`, so these hidden logs never reached our backend.

## Stage 3.1.2 implementation

- MID1 now returns a source-backed client error URL, defaulting to:

  ```text
  <GXB_SELF_URL origin>/client-log
  ```

  With defaults this is `http://172.20.0.21:9000/client-log`.

- Override with `GXB_CLIENT_LOG_URL` when needed.
- Added `POST /client-log`.
- Added a binary-safe multipart parser because the Cocos client writes compressed bytes into a normal multipart form field.
- Supports standard zlib, raw deflate, and gzip decoding attempts.
- Decoded rows are written to:

  ```text
  runtime_logs/client_error_logs.jsonl
  runtime_logs/client_error_uploads.jsonl
  ```

- Undecodable compressed payloads are preserved as base64 in:

  ```text
  runtime_logs/client_error_raw.jsonl
  ```

- Crash dump uploads are captured under:

  ```text
  runtime_logs/client_crash_uploads/
  ```

This endpoint is observability only. It does not mutate player/game state and does not fabricate errors.

## Test boundary

No Flask/APK runtime test was performed by this build pass. Only Python syntax compilation is allowed by the project workflow.

For the device test, remain in the stuck/locked lobby for **at least 35–45 seconds** after login so the client's 30-second ErrorLogPoster cycle can fire. Because `xyd.db.errorLog` is persistent, the first upload may include historical rows from earlier runs; the backend preserves them all for review.
