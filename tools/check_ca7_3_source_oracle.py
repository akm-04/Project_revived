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

current=resolve_oracle('GXB_CA7_3_CURRENT_ARCHIVE','current_src64')
old=resolve_oracle('GXB_CA7_3_OLD_ARCHIVE','old_client')
for label,p,want in [
    ('current',current,'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'),
    ('old',old,'d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'),
]:
    req(p.is_file(),f'exact {label} CA7-3 oracle archive missing')
    if p.is_file(): req(sha(p.read_bytes())==want,f'{label} CA7-3 archive identity drift')

texts={}
if current.is_file():
    expected={
        'app-assets/output/assets/src_64/app/common/network/mid.lua':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
        'app-assets/output/assets/src_64/app/windows/SkinSkillSelectWindow.lua':'a6ac7ecb7da0f441b7babb135c5e68e46ece4b2f4bbb60ce77b0ab7a4af614cd',
        'app-assets/output/assets/src_64/app/windows/HeroMainWindow.lua':'473b72ec14a81d01d6dbdaa19f92c3d78900f40ca34fa5c8cf46585b76d65414',
        'app-assets/output/assets/src_64/app/model/NormalHero.lua':'125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9',
        'app-assets/output/assets/src_64/lib/battle/BaseFighter.lua':'b1936373a0404049f100de1ab639661d245c9f2a317ae6fbd443b71b45d538dc',
        'app-assets/output/assets/src_64/data/tables/window.lua':'c7f2fcc6637ab170d5f802904c5ee971eedac33e7fac7112d1afc1675b3a21e3',
        'app-assets/output/assets/src_64/app/common/ui/WindowManager.lua':'6550f9989c8e004b5cf73caaf9a8932f60751db4b1aa3f0bc6f207b46ceeb4f8',
        'app-assets/output/assets/src_64/app/windows/PetAttributeWindow0.lua':'949a0d07d160f470a23e0d48285acfc279d4aae3ff268cae3f8fb02e7f956e43',
        'app-assets/output/assets/src_64/app/windows/PetAttributeWindow.lua':'8eef73e763bf8564c572d640949a8cd8ca6e1555112d497f81329be38268dfeb',
    }
    with zipfile.ZipFile(current) as z:
        names=set(z.namelist())
        for member,want in expected.items():
            req(member in names,f'current CA7-3 member missing {member}')
            if member in names:
                b=z.read(member); req(sha(b)==want,f'current CA7-3 member hash drift {member}')
                texts[member]=b.decode('utf-8','replace')
                peer=member.replace('/src_64/','/src_32/')
                if peer != member:
                    req(peer in names,f'CA7-3 src_32 peer missing {peer}')
                    if peer in names: req(z.read(peer)==b,f'CA7-3 src_32/src_64 drift {Path(member).name}')

mid=texts.get('app-assets/output/assets/src_64/app/common/network/mid.lua','')
for name,num in [('SKIN_ON',60),('SKIN_CANCEL',61),('USE_ILLUSION_SKIN_ITEM',2979)]:
    req(re.search(rf'xyd\.mid\.{name}\s*=\s*{num}\b',mid) is not None,f'current {name}={num} identity drift')

select=texts.get('app-assets/output/assets/src_64/app/windows/SkinSkillSelectWindow.lua','')
for tok in [
    'xyd.mid.SKIN_CANCEL', 'partner_id = arg_4_0.hero:getHeroID()',
    'xyd.mid.SKIN_ON', 'var_8_0.item_id',
    'arg_4_0.hero:setSkinInfo(arg_10_1.current_skin_id, arg_10_1.skin_ids)',
]: req(tok in select,f'current ordinary-skin wire evidence missing {tok!r}')

main=texts.get('app-assets/output/assets/src_64/app/windows/HeroMainWindow.lua','')
for tok in [
    'partner_id = arg_170_0.hero:getHeroID()', 'item_id = var_170_3', 'xyd.mid.SKIN_ON',
    'arg_170_0.hero:setSkinInfo(arg_170_0.hero.skinId_, arg_174_1.skin_ids)',
    'if arg_174_1.remove_item == 1 then',
    'xyd.mid.USE_ILLUSION_SKIN_ITEM', 'arg_170_0.hero.illusionSkinId_ = arg_172_1.illusion_skin_id',
    'item_id = var_170_5',
]: req(tok in main,f'current acquisition/illusion evidence missing {tok!r}')
req('server_time' not in main[main.find('xyd.mid.SKIN_ON')-800:main.find('xyd.mid.SKIN_ON')+1800], 'current MID60 acquisition path unexpectedly requires server_time')

hero=texts.get('app-assets/output/assets/src_64/app/model/NormalHero.lua','')
for tok in [
    'arg_236_0.skinIds_ = {}', 'arg_236_0.timeLimitSkins = {}',
    'if iter_236_1 == -1 then', 'arg_236_0.timeLimitSkins[iter_236_0] = iter_236_1',
    'if iter_237_1 > 0 and iter_237_1 < var_237_0 then',
    'arg_236_0:setSkinInfo(0)', 'var_237_2.item_id = 0',
    'arg_236_0.illusionSkinId_ = 0',
    'if not arg_38_0.illusionSkinId_ or arg_38_0.illusionSkinId_ == -1 then',
    'elseif arg_38_0.illusionSkinId_ == 0 then', 'elseif arg_38_0.illusionSkinId_ == 1 then',
]: req(tok in hero,f'current Hero appearance-state evidence missing {tok!r}')

battle=texts.get('app-assets/output/assets/src_64/lib/battle/BaseFighter.lua','')
req('function var_0_3.getSkillModelID' in battle and 'return arg_267_0.hero_:getOldModelID()' in battle,
    'combat skin-skill axis no longer binds ordinary getOldModelID')

window=texts.get('app-assets/output/assets/src_64/data/tables/window.lua','')
wm=texts.get('app-assets/output/assets/src_64/app/common/ui/WindowManager.lua','')
pet0=texts.get('app-assets/output/assets/src_64/app/windows/PetAttributeWindow0.lua','')
pet=texts.get('app-assets/output/assets/src_64/app/windows/PetAttributeWindow.lua','')
req('"pet_attribute"' in window and '"PetAttributeWindow"' in window,'current pet_attribute registry no longer maps PetAttributeWindow')
req('import("app.windows." .. xyd.tables.window:className(arg_11_1)).new' in wm,'WindowManager dynamic class import evidence missing')
req('xyd.mid.SKIN_ON' in pet0 and 'xyd.mid.SKIN_CANCEL' in pet0,'historical current-corpus PetAttributeWindow0 MID60/61 evidence missing')
req('xyd.mid.SKIN_ON' not in pet and 'xyd.mid.SKIN_CANCEL' not in pet,'active PetAttributeWindow unexpectedly uses Hero MID60/61')

if old.is_file():
    with zipfile.ZipFile(old) as z:
        names=set(z.namelist())
        expected={
            'src/app/common/network/mid.lua':'c10ab0d38105be79201b6b1682a7fcb36eafa7f09b76002c5b9bf599a968d942',
            'src/app/windows/HeroMainWindow.lua':'0dd44db75c40d58a7e0af34156a97c441be9347cab7cf286279678299ef3ca0d',
            'src/lib/battle/BaseFighter.lua':'f5acb66e9b3ca2d43270bdfa93294dd99c14fda97a3c2676019bce22541dbd1c',
            'src/app/windows/PetAttributeWindow.lua':'003c657bc03a52d37e6594f80ba599e142a1d3ac0b8c3ee5d9945fb2b9dbcbf0',
        }
        oldtexts={}
        for member,want in expected.items():
            req(member in names,f'old CA7-3 member missing {member}')
            if member in names:
                b=z.read(member); req(sha(b)==want,f'old CA7-3 member hash drift {member}'); oldtexts[member]=b.decode('utf-8','replace')
        om=oldtexts.get('src/app/common/network/mid.lua','')
        for name,num in [('SKIN_ON',60),('SKIN_CANCEL',61)]:
            req(re.search(rf'xyd\.mid\.{name}\s*=\s*{num}\b',om) is not None,f'old {name}={num} identity drift')
        oldmain=oldtexts.get('src/app/windows/HeroMainWindow.lua','')
        req('xyd.mid.SKIN_ON' in oldmain,'old Hero MID60 caller missing')
        oldpet=oldtexts.get('src/app/windows/PetAttributeWindow.lua','')
        req('xyd.mid.SKIN_ON' in oldpet and 'xyd.mid.SKIN_CANCEL' in oldpet,'old active Pet MID60/61 differential evidence missing')

# Candidate translation guard: recovered client facts constrain wire/state axes;
# CA7-4 may extend production routing with paid LIVE; CA7-5 Pet mutation remains fenced.
service=(ROOT/'internal/application/characterhero/appearance_service.go').read_text()
dispatch=(ROOT/'internal/adapters/stockruntime/hero_dispatcher.go').read_text()
store=(ROOT/'internal/adapters/postgres/characterstore/appearance.go').read_text()
main_go=(ROOT/'cmd/gxb-api/main_postgres.go').read_text()
for tok in ['func (s Service) SkinOn(', 'func (s Service) SkinCancel(', 'func (s Service) UseIllusionSkinItem(', 'SaveHeroAppearanceMutationTx', 'BuildEffectiveHeroAppearanceTx']:
    req(tok in service or tok in store,f'candidate CA7-3 contract marker missing {tok!r}')
for tok in ['case 60:', 'case 61:', 'case 2979:', '"current_skin_id"', '"skin_ids"', '"illusion_skin_id"']:
    req(tok in dispatch,f'candidate CA7-3 dispatcher marker missing {tok!r}')
req('body["server_time"]' not in dispatch,'candidate invented MID60 server_time output')
req('58, 60, 61, 62' in main_go and '67, 68, 69, 89' in main_go and '304, 2979' in main_go,'candidate production Hero CA7-3/4 registration drift')
for required in ['case 68:', 'case 69:']:
    req(required in dispatch,f'candidate lost accepted CA7-4 route {required}')
for forbidden in ['case 1893:', 'case 1894:', 'case 1895:']:
    req(forbidden not in dispatch,f'candidate captured future CA7-5 mutation route {forbidden}')

if errs:
    print('CA7-3 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA7-3 SOURCE ORACLE CHECK: PASS')
print('current/old client identities pinned; MID60/61/2979 wire/state axes, timed expiry, ordinary combat axis, Pet reachability split, and CA7-4 coexistence preserved')
