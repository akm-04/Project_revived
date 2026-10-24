#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import base64,csv,fnmatch,hashlib,io,json,re,sys,zipfile
ROOT=Path(__file__).resolve().parents[1]
OROOT=Path(sys.argv[1] if len(sys.argv)>1 else '/mnt/data')
WANT_ARCHIVE='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
ERR=[]

def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(1<<20),b''): h.update(b)
 return h.hexdigest()

def locate():
 for p in sorted(OROOT.iterdir()):
  if p.is_file() and p.suffix.lower()=='.zip' and sha(p)==WANT_ARCHIVE:return p
 raise SystemExit('CA4-2A exact current src_64 archive unavailable')

def item_rows(raw:bytes):
 text=raw.decode('utf-8-sig','replace'); m=re.fullmatch(r'\s*return\s+"([A-Za-z0-9+/=\r\n]+)"\s*',text,re.S)
 if not m: raise ValueError('item.lua wrapper drift')
 rd=csv.reader(io.StringIO(base64.b64decode(m.group(1)).decode('utf-8-sig','replace')),delimiter='\t')
 next(rd); keys=next(rd); out={}
 for row in rd:
  if not row or not row[0]: continue
  row += ['']*max(0,len(keys)-len(row)); rec=dict(zip(keys,row))
  try:i=int(float(rec['id']))
  except Exception:continue
  out[i]=rec
 return out

def indexed(raw:bytes):
 text=raw.decode('utf-8-sig').strip(); m=re.fullmatch(r'return\s+"([A-Za-z0-9+/=]+)"',text,re.S)
 if not m: raise ValueError('partner.lua wrapper drift')
 d=base64.b64decode(m.group(1),validate=True).decode('utf-8')
 km=re.search(r'table\.keys\s*=\s*\{(.*?)\}\s*table\.rows',d,re.S)
 if not km: raise ValueError('partner keys missing')
 keys={n:int(i) for n,i in re.findall(r'([A-Za-z0-9_]+)\s*=\s*(\d+)',km.group(1))}
 rm=re.search(r'table\.rows\s*=\s*\{',d); pos=rm.end(); rows={}
 def skip(i):
  while i<len(d) and (d[i].isspace() or d[i]==','): i+=1
  return i
 def val(i):
  i=skip(i)
  if d[i]=='"':
   j=i+1; out=[]; esc=False
   while j<len(d):
    ch=d[j]
    if esc: out.append(ch); esc=False; j+=1; continue
    if ch=='\\': esc=True; j+=1; continue
    if ch=='"': return ''.join(out),j+1
    out.append(ch); j+=1
   raise ValueError('unterminated quote')
  lm=re.match(r'\[(=*)\[',d[i:])
  if lm:
   eq=lm.group(1); start=i+len(lm.group(0)); close=']'+eq+']'; end=d.find(close,start)
   if end<0:raise ValueError('unterminated long string')
   return d[start:end],end+len(close)
  m2=re.match(r'([^,}\s]+)',d[i:]);
  if not m2: raise ValueError('unsupported token')
  return m2.group(1),i+len(m2.group(1))
 while True:
  pos=skip(pos)
  if d[pos]=='}':break
  mr=re.match(r'\[(\d+)\]\s*=\s*\{',d[pos:])
  if not mr: raise ValueError('row prefix drift')
  rid=int(mr.group(1)); pos+=mr.end(); vals=[]
  while True:
   pos=skip(pos)
   if d[pos]=='}':pos+=1;break
   x,pos=val(pos); vals.append(x)
  rows[rid]=vals
 return keys,rows

def field(keys,vals,name):return vals[keys[name]-1]
def iv(v):
 try:return int(float(v or 0))
 except Exception:return 0

arc=locate()
with zipfile.ZipFile(arc) as z:
 partner=z.read('app-assets/output/assets/src_64/data/tables/partner.lua')
 item=z.read('app-assets/output/assets/src_64/data/tables/item.lua')
if hashlib.sha256(partner).hexdigest()!='a1d3d11e308140e57ed861a2dc0031f562420881405a5ba6f62987df8952bc49':ERR.append('partner.lua hash drift')
if hashlib.sha256(item).hexdigest()!='59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc':ERR.append('item.lua hash drift')
keys,rows=indexed(partner); items=item_rows(item)
colors=['white','green','green1','blue','blue1','blue2','purple','purple1','purple2','purple3','purple4','orange','orange1','orange2','red','red1']
roots={iid for iid,r in items.items() if iv(r.get('type')) in (1,8)}
direct=[]; zero=ordinary=special=0; oi=set();si=set()
for rid in sorted(rows):
 vals=rows[rid]; tid=iv(field(keys,vals,'id'))
 if tid!=rid:ERR.append(f'row/id mismatch {rid}/{tid}');continue
 for color,name in enumerate(colors,1):
  xs=[iv(x) for x in field(keys,vals,name).split('|')]
  if len(xs)!=6:ERR.append(f'row {rid} {name} slot count {len(xs)}');continue
  for slot,iid in enumerate(xs,1):
   isordinary=False
   if iid==0:zero+=1
   else:
    if iid not in roots:ERR.append(f'non-root mapped item {iid}')
    awaken=iv(items.get(iid,{}).get('is_awaken_item'))
    isordinary=awaken==0
    if isordinary:ordinary+=1;oi.add(iid)
    else:special+=1;si.add(iid)
   direct.append({'color':color,'hero_table_id':tid,'item_id':iid,'ordinary_eligible':isordinary,'slot':slot})
cat=json.loads((ROOT/'internal/content/builtin/generated/hero_equipment_catalog.json').read_text())
if cat.get('positions')!=direct:ERR.append('generated Hero equipment positions differ from direct source parse')
if (len(rows),len(direct),ordinary,special,zero,len(oi),len(si))!=(555,53280,50504,1646,1130,214,164):ERR.append(f'topology drift {(len(rows),len(direct),ordinary,special,zero,len(oi),len(si))}')
man=json.loads((ROOT/'internal/content/builtin/generated/manifest.json').read_text())
if man.get('source_archive_sha256')!=WANT_ARCHIVE:ERR.append('manifest source archive drift')
if (man.get('compiler_version'),man.get('parser_version'))!=('ca4-2a','lua-generated-v7-hero-equipment'):ERR.append('compiler/parser identity drift')
if 'HERO_EQUIPMENT_CA4_2' not in man.get('enabled_capabilities',[]):ERR.append('capability absent')
if ERR:
 print('CA4-2A SOURCE ORACLE CHECK: FAIL'); [print(' -',e) for e in ERR]; raise SystemExit(1)
print('CA4-2A SOURCE ORACLE CHECK: PASS')
print(f'exact current src_64 {WANT_ARCHIVE} -> rows=555 positions=53280 ordinary=50504 special=1646 zero=1130 unique ordinary/special=214/164; generated mapping exactly matches independent direct source parse')
