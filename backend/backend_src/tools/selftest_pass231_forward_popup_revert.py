#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, re, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parent.parent
manifest=json.loads((ROOT/'local_assets/update_manifest.json').read_text(encoding='utf-8'))
assert manifest['enabled'] is True
assert manifest['version']=='1.631.22'
assert manifest['silent'] is True
volume=ROOT/'local_assets'/'updates'/f"{manifest['package']}.001"
assert volume.is_file()
with zipfile.ZipFile(volume) as zf:
    names=zf.namelist()
    assert names==manifest['files']
    for arch in ('src_32/app/windows/TaskAwakeCell.lua','src_64/app/windows/TaskAwakeCell.lua'):
        packed=zf.read(arch)
        local=(ROOT/'local_assets'/arch).read_bytes()
        assert packed==local
        text=packed.decode('utf-8-sig')
        m=re.search(r'function var_0_0\.finishHeroTwiceAwake\(.*?\nend', text, re.S)
        assert m, arch
        assert 'common_alert' not in m.group(0), arch
        assert 'ALREADY_UNLOCK_AWAKE_SKILL' not in m.group(0), arch
        assert hashlib.sha256(packed).hexdigest()=='e0f0862ba2f1d1c28e992adf6b9ad2e4b4a7aa9f8b66ef4160b882ae62ffa9ae'
print('PASS231_FORWARD_POPUP_REVERT_SELFTEST_OK')
