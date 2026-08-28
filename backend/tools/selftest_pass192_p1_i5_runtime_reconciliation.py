from __future__ import annotations
import copy, tempfile
from pathlib import Path
from types import SimpleNamespace

from gxb_backend.content import GameDataCatalog
from gxb_backend.handlers.bootstrap import BootstrapHandlers
from gxb_backend.handlers.inventory import InventoryHandlers
from gxb_backend.state.multiuser_database import MultiUserDatabase, SANDBOX_UID
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.server_clock import ServerClock

ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'data'; CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(c,m):
    if not c: raise AssertionError(m)

def course_hero(exp=1650):
    return {'partner_id':88001,'table_id':10001001,'star':5,'lev':100,'exp':0,'color':16,
            'skills':[1]*6,'equips':[1]*6,'fumos':[0]*6,'fumo_levels':[0]*6,
            'courses':[100101],'courses_progress':[100],'courses_skill':[0],
            'courses_quality':[5],'courses_exp':[exp]}

def make_services(*,hero=None,items=None):
    p=PlayerState(player_id='999192',account_uid='999192',player_name='Pass192')
    h=copy.deepcopy(hero or course_hero())
    p.heroes={str(h['partner_id']):h}; p.collected_heros={str(h['table_id']):{'table_id':h['table_id'],'star':5,'is_collected':1}}
    p.backpack_items=[{'table_id':int(i),'item_num':int(n),'time':0} for i,n in (items or {}).items()]
    s=RequestServices(p,DATA,lambda:None,catalog=CATALOG,server_clock=ServerClock(lambda:1_000_000))
    return p,s

def test_course_terminal_overshoot_caps_and_debits_once():
    p,s=make_services(items={50001421:3})
    out=s.courses.incr_course_exp({'partner_id':88001,'course_id':100101,'item_id':50001421,'item_num':1,'total_num':3})
    req(out['course_info']['exp']==1680 and out['course_info']['quality']==6,'1650+50 did not cap to source max 1680')
    req(out['total_num']==2,'terminal proficiency item not debited exactly once')
    replay=s.courses.incr_course_exp({'partner_id':88001,'course_id':100101,'item_id':50001421,'item_num':1,'total_num':3})
    req(replay['total_num']==2 and replay['course_info']['exp']==1680,'optimistic replay changed terminal result')

def test_course_shop_wire_contract():
    p,_=make_services(); out=p.shop_payload(29)
    for key in ('shop_type','refresh_times','open_time','is_open','count_down','items','hot_hero','cost_stone','is_awarded'):
        req(key in out,f'Course shop missing {key}')
    req(out['shop_type']==29 and out['is_open']==1 and isinstance(out['items'],list),'Course shop wire defaults invalid')

def test_stage3_bootstrap_hydrates_course_room_rows():
    p,_=make_services(); p.study_infos=[]
    class Repo:
        def payload(self): return {}
    class State:
        def get_player(self): return p
        def get_hero_repository(self): return Repo()
        def get_inventory_repository(self): return Repo()
        def get_summon_repository(self): return Repo()
    h=BootstrapHandlers(SimpleNamespace(state=State()))
    d=h._stage3_detail()
    req('2137' in d and d['2137']=={'study_infos':[]},'stage3 bootstrap omitted GET_STUDY_INFOS hydration')

def test_source_cabinet_book_compose_and_atomic_persistence():
    p,s=make_services(items={140001001:20})
    row=s.workshop_source.cabinet_book_compose(130001001)
    req(row and int(row['fragment_id'])==140001001 and int(row['fragment_num'])==20,'starter Cabinet compose source drift')
    class State:
        def get_services(self): return s
    out=InventoryHandlers(SimpleNamespace(state=State())).compose_item({'item_id':130001001,'item_num':1})
    req(out=={},'Cabinet composition failed')
    req(s.inventory.get_item_num(140001001)==0 and s.inventory.get_item_num(130001001)==1,'Cabinet composition did not atomically persist stacks')
    # Retry after commit is success-safe but cannot duplicate the unique book.
    InventoryHandlers(SimpleNamespace(state=State())).compose_item({'item_id':130001001,'item_num':1})
    req(s.inventory.get_item_num(130001001)==1,'Cabinet composition replay duplicated book')

def test_dev_workshop_seed_is_sandbox_only_one_shot_nonreplenishing():
    with tempfile.TemporaryDirectory(prefix='pass192_seed_') as td:
        db=MultiUserDatabase(Path(td),DATA)
        p=PlayerState(account_uid=SANDBOX_UID,player_id='sandbox192'); p.magic_exp=0; p.backpack_items=[]
        req(db._apply_pass192_debug_p1_i5_workshop_seed(p),'sandbox seed did not apply')
        req(p.magic_exp==51390,'Bookshelf full QA magic_exp budget wrong')
        row=next(x for x in p.backpack_items if int(x.get('table_id',0))==140001001)
        req(int(row['item_num'])==20,'starter Cabinet fragment seed wrong')
        row['item_num']=3
        req(not db._apply_pass192_debug_p1_i5_workshop_seed(p) and int(row['item_num'])==3,'one-shot seed replenished consumed fragments')
        q=PlayerState(account_uid='credential',player_id='credential192'); q.magic_exp=0; q.backpack_items=[]
        req(not db._apply_pass192_debug_p1_i5_workshop_seed(q) and q.magic_exp==0,'dev seed leaked to credential account')

def test_bookshelf_source_budget_proof():
    _,s=make_services(); total=0
    for level in range(1,100):
        row=s.workshop_source.bookshelf_level(level); ids=s.workshop_source.pipe_ints(row['resources_id']); nums=s.workshop_source.pipe_ints(row['resources_num'])
        total += dict(zip(ids,nums)).get(14,0)
    req(total==51390,'Bookshelf source cumulative magic_exp changed')

def main():
    tests=[test_course_terminal_overshoot_caps_and_debits_once,test_course_shop_wire_contract,test_stage3_bootstrap_hydrates_course_room_rows,test_source_cabinet_book_compose_and_atomic_persistence,test_dev_workshop_seed_is_sandbox_only_one_shot_nonreplenishing,test_bookshelf_source_budget_proof]
    for t in tests: t(); print('PASS',t.__name__,flush=True)
    print(f'PASS Pass192 P1-I5 runtime reconciliation ({len(tests)}/{len(tests)})',flush=True)
if __name__=='__main__': main()
