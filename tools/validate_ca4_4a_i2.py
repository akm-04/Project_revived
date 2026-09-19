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
# I1 immutable authority must remain present.
m=json.loads(need('internal/content/builtin/generated/manifest.json') or '{}')
req(m.get('revision_id')=='1d2eceef60f2b1a3561c0ab311c1f78b361b6984764e6b0ef38484d747ee55e8','I1 content revision drift during I2')
req('PET_EQUIPMENT_CA4_4A' in m.get('enabled_capabilities',[]),'Pet equipment content capability absent')
# Durable I2 migration.
mig=R/'migrations/00024_ca4_4a_pet_equipment_state.sql'; req(mig.exists(),'00024 missing')
if mig.exists():
    s=mig.read_text()
    for n in (1,2,3): req(f'ADD COLUMN equip_{n} bigint NOT NULL DEFAULT 0 CHECK (equip_{n} BETWEEN 0 AND 1)' in s,f'equip_{n} migration invariant missing')
    req('fumo_' not in s.lower(),'Pet Fumo columns leaked into I2 migration')
    req('-- +goose Down' not in s,'00024 violates forward-only law')
lock=json.loads(need('docs/architecture/CUMULATIVE_MIGRATION_LOCK.json') or '{}')
if mig.exists(): req(lock.get('migrations',{}).get(mig.name)==hashlib.sha256(mig.read_bytes()).hexdigest(),'00024 hash not sealed')
req(lock.get('highest_migration')==mig.name,'I2 migration high-water drift')
# Owner aggregate + single cohesive CAS.
need('internal/domain/character/equipment.go','type PetEquipmentSlots [PetEquipmentSlotCount]int64','Pet equipment slot must be a collected bit')
need('internal/domain/character/pet.go','Equipment               PetEquipmentSlots','p.Equipment.Validate()')
sql=need('sql/character/pet.sql','equip_1','equip_2','equip_3','-- name: SavePetState :execrows')
req('SavePetProgression' not in sql,'legacy partial progression SQL remains authoritative')
store=need('internal/adapters/postgres/characterstore/pet.go','func (Store) SavePetStateTx','characterqueries.SavePetState','p.Equipment[0]','p.Equipment[2]')
req('SavePetProgressionTx' in store and 'return s.SavePetStateTx(ctx, t, p, oldVersion)' in store,'legacy progression wrapper does not use cohesive Pet CAS')
proj=need('internal/projection/pet/stock.go','"equips":        []any{p.Equipment[0], p.Equipment[1], p.Equipment[2]}','"fumos":         []any{int64(0), int64(0), int64(0)}')
need('internal/application/characterpet/service.go','SavePetStateTx(context.Context, tx.Tx, character.Pet, int64) error')
# Cumulative-stage aware: enforce the historical I2 endpoint boundary only before I3 exists.
later_i3=(R/'internal/application/characterpet/equipment_service.go').exists()
if not later_i3:
    for root in [R/'internal',R/'cmd']:
        for p in root.rglob('*.go'):
            if p.name.endswith('_test.go'): continue
            s=p.read_text(errors='replace')
            if re.search(r'\bcase\s+(783|792)\s*:',s): errs.append(f'I3/I4 route leaked into I2: {p.relative_to(R)}')
    for token in ['EquipItem(', 'OneKeyEquip(']:
        for p in (R/'internal/application/characterpet').rglob('*.go'):
            if p.name.endswith('_test.go'): continue
            req(token not in p.read_text(errors='replace'),f'I3/I4 gameplay leaked into I2: {p.relative_to(R)} {token}')
# Canonical toolchain/dependency pins remain pristine.
expected={'.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718','go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4','go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}
for rel,w in expected.items(): req(hashlib.sha256((R/rel).read_bytes()).hexdigest()==w,f'canonical pin changed {rel}')
if errs:
    print('CA4-4A-I2 VALIDATION: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA4-4A-I2 VALIDATION: PASS')
print('three binary Pet equipment slots are CharacterPet-owned, persisted/reloaded through one cohesive state CAS; Fumo and MID783/MID792 remain absent')
