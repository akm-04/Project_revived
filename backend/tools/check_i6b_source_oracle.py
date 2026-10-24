#!/usr/bin/env python3
"""Verify narrow client-source facts bounding I6B ActivityDirectory.

This is lexical/hash evidence only. It does not infer original-server schedules,
reachability, reset semantics, or child Activity mechanics.
"""
from __future__ import annotations
import fnmatch, hashlib, json, sys, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OROOT=Path(sys.argv[1] if len(sys.argv)>1 else "/mnt/data")
lock=json.loads((ROOT/"oracles.lock.json").read_text())
fixture=json.loads((ROOT/"testdata/sourcefacts/pass496_i6b_activity_directory.json").read_text())

def fsha(p:Path)->str:
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1<<20),b''): h.update(b)
    return h.hexdigest()
def locate(oid:str)->Path:
    o=next(x for x in lock['oracles'] if x['id']==oid)
    for p in sorted(OROOT.iterdir()):
        if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in o['filename_patterns']) and fsha(p)==o['sha256']:
            return p
    raise SystemExit(f"{oid}: verified oracle not found")
def shab(b:bytes)->str:return hashlib.sha256(b).hexdigest()
current=locate('current_src64'); old=locate('old_client')
cp={
 'Activities.lua':'app-assets/output/assets/src_64/app/model/Activities.lua',
 'SelfPlayer.lua':'app-assets/output/assets/src_64/app/model/SelfPlayer.lua',
 'Backend.lua':'app-assets/output/assets/src_64/app/common/network/Backend.lua',
 'mid.lua':'app-assets/output/assets/src_64/app/common/network/mid.lua',
 'HeroCollectWindow.lua':'app-assets/output/assets/src_64/app/windows/HeroCollectWindow.lua',
 'HeroListCell.lua':'app-assets/output/assets/src_64/app/windows/HeroListCell.lua',
}
op={
 'Activities.lua':'src/app/model/Activities.lua','SelfPlayer.lua':'src/app/model/SelfPlayer.lua',
 'Backend.lua':'src/app/common/network/Backend.lua','mid.lua':'src/app/common/network/mid.lua',
}
errs=[]; cur={}; hist={}
with zipfile.ZipFile(current) as z:
    for n,p in cp.items():
        b=z.read(p); cur[n]=b.decode('utf-8-sig',errors='replace')
        if shab(b)!=fixture['current_src64'][n]: errs.append(f"current hash drift {n}: {shab(b)}")
with zipfile.ZipFile(old) as z:
    for n,p in op.items():
        b=z.read(p); hist[n]=b.decode('utf-8-sig',errors='replace')
        if shab(b)!=fixture['old_client'][n]: errs.append(f"old hash drift {n}: {shab(b)}")
checks=[
 ('MID identities', 'xyd.mid.ACTIVITIES = 229' in cur['mid.lua'] and 'xyd.mid.LOAD_SINGLE_ACTIVITY = 234' in cur['mid.lua']),
 ('MID229 empty request/list projection', 'request(xyd.mid.ACTIVITIES, {}' in cur['Activities.lua'] and 'activities = arg_29_1.params.list' in cur['Activities.lua']),
 ('MID234 request and success handler', 'activity_id = arg_21_1' in cur['Activities.lua'] and 'LOAD_SINGLE_ACTIVITY' in cur['Activities.lua'] and 'onLoadSingleActivity_' in cur['Activities.lua']),
 ('bootstrap hydrates activities through MID identity', 'local var_221_12 = xyd.mid.ACTIVITIES' in cur['SelfPlayer.lua'] and 'onLoadActivities_' in cur['SelfPlayer.lua']),
 ('web request injects token and region', 'arg_23_2.token = arg_23_0.token_' in cur['Backend.lua'] and 'arg_23_2.region = arg_23_0.region_' in cur['Backend.lua']),
 ('non-200 follows error callback before successful event dispatch', 'if var_31_1 ~= 200 then' in cur['Backend.lua'] and 'xyd.error.ERROR' in cur['Backend.lua'] and 'mid2EventNames_[xyd.mid.LOAD_SINGLE_ACTIVITY]' in cur['Backend.lua']),
 ('1032 callers do not gate Hero UI on successful payload', 'activity_id = xyd.Activities.HalfPriceSkill' in cur['HeroCollectWindow.lua'] and 'openWindow(xyd.WindowName.heroMainWnd' in cur['HeroCollectWindow.lua'] and 'activity_id = xyd.Activities.HalfPriceSkill' in cur['HeroListCell.lua'] and 'openWindow(xyd.WindowName.heroMainWnd' in cur['HeroListCell.lua']),
 ('historical client corroborates MID229/MID234/bootstrap shape', 'xyd.mid.ACTIVITIES = 229' in hist['mid.lua'] and 'xyd.mid.LOAD_SINGLE_ACTIVITY = 234' in hist['mid.lua'] and 'request(xyd.mid.ACTIVITIES' in hist['Activities.lua'] and 'onLoadActivities_' in hist['SelfPlayer.lua']),
]
for label,ok in checks:
    if not ok: errs.append('source fact missing: '+label)
if errs:
    print('I6B SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    raise SystemExit(1)
print('I6B SOURCE ORACLE CHECK: PASS')
print('verified current/historical MID229/MID234/bootstrap/error-path hashes and source shape; no Activity mechanics/reset semantics inferred')
