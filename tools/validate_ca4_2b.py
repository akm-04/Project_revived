#!/usr/bin/env python3
from pathlib import Path
import hashlib, sys
root=Path(__file__).resolve().parents[1]
errs=[]
req=[
 'internal/application/i5/hero_equipment_resources.go',
 'internal/application/i5/hero_equipment_resources_test.go',
 'internal/application/characterhero/equipment_state.go',
 'internal/content/builtin/generated/hero_equipment_catalog.json',
]
for r in req:
    if not (root/r).is_file(): errs.append(f'missing {r}')
if (root/'internal/application/i5/hero_equipment_resources.go').is_file():
    s=(root/'internal/application/i5/hero_equipment_resources.go').read_text()
    needles=[
      'type TxHeroEquipmentResourceDebiter interface',
      'PrepareHeroEquipmentResourcesTx',
      'ApplyHeroEquipmentResourceDebitTx',
      'LockEconomyOwnerTx', 'LockProgressionTx', 'LockScalarTx', 'LockStackTx',
      'StackQuantity', 'PreparedStackItemIDs',
      'outside prepared closure',
    ]
    for n in needles:
        if n not in s: errs.append(f'missing B seam token: {n}')
    # Apply must not call owner read/lock/content APIs after its declaration.
    apply=s.split('func (d HeroEquipmentResourceDebiter) ApplyHeroEquipmentResourceDebitTx',1)[-1]
    for forbidden in ['LockEconomyOwnerTx(', 'LockProgressionTx(', 'LockScalarTx(', 'LockStackTx(', 'ResolveResourceTx(']:
        if forbidden in apply: errs.append(f'Apply performs forbidden read/lock/content operation: {forbidden}')
# Keep later implementation stages out of B.
for base in ['internal/adapters/stockruntime','cmd/gxb-api']:
    for p in (root/base).rglob('*.go'):
        t=p.read_text(errors='ignore')
        if 'case 54:' in t or 'case 62:' in t:
            errs.append(f'CA4-2D dispatcher/route behavior leaked into B: {p.relative_to(root)}')
for p in (root/'internal/application/characterhero').rglob('*.go'):
    if p.name.endswith('_test.go'): continue
    t=p.read_text(errors='ignore')
    if 'MID54' in t or 'MID62' in t or 'EquipOneClick' in t:
        errs.append(f'CA4-2C gameplay behavior leaked into B: {p.relative_to(root)}')
# Canonical environment pins must remain pristine.
expected={
 '.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718',
 'go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4',
 'go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}
for rel,want in expected.items():
    got=hashlib.sha256((root/rel).read_bytes()).hexdigest()
    if got!=want: errs.append(f'canonical pin changed {rel}: {got}')
if errs:
    print('CA4-2B VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA4-2B VALIDATION: PASS')
print('I5 opaque Prepare/Apply resource snapshot/debit seam present; D01 owner/progression/Mana/stack lock suffix is explicit; Apply is write-only and later CA4-2C/D behavior remains absent')
