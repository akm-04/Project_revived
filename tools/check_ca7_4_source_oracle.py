#!/usr/bin/env python3
from pathlib import Path
import fnmatch, hashlib, json, os, re, sys, zipfile

ROOT=Path(__file__).resolve().parents[1]
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
    if explicit: return Path(explicit)
    oroot=Path(sys.argv[1] if len(sys.argv)>1 else os.environ.get('GXB_ORACLE_ROOT','/mnt/data'))
    lock=json.loads((ROOT/'oracles.lock.json').read_text())
    ent=next(x for x in lock['oracles'] if x['id']==oid)
    if oroot.is_dir():
        for p in sorted(oroot.iterdir()):
            if p.is_file() and any(fnmatch.fnmatch(p.name,pat) for pat in ent['filename_patterns']) and file_sha(p)==ent['sha256']:
                return p
    return Path('')

current=resolve_oracle('GXB_CA7_4_CURRENT_ARCHIVE','current_src64')
want_archive='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
req(current.is_file(),'exact current CA7-4 oracle archive missing')
if current.is_file(): req(file_sha(current)==want_archive,'current CA7-4 archive identity drift')

members={
 'mid':'app-assets/output/assets/src_64/app/common/network/mid.lua',
 'hero':'app-assets/output/assets/src_64/app/model/NormalHero.lua',
 'window':'app-assets/output/assets/src_64/app/windows/HeroMainWindow.lua',
 'backend':'app-assets/output/assets/src_64/app/common/network/Backend.lua',
 'self':'app-assets/output/assets/src_64/app/model/SelfPlayer.lua',
 'skin_dynamic_table':'app-assets/output/assets/src_64/app/common/tables/SkinDynamicTable.lua',
 'misc':'app-assets/output/assets/src_64/data/tables/misc.lua',
 'skin_dynamic':'app-assets/output/assets/src_64/data/tables/skin_dynamic.lua',
 'utils':'app-assets/output/assets/src_64/app/common/utils.lua',
 'super':'app-assets/output/assets/src_64/app/model/SuperHero.lua',
}
expected={
 'mid':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
 'hero':'125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9',
 'window':'473b72ec14a81d01d6dbdaa19f92c3d78900f40ca34fa5c8cf46585b76d65414',
 'backend':'95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840',
 'self':'163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4',
 'skin_dynamic_table':'b41bcc1fd5ded9fc26463ddc8080b1dd1920bf0bd0ba387c1e2dc9b23090bf71',
 'misc':'058cf5719421ed71a12083a8c95b0ccded7204bedb5fa1263d508e2fa4257f9a',
 'skin_dynamic':'defe867b01dc6cc0a1eb8dd5ce8c259bc76c2b4aa15427199b040d30fe4fb920',
 'utils':'6e56c7342e889d7ae8d41fe47cb06f66832227efe702f3863f693ee7ba84ffad',
 'super':'b127c2cbef327d3142031bf30daa0af1b45997c6da82fba946d641a86783d622',
}
texts={}
if current.is_file():
    with zipfile.ZipFile(current) as z:
        names=set(z.namelist())
        for k,m in members.items():
            req(m in names,f'current CA7-4 member missing {m}')
            if m in names:
                b=z.read(m); req(sha(b)==expected[k],f'current CA7-4 member hash drift {m}'); texts[k]=b.decode('utf-8','replace')
                peer=m.replace('/src_64/','/src_32/')
                req(peer in names,f'CA7-4 src_32 peer missing {peer}')
                if peer in names: req(z.read(peer)==b,f'CA7-4 src_32/src_64 drift {Path(m).name}')

mid=texts.get('mid','')
req(re.search(r'xyd\.mid\.UNLOCK_DYNAMIC_CARD\s*=\s*68\b',mid) is not None,'MID68 identity drift')
req(re.search(r'xyd\.mid\.SHOW_DYNAMIC_CARD\s*=\s*69\b',mid) is not None,'MID69 identity drift')
hero=texts.get('hero','')
for tok in [
 'var_0_2.mid.UNLOCK_DYNAMIC_CARD', 'partner_id = arg_224_0:getHeroID()',
 'unlocked_dynamic_card', 'dynamic_card_state',
 'var_0_2.mid.SHOW_DYNAMIC_CARD', 'is_show = var_228_2',
 'arg_228_0.dynamicCardState[var_228_1] = var_228_2',
]: req(tok in hero,f'current CA7-4 NormalHero wire evidence missing {tok!r}')
window=texts.get('window','')
for tok in [
 'dynamicType(arg_76_0.hero:getModelID()) == 2', 'xyd.tables.skinDynamic:cost', 'xyd.tables.skinDynamic:num',
 'xyd.tables.misc:getValue("dymisic_item")', 'selfPlayer.crystal', 'backpack:removeItem',
]: req(tok in window,f'current CA7-4 paid LIVE UI evidence missing {tok!r}')
backend=texts.get('backend','')
req('arg_23_0:webRequest_(iter_30_1.mid, iter_30_1.params' in backend,'stock retry/new web request evidence missing')
req('if arg_36_1.economy_ ~= nil then' in backend,'generic economy_ response handling evidence missing')
selfp=texts.get('self','')
req('arg_60_0.crystal = arg_60_1.params.crystal' in selfp,'SelfPlayer Crystal refresh evidence missing')
misc=texts.get('misc','')
req('"dymisic_item"' in misc and '"50005171"' in misc,'CA7-4 activation item evidence drift')
utils=texts.get('utils','')
req('function xyd.splitToNumber' in utils and 'if arg_24_0 == "" or arg_24_0 == nil then' in utils,'LIVE positional-array parser evidence missing')
req('function xyd.isShowDynamicCard' in utils and 'if var_265_2 == 0 then' in utils,'dynamic card type/visibility evidence missing')

# Candidate translation guard.
service=(ROOT/'internal/application/characterhero/live_service.go').read_text()
dispatch=(ROOT/'internal/adapters/stockruntime/hero_dispatcher.go').read_text()
main=(ROOT/'cmd/gxb-api/main_postgres.go').read_text()
replay=(ROOT/'internal/foundation/replaycatalog/catalog.go').read_text()
for tok in ['func (s Service) UnlockLIVE(', 'func (s Service) SetLIVEShow(', 'AppearanceLIVETx', 'DebitMaterialCostTx', 'SaveHeroLIVEEntitlementTx']:
    req(tok in service,f'candidate CA7-4 service marker missing {tok!r}')
req('h.Kind != character.NormalHero' in service and 'def.HeroOriginTableID != h.OriginTableID' in service,'candidate CA7-4 qualification drift')
req('if !owned {' in service and 'IsShow: true' in service,'candidate MID68 first-acquisition/convergence branch drift')
req('current.IsShow != isShow' in service,'candidate MID69 desired-state convergence drift')
for tok in ['case 68:', 'case 69:', 'requiredJSONBit', '"unlocked_dynamic_card"', '"dynamic_card_state"', 'CurrentScalar(ctx, actor.PlayerID, "crystal"']:
    req(tok in dispatch,f'candidate CA7-4 stock translation marker missing {tok!r}')
req('raw.(json.Number)' in dispatch and 'v != 0 && v != 1' in dispatch,'candidate MID69 strict numeric bit parser drift')
req('67, 68, 69, 89' in main,'candidate CA7-4 production registration drift')
for tok in ['ca7.hero-live-unlock', 'CurrentStateConvergence', 'ca7.hero-live-show', 'ParameterStateSet']:
    req(tok in replay,f'candidate CA7-4 replay classification missing {tok!r}')
for forbidden in ['case 1893:', 'case 1894:', 'case 1895:']:
    req(forbidden not in dispatch,f'candidate captured CA7-5 route {forbidden}')

if errs:
    print('CA7-4 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA7-4 SOURCE ORACLE CHECK: PASS')
print('current oracle identity pinned; MID68/69 wire, paid LIVE costs/item, economy refresh/retry behavior, positional reload projection and candidate translation preserved')
