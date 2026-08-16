#!/usr/bin/env python3
"""Patch a decoded GXB APK with a minimal packaged-Lua resource probe.

The patch is intentionally Lua-only. It instruments AssetDownload.lua and
LoadingProxy.lua in both packaged source trees so we do not need to guess
whether the running APK selected src_32 or src_64.

Usage:
    python3 tools/patch_decoded_assetdownload_probe.py /path/to/decoded_gxb
    python3 tools/patch_decoded_assetdownload_probe.py /path/to/decoded_gxb --remove

The probe writes one JSON object per line to the app's writable
``resource_pipeline_trace.log``. Once Backend.logURL_ is available, the
AssetDownload probe also posts the same object through the game's existing
Backend:log() transport, which the private backend records in
``runtime_logs/resource_client_probe.jsonl``.

It does not change gameplay state, MIDs, download URLs, lazy keys, or
FileDownloader arguments.
"""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path


MARKER_BEGIN = "-- GXB_RESOURCE_PROBE_V061_BEGIN"
MARKER_END = "-- GXB_RESOURCE_PROBE_V061_END"
BACKUP_SUFFIX = ".gxb_v061_probe_original"

ASSET_HELPER = r'''-- GXB_RESOURCE_PROBE_V061_BEGIN
-- Minimal packaged-Lua tracer for EOL resource/download reconstruction.
-- Every operation is wrapped in pcall so diagnostics cannot intentionally
-- alter the original control flow.
local function __gxb_probe_list(arg_0)
    local var_0 = {}

    if type(arg_0) ~= "table" then
        return var_0
    end

    for iter_0, iter_1 in ipairs(arg_0) do
        if type(iter_1) == "table" then
            table.insert(var_0, tostring(iter_1.path or iter_1[1] or "?"))
        else
            table.insert(var_0, tostring(iter_1))
        end
    end

    return var_0
end

local function __gxb_resource_probe(arg_0, arg_1)
    pcall(function()
        local var_0 = arg_1 or {}

        var_0.__gxb_probe = "resource_pipeline_v061"
        var_0.event = tostring(arg_0 or "unknown")
        var_0.time = os.time and os.time() or 0

        local var_1 = var_0_2.encode(var_0)
        local var_2 = xyd.versionUpdatePath .. "resource_pipeline_trace.log"
        local var_3 = io.open(var_2, "a")

        if var_3 then
            var_3:write(var_1 .. "\n")
            var_3:close()
        end

        if xyd.Backend and xyd.Backend.get then
            local var_4 = xyd.Backend.get()

            if var_4 and var_4.log then
                var_4:log(0, var_1, function()
                    return
                end)
            end
        end
    end)
end

-- LoadingProxy can reuse this writer when AssetDownload is already loaded.
xyd.__gxbResourceProbe = __gxb_resource_probe

__gxb_resource_probe("assetdownload_module_loaded", {
    file_downloader = tostring(xyd.FileDownloader),
    res_download_url = tostring(xyd.resDownloadUrl or "")
})
-- GXB_RESOURCE_PROBE_V061_END
'''

LOADING_HELPER = r'''-- GXB_RESOURCE_PROBE_V061_BEGIN
-- LoadingProxy is intentionally instrumented separately so the jellyfish can
-- be attributed even if it was opened by a path other than AssetDownload.
local function __gxb_loading_probe(arg_0, arg_1)
    pcall(function()
        if xyd.__gxbResourceProbe then
            return xyd.__gxbResourceProbe(arg_0, arg_1)
        end

        local var_0 = arg_1 or {}
        var_0.__gxb_probe = "resource_pipeline_v061"
        var_0.event = tostring(arg_0 or "unknown")
        var_0.time = os.time and os.time() or 0

        local var_1 = require("cjson").encode(var_0)
        local var_2 = xyd.versionUpdatePath .. "resource_pipeline_trace.log"
        local var_3 = io.open(var_2, "a")

        if var_3 then
            var_3:write(var_1 .. "\n")
            var_3:close()
        end
    end)
end
-- GXB_RESOURCE_PROBE_V061_END
'''


def _replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one source anchor, found {count}")
    return text.replace(old, new, 1)


def patch_assetdownload_text(text: str) -> str:
    if MARKER_BEGIN in text:
        return text

    anchor = "local var_0_9 = 0\n"
    text = _replace_once(text, anchor, anchor + "\n" + ASSET_HELPER + "\n", "AssetDownload helper insertion")

    old = "function var_0_1.preloadBattleInfos(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)\n\tlocal var_8_0 = {}"
    new = "function var_0_1.preloadBattleInfos(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)\n\t__gxb_resource_probe(\"preload_battle_enter\", {sounds = __gxb_probe_list(arg_8_1), maps = __gxb_probe_list(arg_8_2), models = __gxb_probe_list(arg_8_3)})\n\n\tlocal var_8_0 = {}"
    text = _replace_once(text, old, new, "preloadBattleInfos enter")

    old = "\tif #var_8_0 <= 0 then\n\t\tvar_8_24()"
    new = "\t__gxb_resource_probe(\"preload_battle_queue\", {count = #var_8_0, paths = __gxb_probe_list(var_8_0)})\n\n\tif #var_8_0 <= 0 then\n\t\tvar_8_24()"
    text = _replace_once(text, old, new, "preloadBattleInfos queue")

    old = "\txyd.LoadingProxy.get():addNewLoading(1.5)\n\n\tlocal function var_8_26"
    new = "\t__gxb_resource_probe(\"preload_battle_add_loading\", {count = #var_8_0})\n\txyd.LoadingProxy.get():addNewLoading(1.5)\n\n\tlocal function var_8_26"
    text = _replace_once(text, old, new, "preloadBattleInfos loading")

    old = "function var_0_1.downloadFiles(arg_36_0, arg_36_1, arg_36_2)\n\tif #arg_36_1 < 1 then"
    new = "function var_0_1.downloadFiles(arg_36_0, arg_36_1, arg_36_2)\n\t__gxb_resource_probe(\"download_files_enter\", {count = #arg_36_1, paths = __gxb_probe_list(arg_36_1)})\n\n\tif #arg_36_1 < 1 then"
    text = _replace_once(text, old, new, "downloadFiles enter")

    old = "function var_0_1.insertToStack(arg_42_0, arg_42_1)\n\tlocal var_42_0 = arg_42_1.path"
    new = "function var_0_1.insertToStack(arg_42_0, arg_42_1)\n\tlocal var_42_0 = arg_42_1.path\n\n\t__gxb_resource_probe(\"insert_to_stack\", {path = tostring(var_42_0), busy = tonumber(arg_42_0.busyProcess or 0), down_count = tonumber(arg_42_0.downFileCount or 0)})"
    text = _replace_once(text, old, new, "insertToStack enter")

    old = "\tlocal var_44_3 = xyd.versionUpdatePath .. var_44_0 .. \".asset_tmp\"\n\n\txyd.FileDownloader:download(var_44_2.url, var_44_3, 0, 10, function(arg_45_0, arg_45_1, arg_45_2)"
    new = "\tlocal var_44_3 = xyd.versionUpdatePath .. var_44_0 .. \".asset_tmp\"\n\n\t__gxb_resource_probe(\"download_file_before_native\", {path = tostring(var_44_0), url = tostring(var_44_2.url), tmp = tostring(var_44_3), md5 = tostring(var_44_1), size = tonumber(arg_44_1.size or 0), res_download_url = tostring(xyd.resDownloadUrl or \"\"), file_downloader = tostring(xyd.FileDownloader)})\n\n\txyd.FileDownloader:download(var_44_2.url, var_44_3, 0, 10, function(arg_45_0, arg_45_1, arg_45_2)"
    text = _replace_once(text, old, new, "downloadFile before native")

    old = "\tend, function(arg_46_0, arg_46_1, arg_46_2)\n\t\targ_44_0.downFileCount = arg_44_0.downFileCount - 1"
    new = "\tend, function(arg_46_0, arg_46_1, arg_46_2)\n\t\t__gxb_resource_probe(\"download_file_native_finish\", {path = tostring(var_44_0), result = tostring(arg_46_0), code = tostring(arg_46_1), reset = tostring(arg_46_2)})\n\n\t\targ_44_0.downFileCount = arg_44_0.downFileCount - 1"
    text = _replace_once(text, old, new, "downloadFile finish")

    old = "\tend)\nend\n\nfunction var_0_1.dealCallbacks"
    new = "\tend)\n\n\t__gxb_resource_probe(\"download_file_native_call_returned\", {path = tostring(var_44_0)})\nend\n\nfunction var_0_1.dealCallbacks"
    text = _replace_once(text, old, new, "downloadFile return")
    return text


def patch_loadingproxy_text(text: str) -> str:
    if MARKER_BEGIN in text:
        return text

    anchor = 'local var_0_3 = "new_loading"\n'
    text = _replace_once(text, anchor, anchor + "\n" + LOADING_HELPER + "\n", "LoadingProxy helper insertion")

    old = "function var_0_0.addNewLoading(arg_8_0, arg_8_1)\n\targ_8_0.count_ = arg_8_0.count_ + 1"
    new = "function var_0_0.addNewLoading(arg_8_0, arg_8_1)\n\tlocal var_8_probe_tb = \"\"\n\tpcall(function()\n\t\tif debug and debug.traceback then\n\t\t\tvar_8_probe_tb = debug.traceback(\"addNewLoading\", 2)\n\t\tend\n\tend)\n\t__gxb_loading_probe(\"loadingproxy_add_new\", {delay = tonumber(arg_8_1 or 0), count_before = tonumber(arg_8_0.count_ or 0), traceback = var_8_probe_tb})\n\n\targ_8_0.count_ = arg_8_0.count_ + 1"
    text = _replace_once(text, old, new, "LoadingProxy addNewLoading")

    old = "function var_0_0.removeLoading(arg_9_0)\n\tif arg_9_0.count_ > 0 then"
    new = "function var_0_0.removeLoading(arg_9_0)\n\t__gxb_loading_probe(\"loadingproxy_remove\", {count_before = tonumber(arg_9_0.count_ or 0)})\n\n\tif arg_9_0.count_ > 0 then"
    text = _replace_once(text, old, new, "LoadingProxy removeLoading")
    return text


def asset_targets(decoded_root: Path) -> list[Path]:
    candidates = [
        decoded_root / "assets" / "src_32" / "app" / "common" / "AssetDownload.lua",
        decoded_root / "assets" / "src_64" / "app" / "common" / "AssetDownload.lua",
        decoded_root / "assets" / "src" / "app" / "common" / "AssetDownload.lua",
    ]
    return [path for path in candidates if path.is_file()]


def loading_targets(decoded_root: Path) -> list[Path]:
    candidates = [
        decoded_root / "assets" / "src_32" / "app" / "common" / "ui" / "LoadingProxy.lua",
        decoded_root / "assets" / "src_64" / "app" / "common" / "ui" / "LoadingProxy.lua",
        decoded_root / "assets" / "src" / "app" / "common" / "ui" / "LoadingProxy.lua",
    ]
    return [path for path in candidates if path.is_file()]


def _install_one(path: Path, patcher) -> bool:
    backup = path.with_name(path.name + BACKUP_SUFFIX)
    text = path.read_text(encoding="utf-8-sig")
    if MARKER_BEGIN in text:
        print(f"[RESOURCE-PROBE] already patched: {path}")
        return False
    if not backup.exists():
        shutil.copy2(path, backup)
    path.write_text(patcher(text), encoding="utf-8")
    print(f"[RESOURCE-PROBE] patched: {path}")
    print(f"[RESOURCE-PROBE] backup : {backup}")
    return True


def install(decoded_root: Path) -> None:
    assets = asset_targets(decoded_root)
    loading = loading_targets(decoded_root)
    if not assets:
        raise RuntimeError(f"no packaged AssetDownload.lua found below {decoded_root / 'assets'}")
    if not loading:
        raise RuntimeError(f"no packaged LoadingProxy.lua found below {decoded_root / 'assets'}")

    modified = 0
    for path in assets:
        modified += int(_install_one(path, patch_assetdownload_text))
    for path in loading:
        modified += int(_install_one(path, patch_loadingproxy_text))

    print(f"[RESOURCE-PROBE] complete; modified={modified}, discovered={len(assets) + len(loading)}")
    print("Rebuild/sign the APK with your existing workflow, reproduce 200002 once, then inspect server runtime_logs/resource_client_probe.jsonl.")


def _restore_one(path: Path) -> bool:
    backup = path.with_name(path.name + BACKUP_SUFFIX)
    if backup.is_file():
        shutil.copy2(backup, path)
        backup.unlink()
        print(f"[RESOURCE-PROBE] restored: {path}")
        return True
    if MARKER_BEGIN in path.read_text(encoding="utf-8-sig"):
        raise RuntimeError(f"{path} is patched but its backup is missing; refusing destructive text surgery")
    return False


def remove(decoded_root: Path) -> None:
    targets = asset_targets(decoded_root) + loading_targets(decoded_root)
    if not targets:
        raise RuntimeError(f"no probe target files found below {decoded_root / 'assets'}")
    restored = sum(int(_restore_one(path)) for path in targets)
    print(f"[RESOURCE-PROBE] restore complete; restored={restored}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("decoded_root", type=Path, help="apktool decoded_gxb directory")
    parser.add_argument("--remove", action="store_true", help="restore .gxb_v061_probe_original backups")
    args = parser.parse_args()
    root = args.decoded_root.resolve()
    if not (root / "assets").is_dir():
        raise RuntimeError(f"decoded APK assets directory not found: {root / 'assets'}")
    if args.remove:
        remove(root)
    else:
        install(root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
