#!/usr/bin/env python3
from pathlib import Path
import hashlib, os, re, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def sha(b): return hashlib.sha256(b).hexdigest()
def ep(name): return Path(os.environ.get(name,''))

current=ep('GXB_CA6_4_CURRENT_ARCHIVE')
old=ep('GXB_CA6_4_OLD_ARCHIVE')
expected_archives={
    'current':(current,'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'),
    'old':(old,'d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'),
}
for label,(p,want) in expected_archives.items():
    req(p.is_file(),f'exact {label} oracle archive missing')
    if p.is_file(): req(sha(p.read_bytes())==want,f'{label} archive identity drift')

members={
 'current':{
  'archive':current,
  'mid':'app-assets/output/assets/src_64/app/common/network/mid.lua',
  'mid_sha':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
  'auto':'app-assets/output/assets/src_64/app/windows/WashHeroAutoWindow.lua',
  'auto_sha':'ed37f8bda81f60e7229e09d66acedafc9db9c6a6213ff4b90dd6d28b5462fa03',
  'process':'app-assets/output/assets/src_64/app/windows/WashProcessWindow.lua',
  'process_sha':'ac0f1e96f97901f4cbf4c87b9c94faadc6fad67632993aa855e53ed198da38a2',
 },
 'old':{
  'archive':old,
  'mid':'src/app/common/network/mid.lua',
  'mid_sha':'c10ab0d38105be79201b6b1682a7fcb36eafa7f09b76002c5b9bf599a968d942',
  'auto':'src/app/windows/WashHeroAutoWindow.lua',
  'auto_sha':'28d35bccf7990b457ef91177af15290f3e7fdd3d190571159541fc3037e9b8cc',
  'process':'src/app/windows/WashProcessWindow.lua',
  'process_sha':'58113bee0548466d5991c043f028289d6b0506429eb16e149a10bf8a49fe3d97',
 },
}
for label,cfg in members.items():
    p=cfg['archive']
    if not p.is_file(): continue
    with zipfile.ZipFile(p) as z:
        names=set(z.namelist())
        texts={}
        for key in ['mid','auto','process']:
            member=cfg[key]; want=cfg[key+'_sha']
            req(member in names,f'{label} member missing {member}')
            if member in names:
                b=z.read(member); req(sha(b)==want,f'{label} member hash drift {member}')
                texts[key]=b.decode('utf-8','replace')
                if label=='current':
                    peer=member.replace('/src_64/','/src_32/')
                    if peer!=member:
                        req(peer in names,f'current src_32 peer missing {peer}')
                        if peer in names: req(z.read(peer)==b,f'current src_32/src_64 drift {Path(member).name}')
        mid=texts.get('mid','')
        req(re.search(r'xyd\.mid\.PRACTICE_AUTO\s*=\s*127\b',mid) is not None,f'{label} Hero AUTO MID drift')
        req(re.search(r'xyd\.mid\.PET_PRACTICE_AUTO\s*=\s*132\b',mid) is not None,f'{label} Pet AUTO MID drift')
        auto=texts.get('auto','')
        for tok in [
            'practice_num = arg_10_0.timesNums[arg_10_0.timesFlag]',
            'save_types = arg_10_0.washWayOptioned',
            'var_15_0.locks = arg_10_0.lockOptioned',
            'var_15_0.practice_type = arg_10_0.wayFlag',
            'xyd.mid.PRACTICE_AUTO','xyd.mid.PET_PRACTICE_AUTO',
            'table.insert(arg_6_0.timesNums, xyd.WashTimes.TWO)',
            'table.insert(arg_6_0.timesNums, xyd.WashTimes.FOUR)',
            'table.insert(arg_6_0.timesNums, xyd.WashTimes.SIX)',
            'table.insert(arg_6_0.timesNums, xyd.WashTimes.EIGHT)',
            'table.insert(arg_6_0.timesNums, xyd.WashTimes.TEN)',
            'arg_10_0.hero:updatePractice(arg_16_1.practice_attr)',
        ]:
            req(tok in auto,f'{label} AUTO wire/result evidence missing {tok!r}')
        # Stock admission is strict: equality is rejected when locks consume Bless.
        req('info.bless_value <=' in auto and 'getBlessNum' in auto and 'washNum' in auto,
            f'{label} strict Bless boundary evidence missing')
        # Locking an axis forces the matching save-selection slot on.
        req('washWayOptioned[iter_25_2] = 1' in auto or 'washWayOptioned[iter_26_2] = 1' in auto,
            f'{label} lock=>save predicate evidence missing')
        process=texts.get('process','')
        for tok in ['arg_8_1.add_attrs','arg_8_1.is_adds','arg_11_1.add_attrs','arg_11_1.is_adds']:
            req(tok in process,f'{label} ordered AUTO playback evidence missing {tok!r}')

# Candidate translation checks. These constrain source-backed wire/projection behavior
# while leaving terminal-cap/RNG-distribution details explicitly policy-owned.
decoder=(ROOT/'internal/adapters/stockruntime/practice_auto_decoder.go').read_text()
dispatch=(ROOT/'internal/adapters/stockruntime/practice_auto_dispatcher.go').read_text()
auto_policy=(ROOT/'internal/application/characterpractice/auto.go').read_text()
auto_service=(ROOT/'internal/application/characterpractice/auto_service.go').read_text()
main=(ROOT/'cmd/gxb-api/main_postgres.go').read_text()
for tok in ['case 127:','case 132:','"practice_num"','"save_types"','locked Practice AUTO axis must be selected']:
    req(tok in decoder,f'candidate AUTO decoder missing {tok!r}')
for tok in ['"info"','"add_attrs"','"is_adds"','"practice_attr"','d.Service.Auto']:
    req(tok in dispatch,f'candidate AUTO projection missing {tok!r}')
for tok in ['AutoSavePredicates','validAutoBatchSize','planAutoBatchV1','RollPracticeV1']:
    req(tok in auto_policy,f'candidate AUTO policy missing {tok!r}')
for tok in ['gxb.ca6.practice-auto.v1','AuthorizeLevelAndDebitScalarTx','SaveAccountingTx','applyPracticeTx','putAutoReceipt']:
    req(tok in auto_service,f'candidate AUTO service missing {tok!r}')
compact=re.sub(r'\s+','',main)
req('[]uint16{124,125,126,127,128,129,130,131,132,133}' in compact,
    'candidate production Practice route family drift')
req('134' not in compact[compact.find('[]uint16{124,125,126,127,128,129,130,131,132,133}'):compact.find('[]uint16{124,125,126,127,128,129,130,131,132,133}')+120],
    'candidate Practice route family captured MID134')

if errs:
    print('CA6-4 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA6-4 SOURCE ORACLE CHECK: PASS')
print('current/old AUTO MID+wire+batch+Bless+playback evidence pinned; candidate 127/132 decoding/projection/routing matches; batch edge/RNG policy remains separately qualified')
