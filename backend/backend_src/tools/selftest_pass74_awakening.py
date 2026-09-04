from __future__ import annotations
import json
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.unit_of_work import OperationContext

ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'data'; CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(c,m):
    if not c: raise AssertionError(m)

def hero(pid,tid,star=5,color=15,lev=100):
    return {'partner_id':pid,'table_id':tid,'star':star,'lev':lev,'exp':0,'color':color,'skills':[1]*6,'equips':[1]*6,'fumos':[0]*6,'fumo_levels':[0]*6,'element_equips':[0]*4,'element_levels':[0]*4,'element_bak_equips':[],'element_bak_levels':[],'inscript_items':[],'twice_awake_stage':0}

def services(h=None,crystal=1000,items=None):
    p=PlayerState(player_id='997401',account_uid='997401',player_name='Pass74'); p.lev=100;p.crystal=crystal
    if items:
        p.backpack_items=[{'table_id':int(k),'item_num':int(v),'time':0} for k,v in items.items()]
    if h:
        p.heroes={str(h['partner_id']):h}; p.collected_heros={str(h['table_id']):{'table_id':h['table_id'],'star':h['star'],'is_collected':1}}
    commits=[]; s=RequestServices(p,DATA,lambda: commits.append(1),catalog=CATALOG); return p,s,commits

def main():
    am=json.loads((DATA/'awakening_mission_meta.json').read_text())
    req(am['_counts']=={'ordinary_rows':465,'blood_rows':162,'ordinary_heroes':164,'blood_heroes':81},'awakening source counts drift')

    # Ordinary 2-stage awakening: open gear task -> claim -> bounded Campaign proof -> final claim/entity transition.
    pid=74001; p,s,c=services(hero(pid,10001001))
    r=s.awakening_missions.open_task({'mission_id':1001001,'awake_type':1}); req(r.get('awake_mission_',[{}])[0].get('table_id')==1001001,'ordinary open delta missing')
    ml=s.awakening_missions.mission_list()['mission_list']; req(len(ml)==1 and ml[0]['table_id']==1001001 and ml[0]['is_complete']==1,'stage1 task shape wrong')
    r=s.awakening_missions.claim(1001001); req(r.get('awake_mission_',[{}])[0].get('table_id')==1001003,'stage1 claim did not expose stage2')
    with s.uow.transaction(OperationContext(actor_player_id=p.player_id,domain='test',operation_name='awake_campaign',protocol_mid=114)):
        delta=s.awakening_missions.record_campaign_result({'campaign_id':1100006,'star':3,'awake_mission':1001003})
    req(delta.get('awake_mission_',[{}])[0].get('is_complete')==1,'Campaign proof did not complete active stage2')
    r=s.awakening_missions.claim(1001003); req(r=={},'final ordinary claim rejected'); req(s.heroes.get(pid)['table_id']==11001001,'ordinary awakening table transition missing'); req(s.awakening_missions.mission_list()['mission_list']==[],'ordinary mission not cleared')
    j=s.uow.consume_journal(); req(any(x.get('category')=='ENTITY' and x.get('action')=='AWAKEN_TABLE_ID' for x in j),'ordinary awakening ENTITY journal missing')

    # Arbitrary Campaign proof cannot complete the active mission.
    p2,s2,_=services(hero(74002,10001001)); s2.awakening_missions.open_task({'mission_id':1001001,'awake_type':1}); s2.awakening_missions.claim(1001001)
    with s2.uow.transaction(OperationContext(actor_player_id=p2.player_id,domain='test',operation_name='bad_awake_campaign',protocol_mid=114)):
        bad=s2.awakening_missions.record_campaign_result({'campaign_id':100001,'star':3,'awake_mission':1001003})
    req(bad=={} and s2.awakening_missions.mission_list()['mission_list'][0]['is_complete']==0,'wrong Campaign completed awakening')

    # Blood Awakening: open/claim stage1, dedicated unlimited fight proof, final stage=3.
    bpid=74003; p3,s3,_=services(hero(bpid,11001001,color=15,lev=100))
    req(s3.awakening_missions.open_task({'mission_id':2001001,'awake_type':2}).get('twice_awake_mission_',[{}])[0].get('table_id')==2001001,'blood open delta missing'); req(s3.heroes.get(bpid)['twice_awake_stage']==1,'blood stage1 Hero state missing')
    r=s3.awakening_missions.claim(2001001); req(r.get('twice_awake_mission_',[{}])[0].get('table_id')==2001002 and s3.heroes.get(bpid)['twice_awake_stage']==2,'blood stage2 transition wrong')
    req(s3.awakening_missions.unlimited_start({'twice_awake_mission':2001002,'incubus_id':2001002})=={},'blood start rejected')
    r=s3.awakening_missions.unlimited_result({'twice_awake_mission':2001002,'incubus_id':2001002,'npc_ids':[],'num':1}); req(r.get('twice_awake_mission_',[{}])[0].get('is_complete')==1,'blood result did not complete')
    req(s3.awakening_missions.claim(2001002)=={} and s3.heroes.get(bpid)['twice_awake_stage']==3,'blood final claim wrong')

    # Give-up is canonical and resets Blood stage. Use a fresh stage1 before claim.
    p4,s4,_=services(hero(74004,11001001,color=15,lev=100)); req(s4.awakening_missions.open_task({'mission_id':2001001,'awake_type':2}).get('twice_awake_mission_',[{}])[0].get('table_id')==2001001,'giveup setup failed'); gr=s4.awakening_missions.give_up({'mission_id':2001001,'awake_type':2}); req(gr.get('twice_awake_mission_',[{}])[0].get('is_going')==0,'giveup inactive delta missing'); req(s4.heroes.get(74004)['twice_awake_stage']==0 and not s4.awakening_missions.mission_list()['mission_list'],'giveup state wrong')

    # Pass73 runtime exposed Backend.lua HTTP-200/application-error mismatch:
    # rejected Stone Evolution must still carry authoritative evo_info so the
    # SelfPlayer callback cannot nil-dereference. No mutation/journal is allowed.
    sh=hero(74006,10001001,star=3,color=1,lev=80); pstone,sstone,_=services(sh,items={40001001:5})
    before=sstone.stack_inventory.quantity(40001001); sr=sstone.hero_advanced.breach_stone_add({'partner_id':74006,'attr_id':4,'add_num':21,'cost_item':40001001}); sj=sstone.uow.consume_journal()
    req(sr.get('error_code')==1 and isinstance(sr.get('evo_info'),dict),'stone reject shape unsafe'); req(sstone.stack_inventory.quantity(40001001)==before and sj==[],'stone reject mutated canonical state')

    # Emblem dissolve exact source contract observed in debug: 160500603 -> material 21 x1420.
    p5,s5,_=services(items={160500603:2})
    r=s5.hero_advanced.inscription_resolve({'item_id':160500603,'resolve_num':1}); req(r=={},'resolve response wrong'); req(s5.stack_inventory.quantity(160500603)==1 and s5.economy_ledger.balance('patent_cer')==1420,'resolve settlement wrong')

    # Quick Fumo response shape and daily count. Find a source Fumo-capable normal gear.
    meta=json.loads((DATA/'hero_advanced_progression_meta.json').read_text()); eq=json.loads((DATA/'hero_equipment_meta.json').read_text()); chosen=None
    for tid,row in eq['partners'].items():
        for color,ids in row['equip_lists'].items():
            for slot,iid in enumerate(ids,1):
                m=meta['advanced_items'].get(str(iid)) or {}
                if any(int(v or 0)>0 for v in (m.get('fumo_thresholds') or [])) and int(m.get('fumo_mana') or 0)>0:
                    chosen=(int(tid),int(color),slot); break
            if chosen: break
        if chosen: break
    req(chosen is not None,'no quick-Fumo target'); tid,color,slot=chosen; qpid=74005; qh=hero(qpid,tid,color=color); qh['equips']=[0]*6; qh['equips'][slot-1]=1
    p6,s6,_=services(qh,crystal=100); load=s6.hero_advanced.daily_consume_load(); req(isinstance(load.get('buy_times'),str) and len(load['buy_times'].split('|'))==10,'buy_times shape wrong')
    r=s6.hero_advanced.quick_fumo({'partner_id':qpid,'equip_index':slot,'consume_id':2}); req(r.get('fumo',0)>0 and p6.crystal==80,'quick Fumo settlement/response wrong'); req(s6.hero_advanced.daily_consume_load()['buy_times'].split('|')[1]=='1','quick Fumo count missing'); req(s6.hero_advanced.quick_fumo({'partner_id':qpid,'equip_index':slot,'consume_id':2}).get('error_code')==1,'quick Fumo daily limit missing')

    print(json.dumps({'pass':'74.0','status':'PASS','ordinary_awakening_mission_owner':True,'blood_awakening_mission_owner':True,'campaign_awake_proof_validation':True,'unlimit_awake_proof_validation':True,'emblem_resolve':True,'quick_fumo_contract':True,'stone_reject_shape_safe':True,'giveup_inactive_delta':True},indent=2,sort_keys=True))

if __name__=='__main__': main()
