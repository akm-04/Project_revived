# Stage 3.1.3 — MainScene resource/preload probe

## Why this pass exists

The Stage 3.1.2 APK run still reaches the lobby but produces neither MID 176
`LOAD_FRIENDS` nor MID 2754 `CHECK_GAME_STAT`.  It also produces no
`/client-log` upload even though MID 1 advertises the endpoint.

A source re-check corrects an earlier ordering assumption.  `MainScene` calls
`WindowManager:openWindow()` for left, middle, bottom, touch, and top in order,
but each `openWindow()` schedules an independent asynchronous
`AssetDownload:preloadWindowsByName()` callback.  A bottom-window failure does
not prove that top was never scheduled; bottom and top can independently fail
or wait before their `willOpen()` functions complete.

## Source-confirmed AssetDownload behavior

`WindowManager:openWindow(name)` does:

```text
construct Lua window object
  -> AssetDownload.preloadWindowsByName(name, callback)
      -> loadRes()
      -> willOpen()
      -> add window to scene
      -> open animation
      -> didOpen()
```

`preloadWindowsByName()` checks the client's local `version.json`-derived
`webSkeletonDict_`.  For a file that the manifest says should exist but is
missing locally, the downloader builds this URL:

```text
(xyd.resDownloadUrl or "") .. basename .. "." .. md5
```

The two principal MainScene window resources in the source table are:

```text
main_scene_bottom -> windows/main_bottom_window/main_bottom_window.csb
main_scene_top    -> windows/main_top_window/main_top_window.csb
```

The preload table has no explicit `main_scene_bottom` / `main_scene_top` rows,
so the window resource directory itself is the relevant preload source.

## Stage 3.1.3 backend behavior

Center discovery now advertises, by default:

```text
http://172.20.0.21:9000/res/
```

as `res_download_url`.

Any resulting download attempt is recorded by:

```text
runtime_logs/resource_requests.jsonl
runtime_logs/resource_probe_summary.json
```

The JSONL records only the first request for each distinct requested asset.
The summary tracks retry counts and first/last timestamps.

The probe returns HTTP 404 intentionally.  Source validates the downloaded
file against the expected MD5 and immediately requeues failures.  Returning
fabricated 200 bytes would not fix the asset and would only create misleading
or potentially unsafe state.

Because a missing resource can cause immediate retries, once a
`[RESOURCE PROBE]` line appears the evidence has already been captured; a long
run is unnecessary for this diagnostic.

Disable this diagnostic and restore the Stage 3.1.2 center behavior with:

```bash
GXB_RESOURCE_PROBE=0 python3 server.py
```

Override the base URL with:

```bash
GXB_RES_DOWNLOAD_URL=http://YOUR_HOST:9000/res/ python3 server.py
```

The trailing slash is normalized automatically.

## What this probe can and cannot see

It can see resources requested through `AssetDownload:downloadFiles()`.

It cannot force a request for every resource loaded directly through
`AssetLoader`.  Two direct local dependencies remain important if this probe
stays completely silent:

```text
MainSceneTopWindow:addEcoBar()
  -> EcoSidebar
  -> windows/common_widgets/eco_sidebar.csb

MainSceneBottomWindow:willOpen()
  -> SpineEffect
  -> skeletons/ui_effect/skill_full/skill.json
  -> skeletons/ui_effect/skill_full/skill.atlas
```

Both direct loaders call `xyd.assetDownloadErrorLog()` when their primary file
is absent, but the Stage 3.1.2 run did not produce a client error upload.  Their
absence therefore remains a hypothesis, not a confirmed fact.

## Interpretation matrix

### `resource_requests.jsonl` appears

The local client manifest is trying to recover missing web resources.  The
requested basename and expected MD5 are direct evidence.  Do not compensate by
inventing more MIDs; resource restoration becomes a separate client/assets
problem.

### No resource probe request, still no MID 176 / MID 2754

The MainScene `AssetDownload` preloader is not waiting for a manifest-listed
missing file.  Continue with the synchronous `willOpen()` paths:

- bottom: chat nodes -> skill SpineEffect -> backend redmark -> pet branch -> MID176
- top: EcoSidebar -> left buttons -> player info -> activity list -> entry action -> MID2754

This result would make direct local assets / child-node assumptions / local
model initialization more likely than network or resource-preload recovery.

## Validation

Only Python syntax compilation is performed.  No Flask, endpoint, APK, or
runtime test is performed by the build process.
