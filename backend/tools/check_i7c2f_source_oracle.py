#!/usr/bin/env python3
"""Exact static source/catalog/callback check; no physical-client claim."""
from pathlib import Path
import hashlib,json,sys,zipfile
from generate_builtin_content import compile_archive,canonical_json_bytes,SOURCE_MANIFEST,SOURCE_PREFIX,EXPECTED_SOURCE_ARCHIVE_SHA256
R=Path(__file__).resolve().parents[1];archive=Path(sys.argv[1])/'all-assest-rechecked-1.zip'
assert hashlib.sha256(archive.read_bytes()).hexdigest()==EXPECTED_SOURCE_ARCHIVE_SHA256
expected=compile_archive(archive);checks=0
for n,raw in expected.items():
 assert (R/'internal/content/builtin/generated'/n).read_bytes()==canonical_json_bytes(raw),n;checks+=1
with zipfile.ZipFile(archive)as z:
 source={}
 for p,d,role in SOURCE_MANIFEST:
  if role.startswith('I7C2F_'):
   raw=z.read(SOURCE_PREFIX+p);assert hashlib.sha256(raw).hexdigest()==d;source[p]=raw.decode('utf-8-sig');checks+=1
 for n in ['NormalHero','SuperHero']:
  text=source['app/model/'+n+'.lua'];assert 'twice_awake_stage' in text and 'inscript_items'in text;checks+=1
 callback=source['app/model/Inscription.lua'];assert 'removeItem(var_8_0)'in callback and 'replace_item_id'in callback and 'currency_change'in callback;checks+=1
 window=source['app/windows/InscriptionWindow.lua'];assert 'make_num = 1'in window and 'rebuild_num = 10'in window and 'rebuild_items'in window;checks+=1
 exchange=source['app/windows/ExchangeMaterialWindow.lua'];assert '#arg_3_0.currencyChange'in exchange and 'var_3_1.currency'in exchange and 'var_3_1.change'in exchange;checks+=1
cat=json.loads((R/'internal/content/builtin/generated/inscription_input_catalog.json').read_text());assert len(cat['tables']['items'])==240 and len(cat['tables']['inscription'])==23;checks+=1
resources=json.loads((R/'internal/content/builtin/generated/resource_catalog.json').read_text())['resources']
for k in ['degree_cer','graduate_cer','patent_cer']:
 rows=[r for r in resources if r.get('resource_key')==k];assert len(rows)==1 and rows[0]['class']=='SCALAR_CURRENCY'and rows[0]['settlement_activation']=='ENABLED_R4';checks+=1
print(json.dumps(dict(status='PASS_EXACT_STATIC_SOURCE_CATALOG_AND_CALLBACKS',checks=checks,source_archive_sha256=EXPECTED_SOURCE_ARCHIVE_SHA256,source_files=sorted(source),original_server_math_recovered=False,physical_stock_client=False),indent=2))
