#!/usr/bin/env python3
from pathlib import Path
import hashlib, json, os, re, sys, zipfile

R = Path(__file__).resolve().parents[1]
errs=[]
def req(ok,msg):
    if not ok: errs.append(msg)
def sha(b): return hashlib.sha256(b).hexdigest()
def env_path(name): return Path(os.environ.get(name,''))

current=env_path('GXB_CA4_5_CURRENT_ARCHIVE')
old=env_path('GXB_CA4_5_OLD_ARCHIVE')
v1=env_path('GXB_CA4_5_V1_ARCHIVE')
CURRENT_SHA='c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf'
OLD_SHA='d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1'
V1_SHA='31729d5c5e4509c2c89eaa1e8203cf1570afe87e18ed2610b944e457a9946b15'
for label,p,want in [('current',current,CURRENT_SHA),('old',old,OLD_SHA),('v1',v1,V1_SHA)]:
    req(p.is_file(),f'exact {label} oracle archive missing')
    if p.is_file(): req(sha(p.read_bytes())==want,f'{label} archive identity drift: {sha(p.read_bytes())}')

expected={
'app-assets/output/assets/src_64/app/common/network/mid.lua':'026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af',
'app-assets/output/assets/src_64/app/model/SuperHero.lua':'b127c2cbef327d3142031bf30daa0af1b45997c6da82fba946d641a86783d622',
'app-assets/output/assets/src_64/app/windows/SuperEquipEnhanceWindow.lua':'3f74a162d385dd02af48f69cc7a79332d28e58cb2f348d51da52b7fae11d0046',
'app-assets/output/assets/src_64/app/windows/SuperEquipConfirmWindow.lua':'2bf3d53020dfb49fd4499d0b7722bdde0269836f1b517ec5e8339368ab89c22e',
'app-assets/output/assets/src_64/app/windows/HeroMainWindow.lua':'473b72ec14a81d01d6dbdaa19f92c3d78900f40ca34fa5c8cf46585b76d65414',
'app-assets/output/assets/src_64/data/tables/super_partner_star.lua':'b2c73a59b11db192aad61a48eba26f0cf57f735369ef03f4b729100f25c64d90',
'app-assets/output/assets/src_64/data/tables/super_equip_enhance.lua':'2ade30c55e102057e5c2833e58b66a7d8a684259f0e74f941bc28d5c3cd6af53',
'app-assets/output/assets/src_64/data/tables/super_partner.lua':'ddee186ee41361a3674d4764be68efec01fad32d288c9dc84c552df6f1b770ea',
}
texts={}
if current.is_file():
    with zipfile.ZipFile(current) as z:
        names=set(z.namelist())
        for member,want in expected.items():
            req(member in names,f'current source member missing: {member}')
            if member in names:
                b=z.read(member); req(sha(b)==want,f'current source hash drift {member}: {sha(b)}')
                texts[Path(member).name]=b.decode('utf-8','replace')
mid=texts.get('mid.lua',''); superhero=texts.get('SuperHero.lua',''); enh=texts.get('SuperEquipEnhanceWindow.lua',''); confirm=texts.get('SuperEquipConfirmWindow.lua',''); mainui=texts.get('HeroMainWindow.lua','')
req(re.search(r'SET_HERO_EQUIP\s*=\s*54\b',mid) is not None,'MID54 identity drift')
req(re.search(r'ONE_CLICK_EQUIP\s*=\s*62\b',mid) is not None,'MID62 identity drift')
req(re.search(r'UPGRADE_SUPER_EQUIP\s*=\s*304\b',mid) is not None,'MID304 identity drift')
for tok in ['function var_0_3.getEquipLevel','return arg_129_0.equips_[arg_129_1] - 1','UPGRADE_SUPER_EQUIP','enhance_times','equip_index','partner_id']:
    req(tok in superhero or tok in enh,f'current Super equipment evidence missing {tok!r}')
for tok in ['arg_159_0.equips_[arg_159_1.equip_index] = arg_159_0.equips_[arg_159_1.equip_index] + arg_159_1.enhance_times']:
    req(tok in superhero,'MID304 client raw-slot increment evidence missing')
req('selfPlayer:getBackpack():removeItem' in enh,'MID304 duplicate-item local debit evidence missing')
req('superEquipEnhance:needNum(math.ceil(iter_24_0 / 10))' in enh,'MID304 tier cost loop evidence missing')
req('button_onekeyequips"):setVisible(false)' in mainui,'Super MID62 stock-unreachable UI guard missing')

if old.is_file():
    with zipfile.ZipFile(old) as z:
        oldmid=z.read('src/app/common/network/mid.lua').decode('utf-8','replace') if 'src/app/common/network/mid.lua' in z.namelist() else ''
        req(oldmid!='','old-client mid.lua missing')
        req('UPGRADE_SUPER_EQUIP' not in oldmid,'old client unexpectedly discriminates MID304')
if v1.is_file():
    with zipfile.ZipFile(v1) as z:
        names=set(z.namelist())
        for member in ['gxb_backend/state/hero_advanced_progression_repository.py','gxb_backend/state/hero_equipment_repository.py','source_evidence/src_64/app/model/SuperHero.lua']:
            req(member in names,f'V1 bounded corroborative member missing: {member}')
        if 'gxb_backend/state/hero_advanced_progression_repository.py' in names:
            t=z.read('gxb_backend/state/hero_advanced_progression_repository.py').decode('utf-8','replace')
            req('spirit' in t.lower() or 'horcrux' in t.lower(),'V1 Horcrux/spirit bounded evidence missing')

manifest=json.loads((R/'internal/content/builtin/generated/manifest.json').read_text())
req(manifest.get('revision_id')=='6ba22017fab270d38fbb68ab30bea0afe61442a979f74084fd7f5027a184e116','CA4-5 generated content revision drift')
req('SUPER_EQUIPMENT_CA4_5' in manifest.get('enabled_capabilities',[]),'Super equipment capability absent')
diag=manifest.get('diagnostics',{})
req(diag.get('super_equipment_positions')==84,'Super position count drift')
req(diag.get('super_equipment_unique_base_items')==12,'Super base-item count drift')
req(diag.get('super_equipment_enhancement_caps')==10,'Super cap row count drift')
req(diag.get('super_equipment_enhancement_tiers')==6,'Super tier row count drift')
cat=json.loads((R/'internal/content/builtin/generated/super_equipment_catalog.json').read_text())
positions=cat.get('positions',[]); caps=cat.get('enhancement_caps',[]); tiers=cat.get('enhancement_tiers',[])
req(len(positions)==84 and len({p.get('hero_table_id') for p in positions})==14 and len({p.get('item_id') for p in positions})==12,'generated Super topology drift')
req([(x.get('star'),x.get('max_enhancement'),x.get('effective_client_reachable')) for x in caps]==[(1,10,True),(2,10,True),(3,10,True),(4,10,True),(5,10,True),(6,20,True),(7,30,True),(8,40,True),(9,50,False),(10,60,False)],'generated Super cap policy drift')
req([(x.get('tier'),x.get('min_star'),x.get('duplicate_count'),x.get('effective_client_reachable')) for x in tiers]==[(1,1,1,True),(2,6,1,True),(3,7,1,True),(4,8,1,True),(5,9,2,False),(6,10,2,False)],'generated Super tier policy drift')

svc=(R/'internal/application/characterhero/equipment_service.go').read_text()
dispatch=(R/'internal/adapters/stockruntime/hero_dispatcher.go').read_text()
main=(R/'cmd/gxb-api/main_postgres.go').read_text()
for tok in ['func (s Service) EnhanceSuperEquipment','heroEquipmentMID304SuperV1','SuperEquipmentPositionTx','SuperEquipmentCapTx','SuperEquipmentTierTx','DebitMaterialCostTx','SaveHeroStateTx']:
    req(tok in svc,f'MID304 product path missing {tok}')
sec=svc.split('func (s Service) EnhanceSuperEquipment',1)[1].split('func (s Service) loadOneKeyContentTx',1)[0] if 'func (s Service) EnhanceSuperEquipment' in svc else ''
req('ScalarMaterialCost' not in sec and '"mana"' not in sec.lower(),'MID304 product path invents Mana/scalar debit')
req('.Derive(' not in sec,'MID304 product path unexpectedly consumes RNG entropy')
req('spirit' not in sec.lower() and 'horcrux' not in sec.lower(),'MID304 product path leaks Spirit/Horcrux lifecycle')
for tok in ['case 304:','onlyStockGameplayParams(req.Envelope.Params, "partner_id", "equip_index", "enhance_times")','EnhanceSuperEquipment(ctx, actor','Body: map[string]any{}']:
    req(tok in dispatch,f'MID304 stock wire missing {tok}')
route=re.search(r'for _, mid := range \[\]uint16\{([^}]*)\} \{\s*mustRegister\(mid, heroD\)',main,re.S)
req(bool(route) and re.search(r'(^|\D)304(\D|$)',route.group(1)) is not None,'MID304 production registration missing')

if errs:
    print('CA4-5 SOURCE ORACLE CHECK: FAIL')
    for e in errs: print(' -',e)
    sys.exit(1)
print('CA4-5 SOURCE ORACLE CHECK: PASS')
print('current source identities and Super raw-slot/MID304/tier facts remain pinned; old client stays non-discriminating; V1 Horcrux evidence stays bounded; product path is deterministic, no-Mana, no-RNG, no-Horcrux')
