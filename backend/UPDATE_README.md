# GXB writable update operator guide

This backend has **two separate asset delivery paths**:

- `local_assets/res/` is the lazy exact-MD5 resource gateway served as `/res/<basename>.<md5>`.
- `local_assets/src_32/` + `src_64/` are sparse writable Lua/data overrides delivered through the client's raw **MID2 UpdateScene ZIP-volume** pipeline.

Do not mix them, and do not bulk-copy APK `src_64` into the writable update trees.

## Pass 35.1 prepared package

The archive ships with the exact **62 recovered server-pushed overrides** mirrored into both `src_32` and `src_64`. They came from `downloaded-assets/output/`, which has priority over packaged APK Lua at runtime.

A one-volume update is already built:

- target resource version: `1.631.2`
- volume: `local_assets/updates/gxb-local-1.631.2.zip.001`
- entries: 124 (62 per architecture tree)
- size: 1,859,658 bytes
- MD5: `b10010f6d63938327b7245abe04df851`
- `silent=false`
- **advertisement disabled by default**

Starting `python3 server.py` therefore does not push this package until you explicitly enable it.

## Enable the prepared update

```bash
python3 tools/set_local_update_enabled.py on
python3 server.py
```

The client should query CENTER MID20480, then raw MID2. If its stored resource version is older than `1.631.2`, the server advertises the volume and the client downloads:

```text
/updates/gxb-local-1.631.2.zip.001
```

The client verifies the assembled ZIP MD5, extracts it into the writable version path, stores resource version `1.631.2`, and restarts. On 64-bit clients writable `src_64` takes precedence over packaged APK `src_64`.

After restart, MID2 should report the installed version and the backend should not offer the same update again.

## Disable advertisement

```bash
python3 tools/set_local_update_enabled.py off
```

This stops future offers. It does **not** remove files already installed on the device.

## Build another intentional sparse update

Put only intentional overrides under both architecture trees, then use a strictly numeric resource version:

```bash
python3 tools/build_local_lua_update.py --version 1.631.3 --disable
```

Review `local_assets/update_manifest.json`, then enable deliberately:

```bash
python3 tools/set_local_update_enabled.py on
```

Resource versions must be exactly `N.N.N`. **Do not use suffixes** such as `1.631.0-local1`; recovered `UpdateScene.compareVersion()` converts the three components numerically.

`--silent` is available only when intentionally testing the source-defined `is_review=1` path. Normal testing should leave it off.

## Recovered override import

For an individual recovered writable file, the existing helper can mirror it into both architecture trees:

```bash
python3 tools/import_lua_override.py \
  --archive /path/to/all-assest-rechecked.zip \
  --layer downloaded \
  --path app/windows/LoginWindow.lua
```

The effective source rule is always:

```text
downloaded/writable src_64/<path> if present
else packaged APK src_64/<path>
```

## Device revalidation checklist

Before launch:

1. Ensure `local_assets/res/` is already populated; an early exact-MD5 404 may remain cached for that app session.
2. If this is a declared fresh-account/tutorial test, **Clear App Data** first.
3. Start with the MID2 manifest disabled and capture the baseline MID20480/MID2 exchange.
4. Enable the prepared package, restart/reconnect, and capture the MID2 advertisement and `/updates/...001` transfer.
5. Capture client/ADB logs for MD5 verification, unzip, stored resource version, and restart.
6. Confirm the next MID2 sends `v=1.631.2` and receives no same-version re-offer.
7. Verify one known recovered writable override is active after restart.
8. Restart once more to confirm persistence, then disable advertisement.

Update-side runtime events are written to:

```text
runtime_logs/local_update_events.jsonl
```

Useful operator help is also available with:

```bash
python3 server.py --help
```

## Safety rules

- Payment remains out of scope.
- Never publish all packaged APK Lua as writable content merely to make an update ZIP.
- Never infer gameplay behavior from an update package; this plane only transports files.
- Keep MID2 and CENTER20480 as raw update/center protocol identities even though they are absent from `app/common/network/mid.lua`.
## Runtime validation status (Pass 35.2 documentation sync)

The Pass35.1 device test confirmed the prepared 1.631.2 chain end-to-end:

1. CENTER MID20480 returned the configured engine/resource URLs.
2. MID2 with an empty/current-old writable version advertised one 1.631.2 volume.
3. The client fetched `gxb-local-1.631.2.zip.001` successfully.
4. The client restarted and immediately reported `v=1.631.2`.
5. MID2 then returned no same-version update (`version_current_or_newer`).
6. ADB inspection showed the sparse writable `src_32` and `src_64` override trees on disk.

The test intentionally did **not** clear app data first and confirmed that installing a resource update does not reset the client tutorial/game database. Fresh tutorial tests must still use Android **Clear App Data** as a separate rule.

The package remains disabled by default in distributed backend archives.

