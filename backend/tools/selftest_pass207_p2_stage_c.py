#!/usr/bin/env python3
"""Pass207 P2 Stage C equipment/stage-one/promotion characterization."""
from __future__ import annotations
import json
from pathlib import Path
from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices

ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'data'; CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(c,m):
    if not c: raise AssertionError(m)

def hero(pid,tid,color=15,stage=0,equips=None,fumos=None,fumo_levels=None):
    return {
        'partner_id':pid,'table_id':tid,'star':5,'lev':100,'exp':0,'color':color,
        'skills':[1]*6,'equips':list(equips or [0]*6),'fumos':list(fumos or [0]*6),
        'fumo_levels':list(fumo_levels or [0]*6),'element_equips':[0]*4,'element_levels':[0]*4,
        'element_bak_equips':[],'element_bak_levels':[],'inscript_items':[],'twice_awake_stage':stage,
    }

def services(tid,items=None,pid=207001,color=15,stage=0,equips=None,fumos=None,fumo_levels=None):
    p=PlayerState(player_id=str(pid),account_uid=str(pid),lev=100)
    p.heroes={str(pid):hero(pid,tid,color=color,stage=stage,equips=equips,fumos=fumos,fumo_levels=fumo_levels)}
    p.collected_heros={str(tid):{'table_id':tid,'star':5,'is_collected':1}}
    p.mana=999999999
    p.backpack_items=[{'table_id':int(i),'item_num':int(n),'time':0} for i,n in (items or {}).items()]
    commits=[]; s=RequestServices(p,DATA,lambda:commits.append(1),catalog=CATALOG)
    return p,s,commits

def test_ordinary_stage1_equip_claim_replay():
    pid=207011; p,s,_=services(10001001,{20001185:1},pid=pid)
    opened=s.awakening_missions.open_task({'mission_id':1001001,'awake_type':1})
    req(opened['awake_mission_'][0]['is_complete']==0,'ordinary stage1 did not open incomplete')
    out=s.awakening_equipment.set_hero_equip(pid,1)
    req(out is not None and out['awake_mission_'][0]['is_complete']==1,'ordinary MID54 did not complete stage1')
    req(s.inventory.get_item_num(20001185)==0,'ordinary exclusive gear not debited')
    req(p.heroes[str(pid)]['equips'][0]==1,'ordinary exclusive slot not collected')
    rec=s.awakening_missions.state.active(1); req(rec and rec['mission_id']==1001001 and rec['complete'],'ordinary state not complete')
    replay=s.awakening_equipment.set_hero_equip(pid,1)
    req(replay==out and s.inventory.get_item_num(20001185)==0,'ordinary MID54 replay was not debit-safe')
    claimed=s.awakening_missions.claim(1001001)
    req(claimed['awake_mission_'][0]['table_id']==1001003,'ordinary stage1 claim missing successor')
    rec=s.awakening_missions.state.active(1); req(rec and rec['mission_id']==1001003 and rec['stage']==2 and not rec['complete'],'ordinary stage2 state')
    req(s.awakening_missions.claim(1001001)==claimed,'ordinary MID161 stage1 replay mismatch')


def test_blood_stage1_equip_claim_replay():
    pid=207021
    # Blood stage1 sits on an already-collected ordinary Awakening slot.
    p,s,_=services(11001122,{21001031:1},pid=pid,stage=0,equips=[1,0,0,0,0,0])
    opened=s.awakening_missions.open_task({'mission_id':2122001,'awake_type':2})
    req(p.heroes[str(pid)]['twice_awake_stage']==1,'Blood open did not persist stage1')
    out=s.awakening_equipment.set_hero_equip(pid,1)
    req(out is not None and out['twice_awake_mission_'][0]['is_complete']==1,'Blood MID54 did not complete stage1')
    req(s.inventory.get_item_num(21001031)==0,'Blood exclusive gear not debited')
    req(p.heroes[str(pid)]['equips'][0]==1,'Blood lineage slot changed')
    req(p.heroes[str(pid)]['twice_awake_stage']==1,'Blood MID54 advanced durable stage too early')
    req(s.awakening_equipment.set_hero_equip(pid,1)==out,'Blood MID54 replay mismatch')
    claimed=s.awakening_missions.claim(2122001)
    req(claimed['twice_awake_mission_'][0]['table_id']==2122002,'Blood stage1 claim missing successor')
    req(claimed['twice_awake_stage_']=={'table_id':11001122,'stage':2},'Blood stage2 projection shape')
    req(p.heroes[str(pid)]['twice_awake_stage']==2,'Blood durable stage2 missing')
    rec=s.awakening_missions.state.active(2); req(rec and rec['mission_id']==2122002 and rec['stage']==2 and not rec['complete'],'Blood stage2 state')
    req(s.awakening_missions.claim(2122001)==claimed,'Blood MID161 stage1 replay mismatch')


def test_selective_promotion_preserves_special_slot_and_fumo():
    pid=207031
    p,s,_=services(10001001,{},pid=pid,color=15,equips=[1]*6,fumos=[77,0,0,0,0,0],fumo_levels=[3,0,0,0,0,0])
    before=s.hero_equipment.special_equipment_slots(p.heroes[str(pid)])
    req(before==(1,),f'expected special slot1, got {before}')
    out=s.hero_equipment.powerup_hero(pid)
    req(out.get('error_code') is None,'MID51 special promotion still blocked')
    h=p.heroes[str(pid)]
    req(h['color']==16,'MID51 color not promoted')
    req(h['equips'][0]==1 and h['fumos'][0]==77 and h['fumo_levels'][0]==3,'special slot/Fumo not preserved')
    req(h['equips'][1:]==[0,0,0,0,0],'ordinary slots not reset')
    req(h['fumos'][1:]==[0,0,0,0,0] and h['fumo_levels'][1:]==[0,0,0,0,0],'ordinary Fumo not reset')


def test_normal_mid54_still_normal():
    pid=207041; p,s,_=services(10001001,{},pid=pid,color=14)
    h=p.heroes[str(pid)]; equip_ids=s.hero_equipment._equip_ids(h)
    normal_slot=next((i for i,item in enumerate(equip_ids,1) if item>0 and s.hero_equipment._is_normal_equipment(item)),None)
    req(normal_slot is not None,'no ordinary slot at color14')
    item=equip_ids[normal_slot-1]; s.inventory.add_items([{'item_id':item,'item_num':1}])
    req(s.awakening_equipment.set_hero_equip(pid,normal_slot) is None,'coordinator intercepted normal MID54')
    out=s.hero_equipment.set_hero_equip(pid,normal_slot)
    req(out.get('error_code') is None and p.heroes[str(pid)]['equips'][normal_slot-1]==1,'normal MID54 regression')
    req(s.inventory.get_item_num(item)==0,'normal MID54 item not consumed')



def test_reo_unflagged_blood_gear_source_anomaly():
    pid=207051
    # Reo's recovered Blood gear 21001080 is mission-authoritative but lacks
    # the generic is_bloodline_item flag. The active Blood route must still work.
    p,s,_=services(11001166,{21001080:1},pid=pid,stage=0,equips=[1,0,0,0,0,0])
    opened=s.awakening_missions.open_task({'mission_id':2166001,'awake_type':2})
    req(opened['twice_awake_mission_'][0]['is_complete']==0,'Reo Blood stage1 open')
    out=s.awakening_equipment.set_hero_equip(pid,1)
    req(out is not None and out['twice_awake_mission_'][0]['is_complete']==1,'Reo unflagged Blood gear rejected')
    req(s.inventory.get_item_num(21001080)==0,'Reo Blood gear not debited')

def main():
    for fn in [test_ordinary_stage1_equip_claim_replay,test_blood_stage1_equip_claim_replay,test_selective_promotion_preserves_special_slot_and_fumo,test_normal_mid54_still_normal,test_reo_unflagged_blood_gear_source_anomaly]:
        fn()
    print(json.dumps({'pass':'207.0','stage':'P2-C','status':'PASS','ordinary_mid54_stage1_complete':True,'ordinary_mid161_successor_replay':True,'blood_mid54_stage1_complete_no_stage2':True,'blood_mid161_stage2_projection_replay':True,'promotion_preserves_special_slot_fumo':True,'normal_mid54_regression':True,'reo_unflagged_blood_gear_supported':True},indent=2,sort_keys=True))
    return 0
if __name__=='__main__': raise SystemExit(main())
