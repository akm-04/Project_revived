#!/usr/bin/env python3
from __future__ import annotations
import copy,sys
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
def make(hero_table:int, skin_ids=None,current=0,illusion=-1,item_id=None,count=0):
    p=apply_established_profile(PlayerState()); p.player_id='15100001'; p.account_uid='15100001'
    p.heroes={'90001':{'partner_id':90001,'table_id':hero_table,'star':10,'lev':100,
        'skin_ids':copy.deepcopy(skin_ids if skin_ids is not None else []),
        'current_skin_id':current,'illusion_skin_id':illusion}}
    p.backpack_items=[]
    if item_id and count: p.backpack_items=[{'table_id':item_id,'item_num':count,'time':0}]
    commits=[]; s=RequestServices(p,DATA,lambda:commits.append('commit'),catalog=CATALOG)
    return p,s,commits

def test_source_contract_still_present():
    hero=(SRC/'app/windows/HeroMainWindow.lua').read_text(encoding='utf-8')
    normal=(SRC/'app/model/NormalHero.lua').read_text(encoding='utf-8')
    req('xyd.mid.USE_ILLUSION_SKIN_ITEM' in hero,'MID2979 source call missing')
    req('arg_170_0.hero.illusionSkinId_ = arg_172_1.illusion_skin_id' in hero,'skin response contract drift')
    req('var_170_5 = var_170_0.cardState == xyd.CardStatus.AWAKE_CARD and 1 or 0' in hero,'normal/awake sentinel contract drift')
    req('arg_3_0.illusionSkinId_ = tonumber(arg_3_1.illusion_skin_id or -1)' in normal,'hero bootstrap illusion field drift')
    req('elseif arg_38_0.illusionSkinId_ == 0 then' in normal and 'elseif arg_38_0.illusionSkinId_ == 1 then' in normal,'model sentinel contract drift')

def test_owned_permanent_skin_sets_visual_without_consumption():
    r=SkinSourceCatalog(DATA).skin(50001541)
    p,s,commits=make(r.skin_partner_id,[r.model_id],777,-1,r.skin_item_id,2)
    before_qty=s.stack_inventory.quantity(r.skin_item_id)
    z=s.skin_ownership.use_illusion_skin_item(90001,r.skin_item_id)
    req(z=={'illusion_skin_id':r.model_id},f'bad response {z}')
    hero=s.heroes.get(90001); req(hero['illusion_skin_id']==r.model_id,'illusion state not persisted in hero')
    req(hero['current_skin_id']==777,'MID2979 changed current/skill skin axis')
    req(s.stack_inventory.quantity(r.skin_item_id)==before_qty,'MID2979 consumed physical item')
    req(len(commits)==1,'MID2979 did not commit exactly once')

def test_normal_and_awake_sentinels():
    p,s,_=make(10001067,[],333,999)
    z=s.skin_ownership.use_illusion_skin_item(90001,0); req(z=={'illusion_skin_id':0},f'normal sentinel {z}')
    req(s.heroes.get(90001)['current_skin_id']==333,'normal sentinel changed current skin')
    z=s.skin_ownership.use_illusion_skin_item(90001,1); req(z=={'illusion_skin_id':1},f'awake sentinel {z}')
    req(s.heroes.get(90001)['current_skin_id']==333,'awake sentinel changed current skin')

def test_unowned_and_wrong_hero_fail_closed():
    r=SkinSourceCatalog(DATA).skin(50001541)
    p,s,commits=make(r.skin_partner_id,[],0,-1,r.skin_item_id,1); s.heroes.normalize(); s.stack_inventory.normalize(); before=copy.deepcopy(vars(p))
    z=s.skin_ownership.use_illusion_skin_item(90001,r.skin_item_id)
    req(z.get('error_code')==1 and z.get('msg')=='skin_not_unlocked',f'unowned accepted {z}')
    req(vars(p)==before,'unowned visual request mutated player'); req(not commits,'unowned request committed')
    p,s,_=make(10001001,[r.model_id],0,-1)
    z=s.skin_ownership.use_illusion_skin_item(90001,r.skin_item_id)
    req(z.get('error_code')==1 and z.get('msg')=='skin_does_not_belong_to_hero',f'wrong hero accepted {z}')

def test_temporary_only_stays_fail_closed():
    r=SkinSourceCatalog(DATA).skin(50001541)
    p,s,commits=make(r.skin_partner_id,{str(r.model_id):9999999999},0,-1)
    z=s.skin_ownership.use_illusion_skin_item(90001,r.skin_item_id)
    req(z.get('error_code')==1 and z.get('msg')=='temporary_skin_illusion_lifecycle_unresolved',f'temporary lane broadened {z}')
    req(not commits,'temporary unresolved request committed')

def test_post_mutation_failure_rolls_back():
    r=SkinSourceCatalog(DATA).skin(50001541)
    p,s,commits=make(r.skin_partner_id,[r.model_id],123,-1); s.heroes.normalize(); before=copy.deepcopy(vars(p)); orig=s.uow.mark_changed
    def boom(slice_id=None): raise RuntimeError('boom-after-illusion-mutation')
    s.uow.mark_changed=boom
    try:
        try:s.skin_ownership.use_illusion_skin_item(90001,r.skin_item_id)
        except RuntimeError:pass
    finally:s.uow.mark_changed=orig
    req(vars(p)==before,'UoW did not roll back MID2979'); req(not commits,'failed MID2979 committed')

def test_route_and_mid_constant():
    text=(ROOT/'gxb_backend/dispatch/engine_dispatcher.py').read_text(encoding='utf-8')
    req(int(MID.USE_ILLUSION_SKIN_ITEM)==2979,'MID2979 drift')
    req('MID.USE_ILLUSION_SKIN_ITEM: self.heroes.use_illusion_skin_item' in text,'MID2979 route missing')

def main():
    tests=[test_source_contract_still_present,test_owned_permanent_skin_sets_visual_without_consumption,test_normal_and_awake_sentinels,test_unowned_and_wrong_hero_fail_closed,test_temporary_only_stays_fail_closed,test_post_mutation_failure_rolls_back,test_route_and_mid_constant]
    for t in tests:t(); print('PASS',t.__name__)
    print(f'PASS Pass151 MID2979 illusion skin reconciliation ({len(tests)}/{len(tests)})')
if __name__=='__main__': main()
