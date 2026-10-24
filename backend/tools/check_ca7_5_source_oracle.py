#!/usr/bin/env python3
from pathlib import Path
import fnmatch, hashlib, json, os, re, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def sha(b): return hashlib.sha256(b).hexdigest()
def file_sha(p: Path) -> str:
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1<<20),b''): h.update(b)
    return h.hexdigest()

def resolve_oracle(env_name: str, oid: str) -> Path:
    explicit=os.environ.get(env_name,'')
    if explicit:
        return Path(explicit)
    oroot=Path(sys.argv[1] if len(sys.argv)>1 else os.environ.get('GXB_ORACLE_ROOT','/mnt/data'))
    lock=json.loads((ROOT/'oracles.lock.json').read_text())
    ent=next(x for x in lock['oracles'] if x['id']==oid)
    if oroot.is_dir():
        for p in sorted(oroot.iterdir()):
            if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in ent['filename_patterns']) and file_sha(p)==ent['sha256']:
                return p
    return Path('')

current=resolve_oracle('GXB_CA7_5_CURRENT_ARCHIVE','current_src64')
old=resolve_oracle('GXB_CA7_5_OLD_ARCHIVE','old_client')
for label,p,want in [
    ('current',current,'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'),
    ('old',old,'d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'),
]:
    req(p.is_file(),f'exact {label} CA7-5 oracle archive missing')
    if p.is_file(): req(file_sha(p)==want,f'{label} CA7-5 archive identity drift')

current_expected={
    'app-assets/output/assets/src_64/app/common/network/mid.lua':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
    'app-assets/output/assets/src_64/app/windows/PetEquipInfoWindow.lua':'ff5297ed3fe600451df67fdc8e0b52be77cb30e5411beb72c42a60a45571a938',
    'app-assets/output/assets/src_64/app/windows/BackpackWindow.lua':'48b18493fed4186541fc989a8ef60d6338d444c4e8a0fc986903a57e52ff19c1',
    'app-assets/output/assets/src_64/app/model/Pet.lua':'214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660',
    'app-assets/output/assets/src_64/app/model/SelfPlayer.lua':'163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4',
    'app-assets/output/assets/src_64/app/common/tables/ItemTable.lua':'1f846972f29a55ee2dbb90f2cb9b0124eaeaa90646c3c66644ab66e231c37f00',
    'app-assets/output/assets/src_64/data/tables/item.lua':'59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc',
}
old_expected={
    'src/app/common/network/mid.lua':'c10ab0d38105be79201b6b1682a7fcb36eafa7f09b76002c5b9bf599a968d942',
    'src/app/windows/PetMainWindow.lua':'786f2cb9e8d3a014208395f2667c7269325c7f51fee9952e2baa2e2bad249a57',
    'src/app/windows/BackpackWindow.lua':'f7f24b903311e90027bfdf05c4c672ca397ef9f5e62df137e647bb1542ac74ec',
    'src/app/model/Pet.lua':'ddd75c56c7875aa3f1cb4e4c184df302e4d91e8f11136fe0d58587938f98dc44',
    'src/app/model/SelfPlayer.lua':'aee7827573d82bb36338512e908eb6883911f4996c6c85f1a6f8b826593def3a',
    'src/app/common/tables/ItemTable.lua':'93403b47f624ede80ea4efb336041f9c30364abc89ba12432eef7c849368d81b',
    'src/data/tables/item.lua':'32d073bc32b78d991e084f8f19782fbc66d660221805df540d26384e43e870d0',
}

def read_members(path, expected, label):
    out={}
    if not path.is_file(): return out
    with zipfile.ZipFile(path) as z:
        names=set(z.namelist())
        for member,want in expected.items():
            req(member in names,f'{label} CA7-5 member missing {member}')
            if member in names:
                b=z.read(member)
                req(sha(b)==want,f'{label} CA7-5 member hash drift {member}')
                out[member]=b.decode('utf-8','replace')
                if label=='current':
                    peer=member.replace('/src_64/','/src_32/')
                    if peer != member:
                        req(peer in names,f'CA7-5 src_32 peer missing {peer}')
                        if peer in names: req(z.read(peer)==b,f'CA7-5 src_32/src_64 drift {Path(member).name}')
    return out

cur=read_members(current,current_expected,'current')
oldtxt=read_members(old,old_expected,'old')

for texts, prefix, label in [(cur,'app-assets/output/assets/src_64/','current'),(oldtxt,'src/','old')]:
    mid=texts.get(prefix+'app/common/network/mid.lua','')
    for name,num in [('GET_PET_STYLE_FORM_ITEM',1893),('USE_PET_STYLE',1894),('CANCEL_PET_STYLE',1895)]:
        req(re.search(rf'xyd\.mid\.{name}\s*=\s*{num}\b',mid) is not None,f'{label} {name}={num} identity drift')
    pet=texts.get(prefix+('app/windows/PetEquipInfoWindow.lua' if label=='current' else 'app/windows/PetMainWindow.lua'),'')
    for tok in [
        'pet_id =', 'xyd.mid.CANCEL_PET_STYLE', 'setHomeSkinID(0)',
        'style_id =', 'xyd.mid.USE_PET_STYLE', '.active_style',
        'item_id =', 'xyd.mid.GET_PET_STYLE_FORM_ITEM', '.pet_styles', 'itemNum = 1', 'removeItem(',
    ]: req(tok in pet,f'{label} Pet home-style caller evidence missing {tok!r}')
    # CANCEL branch is the active-state branch; USE/GET are in its else branch.
    cancel_i=pet.find('xyd.mid.CANCEL_PET_STYLE'); use_i=pet.find('xyd.mid.USE_PET_STYLE'); get_i=pet.find('xyd.mid.GET_PET_STYLE_FORM_ITEM')
    req(cancel_i >= 0 and use_i > cancel_i and get_i > use_i,f'{label} cancel-before-use/get reachability ordering drift')
    backpack=texts.get(prefix+'app/windows/BackpackWindow.lua','')
    for tok in ['isPetHomeStyleItem()', ':stylePet(', ':getPetIgnoreAwaken(', 'GET_PET_STYLE_FORM_ITEM', 'item_id =', '.active_style', '.pet_styles', 'itemNum = 1', 'removeItem(']:
        req(tok in backpack,f'{label} backpack acquisition evidence missing {tok!r}')
    petmodel=texts.get(prefix+'app/model/Pet.lua','')
    req('activeStyle = tonumber(' in petmodel and 'active_style or 0' in petmodel,f'{label} Pet active_style state identity drift')
    req('petStyles =' in petmodel and 'pet_styles or {}' in petmodel,f'{label} Pet pet_styles state identity drift')
    player=texts.get(prefix+'app/model/SelfPlayer.lua','')
    req('getPetIgnoreAwaken' in player and ':getTableID() ==' in player and 'afterAwaken' in player,f'{label} base/awakened Pet-family resolution drift')
    itemtable=texts.get(prefix+'app/common/tables/ItemTable.lua','')
    req('stylePet_' in itemtable and 'style_pet' in itemtable and 'function var_0_2.stylePet' in itemtable,f'{label} style_item->Pet origin identity seam drift')

# Candidate translation guard: source facts + frozen R2 implementation policy.
service=(ROOT/'internal/application/characterpet/appearance_style_service.go').read_text()
dispatch=(ROOT/'internal/adapters/stockruntime/pet_dispatcher.go').read_text()
main=(ROOT/'cmd/gxb-api/main_postgres.go').read_text()
store=(ROOT/'internal/adapters/postgres/characterstore/appearance.go').read_text()
replay=(ROOT/'internal/foundation/replaycatalog/catalog.go').read_text()
for tok in ['func (s Service) AcquirePetStyle(', 'func (s Service) SelectPetStyle(', 'func (s Service) CancelPetStyle(', 'BuildEffectivePetAppearanceTx', 'SavePetAppearanceMutationTx', 'SavePetActiveStyleTx']:
    req(tok in service or tok in store,f'candidate CA7-5 service/store marker missing {tok!r}')
for tok in ['case 1893:', 'case 1894:', 'case 1895:', 'requiredPetInt64', '"active_style"', '"pet_styles"']:
    req(tok in dispatch,f'candidate CA7-5 dispatcher marker missing {tok!r}')
acq=dispatch[dispatch.find('case 1893:'):dispatch.find('case 1894:')]
sel=dispatch[dispatch.find('case 1894:'):dispatch.find('case 1895:')]
cancel=dispatch[dispatch.find('case 1895:'):dispatch.find('case 783:')]
for invented in ['"remove_item"','"economy_"','"server_time"','"consumed"','"mutated"','"state_version"']:
    req(invented not in acq,f'MID1893 invented stock response field present {invented}')
req('"active_style"' in acq and '"pet_styles"' in acq,f'MID1893 stock success projection drift')
req('"active_style"' in sel and '"pet_styles"' not in sel,f'MID1894 stock success projection drift')
req('Body: map[string]any{}' in cancel,f'MID1895 stock success must remain empty')
for mid in ['1893','1894','1895']:
    req(re.search(rf'\b{mid}\b',main) is not None,f'CA7-5 production registration missing MID{mid}')
for tok in ['intendedActive := pre.ActiveStyle','p.ActiveStyle = intendedActive','if !owned {','s.debitPetStyleTx','pre.ActiveStyle > 0 && pre.ActiveStyle != styleID','p.ActiveStyle = 0']:
    req(tok in service,f'candidate CA7-5 state-machine marker missing {tok!r}')
req(service.find('LockPetByIDTx') < service.find('s.debitPetStyleTx'), 'candidate CA7-5 Pet owner lock no longer precedes I5 debit')
req(service.count('progressionReceiptReplayTx') >= 6,'candidate CA7-5 early+post-lock D11 rechecks missing')
for tok in ['ca7.pet-style-acquire','CurrentStateConvergence','gxb.ca7-5.pet-style-acquire.v1','ca7.pet-style-select','ca7.pet-style-cancel','gxb.ca7-5.pet-style-select.v1','gxb.ca7-5.pet-style-cancel.v1']:
    req(tok in replay,f'candidate CA7-5 replay marker missing {tok!r}')

if errs:
    print('CA7-5 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA7-5 SOURCE ORACLE CHECK: PASS')
print('current/old oracle bytes pinned; MID1893/1894/1895 wire, callback, reachability, identity and candidate translation preserved')
