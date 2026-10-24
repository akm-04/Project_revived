#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,re,sys
R=Path(__file__).resolve().parents[1]; errs=[]
def req(x,msg):
    if not x: errs.append(msg)
def text(rel):
    p=R/rel
    if not p.exists(): errs.append(f'missing {rel}'); return ''
    return p.read_text(errors='replace')
# A01/A02 immutable topology/content
m=json.loads(text('internal/content/builtin/generated/manifest.json') or '{}')
req(m.get('revision_id')=='1d2eceef60f2b1a3561c0ab311c1f78b361b6984764e6b0ef38484d747ee55e8','content revision drift')
d=m.get('diagnostics',{})
for k,w in [('pet_equipment_positions',2592),('pet_equipment_ordinary_positions',2322),('pet_equipment_special_positions',200),('pet_equipment_zero_positions',70),('pet_equipment_unique_ordinary_items',73),('pet_equipment_unique_special_items',20)]: req(d.get(k)==w,f'{k} drift: {d.get(k)!r}')
# A03-A05 schema/owner/projection
mig=text('migrations/00024_ca4_4a_pet_equipment_state.sql')
for n in (1,2,3): req(f'equip_{n}' in mig and f'CHECK (equip_{n} BETWEEN 0 AND 1)' in mig,f'equip_{n} binary schema invariant missing')
req('fumo_' not in mig.lower(),'Pet Fumo leaked into CA4-4A schema')
pet=text('internal/domain/character/pet.go'); req('Equipment               PetEquipmentSlots' in pet,'Pet aggregate lacks equipment')
store=text('internal/adapters/postgres/characterstore/pet.go'); req('SavePetStateTx' in store and 'SavePetProgressionTx' in store,'cohesive Pet state CAS/wrapper missing')
proj=text('internal/projection/pet/stock.go'); req('p.Equipment[0], p.Equipment[1], p.Equipment[2]' in proj,'durable equips not projected'); req('"fumos":         []any{int64(0), int64(0), int64(0)}' in proj,'Pet Fumo boundary drift')
# A06 neutral I5
neutral=text('internal/application/i5/equipment_resources.go'); req('type TxEquipmentResourceDebiter interface' in neutral and 'HeroEquipmentResourceDebiter' in neutral,'neutral I5 seam missing')
# A07-A21 endpoint/recovery
svc=text('internal/application/characterpet/equipment_service.go')
for token in ['func (s Service) EquipItem','func (s Service) OneKeyEquip','progressionReceiptReplay','receipt.Resolver','SavePetStateTx','ErrPetAwakeningProviderUnavailable','PetUniqueEquipmentCommittedFact','ResultKind: "NO_WORK"']:
    req(token in svc,f'service missing {token!r}')
planner=text('internal/application/characterpet/equipment_planner.go')
for token in ['reservePetEquipmentTarget','qty != used','PetEquipmentOrdinary','MaxEXPShortfall','50001087, 50001088, 50001089']:
    req(token in planner,f'planner missing {token!r}')
wire=text('internal/adapters/stockruntime/pet_dispatcher.go')
req('case 783:' in wire and 'case 792:' in wire,'Pet equipment MIDs not routed')
mid792=wire.split('case 792:',1)[1].split('case 791:',1)[0]
req('"economy_":' not in mid792 and 'Body: map[string]any{}' in mid792,'MID792 response projection drift')
# A24 architecture: CharacterPet application contains no SQL and no CharacterHero gameplay dependency.
for p in (R/'internal/application/characterpet').rglob('*.go'):
    if p.name.endswith('_test.go'): continue
    s=p.read_text(errors='replace')
    req('internal/application/characterhero' not in s,f'Pet->Hero gameplay dependency: {p.relative_to(R)}')
    req(not re.search(r'(?is)\b(?:SELECT|INSERT\s+INTO|UPDATE|DELETE\s+FROM)\s+[a-z_]',s),f'inline SQL in CharacterPet: {p.relative_to(R)}')
# A25 future: only three bits + topology classification; no Fumo owner.
req('PetEquipmentSlots [PetEquipmentSlotCount]int64' in text('internal/domain/character/equipment.go'),'future reset/preserve bit vector absent')
# canonical pins untouched
expected={'.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718','go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4','go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}
for rel,w in expected.items(): req(hashlib.sha256((R/rel).read_bytes()).hexdigest()==w,f'canonical pin changed {rel}')
if errs:
 print('CA4-4A AGGREGATE VALIDATION: FAIL'); [print(' -',e) for e in errs]; sys.exit(1)
print('CA4-4A AGGREGATE VALIDATION: PASS')
print('A01-A25 structural/product invariants present; execution/source/live gates must be evaluated separately')
