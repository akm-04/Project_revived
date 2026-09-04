#!/usr/bin/env python3
"""Pass150 Phase B1/B2 regression: typed Recharge packs + Commerce VIP progression."""
from __future__ import annotations
import copy, json, os, subprocess, sys, tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
DATA=ROOT/'data'; SRC_RAW=os.environ.get('GXB_SRC64','').strip()

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.recharge_catalog import RechargeSourceCatalog
from gxb_backend.state.commerce_purchase import PurchaseLimitReached, UnsupportedPurchaseProduct
from gxb_backend.state.commerce_service import CommerceStateError
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.request_services import RequestServices

CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(v,m):
    if not v: raise AssertionError(m)

def make(save=None):
    p=apply_established_profile(PlayerState())
    p.account_uid='15010001'; p.player_id='15010001'; p.player_name='Pass150 Recharge'; p.vip=0; p.charge=0; p.crystal=0; p.mana=0
    p.commerce_state={}; p.backpack_items=[]
    commits=[]
    cb=save if save is not None else lambda: commits.append(1)
    s=RequestServices(p,DATA,cb,catalog=CATALOG)
    return p,s,commits

def ids(rows): return {int(r['charge_id']) for r in rows}

def test_fresh_source_metadata_and_typed_counts():
    if SRC_RAW:
        with tempfile.TemporaryDirectory(prefix='pass150_b12_') as td:
            out=Path(td)/'meta.json'
            subprocess.run([sys.executable,str(ROOT/'tools/build_recharge_giftbag_meta.py'),'--src64',SRC_RAW,'--output',str(out)],check=True)
            req(out.read_bytes()==(DATA/'recharge_giftbag_source_meta.json').read_bytes(),'giftbag metadata stale versus effective src64')
    c=RechargeSourceCatalog(DATA)
    req(len(c.giftbag_products())==284,'page2 census drift')
    req(len(c.fixed_b2_giftbags())==265,'B2 fixed census drift')
    caps={p.capability for p in c.giftbag_products()}
    req({'B2_FIXED_NONHERO','B3_RANDOM_NONHERO','DEFER_GENERATED_UNIQUE','FAIL_CLOSED_MISSING_GIFT'}<=caps,'capability partition incomplete')

def test_all_fixed_rewards_preflight_canonical_owners():
    _p,s,_=make(); count=0
    for product in s.recharge_source_catalog.fixed_b2_giftbags():
        plan=s.commerce_settlement.giftbag_policy.plan(product,{'charge_count':0})
        s.rewards.validate(plan.rewards); count+=1
    req(count==265,f'exhaustive fixed preflight drift {count}')

def test_mid354_visibility_chain_and_reactivation():
    p,s,_=make(); before=s.recharge_catalog.query_charge_data()['giftbags']; visible=ids(before)
    req(90002002 in visible and 90002003 not in visible,'source chain initial visibility wrong')
    req(90002170 in visible,'source-complete is_open=1 product not EOL-reactivated')
    req(90002112 in visible,'B3 random product should now be advertised')
    req(90002373 not in visible,'Hero product advertised too early')
    # Missing gift representative should never be advertised.
    missing=next(x.charge_id for x in s.recharge_source_catalog.giftbag_products() if x.capability=='FAIL_CLOSED_MISSING_GIFT')
    req(missing not in visible,'source-incomplete product advertised')
    s.commerce_settlement.settle({'intent_id':'chain-1','charge_id':90002002,'platform':'lua_preservation'})
    after=ids(s.recharge_catalog.query_charge_data()['giftbags'])
    req(90002002 not in after and 90002003 in after,'one-shot chain did not advance')

def test_fixed_pack_crystal_does_not_imply_vip():
    p,s,_=make(); result=s.commerce_settlement.settle({'intent_id':'no-vip','charge_id':90002170,'platform':'lua_preservation'})
    req(p.crystal==10,'gift crystal not settled')
    req(p.charge==0 and p.vip==0,'Pack crystal incorrectly granted VIP progression')
    req(result.recharge_event['params']['economy'].get('crystal')==10,'cumulative economy projection missing')
    req(result.recharge_event['params']['items'],'gift item awards missing')

def test_explicit_gift_vip_exp_and_repeatable():
    p,s,_=make()
    first=s.commerce_settlement.settle({'intent_id':'vip-1','charge_id':90002287,'platform':'lua_preservation'})
    req(p.crystal==0,'vip-only gift fabricated crystal')
    req(p.charge==475 and p.vip==2,'explicit gift.vip_exp did not derive VIP')
    req(first.settlement['vip_progression_delta']==475,'vip delta settlement metadata')
    req(90002287 in ids(s.recharge_catalog.query_charge_data()['giftbags']),'repeatable pack disappeared')
    s.commerce_settlement.settle({'intent_id':'vip-2','charge_id':90002287,'platform':'lua_preservation'})
    req(p.charge==950 and p.vip==3,'repeatable explicit VIP progression incorrect')

def test_vip_primitive_requires_uow_and_replay_exactly_once():
    p,s,_=make()
    try:
        s.commerce.grant_vip_progression(30); bad=False
    except CommerceStateError: bad=True
    req(bad and p.charge==0,'VIP progression mutated outside UoW')
    first=s.commerce_settlement.settle({'intent_id':'replay','charge_id':90002287,'platform':'lua_preservation'})
    state=(p.charge,p.vip,s.commerce.product_history(90002287)['charge_count'])
    replay=s.commerce_settlement.settle({'intent_id':'replay','charge_id':90002287,'platform':'lua_preservation'})
    req(replay.replayed and (p.charge,p.vip,s.commerce.product_history(90002287)['charge_count'])==state,'giftbag replay mutated twice')
    req(replay.recharge_event==first.recharge_event,'replay response drift')

def test_deferred_products_fail_authorization():
    _p,s,_=make()
    # B3 random Pack is now supported; Hero and source-incomplete products remain gated.
    for cid in (90002373,):
        try:
            s.commerce_settlement.settle({'intent_id':f'defer-{cid}','charge_id':cid,'platform':'lua_preservation'}); ok=False
        except UnsupportedPurchaseProduct: ok=True
        req(ok,f'deferred charge_id {cid} authorized')
    missing=next(x.charge_id for x in s.recharge_source_catalog.giftbag_products() if x.capability=='FAIL_CLOSED_MISSING_GIFT')
    try:
        s.commerce_settlement.settle({'intent_id':f'defer-{missing}','charge_id':missing,'platform':'lua_preservation'}); ok=False
    except UnsupportedPurchaseProduct: ok=True
    req(ok,'source-incomplete Recharge product authorized')

def test_commit_failure_rolls_back_items_economy_vip_history_receipt():
    def fail(): raise OSError('pass149 simulated durable write failure')
    p,s,_=make(fail); before=copy.deepcopy(vars(p))
    try:
        s.commerce_settlement.settle({'intent_id':'rollback','charge_id':90002223,'platform':'lua_preservation'}); failed=False
    except OSError: failed=True
    req(failed,'simulated save failure did not surface')
    req(vars(p)==before,'giftbag UoW did not rollback whole player')
    req(s.uow.get_receipt('commerce_purchase','rollback') is None,'failed giftbag left receipt')

def test_composition_identity():
    _p,s,_=make()
    req(s.commerce_settlement.entitlements is s.commerce,'Commerce owner split')
    req(s.commerce_settlement.economy is s.economy_ledger,'Economy owner split')
    req(s.commerce_settlement.rewards is s.rewards,'RewardTransaction owner split')
    req(s.commerce_settlement.uow is s.uow,'UoW owner split')
    req(s.commerce_settlement.giftbag_availability is s.recharge_catalog.giftbag_availability,'availability policy split')

def main():
    tests=[test_fresh_source_metadata_and_typed_counts,test_all_fixed_rewards_preflight_canonical_owners,test_mid354_visibility_chain_and_reactivation,test_fixed_pack_crystal_does_not_imply_vip,test_explicit_gift_vip_exp_and_repeatable,test_vip_primitive_requires_uow_and_replay_exactly_once,test_deferred_products_fail_authorization,test_commit_failure_rolls_back_items_economy_vip_history_receipt,test_composition_identity]
    for t in tests: t(); print('PASS',t.__name__)
    print(f'PASS Pass150 Recharge Phase B1/B2 regression ({len(tests)}/{len(tests)})')
if __name__=='__main__': main()
