from __future__ import annotations
import copy
from pathlib import Path
from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.server_clock import ServerClock

ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'data'; CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(c,m):
    if not c: raise AssertionError(m)

def make():
    p=PlayerState(player_id='999193',account_uid='999193',player_name='Pass193')
    p.mana=10_000_000;p.magic_dust=10_000_000;p.magic_liquid=10_000_000;p.magic_energy=100_000;p.crystal=999_999
    h={'partner_id':90001,'table_id':10001001,'star':5,'lev':100,'exp':0,'color':16,'skills':[1]*6,'equips':[1]*6,'fumos':[0]*6,'fumo_levels':[0]*6,'book_shelf_lev':1,'skill_book_info':{}}
    p.heroes={'90001':copy.deepcopy(h)};p.collected_heros={'10001001':{'table_id':10001001,'star':5,'is_collected':1}}
    p.building_list={'1':{'lev':1,'need_time':0,'start_time':0,'new_evolve':0},'3':{'lev':1,'need_time':0,'start_time':0,'new_evolve':0},'4':{'lev':1,'need_time':0,'start_time':0,'new_evolve':0}}
    p.backpack_items=[{'table_id':130001001,'item_num':1,'time':0}]
    box=[1_000_000]
    s=RequestServices(p,DATA,lambda:None,catalog=CATALOG,server_clock=ServerClock(lambda:box[0]))
    return p,s,box

def test_mid1078_complete_book_wire():
    p,s,box=make()
    skills=tuple(s.workshop_source.cabinet_book_skills(130001001)); req(len(skills)==7,'Introduction skill census drift')
    s.cabinet_research.learn(10010001)
    out=s.cabinet_research.speed(10010001)
    req(out['book_id']=='130001001','MID1078 book_id drift')
    req(set(out['book_info'])=={str(x) for x in skills},'MID1078 must return every source skill in the book')
    req(out['book_info']['10010001']['lev']==1,'completed root level missing')
    for sid in skills:
        if sid!=10010001:req(out['book_info'][str(sid)]=={'lev':0},f'unlearned skill {sid} must be explicit lev=0')

def test_mid1078_replay_wire_is_identical_and_free():
    p,s,box=make(); s.cabinet_research.learn(10010001); first=s.cabinet_research.speed(10010001); crystal=p.crystal
    replay=s.cabinet_research.speed(10010001)
    req(replay['book_info']==first['book_info'],'MID1078 replay wire drift')
    req(p.crystal==crystal,'MID1078 replay double charged')

def test_durable_book_state_stays_sparse():
    p,s,box=make(); s.cabinet_research.learn(10010001); s.cabinet_research.speed(10010001)
    durable=(p.workshop_state.get('book_info') or {}).get('130001001') or {}
    req(durable=={'10010001':{'lev':1}},'wire hydration polluted canonical sparse durable book_info')
    getinfo=s.cabinet_research.get_info()['book_info']['130001001']
    req(getinfo=={'10010001':{'lev':1}},'GET_CABINET_INFO sparse source-shaped behavior changed unexpectedly')

def main():
    tests=[test_mid1078_complete_book_wire,test_mid1078_replay_wire_is_identical_and_free,test_durable_book_state_stays_sparse]
    for t in tests:t();print('PASS',t.__name__,flush=True)
    print(f'PASS Pass193 Cabinet MID1078 wire reconciliation ({len(tests)}/{len(tests)})',flush=True)
if __name__=='__main__':main()
