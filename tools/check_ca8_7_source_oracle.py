#!/usr/bin/env python3
from pathlib import Path
import fnmatch, hashlib, json, os, sys, zipfile

ROOT=Path(__file__).resolve().parents[1]
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

current=resolve('GXB_CA8_7_CURRENT_ARCHIVE','current_src64')
old=resolve('GXB_CA8_7_OLD_ARCHIVE','old_client')
cur_sha='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
old_sha='d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'
for label,p,want in [('current',current,cur_sha),('old',old,old_sha)]:
    req(p.is_file(),f'exact {label} CA8-7 oracle archive missing')
    if p.is_file(): req(file_sha(p)==want,f'{label} CA8-7 archive identity drift')

cur_prefix='app-assets/output/assets/src_64/'
old_prefix='src/'
cur_members={
'app/model/NormalHero.lua':'125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9',
'app/model/SuperHero.lua':'b127c2cbef327d3142031bf30daa0af1b45997c6da82fba946d641a86783d622',
'app/model/Pet.lua':'214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660',
'app/model/ActivityHero.lua':'2455aa541adba7566a8a39e7b59cb0fabd8d182b6503d686cc7245a19b059a8f',
'app/scenes/BattleCreate.lua':'bb9ae19c20ec165eeb7ba5b81a4ce85b6b7fea3a3a7eb278123bb8c0af0bbef9',
'lib/battle/BaseFighter.lua':'b1936373a0404049f100de1ab639661d245c9f2a317ae6fbd443b71b45d538dc',
}
old_members={
'app/model/Hero.lua':'0743a10aab6528e3c94efd9d8c549c4f56e3f2b11cf68853a934d688428ba4fa',
'app/model/Pet.lua':'ddd75c56c7875aa3f1cb4e4c184df302e4d91e8f11136fe0d58587938f98dc44',
'app/model/ActivityHero.lua':'64107c6774907a52f165f177fc014b9baf298a6b1347a70b04fcf5e854677e67',
'app/scenes/BattleCreate.lua':'565be5062a6e881fcff6aeace195839945bfb74cce955c88558ecd59f36e7a12',
'lib/battle/BaseFighter.lua':'f5acb66e9b3ca2d43270bdfa93294dd99c14fda97a3c2676019bce22541dbd1c',
}
def read_members(path,prefix,expected,label):
    out={}
    if not path.is_file(): return out
    with zipfile.ZipFile(path) as z:
        names=set(z.namelist())
        for rel,want in expected.items():
            name=prefix+rel
            req(name in names,f'{label} CA8-7 source member missing {rel}')
            if name in names:
                b=z.read(name); req(sha(b)==want,f'{label} CA8-7 member hash drift {rel}')
                out[rel]=b.decode('utf-8','replace')
    return out
cur=read_members(current,cur_prefix,cur_members,'current')
oldtxt=read_members(old,old_prefix,old_members,'old')

# Cross-generation materialization/freeze evidence. This proves client dependency
# and freeze shape, not the historical server's authoritative final compiler.
for texts,label,hero_name in [(cur,'current','app/model/NormalHero.lua'),(oldtxt,'old','app/model/Hero.lua')]:
    battle=texts.get('app/scenes/BattleCreate.lua','')
    req(':setupBattleAttrInfo()' in battle and ':setGlobalBuffs()' in battle,f'{label} battle freeze-before-global-buff evidence drift')
    hero=texts.get(hero_name,'')
    for tok in ['getTotalAttr(', 'getSkillAttr(', 'setupBattleAttrInfo(', 'totalAttrs_']:
        req(tok in hero,f'{label} Hero battle dependency/freeze marker missing {tok!r}')
    base=texts.get('lib/battle/BaseFighter.lua','')
    for tok in ['getSkillLevelByID', 'skillQueue_']:
        req(tok in base,f'{label} fighter skill-consumption marker missing {tok!r}')

# Current Hero profile has additional producer families absent in V1.164.
curhero=cur.get('app/model/NormalHero.lua','')
oldhero=oldtxt.get('app/model/Hero.lua','')
for tok in ['getWhiteAlbumAttr(', 'getElementAttr(', 'getSpiritEquipsAttr(']:
    req(tok in curhero,f'current Hero producer marker missing {tok!r}')
    req(tok not in oldhero,f'V1.164 unexpectedly gained current-only producer marker {tok!r}')

# Pet battle dependency surface is materially stable in the inspected clients.
for texts,label in [(cur,'current'),(oldtxt,'old')]:
    pet=texts.get('app/model/Pet.lua','')
    for tok in ['getTotalAttr(', 'getSkillAttr(', 'getEquipAttr(', 'getTotalPracticeAttr(', 'setupBattleAttrInfo(']:
        req(tok in pet,f'{label} Pet battle dependency marker missing {tok!r}')

# Synthetic activity profiles carry qualified skills/promote attrs rather than
# inheriting the full owned-Hero provider stack.
for texts,label in [(cur,'current'),(oldtxt,'old')]:
    act=texts.get('app/model/ActivityHero.lua','')
    for tok in ['skill_ids', 'promote_attrs', 'getTotalAttr(', 'setupBattleAttrInfo(']:
        req(tok in act,f'{label} ActivityHero synthetic-profile marker missing {tok!r}')

# Client attrMD5 is local integrity state; it must not become a CA8 aggregate hash.
req('attrMD5_' in curhero and 'isClient' in curhero,'current client-local Hero attrMD5 evidence drift')

product=(ROOT/'internal/application/characterasset/battle_contribution.go').read_text()
for tok in [
    'BattleCharacterContributionSchemaVersion = "ca8-7/v1"', 'OwnedHeroBattleContribution', 'BorrowedHeroBattleContribution',
    'SyntheticHeroBattleContribution', 'OwnedCompositeBuilder', 'BorrowedCompositeBuilder', 'MaterializeSyntheticHero',
    'MaterializeSyntheticPet', 'ProviderUnavailableUnqualified',
]: req(tok in product,f'candidate CA8-7 product marker missing {tok!r}')
for bad in ['getTotalAttr', 'attrMD5_', 'getWhiteAlbumAttr', 'getElementAttr', 'getSpiritEquipsAttr', 'ProviderRequiredButUnavailable', 'CombatSnapshot{']:
    req(bad not in product,f'candidate CA8-7 leaked client/final-compiler marker {bad!r}')

if errs:
    print('CA8-7 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA8-7 SOURCE ORACLE CHECK: PASS')
print('current/V1.164 freeze and skill dependencies, current-only Hero producer deltas, stable Pet dependency surface, synthetic profile shape and client-local attrMD5 boundary preserved; no historical server final compiler claimed')
