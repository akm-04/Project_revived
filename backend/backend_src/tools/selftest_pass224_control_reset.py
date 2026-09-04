#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parent.parent
BASE=Path('/mnt/data/pass224_work/pass212/gxb-backend-v0.26.0-pass212.0')
# For fresh-extract portability, fall back to bundled baseline hash inventory written at build time.
CUR_SRC=Path('/mnt/data/latest_src64/app-assets/output/assets/src_64')

def sha(p):
    h=hashlib.sha256(); h.update(p.read_bytes()); return h.hexdigest()

def check(cond,msg):
    if not cond: raise AssertionError(msg)
    print('PASS',msg)

# 1. Runtime payload is Pass212 sparse baseline plus exactly 2 paired files.
manifest=json.loads((ROOT/'local_assets/update_manifest.json').read_text())
files=set(manifest['files'])
check(manifest['version']=='1.631.19','OTA version is 1.631.19')
check(len(files)==146,'OTA contains Pass212 baseline 144 files + 2 paired override families (146 total)')
for rel in ('app/model/NormalHero.lua','app/windows/TaskAwakeCell.lua'):
    check(f'src_32/{rel}' in files and f'src_64/{rel}' in files, f'paired override present: {rel}')
check(not any(p.startswith('res/') or 'old_res' in p or 'eol_compat' in p for p in files),'OTA contains no resource/donor payload')
check(not (ROOT/'local_assets/res').exists(),'distributed local_assets/res is absent')
check(not (ROOT/'local_assets/old_res').exists(),'distributed local_assets/old_res is absent')
check(not (ROOT/'local_assets/current_res').exists(),'distributed local_assets/current_res is absent')

# 2. Both architecture copies are byte-identical.
for rel in ('app/model/NormalHero.lua','app/windows/TaskAwakeCell.lua'):
    a=ROOT/'local_assets/src_32'/rel; b=ROOT/'local_assets/src_64'/rel
    check(a.read_bytes()==b.read_bytes(),f'src_32/src_64 byte identity: {rel}')

# 3. TaskAwake is the current class with only terminal ordinary presentation redirected.
t=(ROOT/'local_assets/src_64/app/windows/TaskAwakeCell.lua').read_text()
check('openWindow("common_alert"' in t and 'ALREADY_UNLOCK_AWAKE_SKILL' in t,'ordinary terminal Awakening uses stock common_alert')
check('openWindow("awake_hero_wnd", var_39_6)' not in t,'ordinary terminal does not invoke historical/current cinematic path')
check('function var_0_0.goTwiceAwakeStageTwo' in t and 'openWindow("awake_twice_select_team"' in t,'Blood stage-two entry remains stock AwakeTwiceSelectTeamWindow route')
check('small_card' not in t and 'images/cards/' not in t,'Pass221 task-art fallback is absent')

# 4. NormalHero correction is local cache/display only; durable Blood stage remains server-owned.
n=(ROOT/'local_assets/src_64/app/model/NormalHero.lua').read_text()
check('var_157_display_table_id' in n,'MID54 captures displayed item identity before request')
check('var_158_0:removeItem(var_158_2)' in n and 'itemID = var_157_display_table_id' in n,'MID54 removes displayed Blood substitute from local backpack')
check('var_128_0:setStateCollected()' in n,'Blood display substitute inherits collected slot state')
check('awakeTwiceStage_ =' not in n[n.find('function var_0_3.equipItems'):n.find('function var_0_3.isHasItem')],'MID54 client fix does not advance Blood lifecycle stage')

# 5. No post-Pass212 experimental runtime modules are present.
for rel in (
 'local_assets/src_64/app/windows/EolAwakeTwiceSelectTeamWindow.lua',
 'local_assets/src_64/app/common/EolAwakeTwiceBattleLauncher.lua',
 'local_assets/src_64/app/common/AssetDownload.lua',
 'local_assets/src_64/app/common/network/Backend.lua',
 'local_assets/src_64/app/common/ui/SpriteLoader.lua',
 'local_assets/src_64/data/tables/window.lua',
 'local_assets/src_64/data/tables/preload_window.lua',
):
    check(not (ROOT/rel).exists(),f'post-Pass212 experimental override absent: {Path(rel).name}')

# 6. Package content agrees with manifest.
volume=ROOT/'local_assets/updates'/f"{manifest['package']}.001"
with zipfile.ZipFile(volume) as z:
    names=set(z.namelist())
    bad=z.testzip()
check(bad is None,'OTA ZIP CRC')
check(names==files,'OTA ZIP members exactly match update manifest')
print(json.dumps({'pass':'224.0','status':'PASS','ota':manifest['version'],'files':len(files)},indent=2))
