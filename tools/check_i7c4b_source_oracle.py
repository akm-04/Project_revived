#!/usr/bin/env python3
from pathlib import Path
import sys,json,zipfile,hashlib,re
sys.path.insert(0,str(Path(__file__).parent));from generate_builtin_content import parse_generated_lua_table
B=Path(__file__).resolve().parents[1];src=Path(sys.argv[1]);assert hashlib.file_digest(src.open('rb'),'sha256').hexdigest()=='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
with zipfile.ZipFile(src)as z:
 def read(n):return z.read('app-assets/output/assets/src_64/'+n)
 manifest=json.loads((B/'internal/content/builtin/generated/manifest.json').read_text());bindings=[x for x in manifest['sources']if x['role']=='I7C4B_ACHIEVEMENT_SOURCE_BOUNDARY'];assert len(bindings)==9
 for r in bindings:assert hashlib.sha256(read(r['path'])).hexdigest()==r['sha256']
 source=parse_generated_lua_table(read('data/tables/achievement.lua'));out=json.loads((B/'internal/content/builtin/generated/achievement_catalog.json').read_text());assert len(source)==len(out['rows'])==33
 for raw,row in zip(sorted(source,key=lambda r:int(r['id'])),out['rows']):assert row==dict(id=int(raw['id']),thresholds=list(map(int,raw['condition'].split('|'))),points=list(map(int,raw['points'].split('|'))),daily=int(raw['is_daily_update']),hidden=int(raw['is_hide']),stamp=int(raw['stamp']))
 mid=read('app/common/network/mid.lua').decode();assert re.search(r'LOAD_ACHIEVEMENT_INFO\s*=\s*1302',mid)and re.search(r'GET_ACHIEVEMENT_AWARD\s*=\s*1303',mid);assert not re.search(r'CHECK_ACHIEVEMENT\s*=',mid)
 model=read('app/model/Achievement.lua').decode();assert 'complete_time'in model and 'CHECK_ACHIEVEMENT'in model
 detail=read('app/windows/AchievementDetailWindow.lua').decode();assert 'complete_time'in detail and all(x in detail.lower()for x in ['silver','gold']) and re.search(r'complete_time\[[^]]+\] > 0',detail)
assert out['rows'][13]['thresholds']==[1,10,20];print('I7C4B SOURCE ORACLE: PASS 33rows/99tiers; source MID1302/1303 known; CHECK unassigned; no inventedroute')
