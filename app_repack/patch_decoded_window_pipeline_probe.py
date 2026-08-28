#!/usr/bin/env python3
"""Instrument current GXB window/resource construction without changing behavior.

Adds synchronous breadcrumbs around WindowManager.openWindow(), BaseWindow.loadRes(),
and AssetLoader.loadNodeFromJson()/cc.CSLoader:createNode() in every packaged Lua tree.
Uses xyd.__gxbResourceProbe when available, otherwise writes directly to the same
resource_pipeline_trace.log used by the V061 AssetDownload probe.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import shutil

MARKER = "GXB_WINDOW_PIPELINE_PROBE_V062"
BACKUP = ".gxb_v062_window_probe_original"

HELPER = r'''-- GXB_WINDOW_PIPELINE_PROBE_V062_BEGIN
local function __gxb_window_probe(arg_0, arg_1)
    pcall(function()
        if xyd.__gxbResourceProbe then
            return xyd.__gxbResourceProbe(arg_0, arg_1)
        end

        local var_0 = arg_1 or {}
        var_0.__gxb_probe = "window_pipeline_v062"
        var_0.event = tostring(arg_0 or "unknown")
        var_0.time = os.time and os.time() or 0
        local var_1 = require("cjson").encode(var_0)
        local var_2 = xyd.versionUpdatePath .. "resource_pipeline_trace.log"
        local var_3 = io.open(var_2, "a")
        if var_3 then
            var_3:write(var_1 .. "\n")
            var_3:close()
        end
        if xyd.Backend and xyd.Backend.get then
            local var_4 = xyd.Backend.get()
            if var_4 and var_4.log then
                var_4:log(0, var_1, function() return end)
            end
        end
    end)
end
-- GXB_WINDOW_PIPELINE_PROBE_V062_END
'''

def repl(text, old, new, label):
    n=text.count(old)
    if n != 1:
        raise RuntimeError(f"{label}: expected 1 anchor, found {n}")
    return text.replace(old,new,1)

def patch_windowmanager(text:str)->str:
    if MARKER in text: return text
    text = repl(text, 'var_0_0.togetherNames = {\n\t"main_scene_top",\n\t"main_scene_right"\n}\n',
                'var_0_0.togetherNames = {\n\t"main_scene_top",\n\t"main_scene_right"\n}\n\n'+HELPER+'\n', 'WM helper')
    text = repl(text,
'''function var_0_0.openWindow(arg_11_0, arg_11_1, arg_11_2, arg_11_3)\n\tif NO_CACHE_MODE''',
'''function var_0_0.openWindow(arg_11_0, arg_11_1, arg_11_2, arg_11_3)\n\t__gxb_window_probe("wm_open_enter", {window = tostring(arg_11_1), class = tostring(xyd.tables.window:className(arg_11_1) or ""), resource = tostring(xyd.tables.window:resource(arg_11_1) or ""), already_open = arg_11_0.windows_[arg_11_1] ~= nil})\n\n\tif NO_CACHE_MODE''', 'WM enter')
    text = repl(text,
'''\tlocal var_11_1 = import("app.windows." .. xyd.tables.window:className(arg_11_1)).new(arg_11_1, arg_11_2)\n\n\tvar_11_1:retain()''',
'''\t__gxb_window_probe("wm_before_import_new", {window = tostring(arg_11_1), class = tostring(xyd.tables.window:className(arg_11_1) or "")})\n\tlocal var_11_1 = import("app.windows." .. xyd.tables.window:className(arg_11_1)).new(arg_11_1, arg_11_2)\n\t__gxb_window_probe("wm_after_import_new", {window = tostring(arg_11_1), object = tostring(var_11_1)})\n\n\tvar_11_1:retain()\n\t__gxb_window_probe("wm_after_retain", {window = tostring(arg_11_1)})''', 'WM import/new')
    text = repl(text,
'''\ttable.insert(arg_11_0.windowsQueue_, arg_11_1)\n\txyd.AssetDownload.get():preloadWindowsByName(arg_11_1, function()\n\t\tvar_11_1:loadRes()''',
'''\ttable.insert(arg_11_0.windowsQueue_, arg_11_1)\n\t__gxb_window_probe("wm_before_preload", {window = tostring(arg_11_1)})\n\txyd.AssetDownload.get():preloadWindowsByName(arg_11_1, function()\n\t\t__gxb_window_probe("wm_preload_callback", {window = tostring(arg_11_1)})\n\t\t__gxb_window_probe("wm_before_loadres", {window = tostring(arg_11_1)})\n\t\tvar_11_1:loadRes()\n\t\t__gxb_window_probe("wm_after_loadres", {window = tostring(arg_11_1), is_loaded = tostring(var_11_1 and var_11_1.isLoaded)})''', 'WM preload/load')
    text = repl(text,
'''\t\tvar_11_1:willOpen(arg_11_2)\n\n\t\tlocal var_13_0 = var_11_1:getContentSize()''',
'''\t\t__gxb_window_probe("wm_before_willopen", {window = tostring(arg_11_1)})\n\t\tvar_11_1:willOpen(arg_11_2)\n\t\t__gxb_window_probe("wm_after_willopen", {window = tostring(arg_11_1)})\n\n\t\t__gxb_window_probe("wm_before_contentsize", {window = tostring(arg_11_1)})\n\t\tlocal var_13_0 = var_11_1:getContentSize()\n\t\t__gxb_window_probe("wm_after_contentsize", {window = tostring(arg_11_1), width = tonumber(var_13_0.width or 0), height = tonumber(var_13_0.height or 0)})''', 'WM willopen/content')
    text = repl(text,
'''\t\tvar_11_1:addTo(var_13_1, var_11_1:priority())\n\t\targ_11_0:playWindowOpenAnimations_(var_11_1, function()''',
'''\t\t__gxb_window_probe("wm_before_addto", {window = tostring(arg_11_1)})\n\t\tvar_11_1:addTo(var_13_1, var_11_1:priority())\n\t\t__gxb_window_probe("wm_after_addto", {window = tostring(arg_11_1)})\n\t\t__gxb_window_probe("wm_before_open_animation", {window = tostring(arg_11_1)})\n\t\targ_11_0:playWindowOpenAnimations_(var_11_1, function()\n\t\t\t__gxb_window_probe("wm_open_animation_callback", {window = tostring(arg_11_1)})''', 'WM add/anim')
    text = repl(text,
'''\t\t\tvar_11_1:didOpen(arg_11_2)\n\t\t\tvar_11_0(var_11_1)''',
'''\t\t\t__gxb_window_probe("wm_before_didopen", {window = tostring(arg_11_1)})\n\t\t\tvar_11_1:didOpen(arg_11_2)\n\t\t\t__gxb_window_probe("wm_after_didopen", {window = tostring(arg_11_1)})\n\t\t\tvar_11_0(var_11_1)\n\t\t\t__gxb_window_probe("wm_after_complete_open", {window = tostring(arg_11_1)})''', 'WM didOpen')
    return text

def patch_assetloader(text:str)->str:
    if MARKER in text: return text
    text = repl(text, 'local var_0_1 = import("framework.scheduler")\n', 'local var_0_1 = import("framework.scheduler")\n\n'+HELPER+'\n', 'AL helper')
    text = repl(text,
'''function var_0_0.loadNodeFromJson(arg_10_0, arg_10_1)\n\tif not xyd.assetDownloadErrorLog(arg_10_1) then''',
'''function var_0_0.loadNodeFromJson(arg_10_0, arg_10_1)\n\t__gxb_window_probe("assetloader_loadnode_enter", {resource = tostring(arg_10_1 or "")})\n\tif not xyd.assetDownloadErrorLog(arg_10_1) then\n\t\t__gxb_window_probe("assetloader_loadnode_assetcheck_fail", {resource = tostring(arg_10_1 or "")})''', 'AL enter')
    text = repl(text,
'''\treturn cc.CSLoader:createNode(arg_10_1)\nend''',
'''\t__gxb_window_probe("assetloader_before_csloader", {resource = tostring(arg_10_1 or "")})\n\tlocal var_10_probe_node = cc.CSLoader:createNode(arg_10_1)\n\t__gxb_window_probe("assetloader_after_csloader", {resource = tostring(arg_10_1 or ""), node = tostring(var_10_probe_node)})\n\treturn var_10_probe_node\nend''', 'AL CSLoader')
    return text

def patch_basewindow(text:str)->str:
    if MARKER in text: return text
    text = repl(text, 'local var_0_3 = import("app.common.ui.SpineEffect")\n', 'local var_0_3 = import("app.common.ui.SpineEffect")\n\n'+HELPER+'\n', 'BW helper')
    text = repl(text,
'''function var_0_0.loadRes(arg_3_0)\n\tlocal var_3_0 = xyd.tables.window:resource(arg_3_0.name)''',
'''function var_0_0.loadRes(arg_3_0)\n\tlocal var_3_0 = xyd.tables.window:resource(arg_3_0.name)\n\t__gxb_window_probe("basewindow_loadres_enter", {window = tostring(arg_3_0.name or ""), resource = tostring(var_3_0 or "")})''', 'BW enter')
    text = repl(text,
'''\targ_3_0.hasLoadRes = true\n\n\targ_3_0:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson(var_3_0))''',
'''\targ_3_0.hasLoadRes = true\n\t__gxb_window_probe("basewindow_before_loadnode", {window = tostring(arg_3_0.name or ""), resource = tostring(var_3_0 or "")})\n\tlocal var_3_probe_node = xyd.AssetLoader.get():loadNodeFromJson(var_3_0)\n\t__gxb_window_probe("basewindow_after_loadnode", {window = tostring(arg_3_0.name or ""), resource = tostring(var_3_0 or ""), node = tostring(var_3_probe_node)})\n\t__gxb_window_probe("basewindow_before_setupcontent", {window = tostring(arg_3_0.name or "")})\n\targ_3_0:setupContentView_(var_3_probe_node)\n\t__gxb_window_probe("basewindow_after_setupcontent", {window = tostring(arg_3_0.name or "")})''', 'BW loadnode/setup')
    return text

def targets(root:Path):
    out=[]
    for tree in ('src_32','src_64','src'):
        specs=[
            (root/'assets'/tree/'app/common/ui/WindowManager.lua', patch_windowmanager),
            (root/'assets'/tree/'app/common/AssetLoader.lua', patch_assetloader),
            (root/'assets'/tree/'app/common/ui/BaseWindow.lua', patch_basewindow),
        ]
        out += [(p,fn) for p,fn in specs if p.is_file()]
    return out

def install(root:Path):
    ts=targets(root)
    if not ts: raise RuntimeError('no window pipeline probe targets found')
    n=0
    for p,fn in ts:
        txt=p.read_text(encoding='utf-8-sig')
        if MARKER in txt:
            print('[WINDOW-PROBE] already patched:',p); continue
        bak=p.with_name(p.name+BACKUP)
        if not bak.exists(): shutil.copy2(p,bak)
        p.write_text(fn(txt),encoding='utf-8')
        print('[WINDOW-PROBE] patched:',p); n+=1
    print(f'[WINDOW-PROBE] complete; modified={n}, discovered={len(ts)}')

def remove(root:Path):
    n=0
    for p,_ in targets(root):
        bak=p.with_name(p.name+BACKUP)
        if bak.exists(): shutil.copy2(bak,p); bak.unlink(); n+=1; print('[WINDOW-PROBE] restored:',p)
    print('[WINDOW-PROBE] restore complete; restored=',n)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('decoded_root',type=Path)
    ap.add_argument('--remove',action='store_true')
    a=ap.parse_args()
    (remove if a.remove else install)(a.decoded_root)
if __name__=='__main__': main()
