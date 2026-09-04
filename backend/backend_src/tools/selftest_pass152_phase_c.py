#!/usr/bin/env python3
"""Pass152 Phase C synthetic EOL Recharge + OTA 1.631.9 acceptance."""
from __future__ import annotations
import copy, hashlib, json, sys, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
DATA=ROOT/'data'
from gxb_backend.content import GameDataCatalog
from gxb_backend.state.commerce_purchase import UnsupportedPurchaseProduct
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.request_services import RequestServices
CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(v,m):
    if not v: raise AssertionError(m)

def make(*, hero_table=None, skin_ids=None):
    p=apply_established_profile(PlayerState()); p.player_id='15200001'; p.account_uid='15200001'; p.commerce_state={}; p.backpack_items=[]
    if hero_table:
        p.heroes={'90001':{'partner_id':90001,'table_id':int(hero_table),'star':10,'lev':100,'skin_ids':copy.deepcopy(skin_ids or []),'current_skin_id':0,'illusion_skin_id':0}}
    else: p.heroes={}
    commits=[]; s=RequestServices(p,DATA,lambda:commits.append('commit'),catalog=CATALOG)
    return p,s,commits

def eol_ids(s): return {x.charge_id for x in s.recharge_source_catalog.eol_products()}

def test_src64_contract_and_ota_payload():
    src=Path('/mnt/data/_reorient150/assets/app-assets/output/assets/src_64')
    sp=(src/'app/model/SelfPlayer.lua').read_text(encoding='utf-8')
    gv=(src/'app/windows/GiftViewWindow.lua').read_text(encoding='utf-8')
    ut=(src/'app/common/utils.lua').read_text(encoding='utf-8')
    req('arg_175_1.params.params.skin_ids' in sp and 'remove_item or 1' in sp,'source Recharge skin callback drift')
    req('xyd.androidPurchase' in gv and 'xyd.sdkPurchase' in gv,'source GiftView purchase boundary drift')
    req('function xyd.version()' in ut and 'USER_DEFAULTS_VERSION_KEY' in ut,'source resource-version contract drift')
    manifest=json.loads((ROOT/'local_assets/update_manifest.json').read_text())
    req(manifest['version']=='1.631.9' and manifest['package']=='gxb-local-1.631.9.zip','OTA version/package drift')
    vol=ROOT/'local_assets/updates/gxb-local-1.631.9.zip.001'; b=vol.read_bytes()
    req(len(b)==manifest['size'] and hashlib.md5(b).hexdigest()==manifest['md5'],'OTA descriptor hash/size drift')
    with zipfile.ZipFile(vol) as z:
        req(len(z.namelist())==138,'OTA cumulative entry count drift')
        for arch in ('src_32','src_64'):
            gb=z.read(f'{arch}/data/tables/giftbag.lua').decode('utf-8-sig')
            gf=z.read(f'{arch}/data/tables/gift.lua').decode('utf-8-sig')
            utils=z.read(f'{arch}/app/common/utils.lua').decode('utf-8-sig')
            req(sum(1 for cid in range(97000001,97000263) if f'"{cid}"' in gb)==262,'skin giftbag rows missing')
            req(sum(1 for cid in range(97002001,97002011) if f'"{cid}"' in gb)==10,'element giftbag rows missing')
            req(sum(1 for gid in range(97100001,97100263) if f'"{gid}"' in gf)==262,'skin gift rows missing')
            req(sum(1 for gid in range(97102001,97102011) if f'"{gid}"' in gf)==10,'element gift rows missing')
            req('pass152ShouldBridge' in utils and 'form("resource_version", xyd.version())' in utils,'dynamic bridge/resource version missing')

def test_version_gate_and_mid354_activation():
    _p,s,_=make()
    synthetic=eol_ids(s)
    for version in (None,'','1.631.8','bad'):
        adv={int(x['charge_id']) for x in s.recharge_catalog.query_charge_data(version)['giftbags']}
        req(not (adv & synthetic),f'synthetic advertised under {version!r}')
    adv={int(x['charge_id']) for x in s.recharge_catalog.query_charge_data('1.631.9')['giftbags']}
    req(synthetic <= adv and len(adv & synthetic)==272,'OTA 1.631.9 did not advertise all fresh synthetic products')
    try:
        s.commerce_settlement.settle({'intent_id':'preota','charge_id':97002001,'platform':'lua_preservation'})
        ok=False
    except UnsupportedPurchaseProduct: ok=True
    req(ok,'synthetic purchase authorized without resource version')

def test_owned_girl_skin_direct_ownership_and_replay():
    base=make()[1].recharge_source_catalog.get_eol_product(97000001)
    p,s,commits=make(hero_table=int(base.metadata['skin_partner_id']))
    before=(p.crystal,p.charge,p.vip,s.stack_inventory.quantity(base.source_item_id))
    raw={'intent_id':'skin-owned-1','charge_id':base.charge_id,'platform':'lua_preservation','resource_version':'1.631.9'}
    result=s.commerce_settlement.settle(raw); params=result.recharge_event['params']; hero=s.heroes.get(90001)
    req(result.status=='COMMITTED' and not result.replayed,'skin owned Girl not committed')
    req(base.metadata['model_id'] in hero['skin_ids'],'permanent skin ownership not materialized')
    req(s.stack_inventory.quantity(base.source_item_id)==before[3],'direct ownership wrongly persisted physical skin item')
    req(params['items']==[{'table_id':base.source_item_id,'item_num':1}] and params['remove_item']==1,'source-shaped transient skin award missing')
    req(params['skin_ids']==hero['skin_ids'],'source-shaped skin_ids mismatch')
    req((p.crystal,p.charge,p.vip)==before[:3],'synthetic skin changed Crystal/charge/VIP')
    adv={int(x['charge_id']) for x in s.recharge_catalog.query_charge_data('1.631.9')['giftbags']}
    req(base.charge_id not in adv,'owned synthetic skin remained advertised')
    replay=s.commerce_settlement.settle(raw)
    req(replay.replayed and replay.status=='REPLAYED','receipt replay lost after product became unavailable')
    req(len(commits)==1,'skin commit/replay count wrong')

def test_skin_without_girl_grants_physical_item_and_hides():
    p,s,_=make(); product=s.recharge_source_catalog.get_eol_product(97000002); before=s.stack_inventory.quantity(product.source_item_id)
    r=s.commerce_settlement.settle({'intent_id':'skin-item-1','charge_id':product.charge_id,'platform':'lua_preservation','resource_version':'1.631.9'})
    params=r.recharge_event['params']
    req(s.stack_inventory.quantity(product.source_item_id)==before+1,'no-Girl skin did not use canonical stack grant')
    req('skin_ids' not in params and params['items']==[{'table_id':product.source_item_id,'item_num':1}],'no-Girl branch emitted wrong callback')
    adv={int(x['charge_id']) for x in s.recharge_catalog.query_charge_data('1.631.9')['giftbags']}
    req(product.charge_id not in adv,'physical-held skin remained advertised')

def test_elemental_repeatable_canonical_item_no_progression():
    p,s,commits=make(); product=s.recharge_source_catalog.get_eol_product(97002001); before=(p.crystal,p.charge,p.vip,s.stack_inventory.quantity(product.source_item_id))
    for n in (1,2):
        r=s.commerce_settlement.settle({'intent_id':f'elem-{n}','charge_id':product.charge_id,'platform':'lua_preservation','resource_version':'1.631.9'})
        req(r.settlement['product_kind']=='SYNTHETIC_EOL_ELEMENTAL','wrong elemental product kind')
    req(s.stack_inventory.quantity(product.source_item_id)==before[3]+2,'elemental repeat grant count wrong')
    req((p.crystal,p.charge,p.vip)==before[:3],'elemental synthetic purchase changed progression/economy')
    req(s.commerce.product_history(product.charge_id)['charge_count']==2,'elemental history count wrong')
    adv={int(x['charge_id']) for x in s.recharge_catalog.query_charge_data('1.631.9')['giftbags']}
    req(product.charge_id in adv,'repeatable elemental product disappeared')
    req(len(commits)==2,'elemental commits wrong')

def test_transaction_rollback_for_direct_skin_grant():
    product=make()[1].recharge_source_catalog.get_eol_product(97000003)
    p,s,commits=make(hero_table=int(product.metadata['skin_partner_id'])); s.heroes.normalize(); before=copy.deepcopy(vars(p))
    original=s.commerce.stage_completion_outbox
    def boom(*a,**k): raise RuntimeError('boom-after-materialization')
    s.commerce.stage_completion_outbox=boom
    try:
        try: s.commerce_settlement.settle({'intent_id':'skin-rollback','charge_id':product.charge_id,'platform':'lua_preservation','resource_version':'1.631.9'})
        except RuntimeError: pass
    finally: s.commerce.stage_completion_outbox=original
    req(vars(p)==before,'EOL direct skin rollback left partial mutation')
    req(not commits,'failed EOL purchase committed')

def main():
    tests=[test_src64_contract_and_ota_payload,test_version_gate_and_mid354_activation,test_owned_girl_skin_direct_ownership_and_replay,test_skin_without_girl_grants_physical_item_and_hides,test_elemental_repeatable_canonical_item_no_progression,test_transaction_rollback_for_direct_skin_grant]
    for t in tests:t(); print('PASS',t.__name__)
    print(f'PASS Pass152 Phase C ({len(tests)}/{len(tests)})')
if __name__=='__main__': main()
