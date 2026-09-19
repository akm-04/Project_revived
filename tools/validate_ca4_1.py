#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
import hashlib, json, sys
ROOT=Path(__file__).resolve().parents[1]
errs=[]
def req(cond,msg):
    if not cond: errs.append(msg)

def text(p): return (ROOT/p).read_text()
manifest=json.loads(text('internal/content/builtin/generated/manifest.json'))
req('EQUIPMENT_PRIMITIVES_CA4' in manifest.get('enabled_capabilities',[]),'CA4-1 content capability absent')
req((manifest.get('compiler_version'),manifest.get('parser_version')) in {('ca4-1','lua-generated-v6-equipment-primitives'),('ca4-2a','lua-generated-v7-hero-equipment'),('ca4-4a-i1','lua-generated-v10-pet-equipment'),('ca4-4b-i1','lua-generated-v11-pet-restoration'),('ca4-5-i1','lua-generated-v12-super-equipment'), ('ca6-2-practice-foundation','lua-generated-v13-practice')},'CA4-1 cumulative compiler identity drift')
cat=json.loads(text('internal/content/builtin/generated/equipment_primitives_catalog.json'))
req(len(cat.get('items',[]))==1176,'CA4-1 primitive count drift')
req(len(cat.get('recipe_edges',[]))==1934,'CA4-1 recipe edge count drift')
req(all(int(x['ordinal'])>0 for x in cat.get('recipe_edges',[])),'CA4-1 recipe ordinal must be 1-based positive')

mig=ROOT/'migrations/00019_ca4_equipment_primitives.sql'
req(mig.exists(),'migration 00019 missing')
lock=json.loads(text('docs/architecture/CUMULATIVE_MIGRATION_LOCK.json'))
req(str(lock.get('highest_migration','')) >= mig.name,'cumulative migration high-water below CA4-1')
req(lock.get('migrations',{}).get(mig.name)==hashlib.sha256(mig.read_bytes()).hexdigest(),'migration 00019 hash not sealed')
own=json.loads(text('docs/architecture/CANONICAL_TABLE_OWNERSHIP.json')).get('tables',{})
for table in ('gxb_content_equipment_primitives','gxb_content_equipment_recipe_edges'):
    ent=own.get(table)
    req(bool(ent),f'ownership missing {table}')
    if ent:
        req(ent.get('owner')=='content-registry',f'{table} not content-registry owned')
        req(ent.get('migration')=='migrations/00019_ca4_equipment_primitives.sql',f'{table} migration drift')

mx=text('internal/application/i5/material_exchange.go')
for marker in ('PrepareMaterialExchangeTx','ApplyMaterialExchangeTx','canonicalGrantLockRequirements','ErrMaterialExchangeResourceCollision','ErrMaterialExchangeGrantAlreadySettled'):
    req(marker in mx,f'I5 combined material exchange missing {marker}')
contracts=text('internal/application/characterasset/contracts.go')
for marker in ('PlayerProgressionMaxHeroColorProvider','RestorationModifier','HeroPromotionRestorationSource','PetPromotionRestorationSource','RawEquipmentState'):
    req(marker in contracts,f'CA4 shared contract missing {marker}')
for forbidden in ('MID54','MID62','MID58','MID51','MID57','MID783','MID792','MID785','MID790','MID304','CreateSpirit','UpgradeSpirit','Horcrux'):
    req(forbidden not in contracts,f'future-family/lifecycle behavior leaked into CA4-1 contracts: {forbidden}')

if errs:
    print('CA4-1 VALIDATION: FAIL')
    for e in errs: print(' -',e)
    raise SystemExit(1)
print('CA4-1 VALIDATION: PASS')
print('shared content/I5/Character contracts are present; migration/ownership sealed; later CA4 family mechanics remain absent')
