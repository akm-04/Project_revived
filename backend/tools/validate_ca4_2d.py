#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, sys
root=Path(__file__).resolve().parents[1]
errs=[]
req=[
 'internal/adapters/stockruntime/hero_dispatcher.go',
 'internal/adapters/stockruntime/hero_ca4_2_test.go',
 'internal/application/characterhero/equipment_service.go',
 'internal/application/characterhero/equipment_planner.go',
 'internal/application/i5/hero_equipment_resources.go',
 'internal/projection/hero/stock.go',
 'internal/archguard/ca4_2_contract_test.go',
 'cmd/gxb-api/main_postgres.go',
]
for rel in req:
    if not (root/rel).is_file(): errs.append(f'missing {rel}')

dispatch=(root/'internal/adapters/stockruntime/hero_dispatcher.go').read_text(errors='ignore')
for token in ['case 54:', 'case 62:', 'EquipItem(', 'OneKeyEquip(', '"error_code": int64(30001)', 'CurrentScalar(ctx, actor.PlayerID, "mana"', '"equips": equips', '"economy_"']:
    if token not in dispatch: errs.append(f'missing D dispatcher token: {token}')
main=(root/'cmd/gxb-api/main_postgres.go').read_text(errors='ignore')
for token in ['HeroEquipmentResourceDebiter{Store: i5db, Content: contentDB}', 'Equipment: contentDB', 'EquipmentResources: heroEquipmentResources', 'Economy: heroEconomyProjection']:
    if token not in main: errs.append(f'missing D wiring token: {token}')
manifest=json.loads((root/'internal/content/builtin/generated/manifest.json').read_text())
ca45='SUPER_EQUIPMENT_CA4_5' in manifest.get('enabled_capabilities',[])
if ca45:
    i3 = 'func (s Service) EnhanceSuperEquipment' in (root/'internal/application/characterhero/equipment_service.go').read_text(errors='ignore')
    want = '[]uint16{49, 51, 52, 54, 55, 57, 58, 62, 63, 67, 89, 304}' if i3 else '[]uint16{49, 51, 52, 54, 55, 57, 58, 62, 63, 67, 89}'
    if want not in main:
        errs.append('CA4-5 production Hero MID set does not match qualified shared/MID304 stage')
else:
    if '[]uint16{49, 52, 55, 63, 67, 89}' not in main:
        errs.append('production Hero MID set does not preserve CA4-2 deferral')
    for token in ['mustRegister(54', 'mustRegister(62', '[]uint16{49, 52, 54', '[]uint16{49, 52, 55, 62']:
        if token in main: errs.append(f'production shared MID activated before CA4-5: {token}')

svc=(root/'internal/application/characterhero/equipment_service.go').read_text(errors='ignore')
for token in ['func (s Service) EquipItem', 'func (s Service) OneKeyEquip', 'AlreadyEquipped: true', 'NoWork: true', 'ApplyHeroEquipmentResourceDebitTx', 'SaveHeroStateTx']:
    if token not in svc: errs.append(f'missing C service token under D: {token}')
proj=(root/'internal/projection/hero/stock.go').read_text(errors='ignore')
if 'for i, v := range h.Equipment' not in proj or '"equips": equips' not in proj:
    errs.append('durable Hero equipment reload projection missing')

expected={
 '.go-version':'a8844fbc8c3eb51c26ed00aec4cd5a5a9d647f849c6ead07bcc83ed24c4a7718',
 'go.mod':'313c574368bb56dc570bc3427b65f59b059e492f909fe43b7d0291b5ced21dc4',
 'go.sum':'efbf6753542d66e2fefcb2ab5e2ade7c9d28f2206a1113d1eb9568f2cb75808d'}
for rel,want in expected.items():
    got=hashlib.sha256((root/rel).read_bytes()).hexdigest()
    if got!=want: errs.append(f'canonical pin changed {rel}: {got}')

if errs:
    print('CA4-2D VALIDATION: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA4-2D VALIDATION: PASS')
print('diagnostic MID54/MID62 dispatcher branches + authoritative Mana projection + CA4-5-aware production wiring present')
