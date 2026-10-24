#!/usr/bin/env python3
from __future__ import annotations
import fnmatch, hashlib, json, re, sys, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OROOT=Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data')
lock=json.loads((ROOT/'oracles.lock.json').read_text())

def file_sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1<<20),b''):h.update(b)
    return h.hexdigest()

def locate(id):
    o=next(x for x in lock['oracles'] if x['id']==id)
    for p in sorted(OROOT.iterdir()):
        if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in o['filename_patterns']) and file_sha(p)==o['sha256']:
            return p
    raise SystemExit(f'{id}: verified oracle not found')

def member(z,path):
    with zipfile.ZipFile(z) as zz:return zz.read(path)

def h(b):return hashlib.sha256(b).hexdigest()
errs=[]
cur=locate('current_src64'); apk=locate('native_apk')
paths={
 'backend':'app-assets/output/assets/src_64/app/common/network/Backend.lua',
 'mid':'app-assets/output/assets/src_64/app/common/network/mid.lua',
 'functions':'app-assets/output/assets/src_64/framework/functions.lua',
}
b={k:member(cur,v) for k,v in paths.items()}
expected={
 'backend':'95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840',
 'mid':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
 'functions':'88d28150e9c8735f3aecf2cbeff5f60cede5e45edb50060478a7a80714a93378',
}
for k,v in expected.items():
    if h(b[k])!=v:errs.append(f'{k} member hash drift {h(b[k])}')
backend=b['backend'].decode('utf-8-sig'); mid=b['mid'].decode('utf-8-sig'); functions=b['functions'].decode('utf-8-sig')
for sym in ['ARENA_FIGHT_RESULT','PEAK_START_FIGHT','TREASURE_SAVE_BATTLE_RESULT','REARENA_END_FIGHT','REGION_FIGHT_RESULT','CONQUER_SCHOOL_FIGHT_RESULT','SAVE_FURNITURES']:
    if sym not in backend:errs.append('missing special zlib symbol '+sym)
for token in ['[1844] = true','string.urlencode(var_23_8)','addPOSTValue("payload", var_23_15)','var_23_10 and 30 or 20','arg_21_1 ~= xyd.mid.LOAD_CHAT_ROOM_INFO']:
    if token not in backend:errs.append('Backend wire fact missing '+token)
for forbidden in ['client_op_id','client_operation_id','summon_op_id','contextEpoch']:
    if forbidden in backend:errs.append('stock Backend unexpectedly contains '+forbidden)
for token in ['bit(arg_1_0, 36864)','band(arg_1_0, 36864) == 32768','band(arg_2_0, 36864) == 36864']:
    if token.startswith('bit('):continue
    if token not in mid:errs.append('mid.lua route bitmask missing '+token)
for token in ['string.gsub(tostring(arg_51_0), "\\n", "\\r\\n")','([^%w%.%- ])','return string.gsub(arg_51_0, " ", "+")']:
    if token not in functions:errs.append('urlencode source fact missing '+token)
q=member(apk,'smali_classes2/org/cocos2dx/lib/QuickHTTPInterface.smali')
if h(q)!='ed934299d89031f5d0c9c49c7dd47f9056398b0175fa31cb1b3996eaed16e439':errs.append('QuickHTTPInterface member hash drift')
qs=q.decode('utf-8',errors='replace')
for token in ['.method static postContent(','Ljava/lang/String;->getBytes()[B','Ljava/io/DataOutputStream;->write([B)V']:
    if token not in qs:errs.append('QuickHTTP wire fact missing '+token)
if errs:
    print('I2 ORACLE WIRE CHECK: FAIL');[print(' -',e) for e in errs];raise SystemExit(1)
print('I2 ORACLE WIRE CHECK: PASS')
print('current Backend/mid/functions + APK QuickHTTP hashes and frozen wire facts verified')
