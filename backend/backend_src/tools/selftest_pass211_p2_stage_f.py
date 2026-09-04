#!/usr/bin/env python3
"""Pass211 P2 Stage F minimal Occult/Sorcery War dependency characterization."""
from __future__ import annotations
import copy,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:sys.path.insert(0,str(ROOT))
DATA=ROOT/'data'
from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.mutation_plan import ActorRef,IdempotencySpec,MutationOrigin,MutationPlan,TemporalTransition
from gxb_backend.state.unit_of_work import OperationContext
from gxb_backend.state.occult_service import OccultServiceError

CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')
def require(v,msg):
    if not v:raise AssertionError(msg)

def make(pid=211001):
    p=PlayerState(player_id=str(pid),account_uid=str(pid),lev=100)
    p.energy=20000;p.max_energy=20000;p.energy_time=0
    commits=[];s=RequestServices(p,DATA,lambda:commits.append(1),catalog=CATALOG)
    return p,s,commits

def seed(s,mission_id,generation=1):
    row=s.awakening_source.mission(mission_id,1) or {}
    rec={'mission_id':mission_id,'awake_type':1,'hero_partner_id':1,'hero_table_id':int(row.get('hero_table_id',0) or 0),'stage':1,'generation':generation,'complete':False,'count':0,'opened_at':s.player.now()}
    with s.uow.transaction(OperationContext(actor_player_id=str(s.player.player_id),domain='pass211_test',operation_name='seed')):
        s.awakening_missions._set_active(1,rec)

def spend(s,amount):
    with s.uow.transaction(OperationContext(actor_player_id=str(s.player.player_id),domain='pass211_test',operation_name='spend')):
        s.mutation_settlement.apply(MutationPlan(schema_version=1,plan_id=f'test:energy:{amount}:{s.uow.current_state_version}',origin=MutationOrigin(domain='test',operation='energy_spend'),actor=ActorRef(player_id=str(s.player.player_id)),expected_state_version=None,idempotency=IdempotencySpec(),preconditions=(),operations=(TemporalTransition('energy','DEBIT',amount),)))

def test_source_catalog_and_owner_boundary():
    p,s,_=make()
    require((s.occult_source.ticket_energy_threshold,s.occult_source.ticket_cap,s.occult_source.sweep_reward_rate_raw)==(3000,2,0.6),'source constants drift')
    require(len(s.occult_source.chapters)==6 and len(s.occult_source.routes)==22,'Occult source census drift')
    require(all(int(r['awaken_num_raw'])==30 for r in s.occult_source.routes.values()),'raw awaken_num drift')
    descriptor=s.resource_registry.require('occult_ticket')
    require(descriptor.owner_service=='SorceryWarAggregate' and descriptor.mutation_capability=='DOMAIN_GUARDED_CREDIT_DEBIT' and descriptor.cap_policy=='SOURCE_CAP_2_SORCERY_WAR','occult_ticket registry ownership/cap drift')
    require('occult_stamina_accrual' in s.derived_mutation_rules.names,'derived rule not registered')
    require('OCCULT' in s.mutation_settlement._entity_owners,'OCCULT entity owner not registered')

def test_idle_and_synthetic_unlock():
    p,s,_=make(211011)
    info=s.occult.get_info(); base=info['base_info']
    require(info['occult_ticket']==0,'idle ticket drift')
    require(base['room_id']==0 and base['chapter_id']==0 and base['cost_energy']==0 and base['dispatch_limit']==30,'safe idle base_info drift')
    require(base['max_points']==[0,0,0,0,0,0],'idle synthetic clear leaked')
    seed(s,1171001); info=s.occult.get_info(); require(info['base_info']['max_points']==[0,1,0,0,0,0],'active chapter-2 sweep unlock drift')
    seed(s,1185001,2); require(s.occult.get_info()['base_info']['max_points']==[0,0,1,0,0,0],'active chapter-3 sweep unlock drift')

def test_stamina_accrual_cap_pause_and_projection():
    p,s,_=make(211021)
    spend(s,2999); require((p.occult_ticket,p.occult_state.get('cost_energy'))==(0,2999),'2999 progress drift')
    sem=s.uow.consume_semantic(); require(not any(isinstance(r,dict) and 'occult_ticket' in r for r in sem.get('economy_',[])),'ticket projection emitted before threshold')
    spend(s,1); require((p.occult_ticket,p.occult_state.get('cost_energy'))==(1,0),'first threshold drift')
    sem=s.uow.consume_semantic(); require(any(isinstance(r,dict) and r.get('occult_ticket')==1 for r in sem.get('economy_',[])),f'first ticket semantic drift: {sem}')
    spend(s,6500); require((p.occult_ticket,p.occult_state.get('cost_energy'))==(2,0),'cap/overflow discard drift')
    spend(s,50); require((p.occult_ticket,p.occult_state.get('cost_energy'))==(2,0),'at-cap spend advanced progress')
    sem=s.uow.consume_semantic(); require(any(isinstance(r,dict) and r.get('occult_ticket')==2 for r in sem.get('economy_',[])),'cap transition semantic missing')


def test_existing_campaign_energy_path_feeds_occult_rule():
    p,s,_=make(211025)
    # MID114's canonical Campaign energy settlement is an existing TemporalTransition.
    with s.uow.transaction(OperationContext(actor_player_id=str(p.player_id),domain='pass211_test',operation_name='campaign_energy',protocol_mid=114)):
        projection=s.world._settle_campaign_energy(100001,3)
    require(projection.get('energy') is not None,'Campaign energy owner did not settle')
    require(p.occult_ticket==0 and p.occult_state.get('cost_energy')==6,f'Campaign energy did not feed Occult derived rule: {p.occult_state}')

def test_sweep_atomicity_policy_and_nonce_limit():
    p,s,_=make(211031);seed(s,1171001);p.occult_ticket=2
    before=(p.occult_ticket,copy.deepcopy(p.occult_state),copy.deepcopy(p.backpack_items))
    try:s.occult.sweep(3)
    except OccultServiceError:pass
    else:raise AssertionError('wrong chapter accepted')
    require((p.occult_ticket,p.occult_state,p.backpack_items)==before,'wrong chapter mutated Occult/inventory state')
    route=s.occult_source.awakening_route(1171001); frag=int(route['fragment_item'])
    first=s.occult.sweep(2); require(first=={'awards':[{'item_id':frag,'item_num':1}],'occult_ticket':1},f'first sweep response drift {first}')
    require(s.inventory.get_item_num(frag)==1 and p.occult_ticket==1,'first sweep settlement drift')
    second=s.occult.sweep(2); require(second['occult_ticket']==0 and s.inventory.get_item_num(frag)==2,'wire-identical second sweep must be legitimate second action')
    try:s.occult.sweep(2)
    except OccultServiceError:pass
    else:raise AssertionError('zero-ticket sweep accepted')
    require(s.inventory.get_item_num(frag)==2 and p.occult_ticket==0,'failed sweep partially mutated')

def test_all_22_routes_and_relog():
    for i,(mid,route) in enumerate(sorted(make(211040)[1].occult_source.routes.items())):
        p,s,_=make(211100+i);seed(s,mid);p.occult_ticket=1
        cid=int(route['chapter_id']); frag=int(route['fragment_item'])
        maxp=s.occult.get_info()['base_info']['max_points']; require(maxp[cid-1]==1 and sum(maxp)==1,f'route {mid} synthetic unlock drift')
        out=s.occult.sweep(cid); require(out['awards']==[{'item_id':frag,'item_num':1}] and s.inventory.get_item_num(frag)==1,f'route {mid} settlement drift')
    p,s,_=make(211199);p.occult_ticket=1;p.occult_state={'schema_version':1,'cost_energy':1777};s2=RequestServices(p,DATA,lambda:None,catalog=CATALOG)
    require(s2.occult.get_info()['occult_ticket']==1 and s2.occult.get_info()['base_info']['cost_energy']==1777,'Occult relog hydration drift')

def test_only_minimal_occult_mids_are_routed():
    # Static routing check avoids needing a real on-disk StateRepository for this assertion.
    text=(ROOT/'gxb_backend/dispatch/engine_dispatcher.py').read_text()
    require('"GET_INFO": self.occult.get_info' in text and '"OCCULT_SWEEP": self.occult.sweep' in text,'minimal Occult routes missing')
    for name in ('START_CHALLENGE','GET_CAMPAIGN_INFO','CREATE_ROOM','JOIN_ROOM','SINGLE_FIGHT','TEAM_FIGHT'):
        require(f'"{name}": self.occult.' not in text,f'full Occult MID unexpectedly activated: {name}')

def main():
    tests=[test_source_catalog_and_owner_boundary,test_idle_and_synthetic_unlock,test_stamina_accrual_cap_pause_and_projection,test_existing_campaign_energy_path_feeds_occult_rule,test_sweep_atomicity_policy_and_nonce_limit,test_all_22_routes_and_relog,test_only_minimal_occult_mids_are_routed]
    for fn in tests:fn();print('PASS',fn.__name__)
    print(f'PASS Pass211 Stage F characterization: {len(tests)}/{len(tests)}')
if __name__=='__main__':main()
