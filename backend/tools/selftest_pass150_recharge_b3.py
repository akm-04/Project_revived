#!/usr/bin/env python3
"""Pass150 Phase B3: source-native random Recharge Pack over request ROS."""
from __future__ import annotations
import copy, json, os, subprocess, sys, tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
DATA=ROOT/'data'; SRC_RAW=os.environ.get('GXB_SRC64','').strip()

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.recharge_catalog import RechargeSourceCatalog
from gxb_backend.state.commerce_purchase import UnsupportedPurchaseProduct
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.random_outcome_service import EntropyDrawRequest
from gxb_backend.state.request_services import RequestServices

CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

class RecordingEntropy:
    def __init__(self, mode='last'):
        self.mode=mode; self.requests=[]
    def draw(self, req:EntropyDrawRequest)->int:
        self.requests.append(req)
        if self.mode=='first': return 0
        if self.mode=='last': return req.upper_exclusive-1
        return int(self.mode)%req.upper_exclusive

def req(v,m):
    if not v: raise AssertionError(m)

def make(entropy=None, save=None):
    p=apply_established_profile(PlayerState())
    p.account_uid='15000001'; p.player_id='15000001'; p.player_name='Pass150 Recharge'; p.vip=0; p.charge=0; p.crystal=0; p.mana=0
    p.commerce_state={}; p.backpack_items=[]
    commits=[]; cb=save if save is not None else lambda: commits.append(1)
    e=entropy or RecordingEntropy()
    s=RequestServices(p,DATA,cb,catalog=CATALOG,entropy_provider=e)
    return p,s,e,commits

def ids(rows): return {int(r['charge_id']) for r in rows}

def test_fresh_source_metadata_and_random_shape():
    if SRC_RAW:
        with tempfile.TemporaryDirectory(prefix='pass150_recharge_') as td:
            out=Path(td)/'meta.json'
            subprocess.run([sys.executable,str(ROOT/'tools/build_recharge_giftbag_meta.py'),'--src64',SRC_RAW,'--output',str(out)],check=True)
            req(out.read_bytes()==(DATA/'recharge_giftbag_source_meta.json').read_bytes(),'giftbag metadata stale versus fresh effective src64')
    c=RechargeSourceCatalog(DATA)
    req(len(c.giftbag_products())==284,'page2 census drift')
    req(len(c.fixed_b2_giftbags())==265,'B2 census drift')
    req(len(c.random_b3_giftbags())==1,'B3 random census drift')
    p=c.random_b3_giftbags()[0]
    req((p.charge_id,p.gift_id,p.drops)==(90002112,90011123,(600002,)),'B3 route drift')
    occ=p.drop_occurrences[0]
    req([x.item_num for x in occ.candidates]==[1,2,4,9,17],'B3 candidate quantity drift')
    req([x.drop_rate for x in occ.candidates]==[7547,1886,377,125,62],'B3 relative weight drift')
    req(sum(x.drop_rate for x in occ.candidates)==9997,'B3 weight total drift')
    req(all(x.item_id==50001043 and x.roll_type==1 for x in occ.candidates),'B3 candidate source drift')

def test_preflight_all_random_outcomes_zero_entropy():
    _p,s,e,_=make(); product=s.recharge_source_catalog.get_giftbag(90002112)
    plans=s.commerce_settlement.giftbag_policy.preflight_rewards(product,{'charge_count':0})
    req(len(plans)==5,'B3 preflight should cover five possible outcomes')
    for plan in plans: s.rewards.validate(plan)
    req(len(e.requests)==0,'B3 preflight consumed entropy')

def test_mid354_advertises_random_pack_then_hides_after_one_shot():
    p,s,e,_=make(); before=ids(s.recharge_catalog.query_charge_data()['giftbags'])
    req(90002112 in before,'B3 source-native random Pack not advertised')
    s.commerce_settlement.settle({'intent_id':'b3-one','charge_id':90002112,'platform':'lua_preservation'})
    after=ids(s.recharge_catalog.query_charge_data()['giftbags'])
    req(90002112 not in after,'B3 one-shot Pack remained advertised')
    req(len(e.requests)==1,'B3 purchase did not consume exactly one draw')

def test_last_roll_settles_fixed_plus_random_and_source_scalars():
    p,s,e,_=make(RecordingEntropy('last'))
    result=s.commerce_settlement.settle({'intent_id':'b3-last','charge_id':90002112,'platform':'lua_preservation'})
    r=e.requests[0]
    req((r.namespace,r.ordinal,r.upper_exclusive)==('recharge.giftbag',0,9997),'B3 entropy topology drift')
    inv={int(x['table_id']):int(x['item_num']) for x in result.recharge_event['params']['items']}
    req(inv.get(50001014)==5 and inv.get(50001013)==10 and inv.get(50001043)==17,'B3 award projection wrong')
    req(p.crystal==60 and p.mana==20000,'B3 fixed scalar settlement wrong')
    req(p.charge==0 and p.vip==0,'B3 Pack fabricated VIP progression')
    sel=result.settlement['random_selections']
    req(len(sel)==1 and sel[0]['row_id']==600002005 and sel[0]['item_num']==17,'B3 random provenance missing')
    req(result.settlement['product_kind']=='SOURCE_NATIVE_RANDOM_GIFTBAG','B3 product kind wrong')

def test_first_roll_selects_first_candidate():
    _p,s,e,_=make(RecordingEntropy('first'))
    result=s.commerce_settlement.settle({'intent_id':'b3-first','charge_id':90002112,'platform':'lua_preservation'})
    sel=result.settlement['random_selections'][0]
    req(sel['row_id']==600002001 and sel['item_num']==1,'B3 first bucket selection wrong')
    req(len(e.requests)==1,'B3 first roll draw count wrong')

def test_replay_is_exactly_once_and_consumes_no_second_entropy():
    p,s,e,_=make(RecordingEntropy('last'))
    first=s.commerce_settlement.settle({'intent_id':'b3-replay','charge_id':90002112,'platform':'lua_preservation'})
    state=copy.deepcopy(vars(p)); draws=len(e.requests)
    replay=s.commerce_settlement.settle({'intent_id':'b3-replay','charge_id':90002112,'platform':'lua_preservation'})
    req(replay.replayed and replay.recharge_event==first.recharge_event,'B3 replay response drift')
    req(vars(p)==state,'B3 replay mutated player')
    req(len(e.requests)==draws,'B3 replay consumed entropy')

def test_unsupported_products_fail_before_entropy():
    _p,s,e,_=make()
    for cid in (90002373,):
        try:
            s.commerce_settlement.settle({'intent_id':f'bad-{cid}','charge_id':cid,'platform':'lua_preservation'}); ok=False
        except UnsupportedPurchaseProduct: ok=True
        req(ok,f'unsupported {cid} authorized')
    req(len(e.requests)==0,'unsupported product consumed Recharge entropy')

def test_post_rng_commit_failure_rolls_back_whole_player():
    def fail(): raise OSError('pass150 simulated durable write failure')
    p,s,e,_=make(RecordingEntropy('last'),fail); before=copy.deepcopy(vars(p))
    try:
        s.commerce_settlement.settle({'intent_id':'b3-rollback','charge_id':90002112,'platform':'lua_preservation'}); failed=False
    except OSError: failed=True
    req(failed,'B3 simulated save failure did not surface')
    req(vars(p)==before,'B3 UoW did not roll back whole player after random selection')
    req(s.uow.get_receipt('commerce_purchase','b3-rollback') is None,'B3 failed settlement left receipt')
    req(len(e.requests)==1,'B3 rollback topology expected one consumed request-scoped draw')

def test_b2_fixed_stays_entropy_free_and_composition_shared():
    p,s,e,_=make()
    s.commerce_settlement.settle({'intent_id':'b2-control','charge_id':90002170,'platform':'lua_preservation'})
    req(len(e.requests)==0,'B2 fixed Pack consumed B3 entropy')
    req(s.commerce_settlement.giftbag_policy is s.recharge_giftbag_policy,'Recharge policy composition split')
    req(s.recharge_giftbag_policy.random_outcomes is s.recharge_giftbag_random_outcomes,'Recharge ROS adapter split')
    req(s.commerce_settlement.entitlements is s.commerce and s.commerce_settlement.rewards is s.rewards and s.commerce_settlement.uow is s.uow,'canonical Commerce owners split')

def main():
    tests=[test_fresh_source_metadata_and_random_shape,test_preflight_all_random_outcomes_zero_entropy,test_mid354_advertises_random_pack_then_hides_after_one_shot,test_last_roll_settles_fixed_plus_random_and_source_scalars,test_first_roll_selects_first_candidate,test_replay_is_exactly_once_and_consumes_no_second_entropy,test_unsupported_products_fail_before_entropy,test_post_rng_commit_failure_rolls_back_whole_player,test_b2_fixed_stays_entropy_free_and_composition_shared]
    for t in tests: t(); print('PASS',t.__name__)
    print(f'PASS Pass150 Recharge Phase B3 ({len(tests)}/{len(tests)})')
if __name__=='__main__': main()
