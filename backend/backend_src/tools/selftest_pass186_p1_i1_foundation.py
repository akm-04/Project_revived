#!/usr/bin/env python3
from __future__ import annotations
import copy, sys, tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.course_source_catalog import CourseSourceCatalog
from gxb_backend.content.white_album_source_catalog import WhiteAlbumSourceCatalog
from gxb_backend.content.workshop_source_catalog import WorkshopSourceCatalog
from gxb_backend.content.element_equipment_source_catalog import ElementEquipmentSourceCatalog
from gxb_backend.state.durable_timed_job import DurableJobState, DurableTimedJobPolicy
from gxb_backend.state.event_centre_acceleration_policy import EventCentreAccelerationPolicy
from gxb_backend.state.hero_creation_initializers import HeroCreationInitializerRegistry
from gxb_backend.state.hero_course_state_adapter import HeroCourseStateAdapter
from gxb_backend.state.hero_entity_mutation_service import HeroEntityMutationService, HeroEntityMutationError
from gxb_backend.state.hero_progression_repository import HeroProgressionRepository
from gxb_backend.state.hero_repository import HeroRepository
from gxb_backend.state.mutation_plan import EntityMutation
from gxb_backend.state.p1_foundation_state import P1FoundationStateNormalizer
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.unit_of_work import PlayerUnitOfWork
from gxb_backend.state.vip_policy import VipPrivilegeResolver, VipProgressionPolicy
from gxb_backend.state.request_services import RequestServices

DATA=ROOT/'data'

def hero(pid=10001,table=10001001):
    return {'partner_id':pid,'table_id':table,'star':5,'lev':100,'color':16,'skills':[1]*6,'equips':[1]*6,'fumos':[0]*6,'fumo_levels':[0]*6}

def check_source_catalogs():
    c=CourseSourceCatalog(DATA); a=WhiteAlbumSourceCatalog(DATA); w=WorkshopSourceCatalog(DATA); e=ElementEquipmentSourceCatalog(DATA)
    assert (len(c.subjects),len(c.classes),len(c.books),len(c.book_colors),c.study_seconds)==(4,12,48,6,28800)
    assert c.application_item_for_course(100101)==160600001
    assert len(a.normal)==132 and len(a.special)==23 and a.special_set(23)
    assert (len(w.bookshelf),len(w.cabinet),len(w.cabinet_books),len(w.cabinet_skills))==(100,6,54,399)
    assert len(e.by_item_id)==80

def check_timed_policies():
    p=DurableTimedJobPolicy()
    assert p.snapshot(start_time=0,need_time=28800,now=10).state==DurableJobState.IDLE
    r=p.snapshot(start_time=100,need_time=100,now=150); assert r.state==DurableJobState.RUNNING and r.remaining==50 and r.progress==0.5
    r=p.snapshot(start_time=100,need_time=100,now=250); assert r.state==DurableJobState.READY and r.remaining==0 and r.progress==1.0
    acc=EventCentreAccelerationPolicy()
    assert [acc.crystal_cost(x) for x in (0,72,14399,14400,43199,43200,86400)]==[1,1,200,200,400,400,500]

def check_vip_and_study_shape():
    policy=VipProgressionPolicy(DATA)
    p=PlayerState(vip=15); assert VipPrivilegeResolver(p,policy).study_room_limit()==5
    p.vip=0; assert VipPrivilegeResolver(p,policy).study_room_limit()==2
    p.study_infos=[]; assert p.study_payload()=={'study_infos':[]}

def check_state_migration():
    p=PlayerState()
    p.study_infos={'infos':{}}  # legacy Pass183 bootstrap shape
    p.white_album_state={'special_claims':{'1':1,'999':1}}
    p.heroes={'10001':hero()}
    p.heroes['10001']['book_shelf_lev']=7
    p.heroes['10001']['skill_book_info']={'10010001':2,'99999999':9}
    p.building_list=[{'building_id':4,'lev':3,'need_time':0,'start_time':0,'new_evolve':0}]
    p.workshop_state={'book_info':{'10010001':1,'99999999':5}}
    g=GameDataCatalog.load(DATA/'game_data_catalog.json'); a=WhiteAlbumSourceCatalog(DATA); w=WorkshopSourceCatalog(DATA)
    n=P1FoundationStateNormalizer(p,album=a,workshop=w,game_data=g)
    assert n.normalize() is True
    assert p.study_infos==[]
    assert p.white_album_state['special_claims']=={'1':1}
    assert p.building_list['4']['lev']==7 and p.heroes['10001']['book_shelf_lev']==7
    assert p.workshop_state['book_info'].get('10010001')==2 and '99999999' not in p.workshop_state['book_info']
    assert p.workshop_state['cabinet_info']['cur_learn_skill']==0 and p.workshop_state['building_jobs']=={}
    frozen=copy.deepcopy(p.__dict__); assert n.normalize() is False; assert p.__dict__==frozen

def check_initializer_and_typed_mutations():
    p=PlayerState(); p.heroes={}
    registry=HeroCreationInitializerRegistry(); registry.register('test',lambda record,player: record.__setitem__('book_shelf_lev',42))
    hrepo=HeroRepository(p,data_dir=DATA,creation_initializers=registry,catalog=GameDataCatalog.load(DATA/'game_data_catalog.json'))
    created=hrepo.add_owned_hero({'table_id':10001001,'star':5},persist=False); pid=created['partner_id']; assert created['book_shelf_lev']==42
    uow=PlayerUnitOfWork(p,lambda:None); prog=HeroProgressionRepository(p,DATA,heroes=hrepo,uow=uow,catalog=GameDataCatalog.load(DATA/'game_data_catalog.json'))
    owner=HeroEntityMutationService(hrepo,prog,uow)
    owner.apply(EntityMutation('HERO',pid,'COURSE_ACQUIRE',indices=(100101,)))
    owner.apply(EntityMutation('HERO',pid,'COURSE_SET_PROGRESS',amount=40,indices=(100101,)))
    owner.apply(EntityMutation('HERO',pid,'COURSE_BIND_SKILL',amount=2,indices=(100101,)))
    owner.apply(EntityMutation('HERO',pid,'COURSE_SET_EXP_QUALITY',indices=(100101,),counts=(3,17)))
    rec=HeroCourseStateAdapter.records(hrepo.get(pid))[0]; assert (rec.course_id,rec.progress,rec.skill,rec.quality,rec.exp)==(100101,40,2,3,17)
    owner.apply(EntityMutation('HERO',pid,'WHITE_ALBUM_SET_STAGES',counts=(2,1)))
    owner.apply(EntityMutation('HERO',pid,'SET_BOOKSHELF_LEVEL',amount=55))
    owner.apply(EntityMutation('HERO',pid,'SET_CABINET_SKILL_LEVEL',amount=2,indices=(10010001,)))
    after=hrepo.get(pid); assert after['collect_quality_stage']==2 and after['collect_star_stage']==1 and after['book_shelf_lev']==55 and after['skill_book_info']['10010001']==2
    try: owner.apply(EntityMutation('HERO',pid,'WHITE_ALBUM_SET_STAGES',counts=(1,0)))
    except HeroEntityMutationError: pass
    else: raise AssertionError('White Album downgrade accepted')
    owner.apply(EntityMutation('HERO',pid,'COURSE_FORGET',indices=(100101,)))
    assert HeroCourseStateAdapter.records(hrepo.get(pid))==()

def check_composition():
    p=PlayerState(); p.heroes={'10001':hero()}
    services=RequestServices(p,DATA,lambda:None,catalog=GameDataCatalog.load(DATA/'game_data_catalog.json'))
    assert services.course_source.study_seconds==28800
    assert services.white_album_source.special_set(1)
    assert services.workshop_source.cabinet_skill(10010001)
    assert services.element_source.item(20001407)
    assert services.hero_creation_initializers.names==()
    assert services.p1_foundation_state is not None

TESTS=[check_source_catalogs,check_timed_policies,check_vip_and_study_shape,check_state_migration,check_initializer_and_typed_mutations,check_composition]
if __name__=='__main__':
    for fn in TESTS:
        fn(); print(f'PASS {fn.__name__}')
    print(f'PASS186 P1-I1 foundation: {len(TESTS)}/{len(TESTS)} PASS')
