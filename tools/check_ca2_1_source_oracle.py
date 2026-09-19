#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import fnmatch,hashlib,json,sys,zipfile
ROOT=Path(__file__).resolve().parents[1]; OROOT=Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data')
LOCK=json.loads((ROOT/'oracles.lock.json').read_text())
def sha(p):
 h=hashlib.sha256();
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1<<20),b''):h.update(b)
 return h.hexdigest()
def locate(oid):
 e=next(x for x in LOCK['oracles'] if x['id']==oid)
 for p in sorted(OROOT.iterdir()):
  if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in e['filename_patterns']) and sha(p)==e['sha256']:return p
 raise SystemExit(f'{oid}: verified oracle unavailable')
def text(z,n):return z.read(n).decode('utf-8-sig','replace')
cur=locate('current_src64'); errs=[]
with zipfile.ZipFile(cur) as z:
 player=text(z,'app-assets/output/assets/src_64/app/model/Player.lua')
 selfp=text(z,'app-assets/output/assets/src_64/app/model/SelfPlayer.lua')
 superh=text(z,'app-assets/output/assets/src_64/app/model/SuperHero.lua')
 const=text(z,'app-assets/output/assets/src_64/app/common/const.lua')
 mid=text(z,'app-assets/output/assets/src_64/app/common/network/mid.lua')
 checks=[
  ('MID49 resets/loads sort type and Hero list', all(x in player for x in ['arg_11_0.heros_ = {}','arg_11_0.sortType = 0','arg_11_1.params.sort_type','pairs(arg_11_1.params.heros)'])),
  ('MID89 numeric identity present', 'xyd.mid.SAVA_SORT_TYPE = 89' in mid),
  ('MID49 numeric identity present', 'xyd.mid.LOAD_HEROS = 49' in mid),
  ('Super wire requires partner_type fallback', 'partner_type or 0' in superh),
  ('effective Super star ceiling 8', 'SUPER_HERO_TOTAL_STARS = 8' in const),
 ]
 for label,ok in checks:
  if not ok: errs.append(label)
# Exact compiler performs deeper source hashes/counts.
if errs:
 print('CA2-1 SOURCE ORACLE CHECK: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA2-1 SOURCE ORACLE CHECK: PASS')
print('exact current src_64 corroborates MID49/MID89 private roster shape, Super partner_type, and 8-star effective ceiling')
