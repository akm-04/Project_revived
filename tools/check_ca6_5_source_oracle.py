#!/usr/bin/env python3
from pathlib import Path
from collections import defaultdict
import hashlib, json, os, re, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def sha(b): return hashlib.sha256(b).hexdigest()
def ep(name): return Path(os.environ.get(name,''))

current=ep('GXB_CA6_5_CURRENT_ARCHIVE')
old=ep('GXB_CA6_5_OLD_ARCHIVE')
expected={
 'current':(current,'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'),
 'old':(old,'d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'),
}
for label,(p,want) in expected.items():
    req(p.is_file(),f'exact {label} oracle archive missing')
    if p.is_file(): req(sha(p.read_bytes())==want,f'{label} archive identity drift')

members={
 'current':{
  'archive':current,
  'files':{
   'normal':'app-assets/output/assets/src_64/app/model/NormalHero.lua',
   'super':'app-assets/output/assets/src_64/app/model/SuperHero.lua',
   'pet':'app-assets/output/assets/src_64/app/model/Pet.lua',
   'self':'app-assets/output/assets/src_64/app/model/SelfPlayer.lua',
   'player':'app-assets/output/assets/src_64/app/model/Player.lua',
   'wash':'app-assets/output/assets/src_64/app/windows/WashHeroWindow.lua',
  },
  'hashes':{
   'normal':'125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9',
   'super':'b127c2cbef327d3142031bf30daa0af1b45997c6da82fba946d641a86783d622',
   'pet':'214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660',
   'self':'163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4',
   'player':'e8e591f754ffc4fb68d81aa108a861e724a9ac0e16af18b38237bafdd7946dad',
   'wash':'085ce4a90888284de4e12bc142c8b8e356d605e7a8e712fcd0e5b6f0a89a561c',
  },
 },
 'old':{
  'archive':old,
  'files':{
   'hero':'src/app/model/Hero.lua',
   'pet':'src/app/model/Pet.lua',
   'self':'src/app/model/SelfPlayer.lua',
   'player':'src/app/model/Player.lua',
   'wash':'src/app/windows/WashHeroWindow.lua',
  },
  'hashes':{
   'hero':'0743a10aab6528e3c94efd9d8c549c4f56e3f2b11cf68853a934d688428ba4fa',
   'pet':'ddd75c56c7875aa3f1cb4e4c184df302e4d91e8f11136fe0d58587938f98dc44',
   'self':'aee7827573d82bb36338512e908eb6883911f4996c6c85f1a6f8b826593def3a',
   'player':'e8e591f754ffc4fb68d81aa108a861e724a9ac0e16af18b38237bafdd7946dad',
   'wash':'3125448c5d3ec40c5c38bdacfdfffcb5a0b9ef5f45a800a141704b7e376d2bf1',
  },
 },
}
texts={}
for label,cfg in members.items():
    if not cfg['archive'].is_file(): continue
    with zipfile.ZipFile(cfg['archive']) as z:
        names=set(z.namelist())
        for key,member in cfg['files'].items():
            req(member in names,f'{label} member missing {member}')
            if member not in names: continue
            b=z.read(member)
            req(sha(b)==cfg['hashes'][key],f'{label} member hash drift {member}')
            texts[(label,key)]=b.decode('utf-8','replace')
            if label=='current':
                peer=member.replace('/src_64/','/src_32/')
                if peer != member:
                    req(peer in names,f'current src_32 peer missing {peer}')
                    if peer in names: req(z.read(peer)==b,f'current src_32/src_64 drift {Path(member).name}')

# MID1 key49 is authoritative in both current and old clients; later explicit load short-circuits.
for label in ('current','old'):
    selfp=texts.get((label,'self'),'')
    player=texts.get((label,'player'),'')
    req('xyd.mid.LOAD_HEROS' in selfp and 'herosLoaded_ = true' in selfp and 'herosEvent_' in selfp,
        f'{label} embedded MID49 Hero hydration evidence missing')
    req('loadHeros' in player and 'herosLoaded_' in player and 'return' in player,
        f'{label} explicit Hero load short-circuit evidence missing')

# Reducer behavior is longitudinal: Hero awards add, Pet awards overwrite; raw axis is still added.
for label,key in [('current','normal'),('current','super'),('old','hero')]:
    s=texts.get((label,key),'')
    req('practiceAwardAttrs' in s and 'or 0) +' in s and 'getTotalPracticeAttr' in s,
        f'{label}/{key} additive Hero Practice reducer evidence missing')
for label in ('current','old'):
    s=texts.get((label,'pet'),'')
    req('practiceAwardAttrs' in s and re.search(r'practiceAwardAttrs.*?\]\s*=\s*var_',s) is not None and 'getTotalPracticeAttr' in s,
        f'{label} Pet source-order overwrite reducer evidence missing')

# Current+old callbacks refresh the shared Practice info used by timer/red-mark path.
for label in ('current','old'):
    wash=texts.get((label,'wash'),'')
    selfp=texts.get((label,'self'),'')
    req('updateInfo' in wash and 'player.practiceInfo' in wash and 'last_time + xyd.TimeGap' in selfp,
        f'{label} Practice timer/info refresh evidence missing')

# Real catalog evidence: Hero duplicate nonzero award targets exist, so additive semantics are material.
catalog=json.loads((ROOT/'internal/content/builtin/generated/practice_catalog.json').read_text())
by=defaultdict(list)
for row in catalog['hero_thresholds']:
    by[row['hero_table_id']].append(row)
dups=0
for rows in by.values():
    targets=[r['target_attr_type'] for r in rows if r['target_attr_type']>0 and r['bonus_value']>0]
    if len(targets)!=len(set(targets)): dups+=1
req(dups==26,f'Hero duplicate-target catalog count drift: {dups} != 26')

# Candidate translation checks.
hero_boot=(ROOT/'internal/adapters/postgres/characterstore/hero_projection.go').read_text()
main=(ROOT/'cmd/gxb-api/main_postgres.go').read_text()
lobby=(ROOT/'internal/projection/lobby/shapes.go').read_text()
practice_dispatch=(ROOT/'internal/adapters/stockruntime/practice_dispatcher.go').read_text()
asset=(ROOT/'internal/application/characterasset/practice_contribution.go').read_text()
reduce=(ROOT/'internal/application/characterpractice/contribution.go').read_text()
hero=(ROOT/'internal/application/characterhero/practice_contribution.go').read_text()
pet=(ROOT/'internal/application/characterpet/practice_contribution.go').read_text()
for tok in ['Claims() []string { return []string{"49"} }','HeroCoreActiveTx','HeroEquipmentRevisionTx','HeroFumoRevisionTx','ReadRootTx(ctx, q','ListHeroesTx(ctx, q','StockRosterView','detail["49"] = body']:
    req(tok in hero_boot,f'candidate Hero MID1 key49 projection missing {tok!r}')
req('case 124:' not in lobby,'candidate stale Lobby MID124 response shape remains')
for tok in ['case 124:','lobby.BootLegitTimer','d.Tracker.Record']:
    req(tok in practice_dispatch,f'candidate Practice MID124 telemetry ownership missing {tok!r}')
req('characterstore.HeroBootstrapProjection{Content: contentDB}' in main,'candidate Hero key49 contributor not registered')
for tok in ['PracticeContribution','ContentRevision','StateVersion','HERO_ADDITIVE','PET_SOURCE_ORDER_OVERWRITE']:
    req(tok in asset,f'candidate Practice contribution DTO missing {tok!r}')
for tok in ['ReduceAppliedPracticeContribution','checkedContributionAdd','sort.Slice']:
    req(tok in reduce,f'candidate Practice reducer missing {tok!r}')
for s,label in [(hero,'Hero'),(pet,'Pet')]:
    for tok in ['PracticeRevisionTx','ThresholdsTx','StateVersion','ContentRevision']:
        req(tok in s,f'candidate {label} contribution reader missing {tok!r}')
    for bad in ['INSERT INTO ','UPDATE ','DELETE FROM ','BattleMode','formation','suppression']:
        req(bad not in s,f'candidate {label} contribution reader leaked {bad!r}')

# Production routes remain CA6-4 exact; CA6-5 adds no gameplay MID.
compact=re.sub(r'\s+','',main)
req('[]uint16{124,125,126,127,128,129,130,131,132,133}' in compact,'Practice production route family drift')
req('[]uint16{134,780,781,782,783,785,786,787,789,790,791,792}' in compact,'Pet production route family drift')

if errs:
    print('CA6-5 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA6-5 SOURCE ORACLE CHECK: PASS')
print(f'current+old MID1 Hero hydration/reducer/timer evidence pinned; real Hero duplicate-target tables={dups}; candidate key49/contribution/routing translation matches')
