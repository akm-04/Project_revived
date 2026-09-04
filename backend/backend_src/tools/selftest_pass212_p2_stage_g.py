#!/usr/bin/env python3
"""Pass212 P2 Stage G exhaustive closure/release-gate characterization."""
from __future__ import annotations
import copy,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
DATA=ROOT/'data'
from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.protocol.mutation_contracts import MutationContractRegistry,MutationSafetyFirewall
from gxb_backend.state.unit_of_work import OperationContext
from gxb_backend.state.response_projector import ResponseProjector
from gxb_backend.state.projection_profiles import ProjectionProfileRegistry

CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')
def require(v,msg):
    if not v: raise AssertionError(msg)
def hero(pid,tid):
    return {'partner_id':pid,'table_id':tid,'star':5,'lev':100,'exp':0,'color':15,'skills':[1]*6,
            'equips':[0]*6,'fumos':[0]*6,'fumo_levels':[0]*6,'element_equips':[0]*4,
            'element_levels':[0]*4,'element_bak_equips':[],'element_bak_levels':[],
            'inscript_items':[],'twice_awake_stage':0}
def make(pid=212001, *, awakening_state=None, items=None):
    p=PlayerState(player_id=str(pid),account_uid=str(pid),lev=100)
    if awakening_state is not None:p.awakening_state=copy.deepcopy(awakening_state)
    p.backpack_items=[{'table_id':int(i),'item_num':int(n),'time':0} for i,n in (items or {}).items()]
    commits=[];s=RequestServices(p,DATA,lambda:commits.append(1),catalog=CATALOG)
    return p,s,commits

def test_route_census_and_executable_partition():
    p,s,_=make()
    o={int(k):dict(v) for k,v in s.awakening_source.rows(1).items() if int(v.get('stage',0))==1}
    b={int(k):dict(v) for k,v in s.awakening_source.rows(2).items() if int(v.get('stage',0))==1}
    require((len(o),len(b))==(164,81),'root census drift')
    oroutes={mid:dict(s.awakening_source.stage1_route(mid,1)) for mid in o}
    broutes={mid:dict(s.awakening_source.stage1_route(mid,2)) for mid in b}
    from collections import Counter
    require(Counter(r['route_class'] for r in oroutes.values())==Counter({'CAMPAIGN':131,'OCCULT':22,'EVENT_OUTLIER':11}),'ordinary route partition drift')
    require(Counter(r['route_class'] for r in broutes.values())==Counter({'CAMPAIGN':74,'EVENT_OUTLIER':7}),'blood route partition drift')
    require(all(r.get('campaigns') for r in oroutes.values() if r['route_class']=='CAMPAIGN'),'ordinary Campaign route without mappings')
    require(all(r.get('campaigns') for r in broutes.values() if r['route_class']=='CAMPAIGN'),'Blood Campaign route without mappings')
    require(set(s.occult_source.routes)=={mid for mid,r in oroutes.items() if r['route_class']=='OCCULT'},'22 Occult route closure drift')
    events={(int(r['awake_type']),int(r['mission_id'])) for r in s.awakening_compatibility.event_rows}
    expected={(1,mid) for mid,r in oroutes.items() if r['route_class']=='EVENT_OUTLIER'}|{(2,mid) for mid,r in broutes.items() if r['route_class']=='EVENT_OUTLIER'}
    require(events==expected and len(events)==18,'event entitlement closure drift')
    # Every ordinary intermediate is Wish-eligible except the exact 11 source-blacklisted event intermediates.
    blocked={int(r['material_item']) for r in oroutes.values() if not s.awakening_compatibility.wish_allowed(r['material_item'])}
    require(blocked==set(s.awakening_compatibility.wish_blacklist) and len(blocked)==11,'Wish Bottle route coverage drift')

def test_all_245_open_giveup_roots():
    p,s,_=make(212010)
    # One source-valid Hero per distinct table ID. Reuse is safe because each open is immediately given up.
    tids=[]
    for at in (1,2):
        for row in s.awakening_source.rows(at).values():
            if int(row.get('stage',0))==1:tids.append(int(row['table_id']))
    for idx,tid in enumerate(sorted(set(tids)),start=1):p.heroes[str(idx)]=hero(idx,tid)
    counts={1:0,2:0}
    for at in (1,2):
        mids=sorted(int(mid) for mid,row in s.awakening_source.rows(at).items() if int(row.get('stage',0))==1)
        for mid in mids:
            out=s.awakening_missions.open_task({'mission_id':mid,'awake_type':at})
            require(out.get('error_code')!=1,f'open failed {at}/{mid}: {out}')
            channel='awake_mission_' if at==1 else 'twice_awake_mission_'
            require(out[channel][0]['table_id']==mid and out[channel][0]['is_going']==1,f'open projection drift {at}/{mid}')
            replay=s.awakening_missions.open_task({'mission_id':mid,'awake_type':at})
            require(replay==out,f'open replay drift {at}/{mid}')
            tomb=s.awakening_missions.give_up({'mission_id':mid,'awake_type':at})
            require(tomb.get('error_code')!=1 and tomb[channel][0]['is_going']==0,f'giveup failed {at}/{mid}: {tomb}')
            require(s.awakening_missions.give_up({'mission_id':mid,'awake_type':at})==tomb,f'giveup replay drift {at}/{mid}')
            counts[at]+=1
    require(counts=={1:164,2:81},f'executed root count drift {counts}')

def test_giveup_anomalies_source_exact():
    d=json.loads((DATA/'awakening_source_catalog.json').read_text())
    ordinary=d['ordinary_stage1_routes']; blood=d['blood_stage1_routes']
    no_o=sorted(int(k) for k,v in ordinary.items() if not v.get('delete_items'))
    no_b=sorted(int(k) for k,v in blood.items() if not v.get('delete_items'))
    require(no_o==[1024001,1041001,1075001,1122001,1144001,1157001,1158001,1200001,1232001,1242001,1260001,1262001],'ordinary no-delete census drift')
    require(no_b==[2122001,2157001,2158001,2190001,2200001,2232001,2258001],'Blood no-delete census drift')
    anomalies={mid:ordinary[str(mid)]['delete_items'] for mid in (1038001,1109001,1125001,1197001)}
    require(anomalies=={
        1038001:[50001164,60001099],
        1109001:[50001185,60001102],
        1125001:[50001452,20001291],
        1197001:[50001544,60001202],
    },f'ordinary mismatch corpus drift {anomalies}')
    require(len(no_o)+len(no_b)==19,'total no-delete census drift')

def test_v1_migration_fresh_account_and_bootstrap():
    p,s,_=make(212020)
    root=s.awakening_missions.state.root()
    require(root['schema_version']==2 and root['active']=={} or root['schema_version']==2,'fresh account state v2 normalization')
    # Existing v1 state must preserve the active canonical mission and unknown root extension while adding generations/replay buckets.
    v1={'schema_version':1,'active':{'1':{'mission_id':1001001,'awake_type':1,'stage':1,'complete':False,'count':0,'hero_partner_id':7,'hero_table_id':10001001}},'future_extension':{'keep':1},'event_entitlements':{}}
    p,s,_=make(212021,awakening_state=v1);p.heroes={'7':hero(7,10001001)}
    with s.uow.transaction(OperationContext(actor_player_id=str(p.player_id),domain='pass212',operation_name='migrate')):
        root=s.awakening_missions.state.root()
    require(root['schema_version']==2 and root['active']['1']['generation']==1 and root['next_generation']['1']==2,'v1 generation migration drift')
    require(root.get('future_extension')=={'keep':1},'v1 unknown extension lost')
    boot=s.awakening_missions.bootstrap_channels();require(boot['awake_mission_'][0]['table_id']==1001001,'migrated bootstrap projection drift')
    s2=RequestServices(p,DATA,lambda:None,catalog=CATALOG);require(s2.awakening_missions.bootstrap_channels()==boot,'relog bootstrap drift')

def test_surgical_fence_retirement():
    reg=MutationContractRegistry.load(DATA/'mutation_contract_registry.json'); fw=MutationSafetyFirewall(reg)
    c=reg.contract(171);require(c and c.enforcement=='ALLOW_DURABLE' and c.backend_capability=='DURABLE_MUTATION','MID171 durable fence not retired')
    require(fw.evaluate(171,'GET_AWAKE_ITEM') is None,'MID171 still firewall blocked')
    for mid in (165,166,823):
        c=reg.contract(mid);require(c and c.firewall_blocked and c.backend_capability=='EXPLICIT_FAIL_CLOSED',f'unsafe Pet fence retired {mid}')
    text=(ROOT/'gxb_backend/handlers/heroes.py').read_text()
    require('awakening_equipment_promotion_deferred' not in text and '_promotion_transport' not in text,'MID51/57 stale Awakening transport fence remains')
    dispatch=(ROOT/'gxb_backend/dispatch/engine_dispatcher.py').read_text()
    require('"GET_AWAKE_ITEM": self.tasks.awake_get_item' in dispatch,'MID171 durable route missing')
    # Full Occult remains minimal/fenced: only Stage-F information+sweep owner is activated.
    require('"GET_INFO": self.occult.get_info' in dispatch and '"OCCULT_SWEEP": self.occult.sweep' in dispatch,'minimal Occult routes lost')
    for name in ('START_CHALLENGE','GET_CAMPAIGN_INFO','CREATE_ROOM','JOIN_ROOM','SINGLE_FIGHT','TEAM_FIGHT'):
        require(f'"{name}": self.occult.' not in dispatch,f'full Occult route accidentally opened {name}')

def test_mid171_wire_projection_is_callback_local():
    p,s,_=make(212025,items={50005037:1});p.heroes={'1':hero(1,10001001)}
    s.awakening_missions.open_task({'mission_id':1001001,'awake_type':1})
    # Drain the open-task journal/semantics so this assertion is MID171-only.
    s.uow.consume_semantic();s.uow.consume_journal()
    projector=ResponseProjector.capture(p,resource_registry=s.resource_registry)
    raw=s.awakening_missions.get_awake_item({'item_num':1})
    semantic=s.apply_semantic_deltas(raw);journal=s.uow.consume_journal()
    profile=ProjectionProfileRegistry.load(DATA/'projection_profile_registry.json').resolve(mid=171,label='GET_AWAKE_ITEM',transport='engine_web')
    wire=projector.project(semantic,p,committed_journal=journal,profile=profile)
    require(wire=={'item_id':50001019,'item_num':1},f'MID171 must remain callback-local with no generic stack projection: {wire}')
    require(any(r.get('category')=='STACK' for r in journal),'MID171 durable stack journal missing')
    require(profile.project_journal_stack_credits is False,'MID171/default profile unexpectedly projects stack credits')

def test_mid171_live_settlement_and_nonce_limit():
    p,s,_=make(212030,items={50005037:2});p.heroes={'1':hero(1,10001001)}
    out=s.awakening_missions.open_task({'mission_id':1001001,'awake_type':1});require(out.get('error_code')!=1,'ordinary open for wish failed')
    first=s.awakening_missions.get_awake_item({'item_num':1});require(first=={'item_id':50001019,'item_num':1},f'MID171 response drift {first}')
    require(s.inventory.get_item_num(50005037)==1 and s.inventory.get_item_num(50001019)==1,'MID171 first settlement drift')
    second=s.awakening_missions.get_awake_item({'item_num':1});require(second==first,'nonce-less second legitimate request response drift')
    require(s.inventory.get_item_num(50005037)==0 and s.inventory.get_item_num(50001019)==2,'nonce-less second legitimate request must settle twice')
    third=s.awakening_missions.get_awake_item({'item_num':1});require(third.get('error_code')==1,'zero-bottle request accepted')

def main():
    tests=[test_route_census_and_executable_partition,test_all_245_open_giveup_roots,test_giveup_anomalies_source_exact,test_v1_migration_fresh_account_and_bootstrap,test_surgical_fence_retirement,test_mid171_wire_projection_is_callback_local,test_mid171_live_settlement_and_nonce_limit]
    for fn in tests:fn();print('PASS',fn.__name__)
    print(json.dumps({'pass':'212.0','stage':'P2-G','status':'PASS','ordinary_roots':164,'blood_roots':81,'giveup_no_list_total':19,'giveup_anomalies':4,'event_entitlements':18,'mid171_firewall_retired':True,'mid51_mid57_dead_adapter_removed':True,'pet_and_full_occult_fences_preserved':True,'nonce_less_limit_preserved':True},indent=2,sort_keys=True))
if __name__=='__main__':main()
