#!/usr/bin/env python3
"""Pass227 Blood-only MID867 semantic-empty wire reconciliation."""
from __future__ import annotations
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.unit_of_work import OperationContext
DATA=ROOT/'data'; CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(v,m):
    if not v: raise AssertionError(m)

def services(pid=227001):
    p=PlayerState(player_id=str(pid),account_uid=str(pid),lev=100)
    p.heroes={str(pid):{'partner_id':pid,'table_id':11001001,'star':5,'lev':100,'exp':0,'color':15,'skills':[1]*6,'skill_ids':[0]*6,'equips':[0]*6,'fumos':[0]*6,'fumo_levels':[0]*6,'element_equips':[0]*4,'element_levels':[0]*4,'element_bak_equips':[],'element_bak_levels':[],'inscript_items':[],'twice_awake_stage':2}}
    s=RequestServices(p,DATA,lambda:None,catalog=CATALOG)
    ctx=OperationContext(actor_player_id=str(pid),domain='pass227_test',operation_name='seed',protocol_mid=None)
    with s.uow.transaction(ctx):
        s.awakening_missions._set_active(2,{'mission_id':2001002,'awake_type':2,'hero_partner_id':pid,'hero_table_id':11001001,'stage':2,'generation':227,'complete':False,'count':0,'opened_at':p.now()})
    return p,s

def main():
    p,s=services()
    req(s.awakening_missions.unlimited_start({'twice_awake_mission':2001002,'incubus_id':2001002})=={},'MID866 start failed')
    base={'twice_awake_mission':2001002,'incubus_id':2001002,'num':20}
    for label,value in [('nonempty_array',[1]),('nonempty_object',{'1':1}),('null',None),('scalar',0)]:
        out=s.awakening_missions.unlimited_result({**base,'npc_ids':value})
        req(out.get('msg')=='blood_awake_terminal_npc_mismatch',f'{label} accepted: {out}')
    out=s.awakening_missions.unlimited_result(dict(base))
    req(out.get('msg')=='blood_awake_terminal_npc_mismatch',f'missing npc_ids accepted: {out}')
    # Exact stock-client runtime shape observed in Pass226.
    result=s.awakening_missions.unlimited_result({**base,'npc_ids':{}})
    req(result.get('items')==[],'stock {} wire rejected')
    req((result.get('twice_awake_mission_') or [{}])[0].get('is_complete')==1,'Blood mission not completed')
    # Semantic legacy/test shape remains replay-compatible, but only in Blood branch.
    replay=s.awakening_missions.unlimited_result({**base,'npc_ids':[]})
    req(replay==result,'[] semantic-empty replay drift')
    claim=s.awakening_missions.claim(2001002)
    req(claim=={'twice_awake_stage_':{'table_id':11001001,'stage':3}},f'MID161 terminal claim drift: {claim}')
    req(p.heroes['227001']['twice_awake_stage']==3,'stage 3 not persisted')
    print('PASS227 BLOOD MID867 WIRE: PASS')
    print('stock_wire_npc_ids={} accepted')
    print('semantic_empty_array=[] accepted/replayed')
    print('missing/null/scalar/nonempty rejected')
    print('MID161 stage3 claim PASS')
if __name__=='__main__': main()
