#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, os, sys, zipfile
R=Path(__file__).resolve().parents[1]
errs=[]
def req(x,msg):
    if not x: errs.append(msg)
def sha(b): return hashlib.sha256(b).hexdigest()
archive=Path(os.environ.get('GXB_R4A_SOURCE_ARCHIVE',''))
req(archive.is_file(),'exact source archive missing; set GXB_R4A_SOURCE_ARCHIVE')
expected={
 'app-assets/output/assets/src_64/data/tables/pet.lua':'bc974045ec92fd7c0ebb2655d635d1b057eee7f74a871cfa2316b511ad55986e',
 'app-assets/output/assets/src_64/data/tables/item.lua':'59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc',
 'app-assets/output/assets/src_64/data/tables/partner_exp.lua':'55f3808decc768a40343aaed2d0c85a5beda34926fbb559970296d140871b39b',
}
if archive.is_file():
    with zipfile.ZipFile(archive) as z:
        names=set(z.namelist())
        for n,w in expected.items():
            req(n in names,f'missing current src_64 member {n}')
            if n in names: req(sha(z.read(n))==w,f'source hash drift {n}: {sha(z.read(n))}')
manifest=json.loads((R/'internal/content/builtin/generated/manifest.json').read_text())
req(manifest.get('revision_id')=='1d2eceef60f2b1a3561c0ab311c1f78b361b6984764e6b0ef38484d747ee55e8','I1 content revision drift')
req((manifest.get('compiler_version'),manifest.get('parser_version'))==('ca4-4a-i1','lua-generated-v10-pet-equipment'),'I1 compiler/parser drift')
req('PET_EQUIPMENT_CA4_4A' in manifest.get('enabled_capabilities',[]),'Pet equipment capability absent')
source_by_path={x['path']:x['sha256'] for x in manifest.get('sources',[])}
for rel,w in [('data/tables/pet.lua',expected['app-assets/output/assets/src_64/data/tables/pet.lua']),('data/tables/item.lua',expected['app-assets/output/assets/src_64/data/tables/item.lua']),('data/tables/partner_exp.lua',expected['app-assets/output/assets/src_64/data/tables/partner_exp.lua'])]:
    req(source_by_path.get(rel)==w,f'manifest source identity drift {rel}')
cat=json.loads((R/'internal/content/builtin/generated/pet_equipment_catalog.json').read_text())
pos=cat.get('positions',[])
counts={'EMPTY':0,'ORDINARY':0,'AWAKENING':0}; ids={'ORDINARY':set(),'AWAKENING':set()}; per={}
for p in pos:
    c=p.get('classification'); counts[c]=counts.get(c,0)+1
    if c in ids and p.get('item_id',0): ids[c].add(p['item_id'])
    per.setdefault(p['pet_table_id'],[]).append((p['color'],p['slot'],p['item_id'],c))
req(len(pos)==2592,f'position count {len(pos)}')
req(counts=={'EMPTY':70,'ORDINARY':2322,'AWAKENING':200},f'classification counts {counts}')
req((len(ids['ORDINARY']),len(ids['AWAKENING']))==(73,20),f'unique mapped IDs {(len(ids["ORDINARY"]),len(ids["AWAKENING"]))}')
req(len(per)==54 and all(len(v)==48 for v in per.values()),'54x48 form topology drift')
for p in pos:
    if p['classification']=='AWAKENING': req(p['slot']==1 and 12<=p['color']<=16,'Awakening position escaped high-color slot1')
    if p['classification']=='EMPTY': req(p['slot']==1 and 12<=p['color']<=16,'zero position escaped high-color slot1')
# Neutral compatibility curve must read the same immutable hero-exp authority; never duplicate partnerExp into Pet state.
sql=(R/'sql/content/content.sql').read_text()
req('ReadEquipmentCompatibilityExpPolicy' in sql and 'FROM gxb_content_hero_exp' in sql,'neutral compatibility EXP read does not use canonical hero-exp content table')
for forbidden in ['gxb_content_pet_partner_exp','pet_partner_exp','pet_compat_exp']:
    req(forbidden not in sql,f'duplicated compatibility curve authority {forbidden}')
if errs:
    print('CA4-4A-I1 SOURCE ORACLE CHECK: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA4-4A-I1 SOURCE ORACLE CHECK: PASS')
print('exact current src_64 pet/item/partner_exp identities + generated 2592-position Pet topology + neutral shared partnerExp authority are coherent')
