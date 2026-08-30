#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, zipfile
ROOT=Path(__file__).resolve().parent.parent
STOCK_SHA='95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840'
PATCH_SHA='99c63b9f5f2795103ca01980a2efb8e6b3b8482e1ecc1493dc14a09b204fa3d1'
OLD='arg_53_0.requests_ = arg_53_0.request_ or {}'
NEW='arg_53_0.requests_ = arg_53_0.requests_ or {}'
for arch in ('src_32','src_64'):
    p=ROOT/'local_assets'/arch/'app/common/network/Backend.lua'
    text=p.read_text(encoding='utf-8-sig')
    assert OLD not in text
    assert text.count(NEW)==1
    assert hashlib.sha256(p.read_bytes()).hexdigest()==PATCH_SHA
manifest=json.loads((ROOT/'local_assets/update_manifest.json').read_text())
assert manifest['version']=='1.631.23'
assert manifest['enabled'] is True and manifest['silent'] is True
for member in ('src_32/app/common/network/Backend.lua','src_64/app/common/network/Backend.lua'):
    assert member in manifest['files']
assert all(not x.endswith('LoadingProxy.lua') for x in manifest['files'])
assert all(not x.endswith('EventCentre.lua') for x in manifest['files'])
volume=ROOT/'local_assets'/'updates'/(manifest['package']+'.001')
with zipfile.ZipFile(volume) as z:
    for member in ('src_32/app/common/network/Backend.lua','src_64/app/common/network/Backend.lua'):
        assert hashlib.sha256(z.read(member)).hexdigest()==PATCH_SHA
# Static proof that the stock typo necessarily clobbers the tracking table:
# Backend.request_ has no declaration/assignment in the authoritative Backend.lua,
# while createRequest_ previously assigned requests_ from request_ or {}.
text=(ROOT/'local_assets'/'src_64'/'app/common/network/Backend.lua').read_text(encoding='utf-8-sig')
assert 'arg_53_0.request_ or {}' not in text
print('Pass280 Wave G request-registry reconciliation: PASS')
