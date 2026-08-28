#!/usr/bin/env python3
"""Build Pass73 source-derived advanced Hero/Girls progression metadata.

Parses supplied effective src_64 without executing Lua.  Deterministic client-
visible contracts only: SuperHero post-5 evolution/equipment, Fumo materials,
Element Equipment strengthen/decompose tables, and deterministic Inscription
insert/remove metadata.  Hidden server-side random generation is deliberately
not modeled here.
"""
from __future__ import annotations
import argparse, base64, csv, io, json, re, sys
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_hero_equipment_meta import (_decode_wrapped, _extract_table, _string_values, _split_ints, _int, _flat_table_rows)


def _flat(path: Path) -> list[dict[str,str]]:
    keys, rows = _flat_table_rows(path)
    out=[]
    for row in rows:
        if len(row)<len(keys): row=row+[""]*(len(keys)-len(row))
        out.append({k:row[i] if i<len(row) else "" for i,k in enumerate(keys) if k})
    return out


def _partner_stones(path: Path) -> dict[str,dict[str,Any]]:
    decoded=_decode_wrapped(path)
    km=re.search(r"table\.keys\s*=\s*\{(.*?)\}\s*table\.rows",decoded,re.S)
    if not km: raise ValueError('partner key map not found')
    keys={n:int(i)-1 for n,i in re.findall(r"(\w+)\s*=\s*(\d+)",km.group(1))}
    for k in ('id','stone_id','stone_ticket'):
        if k not in keys: raise ValueError(f'partner missing {k}')
    out={}
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{",decoded):
        vals=_string_values(_extract_table(decoded,m.start()))
        def val(k):
            idx=keys[k]; return vals[idx] if idx<len(vals) else ''
        tid=_int(val('id'),0)
        if tid<=0: continue
        out[str(tid)]={'table_id':tid,'stone_id':_int(val('stone_id'),0),'stone_ticket':_int(val('stone_ticket'),0)}
    return out


def _super_partners(path: Path) -> dict[str,dict[str,Any]]:
    decoded=_decode_wrapped(path)
    km=re.search(r"table\.keys\s*=\s*\{(.*?)\}\s*table\.rows",decoded,re.S)
    if not km: raise ValueError('super_partner key map not found')
    keys={n:int(i)-1 for n,i in re.findall(r"(\w+)\s*=\s*(\d+)",km.group(1))}
    required=['id','equipment','stone_id','stone_ticket','ini_star']
    for k in required:
        if k not in keys: raise ValueError(f'super_partner missing {k}')
    out={}
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{",decoded):
        vals=_string_values(_extract_table(decoded,m.start()))
        def val(k):
            idx=keys[k]; return vals[idx] if idx<len(vals) else ''
        tid=_int(val('id'),0)
        if tid<=0: continue
        out[str(tid)]={
            'table_id':tid,
            'stone_id':_int(val('stone_id'),0),
            'stone_ticket':_int(val('stone_ticket'),0),
            'ini_star':_int(val('ini_star'),1),
            'equipment':_split_ints(val('equipment')),
        }
    return out


def _item_rows(path: Path) -> dict[str,dict[str,Any]]:
    decoded=_decode_wrapped(path)
    rows=list(csv.reader(io.StringIO(decoded),delimiter='\t'))
    h=rows[1]; ix={n:i for i,n in enumerate(h) if n}
    wanted=['id','type','sub_type','fumo','fumo_mana','moneng','partner_id','inscript_id','inscript_suit_id']
    for k in wanted:
        if k not in ix: raise ValueError(f'item.lua missing {k}')
    out={}
    for r in rows[2:]:
        if len(r)<len(h): r=r+['']*(len(h)-len(r))
        iid=_int(r[ix['id']],0)
        if iid<=0: continue
        fumo=_split_ints(r[ix['fumo']])
        row={
            'id':iid,
            'type':_int(r[ix['type']],0),
            'sub_type':_int(r[ix['sub_type']],0),
            'fumo_thresholds':fumo,
            'fumo_mana':max(0,_int(r[ix['fumo_mana']],0)),
            'moneng':max(0,_int(r[ix['moneng']],0)),
            'partner_id':_int(r[ix['partner_id']],0),
            'inscript_id':_int(r[ix['inscript_id']],0),
            'inscript_suit_id':_int(r[ix['inscript_suit_id']],0),
        }
        if row['moneng']>0 or row['fumo_thresholds'] or row['fumo_mana']>0 or row['inscript_id']>0:
            out[str(iid)]=row
    return out


def _misc(path:Path)->dict[str,str]:
    out={}
    for r in _flat(path):
        if r.get('key'): out[r['key']]=r.get('value','')
    return out

def _inscription_exchange(path:Path, material_ids:list[int])->list[dict[str,int]]:
    decoded=_decode_wrapped(path); rows=list(csv.reader(io.StringIO(decoded),delimiter='\t')); h=rows[1]; ix={n:i for i,n in enumerate(h) if n}
    for k in ('id','economic_value'):
        if k not in ix: raise ValueError(f'item.lua missing {k}')
    wanted=set(material_ids); found={}
    for r in rows[2:]:
        if len(r)<len(h): r=r+['']*(len(h)-len(r))
        iid=_int(r[ix['id']],0)
        if iid not in wanted: continue
        pair=_split_ints(r[ix['economic_value']])
        if len(pair)!=2 or pair[0]<=0 or pair[1]<=0: raise ValueError(f'inscription exchange material {iid} lacks economic_value')
        found[iid]={'item_id':iid,'currency_id':pair[0],'per_item':pair[1]}
    if set(found)!=wanted: raise ValueError(f'inscription exchange material source incomplete: {sorted(wanted-set(found))}')
    return [found[iid] for iid in material_ids]

def main()->int:
    ap=argparse.ArgumentParser(); ap.add_argument('source_root',type=Path); ap.add_argument('--output',type=Path,required=True)
    a=ap.parse_args(); t=a.source_root/'data/tables'
    partner_stones=_partner_stones(t/'partner.lua')
    super_partners=_super_partners(t/'super_partner.lua')
    super_stars={}
    for r in _flat(t/'super_partner_star.lua'):
        star=_int(r.get('star'),0)
        if 1<=star<=8: # live client cap, rows9/10 are dormant drift
            super_stars[str(star)]={
                'star':star,'mana_cost':max(0,_int(r.get('mana_cost'),0)),
                'stone_cost':max(0,_int(r.get('stone_cost'),0)),
                'need_hero_num':max(0,_int(r.get('need_hero_num'),0)),
                'equipment_limit':max(0,_int(r.get('equipment_limit'),0)),
            }
    super_enhance={}
    for r in _flat(t/'super_equip_enhance.lua'):
        i=_int(r.get('id'),0)
        if i>0: super_enhance[str(i)]={'id':i,'need_star':_int(r.get('need_star'),0),'need_num':_int(r.get('need_num'),0)}
    items=_item_rows(t/'item.lua')
    element={}
    element_item_to_id={}
    for r in _flat(t/'element_equip.lua'):
        eid=_int(r.get('id'),0); iid=_int(r.get('item_id'),0)
        if eid<=0 or iid<=0: continue
        row={'id':eid,'item_id':iid,'element':_int(r.get('element'),0),'equip_type':_int(r.get('equip_type'),0),'partner_id':_int(r.get('partner_id'),0),'is_hide':_int(r.get('is_hide'),0)}
        element[str(eid)]=row; element_item_to_id[str(iid)]=eid
    element_strength={}
    for r in _flat(t/'element_strth.lua'):
        rank=_int(r.get('strth_ranks'),-1)
        if rank<0: continue
        row={'rank':rank}
        for typ in (1,2,3):
            row[f'strth_mtrs{typ}']=_split_ints(r.get(f'strth_mtrs{typ}'))
            row[f'strth_nums{typ}']=_split_ints(r.get(f'strth_nums{typ}'))
            row[f'dec_mtrs{typ}']=_split_ints(r.get(f'dec_mtrs{typ}'))
            row[f'dec_nums{typ}']=_split_ints(r.get(f'dec_nums{typ}'))
        element_strength[str(rank)]=row
    inscriptions={}; inscription_item_to_type={}
    for r in _flat(t/'inscription.lua'):
        iid=_int(r.get('id'),0)
        if iid<=0: continue
        item_ids=_split_ints(r.get('item_id'))
        row={'id':iid,'item_ids':item_ids,'level':_int(r.get('level'),0),'item_type':_int(r.get('item_type'),0),'item_pos':_int(r.get('item_pos'),0),'special':_int(r.get('special'),0),'resolve_material':_int(r.get('resolve_material'),0),'resolve_num':_int(r.get('resolve_num'),0),'change_gold':_int(r.get('change_gold'),0),'change_crystal':_int(r.get('change_crystal'),0)}
        inscriptions[str(iid)]=row
        for concrete in item_ids: inscription_item_to_type[str(concrete)]=iid
    # Pass98: inscription.lua.item_id omits 14 source-valid Honor variants, while
    # effective item.lua carries their authoritative inscript_id.  Use that
    # per-item relationship as the complete concrete-item mapping and require
    # every referenced inscription type to exist in inscription.lua.
    for concrete, item_row in items.items():
        mapped=_int(item_row.get('inscript_id'),0)
        if mapped<=0:
            continue
        if str(mapped) not in inscriptions:
            raise ValueError(f'item.lua inscription item {concrete} references unknown inscription {mapped}')
        inscription_item_to_type[str(concrete)]=mapped
    misc=_misc(t/'misc.lua')
    inscript_cost_items=_split_ints(misc.get('inscript_cost_items',''))
    inscription_exchange=_inscription_exchange(t/'item.lua',inscript_cost_items)
    stone_evolution={}
    for r in _flat(t/'stone_evolution.lua'):
        stage=_int(r.get('id'),0)
        if stage>0:
            stone_evolution[str(stage)]={
                'stage':stage,'level':_int(r.get('level'),0),'star':_int(r.get('star'),0),
                'attrs':_split_ints(r.get('attrs')),'attrs_num':_split_ints(r.get('attrs_num')),
                'limit_num':max(0,_int(r.get('limit_num'),0)),
            }
    stone_tickets={}
    for r in _flat(t/'stone_ticket.lua'):
        typ=_int(r.get('id'),0)
        if typ>0: stone_tickets[str(typ)]=_split_ints(r.get('stone_ticket_items'))
    advanced_test_items=set()
    for row in partner_stones.values(): advanced_test_items.add(row['stone_id'])
    for vals in stone_tickets.values(): advanced_test_items.update(vals)
    for sp in super_partners.values(): advanced_test_items.update(sp['equipment']); advanced_test_items.add(sp['stone_id'])
    for k,r in items.items():
        if r['moneng']>0 or r['inscript_id']>0: advanced_test_items.add(int(k))
    for r in element.values(): advanced_test_items.add(r['item_id'])
    for r in element_strength.values():
        for typ in (1,2,3): advanced_test_items.update(r[f'strth_mtrs{typ}']); advanced_test_items.update(r[f'dec_mtrs{typ}'])
    advanced_test_items.discard(0)
    payload={
      '_meta':{'format':'GXB Pass73/Pass98 source-derived advanced Hero/Girls progression metadata','source_authority':'effective src_64','hidden_randomness':'excluded / PRIVATE_SERVER_POLICY boundary','pass98_inscription_mapping':'item.lua.inscript_id completes concrete mapping; inscription.lua owns resolve policy'},
      'live_super_max_star':8,
      'partner_stones':partner_stones,'super_partners':super_partners,'super_stars':super_stars,'super_equip_enhance':super_enhance,
      'stone_evolution':stone_evolution,'stone_tickets':stone_tickets,
      'advanced_items':items,
      'element_equips':element,'element_item_to_id':element_item_to_id,'element_strength':element_strength,
      'element_max_rank':max(0,_int(misc.get('element_equip_str_max_rank'),10)),
      'inscriptions':inscriptions,'inscription_item_to_type':inscription_item_to_type,
      'remove_inscription_crystal':max(0,_int(misc.get('remove_inscript_cost'),20)),
      'inscription_exchange_materials':inscription_exchange,
      'advanced_test_item_ids':sorted(advanced_test_items),
    }
    a.output.parent.mkdir(parents=True,exist_ok=True); a.output.write_text(json.dumps(payload,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print(json.dumps({'super_partners':len(super_partners),'advanced_items':len(items),'element_equips':len(element),'inscriptions':len(inscriptions),'test_items':len(advanced_test_items)},sort_keys=True))
    return 0
if __name__=='__main__': raise SystemExit(main())
