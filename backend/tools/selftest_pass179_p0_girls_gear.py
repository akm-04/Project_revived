#!/usr/bin/env python3
"""Pass179 P0 Girls/Gear implementation self-test."""
from __future__ import annotations
import json
from collections import Counter
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.fumo_restoration_planner import FumoEquippedSlot
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.handlers.heroes import HeroHandlers
from gxb_backend.transport.result import EngineTransportResult

ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'data'; CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def require(cond,msg):
    if not cond: raise AssertionError(msg)

def hero(pid,tid,color):
    return {'partner_id':pid,'table_id':tid,'star':5,'lev':100,'exp':0,'color':color,'skills':[1]*6,'equips':[1]*6,'fumos':[0]*6,'fumo_levels':[0]*6,'element_equips':[0]*4,'element_levels':[0]*4,'element_bak_equips':[],'element_bak_levels':[],'inscript_items':[]}

def services(h=None):
    p=PlayerState(player_id='179001',account_uid='179001',player_name='Pass179'); p.lev=100; p.mana=999_999_999; p.crystal=999_999
    p.heroes={} if h is None else {str(h['partner_id']):h}; p.collected_heros={}
    commits=[]; s=RequestServices(p,DATA,lambda:commits.append(int(p.persistence_state.get('state_version',-1))),catalog=CATALOG)
    return p,s,commits

def test_source_catalogs():
    f=json.loads((DATA/'fumo_restoration_source_catalog.json').read_text())
    require([x['item_id'] for x in f['materials']]==[50001007,50001006,50001003],'Fumo restoration source order drift')
    require([x['enchant_value'] for x in f['materials']]==[200,60,10],'Fumo restoration values drift')
    require(f['quality_restore_fraction']=={'2':[1,1],'3':[3,8],'4':[9,50],'5':[9,100],'6':[9,200]},'Fumo quality coefficient drift')
    a=json.loads((DATA/'hero_advanced_progression_meta.json').read_text())
    require(a['inscription_exchange_materials']==[
        {'currency_id':19,'item_id':50001343,'per_item':5},
        {'currency_id':20,'item_id':50001344,'per_item':5},
        {'currency_id':21,'item_id':50001345,'per_item':5},
    ],'MID1407 source exchange mapping drift')

def test_fumo_policy_and_promotion():
    p,s,c=services()
    plan=s.fumo_restoration.plan([FumoEquippedSlot(20001001,3,160)])
    require(plan.refundable_value==60 and plan.wire_rows()==[{'table_id':50001006,'item_num':1}],'Blue Fumo restore policy drift')
    plan=s.fumo_restoration.plan([FumoEquippedSlot(20001001,4,1120)])
    require(plan.refundable_value==201 and plan.wire_rows()==[{'table_id':50001007,'item_num':1}] and plan.discarded_residual==1,'Purple Fumo floor/decompose drift')

    eq=json.loads((DATA/'hero_equipment_meta.json').read_text()); adv=json.loads((DATA/'hero_advanced_progression_meta.json').read_text())
    chosen=None; special=None
    for tid,row in eq['partners'].items():
        for color_s,ids in row['equip_lists'].items():
            color=int(color_s)
            if color>=16: continue
            metas=[eq['items'].get(str(i),{}) for i in ids if int(i)>0]
            if len(ids)==6 and metas and all(int(m.get('is_awaken_item',0))==0 and int(m.get('is_bloodline_item',0))==0 for m in metas):
                if any(sum(int(v) for v in (adv['advanced_items'].get(str(i),{}).get('fumo_thresholds') or []))>0 for i in ids):
                    chosen=(int(tid),color,ids)
            if any(int(m.get('is_awaken_item',0))>0 or int(m.get('is_bloodline_item',0))>0 for m in metas):
                special=special or (int(tid),color)
            if chosen and special: break
        if chosen and special: break
    require(chosen is not None and special is not None,'ordinary/special promotion fixtures unavailable')
    h=hero(179011,chosen[0],chosen[1]); h['fumos']=[100]*6
    p,s,c=services(h); before={i:s.stack_inventory.quantity(i) for i in [50001007,50001006,50001003]}
    result=s.hero_equipment.powerup_hero(h['partner_id']); journal=s.uow.consume_journal()
    require('error_code' not in result and result.get('restore_items'),'Fumo-bearing ordinary promotion rejected')
    require(s.heroes.get(h['partner_id'])['color']==chosen[1]+1 and s.heroes.get(h['partner_id'])['fumos']==[0]*6,'ordinary promotion state wrong')
    require(any(row['category']=='STACK' and row['action']=='CREDIT' for row in journal) and journal[-1]['category']=='ENTITY','Fumo restore/promotion journal wrong')
    require(any(s.stack_inventory.quantity(i)>before[i] for i in before),'Fumo returned no material')
    require(len(c)==1,'Fumo promotion must commit once')

    # Pass179 removes the old coarse "any Fumo means unsupported" fence for
    # ordinary equip.  Existing Fumo on other/current slots must not block a
    # normal equipment insertion that has no promotion semantics.
    eh=hero(179013,chosen[0],chosen[1]); eh['equips']=[0,1,1,1,1,1]; eh['fumos']=[25]*6
    p3,s3,c3=services(eh); first_item=int(chosen[2][0]); p3.backpack_items=[{'table_id':first_item,'item_num':1,'time':0}]
    equip_out=s3.hero_equipment.set_hero_equip(eh['partner_id'],1); equip_journal=s3.uow.consume_journal()
    require(equip_out=={} and s3.heroes.get(eh['partner_id'])['equips'][0]==1,'ordinary equip remains incorrectly fenced by Fumo')
    require(s3.heroes.get(eh['partner_id'])['fumos']==[25]*6,'ordinary equip unexpectedly mutated Fumo')
    require(len(c3)==1 and [r['category'] for r in equip_journal]==['STACK','ENTITY'],'ordinary equip/Fumo regression journal wrong')

    sh=hero(179012,special[0],special[1]); p2,s2,_=services(sh)
    rejected=s2.hero_equipment.powerup_hero(sh['partner_id'])
    transport=HeroHandlers._promotion_transport(rejected)
    require(isinstance(transport,EngineTransportResult) and transport.status_code==409,'Awakening-stage promotion must transport-block')
    require(s2.heroes.get(sh['partner_id'])['color']==special[1] and not s2.uow.consume_journal(),'special promotion mutated state')

def test_mid1407():
    p,s,c=services(); p.backpack_items=[{'table_id':50001343,'item_num':2,'time':0},{'table_id':50001344,'item_num':3,'time':0},{'table_id':50001345,'item_num':4,'time':0}]
    out=s.hero_advanced.inscription_exchange_materials_all({}); journal=s.uow.consume_journal()
    require(out=={'currency_change':[{'currency':19,'change':10},{'currency':20,'change':15},{'currency':21,'change':20}]},'MID1407 wire response drift')
    require((p.degree_cer,p.graduate_cer,p.patent_cer)==(10,15,20),'MID1407 ledger credit wrong')
    require(all(s.stack_inventory.quantity(i)==0 for i in (50001343,50001344,50001345)),'MID1407 did not consume all materials')
    require([r['category'] for r in journal]==['RESOURCE','RESOURCE','RESOURCE','STACK','STACK','STACK'],'MID1407 journal ordering drift')
    require(len(c)==1,'MID1407 must commit once')
    again=s.hero_advanced.inscription_exchange_materials_all({})
    require(again=={'currency_change':[]} and not s.uow.consume_journal(),'MID1407 empty retry must be successful no-op')

def test_all_gear_packs():
    p,s,_=services(); ops=[o for o in s.gift_opening_source.operations() if o.raw_equip not in {'','0'}]
    require(len(ops)==199,'gift.equip census drift')
    selectors=Counter(int(o.raw_equip.split('|')[1]) for o in ops)
    require(selectors==Counter({16:195,10:3,6:1}),'gift.equip selector distribution drift')
    for op in ops:
        resolved=s.gift_opening_planner.resolve(op.item_id,op.gift_id,1)
        pre=s.gift_opening_planner.preflight_rewards(resolved); s.rewards.validate(pre)
        plan=s.gift_opening_planner.plan_resolved(resolved); s.rewards.validate(plan.rewards)
        require(plan.wire_awards and sum(n for _,n in plan.wire_awards)>0,f'Gear Pack {op.item_id} empty')
    # one real settlement proves source package debit + canonical RewardTransaction stack grants.
    op=ops[0]; p2,s2,c=services(); p2.backpack_items=[{'table_id':op.item_id,'item_num':2,'time':0}]
    expected=s2.gear_pack_materializer.counts(op.raw_equip,copies=2)
    out=s2.gift_opening.open({'item_id':op.item_id,'gift_id':op.gift_id,'num':2}); journal=s2.uow.consume_journal()
    require('error_code' not in out and {r['table_id']:r['item_num'] for r in out['awards']}==dict(sorted(expected.items())),'Gear Pack settlement/wire mismatch')
    require(s2.stack_inventory.quantity(op.item_id)==0,'Gear Pack source stack not consumed')
    require(len(c)==1 and journal and all(r['category']=='STACK' for r in journal),'Gear Pack must settle in one Stack/UoW commit')

def test_existing_gift_lanes_regression():
    # P0 activates only the formerly-deferred gift.equip lane.  A representative
    # pre-existing deterministic and ordinary-random operation must still pass
    # through their original planners/settlement owners unchanged.
    for capability in (
        s_cap := 'ORDINARY_CURRENT_OWNERS',
        r_cap := 'ORDINARY_RANDOM_CURRENT_OWNERS',
    ):
        p,s,c=services()
        op=next((o for o in s.gift_opening_source.operations() if o.capability==capability),None)
        require(op is not None,f'Gift regression fixture missing for {capability}')
        p.backpack_items=[{'table_id':op.item_id,'item_num':1,'time':0}]
        out=s.gift_opening.open({'item_id':op.item_id,'gift_id':op.gift_id,'num':1})
        journal=s.uow.consume_journal()
        require('error_code' not in out,f'Existing Gift lane regressed: {capability}')
        require(isinstance(out.get('awards'),list),f'Existing Gift lane wire shape regressed: {capability}')
        require(s.stack_inventory.quantity(op.item_id)==0,f'Existing Gift source not consumed: {capability}')
        require(len(c)==1 and journal,f'Existing Gift lane did not settle atomically: {capability}')

def main():
    tests=[test_source_catalogs,test_fumo_policy_and_promotion,test_mid1407,test_all_gear_packs,test_existing_gift_lanes_regression]
    for fn in tests: fn(); print('PASS',fn.__name__)
    print(json.dumps({'pass':'179.0','status':'PASS','p0_i1_foundation':True,'p0_i2_fumo_promotion':True,'p0_i3_mid1407':True,'p0_i4_gear_packs':199,'awakening_promotion':'HTTP409_DEFER_P2'},sort_keys=True))
if __name__=='__main__': main()
