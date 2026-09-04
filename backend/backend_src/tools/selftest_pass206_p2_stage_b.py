#!/usr/bin/env python3
"""Pass206 P2 Stage B composition/lifecycle-entry characterization."""
from __future__ import annotations
import json
from pathlib import Path
from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.protocol.mutation_contracts import MutationContractRegistry

ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'data'; CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')
def req(c,m):
    if not c: raise AssertionError(m)
def hero(pid,tid,color=15,stage=0):
    return {'partner_id':pid,'table_id':tid,'star':5,'lev':100,'exp':0,'color':color,'skills':[1]*6,'equips':[0]*6,'fumos':[0]*6,'fumo_levels':[0]*6,'element_equips':[0]*4,'element_levels':[0]*4,'element_bak_equips':[],'element_bak_levels':[],'inscript_items':[],'twice_awake_stage':stage}
def services(tid,items=None,mana=999999,pid=206001):
    p=PlayerState(player_id=str(pid),account_uid=str(pid),lev=100); h=hero(pid,tid); p.heroes={str(pid):h}; p.collected_heros={str(tid):{'table_id':tid,'star':5,'is_collected':1}}; p.mana=mana
    p.backpack_items=[{'table_id':int(i),'item_num':int(n),'time':0} for i,n in (items or {}).items()]
    commits=[]; s=RequestServices(p,DATA,lambda:commits.append(1),catalog=CATALOG); return p,s,commits

def test_composition():
    p,s,c=services(10001001,{60001043:60},mana=20000)
    out=s.item_composition.compose({'item_id':50001019}); req(out=={},'ordinary material compose response'); req(s.inventory.get_item_num(60001043)==0 and s.inventory.get_item_num(50001019)==1,'ordinary material stacks'); req(p.mana==10000,'ordinary material mana')
    # Exclusive gear source recipe consumes intermediate + three ordinary pieces, never a generic award response.
    p,s,c=services(10001001,{50001019:1,20001108:1,20001129:1,20001130:1},mana=20000,pid=206002)
    out=s.item_composition.compose({'item_id':20001185}); req(out=={},'ordinary gear compose response'); req(s.inventory.get_item_num(20001185)==1 and s.inventory.get_item_num(50001019)==0,'ordinary gear stacks')
    # Blood recipe consumes its intermediate and two ordinary pieces; prior ordinary Awake gear is not a material.
    p,s,c=services(11001122,{50001601:1,20001242:1,20001219:1},mana=120000,pid=206003)
    out=s.item_composition.compose({'item_id':21001031}); req(out=={},'blood gear compose response'); req(s.inventory.get_item_num(21001031)==1,'blood gear credit')
    # Cabinet provider remains first and preserves one-owned-book replay semantics.
    p,s,c=services(10001001,{140001001:20},mana=10,pid=206004)
    req(s.item_composition.compose({'item_id':130001001})=={},'cabinet compose'); req(s.inventory.get_item_num(130001001)==1 and s.inventory.get_item_num(140001001)==0,'cabinet stacks')
    req(s.item_composition.compose({'item_id':130001001})=={},'cabinet replay'); req(s.inventory.get_item_num(130001001)==1,'cabinet duplicate')

def test_open_replay_event_and_giveup():
    p,s,c=services(10001041,{},pid=206011)
    out=s.awakening_missions.open_task({'mission_id':1041001,'awake_type':1}); row=out['awake_mission_'][0]
    req(row['is_complete']==0 and row['count']==0,'stage1 must open incomplete'); req(out['extra_drops_']==[{'table_id':50001321,'item_num':1}],'event extra_drops shape'); req(s.inventory.get_item_num(50001321)==1,'event durable grant')
    replay=s.awakening_missions.open_task({'mission_id':1041001,'awake_type':1}); req(replay==out,'open replay payload'); req(s.inventory.get_item_num(50001321)==1,'open replay duplicated grant')
    tomb=s.awakening_missions.give_up({'mission_id':1041001,'awake_type':1}); req(tomb['awake_mission_'][0]['is_going']==0,'giveup tombstone'); req(s.inventory.get_item_num(50001321)==1,'no-list giveup purged entitlement')
    req(s.awakening_missions.give_up({'mission_id':1041001,'awake_type':1})==tomb,'giveup retry')
    reopen=s.awakening_missions.open_task({'mission_id':1041001,'awake_type':1}); req('extra_drops_' not in reopen,'reopen duplicated event entitlement'); req(s.inventory.get_item_num(50001321)==1,'reopen economic duplication')

def test_giveup_full_stack_and_odin_restore():
    p,s,c=services(10001001,{50001019:3,60001043:70},pid=206021); s.awakening_missions.open_task({'mission_id':1001001,'awake_type':1}); out=s.awakening_missions.give_up({'mission_id':1001001,'awake_type':1})
    req(s.inventory.get_item_num(50001019)==0 and s.inventory.get_item_num(60001043)==0,'Give Up must purge full source stacks'); req(set(out)=={'awake_mission_'},'Give Up leaked stack projection')
    p,s,c=services(10001258,{},pid=206022); first=s.awakening_missions.open_task({'mission_id':1258001,'awake_type':1}); req(s.inventory.get_item_num(50002082)==1,'Odin first entitlement')
    s.awakening_missions.give_up({'mission_id':1258001,'awake_type':1}); req(s.inventory.get_item_num(50002082)==0,'Odin source delete list not applied'); ent=s.awakening_missions.state.event_entitlement(1,1258001); req(ent['status']=='RESTORABLE','Odin entitlement not restorable')
    second=s.awakening_missions.open_task({'mission_id':1258001,'awake_type':1}); req(second['extra_drops_']==[{'table_id':50002082,'item_num':1}] and s.inventory.get_item_num(50002082)==1,'Odin restoration'); ent=s.awakening_missions.state.event_entitlement(1,1258001); req(ent['grant_count']==1 and ent['restoration_count']==1,'Odin lifetime/live accounting')

def test_blood_event_and_wish():
    p,s,c=services(11001122,{},pid=206031); out=s.awakening_missions.open_task({'mission_id':2122001,'awake_type':2}); req(out['twice_awake_mission_'][0]['is_complete']==0,'Blood stage1 complete'); req(out['extra_drops_']==[{'table_id':50001601,'item_num':1}],'Blood event material'); req(p.heroes[str(206031)]['twice_awake_stage']==1,'Blood durable stage1')
    s.awakening_missions.give_up({'mission_id':2122001,'awake_type':2}); req(p.heroes[str(206031)]['twice_awake_stage']==0,'Blood giveup stage reset'); req(s.inventory.get_item_num(50001601)==1,'Blood no-list Give Up purge')
    p,s,c=services(10001001,{50005037:2},pid=206032); s.awakening_missions.open_task({'mission_id':1001001,'awake_type':1}); out=s.awakening_missions.get_awake_item({'item_num':1}); req(out=={'item_id':50001019,'item_num':1},'Wish response'); req(s.inventory.get_item_num(50005037)==1 and s.inventory.get_item_num(50001019)==1,'Wish settlement')
    p,s,c=services(10001041,{50005037:1},pid=206033); s.awakening_missions.open_task({'mission_id':1041001,'awake_type':1}); before=s.inventory.get_item_num(50005037); out=s.awakening_missions.get_awake_item({'item_num':1}); req(out.get('error_code')==1 and s.inventory.get_item_num(50005037)==before,'Wish blacklist')


def safe_firewall_probe():
    import sys,types,tempfile
    fake=types.ModuleType('flask'); fake.Request=object; fake.jsonify=lambda data=None,**k:data; fake.make_response=lambda data=None,status=200,**k:data; fake.send_file=lambda *a,**k:None
    sys.modules.setdefault('flask',fake)
    from gxb_backend.config import Settings
    from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
    from gxb_backend.state.repository import StateRepository
    from gxb_backend.protocol.mids import MID
    with tempfile.TemporaryDirectory(prefix='pass206_dispatch_') as td:
        root=Path(td); state=StateRepository(DATA/'player_db.json',profile='established',legacy_path=ROOT/'state/gxb_state.json',multiuser_root=root/'server_state')
        d=EngineDispatcher(state,Settings(multiuser_root=root/'server_state',runtime_log_dir=root/'logs'))
        if getattr(d.handlers[MID.GET_AWAKE_ITEM],'__name__','')!='awake_get_item': return False
        result=d.mutation_firewall.evaluate(int(MID.GET_AWAKE_ITEM),'GET_AWAKE_ITEM')
        return result is not None and int(result.status_code)==409 and int(result.body.get('error_code',0))==1

def test_policy_and_firewall():
    p,s,c=services(10001001,{},pid=206041); req(len(s.awakening_compatibility.event_rows)==18,'event policy census'); req(len(s.awakening_compatibility.wish_blacklist)==11,'wish blacklist census')
    provider=s.item_composition.providers[1]; req(len(provider.allowed)==417,'Awakening composition provider census')
    reg=MutationContractRegistry.load(DATA/'mutation_contract_registry.json'); contract=reg.contract(171); req(contract is not None and contract.enforcement=='BLOCK_PHASE1','MID171 firewall retired early')
    blocked=safe_firewall_probe(); req(blocked,'MID171 actual firewall path retired early')

def main():
    for fn in [test_composition,test_open_replay_event_and_giveup,test_giveup_full_stack_and_odin_restore,test_blood_event_and_wish,test_policy_and_firewall]: fn()
    print(json.dumps({'pass':'206.0','stage':'P2-B','status':'PASS','composition_provider':True,'activation_incomplete':True,'giveup_full_stack_tombstone_replay':True,'event_entitlements':18,'odin_restore':True,'wish_service_implemented_firewall_preserved':True},indent=2,sort_keys=True)); return 0
if __name__=='__main__': raise SystemExit(main())
