#!/usr/bin/env python3
from pathlib import Path
import hashlib, os, re, sys, zipfile

ROOT = Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def sha(b): return hashlib.sha256(b).hexdigest()
def env_path(name): return Path(os.environ.get(name,''))

current=env_path('GXB_CA5_3_CURRENT_ARCHIVE')
old=env_path('GXB_CA5_3_OLD_ARCHIVE')
v1=env_path('GXB_CA5_3_V1_ARCHIVE')
CURRENT_SHA='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
OLD_SHA='d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'
V1_SHA='31729d5c5e4509c2c89eaa1e8203cf1570afe87e18ed2610b944e457a9946b15'
for label,p,want in [('current',current,CURRENT_SHA),('old',old,OLD_SHA),('v1',v1,V1_SHA)]:
    req(p.is_file(),f'exact {label} oracle archive missing')
    if p.is_file(): req(sha(p.read_bytes())==want,f'{label} archive identity drift: {sha(p.read_bytes())}')

cur_expected={
'app-assets/output/assets/src_64/app/common/network/Backend.lua':'95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840',
'app-assets/output/assets/src_64/app/common/network/mid.lua':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
'app-assets/output/assets/src_64/app/model/SelfPlayer.lua':'163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4',
'app-assets/output/assets/src_64/app/windows/HeroListWindow.lua':'6128b1924caf12a1b191c9a59defabc9bbfdb0b98666f7885da20b1a7245b8ac',
'app-assets/output/assets/src_64/app/windows/HeroPresetWindow.lua':'5c969bd32cb1c3a16316e7c49539acd562601dd8ec3a938ea2fe57358c6d9244',
'app-assets/output/assets/src_64/app/windows/SaveTeamWindow.lua':'e3a3116681c9fb6cda49b3c9aa7c9595162ad62c3a92acf126872468cdd1dd60',
'app-assets/output/assets/src_64/app/windows/SelectTeamNewWindow.lua':'0fabc7b70c2acf48765c41b414e3cae7504f567cb6fbe344b0f98456ed18667a',
'app-assets/output/assets/src_64/app/windows/SelectTeamWindow.lua':'6d57e6bc7251060184190f7be14dcc9a277251673493a5b27e6c67c71cb96561',
}
texts={}
if current.is_file():
    with zipfile.ZipFile(current) as z:
        names=set(z.namelist())
        for member,want in cur_expected.items():
            req(member in names,f'current source member missing: {member}')
            if member in names:
                b=z.read(member); req(sha(b)==want,f'current source hash drift {member}: {sha(b)}')
                texts[Path(member).name]=b.decode('utf-8','replace')
                peer=member.replace('/src_64/','/src_32/')
                req(peer in names,f'src_32 peer missing: {peer}')
                if peer in names: req(z.read(peer)==b,f'src_32/src_64 drift for {Path(member).name}')
        window='app-assets/output/assets/src_64/app/common/WindowConst.lua'
        table='app-assets/output/assets/src_64/data/tables/window.lua'
        req(window in names and table in names,'current window routing evidence missing')
        if window in names: texts['WindowConst.lua']=z.read(window).decode('utf-8','replace')
        if table in names: texts['window.lua']=z.read(table).decode('utf-8','replace')

mid=texts.get('mid.lua',''); backend=texts.get('Backend.lua',''); selfp=texts.get('SelfPlayer.lua','')
hero_list=texts.get('HeroListWindow.lua',''); legacy=texts.get('HeroPresetWindow.lua',''); save=texts.get('SaveTeamWindow.lua','')
newsel=texts.get('SelectTeamNewWindow.lua',''); oldsel=texts.get('SelectTeamWindow.lua',''); windowconst=texts.get('WindowConst.lua',''); windowtab=texts.get('window.lua','')
req(re.search(r'SAVE_TEAM\s*=\s*1793\b',mid) is not None,'current MID1793 identity drift')
for tok in ['function var_0_0.heroPreset','xyd.mid.SAVE_TEAM','save_team','save_team_name','save_pet','arg_243_0 == xyd.error.OK']:
    req(tok in selfp,f'current SelfPlayer MID1793 callback evidence missing {tok!r}')
for tok in ['team_str = var_27_6','team_name_str = var_27_7','pet_str = var_27_8','selfPlayer:heroPreset']:
    req(tok in hero_list,f'current modern delete evidence missing {tok!r}')
for tok in ['team_str = var_14_4','team_name_str = var_14_5','player:heroPreset']:
    req(tok in legacy,f'current legacy delete evidence missing {tok!r}')
legacy_block=legacy[legacy.find('local var_14_6 = {'):legacy.find('arg_12_0.player:heroPreset',legacy.find('local var_14_6 = {'))] if 'local var_14_6 = {' in legacy else ''
req('pet_str' not in legacy_block,'legacy HeroPresetWindow delete unexpectedly carries pet_str')
for tok in ['team_str = var_7_0','team_name_str = var_7_1','pet_str = var_7_2','player:heroPreset']:
    req(tok in save,f'current save-team full triple evidence missing {tok!r}')
req('xyd.WindowName.SelectTeamWnd = "battle_select_team"' in windowconst,'effective SelectTeamWnd routing drift')
for tok in ['"battle_select_team"','"SelectTeamNewWindow"','"select_team_old"','"SelectTeamWindow"']:
    req(tok in windowtab,f'window table routing evidence missing {tok!r}')
new_anchor='elseif arg_87_0.type == xyd.SelectTeamType.HERO_PRESET then'
new_start=newsel.find(new_anchor)
new_end=newsel.find('\n\t\telseif arg_87_0.type ==',new_start+len(new_anchor)) if new_start>=0 else -1
new_block=newsel[new_start:new_end] if new_start>=0 and new_end>new_start else ''
for tok in ['pet_id = var_93_1','var_93_1 = 0','openWindow("save_team"']:
    req(tok in new_block,f'effective SelectTeamNew HERO_PRESET Pet evidence missing {tok!r}')
old_anchor='elseif arg_76_0.type == xyd.SelectTeamType.HERO_PRESET then'
old_start=oldsel.find(old_anchor)
old_end=oldsel.find('\n\t\telseif arg_76_0.type ==',old_start+len(old_anchor)) if old_start>=0 else -1
old_block=oldsel[old_start:old_end] if old_start>=0 and old_end>old_start else ''
req('openWindow("save_team"' in old_block,'retained SelectTeamWindow HERO_PRESET branch missing')
req('pet_id =' not in old_block,'retained SelectTeamWindow unexpectedly gained preset pet_id')
req('json.encode(arg_23_2)' in backend and 'arg_23_2 = arg_23_2 or {}' in backend,'Backend direct request-table JSON encoding evidence drift')

if old.is_file():
    with zipfile.ZipFile(old) as z:
        names=set(z.namelist())
        old_expected={
            'src/app/common/network/mid.lua':'c10ab0d38105be79201b6b1682a7fcb36eafa7f09b76002c5b9bf599a968d942',
            'src/app/model/SelfPlayer.lua':'aee7827573d82bb36338512e908eb6883911f4996c6c85f1a6f8b826593def3a',
            'src/app/windows/HeroPresetWindow.lua':'b7da31c3918f368e3ad862d51b0eb2cc867dd04ffe5f54e1d2b7b8f652cb0130',
            'src/app/windows/SaveTeamWindow.lua':'02e74e4eee81a2b9e5b03f04e8e55de974be1bd38c3672eb355d51fbf27c6758',
        }
        oldtexts={}
        for member,want in old_expected.items():
            req(member in names,f'old source member missing: {member}')
            if member in names:
                b=z.read(member); req(sha(b)==want,f'old source hash drift {member}: {sha(b)}'); oldtexts[Path(member).name]=b.decode('utf-8','replace')
        req(re.search(r'SAVE_TEAM\s*=\s*1793\b',oldtexts.get('mid.lua','')) is not None,'old client MID1793 identity drift')
        req('pet_str' not in oldtexts.get('SaveTeamWindow.lua',''),'old client unexpectedly has saved-pet full write')
        req('pet_str' not in oldtexts.get('HeroPresetWindow.lua',''),'old client unexpectedly has saved-pet legacy delete')

if v1.is_file():
    with zipfile.ZipFile(v1) as z:
        member='gxb_backend/handlers/heroes.py'
        req(member in z.namelist(),'frozen V1 save_team corroborative handler missing')
        if member in z.namelist():
            b=z.read(member); req(sha(b)=='62831702ec042e99e7c50509725233b53963b559c07364bc4f96a6ceba36ea34','frozen V1 handler identity drift')
            t=b.decode('utf-8','replace')
            for tok in ['def save_team','HeroPresetWindow has at least one delete path that omits pet_str','req["pet_str"] if "pet_str" in req else repo.player.save_pet']:
                req(tok in t,f'frozen V1 bounded corroborative evidence missing {tok!r}')

# Candidate-bound implementation guard: ensure source evidence was translated narrowly.
codec=(ROOT/'internal/application/charactersavedpreset/command_codec.go').read_text()
svc=(ROOT/'internal/application/charactersavedpreset/service.go').read_text()
dispatch=(ROOT/'internal/adapters/stockruntime/saved_preset_dispatcher.go').read_text()
for tok in ['PetPresent','ParseFullCommand','ResolveLegacyDelete','ErrAmbiguousLegacyDelete']:
    req(tok in codec,f'candidate codec missing {tok}')
for tok in ['UnionReferences','RetryDefiniteAbort: true','.Covers(','character-saved-preset','pet_present']:
    req(tok in svc,f'candidate service missing {tok}')
for tok in ['req.Envelope.MID != 1793','team_str','team_name_str','pet_str','"save_team"','"save_team_name"','"save_pet"']:
    req(tok in dispatch,f'candidate stock wire missing {tok}')
for invented in ['MAX_TEAM_MEMBER_NUM','presetNum(','PRESET_TEAM_NAME_INVALID']:
    req(invented not in codec+svc,f'candidate promoted UI-only policy marker {invented!r}')

if errs:
    print('CA5-3 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA5-3 SOURCE ORACLE CHECK: PASS')
print('current/old/V1 oracle identities remain pinned; effective current full/modern-delete triple and retained pet-less legacy delete remain discriminated; candidate does not promote UI/V1 policy into server truth')
