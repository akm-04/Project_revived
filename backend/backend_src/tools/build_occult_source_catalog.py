#!/usr/bin/env python3
"""Build Pass211 source-only Occult/Sorcery War catalog from effective src_64."""
from __future__ import annotations
import argparse, hashlib, json, re
from pathlib import Path

ASSET_SHA256 = "89f0f830508b92e5fff6ad53c6a9dae961a14042dbfdf5649008efb8353f5608"

def sha(path: Path) -> str:
    h=hashlib.sha256();
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024), b''): h.update(chunk)
    return h.hexdigest()

def misc_value(text: str, key: str) -> str:
    m=re.search(r'\{\s*"'+re.escape(key)+r'",\s*"([^"]+)"', text, re.S)
    if not m: raise SystemExit(f"missing misc key {key}")
    return m.group(1)

def main() -> None:
    ap=argparse.ArgumentParser(); ap.add_argument('--src64',type=Path,required=True); ap.add_argument('--data-dir',type=Path,required=True)
    ns=ap.parse_args(); src=ns.src64; data=ns.data_dir
    chapter_file=src/'data/tables/creats_chapter_select.lua'; misc_file=src/'data/tables/misc.lua'
    occult_model=src/'app/model/Occult.lua'; occult_window=src/'app/windows/OccultWindow.lua'; mid_file=src/'app/common/network/mid.lua'
    chapter_text=chapter_file.read_text(encoding='utf-8-sig'); misc_text=misc_file.read_text(encoding='utf-8-sig')
    blocks=re.findall(r'\t\t\{\n(.*?)\n\t\t\}', chapter_text, re.S)
    chapters=[]; mission_map={}
    for block in blocks:
        vals=re.findall(r'"([^"]*)"', block)
        if len(vals) != 17: continue
        cid=int(vals[0]); mids=[] if vals[9]=='0' else [int(x) for x in vals[9].split('|')]
        items=[] if vals[10]=='0' else [int(x) for x in vals[10].split('|')]
        nums=[] if vals[11]=='0' else [int(x) for x in vals[11].split('|')]
        if not (len(mids)==len(items)==len(nums)): raise SystemExit(f"chapter {cid} awake vector mismatch")
        row={'chapter_id':cid,'table_id':int(vals[1]),'chapter_name':vals[3],
             'awakening_mission_ids':mids,'awakening_items':items,'awakening_nums_raw':nums}
        chapters.append(row)
        for mid,item,num in zip(mids,items,nums):
            if mid in mission_map: raise SystemExit(f'duplicate occult mission {mid}')
            mission_map[mid]={'mission_id':mid,'chapter_id':cid,'chapter_table_id':int(vals[1]),'fragment_item':item,'awaken_num_raw':num}
    if len(chapters)!=6 or len(mission_map)!=22: raise SystemExit(f"unexpected chapter/route census {len(chapters)}/{len(mission_map)}")
    awakening=json.loads((data/'awakening_source_catalog.json').read_text(encoding='utf-8'))
    expected={int(k):v['occult'] for k,v in awakening['ordinary_stage1_routes'].items() if v.get('route_class')=='OCCULT'}
    if len(expected)!=22: raise SystemExit('awakening catalog occult census drift')
    for mid,row in mission_map.items():
        er=expected.get(mid) or {}
        for key in ('chapter_id','chapter_table_id','fragment_item','awaken_num_raw'):
            if int(er.get(key,0) or 0)!=int(row[key]): raise SystemExit(f'awakening cross-ref drift {mid}/{key}')
    source_files=[occult_model,occult_window,chapter_file,misc_file,mid_file]
    raw={
      'schema_version':1,
      '_meta':{
        'schema_version':1,'source_resolution':'effective_src64','epistemic_class':'SOURCE_FACT_ONLY',
        'source_archive_sha256':ASSET_SHA256,'effective_src64_file_count':4370,
        'source_files':{str(p.relative_to(src)):sha(p) for p in source_files},
        'notes':['awaken_nums_raw=30 and creats_sweep_reward_rate=0.6 are preserved source facts only; neither is treated as recovered server fragment quantity.']
      },
      'constants':{
        'ticket_energy_threshold':int(float(misc_value(misc_text,'creats_ticket_get'))),
        'ticket_cap':int(float(misc_value(misc_text,'creats_ticket_max'))),
        'sweep_reward_rate_raw':float(misc_value(misc_text,'creats_sweep_reward_rate')),
        'dispatch_hero_limit':int(float(misc_value(misc_text,'creats_dispatch_hero_limit'))),
      },
      'counts':{'chapters':len(chapters),'ordinary_awakening_routes':len(mission_map)},
      'chapters':chapters,
      'awakening_routes':{str(k):v for k,v in sorted(mission_map.items())},
    }
    out=data/'occult_source_catalog.json'; out.write_text(json.dumps(raw,indent=2,sort_keys=True,ensure_ascii=False)+'\n',encoding='utf-8')
    print(out); print(json.dumps(raw['constants'],sort_keys=True)); print(raw['counts'])
if __name__=='__main__': main()
