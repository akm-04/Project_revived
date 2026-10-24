#!/usr/bin/env python3
from pathlib import Path
import hashlib, os, re, sys, zipfile

ROOT=Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def sha(b): return hashlib.sha256(b).hexdigest()
def ep(name): return Path(os.environ.get(name,''))

current=ep('GXB_CA6_3_CURRENT_ARCHIVE')
old=ep('GXB_CA6_3_OLD_ARCHIVE')
v1=ep('GXB_CA6_3_V1_ARCHIVE')
expected_archives={
    'current':(current,'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'),
    'old':(old,'d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'),
    'v1':(v1,'31729d5c5e4509c2c89eaa1e8203cf1570afe87e18ed2610b944e457a9946b15'),
}
for label,(p,want) in expected_archives.items():
    req(p.is_file(),f'exact {label} oracle archive missing')
    if p.is_file(): req(sha(p.read_bytes())==want,f'{label} archive identity drift')

current_expected={
'app-assets/output/assets/src_64/app/common/network/mid.lua':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
'app-assets/output/assets/src_64/app/common/tables/PracticeTypeTable.lua':'4db929ca65f9b841a2a82cad173dd27fc74d5a3507a1167f3549094e526b71ce',
'app-assets/output/assets/src_64/app/windows/WashHeroWindow.lua':'085ce4a90888284de4e12bc142c8b8e356d605e7a8e712fcd0e5b6f0a89a561c',
'app-assets/output/assets/src_64/app/windows/WashHeroAutoWindow.lua':'ed37f8bda81f60e7229e09d66acedafc9db9c6a6213ff4b90dd6d28b5462fa03',
'app-assets/output/assets/src_64/data/tables/practice_type.lua':'74b94f440898a24522fb1c91f61528bab91f3724300f2e0534e586e8f4d2f14d',
}
texts={}
if current.is_file():
    with zipfile.ZipFile(current) as z:
        names=set(z.namelist())
        for member,want in current_expected.items():
            req(member in names,f'current member missing {member}')
            if member in names:
                b=z.read(member); req(sha(b)==want,f'current member hash drift {member}')
                texts[Path(member).name]=b.decode('utf-8','replace')
                peer=member.replace('/src_64/','/src_32/')
                if peer != member:
                    req(peer in names,f'src_32 peer missing {peer}')
                    if peer in names: req(z.read(peer)==b,f'src_32/src_64 drift {Path(member).name}')

mid=texts.get('mid.lua','')
for name,num in [('GET_PRACTICE_INFO',124),('PRACTICE',125),('PRACTICE_SAVE',126),('PRACTICE_AUTO',127),('WASH_BY_TICKET',128),('PET_GET_PRACTICE_INFO',129),('PET_PRACTICE',130),('PET_PRACTICE_SAVE',131),('PET_PRACTICE_AUTO',132),('PET_WASH_BY_TICKET',133),('PET_USE_EXP_ITEMS',134)]:
    req(re.search(rf'xyd\.mid\.{name}\s*=\s*{num}\b',mid) is not None,f'current MID{name}={num} identity drift')
wash=texts.get('WashHeroWindow.lua','')
for tok in ['xyd.mid.GET_PRACTICE_INFO','xyd.mid.PRACTICE','xyd.mid.PET_PRACTICE','xyd.mid.PRACTICE_SAVE','xyd.mid.PET_PRACTICE_SAVE','xyd.mid.WASH_BY_TICKET','xyd.mid.PET_WASH_BY_TICKET','var_30_3.locks = arg_13_0.locks','var_30_3.practice_type = arg_13_0.practiceType','arg_13_0.changeAttrs = arg_32_1.add_attr','arg_13_0.hero:updatePractice(arg_22_1.practice_attr)','arg_39_0.lastTime = arg_39_1.last_time','arg_39_0.baseCrystal = arg_39_1.base_crystal','arg_39_0.baseMana = arg_39_1.base_mana','arg_39_0.blessValue = arg_39_1.bless_value']:
    req(tok in wash,f'current manual/save/get wire evidence missing {tok!r}')
auto=texts.get('WashHeroAutoWindow.lua','')
for tok in ['practice_num = arg_10_0.timesNums[arg_10_0.timesFlag]','save_types = arg_10_0.washWayOptioned','var_15_0.locks = arg_10_0.lockOptioned','var_15_0.practice_type = arg_10_0.wayFlag','xyd.mid.PRACTICE_AUTO','xyd.mid.PET_PRACTICE_AUTO','arg_10_0.hero:updatePractice(arg_16_1.practice_attr)']:
    req(tok in auto,f'current AUTO separation evidence missing {tok!r}')
loader=texts.get('PracticeTypeTable.lua','')
for tok in ['arg_2_0.lower_limit','arg_2_0.up_limit']:
    req(tok in loader,f'current PracticeType loader mismatch evidence missing {tok!r}')
for tok in ['low_limit_weight','weight_num']:
    req(tok not in loader,f'current PracticeType loader unexpectedly qualifies dormant field {tok!r}')

if old.is_file():
    with zipfile.ZipFile(old) as z:
        expected={
            'src/app/common/network/mid.lua':'c10ab0d38105be79201b6b1682a7fcb36eafa7f09b76002c5b9bf599a968d942',
            'src/app/common/tables/PracticeTypeTable.lua':'4db929ca65f9b841a2a82cad173dd27fc74d5a3507a1167f3549094e526b71ce',
            'src/app/windows/WashHeroWindow.lua':'3125448c5d3ec40c5c38bdacfdfffcb5a0b9ef5f45a800a141704b7e376d2bf1',
            'src/app/windows/WashHeroAutoWindow.lua':'28d35bccf7990b457ef91177af15290f3e7fdd3d190571159541fc3037e9b8cc',
            'src/data/tables/practice_type.lua':'74b94f440898a24522fb1c91f61528bab91f3724300f2e0534e586e8f4d2f14d',
        }
        oldtexts={}
        for member,want in expected.items():
            req(member in z.namelist(),f'old member missing {member}')
            if member in z.namelist():
                b=z.read(member); req(sha(b)==want,f'old member hash drift {member}'); oldtexts[Path(member).name]=b.decode('utf-8','replace')
        oldmid=oldtexts.get('mid.lua','')
        for name,num in [('GET_PRACTICE_INFO',124),('PRACTICE',125),('PRACTICE_SAVE',126),('PRACTICE_AUTO',127),('WASH_BY_TICKET',128),('PET_GET_PRACTICE_INFO',129),('PET_PRACTICE',130),('PET_PRACTICE_SAVE',131),('PET_PRACTICE_AUTO',132),('PET_WASH_BY_TICKET',133),('PET_USE_EXP_ITEMS',134)]:
            req(re.search(rf'xyd\.mid\.{name}\s*=\s*{num}\b',oldmid) is not None,f'old MID{name}={num} identity drift')

if v1.is_file():
    with zipfile.ZipFile(v1) as z:
        expected={
            'gxb_backend/protocol/mids.py':'71888f4aaea2921c1af91cce4b458915d354b8a004b9bf2dce2b79b92fe139a0',
            'gxb_backend/handlers/practice.py':'d46fd57b111cbd9e3ffa3c97ba633a8ca5fb6df2925bb46b6ed7bbb4ff11b7bf',
            'gxb_backend/dispatch/engine_dispatcher.py':'6f0a61ed76ef78760037c22e67473e56018194831d7f00ea231b075c7192c26a',
        }
        for member,want in expected.items():
            req(member in z.namelist(),f'frozen V1 member missing {member}')
            if member in z.namelist(): req(sha(z.read(member))==want,f'frozen V1 member hash drift {member}')
        if 'gxb_backend/handlers/practice.py' in z.namelist():
            t=z.read('gxb_backend/handlers/practice.py').decode('utf-8','replace')
            req('hero_practice_server_algorithm_unresolved' in t,'frozen V1 unresolved server-algorithm boundary drift')

# Candidate-bound translation: the recovered source constrains wire ownership but
# does not turn dormant table columns or frozen-V1 guesses into gameplay authority.
roll=(ROOT/'internal/application/characterpractice/roll_policy.go').read_text()
service=(ROOT/'internal/application/characterpractice/service.go').read_text()
dispatch=(ROOT/'internal/adapters/stockruntime/practice_dispatcher.go').read_text()
main=(ROOT/'cmd/gxb-api/main_postgres.go').read_text()
for tok in ['PRACTICE_ROLL_POLICY_V1','characterpractice.roll.v1.selector/method=%d/round=%d','attemptOrdinal']:
    req(tok in roll,f'candidate frozen roll-policy marker missing {tok!r}')
for forbidden in ['low_limit_weight','weight_num','lower_limit','up_limit']:
    req(forbidden not in roll,f'candidate imported dormant Practice metadata into roll authority: {forbidden!r}')
for tok in ['case 124:','case 125:','case 126:','case 128:','case 129:','case 130:','case 131:','case 133:']:
    req(tok in dispatch,f'candidate Practice dispatcher missing {tok!r}')
for forbidden in ['case 127:','case 132:','case 134:']:
    req(forbidden not in dispatch,f'candidate CA6-3 captured future/foreign MID via {forbidden!r}')
req('PracticeDispatcher' in main,'candidate production wiring missing PracticeDispatcher')
req('RollPolicyV1' in service,'candidate service provenance missing frozen roll policy')

if errs:
    print('CA6-3 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA6-3 SOURCE ORACLE CHECK: PASS')
print('current/old/V1 identities and Practice wire family pinned; AUTO remains separate; dormant RNG-looking metadata is not runtime authority')
