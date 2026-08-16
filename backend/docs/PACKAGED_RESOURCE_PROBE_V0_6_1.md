# v0.6.1 packaged resource probe

Purpose: locate the exact Chapter-2 jellyfish/download failure boundary without
editing smali or native libraries and without changing gameplay protocol.

## Why this replaces the v0.6.0 writable overlay

The v0.6.0 writable `src_64/app/xinyoudi.lua` experiment produced no trace file.
That is a failed instrumentation load, not evidence that Lua or FileDownloader
crashed. The old `pull` command also force-stopped the package before reading the
trace, so the app closing after `pull` was tool behavior.

The user already has a working apktool/LuaJIT-decompiler workshop. v0.6.1 patches
only the already-decoded plaintext Lua that will be packaged into the APK, in both
`src_32` and `src_64` trees.

Files touched:

```text
assets/src_32/app/common/AssetDownload.lua
assets/src_64/app/common/AssetDownload.lua
assets/src_32/app/common/ui/LoadingProxy.lua
assets/src_64/app/common/ui/LoadingProxy.lua
```

No smali or `.so` file is changed by this probe.

## Patch command

After `decompile_and_patch.sh` has copied the plaintext Lua into `decoded_gxb`, but
before `apktool b` runs:

```bash
python3 /path/to/gxb-backend-v0.6.1-packaged-resource-probe-2026-08-17/tools/patch_decoded_assetdownload_probe.py \
    /home/akm/Miscallaneus/recovery/gxb/workdir/decoded_gxb
```

Because the user's current `patch_game.sh` immediately rebuilds after
`decompile_and_patch.sh`, the easiest repeatable integration is to add this one line
near the end of `decompile_and_patch.sh`, immediately before its final
"Handing control back" message:

```bash
python3 /ABSOLUTE/PATH/TO/v0.6.1/tools/patch_decoded_assetdownload_probe.py \
  "$WORKDIR/$DECODE_DIR"
```

Then continue using the existing apktool/signing workflow.

The patcher makes `.gxb_v061_probe_original` backups beside each modified Lua file.
To restore the decoded tree:

```bash
python3 tools/patch_decoded_assetdownload_probe.py /path/to/decoded_gxb --remove
```

## Runtime capture

Run the v0.6.1 backend and launch the instrumented APK. Reproduce campaign `200002`
once and leave the jellyfish visible briefly.

Primary server-side trace:

```text
runtime_logs/resource_client_probe.jsonl
```

The Lua probe sends these records using the game's existing source-defined
`Backend:log(0, payload, callback)` transport after login has supplied `log_url`.
The backend recognizes `__gxb_probe=resource_pipeline_v061` and keeps these records
separate from genuine client errors.

A synchronous local fallback is also written to:

```text
/data/data/com.carolgames.gxb/files/com.carolgames.gxb/resource_pipeline_trace.log
```

It can be pulled without stopping the app:

```bash
python3 tools/pull_packaged_resource_probe_adb.py
```

Unlike the v0.6.0 pull helper, this does **not** call `am force-stop` unless
`--force-stop` is explicitly supplied.

## How to interpret the trace

Expected sequence for the current theory:

```text
assetdownload_module_loaded
preload_battle_enter
preload_battle_queue
preload_battle_add_loading
loadingproxy_add_new
download_files_enter
insert_to_stack
download_file_before_native
download_file_native_call_returned   # if the binding returns immediately
... /res/<basename>.<md5> GET ...
download_file_native_finish
loadingproxy_remove
```

Important forks:

- `loadingproxy_add_new` exists, but no `preload_battle_add_loading`:
  another subsystem is opening the jellyfish; use its traceback.
- `preload_battle_queue count=0`:
  the stall is after/beside resource selection, not missing lazy resources.
- queue is nonzero but no `download_files_enter`:
  Lua scheduling/callback path is failing before the downloader.
- `download_file_before_native` is the last line:
  the Lua-visible call into `xyd.FileDownloader` blocks or throws before returning.
- `download_file_native_call_returned` appears but no `/res/` GET and no finish:
  native downloader accepted the call but never emitted/completed HTTP.
- `download_file_native_finish` reports failure:
  its result/code is direct evidence for the next server/client investigation.
- `/res/` GET appears:
  switch investigation to actual downloader HTTP requirements (headers, range,
  response codes, content-length, resume semantics).

## What this probe intentionally does not do

- no MID113 changes;
- no MID2 fabricated update packages;
- no lazy key deletion;
- no resource copying into the device;
- no dummy hashes;
- no native/smali patching;
- no gameplay-state mutation.

The goal is to stop guessing about the downloader boundary before deciding whether a
server-only fix is possible.
