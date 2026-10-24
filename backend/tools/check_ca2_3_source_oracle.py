#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import fnmatch,hashlib,json,sys,zipfile,re
ROOT=Path(__file__).resolve().parents[1]
OROOT=Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data')
LOCK=json.loads((ROOT/'oracles.lock.json').read_text())
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1<<20),b''): h.update(b)
 return h.hexdigest()
def locate(oid):
 e=next(x for x in LOCK['oracles'] if x['id']==oid)
 for p in sorted(OROOT.iterdir()):
  if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in e['filename_patterns']) and sha(p)==e['sha256']: return p
 raise SystemExit(f'{oid}: verified oracle unavailable')
def text(z,n): return z.read(n).decode('utf-8-sig','replace')
cur=locate('current_src64'); errs=[]
with zipfile.ZipFile(cur) as z:
 mid=text(z,'app-assets/output/assets/src_64/app/common/network/mid.lua')
 selfp=text(z,'app-assets/output/assets/src_64/app/model/SelfPlayer.lua')
 normal=text(z,'app-assets/output/assets/src_64/app/model/NormalHero.lua')
 superh=text(z,'app-assets/output/assets/src_64/app/model/SuperHero.lua')
 herot=text(z,'app-assets/output/assets/src_64/app/common/tables/HeroTable.lua')
 start=text(z,'app-assets/output/assets/src_64/app/common/tables/StarTable.lua')
 collect=text(z,'app-assets/output/assets/src_64/app/windows/HeroCollectWindow.lua')
 superw=text(z,'app-assets/output/assets/src_64/app/windows/SuperPartnerWindow.lua')
 func=text(z,'app-assets/output/assets/src_64/data/tables/function.lua')
 checks=[
  ('MID59 identity','xyd.mid.STONE_SUMMON_HERO = 59' in mid),
  ('MID305 identity','xyd.mid.SUMMON_SUPER_HERO = 305' in mid),
  ('MID64 capacity identity','xyd.mid.EXPAND_HERO_SLOTS = 64' in mid),
  ('MID59 direct Hero response','var_142_0:populate(arg_142_1)' in selfp and 'itemID = tonumber(arg_141_1.stone)' in selfp and 'itemNum = arg_141_1.stone_num' in selfp),
  ('MID305 partner_info response','var_144_0:populate(arg_144_1.partner_info)' in selfp),
  ('MID305 table_id request','table_id = arg_4_0.superHeros[arg_4_0.current_]' in superw),
  ('Normal initialStar default','arg_2_0.star_ = arg_2_3.star or var_0_8:initialStar(arg_2_1)' in normal),
  ('Super initialStar default','arg_2_0.star_ = arg_2_3.star or var_0_7:initialStar(arg_2_1)' in superh),
  ('HeroTable ini_star fallback','return arg_22_0:getRowTable(arg_22_1).ini_star or 1' in herot),
  ('summonPrice source table','arg_1_0.summonPrices_[var_2_0] = tonumber(arg_2_0.summon_price)' in start and 'return arg_7_0.summonPrices_[arg_7_1] or 0' in start),
  ('summon UI Mana check','xyd.tables.star:summonPrice(var_25_4:getStar())' in collect and 'var_30_1 > arg_25_0.selfPlayer.mana' in collect),
  ('Vows prerequisite scan','for iter_19_0 = 1, 5 do' in superw and 'var_19_6:getStar() == xyd.MAX_STAR_LEVEL' in superw),
  ('Function88 Vows level100','"88"' in func and '"Vows"' in func and '"1|100"' in func),
 ]
 for label,ok in checks:
  if not ok: errs.append(label)
cat=json.loads((ROOT/'internal/content/builtin/generated/hero_core_catalog.json').read_text())
# Preserve exact qualified immutable data used by CA2-3.
acq=cat.get('acquisition_items',[])
if len(acq)!=291: errs.append(f'acquisition mapping count drift {len(acq)}')
tmpl={x['table_id']:x for x in cat.get('templates',[])}
try:
 if tmpl[10001062]['initial_star']!=5: errs.append('item 40001062 / Hero 10001062 source initial_star drift')
except KeyError: errs.append('Hero 10001062 template missing')
normal_rows={x['star']:(x['summon_num'],x['summon_mana']) for x in cat.get('normal_star_rows',[])}
want={1:(10,1000),2:(30,50000),3:(80,200000),4:(180,500000),5:(330,1300000)}
if {k:normal_rows.get(k) for k in want} != want: errs.append(f'Normal summon policy drift {normal_rows}')
if len(cat.get('super_prerequisites',[]))!=70: errs.append('Super prerequisite row count drift')
if errs:
 print('CA2-3 SOURCE ORACLE CHECK: FAIL'); [print(' -',e) for e in errs]; raise SystemExit(1)
print('CA2-3 SOURCE ORACLE CHECK: PASS')
print('exact current src_64 corroborates MID59/MID305 wire behavior, source initial-star creation, summon Mana/fragment qualification, Vows prerequisites, and Function88 level-100 gate')
