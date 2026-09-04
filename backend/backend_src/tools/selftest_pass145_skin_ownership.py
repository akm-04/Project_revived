#!/usr/bin/env python3
from __future__ import annotations
import copy,hashlib,json,subprocess,sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
DATA=ROOT/'data'; SRC=ROOT/'source_evidence/src_64'
from gxb_backend.content import GameDataCatalog
from gxb_backend.content.skin_source_catalog import SkinSourceCatalog
from gxb_backend.protocol.mids import MID
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.request_services import RequestServices

CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')
def req(v,m):
    if not v: raise AssertionError(m)
def make(hero_table:int, skin_ids=None,current=0,item_id=None,count=0):
    p=apply_established_profile(PlayerState()); p.player_id='14500001'; p.account_uid='14500001'; p.heroes={'90001':{'partner_id':90001,'table_id':hero_table,'star':10,'lev':100,'skin_ids':copy.deepcopy(skin_ids if skin_ids is not None else []),'current_skin_id':current}}
    p.backpack_items=[]
    if item_id and count: p.backpack_items=[{'table_id':item_id,'item_num':count,'time':0}]
    commits=[]; s=RequestServices(p,DATA,lambda:commits.append('commit'),catalog=CATALOG)
    return p,s,commits

def test_fresh_catalog_rebuild():
    with tempfile.TemporaryDirectory() as td:
        out=Path(td)/'skin.json'
        subprocess.run([sys.executable,str(ROOT/'tools/build_skin_source_catalog.py'),'--src64',str(SRC),'--data-dir',str(DATA),'--out',str(out)],check=True)
        req(out.read_bytes()==(DATA/'skin_source_catalog.json').read_bytes(),'skin catalog stale versus packaged src64')
    c=SkinSourceCatalog(DATA); req(c.summary=={'canonical_permanent_skins':262,'cosmetic_only':37,'girls':212,'skill_bearing':225},f'census drift {c.summary}')
    row=c.skin(50001878); req(row and set(row.accepted_hero_table_ids)=={10001188,11001188},'awaken normalization drift')

def test_new_unlock_preserves_current_and_consumes_one():
    c=SkinSourceCatalog(DATA); r=c.skin(50001433); p,s,commits=make(r.skin_partner_id,[],777,r.skin_item_id,2)
    z=s.skin_ownership.skin_on(90001,r.skin_item_id); req(z.get('error_code',0)==0,str(z)); req(z['current_skin_id']==777,'new unlock auto-equipped unexpectedly'); req(r.model_id in z['skin_ids'],'ownership missing'); req(s.stack_inventory.quantity(r.skin_item_id)==1,'did not consume exactly one'); req(z['remove_item']==1,'remove_item mismatch'); req(len(commits)==1,'commit count')

def test_owned_switch_consumes_zero_even_with_duplicate_item():
    c=SkinSourceCatalog(DATA); r=c.skin(50001433); p,s,_=make(r.skin_partner_id,[r.model_id],0,r.skin_item_id,2)
    z=s.skin_ownership.skin_on(90001,r.skin_item_id); req(z['current_skin_id']==r.model_id,'owned skin not equipped'); req(s.stack_inventory.quantity(r.skin_item_id)==2,'owned switch consumed duplicate'); req(z['remove_item']==0,'owned switch remove_item')

def test_multiple_skin_switch_and_cancel():
    c=SkinSourceCatalog(DATA); groups={}
    for r in c.rows(): groups.setdefault(r.skin_partner_id,[]).append(r)
    rows=next(v for v in groups.values() if len(v)>=2); a,b=rows[:2]
    p,s,_=make(a.skin_partner_id,[a.model_id,b.model_id],a.model_id)
    z=s.skin_ownership.skin_on(90001,b.skin_item_id); req(z['current_skin_id']==b.model_id,'second skin switch failed')
    z=s.skin_ownership.skin_cancel(90001); req(z['current_skin_id']==0,'cancel did not unequip'); req(set(int(x) for x in z['skin_ids'])=={a.model_id,b.model_id},'cancel changed ownership')

def test_awakened_hero_match():
    r=SkinSourceCatalog(DATA).skin(50001878); p,s,_=make(11001188,[],0,r.skin_item_id,1)
    z=s.skin_ownership.skin_on(90001,r.skin_item_id); req(z.get('error_code',0)==0,f'awaken match failed {z}')

def test_map_shape_preserves_timed_skin():
    c=SkinSourceCatalog(DATA); r=c.skin(50001433); timed='49999999'; raw={timed:9999999999}
    p,s,_=make(r.skin_partner_id,raw,0,r.skin_item_id,1); z=s.skin_ownership.skin_on(90001,r.skin_item_id)
    req(z['skin_ids'][timed]==9999999999,'timed ownership lost'); req(z['skin_ids'][str(r.model_id)]==-1,'permanent map ownership missing')

def test_same_model_temporary_conversion_fails_closed():
    r=SkinSourceCatalog(DATA).skin(50001433); p,s,commits=make(r.skin_partner_id,{str(r.model_id):9999999999},0,r.skin_item_id,1); s.heroes.normalize(); before=copy.deepcopy(vars(p))
    z=s.skin_ownership.skin_on(90001,r.skin_item_id); req(z.get('error_code')==1,'temp conversion unexpectedly accepted'); req(vars(p)==before,'temp conversion mutated'); req(not commits,'temp conversion committed')

def test_wrong_hero_missing_item_and_temp_item_fail_closed():
    r=SkinSourceCatalog(DATA).skin(50001433)
    p,s,_=make(10001001,[],0,r.skin_item_id,1); req(s.skin_ownership.skin_on(90001,r.skin_item_id).get('error_code')==1,'wrong hero accepted')
    p,s,_=make(r.skin_partner_id,[],0,None,0); req(s.skin_ownership.skin_on(90001,r.skin_item_id).get('error_code')==1,'missing item accepted')
    p,s,_=make(10001006,[],0,50001807,1); req(s.skin_ownership.skin_on(90001,50001807).get('error_code')==1,'temporary item accepted')

def test_post_debit_failure_rolls_back():
    r=SkinSourceCatalog(DATA).skin(50001433); p,s,commits=make(r.skin_partner_id,[],123,r.skin_item_id,1); s.heroes.normalize(); s.stack_inventory.normalize(); before=copy.deepcopy(vars(p)); orig=s.uow.mark_changed
    def boom(slice_id=None): raise RuntimeError('boom-after-debit')
    s.uow.mark_changed=boom
    try:
        try:s.skin_ownership.skin_on(90001,r.skin_item_id)
        except RuntimeError:pass
    finally:s.uow.mark_changed=orig
    req(vars(p)==before,'UoW did not roll back post-debit failure'); req(not commits,'failed transaction committed')

def test_production_composition_and_mid_constants():
    r=SkinSourceCatalog(DATA).skin(50001433); p,s,_=make(r.skin_partner_id,[],0,r.skin_item_id,1)
    req(s.skin_ownership.heroes is s.heroes,'skin service not sharing HeroRepository'); req(s.skin_ownership.stacks is s.stack_inventory,'skin service not sharing StackInventory'); req(s.skin_ownership.uow is s.uow,'skin service not sharing UoW'); req(int(MID.SKIN_ON)==60 and int(MID.SKIN_CANCEL)==61,'MID drift')

def main():
    tests=[test_fresh_catalog_rebuild,test_new_unlock_preserves_current_and_consumes_one,test_owned_switch_consumes_zero_even_with_duplicate_item,test_multiple_skin_switch_and_cancel,test_awakened_hero_match,test_map_shape_preserves_timed_skin,test_same_model_temporary_conversion_fails_closed,test_wrong_hero_missing_item_and_temp_item_fail_closed,test_post_debit_failure_rolls_back,test_production_composition_and_mid_constants]
    for t in tests:t(); print('PASS',t.__name__)
    print(f'PASS Pass145 Phase A skin ownership ({len(tests)}/{len(tests)})')
if __name__=='__main__': main()
