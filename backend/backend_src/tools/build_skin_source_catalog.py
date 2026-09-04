#!/usr/bin/env python3
from __future__ import annotations
import argparse,base64,csv,hashlib,io,json,re
from pathlib import Path

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def i(v,d=0):
    try:return int(v or 0)
    except:return d

def rows_lua(path):
    text=path.read_text(encoding='utf-8-sig')
    km=re.search(r"keys\s*=\s*\{(.*?)\}\s*,\s*rows\s*=",text,re.S)
    rm=re.search(r"rows\s*=\s*\{(.*)\}\s*\}\s*$",text,re.S)
    if not km or not rm: raise RuntimeError(f'cannot parse {path}')
    keys=re.findall(r'"([^"]*)"',km.group(1))
    chunks=re.findall(r'\{\s*((?:"(?:[^"\\]|\\.)*"\s*,?\s*)+)\}',rm.group(1),re.S)
    out=[]
    for c in chunks:
        vals=re.findall(r'"((?:[^"\\]|\\.)*)"',c)
        if len(vals)==len(keys): out.append(dict(zip(keys,vals)))
    return out

def item_rows(path):
    raw=path.read_text(encoding='utf-8-sig'); m=re.match(r'\s*return\s+"(.*)"\s*$',raw,re.S)
    if not m: raise RuntimeError(f'cannot decode {path}')
    dec=base64.b64decode(m.group(1)).decode('utf-8'); lines=dec.splitlines()
    return [r for r in csv.DictReader(io.StringIO('\n'.join(lines[1:])),delimiter='\t') if r.get('id')]

def build(src64:Path,data_dir:Path):
    skin_p=src64/'data/tables/skin_skill.lua'; item_p=src64/'data/tables/item.lua'
    bp=src64/'app/windows/BackpackWindow.lua'; hm=src64/'app/windows/HeroMainWindow.lua'; sw=src64/'app/windows/SkinSkillSelectWindow.lua'; sp=src64/'app/model/SelfPlayer.lua'; nh=src64/'app/model/NormalHero.lua'; sh=src64/'app/model/SuperHero.lua'; pet=src64/'app/windows/PetAttributeWindow0.lua'
    for p in [skin_p,item_p,bp,hm,sw,sp,nh,sh,pet]:
        if not p.is_file(): raise RuntimeError(f'missing {p}')
    skins=rows_lua(skin_p); items={i(r.get('id')):r for r in item_rows(item_p) if i(r.get('id'))>0}
    awake=json.loads((data_dir/'awakening_mission_meta.json').read_text())
    after={}
    for r in (awake.get('ordinary') or {}).values():
        b=i(r.get('table_id')); a=i(r.get('awaken_table_id'))
        if b>0 and a>0: after[b]=a
    out=[]; girls=set(); skill=0; cosmetic=0
    for r in skins:
        sid=i(r.get('skin_id')); source_hero=i(r.get('hero')); model=i(r.get('model')); sk=i(r.get('skill'))
        item=items.get(sid)
        if item is None: raise RuntimeError(f'skin item missing {sid}')
        partner=i(item.get('skin_partner')); item_model=i(item.get('skin_model')); lifetime=i(item.get('skin_last_time'))
        if partner<=0 or item_model<=0: raise RuntimeError(f'invalid skin item metadata {sid}')
        if item_model!=model: raise RuntimeError(f'model mismatch {sid}: {item_model}!={model}')
        if lifetime>0: raise RuntimeError(f'canonical skin_skill row unexpectedly temporary {sid}')
        accepted={partner,source_hero}
        if partner in after: accepted.add(after[partner])
        # If skin_skill names awakened id, accept its source-defined base partner too.
        row={
            'skin_item_id':sid,'skin_partner_id':partner,'skin_skill_hero_id':source_hero,
            'accepted_hero_table_ids':sorted(x for x in accepted if x>0),
            'model_id':model,'skill_id':sk,'rare':i(r.get('rare')),'skin_numb':i(r.get('skin_numb')),
            'item_name':str(item.get('name') or ''),'sell_crystal':i(item.get('crystal')),'stack':i(item.get('stack')),
            'skin_last_time':lifetime,
        }
        out.append(row); girls.add(partner); skill += int(sk>0); cosmetic += int(sk<=0)
    out.sort(key=lambda x:x['skin_item_id'])
    return {
      '_meta':{
        'schema_version':1,'source_resolution':'effective_src64','phase':'PASS145_PHASE_A',
        'source_files':{str(p.relative_to(src64)):sha(p) for p in [skin_p,item_p,bp,hm,sw,sp,nh,sh,pet]},
        'awakening_meta_sha256':sha(data_dir/'awakening_mission_meta.json'),
        'epistemic_note':'catalog rows are source facts; runtime MID60 policy follows source-observed client branches',
      },
      'summary':{'canonical_permanent_skins':len(out),'girls':len(girls),'skill_bearing':skill,'cosmetic_only':cosmetic},
      'skins':out,
      'deferred':{
        'temporary_skin_items':[50001807,50009163],
        'source_inconsistent_skin_item':[50005191],
        'pet_mid60_overload':'source-observed; outside Girl Phase A and remains fail-closed',
      }
    }

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--src64',type=Path,required=True); ap.add_argument('--data-dir',type=Path,required=True); ap.add_argument('--out',type=Path,required=True); a=ap.parse_args()
    a.out.write_text(json.dumps(build(a.src64,a.data_dir),indent=2,sort_keys=True,ensure_ascii=False)+'\n',encoding='utf-8')
if __name__=='__main__': main()
