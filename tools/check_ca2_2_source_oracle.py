#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import fnmatch,hashlib,json,re,sys,zipfile
ROOT=Path(__file__).resolve().parents[1]
OROOT=Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data')
LOCK=json.loads((ROOT/'oracles.lock.json').read_text())
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1<<20),b''):h.update(b)
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
 addexp=text(z,'app-assets/output/assets/src_64/app/windows/AddExpWindow.lua')
 checks=[
  ('MID52', 'xyd.mid.EVOLVE_HERO = 52' in mid),
  ('MID55', 'xyd.mid.USE_EXP_ITEM = 55' in mid),
  ('MID63', 'xyd.mid.USE_EXP_ITEMS = 63' in mid),
  ('MID67', 'xyd.mid.LOAD_HERO_PIECES = 67' in mid),
  ('MID52 partner_id request', 'partner_id = arg_160_1.partner_id' in selfp and 'xyd.mid.EVOLVE_HERO' in selfp),
  ('MID55 request/canonical response fields', all(x in addexp for x in ['item_id = var_12_1','partner_id = arg_12_0.hero:getHeroID()','item_num = arg_12_0.usedItemNums[var_12_1]','total_num = arg_12_0.selfPlayer:getBackpack():getItemNumByID(var_12_1)','arg_17_2.partner_exp','arg_17_2.total_num'])),
  ('MID63 items request', 'items = var_20_2' in addexp and 'addPartnerExps' in addexp),
  ('MID67 top-level numeric map consumer', 'for iter_97_0, iter_97_1 in pairs(arg_97_1.params)' in selfp and 'tonumber(iter_97_0)' in selfp),
  ('Normal cumulative EXP clamp', 'math.min(arg_163_0.exp_ + arg_163_1, var_163_2)' in normal and 'tables.partnerExp:totalExp' in normal),
  ('Super cumulative EXP clamp', 'math.min(arg_165_0.exp_ + arg_165_1, var_165_2)' in superh and 'tables.partnerExp:totalExp' in superh),
 ]
 for label,ok in checks:
  if not ok: errs.append(label)
cat=json.loads((ROOT/'internal/content/builtin/generated/hero_core_catalog.json').read_text())
exp=[(x['item_id'],x['exp_value']) for x in cat.get('exp_items',[])]
if exp != [(50001001,60),(50001002,300),(50001004,1500),(50001005,7500),(50005182,10000)]: errs.append(f'Hero EXP item/value drift {exp}')
normal_rows={x['star']:(x['evolve_num'],x['evolve_mana']) for x in cat['normal_star_rows']}
if {k:normal_rows.get(k) for k in (2,3,4,5)} != {2:(20,35000),3:(50,120000),4:(100,300000),5:(150,800000)}: errs.append('Normal evolution cost drift')
super_rows={x['star']:(x['stone_cost'],x['mana_cost'],x['need_hero_num'],x['effective_client_reachable']) for x in cat['super_star_rows']}
want={2:(0,0,2,True),3:(0,0,3,True),4:(0,0,4,True),5:(0,0,5,True),6:(0,80000000,5,True),7:(300,90000000,5,True),8:(800,100000000,5,True)}
if {k:super_rows.get(k) for k in want} != want: errs.append('Super/Vows evolution policy drift')
if len(cat.get('acquisition_items',[])) != 291: errs.append('Hero piece mapping count drift')
if errs:
 print('CA2-2 SOURCE ORACLE CHECK: FAIL'); [print(' -',e) for e in errs]; raise SystemExit(1)
print('CA2-2 SOURCE ORACLE CHECK: PASS')
print('exact current src_64 corroborates MID52/55/63/67 shapes, EXP behavior/items, qualified base-star costs, and Hero piece map basis')
