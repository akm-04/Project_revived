#!/usr/bin/env python3
from pathlib import Path
import hashlib, os, re, sys, zipfile

ROOT=Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def sha(b): return hashlib.sha256(b).hexdigest()
def ep(name): return Path(os.environ.get(name,''))

current=ep('GXB_CA5_4_CURRENT_ARCHIVE')
old=ep('GXB_CA5_4_OLD_ARCHIVE')
v1=ep('GXB_CA5_4_V1_ARCHIVE')
native=ep('GXB_CA5_4_NATIVE_ARCHIVE')
expected_archives={
    'current':(current,'c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'),
    'old':(old,'d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'),
    'v1':(v1,'31729d5c5e4509c2c89eaa1e8203cf1570afe87e18ed2610b944e457a9946b15'),
    'native':(native,'fcc0f03e5973dd41a190a4bd390a8c4c5185f5f7cf2d4eeb0bcad696cfee7517'),
}
for label,(p,want) in expected_archives.items():
    req(p.is_file(),f'exact {label} oracle archive missing')
    if p.is_file(): req(sha(p.read_bytes())==want,f'{label} archive identity drift')

current_expected={
'app-assets/output/assets/src_64/app/model/SelfPlayer.lua':'163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4',
'app-assets/output/assets/src_64/app/windows/HeroSettingWindow.lua':'c77b72f9ff110ff92c4cb1ccd2afb0481aa1301f64558bea9bf28ec9a8cc66a0',
'app-assets/output/assets/src_64/app/windows/SelectTeamNewWindow.lua':'0fabc7b70c2acf48765c41b414e3cae7504f567cb6fbe344b0f98456ed18667a',
'app-assets/output/assets/src_64/app/windows/HeroPresetWindow.lua':'5c969bd32cb1c3a16316e7c49539acd562601dd8ec3a938ea2fe57358c6d9244',
'app-assets/output/assets/src_64/app/windows/HeroListWindow.lua':'6128b1924caf12a1b191c9a59defabc9bbfdb0b98666f7885da20b1a7245b8ac',
'app-assets/output/assets/src_64/app/common/network/mid.lua':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
'app-assets/output/assets/src_64/app/common/WindowConst.lua':'01f477067e13f5cd0d5404845ff92b89928521eded837217c80fb5eb83bc4f4e',
'app-assets/output/assets/src_64/data/tables/window.lua':'c7f2fcc6637ab170d5f802904c5ee971eedac33e7fac7112d1afc1675b3a21e3',
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
                if '/src_64/' in member:
                    peer=member.replace('/src_64/','/src_32/')
                    req(peer in names,f'src_32 peer missing {peer}')
                    if peer in names: req(z.read(peer)==b,f'src_32/src_64 drift {Path(member).name}')
        literal_open=[]
        for name in names:
            if '/src_64/' not in name or not name.endswith('.lua'):
                continue
            b=z.read(name)
            if b'openWindow("hero_setting"' in b or b"openWindow('hero_setting'" in b:
                literal_open.append(name)
        req(not literal_open,f'bounded literal hero_setting opener appeared: {literal_open[:5]}')

mid=texts.get('mid.lua','')
selfp=texts.get('SelfPlayer.lua','')
setting=texts.get('HeroSettingWindow.lua','')
select=texts.get('SelectTeamNewWindow.lua','')
windowtab=texts.get('window.lua','')
req(re.search(r'DISMISS_HERO\s*=\s*66\b',mid) is not None,'current MID66 identity drift')
for tok in ['function var_0_0.dismissHero','xyd.mid.DISMISS_HERO','arg_171_0:deleteHero(arg_171_1.partner_id)','arg_172_0 == xyd.error.OK']:
    req(tok in selfp,f'current SelfPlayer dismiss evidence missing {tok!r}')
for tok in ['function var_0_0.dismissHero','partner_id = arg_13_0.heroID_','isRep() == 1','isLock() == 1','isDefenceHero(arg_12_0.heroID_)']:
    req(tok in setting,f'current HeroSetting evidence missing {tok!r}')
for tok in ['"hero_setting"','"HeroSettingWindow"']:
    req(tok in windowtab,f'current registered HeroSetting evidence missing {tok!r}')
for tok in ['function var_0_0.getSaveTeams','if var_241_10 then','teamName = var_241_7','pet = var_241_13']:
    req(tok in selfp,f'current saved-preset projection evidence missing {tok!r}')
for tok in ['function var_0_0.initPresetTeams','selfPlayer:getSaveTeams()','function var_0_0.loadPreFormation','xyd.db.formation:getFormationData','xyd.SelectTeamType.HERO_PRESET']:
    req(tok in select,f'current preset/mode separation evidence missing {tok!r}')

if old.is_file():
    with zipfile.ZipFile(old) as z:
        names=set(z.namelist())
        expected={
            'src/app/common/network/mid.lua':'c10ab0d38105be79201b6b1682a7fcb36eafa7f09b76002c5b9bf599a968d942',
            'src/app/model/SelfPlayer.lua':'aee7827573d82bb36338512e908eb6883911f4996c6c85f1a6f8b826593def3a',
            'src/app/windows/HeroSettingWindow.lua':'c77b72f9ff110ff92c4cb1ccd2afb0481aa1301f64558bea9bf28ec9a8cc66a0',
        }
        oldtexts={}
        for member,want in expected.items():
            req(member in names,f'old member missing {member}')
            if member in names:
                b=z.read(member); req(sha(b)==want,f'old member hash drift {member}'); oldtexts[Path(member).name]=b.decode('utf-8','replace')
        req(re.search(r'DISMISS_HERO\s*=\s*66\b',oldtexts.get('mid.lua','')) is not None,'old MID66 identity drift')
        req('function var_0_0.dismissHero' in oldtexts.get('SelfPlayer.lua',''),'old dismiss wrapper missing')

if v1.is_file():
    with zipfile.ZipFile(v1) as z:
        member='gxb_backend/dispatch/engine_dispatcher.py'
        req(member in z.namelist(),'frozen V1 dispatcher missing')
        if member in z.namelist():
            b=z.read(member); req(sha(b)=='6f0a61ed76ef78760037c22e67473e56018194831d7f00ea231b075c7192c26a','frozen V1 dispatcher identity drift')
            t=b.decode('utf-8','replace')
            for tok in ['Status-only / safe acknowledgement commands','More semantic state','"DISMISS_HERO"','h[mid] = self.system.status_only']:
                req(tok in t,f'frozen V1 bounded status-only evidence missing {tok!r}')

# Candidate-bound narrow translation.
dto=(ROOT/'internal/application/characterasset/saved_preset_reference_state.go').read_text()
reader=(ROOT/'internal/application/charactersavedpreset/reference_state.go').read_text()
guard=(ROOT/'internal/application/charactersavedpreset/reference_guard.go').read_text()
sql=(ROOT/'sql/character/preset.sql').read_text()
for tok in ['SavedPresetReferenceState','StateVersion','SavedPresetReferenceLoadout','[]character.HeroRef','*character.PetRef']:
    req(tok in dto,f'candidate reference DTO missing {tok!r}')
for tok in ['ReadSavedPresetAggregateTx','StateVersion: agg.Root.StateVersion']:
    req(tok in reader,f'candidate reference reader missing {tok!r}')
for tok in ['ca5.saved-presets','PreflightHeroRemovalTx','PreflightPetRemovalTx','SavedPresetRootLockKey','SavedPresetReferencesHeroTx','SavedPresetReferencesPetTx','ErrReferenceInUse']:
    req(tok in guard,f'candidate reference guard missing {tok!r}')
for tok in ['SavedPresetReferencesHero','SavedPresetReferencesPet','SELECT EXISTS']:
    req(tok in sql,f'candidate reference query missing {tok!r}')
for forbidden in ['DISMISS_HERO','isDefenceHero','isRep()','isLock()']:
    req(forbidden not in guard+reader+dto,f'candidate promoted client-only dismissal policy {forbidden!r}')
req('Name string' not in dto,'candidate reference DTO promoted preset presentation name')
req('17.formation' not in guard+reader+dto,'candidate claimed universal formation')

if errs:
    print('CA5-4 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA5-4 SOURCE ORACLE CHECK: PASS')
print('current/old/V1/native identities pinned; MID66 UI/wrapper evidence remains bounded, saved presets remain mode-adapted source loadouts, and candidate activates only reverse guard/reference-state seams')
