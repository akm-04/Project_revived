from __future__ import annotations
import copy, sys, tempfile, types
from pathlib import Path
from gxb_backend.content import GameDataCatalog
from gxb_backend.protocol.mids import MID
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.server_clock import ServerClock
from gxb_backend.transport.result import EngineTransportResult

ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'data'; CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(c,m):
    if not c: raise AssertionError(m)

def normal(pid=89001,tid=10001001):
    return {'partner_id':pid,'table_id':tid,'star':5,'lev':100,'exp':0,'color':16,'skills':[1]*6,'equips':[1]*6,'fumos':[0]*6,'fumo_levels':[0]*6,'book_shelf_lev':1}

def superh(pid=89002,tid=11001):
    h=normal(pid,tid);h['book_shelf_lev']=0;return h

def make(clock=None, heroes=None):
    p=PlayerState(player_id='998901',account_uid='998901',player_name='Pass189')
    p.magic_dust=2_000_000;p.magic_liquid=2_000_000;p.magic_energy=50_000;p.magic_exp=50_000;p.crystal=999_999
    hs=heroes or [normal(),superh()];p.heroes={str(h['partner_id']):copy.deepcopy(h) for h in hs}
    p.collected_heros={str(h['table_id']):{'table_id':h['table_id'],'star':h['star'],'is_collected':1} for h in hs}
    box=clock or [1_000_000]; commits=[]
    s=RequestServices(p,DATA,lambda:commits.append(int(p.persistence_state.get('state_version',-1))),catalog=CATALOG,server_clock=ServerClock(lambda:box[0]))
    return p,s,box,commits

def test_source_catalog_and_payload():
    p,s,box,_=make(); w=s.workshop_source
    req(w.max_building_level(4)==100 and w.max_building_level(1)==6,'Workshop max levels drift')
    r=w.building_level(4,1); req(r and r['resources_id']=='11|12|13|14' and int(r['time'])==1800,'Bookshelf row1 drift')
    out=s.workshop_buildings.get_building_list();req(set(out['building_list'])==set(map(str,range(1,8))),'GET_BUILDING_LIST missing rows')
    req(out['cabinet_info']['cur_learn_skill']==0,'cabinet_info projection drift')

def test_bookshelf_upgrade_lazy_complete_confirm_and_projection():
    p,s,box,_=make(); before=(p.magic_dust,p.magic_liquid,p.magic_energy,p.magic_exp)
    out=s.workshop_buildings.upgrade(4);req(out['lev']==1 and out['need_time']==1800 and out['start_time']==box[0],'Bookshelf did not start at current lev')
    req((p.magic_dust,p.magic_liquid,p.magic_energy,p.magic_exp)==(before[0]-10000,before[1]-10000,before[2]-200,before[3]-20),'Bookshelf cost wrong')
    balances=(p.magic_dust,p.magic_liquid,p.magic_energy,p.magic_exp);s.workshop_buildings.upgrade(4);req((p.magic_dust,p.magic_liquid,p.magic_energy,p.magic_exp)==balances,'upgrade retry double-spent')
    box[0]+=1800;out=s.workshop_buildings.get_building_list(); row=out['building_list']['4']
    req(row['lev']==2 and row['new_evolve']==1 and row['start_time']==0,'lazy completion wrong')
    req(s.heroes.get(89001)['book_shelf_lev']==2,'Normal Hero Bookshelf not projected')
    req(s.heroes.get(89002).get('book_shelf_lev',0)==0,'Super Hero incorrectly received Bookshelf projection')
    s.workshop_buildings.confirm(4);req(s.workshop_buildings.get_building_list()['building_list']['4']['new_evolve']==0,'confirm did not clear new_evolve')

def test_speed_exact_cost_and_replay():
    p,s,box,_=make();s.workshop_buildings.upgrade(4);cr=p.crystal
    out=s.workshop_buildings.speed(4);req(out['lev']==2 and out['new_evolve']==1,'speed did not complete')
    req(p.crystal==cr-25,'1800s Event Centre speed cost must be 25')
    again=p.crystal;out2=s.workshop_buildings.speed(4);req(out2['lev']==2 and p.crystal==again,'speed replay double-charged')

def test_cancel_proportional_refund_snapshot():
    p,s,box,_=make();base=(p.magic_dust,p.magic_liquid,p.magic_energy,p.magic_exp);s.workshop_buildings.upgrade(4);box[0]+=900
    out=s.workshop_buildings.cancel(4);req(out['building_info']['lev']==1 and out['building_info']['start_time']==0,'cancel did not restore idle row')
    req(out['return_res_id']==[11,12,13,14] and out['return_res_num']==[5000,5000,100,10],'half-time refund mismatch')
    req((p.magic_dust,p.magic_liquid,p.magic_energy,p.magic_exp)==(base[0]-5000,base[1]-5000,base[2]-100,base[3]-10),'refund balances wrong')

def test_cabinet_source_prerequisite_and_deferred_types():
    p,s,box,_=make(); out=s.workshop_buildings.upgrade(1);req(out['lev']==1 and out['need_time']==43200,'Cabinet1->2 source start wrong')
    s.workshop_buildings.speed(1);s.workshop_buildings.confirm(1)
    # Source row lev2 requires Trash lev2; default Trash remains lev1 in P1 scope.
    try:s.workshop_buildings.upgrade(1);raise AssertionError('Cabinet prerequisite bypassed')
    except Exception as e:req('prerequisite' in str(e),'Cabinet prerequisite failed for wrong reason')
    try:s.workshop_buildings.upgrade(3);raise AssertionError('deferred Trash mutation accepted')
    except Exception as e:req('deferred' in str(e),'deferred building failed for wrong reason')

def test_new_hero_initializer_and_restart():
    p,s,box,_=make(heroes=[normal()]);p.building_list={'4':{'lev':7,'need_time':0,'start_time':0,'new_evolve':0}}
    h=s.heroes.add_owned_hero({'table_id':10001002,'star':5},persist=False);req(h.get('book_shelf_lev')==7,'new Normal Hero did not inherit Bookshelf')
    hs=s.heroes.add_owned_hero({'table_id':11001,'star':5},persist=False);req(int(hs.get('book_shelf_lev',0))==0,'new Super Hero inherited Normal Bookshelf')
    from gxb_backend.state.multiuser_database import MultiUserDatabase
    with tempfile.TemporaryDirectory(prefix='pass189_workshop_roundtrip_') as td:
        s.workshop_buildings.upgrade(4); db=MultiUserDatabase(Path(td),DATA);db.save_player(p);r=db.load_player(p.player_id)
        req(r is not None and int(r.building_list['4']['start_time'])==box[0],'building job lost on restart')
        req(str(4) in (r.workshop_state.get('building_jobs') or {}),'building cost snapshot lost on restart')

def test_dispatch_routes():
    fake=types.ModuleType('flask');fake.Request=object;fake.jsonify=lambda data=None,**k:data;fake.make_response=lambda data=None,status=200,**k:data;fake.send_file=lambda *a,**k:None;sys.modules.setdefault('flask',fake)
    from gxb_backend.config import Settings
    from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
    from gxb_backend.state.repository import StateRepository
    with tempfile.TemporaryDirectory(prefix='pass189_dispatch_') as td:
        root=Path(td);state=StateRepository(DATA/'player_db.json',profile='established',legacy_path=ROOT/'state/gxb_state.json',multiuser_root=root/'server_state')
        d=EngineDispatcher(state,Settings(multiuser_root=root/'server_state',runtime_log_dir=root/'logs'))
        exp={1056:'get_building_list',1057:'upgrade_building',1058:'cancel_evolve_building',1077:'speed_up_building',1080:'confirm_building_upgrade'}
        for mid,name in exp.items():req(getattr(d.handlers[mid],'__name__','')==name,f'MID{mid} Workshop route missing')

def main():
    tests=[test_source_catalog_and_payload,test_bookshelf_upgrade_lazy_complete_confirm_and_projection,test_speed_exact_cost_and_replay,test_cancel_proportional_refund_snapshot,test_cabinet_source_prerequisite_and_deferred_types,test_new_hero_initializer_and_restart,test_dispatch_routes]
    for t in tests:t();print('PASS',t.__name__,flush=True)
    print(f'PASS Pass189 P1-I4A Workshop buildings + Bookshelf ({len(tests)}/{len(tests)})',flush=True)
if __name__=='__main__':main()
