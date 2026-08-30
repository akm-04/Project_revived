#!/usr/bin/env python3
from __future__ import annotations

import inspect
import sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
DATA=ROOT/'data'

from gxb_backend.content import EmblemSourceCatalog, GameDataCatalog
from gxb_backend.handlers.heroes import HeroHandlers
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices

CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')


def req(value: bool, message: str) -> None:
    if not value: raise AssertionError(message)


def hero(pid: int=242001) -> dict:
    return {
        'partner_id':pid,'table_id':10121,'star':5,'lev':100,'exp':0,'color':15,
        'skills':[1]*6,'equips':[1]*6,'fumos':[0]*6,'fumo_levels':[0]*6,
        'element_equips':[0]*4,'element_levels':[0]*4,'element_bak_equips':[],
        'element_bak_levels':[],'inscript_items':[],'twice_awake_stage':3,
    }


def services(*, crystal: int=1000):
    p=PlayerState(player_id='242001',account_uid='242001',player_name='Pass242-I1')
    p.lev=100; p.max_lev=100; p.crystal=crystal; p.heroes={'242001':hero()}; p.backpack_items=[]
    commits=[]
    s=RequestServices(p,DATA,lambda:commits.append(int(p.persistence_state.get('state_version',-1))),catalog=CATALOG)
    return p,s,commits


def seed(p: PlayerState, *pairs: tuple[int,int]) -> None:
    p.backpack_items=[{'table_id':int(i),'item_num':int(n),'time':0} for i,n in pairs if n>0]


def test_live_handlers_route_to_single_emblem_owner():
    text=inspect.getsource(HeroHandlers)
    req('get_emblem_service().insert(req)' in text,'MID1402 handler not routed to EmblemService')
    req('get_emblem_service().remove(req)' in text,'MID1403 handler not routed to EmblemService')
    req('get_emblem_service().resolve(req)' in text,'MID1404 handler not routed to EmblemService')
    req('get_emblem_service().exchange_materials(req)' in text,'MID1407 handler not routed to EmblemService')
    p,s,_=services()
    req(s.hero_advanced.emblem_service is s.emblem,'legacy HeroAdvanced shim does not delegate to live Emblem owner')
    req(s.emblem.make({'inscript_id':10001,'make_num':1})['error_code']==1,'MID1400 unexpectedly enabled')
    req(s.emblem.rebuild({'item_id':160100101})['error_code']==1,'MID1401 unexpectedly enabled')
    req(s.emblem.save_rebuild({'item_id':160100102})['error_code']==1,'MID1405 unexpectedly enabled')
    req(s.emblem.abandon_rebuild({})['error_code']==1,'MID1406 unexpectedly enabled')


def test_source_position_resolver_matches_stock_fallback():
    source=EmblemSourceCatalog(DATA)
    req(source.physical_position(160100101)==1,'ordinary Excellence position drift')
    req(source.physical_position(160200101)==2,'ordinary Honor position drift')
    req(source.physical_position(160300101)==3,'ordinary Specialty position drift')
    req(source.physical_position(160400101)==1,'Scholarship pos1 fallback drift')
    req(source.physical_position(160400102)==2,'Scholarship pos2 fallback drift')
    req(source.physical_position(160500103)==3,'Scholarship pos3 fallback drift')
    req(source.physical_position(160200111)==2,'Honor artifact position drift')
    for item_id in source.concrete_item_ids():
        req(source.physical_position(item_id) in (1,2,3),f'concrete Emblem {item_id} has invalid physical position')


def test_ordinary_insert_remove_parity_and_atomic_cost():
    p,s,c=services(crystal=100)
    seed(p,(160100101,1))
    out=s.emblem.insert({'partner_id':242001,'item_id':160100101})
    journal=s.uow.consume_journal()
    req(out=={'inscript_items':[160100101]},'ordinary insert wire drift')
    req(s.stack_inventory.quantity(160100101)==0 and p.crystal==100,'empty insert economy drift')
    req([r['category'] for r in journal]==['STACK','ENTITY'],'empty insert journal drift')
    req(len(c)==1,'empty insert did not commit once')

    seed(p,(160100102,1))
    rejected=s.emblem.insert({'partner_id':242001,'item_id':160100102})
    req(rejected=={'error_code':1} and s.stack_inventory.quantity(160100102)==1 and p.crystal==100,'occupied slot insert did not fail closed')
    req(not s.uow.consume_journal(),'rejected occupied insert staged journal')

    out=s.emblem.insert({'partner_id':242001,'item_id':160100102,'replace_item_id':160100101})
    journal=s.uow.consume_journal()
    req(out=={'inscript_items':[160100102]},'ordinary replacement wire drift')
    req(p.crystal==80 and s.stack_inventory.quantity(160100101)==1 and s.stack_inventory.quantity(160100102)==0,'ordinary replacement settlement drift')
    req([r['category'] for r in journal]==['RESOURCE','STACK','STACK','ENTITY'],'replacement journal drift')

    out=s.emblem.remove({'partner_id':242001,'item_id':160100102})
    journal=s.uow.consume_journal()
    req(out=={'inscript_items':[]},'ordinary remove wire drift')
    req(p.crystal==60 and s.stack_inventory.quantity(160100102)==1,'ordinary remove settlement drift')
    req([r['category'] for r in journal]==['RESOURCE','STACK','ENTITY'],'remove journal drift')


def test_scholarship_dynamic_positions_equip_replace_remove():
    p,s,_=services(crystal=100)
    seed(p,(160400101,1),(160400102,1),(160500601,1))
    # 160400101 is Scholarship row item_pos=0 but inscription_pos says physical slot1.
    first=s.emblem.insert({'partner_id':242001,'item_id':160400101})
    req(first=={'inscript_items':[160400101]},'Scholarship slot1 insert failed')
    second=s.emblem.insert({'partner_id':242001,'item_id':160400102})
    req(second=={'inscript_items':[160400101,160400102]},'Scholarship slot2 insert failed')
    # Another Scholarship slot1 item must collide with the existing concrete position.
    blocked=s.emblem.insert({'partner_id':242001,'item_id':160500601})
    req(blocked=={'error_code':1},'Scholarship position collision was not detected')
    replaced=s.emblem.insert({'partner_id':242001,'item_id':160500601,'replace_item_id':160400101})
    req(replaced=={'inscript_items':[160400102,160500601]},'Scholarship dynamic replacement failed')
    req(p.crystal==80 and s.stack_inventory.quantity(160400101)==1,'Scholarship replacement cost/return drift')
    removed=s.emblem.remove({'partner_id':242001,'item_id':160400102})
    req(removed=={'inscript_items':[160500601]},'Scholarship dynamic remove failed')
    req(p.crystal==60 and s.stack_inventory.quantity(160400102)==1,'Scholarship removal settlement drift')


def test_resolve_catalog_complete_and_representatives():
    source=EmblemSourceCatalog(DATA)
    resource_ids=[]
    for item_id in source.concrete_item_ids():
        item=source.require_concrete_item(item_id)
        row=source.require_inscription(item['inscription_id'])
        rid=int(row['resolve_material']); num=int(row['resolve_num'])
        req(rid in (19,20,21) and num>0,f'Emblem {item_id} has unresolved dissolve row')
        resource_ids.append(rid)
    req(len(resource_ids)==254,'dissolve source census drift')

    # ordinary Excellence, Honor artifact, Scholarship set piece
    fixtures=[(160100101,'degree_cer',90),(160200111,'graduate_cer',90),(160500601,'patent_cer',1420)]
    for idx,(item_id,key,expected) in enumerate(fixtures,1):
        p,s,_=services(); seed(p,(item_id,2)); before=int(getattr(p,key))
        out=s.emblem.resolve({'item_id':item_id,'resolve_num':2})
        req(out=={},f'dissolve fixture {idx} response drift')
        req(s.stack_inventory.quantity(item_id)==0,f'dissolve fixture {idx} did not consume stack')
        req(int(getattr(p,key))==before+expected*2,f'dissolve fixture {idx} resource drift')
        req([r['category'] for r in s.uow.consume_journal()]==['RESOURCE','STACK'],f'dissolve fixture {idx} journal drift')


def test_star_exchange_current_source_mapping_and_noop():
    p,s,c=services(); seed(p,(50001343,2),(50001344,3),(50001345,4))
    out=s.emblem.exchange_materials({}); journal=s.uow.consume_journal()
    req(out=={'currency_change':[{'currency':19,'change':10},{'currency':20,'change':15},{'currency':21,'change':20}]},'MID1407 wire drift')
    req((p.degree_cer,p.graduate_cer,p.patent_cer)==(10,15,20),'MID1407 ledger drift')
    req(all(s.stack_inventory.quantity(i)==0 for i in (50001343,50001344,50001345)),'MID1407 physical Stars not consumed')
    req([r['category'] for r in journal]==['RESOURCE','RESOURCE','RESOURCE','STACK','STACK','STACK'],'MID1407 journal ordering drift')
    req(len(c)==1,'MID1407 did not commit once')
    again=s.emblem.exchange_materials({})
    req(again=={'currency_change':[]} and not s.uow.consume_journal(),'MID1407 empty action not stable no-op')


def test_legacy_direct_call_shims_hit_same_owner():
    p,s,_=services(crystal=100); seed(p,(160300101,1))
    out=s.hero_advanced.inscription_insert({'partner_id':242001,'item_id':160300101})
    req(out=={'inscript_items':[160300101]},'HeroAdvanced compatibility shim insert drift')
    out=s.hero_advanced.inscription_remove({'partner_id':242001,'item_id':160300101})
    req(out=={'inscript_items':[]},'HeroAdvanced compatibility shim remove drift')


def main() -> None:
    tests=[
        test_live_handlers_route_to_single_emblem_owner,
        test_source_position_resolver_matches_stock_fallback,
        test_ordinary_insert_remove_parity_and_atomic_cost,
        test_scholarship_dynamic_positions_equip_replace_remove,
        test_resolve_catalog_complete_and_representatives,
        test_star_exchange_current_source_mapping_and_noop,
        test_legacy_direct_call_shims_hit_same_owner,
    ]
    for test in tests:
        test(); print('PASS',test.__name__)
    print('PASS Pass242 Emblem I1 deterministic reconciliation (%d tests)'%len(tests))

if __name__=='__main__': main()
