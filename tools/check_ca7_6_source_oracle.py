#!/usr/bin/env python3
from pathlib import Path
import fnmatch, hashlib, json, os, re, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def file_sha(p: Path) -> str:
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1<<20),b''): h.update(b)
    return h.hexdigest()
def sha(b: bytes) -> str: return hashlib.sha256(b).hexdigest()

def resolve(env_name: str, oid: str) -> Path:
    explicit=os.environ.get(env_name,'')
    if explicit: return Path(explicit)
    root=Path(sys.argv[1] if len(sys.argv)>1 else os.environ.get('GXB_ORACLE_ROOT','/mnt/data'))
    lock=json.loads((ROOT/'oracles.lock.json').read_text())
    ent=next(x for x in lock['oracles'] if x['id']==oid)
    if root.is_dir():
        for p in sorted(root.rglob('*.zip')):
            try:
                if any(fnmatch.fnmatch(p.name,pat) for pat in ent['filename_patterns']) and file_sha(p)==ent['sha256']:
                    return p
            except OSError:
                pass
    return Path('')

current=resolve('GXB_CA7_6_CURRENT_ARCHIVE','current_src64')
old=resolve('GXB_CA7_6_OLD_ARCHIVE','old_client')
cur_sha='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
old_sha='d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'
for label,p,want in [('current',current,cur_sha),('old',old,old_sha)]:
    req(p.is_file(),f'exact {label} CA7-6 oracle archive missing')
    if p.is_file(): req(file_sha(p)==want,f'{label} CA7-6 archive identity drift')

cur_prefix='app-assets/output/assets/src_64/'
current_members={
'app/common/network/mid.lua':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
'app/model/NormalHero.lua':'125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9',
'app/model/SuperHero.lua':'b127c2cbef327d3142031bf30daa0af1b45997c6da82fba946d641a86783d622',
'lib/battle/BaseFighter.lua':'b1936373a0404049f100de1ab639661d245c9f2a317ae6fbd443b71b45d538dc',
'app/windows/HeroMainWindow.lua':'473b72ec14a81d01d6dbdaa19f92c3d78900f40ca34fa5c8cf46585b76d65414',
'app/windows/SkinSkillSelectWindow.lua':'a6ac7ecb7da0f441b7babb135c5e68e46ece4b2f4bbb60ce77b0ab7a4af614cd',
'app/windows/BackpackWindow.lua':'48b18493fed4186541fc989a8ef60d6338d444c4e8a0fc986903a57e52ff19c1',
'app/windows/PetEquipInfoWindow.lua':'ff5297ed3fe600451df67fdc8e0b52be77cb30e5411beb72c42a60a45571a938',
'app/model/Pet.lua':'214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660',
'app/model/Library.lua':'1830b7e7a5a5203dc7e9eea5bd505b5025b03b52454c69756e14549718962063',
'app/windows/TuJianHeroDetailWindow.lua':'6b3f7c6ebc30019c021835aa20dac3b06a06ebbe9299d5c54291de10733e7f5f',
'data/tables/window.lua':'c7f2fcc6637ab170d5f802904c5ee971eedac33e7fac7112d1afc1675b3a21e3',
'app/common/ui/WindowManager.lua':'6550f9989c8e004b5cf73caaf9a8932f60751db4b1aa3f0bc6f207b46ceeb4f8',
'app/windows/PetAttributeWindow.lua':'8eef73e763bf8564c572d640949a8cd8ca6e1555112d497f81329be38268dfeb',
'app/windows/PetAttributeWindow0.lua':'949a0d07d160f470a23e0d48285acfc279d4aae3ff268cae3f8fb02e7f956e43',
'app/windows/NewBattleLoadingWindow.lua':'4a5336e3b02ea7d139d24025d25b7b5afd8f3f897fc85fff2496ffe3433e9368',
'app/windows/RegionArenaLoadingWindow.lua':'55804d87c9bfe470b80d575d658a518f10c2e5bb747521df35a3fe3253d97644',
'app/windows/SyncSelectTeamWindow.lua':'4b7fae926203e1c5a84612004b4f983466033f36e3bb7a958cc8e2cc1946e39f',
}
old_members={
'src/app/common/network/mid.lua':'c10ab0d38105be79201b6b1682a7fcb36eafa7f09b76002c5b9bf599a968d942',
'src/app/model/Hero.lua':'0743a10aab6528e3c94efd9d8c549c4f56e3f2b11cf68853a934d688428ba4fa',
'src/lib/battle/BaseFighter.lua':'f5acb66e9b3ca2d43270bdfa93294dd99c14fda97a3c2676019bce22541dbd1c',
'src/app/windows/PetAttributeWindow.lua':'003c657bc03a52d37e6594f80ba599e142a1d3ac0b8c3ee5d9945fb2b9dbcbf0',
'src/app/model/Pet.lua':'ddd75c56c7875aa3f1cb4e4c184df302e4d91e8f11136fe0d58587938f98dc44',
}
curtxt={}; oldtxt={}
if current.is_file():
    with zipfile.ZipFile(current) as z:
        names=z.namelist(); files=[n for n in names if n.startswith(cur_prefix) and not n.endswith('/')]
        req(len(files)==4370,f'current src_64 file census drift: {len(files)} != 4370')
        for rel,want in current_members.items():
            name=cur_prefix+rel; req(name in names,f'current CA7-6 source member missing {rel}')
            if name in names:
                b=z.read(name); req(sha(b)==want,f'current CA7-6 member hash drift {rel}'); curtxt[rel]=b.decode('utf-8','replace')
        # Full-tree reachability/consumer census assertions.
        external=[]; battle_dynamic=[]; battle_unlock=[]; battle_style=[]
        for name in files:
            if not name.endswith('.lua'): continue
            text=z.read(name).decode('utf-8','replace')
            rel=name[len(cur_prefix):]
            if rel!='app/windows/PetAttributeWindow0.lua' and 'PetAttributeWindow0' in text: external.append(rel)
            if rel.startswith('lib/battle/'):
                if 'dynamic_card_state' in text: battle_dynamic.append(rel)
                if 'unlocked_dynamic_card' in text: battle_unlock.append(rel)
                if 'active_style' in text: battle_style.append(rel)
        req(not external,f'PetAttributeWindow0 unexpectedly reachable/referenced: {external[:8]}')
        req(not battle_dynamic,f'battle dynamic_card_state consumer appeared: {battle_dynamic[:8]}')
        req(not battle_unlock,f'battle unlocked_dynamic_card consumer appeared: {battle_unlock[:8]}')
        req(not battle_style,f'battle active_style consumer appeared: {battle_style[:8]}')
if old.is_file():
    with zipfile.ZipFile(old) as z:
        names=set(z.namelist())
        for name,want in old_members.items():
            req(name in names,f'old CA7-6 source member missing {name}')
            if name in names:
                b=z.read(name); req(sha(b)==want,f'old CA7-6 member hash drift {name}'); oldtxt[name]=b.decode('utf-8','replace')

mid=curtxt.get('app/common/network/mid.lua','')
for name,num in [('SKIN_ON',60),('SKIN_CANCEL',61),('UNLOCK_DYNAMIC_CARD',68),('SHOW_DYNAMIC_CARD',69),('GET_PET_STYLE_FORM_ITEM',1893),('USE_PET_STYLE',1894),('CANCEL_PET_STYLE',1895),('USE_ILLUSION_SKIN_ITEM',2979)]:
    req(re.search(rf'xyd\.mid\.{name}\s*=\s*{num}\b',mid) is not None,f'current MID identity drift {name}={num}')
normal=curtxt.get('app/model/NormalHero.lua','')
battle=curtxt.get('lib/battle/BaseFighter.lua','')
req('return arg_38_0:getOldModelID()' in normal and 'return arg_38_0.illusionSkinId_' in normal,'current illusion-aware presentation split drift')
req('function var_0_3.getSkillModelID' in battle and ':getOldModelID()' in battle,'current ordinary-skin combat skill axis drift')
req('getSkillModelID() == var_383_2' in battle,'current skin-skill matching no longer uses skill-model axis')
oldbattle=oldtxt.get('src/lib/battle/BaseFighter.lua','')
req('getSkillModelID' not in oldbattle,'v1.164 unexpectedly has current getSkillModelID split')
req('getModelID() == var_365_2' in oldbattle,'v1.164 skin-skill differential drift')
pet=curtxt.get('app/model/Pet.lua','')
req('active_style or 0' in pet and 'pet_styles or {}' in pet,'current Pet style state identities drift')
req('function var_0_3.getModelID' in pet and 'modelIDs(arg_33_0:getTableID())' in pet,'current Pet display model derivation drift')
window=curtxt.get('data/tables/window.lua',''); wm=curtxt.get('app/common/ui/WindowManager.lua','')
req('"pet_attribute"' in window and '"PetAttributeWindow"' in window,'current pet_attribute route drift')
req('import("app.windows." .. xyd.tables.window:className' in wm,'current WindowManager registered-class loading drift')
legacy=curtxt.get('app/windows/PetAttributeWindow0.lua','')
req('xyd.mid.SKIN_ON' in legacy and 'xyd.mid.SKIN_CANCEL' in legacy,'retained PetAttributeWindow0 historical branch missing')
lib=curtxt.get('app/model/Library.lua',''); detail=curtxt.get('app/windows/TuJianHeroDetailWindow.lua','')
req('SET_BOARD_HERO' in lib and all(x in detail for x in ['board_partner','board_card','board_model_id']),'Library board boundary source drift')

# Candidate translation constraints: contribution is qualified state/provenance only, never a collapsed battle model.
hero=(ROOT/'internal/application/characterhero/appearance_contribution.go').read_text()
petgo=(ROOT/'internal/application/characterpet/appearance_contribution.go').read_text()
asset=(ROOT/'internal/application/characterasset/appearance_contribution.go').read_text()
for forbidden in ['EffectiveModelID','BattleModelID','SkillModelID','SkinSkillID']:
    req(forbidden not in hero+petgo+asset,f'CA7-6 contribution collapsed/derived battle model semantics via {forbidden}')
for tok in ['ContentRevision','Appearance','OwnerID','TableID','OriginTableID']:
    req(tok in asset,f'CA7-6 contribution provenance marker missing {tok}')

if errs:
    print('CA7-6 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA7-6 SOURCE ORACLE CHECK: PASS')
print('full current src_64 census, eight appearance MIDs, presentation/combat differential, LIVE/Pet-style nonbattle census, Library boundary and legacy Pet window reachability preserved')
