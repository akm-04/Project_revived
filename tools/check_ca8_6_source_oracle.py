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

current=resolve('GXB_CA8_6_CURRENT_ARCHIVE','current_src64')
old=resolve('GXB_CA8_6_OLD_ARCHIVE','old_client')
cur_sha='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
old_sha='d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'
for label,p,want in [('current',current,cur_sha),('old',old,old_sha)]:
    req(p.is_file(),f'exact {label} CA8-6 oracle archive missing')
    if p.is_file(): req(file_sha(p)==want,f'{label} CA8-6 archive identity drift')

cur_prefix='app-assets/output/assets/src_64/'
old_prefix='src/'
current_members={
'app/model/PersonDisplay.lua':'022fcbf39167ac9197ce5034b32fd5833016742744ad3de118ceacf6f808cfb8',
'app/windows/PersonDisplayWindow.lua':'22a0c02172eabec1d9728d18293273c8e2aa9e6c8e5b1a4bf3af2feae14f158c',
'app/windows/SelectHeroCardWindow.lua':'e1db1b02194652043b289b2670501c0fc8226ccaba17c8e5eca1a915e715440e',
'app/model/NormalHero.lua':'125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9',
'app/model/Pet.lua':'214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660',
'app/windows/HeroListCell.lua':'0b2f3142f31e6ca39a54a2500908c04c392a0e5dc658410eb1833dde0f78e943',
'app/common/network/mid.lua':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
}
old_members={
'app/model/PersonDisplay.lua':'022fcbf39167ac9197ce5034b32fd5833016742744ad3de118ceacf6f808cfb8',
'app/windows/PersonDisplayWindow.lua':'dbe7ae0f8c4ea304fa3b4e065010584cf5d1d6bf97fdd1fbb11dce80d248ae99',
'app/windows/SelectHeroCardWindow.lua':'54cb3118fb70048eb3edf74e9819a439745eeda27b397eb0f786c7c441cae04b',
'app/model/Hero.lua':'0743a10aab6528e3c94efd9d8c549c4f56e3f2b11cf68853a934d688428ba4fa',
'app/common/network/mid.lua':'c10ab0d38105be79201b6b1682a7fcb36eafa7f09b76002c5b9bf599a968d942',
}

def read_members(path: Path, prefix: str, expected: dict[str,str], label: str):
    out={}
    if not path.is_file(): return out
    with zipfile.ZipFile(path) as z:
        names=set(z.namelist())
        for rel,want in expected.items():
            name=prefix+rel
            req(name in names,f'{label} CA8-6 source member missing {rel}')
            if name in names:
                b=z.read(name)
                req(sha(b)==want,f'{label} CA8-6 member hash drift {rel}')
                out[rel]=b.decode('utf-8','replace')
    return out

cur=read_members(current,cur_prefix,current_members,'current')
oldtxt=read_members(old,old_prefix,old_members,'old')

# Cross-generation request/model continuity. These prove client request/consumer
# behavior only; they do not prove the original server's response schema.
req(cur.get('app/model/PersonDisplay.lua','') == oldtxt.get('app/model/PersonDisplay.lua',''),
    'current and V1.164 PersonDisplay.lua continuity drift')
for texts,label in [(cur,'current'),(oldtxt,'old')]:
    mid=texts.get('app/common/network/mid.lua','')
    for name,num in [('GET_PLAYER_CARD_INFO',1829),('MODIFY_SHOW_CASE',1832),('GET_SHOWCASE_DETAIL',1838)]:
        req(re.search(rf'xyd\.mid\.{name}\s*=\s*{num}\b',mid) is not None,f'{label} {name}={num} identity drift')
    person=texts.get('app/model/PersonDisplay.lua','')
    for tok in [
        'to_player_id = var_27_0', 'sub_type = arg_27_1.sub_type', 'xyd.mid.GET_PLAYER_CARD_INFO',
        'ids = arg_56_1', 'xyd.mid.MODIFY_SHOW_CASE',
        'index = arg_77_1.index', 'to_player_id = arg_77_1.playerID', 'xyd.mid.GET_SHOWCASE_DETAIL',
    ]:
        req(tok in person,f'{label} public profile request marker missing {tok!r}')

# Public showcase selection is sourced from owned local collections/getters in
# both inspected client generations; it is not a Guild/Tutor rental selector.
for texts,label in [(cur,'current'),(oldtxt,'old')]:
    select=texts.get('app/windows/SelectHeroCardWindow.lua','')
    for tok in ['selfPlayer.heros_', 'selfPlayer.collectedPets', 'selfPlayer:getHeroByID(', 'selfPlayer:getPetByID(', 'local var_0_4 = 6']:
        req(tok in select,f'{label} owned showcase selector evidence missing {tok!r}')
    for bad in ['rentHeros', 'rentPets', 'tutor_rent_hero', 'rent_player_id']:
        req(bad not in select,f'{label} showcase selector unexpectedly consumes rental marker {bad!r}')

# Presentation/version deltas stay out of Character truth.
cur_window=cur.get('app/windows/PersonDisplayWindow.lua','')
old_window=oldtxt.get('app/windows/PersonDisplayWindow.lua','')
req('local var_0_6 = 5' in cur_window,'current visible showcase count no longer 5')
req('local var_0_6 = 6' in old_window,'V1.164 visible showcase count no longer 6')

cur_hero=cur.get('app/model/NormalHero.lua','')
old_hero=oldtxt.get('app/model/Hero.lua','')
req('arg_3_0.force_ = math.ceil(tonumber(arg_3_1.force) or 0)' in cur_hero,'current optional Hero force input drift')
req('force_' not in old_hero,'V1.164 unexpectedly gained current Hero force field')
req('arg_3_0.isLike = arg_3_1.is_like or 0' in cur_hero,'current Bookmark/is_like model residual drift')
req(re.search(r'xyd\.mid\.HERO_COLLOCATION\s*=\s*3116\b',cur.get('app/common/network/mid.lua','')) is not None,'current HERO_COLLOCATION=3116 drift')
req('HERO_COLLOCATION' not in oldtxt.get('app/common/network/mid.lua',''),'V1.164 unexpectedly gained current Bookmark MID')

# Client-side defaults are presentation fallbacks, not server truth.
req('local var_3_1 = arg_3_1.skills or {' in cur_hero,'current Hero skill default/fallback marker drift')
req('local var_4_0 = arg_4_1.skills or {' in cur.get('app/model/Pet.lua',''),'current Pet skill default/fallback marker drift')

# Candidate translation: internal OWNED-only Character facade. Keep endpoint
# response/version policy out of CA8-6 and do not fabricate Hero skill values.
product=(ROOT/'internal/application/characterasset/public_showcase.go').read_text()
for tok in [
    'type PublicHeroCharacterFacet struct', 'type PublicPetCharacterFacet struct',
    'type PublicShowcaseCharacterReader struct', 'OwnerComposite *OwnedCompositeBuilder',
    'character.HeroRef', 'character.PetRef', '.OwnedHeroTx(', '.OwnedPetTx(',
    'HeroSkillsDisposition: ProviderUnavailableUnqualified',
]:
    req(tok in product,f'candidate CA8-6 product marker missing {tok!r}')
for bad in [
    'GET_PLAYER_CARD_INFO', 'MODIFY_SHOW_CASE', 'GET_SHOWCASE_DETAIL', '1829', '1832', '1838',
    'show_case', 'is_like', 'HERO_COLLOCATION', 'force_', 'ActorOriginBorrowed',
    'ActorOriginTrial', 'ActorOriginNPCTemplate',
]:
    req(bad not in product,f'candidate CA8-6 leaked client/wire/origin marker {bad!r}')

if errs:
    print('CA8-6 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA8-6 SOURCE ORACLE CHECK: PASS')
print('current/V1.164 identities, owned selector provenance, MID1829/1832/1838 request continuity, 5-visible/6-stored delta, optional-force/Bookmark deltas and client-default nonauthority preserved; no original-server response schema claimed')
