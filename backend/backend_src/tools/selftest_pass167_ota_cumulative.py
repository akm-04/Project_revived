from __future__ import annotations
import hashlib, json, re, zipfile
from collections import defaultdict
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'local_assets/update_manifest.json').read_text())
assert manifest['version']=='1.631.11'
assert manifest['package']=='gxb-local-1.631.11.zip'
assert manifest['enabled'] is True and manifest['silent'] is True
assert len(manifest['files'])==140 and len(set(manifest['files']))==140
hota={'src_32/app/windows/HunqiCombEditorWindow.lua','src_64/app/windows/HunqiCombEditorWindow.lua'}
assert hota.issubset(set(manifest['files']))
assert not any(x.startswith('source_evidence/') for x in manifest['files'])
vol=ROOT/'local_assets/updates/gxb-local-1.631.11.zip.001'
b=vol.read_bytes(); assert len(b)==int(manifest['size']); assert hashlib.md5(b).hexdigest()==manifest['md5']
with zipfile.ZipFile(vol) as z:
    names=z.namelist(); assert len(names)==140 and set(names)==set(manifest['files'])
    g64=z.read('src_64/data/tables/giftbag.lua').decode(); g32=z.read('src_32/data/tables/giftbag.lua').decode()
    c32=z.read('src_32/app/windows/HunqiCombEditorWindow.lua').decode('utf-8-sig')
    c64=z.read('src_64/app/windows/HunqiCombEditorWindow.lua').decode('utf-8-sig')
assert c32==c64 and 'addSpiritColloCount(iter_18_old_1, -1)' in c64
plan=json.loads((ROOT/'data/recharge_eol_skin_plan.json').read_text())
counts=defaultdict(int); expected={}
for row in plan:
    girl=str(row['girl_display_name']).strip(); counts[girl]+=1; expected[int(row['charge_id'])]=f'{girl} {counts[girl]}'
expected.update({97002001:'Adv Elem Pick',97002002:'Elem Pick',97002003:'Adv Elem Pack',97002004:'Elem Pack',97002005:'Adv Lightning',97002006:'Adv Fire',97002007:'Adv Water',97002008:'Lightning',97002009:'Fire',97002010:'Water'})
for text in (g64,g32):
    for cid,short in expected.items():
        m=re.search(rf'\n\s*"{cid}",\n\s*"([^"]*)",\n\s*"([^"]*)",',text); assert m,cid
        assert m.group(1)==short and m.group(2)==short,(cid,m.groups(),short)
assert len(expected)==272
meta=json.loads((ROOT/'data/recharge_eol_product_meta.json').read_text())
assert meta['_meta']['display_ota']=='1.631.10'  # origin of the display-name layer, preserved cumulatively
for row in meta['skin_products']+meta['elemental_products']:
    assert row['display_name']==expected[int(row['charge_id'])]
print('PASS167_OTA_CUMULATIVE: PASS 140 entries; prior 272 display names preserved; HOTA-002 present')
