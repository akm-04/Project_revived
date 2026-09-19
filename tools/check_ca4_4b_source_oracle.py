#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, os, re, sys, zipfile

R = Path(__file__).resolve().parents[1]
errs = []
def req(ok, msg):
    if not ok: errs.append(msg)
def sha(b): return hashlib.sha256(b).hexdigest()

def archive_from(*names):
    for name in names:
        v = os.environ.get(name, '')
        if v:
            return Path(v)
    return Path('')

current = archive_from('GXB_CA4_4B_CURRENT_ARCHIVE', 'GXB_R4A_SOURCE_ARCHIVE')
old = archive_from('GXB_CA4_4B_OLD_ARCHIVE')
req(current.is_file(), 'exact current src_64 archive missing; set GXB_CA4_4B_CURRENT_ARCHIVE')
req(old.is_file(), 'exact old-client archive missing; set GXB_CA4_4B_OLD_ARCHIVE')

CURRENT_ARCHIVE_SHA = 'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
OLD_ARCHIVE_SHA = 'd0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'
current_expected = {
    'app-assets/output/assets/src_64/app/common/network/mid.lua': '026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
    'app-assets/output/assets/src_64/app/model/Pet.lua': '214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660',
    'app-assets/output/assets/src_64/app/windows/PetMainWindow.lua': 'fcebe7e4fa742d8a176c8da10502c410e5031720023369bebed01c7da3a99832',
    'app-assets/output/assets/src_64/data/tables/item.lua': '59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc',
}
old_expected = {
    'src/app/common/network/mid.lua': 'c10ab0d38105be79201b6b1682a7fcb36eafa7f09b76002c5b9bf599a968d942',
    'src/app/model/Pet.lua': 'ddd75c56c7875aa3f1cb4e4c184df302e4d91e8f11136fe0d58587938f98dc44',
    'src/app/windows/PetMainWindow.lua': '786f2cb9e8d3a014208395f2667c7269325c7f51fee9952e2baa2e2bad249a57',
    'src/data/tables/item.lua': '32d073bc32b78d991e084f8f19782fbc66d660221805df540d26384e43e870d0',
}
texts = {}
for label, archive, archive_sha, expected in [('current', current, CURRENT_ARCHIVE_SHA, current_expected), ('old', old, OLD_ARCHIVE_SHA, old_expected)]:
    if not archive.is_file():
        continue
    req(sha(archive.read_bytes()) == archive_sha, f'{label} archive identity drift: {sha(archive.read_bytes())}')
    with zipfile.ZipFile(archive) as z:
        names = set(z.namelist())
        for path, want in expected.items():
            req(path in names, f'{label} source member missing: {path}')
            if path in names:
                b = z.read(path)
                req(sha(b) == want, f'{label} source hash drift {path}: {sha(b)}')
                texts[(label, path.split('/')[-1])] = b.decode('utf-8', 'replace')

for label in ('current', 'old'):
    mid = texts.get((label, 'mid.lua'), '')
    pet = texts.get((label, 'Pet.lua'), '')
    main = texts.get((label, 'PetMainWindow.lua'), '')
    req(re.search(r'PET_ADVANCE\s*=\s*785\b', mid) is not None, f'{label} MID785 identity drift')
    req(re.search(r'PET_ONE_KEY_UP\s*=\s*790\b', mid) is not None, f'{label} MID790 identity drift')
    for token in [
        'pet_id =', 'PET_ADVANCE', 'PET_ONE_KEY_UP',
        'equips_[', 'fumo_[', 'color_ =', 'isAwakenItem',
    ]:
        req(token in pet, f'{label} Pet.lua evidence missing {token!r}')
    for token in [
        'CheckOneClickJinjie', 'composeMana', 'partnerExp:totalExp',
        '50001087', '50001088', '50001089', 'selfPlayer.mana',
        'restore_items', '.table_id', '.item_num',
    ]:
        req(token in main, f'{label} PetMainWindow.lua evidence missing {token!r}')

# Current client specifically exposes raw three-slot Fumo in private Pet data,
# clears ordinary equip/Fumo on promotion, and max-color one-key collects ordinary slots.
cur_pet = texts.get(('current', 'Pet.lua'), '')
req('arg_3_3.fumos or' in cur_pet and 'table.insert(arg_3_0.fumo_' in cur_pet, 'current raw fumos[3] private-state evidence missing')
req('arg_119_0.fumo_[iter_120_0] = 0' in cur_pet, 'current MID790 ordinary Fumo clear evidence missing')
req('arg_125_0.fumo_[iter_126_0] = 0' in cur_pet, 'current MID785 ordinary Fumo clear evidence missing')
req('arg_119_0.equips_[iter_120_2] = 1' in cur_pet, 'current MID790 max-color ordinary collect evidence missing')

# Generated immutable content must remain exactly tied to the source-qualified I1 catalog.
manifest = json.loads((R / 'internal/content/builtin/generated/manifest.json').read_text())
req(manifest.get('revision_id') in {'b36ac5cac34e64ed980f8c5beb3437e1bfceb34a55400b2af50620d09e87b8eb', '6ba22017fab270d38fbb68ab30bea0afe61442a979f74084fd7f5027a184e116'}, 'CA4-4B generated content revision/successor drift')
req((manifest.get('compiler_version'), manifest.get('parser_version')) in {('ca4-4b-i1','lua-generated-v11-pet-restoration'), ('ca4-5-i1','lua-generated-v12-super-equipment'), ('ca6-2-practice-foundation','lua-generated-v13-practice')}, 'CA4-4B generator successor identity drift')
req('PET_PROMOTION_RESTORATION_CA4_4B' in manifest.get('enabled_capabilities', []), 'Pet promotion restoration capability absent')
req(manifest.get('diagnostics', {}).get('pet_promotion_restoration_eligible_equipment') == 73, 'Pet restoration eligibility diagnostic drift')
cat = json.loads((R / 'internal/content/builtin/generated/pet_promotion_restoration_catalog.json').read_text())
rows = cat.get('eligible_equipment', [])
req(len(rows) == 73, f'Pet restoration catalog row count drift: {len(rows)}')
dist = {}
q1 = []
for row in rows:
    q = row.get('source_quality'); dist[q] = dist.get(q, 0) + 1
    if q == 1: q1.append(row.get('equipment_item_id'))
req(dist == {1:3, 2:13, 3:11, 4:24, 5:15, 6:7}, f'Pet restoration quality distribution drift: {dist}')
req(q1 == [80001001, 80001006, 80001010], f'Pet q1 identity drift: {q1}')

# Product guard: both routes stay strict/minimal and use the accepted owner/seams.
wire = (R / 'internal/adapters/stockruntime/pet_dispatcher.go').read_text()
service = (R / 'internal/application/characterpet/promotion_service.go').read_text()
planner = (R / 'internal/application/characterpet/equipment_planner.go').read_text()
main_postgres = (R / 'cmd/gxb-api/main_postgres.go').read_text()
route_match = re.search(r'(?s)for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, petD\)', main_postgres)
req(bool(route_match), 'production Pet registration block missing')
if route_match:
    for mid in (785, 790):
        req(re.search(rf'(^|\D){mid}(\D|$)', route_match.group(1)) is not None, f'MID{mid} production registration missing')
for mid in ('case 785:', 'case 790:'):
    req(mid in wire, f'product route missing {mid}')
req('requiredPetInt64(req.Envelope.Params, "pet_id")' in wire and 'onlyStockGameplayParams(req.Envelope.Params, "pet_id")' in wire, 'strict pet_id parser/shape guard missing')
req('petRestorationResponse(' in wire, 'restore_items-only response helper missing')
route785 = wire.split('case 785:',1)[1].split('case 790:',1)[0]
route790 = wire.split('case 790:',1)[1].split('case 786:',1)[0]
for forbidden in ['"economy_"', '"mana"']:
    req(forbidden not in route785 and forbidden not in route790, f'MID785/MID790 expose forbidden response field {forbidden}')
for token in ['LockPetByIDTx', 'SavePetStateTx', 'PreparePromotionResourcesTx', 'ApplyPromotionResourcesTx', 'PetExpPolicyTx', 'petOneKeyPromotionReceiptSchema']:
    req(token in service, f'CA4-4B service contract token missing {token}')
req('50001087, 50001088, 50001089' in planner and 'MaxEXPShortfall' in planner, 'CA4-4A planner compatibility reuse drift')

if errs:
    print('CA4-4B SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -', e)
    sys.exit(1)
print('CA4-4B SOURCE ORACLE CHECK: PASS')
print('exact current+old client hashes preserve MID785/MID790 identities, pet_id-only transitions, raw Fumo/ordinary clear/max-color collect, recursive planner/potion facts and restore_items projection; generated Pet restoration catalog remains exact')
