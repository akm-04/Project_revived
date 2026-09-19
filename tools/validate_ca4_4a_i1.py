#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,re,sys
R=Path(__file__).resolve().parents[1]; errs=[]
def req(x,msg):
    if not x: errs.append(msg)
def need(rel,*tokens):
    p=R/rel
    if not p.exists(): errs.append(f'missing {rel}'); return ''
    s=p.read_text(errors='replace')
    for t in tokens:
        if t not in s: errs.append(f'{rel}: missing {t!r}')
    return s
m=json.loads(need('internal/content/builtin/generated/manifest.json') or '{}')
req((m.get('compiler_version'),m.get('parser_version'))==('ca4-4a-i1','lua-generated-v10-pet-equipment'),'I1 compiler/parser drift')
req(m.get('revision_id')=='1d2eceef60f2b1a3561c0ab311c1f78b361b6984764e6b0ef38484d747ee55e8','I1 content revision drift')
req('PET_EQUIPMENT_CA4_4A' in m.get('enabled_capabilities',[]),'I1 capability absent')
d=m.get('diagnostics',{})
for k,w in [('pet_equipment_positions',2592),('pet_equipment_ordinary_positions',2322),('pet_equipment_special_positions',200),('pet_equipment_zero_positions',70),('pet_equipment_unique_ordinary_items',73),('pet_equipment_unique_special_items',20)]: req(d.get(k)==w,f'{k}={d.get(k)!r} want {w}')
cat=json.loads(need('internal/content/builtin/generated/pet_equipment_catalog.json') or '{}')
req(len(cat.get('positions',[]))==2592,'Pet equipment artifact count drift')
mig=R/'migrations/00023_ca4_4a_pet_equipment_content.sql'; req(mig.exists(),'00023 missing')
if mig.exists():
    s=mig.read_text(); req('CREATE TABLE gxb_content_pet_equipment' in s,'00023 missing Pet equipment content table'); req('ALTER TABLE player_pets' not in s and 'CREATE TABLE player_pets' not in s,'I2 durable Pet state leaked into I1 migration'); req('-- +goose Down' not in s,'00023 violates forward-only law')
lock=json.loads(need('docs/architecture/CUMULATIVE_MIGRATION_LOCK.json') or '{}')
if mig.exists(): req(lock.get('migrations',{}).get(mig.name)==hashlib.sha256(mig.read_bytes()).hexdigest(),'00023 hash not sealed in cumulative lock')
req(str(lock.get('highest_migration','')) >= mig.name,'I1 migration high-water predates 00023')
own=json.loads(need('docs/architecture/CANONICAL_TABLE_OWNERSHIP.json') or '{}').get('tables',{})
row=own.get('gxb_content_pet_equipment'); req(bool(row) and row.get('owner')=='content-registry' and row.get('migration')==str(mig.relative_to(R)),'Pet equipment content ownership drift')
need('internal/domain/character/equipment.go','type PetEquipmentPosition struct','type EquipmentCompatibilityExpThreshold struct')
need('internal/adapters/postgres/contentstore/pet_equipment.go','PET_EQUIPMENT_CA4_4A','PetEquipmentPositionTx','EquipmentCompatibilityExpPolicyTx')
need('internal/application/i5/equipment_resources.go','type TxEquipmentResourceDebiter interface','PrepareEquipmentResourcesTx','ApplyEquipmentResourceDebitTx')
# Cumulative-stage aware: when later CA4-4A stages are absent, enforce the historical I1 boundary.
later_i2=(R/'migrations/00024_ca4_4a_pet_equipment_state.sql').exists()
later_i3=(R/'internal/application/characterpet/equipment_service.go').exists()
if not later_i2:
    for rel in ['migrations/00023_ca4_4a_pet_equipment_content.sql','sql/character/pet.sql','internal/domain/character/pet.go']:
        s=need(rel)
        for token in ['equip_1','equip_2','equip_3']:
            req(token not in s,f'I2 durable equipment leaked into I1 {rel}')
if not later_i3:
    for root in [R/'internal',R/'cmd']:
        for p in root.rglob('*.go'):
            if p.name.endswith('_test.go'): continue
            s=p.read_text(errors='replace')
            if re.search(r'\bcase\s+(783|792)\s*:',s): errs.append(f'I3/I4 route leaked into I1: {p.relative_to(R)}')
expected={'.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718','go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4','go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}
for rel,w in expected.items(): req(hashlib.sha256((R/rel).read_bytes()).hexdigest()==w,f'canonical pin changed {rel}')
if errs:
    print('CA4-4A-I1 VALIDATION: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA4-4A-I1 VALIDATION: PASS')
print('immutable Pet equipment topology + neutral partnerExp read + neutral I5 Prepare/Apply seam are present; durable Pet equipment and MID783/MID792 remain absent')
