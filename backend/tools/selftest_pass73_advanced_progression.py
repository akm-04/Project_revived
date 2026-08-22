from __future__ import annotations
import json, tempfile
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.multiuser_database import MultiUserDatabase, SANDBOX_UID
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.handlers.practice import PracticeHandlers
from gxb_backend.handlers.heroes import HeroHandlers

ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'data'; CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(c,m):
    if not c: raise AssertionError(m)

def hero(pid,tid,star=1,color=1):
    return {'partner_id':pid,'table_id':tid,'star':star,'lev':100,'exp':0,'color':color,'skills':[1]*6,'equips':[0]*6,'fumos':[0]*6,'fumo_levels':[0]*6,'element_equips':[0]*4,'element_levels':[0]*4,'element_bak_equips':[],'element_bak_levels':[],'inscript_items':[]}

def services(h,mana=500_000_000,crystal=1_000_000):
    p=PlayerState(player_id='997301',account_uid='997301',player_name='Pass73'); p.lev=100;p.mana=mana;p.crystal=crystal;p.heroes={str(h['partner_id']):h};p.collected_heros={str(h['table_id']):{'table_id':h['table_id'],'star':h['star'],'is_collected':1}}
    commits=[]
    s=RequestServices(p,DATA,lambda: commits.append(int(p.persistence_state.get('state_version',-1))),catalog=CATALOG)
    return p,s,commits

def main():
    meta=json.loads((DATA/'hero_advanced_progression_meta.json').read_text())
    req(len(meta['super_partners'])==14,'super partner count drift'); req(meta['super_stars']['6']['mana_cost']==80_000_000,'star6 Mana drift'); req(meta['super_stars']['7']['stone_cost']==300,'star7 stone drift'); req(meta['element_max_rank']==10,'element max drift'); req(meta['remove_inscription_crystal']==20,'inscription remove cost drift')
    req(len(meta['partner_stones'])==555,'partner stone count drift'); req(len(meta['stone_evolution'])==3,'stone evolution stage count drift'); req(meta['stone_evolution']['1']['limit_num']==20 and meta['stone_evolution']['3']['limit_num']==40,'stone evolution limit drift')

    # SuperHero star5->6 has 80M Mana and zero scrolls.
    spid=73001; stid=11001
    p,s,c=services(hero(spid,stid,star=5),mana=100_000_000)
    r=s.hero_advanced.super_evolve({'partner_id':spid}); j=s.uow.consume_journal()
    req(r=={},'super 5->6 rejected'); req(p.mana==20_000_000,'super 5->6 Mana wrong'); req(s.heroes.get(spid)['star']==6,'super star not persisted'); req([x['category'] for x in j]==['RESOURCE','ENTITY'],'super 5->6 journal drift'); req(len(c)==1,'super evolve commit count')

    # SuperHero star6->7 consumes 300 own scroll + 90M Mana atomically.
    p2,s2,_=services(hero(spid,stid,star=6),mana=100_000_000); stone=meta['super_partners'][str(stid)]['stone_id']; p2.backpack_items=[{'table_id':stone,'item_num':300,'time':0}]
    r=s2.hero_advanced.super_evolve({'partner_id':spid}); j=s2.uow.consume_journal()
    req(r=={} and p2.mana==10_000_000 and s2.stack_inventory.quantity(stone)==0 and s2.heroes.get(spid)['star']==7,'super 6->7 settlement wrong'); req([x['category'] for x in j]==['RESOURCE','STACK','ENTITY'],'super 6->7 journal drift')

    # Fixed SuperHero gear consumes one exact item; MID304 consumes duplicate and increments encoded equip level.
    p3,s3,_=services(hero(spid,stid,star=6)); gear=meta['super_partners'][str(stid)]['equipment'][0]; p3.backpack_items=[{'table_id':gear,'item_num':3,'time':0}]
    req(s3.hero_advanced.super_set_equip(spid,1)=={},'super equip rejected'); s3.uow.consume_journal(); req(s3.stack_inventory.quantity(gear)==2 and s3.heroes.get(spid)['equips'][0]==1,'super equip state wrong')
    req(s3.hero_advanced.super_enhance_equip({'partner_id':spid,'equip_index':1,'enhance_times':1})=={},'super enhance rejected'); j=s3.uow.consume_journal(); req(s3.stack_inventory.quantity(gear)==1 and s3.heroes.get(spid)['equips'][0]==2,'super enhance state wrong'); req([x['category'] for x in j]==['STACK','ENTITY'],'super enhance journal drift')

    # Find a normal source gear item with real Fumo thresholds and a material with moneng.
    eqmeta=json.loads((DATA/'hero_equipment_meta.json').read_text()); advanced=meta['advanced_items']; chosen=None
    for tid,row in eqmeta['partners'].items():
        for color,ids in row['equip_lists'].items():
            for slot,iid in enumerate(ids,1):
                m=advanced.get(str(iid)) or {}
                if m.get('fumo_thresholds') and int(m.get('fumo_mana') or 0)>0:
                    chosen=(int(tid),int(color),slot,int(iid)); break
            if chosen: break
        if chosen: break
    req(chosen is not None,'no Fumo-capable ordinary equipment found'); ntid,ncolor,nslot,target=chosen
    material=next(int(i) for i,r in advanced.items() if int(r.get('moneng') or 0)>0)
    npid=73002; p4,s4,_=services(hero(npid,ntid,star=5,color=ncolor),mana=500_000_000); s4.heroes.get(npid)['equips'][nslot-1]=1; p4.backpack_items=[{'table_id':material,'item_num':2,'time':0}]
    old=p4.mana; rr=s4.hero_advanced.fumo({'partner_id':npid,'equip_index':nslot,'materials':[material]}); j=s4.uow.consume_journal(); gain=int((advanced[str(material)])['moneng']); cap=sum(int(v) for v in advanced[str(target)]['fumo_thresholds']); actual=min(gain,cap); cost=actual*int(advanced[str(target)]['fumo_mana'])
    req(rr.get('fumo')==actual and p4.mana==old-cost and s4.stack_inventory.quantity(material)==1,'Fumo settlement wrong'); req([x['category'] for x in j]==['RESOURCE','STACK','ENTITY'],'Fumo journal drift')

    # Element Equipment: backpack -> equipped, strengthen consumes exact rank/type material, unload -> binding, destroy -> static refund.
    eid=min(int(k) for k in meta['element_equips']); erow=meta['element_equips'][str(eid)]; base=int(erow['item_id']); etype=int(erow['equip_type']); costs=meta['element_strength']['0'][f'strth_mtrs{etype}']; nums=meta['element_strength']['0'][f'strth_nums{etype}']; mat=int(costs[0]); num=int(nums[0])
    p5,s5,_=services(hero(npid,10001001,star=5,color=16)); p5.backpack_items=[{'table_id':base,'item_num':1,'time':0},{'table_id':mat,'item_num':num+50,'time':0}]
    rr=s5.hero_advanced.element_equip({'partner_id':npid,'equip_id':eid,'equip_pos':1}); s5.uow.consume_journal(); req(rr['element_equips'].split('|')[0]==str(eid) and s5.stack_inventory.quantity(base)==0,'element equip wrong')
    rr=s5.hero_advanced.element_strengthen({'partner_id':npid,'equip_id':eid}); j=s5.uow.consume_journal(); req(rr['element_levels'].split('|')[0]=='1' and s5.stack_inventory.quantity(mat)==50,'element strengthen wrong'); req([x['category'] for x in j]==['STACK','ENTITY'],'element strengthen journal drift')
    rr=s5.hero_advanced.element_unload({'partner_id':npid,'equip_pos':1}); s5.uow.consume_journal(); req(rr['element_equips'].split('|')[0]=='0' and eid in s5.heroes.get(npid)['element_bak_equips'],'element unload wrong')
    before_refund=s5.stack_inventory.quantity(mat); rr=s5.hero_advanced.element_destroy_on_hero({'partner_id':npid,'equip_id':eid}); j=s5.uow.consume_journal(); req(eid not in s5.heroes.get(npid)['element_bak_equips'] and s5.stack_inventory.quantity(mat)>before_refund,'element decompose wrong'); req([x['category'] for x in j][-1]=='ENTITY','element decompose entity missing')

    # Deterministic Inscription insert/remove. Source client locally mirrors stack changes; server persists them silently.
    insrow=next(v for v in meta['inscriptions'].values() if v['item_ids']); ins_item=int(insrow['item_ids'][0]); p6,s6,_=services(hero(npid,10001001,star=5,color=16),crystal=100); p6.backpack_items=[{'table_id':ins_item,'item_num':1,'time':0}]
    rr=s6.hero_advanced.inscription_insert({'partner_id':npid,'item_id':ins_item}); s6.uow.consume_journal(); req(ins_item in rr['inscript_items'] and s6.stack_inventory.quantity(ins_item)==0,'inscription insert wrong')
    rr=s6.hero_advanced.inscription_remove({'partner_id':npid,'item_id':ins_item}); j=s6.uow.consume_journal(); req(ins_item not in rr['inscript_items'] and s6.stack_inventory.quantity(ins_item)==1 and p6.crystal==80,'inscription remove wrong'); req([x['category'] for x in j]==['RESOURCE','STACK','ENTITY'],'inscription remove journal drift')

    # Stone Evolution MID2608: exact source-authorized stone debit + Hero ENTITY point update.
    stone_tid=10001001; stone_pid=73003; stone_row=meta['partner_stones'][str(stone_tid)]; own_stone=int(stone_row['stone_id']); attr=int(meta['stone_evolution']['1']['attrs'][0])
    sh=hero(stone_pid,stone_tid,star=3,color=16); sh['lev']=80; sh['evo_stage']=1; sh['evo_attr_points']={}
    p7,s7,_=services(sh); p7.backpack_items=[{'table_id':own_stone,'item_num':2,'time':0}]
    rr=s7.hero_advanced.breach_stone_add({'partner_id':stone_pid,'attr_id':attr,'add_num':1,'cost_item':own_stone}); j=s7.uow.consume_journal()
    req(rr.get('evo_info',{}).get('evo_attr_points',{}).get(str(attr))==1,'stone add response wrong'); req(s7.stack_inventory.quantity(own_stone)==1,'stone add stack debit wrong'); req([x['category'] for x in j]==['STACK','ENTITY'],'stone add journal drift')

    # Source-authorized universal ticket works; unlisted item fails closed without state mutation.
    ticket=int(meta['stone_tickets'][str(stone_row['stone_ticket'])][0]); p7.backpack_items.append({'table_id':ticket,'item_num':2,'time':0})
    rr=s7.hero_advanced.breach_stone_add({'partner_id':stone_pid,'attr_id':attr,'add_num':1,'cost_item':ticket}); s7.uow.consume_journal(); req(rr.get('evo_info',{}).get('evo_attr_points',{}).get(str(attr))==2 and s7.stack_inventory.quantity(ticket)==1,'stone ticket settlement wrong')
    before=dict(s7.heroes.get(stone_pid)['evo_attr_points']); bad=s7.hero_advanced.breach_stone_add({'partner_id':stone_pid,'attr_id':attr,'add_num':1,'cost_item':99999999}); req(bad.get('error_code')==1 and s7.heroes.get(stone_pid)['evo_attr_points']==before and not s7.uow.consume_journal(),'unauthorized stone did not fail closed')

    # MID2609 requires every current-stage attribute full and the next stage's level/star, then resets points.
    stage_attrs=[int(v) for v in meta['stone_evolution']['1']['attrs']]; stage_full={str(v):20 for v in stage_attrs}; eh=hero(73004,stone_tid,star=4,color=16); eh['lev']=90; eh['evo_stage']=1; eh['evo_attr_points']=stage_full
    p8,s8,_=services(eh); rr=s8.hero_advanced.breach_stone_evolve({'partner_id':73004}); j=s8.uow.consume_journal(); req(rr.get('evo_info')=={'evo_attr_points':{},'evo_stage':2},'stone evolve response wrong'); req(s8.heroes.get(73004)['evo_stage']==2 and s8.heroes.get(73004)['evo_attr_points']=={},'stone evolve state wrong'); req([x['category'] for x in j]==['ENTITY'],'stone evolve journal drift')
    eh2=hero(73005,stone_tid,star=3,color=16); eh2['lev']=80; eh2['evo_stage']=1; eh2['evo_attr_points']=stage_full; p9,s9,_=services(eh2); rr=s9.hero_advanced.breach_stone_evolve({'partner_id':73005}); req(rr.get('error_code')==1 and s9.heroes.get(73005)['evo_stage']==1 and not s9.uow.consume_journal(),'next-stage qualification did not fail closed')

    # Hidden server/random Hero progression operations must never report false success.
    req(PracticeHandlers(None).hero_mutation({}).get('error_code')==1,'Hero Practice still false-successes')
    req(HeroHandlers(None).advanced_hidden_fail_closed({}).get('error_code')==1,'advanced hidden boundary not fail-closed')

    # Pass73 advanced test seed stays sandbox-only and one-shot.
    seed=json.loads((DATA/'debug_guest_advanced_inventory_seed.json').read_text()); req(seed['item_count']==1225,'advanced seed count drift')
    with tempfile.TemporaryDirectory() as tmp:
        db=MultiUserDatabase(Path(tmp),DATA); dbg=PlayerState(player_id='13371337',account_uid=SANDBOX_UID,player_name='Debug'); req(db._apply_pass73_debug_advanced_seed(dbg),'advanced seed not applied'); sample=int(seed['item_ids'][0]); row=next(x for x in dbg.backpack_items if int(x['table_id'])==sample); row['item_num']=999; req(not db._apply_pass73_debug_advanced_seed(dbg),'advanced seed reapplied'); req(int(row['item_num'])==999,'advanced seed replenished'); normal=PlayerState(player_id='8',account_uid='8',player_name='N'); req(not db._apply_pass73_debug_advanced_seed(normal),'advanced seed leaked')

    print(json.dumps({'pass':'73.0','status':'PASS','super_post5_evolve':True,'super_equipment_enhancement':True,'fumo_atomic':True,'element_equipment_deterministic_plane':True,'inscription_insert_remove':True,'stone_evolution_mid2608_2609':True,'hidden_random_fail_closed':True,'debug_advanced_seed_items':1225,'deferred_hidden_server_policy':['Practice candidate generation','Inscription make/rebuild candidate generation','Horcrux instance generation','mission-driven Awakening/Blood Awakening deferred; undefined AWAKE_HERO appears legacy/version-drift','Campaign Energy settlement']},indent=2,sort_keys=True))

if __name__=='__main__': main()
