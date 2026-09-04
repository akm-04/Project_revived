#!/usr/bin/env python3
from __future__ import annotations
import copy, json
from pathlib import Path
from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.request_services import RequestServices

ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'data'; CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')
def req(v,m):
    if not v: raise AssertionError(m)
def services(name='c'):
    p=PlayerState(player_id=name,account_uid=name,player_name=name); commits=[]
    s=RequestServices(p,DATA,lambda: commits.append(copy.deepcopy(p.message_pushes)),catalog=CATALOG)
    return p,s,commits

def test_deferred_shapes():
    p,s,commits=services('deferred')
    before=copy.deepcopy(p.practice_info)
    practice=s.deferred_status.response(124)
    req(set(practice)=={'last_time','practice_attr','lock','times','base_crystal','base_mana','bless_value'},'MID124 field set drift')
    req(practice['practice_attr']==[0,0,0] and practice['lock']==[] and practice['times']==0,'MID124 baseline drift')
    req(isinstance(practice['last_time'],int) and practice['last_time']>0,'MID124 last_time not clock-owned')
    req(p.practice_info==before and commits==[],'MID124 persisted fabricated state')
    p.practice_info={'hero':{'practice_attr':[1,2,3],'times':2,'base_mana':9,'last_time':123}}
    overlay=s.deferred_status.response(124)
    req(overlay['practice_attr']==[1,2,3] and overlay['times']==2 and overlay['base_mana']==9 and overlay['last_time']==123,'MID124 canonical overlay wrong')
    req(s.deferred_status.response(530)=={'teams_info':[],'sp_info':{'sp':0,'sp_last_refresh_time':0}},'MID530 shape drift')
    info=s.deferred_status.response(816); req(set(info)=={'normal','is_super_open'} and info['is_super_open']==0,'MID816 top shape drift')
    req(all(isinstance(info['normal'][k],int) for k in ('now_floor','max_floor','begin_sweep_time','is_can_sweep','mission_sweep_times','can_sweep_times','challenge_times')),'MID816 numeric shape drift')
    red=s.deferred_status.response(822); req('normal' not in red and all(isinstance(v,int) for v in red.values()),'MID822 flat shape drift')
    guild=s.deferred_status.response(1152); req(guild=={'is_enroll':0} and 'step_id' not in guild,'MID1152 inactive shape drift')

def test_hydration_exact():
    p,s,_=services('hydration')
    snap=s.hydration_snapshot.stage3_snapshot()
    mids={int(k) for k in snap}
    req(mids==set(s.synchronization_catalogs.stage3_mids()) and len(mids)==22,'Stage3 registry/provider mismatch')
    req(not ({124,530,816,822,1152}&mids),'deferred adapter leaked into Stage3')
    req('2560' in snap and isinstance(snap['2560'],list),'derived redmark bootstrap projection missing')

def test_message_push():
    base=PlayerState(player_id='legacy',account_uid='legacy')
    migrated=JsonPlayerDatabase.deserialize_player({'message_pushes':{'1':1,'2':0,'3':True,'99':1,'oops':1}},base)
    req(migrated.message_pushes==[1,3],'legacy MessagePush dict normalization wrong')
    p,s,commits=services('push')
    req(s.message_push_preferences.enable(3)=={} and p.message_pushes==[3] and len(commits)==1,'MessagePush enable commit wrong')
    req(s.message_push_preferences.enable(3)=={} and len(commits)==1,'MessagePush enable not idempotent')
    req(s.message_push_preferences.enable(99).get('error_code')==1 and len(commits)==1,'invalid MessagePush type mutated')
    req(s.message_push_preferences.disable(3)=={} and p.message_pushes==[] and len(commits)==2,'MessagePush disable commit wrong')
    req(isinstance(p.player_info_payload()['message_pushes'],list),'player_info MessagePush wire is not list')

def test_fences_and_routes():
    reg=json.loads((DATA/'mutation_contract_registry.json').read_text())
    rows={r['mid']:r for r in reg['contracts']}
    for mid in (125,126,127,128,130,131,132,133,817,818,819,821,823,824,825,826,827):
        req(rows[mid]['enforcement'] in {'BLOCK_PHASE1','BLOCK_PHASE2'},f'mutation {mid} not explicitly blocked')
    req(rows[820]['enforcement']=='DEFER_TERMINAL','Pet campaign terminal policy drift')
    req(rows[1025]['backend_capability']=='CANONICAL_DURABLE_PREFERENCE' and rows[1026]['backend_capability']=='CANONICAL_DURABLE_PREFERENCE','MessagePush audit contract missing')
    source=(ROOT/'gxb_backend/dispatch/engine_dispatcher.py').read_text()
    for symbol in ('TREASURE_LOAD_INFO','GUILD_WAR_RED_POINT','MESSAGE_PUSH_ADD','MESSAGE_PUSH_REMOVE'):
        req(symbol in source,f'Wave C route missing {symbol}')

def main():
    test_deferred_shapes(); test_hydration_exact(); test_message_push(); test_fences_and_routes()
    print(json.dumps({'pass':'275.0','status':'PASS','wave':'C_SERVER_HYDRATION_DEFERRED_ADAPTERS_MESSAGE_PUSH','stage3_mids':22,'deferred_mids':[124,530,816,822,1152],'message_push_ids':list(range(1,13)),'message_push_storage':'sorted_unique_list','client_runtime_changed':False},indent=2,sort_keys=True))
if __name__=='__main__': main()
