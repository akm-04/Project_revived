#!/usr/bin/env python3
"""Build effective-src64 Fumo restoration source facts without executing Lua."""
from __future__ import annotations
import argparse, base64, csv, io, json, re, sys
from fractions import Fraction
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_hero_equipment_meta import _flat_table_rows, _split_ints


def main() -> int:
    ap=argparse.ArgumentParser(); ap.add_argument('source_root',type=Path); ap.add_argument('--output',type=Path,required=True); a=ap.parse_args()
    table=a.source_root/'data/tables'; keys,rows=_flat_table_rows(table/'misc.lua'); ki=keys.index('key'); vi=keys.index('value')
    misc={r[ki]:r[vi] for r in rows if len(r)>max(ki,vi)}
    item_ids=_split_ints(misc['enchant_items'])
    wrapped=(table/'item.lua').read_text(encoding='utf-8-sig'); m=re.search(r'return\s+"([A-Za-z0-9+/=]+)"',wrapped,re.S)
    decoded=base64.b64decode(m.group(1)).decode('utf-8'); ir=list(csv.reader(io.StringIO(decoded),delimiter='\t')); h=ir[1]; ix={n:i for i,n in enumerate(h) if n}
    item_by_id={int(r[ix['id']]):r for r in ir[2:] if len(r)>ix['id'] and str(r[ix['id']]).isdigit()}
    materials=[]
    for ordinal,item_id in enumerate(item_ids):
        row=item_by_id[item_id]; value=int(row[ix['moneng']] or 0)
        if value<=0: raise ValueError(f'enchant material {item_id} has no moneng')
        materials.append({'item_id':item_id,'enchant_value':value,'ordinal':ordinal})
    coeff={}
    for quality in range(2,7):
        text=misc[f'enchant_restore_param{quality}']; frac=Fraction(text)
        coeff[str(quality)]=[frac.numerator,frac.denominator]
    payload={
        '_meta':{
            'format':'GXB Pass179 P0 Fumo restoration source facts',
            'source_resolution':'effective_src64',
            'source':['src_64/data/tables/misc.lua: enchant_items + enchant_restore_param2..6','src_64/data/tables/item.lua: enchant material moneng values'],
            'original_server_rounding':'UNKNOWN_CLIENT_SOURCE_CEILING',
        },
        'materials':materials,
        'quality_restore_fraction':coeff,
    }
    a.output.parent.mkdir(parents=True,exist_ok=True); a.output.write_text(json.dumps(payload,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print(f'wrote {a.output}: materials={len(materials)} qualities={len(coeff)}')
    return 0
if __name__=='__main__': raise SystemExit(main())
