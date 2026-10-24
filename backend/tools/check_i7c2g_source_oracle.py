#!/usr/bin/env python3
"""Exact current source and payload reconciliation; static evidence only."""
from pathlib import Path
import json,hashlib,sys,zipfile
from generate_builtin_content import compile_archive,canonical_json_bytes,SOURCE_PREFIX,EXPECTED_SOURCE_ARCHIVE_SHA256
R=Path(__file__).resolve().parents[1];p=Path(sys.argv[1])/'all-assest-rechecked-1.zip';assert hashlib.sha256(p.read_bytes()).hexdigest()==EXPECTED_SOURCE_ARCHIVE_SHA256
expected=compile_archive(p)
for n,v in expected.items():assert (R/'internal/content/builtin/generated'/n).read_bytes()==canonical_json_bytes(v),n
with zipfile.ZipFile(p)as z:
 def source(n):return z.read(SOURCE_PREFIX+n).decode('utf-8-sig')
 model=source('app/model/ElementEquip.lua');assert all(s in model for s in ['ELEMENT_EQUIP','ELEMENT_LEV_UP','ELEMENT_UNLOAD','ELEMENT_DESTORY_ON_PARTNER','ELEMENT_DESTORY_IN_BACKPACK','element_bak_equips','element_bak_levels','splitToNumber'])
 window=source('app/windows/ElementEquipWindow.lua');assert 'getElementBindingEquips'in window and 'var_26_0.itemNum = 1'in window and 'strthMtrs(arg_21_0.equipLV'in window
 normal=source('app/model/NormalHero.lua');super_=source('app/model/SuperHero.lua');assert 'getExclusiveElementAttr'in normal and 'getZhugeBookSkillNum'in normal and '20001453'in normal;assert 'getExclusiveElementAttr'not in super_
 entry=source('app/windows/HeroMainWindow.lua');assert 'selfPlayer:isMaxLev()'in entry and 'getEquipLevel(iter_285_1) < 20'in entry and 'getColor() == xyd.MAX_HERO_COLOR'in entry
 accessor=source('app/common/tables/ElementEquipTable.lua');assert 'parse("element_equip.lua"'in accessor and 'battle_strth'in accessor and 'DECIMAL_BASE'in accessor
 cat=expected['element_input_catalog.json']['tables'];assert len(cat['equipment'])==80 and len(cat['strengthen'])==11 and len(cat['items'])==107
 resources=expected['resource_catalog.json']['resources'];rows={r.get('item_id'):r for r in resources if r.get('class')=='STACK_ITEM'}
 for r in cat['equipment']:assert rows[int(r['item_id'])]['item_type']==21
 assert rows[50001885]['stack_cap']==99 and rows[50001886]['stack_cap']==999
print(json.dumps(dict(status='PASS_EXACT_CURRENT_ELEMENT_SOURCE_AND_ALL30_PAYLOADS',source_archive_sha256=EXPECTED_SOURCE_ARCHIVE_SHA256,equipment_rows=80,strengthen_rows=11,existing_resources=107,source_records=167,physical_client=False,original_server_storage_recovered=False),indent=2))
