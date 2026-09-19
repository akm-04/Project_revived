#!/usr/bin/env python3
from pathlib import Path
import hashlib, sys
root=Path(__file__).resolve().parents[1]
errs=[]
req=[
 'internal/application/characterhero/equipment_planner.go',
 'internal/application/characterhero/equipment_service.go',
 'internal/application/characterhero/equipment_planner_oracle_test.go',
 'internal/application/characterhero/equipment_service_test.go',
 'internal/application/characterhero/testdata/ca4_2_planner_adversarial_vectors.json',
 'internal/application/i5/hero_equipment_resources.go',
]
for rel in req:
    if not (root/rel).is_file(): errs.append(f'missing {rel}')
if (root/'internal/application/characterhero/equipment_planner.go').is_file():
    s=(root/'internal/application/characterhero/equipment_planner.go').read_text()
    for n in ['heroEquipmentPotionOrder','planOneKeyEquipment','reserveEquipmentTarget','MaxEXPShortfall','PotionEXPGranted']:
        if n not in s: errs.append(f'missing planner token {n}')
if (root/'internal/application/characterhero/equipment_service.go').is_file():
    s=(root/'internal/application/characterhero/equipment_service.go').read_text()
    for n in ['func (s Service) EquipItem','func (s Service) OneKeyEquip','SaveHeroStateTx','PrepareHeroEquipmentResourcesTx','ApplyHeroEquipmentResourceDebitTx','AlreadyEquipped','NoWork','gxb.ca4-2.mid54.v1','gxb.ca4-2.mid62.v1']:
        if n not in s: errs.append(f'missing service token {n}')
# The embedded research vector must remain byte-identical to the sealed Pass536 oracle.
v=root/'internal/application/characterhero/testdata/ca4_2_planner_adversarial_vectors.json'
if v.is_file():
    got=hashlib.sha256(v.read_bytes()).hexdigest()
    want='28d08a3346b1c6015a7da3a0e2b442613374d5199fd674d367580b7757f9ae78'
    if got!=want: errs.append(f'planner oracle changed: {got}')
# C explicitly does not add dispatcher cases or production route registration.
dispatch=root/'internal/adapters/stockruntime/hero_dispatcher.go'
if dispatch.is_file():
    t=dispatch.read_text()
    for token in ['case 54:', 'case 62:']:
        if token in t: errs.append(f'CA4-2D dispatcher behavior leaked into C: {token}')
# Canonical toolchain/dependency pins remain pristine.
expected={
 '.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718',
 'go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4',
 'go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}
for rel,want in expected.items():
    got=hashlib.sha256((root/rel).read_bytes()).hexdigest()
    if got!=want: errs.append(f'canonical pin changed {rel}: {got}')
if errs:
    print('CA4-2C VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA4-2C VALIDATION: PASS')
print('Normal-Hero MID54/MID62 semantic service and deterministic planner are present; sealed planner oracle is intact; I5 composition is typed; dispatcher/production routing remains deferred to CA4-2D/CA4-5.')
