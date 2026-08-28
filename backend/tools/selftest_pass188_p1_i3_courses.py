from __future__ import annotations
import copy, sys, tempfile, types
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.protocol.mids import MID
from gxb_backend.state.hero_course_state_adapter import HeroCourseStateAdapter
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.server_clock import ServerClock
from gxb_backend.transport.result import EngineTransportResult

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'data'
CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(cond,msg):
    if not cond: raise AssertionError(msg)

def hero(pid=88001,tid=10001001,courses=None):
    h={'partner_id':pid,'table_id':tid,'star':5,'lev':100,'exp':0,'color':16,
       'skills':[1]*6,'equips':[1]*6,'fumos':[0]*6,'fumo_levels':[0]*6,
       'element_equips':[0]*4,'element_levels':[0]*4,
       'courses':[],'courses_progress':[],'courses_skill':[],'courses_quality':[],'courses_exp':[]}
    if courses:
        h['courses']=[r[0] for r in courses];h['courses_progress']=[r[1] for r in courses];h['courses_skill']=[r[2] for r in courses];h['courses_quality']=[r[3] for r in courses];h['courses_exp']=[r[4] for r in courses]
    return h

def make_services(hs=None,items=None,clock_box=None,vip=15):
    p=PlayerState(player_id='998801',account_uid='998801',player_name='Pass188');p.vip=vip
    hs=hs or [hero()];p.heroes={str(h['partner_id']):copy.deepcopy(h) for h in hs}
    p.collected_heros={str(h['table_id']):{'table_id':h['table_id'],'star':h['star'],'is_collected':1} for h in hs}
    p.backpack_items=[{'table_id':int(i),'item_num':int(n),'time':0} for i,n in (items or [])]
    box=clock_box or [1_000_000]
    commits=[]
    s=RequestServices(p,DATA,lambda:commits.append(int(p.persistence_state.get('state_version',-1))),catalog=CATALOG,server_clock=ServerClock(lambda:box[0]))
    return p,s,box,commits

def rec(s,pid,cid):
    h=s.heroes.get(pid);return next((r for r in HeroCourseStateAdapter.records(h) if r.course_id==cid),None)

def test_source_constants_and_policy():
    _,s,_,_=make_services()
    c=s.course_source
    req((len(c.subjects),len(c.classes),len(c.books),len(c.book_colors))==(4,12,48,6),'course census drift')
    req(c.study_seconds==28800 and c.forget_crystal==200 and c.speed_money==30,'course misc drift')
    req(c.proficiency_for_item(50001420)==10 and c.proficiency_for_item(50001423)==1250,'proficiency item decode drift')
    req(c.quality_for_exp(89)==1 and c.quality_for_exp(90)==2 and c.quality_for_exp(1680)==6,'quality thresholds drift')
    req(c.forget_returns(3)==((50001421,2),(50001420,2)),'source forget returns drift')
    req(c.speed_cost(28800)==240 and c.speed_cost(1801)==30 and c.speed_cost(1800)==15,'speed formula drift')
    req(s.course_study_progress.complete(0)==20 and s.course_study_progress.complete(95)==100,'compat progress policy drift')

def test_apply_and_first_study_idempotency():
    p,s,box,_=make_services(items=[(160600001,4)])
    out=s.courses.apply_course(88001,100101);req(out['course_info']['progress']==0,'apply did not acquire')
    req(s.inventory.get_item_num(160600001)==3,'apply application spend wrong')
    s.courses.apply_course(88001,100101);req(s.inventory.get_item_num(160600001)==3,'duplicate apply double-spent')
    # Separate first-time STUDY path acquires and starts atomically.
    p2,s2,box2,_=make_services(items=[(160600002,3)])
    out=s2.courses.study(88001,100201);req(out['course_info']['progress']==0 and len(out['study_infos'])==1,'first Study did not start')
    req(s2.inventory.get_item_num(160600002)==2,'Study application spend wrong')
    s2.courses.study(88001,100201);req(s2.inventory.get_item_num(160600002)==2,'duplicate Study double-spent')
    req(out['study_infos'][0]['need_time']==28800,'Study duration wrong')

def test_lazy_completion_and_continue_to_100():
    p,s,box,_=make_services(items=[(160600001,2)])
    s.courses.study(88001,100101)
    # Studyroom poll renders ENDED but does not materialize.
    box[0]+=28800
    out=s.courses.get_studyroom_info({});req(len(out['study_infos'])==1 and rec(s,88001,100101).progress==0,'studyroom poll auto-completed')
    out=s.courses.get_course_info(88001);req(rec(s,88001,100101).progress==20 and out['study_infos']==[],'GET_COURSE_INFO did not materialize one completion')
    # Repeated GET is idempotent; then four CONTINUE cycles use no application items.
    s.courses.get_course_info(88001);req(rec(s,88001,100101).progress==20,'completion replay double-progressed')
    before=s.inventory.get_item_num(160600001)
    for expected in (40,60,80,100):
        s.courses.continue_study(88001,100101);box[0]+=28800;s.courses.get_course_info(88001)
        req(rec(s,88001,100101).progress==expected,f'continue completion expected {expected}')
    req(s.inventory.get_item_num(160600001)==before,'CONTINUE consumed application item')

def test_room_speed_cancel_and_capacity():
    hs=[hero(88100+i,10001001+i) for i in range(6)]
    p,s,box,_=make_services(hs=hs,items=[])
    limit=s.vip_privileges.study_room_limit();req(limit==5,'dev VIP study-room source limit drift')
    for h in hs[:limit]: s.courses.enter_room(h['partner_id'])
    try:s.courses.enter_room(hs[limit]['partner_id']);raise AssertionError('room cap accepted extra hero')
    except Exception as exc:req('limit' in str(exc),'room cap failed for wrong reason')
    # Speed a known incomplete course from full 8h -> exact 240 Crystal and +20.
    p2,s2,box2,_=make_services(hs=[hero(courses=[(100101,80,0,1,0)])])
    before=s2.economy_ledger.balance('crystal');s2.courses.continue_study(88001,100101);out=s2.courses.speed_study(88001,100101)
    req(rec(s2,88001,100101).progress==100 and out['study_infos']==[],'speed did not complete')
    req(s2.economy_ledger.balance('crystal')==before-240,'full speed Crystal cost wrong')
    again=s2.economy_ledger.balance('crystal');s2.courses.speed_study(88001,100101);req(s2.economy_ledger.balance('crystal')==again,'speed replay double-charged')
    # Cancellation removes job without progress.
    p3,s3,box3,_=make_services(hs=[hero(courses=[(100101,40,0,1,0)])]);s3.courses.continue_study(88001,100101);s3.courses.cancel_study(88001)
    req(rec(s3,88001,100101).progress==40 and s3.courses.get_study_infos({})['study_infos']==[],'cancel mutated course progress')

def test_binding_proficiency_forget_and_replays():
    p,s,box,_=make_services(hs=[hero(courses=[(100101,100,0,1,0),(100102,100,0,1,0)])],items=[(50001420,20)])
    s.courses.add_skill(88001,100101,1);s.courses.add_skill(88001,100102,1)
    req(rec(s,88001,100101).skill==0 and rec(s,88001,100102).skill==1,'one-course-per-skill binding not enforced')
    out=s.courses.incr_course_exp({'partner_id':88001,'course_id':100102,'item_id':50001420,'item_num':9,'total_num':20})
    req(out['course_info']['exp']==90 and out['course_info']['quality']==2 and out['total_num']==11,'proficiency/quality update wrong')
    # optimistic total replay
    out2=s.courses.incr_course_exp({'partner_id':88001,'course_id':100102,'item_id':50001420,'item_num':9,'total_num':20})
    req(out2['total_num']==11 and rec(s,88001,100102).exp==90,'proficiency replay double-consumed')
    crystal=s.economy_ledger.balance('crystal');out=s.courses.forget_course(88001,100102)
    req(rec(s,88001,100102) is None and s.economy_ledger.balance('crystal')==crystal-200,'forget mutation/cost wrong')
    req(out['return_items']==[{'item_id':50001421,'item_num':1}] and s.inventory.get_item_num(50001421)==1,'forget source refund wrong')
    crystal2=s.economy_ledger.balance('crystal');s.courses.forget_course(88001,100102);req(s.economy_ledger.balance('crystal')==crystal2,'forget replay double-charged/refunded')

def test_persistence_roundtrip():
    from gxb_backend.state.multiuser_database import MultiUserDatabase
    with tempfile.TemporaryDirectory(prefix='pass188_course_roundtrip_') as td:
        p,s,box,_=make_services(items=[(160600001,2)])
        s.courses.study(88001,100101);box[0]+=28800;s.courses.get_course_info(88001);s.courses.continue_study(88001,100101)
        db=MultiUserDatabase(Path(td),DATA);db.save_player(p);r=db.load_player(p.player_id);req(r is not None,'course restart load failed')
        rh=r.heroes.get('88001') or r.heroes.get(88001);rr=next(x for x in HeroCourseStateAdapter.records(rh) if x.course_id==100101)
        req(rr.progress==20,'course progress lost on restart')
        req(len(r.study_infos)==1 and int(r.study_infos[0].get('course_id',0))==100101,'study job lost on restart')

def test_safe_unknowns_and_dispatch_routes():
    p,s,_,_=make_services();req(s.courses.courses_recommend({})=={'recommend_list':[]},'recommendation not safe-empty')
    g=s.courses.gift_box_info({});req(g.get('is_has_gift')==0,'gift box bootstrap lacks source-required flag')
    fake=types.ModuleType('flask');fake.Request=object;fake.jsonify=lambda data=None,**k:data;fake.make_response=lambda data=None,status=200,**k:data;fake.send_file=lambda *a,**k:None
    sys.modules.setdefault('flask',fake)
    from gxb_backend.config import Settings
    from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
    from gxb_backend.state.repository import StateRepository
    with tempfile.TemporaryDirectory(prefix='pass188_dispatch_') as td:
        root=Path(td);state=StateRepository(DATA/'player_db.json',profile='established',legacy_path=ROOT/'state/gxb_state.json',multiuser_root=root/'server_state')
        d=EngineDispatcher(state,Settings(multiuser_root=root/'server_state',runtime_log_dir=root/'logs'))
        expected={2128:'apply_course',2129:'get_course_info',2130:'get_studyroom_info',2131:'study',2132:'speed_study',2133:'add_skill',2134:'forget_course',2135:'enter_room',2136:'leave_room',2137:'get_study_infos',2138:'cancel_study',2139:'get_gift_box_info',2140:'incr_course_exp',2141:'open_gift_box',2142:'continue_study',2500:'get_courses_recommend'}
        for mid,name in expected.items():req(getattr(d.handlers[mid],'__name__','')==name,f'Course MID {mid} route drift')
        blocked=d.handlers[MID.OPEN_GIFT_BOX]({});req(isinstance(blocked,EngineTransportResult) and blocked.status_code==409,'Gift Box awards not fail-closed')

def main():
    tests=[test_source_constants_and_policy,test_apply_and_first_study_idempotency,test_lazy_completion_and_continue_to_100,test_room_speed_cancel_and_capacity,test_binding_proficiency_forget_and_replays,test_persistence_roundtrip,test_safe_unknowns_and_dispatch_routes]
    for t in tests:t();print('PASS',t.__name__,flush=True)
    print(f'PASS Pass188 P1-I3 Courses ({len(tests)}/{len(tests)})',flush=True)

if __name__=='__main__':main()
