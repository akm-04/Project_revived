from __future__ import annotations
import json, re, zipfile, hashlib
from pathlib import Path
from collections import defaultdict
ROOT=Path(__file__).resolve().parents[1]
manifest=json.loads((ROOT/'local_assets/update_manifest.json').read_text())
assert manifest['version']=='1.631.10'
assert manifest['package']=='gxb-local-1.631.10.zip'
vol=ROOT/'local_assets/updates/gxb-local-1.631.10.zip.001'
b=vol.read_bytes()
assert len(b)==int(manifest['size'])
assert hashlib.md5(b).hexdigest()==manifest['md5']
with zipfile.ZipFile(vol) as z:
    names=z.namelist(); assert len(names)==138 and len(names)==len(set(names))
    g64=z.read('src_64/data/tables/giftbag.lua').decode()
    g32=z.read('src_32/data/tables/giftbag.lua').decode()
plan=json.loads((ROOT/'data/recharge_eol_skin_plan.json').read_text())
counts=defaultdict(int); expected={}
for row in plan:
    girl=str(row['girl_display_name']).strip(); counts[girl]+=1
    expected[int(row['charge_id'])]=f'{girl} {counts[girl]}'
expected.update({97002001:'Adv Elem Pick',97002002:'Elem Pick',97002003:'Adv Elem Pack',97002004:'Elem Pack',97002005:'Adv Lightning',97002006:'Adv Fire',97002007:'Adv Water',97002008:'Lightning',97002009:'Fire',97002010:'Water'})
for text in (g64,g32):
    for cid,short in expected.items():
        pat=re.compile(rf'\n\s*"{cid}",\n\s*"([^"]*)",\n\s*"([^"]*)",')
        m=pat.search(text); assert m, cid
        assert m.group(1)==short and m.group(2)==short,(cid,m.groups(),short)
assert len(expected)==272
meta=json.loads((ROOT/'data/recharge_eol_product_meta.json').read_text())
assert meta['_meta']['display_ota']=='1.631.10'
assert len(meta['skin_products'])==262 and len(meta['elemental_products'])==10
for row in meta['skin_products']+meta['elemental_products']:
    assert row['display_name']==expected[int(row['charge_id'])]
print('PASS154_DISPLAY_POLISH: PASS 272/272 names; OTA entries=138')
