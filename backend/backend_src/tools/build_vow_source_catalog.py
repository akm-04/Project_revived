#!/usr/bin/env python3
"""Build source-derived Vow/Super Partner acquisition catalog from effective src_64."""
from __future__ import annotations
import argparse, json, re, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_hero_equipment_meta import _decode_wrapped, _extract_table, _string_values, _split_ints, _int, _flat_table_rows


def _super_rows(path: Path):
    decoded=_decode_wrapped(path)
    km=re.search(r"table\.keys\s*=\s*\{(.*?)\}\s*table\.rows",decoded,re.S)
    if not km: raise ValueError('super_partner key map not found')
    keys={n:int(i)-1 for n,i in re.findall(r"(\w+)\s*=\s*(\d+)",km.group(1))}
    required=['id','name','material_hero','stone_id','ini_star','equipment','stone_campaign']
    for k in required:
        if k not in keys: raise ValueError(f'super_partner missing {k}')
    out={}
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{",decoded):
        vals=_string_values(_extract_table(decoded,m.start()))
        def val(k):
            idx=keys[k]; return vals[idx] if idx<len(vals) else ''
        tid=_int(val('id'),0)
        if tid<=0: continue
        mats=_split_ints(val('material_hero'))
        equips=_split_ints(val('equipment'))
        if len(mats)!=5: raise ValueError(f'Vow {tid} material_hero expected 5, got {mats}')
        if len(equips)!=6: raise ValueError(f'Vow {tid} equipment expected 6, got {equips}')
        out[str(tid)]={
            'table_id':tid,'name':val('name'),'material_hero':mats,
            'scroll_id':_int(val('stone_id'),0),'ini_star':_int(val('ini_star'),1),
            'equipment':equips,'stone_campaign':_int(val('stone_campaign'),0),
        }
    return out


def _misc(path: Path):
    keys, rows=_flat_table_rows(path)
    ix={k:i for i,k in enumerate(keys)}
    out={}
    for row in rows:
        if len(row)<len(keys): row=row+['']*(len(keys)-len(row))
        key=row[ix.get('key',-1)] if 'key' in ix else ''
        value=row[ix.get('value',-1)] if 'value' in ix else ''
        if key: out[key]=value
    return out


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('source_root',type=Path); ap.add_argument('--output',type=Path,required=True)
    a=ap.parse_args(); t=a.source_root/'data/tables'
    rows=_super_rows(t/'super_partner.lua'); misc=_misc(t/'misc.lua')
    payload={
      '_meta':{'schema_version':1,'format':'GXB Vow/Super Partner acquisition source catalog','source_authority':'effective src_64','summon_mid':305,'exchange_mid':306},
      'essence_item_id':_int(misc.get('taitan_stone_item_id'),0),
      'essence_exchange_cost':_int(misc.get('taitan_exchange_super_hero'),0),
      'vows':rows,
    }
    if len(rows)!=14: raise ValueError(f'expected 14 Vows, got {len(rows)}')
    if payload['essence_item_id']!=50001666 or payload['essence_exchange_cost']!=100:
        raise ValueError(f"Vow essence constants drift: {payload['essence_item_id']}/{payload['essence_exchange_cost']}")
    a.output.parent.mkdir(parents=True,exist_ok=True)
    a.output.write_text(json.dumps(payload,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print(json.dumps({'vows':len(rows),'essence_item_id':payload['essence_item_id'],'exchange_cost':payload['essence_exchange_cost']},sort_keys=True))
if __name__=='__main__': main()
