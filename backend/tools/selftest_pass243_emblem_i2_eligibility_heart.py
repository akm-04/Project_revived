#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import sys
import tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
DATA=ROOT/'data'

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.maintenance_services import PlayerMaintenanceServices
from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.projection_profiles import ProjectionProfileRegistry
from gxb_backend.state.response_projector import ResponseProjector
from gxb_backend.state.unit_of_work import OperationContext

CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')


def req(value: bool, message: str) -> None:
    if not value: raise AssertionError(message)


def hero(pid: int, *, stage: int=3, lev: int=100) -> dict:
    return {
        'partner_id':pid,'table_id':11001001,'star':5,'lev':lev,'exp':0,'color':15,
        'skills':[1]*6,'skill_ids':[0]*6,'equips':[0]*6,'fumos':[0]*6,'fumo_levels':[0]*6,
        'element_equips':[0]*4,'element_levels':[0]*4,'element_bak_equips':[],
        'element_bak_levels':[],'inscript_items':[],'twice_awake_stage':stage,
    }


def services(pid: int=243001, *, stage: int=3, hero_level: int=100, player_level: int=100, items=None):
    p=PlayerState(player_id=str(pid),account_uid=str(pid),player_name='Pass243-I2')
    p.lev=player_level; p.max_lev=100; p.heroes={str(pid):hero(pid,stage=stage,lev=hero_level)}
    p.func_ids=[int(v) for v in p.func_ids if int(v)!=45]
    p.function_state={'schema_version':1,'eligible_ids':[],'announced_ids':list(p.func_ids),'pending':{}}
    p.backpack_items=[{'table_id':int(i),'item_num':int(n),'time':0} for i,n in (items or {}).items() if int(n)>0]
    commits=[]
    s=RequestServices(p,DATA,lambda:commits.append(int(p.persistence_state.get('state_version',-1))),catalog=CATALOG)
    return p,s,commits


def test_current_source_i2_facts_packaged():
    source=DATA/'emblem_source_catalog.json'
    req(source.is_file(),'Emblem source catalog missing')
    import json
    d=json.loads(source.read_text())
    req(d['identity']['function_id']==45 and d['identity']['function_level']==100,'Function45 identity drift')
    req(d['identity']['eligibility']=='hero.isAwakeTwice() AND hero.level >= 100','per-Hero source gate drift')
    req(d['heart_recipe']=={'item_id':50001346,'components':[{'item_id':50001347,'count':60}],'mana':0},'Heart recipe drift')
    f=ROOT/'source_evidence/src_64/app/common/tables/FunctionOpenTable.lua'
    req(f.is_file(),'current FunctionOpenTable evidence missing')
    req(hashlib.sha256(f.read_bytes()).hexdigest()=='0494aed27d769e03924450cd554c759f7245823fa907688dfd9e7766f0481b44','FunctionOpenTable evidence hash drift')
    text=f.read_text(encoding='utf-8-sig')
    req('elseif var_2_3 == 7 then' in text and 'arg_1_0.levels_[var_2_0] = var_2_4' in text,'FunctionOpen type7 level behavior drift')


def test_level_100_is_pending_until_blood_hero_exists():
    p,s,_=services(stage=0,hero_level=100,player_level=99)
    delta=s.function_state.observe_level_progress(99,100,persist=False)
    p.lev=100
    req(45 in delta.eligible_ids,'Function45 not made level-eligible at 100')
    req(45 not in delta.announced_ids and not s.function_state.is_announced(45),'Function45 announced from level alone')
    req((s.function_state._root().get('pending') or {}).get('45',{}).get('policy')=='blood_awakened_hero_coordinated','Function45 pending policy missing')
    req(45 not in (s.apply_semantic_deltas({}).get('new_funcs_') or []),'level-only path staged NEW_FUNC_OPEN')


def test_blood_terminal_announces_function45_and_replays_wire():
    pid=243010; p,s,_=services(pid,stage=2,hero_level=100,player_level=100)
    s.function_state.ensure_level_eligible(45,100,persist=False)
    req(not s.function_state.is_announced(45),'test precondition Function45 already announced')
    with s.uow.transaction(OperationContext(actor_player_id=str(pid),domain='pass243',operation_name='seed_blood_terminal')):
        s.awakening_missions._set_active(2,{
            'mission_id':2001002,'awake_type':2,'hero_partner_id':pid,'hero_table_id':11001001,
            'stage':2,'generation':243,'complete':False,'count':0,'opened_at':p.now(),
        })
    req(s.awakening_missions.unlimited_start({'twice_awake_mission':2001002,'incubus_id':2001002})=={},'MID866 setup failed')
    result=s.awakening_missions.unlimited_result({'twice_awake_mission':2001002,'incubus_id':2001002,'num':20,'npc_ids':{}})
    req(result.get('items')==[],'MID867 setup failed')
    raw=s.awakening_missions.claim(2001002)
    req(raw.get('twice_awake_stage_')=={'table_id':11001001,'stage':3},f'Blood terminal projection drift {raw}')
    req(raw.get('new_funcs_')==[45],f'Function45 not embedded in terminal replay payload {raw}')
    projected=s.apply_semantic_deltas(raw)
    req(projected.get('new_funcs_')==[45],'Function45 semantic projection drift')
    req(p.heroes[str(pid)]['twice_awake_stage']==3 and s.function_state.is_announced(45),'Blood terminal did not persist stage3+Function45')
    replay=s.awakening_missions.claim(2001002)
    req(replay.get('new_funcs_')==[45] and replay.get('twice_awake_stage_',{}).get('stage')==3,'MID161 response-loss replay lost Function45')


def test_maintenance_repairs_historical_qualifier_without_semantic_channel():
    p=PlayerState(player_id='243020',account_uid='243020',player_name='Pass243-maint')
    p.lev=100; p.max_lev=100; p.heroes={'243020':hero(243020,stage=3,lev=100)}
    p.func_ids=[int(v) for v in p.func_ids if int(v)!=45]
    p.function_state={'schema_version':1,'eligible_ids':[],'announced_ids':list(p.func_ids),'pending':{}}
    m=PlayerMaintenanceServices(p,DATA)
    req(m.emblem_eligibility.maintenance_reconcile(),'maintenance did not repair missing Function45')
    req(m.function_state.is_eligible(45) and m.function_state.is_announced(45) and 45 in p.func_ids,'maintenance Function45 state drift')
    req(not m.emblem_eligibility.maintenance_reconcile(),'maintenance repair not idempotent')


def test_multiuser_load_maintenance_repairs_function45():
    p=PlayerState(player_id='243021',account_uid='243021',player_name='Pass243-db-maint')
    p.lev=100; p.max_lev=100; p.heroes={'243021':hero(243021,stage=3,lev=100)}
    p.func_ids=[int(v) for v in p.func_ids if int(v)!=45]
    p.function_state={'schema_version':1,'eligible_ids':[],'announced_ids':list(p.func_ids),'pending':{}}
    with tempfile.TemporaryDirectory(prefix='pass243-db-') as td:
        db=MultiUserDatabase(Path(td),DATA)
        req(db.normalize_player(p,persist=False),'MultiUserDatabase normalization did not report Function45 repair')
        req(45 in p.func_ids and 45 in (p.function_state.get('announced_ids') or []),'MultiUserDatabase normalization failed Function45 repair')
        before=(list(p.func_ids), dict(p.function_state))
        db.normalize_player(p,persist=False)
        after=(list(p.func_ids), dict(p.function_state))
        req(after==before,'second MultiUserDatabase normalization changed I2 Function45 state')


def test_insert_enforces_hero_gate_but_remove_is_recovery_safe():
    # stage2 is not eligible even at level100.
    p,s,_=services(243030,stage=2,items={160100101:1})
    before=s.stack_inventory.quantity(160100101)
    out=s.emblem.insert({'partner_id':243030,'item_id':160100101})
    req(out.get('msg')=='emblem_hero_not_eligible' and s.stack_inventory.quantity(160100101)==before,'stage2 insert gate failed')
    req(not s.uow.consume_journal(),'rejected stage2 insert mutated journal')
    # Blood stage3 but Hero level99 is still ineligible.
    p2,s2,_=services(243031,stage=3,hero_level=99,items={160100101:1})
    req(s2.emblem.insert({'partner_id':243031,'item_id':160100101}).get('msg')=='emblem_hero_not_eligible','level99 insert gate failed')
    # Exact canonical Hero gate authorizes insert even if Function45 itself has not yet been announced.
    p3,s3,_=services(243032,stage=3,hero_level=100,items={160100101:1})
    req(not s3.function_state.is_announced(45),'insert fixture unexpectedly announced Function45')
    req(s3.emblem.insert({'partner_id':243032,'item_id':160100101})=={'inscript_items':[160100101]},'eligible insert failed')
    # Recovery policy: malformed/imported state must not trap an already-equipped medal.
    p3.heroes['243032']['twice_awake_stage']=0
    p3.crystal=100
    out=s3.emblem.remove({'partner_id':243032,'item_id':160100101})
    req(out=={'inscript_items':[]} and s3.stack_inventory.quantity(160100101)==1 and p3.crystal==80,'recovery-safe remove drift')


def test_heart_mid83_provider_exact_and_bounded():
    p,s,_=services(243040,items={50001347:120})
    p.mana=777777
    out=s.item_composition.compose({'item_id':50001346,'item_num':2})
    req(out=={},f'Heart compose response drift {out}')
    req(s.stack_inventory.quantity(50001347)==0 and s.stack_inventory.quantity(50001346)==2,'Heart x2 settlement drift')
    req(p.mana==777777,'Heart compose incorrectly charged Mana')
    journal=s.uow.consume_journal()
    req([r.get('category') for r in journal]==['STACK','STACK'],'Heart compose journal should be fragment debit + Heart credit only')
    # Current SelfPlayer.makeItem() reconciles target/components locally after
    # MID83 OK. The default web projector must therefore keep the wire body
    # empty and must never synthesize the Heart STACK credit as a generic award.
    profiles=ProjectionProfileRegistry.load(DATA/'projection_profile_registry.json')
    projector=ResponseProjector.capture(p,resource_registry=s.resource_registry)
    projected=projector.project({},p,committed_journal=journal,profile=profiles.resolve(mid=83,label='COMPOSE_ITEM',transport='engine_web'))
    req(projected=={},f'MID83 Heart projection would double-apply stock local Backpack mutation: {projected}')
    # insufficient source material must fail atomically.
    p2,s2,_=services(243041,items={50001347:59})
    bad=s2.item_composition.compose({'item_id':50001346,'item_num':1})
    req(bad.get('error_code')==1 and s2.stack_inventory.quantity(50001347)==59 and s2.stack_inventory.quantity(50001346)==0,'insufficient Heart fragments not atomic')
    # Unknown generic item-table recipes remain fenced by the provider allowlist.
    unknown=s2.item_composition.compose({'item_id':50001349,'item_num':1})
    req(unknown=={'awards':[]},'I2 accidentally widened global MID83 composition')


def test_rng_routes_still_fenced():
    _,s,_=services(243050)
    for out in (
        s.emblem.make({'inscript_id':10001,'make_num':1}),
        s.emblem.rebuild({'item_id':160100101,'rebuild_num':1,'cost_type':2}),
        s.emblem.save_rebuild({'item_id':160100102}),
        s.emblem.abandon_rebuild({}),
    ):
        req(out.get('error_code')==1 and out.get('msg')==s.emblem.UNRESOLVED_MESSAGE,'I2 opened an RNG route early')


def main() -> None:
    tests=[
        test_current_source_i2_facts_packaged,
        test_level_100_is_pending_until_blood_hero_exists,
        test_blood_terminal_announces_function45_and_replays_wire,
        test_maintenance_repairs_historical_qualifier_without_semantic_channel,
        test_multiuser_load_maintenance_repairs_function45,
        test_insert_enforces_hero_gate_but_remove_is_recovery_safe,
        test_heart_mid83_provider_exact_and_bounded,
        test_rng_routes_still_fenced,
    ]
    for test in tests:
        test(); print('PASS',test.__name__)
    print(f'PASS Pass243 Emblem I2 eligibility + Function45 + Heart ({len(tests)} tests)')

if __name__=='__main__': main()
