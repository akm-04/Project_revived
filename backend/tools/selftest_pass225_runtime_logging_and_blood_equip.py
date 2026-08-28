#!/usr/bin/env python3
from __future__ import annotations
import json, zipfile
from pathlib import Path
from gxb_backend.observability.console_runtime import classify_legacy_line, CATEGORY_LEVEL
ROOT=Path(__file__).resolve().parent.parent

def check(cond,msg):
    if not cond: raise AssertionError(msg)
    print('PASS',msg)

manifest=json.loads((ROOT/'local_assets/update_manifest.json').read_text())
check(manifest['version']=='1.631.20','OTA version 1.631.20')
check(len(manifest['files'])==146,'Pass212 baseline plus two paired client override families')
check(not any(x.startswith('res/') for x in manifest['files']),'OTA has zero res members')
for rel in ('app/model/NormalHero.lua','app/windows/TaskAwakeCell.lua'):
    a=ROOT/'local_assets/src_32'/rel; b=ROOT/'local_assets/src_64'/rel
    check(a.read_bytes()==b.read_bytes(),f'paired override byte identity {rel}')

n=(ROOT/'local_assets/src_64/app/model/NormalHero.lua').read_text()
check('__eolBloodEquipCollected_' in n,'Blood substitute has dedicated transient collected cache')
check('arg_128_0.equips_[arg_128_1] and arg_128_0.equips_[arg_128_1] > 0' not in n,'ordinary collected slot no longer pre-equips Blood substitute')
check('var_157_is_blood_substitute' in n and 'var_157_display_table_id' in n,'MID54 identifies displayed Blood substitute')
check('arg_157_0.__eolBloodEquipCollected_[arg_157_1] = true' in n,'Blood collected marker set only in successful MID54 callback')
segment=n[n.find('function var_0_3.equipItems'):n.find('function var_0_3.isHasItem')]
check('awakeTwiceStage_ =' not in segment,'client MID54 fix does not mutate durable Blood stage')

t=(ROOT/'local_assets/src_64/app/windows/TaskAwakeCell.lua').read_text()
check('ALREADY_UNLOCK_AWAKE_SKILL' in t and 'openWindow("common_alert"' in t,'runtime-accepted ordinary Awakening common_alert retained')
check('openWindow("awake_twice_select_team"' in t,'stock Blood stage-two route retained')

s=(ROOT/'server.py').read_text()
check('DEBUG_VERBOSE = 1' in s and 'runtime_logs' in s and 'configure_console' in s,'server.py exposes default debug verbosity and auto log')
check(CATEGORY_LEVEL=={'basic':1,'error':1,'missing':1,'window':2,'http_download':3,'full':4},'console categories have stable levels')
check(classify_legacy_line('[RESOURCE CLIENT PROBE] event=wm_open_enter')=='window','window probe classifier')
check(classify_legacy_line('[RESOURCE] served foo <- bar')=='http_download','resource served classifier')
check(classify_legacy_line('1.2.3.4 - - [x] "GET /res/a HTTP/1.1" 404 -')=='error','resource 404 always error/basic-visible')
check(classify_legacy_line('1.2.3.4 - - [x] "POST /client-log HTTP/1.1" 200 -')=='full','raw client-log access reserved for verbose=4')

check(not list(ROOT.glob('PASS*.json')),'root PASS*.json clutter removed')
check((ROOT/'docs/json/PASS225_RUNTIME_EVIDENCE.json').is_file(),'Pass225 JSON evidence stored under docs/json')
check((ROOT/'VERSION.json').is_file(),'operational VERSION.json remains root')

vol=ROOT/'local_assets/updates'/f"{manifest['package']}.001"
with zipfile.ZipFile(vol) as z:
    check(z.testzip() is None,'OTA CRC')
    check(set(z.namelist())==set(manifest['files']),'OTA members match manifest')
print(json.dumps({'pass':'225.0','status':'PASS','ota':manifest['version'],'files':len(manifest['files'])},indent=2))
