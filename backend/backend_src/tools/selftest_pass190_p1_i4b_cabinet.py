from __future__ import annotations
import copy, json, sys, tempfile, types
from pathlib import Path
from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.server_clock import ServerClock

ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'data'; CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(c,m):
    if not c: raise AssertionError(m)

def hero(pid=90001,tid=10001001):
    return {'partner_id':pid,'table_id':tid,'star':5,'lev':100,'exp':0,'color':16,'skills':[1]*6,'equips':[1]*6,'fumos':[0]*6,'fumo_levels':[0]*6,'book_shelf_lev':1,'skill_book_info':{}}

def make(*,clock=None,cabinet_lev=1,heroes=None,items=None):
    p=PlayerState(player_id='999190',account_uid='999190',player_name='Pass190')
    p.mana=10_000_000;p.magic_dust=10_000_000;p.magic_liquid=10_000_000;p.magic_energy=100_000;p.magic_exp=100_000;p.crystal=999_999
    hs=heroes or [hero()];p.heroes={str(h['partner_id']):copy.deepcopy(h) for h in hs};p.collected_heros={str(h['table_id']):{'table_id':h['table_id'],'star':h['star'],'is_collected':1} for h in hs}
    p.building_list={'1':{'lev':cabinet_lev,'need_time':0,'start_time':0,'new_evolve':0},'4':{'lev':1,'need_time':0,'start_time':0,'new_evolve':0}}
    p.backpack_items=[{'table_id':int(i),'item_num':int(n),'time':0} for i,n in (items or {}).items()]
    box=clock or [1_000_000]; commits=[]
    s=RequestServices(p,DATA,lambda:commits.append(int(p.persistence_state.get('state_version',-1))),catalog=CATALOG,server_clock=ServerClock(lambda:box[0]))
    return p,s,box,commits

def test_source_catalog_and_nested_wire():
    p,s,box,_=make(items={130001001:1})
    w=s.workshop_source
    req(len(w.cabinet_books)==54 and len(w.cabinet_skills)==399 and len(w.skill_costs)==6,'Cabinet census drift')
    req(w.cabinet_book_skills(130001001)[0]==10010001,'book skill map drift')
    req(w.cabinet_skill_prerequisites(10010004)==(10010001,),'prerequisite drift')
    req(w.cabinet_skill_need_time(10010001,1,1)==60,'skill time drift')
    req(w.cabinet_skill_cost(10010001,1)==((11,40000),(12,10000),(1,40000)),'skill cost drift')
    out=s.cabinet_research.get_info();req(len(out['book_info'])==54 and out['book_info']['130001001']=={},'GET_CABINET_INFO must expose nested all-book map')
    req(out['cabinet_info']=={'cur_learn_skill':0,'need_time':0,'start_time':0,'recent_complete_skill':0},'cabinet idle wire drift')

def test_learn_lazy_complete_projection_confirm_and_replay():
    p,s,box,_=make(items={130001001:1})
    before=(p.magic_dust,p.magic_liquid,p.mana)
    out=s.cabinet_research.learn(10010001);ci=out['cabinet_info'];req(ci['cur_learn_skill']==10010001 and ci['need_time']==60 and ci['start_time']==box[0],'learn did not start source timer')
    req((p.magic_dust,p.magic_liquid,p.mana)==(before[0]-40000,before[1]-10000,before[2]-40000),'learn costs wrong')
    balances=(p.magic_dust,p.magic_liquid,p.mana);s.cabinet_research.learn(10010001);req((p.magic_dust,p.magic_liquid,p.mana)==balances,'active learn replay double-spent')
    box[0]+=60;info=s.cabinet_research.get_info();req(info['book_info']['130001001']['10010001']['lev']==1,'lazy completion did not advance global book')
    req(info['cabinet_info']['recent_complete_skill']==10010001 and info['cabinet_info']['cur_learn_skill']==0,'completion acknowledgement state wrong')
    req(s.heroes.get(90001)['skill_book_info']['10010001']==1,'owned Hero did not receive Cabinet projection')
    # confirmation is idempotent
    s.cabinet_research.confirm();s.cabinet_research.confirm();req(s.cabinet_research.get_info()['cabinet_info']['recent_complete_skill']==0,'confirm did not clear recent skill')

def test_prerequisite_single_job_and_speed():
    p,s,box,_=make(items={130001001:1})
    try:s.cabinet_research.learn(10010004);raise AssertionError('prerequisite bypassed')
    except Exception as e:req('prerequisite' in str(e),'wrong prerequisite failure')
    # Seed source-valid root level through canonical nested state, then start dependent 5400s skill.
    p.workshop_state={'book_info':{'130001001':{'10010001':{'lev':1}}},'cabinet_info':{'cur_learn_skill':0,'need_time':0,'start_time':0,'recent_complete_skill':0,'cost_snapshot':{}},'building_jobs':{}}
    out=s.cabinet_research.learn(10010004);req(out['cabinet_info']['need_time']==5400,'dependent skill time wrong')
    try:s.cabinet_research.learn(10010005);raise AssertionError('concurrent Cabinet job accepted')
    except Exception as e:req('another Cabinet skill' in str(e),'wrong concurrent-job failure')
    cr=p.crystal;s.cabinet_research.speed(10010004);req(p.crystal==cr-75,'5400s speed cost must be 75')
    state=s.cabinet_research.get_info();req(state['book_info']['130001001']['10010004']['lev']==1,'speed did not complete skill')
    cr2=p.crystal;s.cabinet_research.speed(10010004);req(p.crystal==cr2,'speed replay double charged')

def test_skillpage_cancel_policy_and_resource_refund():
    # 20010003 target level6: source time 12600 - Cabinet6 cut9000 = 3600.
    p,s,box,_=make(cabinet_lev=6,items={230001001:1,240001001:100})
    p.workshop_state={'book_info':{'230001001':{'20010001':{'lev':6},'20010003':{'lev':5}}},'cabinet_info':{'cur_learn_skill':0,'need_time':0,'start_time':0,'recent_complete_skill':0,'cost_snapshot':{}},'building_jobs':{}}
    base=(p.magic_liquid,p.magic_dust,p.mana,p.magic_energy,s.inventory.quantity(240001001))
    out=s.cabinet_research.learn(20010003);req(out['cabinet_info']['need_time']==3600,'page skill research time wrong')
    # cost type4 level6 = liquid1m,dust250k,mana640k,energy1500,page60
    req((p.magic_liquid,p.magic_dust,p.mana,p.magic_energy,s.inventory.quantity(240001001))==(base[0]-1_000_000,base[1]-250_000,base[2]-640_000,base[3]-1500,base[4]-60),'page research debit wrong')
    box[0]+=1800;out=s.cabinet_research.cancel(20010003);req(out['return_skillpage']==60 and out['cabinet_info']['cur_learn_skill']==0,'cancel page return/state wrong')
    req((p.magic_liquid,p.magic_dust,p.mana,p.magic_energy,s.inventory.quantity(240001001))==(base[0]-500_000,base[1]-125_000,base[2]-320_000,base[3]-750,base[4]),'half-time ordinary refund/full page refund wrong')
    # duplicate cancel cannot refund twice
    snapshot=(p.magic_liquid,p.magic_dust,p.mana,p.magic_energy,s.inventory.quantity(240001001));again=s.cabinet_research.cancel(20010003);req(again['return_skillpage']==0 and snapshot==(p.magic_liquid,p.magic_dust,p.mana,p.magic_energy,s.inventory.quantity(240001001)),'cancel replay double-refunded')

def test_ready_cancel_completes_without_refund():
    p,s,box,_=make(items={130001001:1});base=(p.magic_dust,p.magic_liquid,p.mana);s.cabinet_research.learn(10010001);box[0]+=60
    out=s.cabinet_research.cancel(10010001);req(out['return_skillpage']==0 and out['cabinet_info']['recent_complete_skill']==10010001,'READY cancel must materialize completion')
    req((p.magic_dust,p.magic_liquid,p.mana)==(base[0]-40000,base[1]-10000,base[2]-40000),'READY cancel incorrectly refunded costs')

def test_migration_restart_and_building_payload_materialization():
    from gxb_backend.state.p1_foundation_state import P1FoundationStateNormalizer
    p,s,box,_=make(items={130001001:1})
    # Earlier Pass186 flat placeholder migrates monotonically to nested source shape.
    p.workshop_state={'book_info':{'10010001':1},'cabinet_info':{},'building_jobs':{}}
    n=P1FoundationStateNormalizer(p,album=s.white_album_source,workshop=s.workshop_source,game_data=CATALOG);req(n.normalize(),'flat Cabinet placeholder did not migrate')
    req(p.workshop_state['book_info']['130001001']['10010001']['lev']==1,'flat->nested migration wrong')
    # Start another valid skill and persist/reload active timer + cost snapshot.
    s.cabinet_research.learn(10010004)
    from gxb_backend.state.multiuser_database import MultiUserDatabase
    with tempfile.TemporaryDirectory(prefix='pass190_cabinet_roundtrip_') as td:
        db=MultiUserDatabase(Path(td),DATA);db.save_player(p);r=db.load_player(p.player_id)
        req(r is not None and r.workshop_state['cabinet_info']['cur_learn_skill']==10010004,'Cabinet active job lost on restart')
        req(r.workshop_state['cabinet_info']['cost_snapshot'].get('skill_id')==10010004,'Cabinet cost snapshot lost on restart')
    # GET_BUILDING_LIST must carry lazy-completed cabinet_info as source does.
    box[0]+=5400; from gxb_backend.handlers.workshop import WorkshopHandlers
    class S:
        def get_cabinet_research_service(_):return s.cabinet_research
        def get_workshop_building_service(_):return s.workshop_buildings
    class C:state=S()
    out=WorkshopHandlers(C()).get_building_list({});req(out['cabinet_info']['recent_complete_skill']==10010004 and out['cabinet_info']['cur_learn_skill']==0,'GET_BUILDING_LIST did not materialize Cabinet completion')

def test_dispatch_routes():
    fake=types.ModuleType('flask');fake.Request=object;fake.jsonify=lambda data=None,**k:data;fake.make_response=lambda data=None,status=200,**k:data;fake.send_file=lambda *a,**k:None;sys.modules.setdefault('flask',fake)
    from gxb_backend.config import Settings
    from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
    from gxb_backend.state.repository import StateRepository
    with tempfile.TemporaryDirectory(prefix='pass190_dispatch_') as td:
        root=Path(td);state=StateRepository(DATA/'player_db.json',profile='established',legacy_path=ROOT/'state/gxb_state.json',multiuser_root=root/'server_state')
        d=EngineDispatcher(state,Settings(multiuser_root=root/'server_state',runtime_log_dir=root/'logs'))
        exp={1059:'get_cabinet_info',1060:'learn_skill',1061:'give_up_learn_skill',1078:'speed_up_skill',1079:'cabinet_skill_confirm'}
        for mid,name in exp.items():req(getattr(d.handlers[mid],'__name__','')==name,f'MID{mid} Cabinet route missing')

def main():
    tests=[test_source_catalog_and_nested_wire,test_learn_lazy_complete_projection_confirm_and_replay,test_prerequisite_single_job_and_speed,test_skillpage_cancel_policy_and_resource_refund,test_ready_cancel_completes_without_refund,test_migration_restart_and_building_payload_materialization,test_dispatch_routes]
    for t in tests:t();print('PASS',t.__name__,flush=True)
    print(f'PASS Pass190 P1-I4B Cabinet research ({len(tests)}/{len(tests)})',flush=True)
if __name__=='__main__':main()
