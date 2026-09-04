#!/usr/bin/env python3
from __future__ import annotations
import io, json, tempfile
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.observability.console_runtime import ConsoleRuntime, next_server_log_path
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'data'
CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def check(cond,msg):
    if not cond: raise AssertionError(msg)
    print('PASS',msg)

def hero(pid,tid):
    return {'partner_id':pid,'table_id':tid,'star':5,'lev':100,'exp':0,'color':15,'skills':[1]*6,
            'equips':[0]*6,'fumos':[0]*6,'fumo_levels':[0]*6,'element_equips':[0]*4,
            'element_levels':[0]*4,'element_bak_equips':[],'element_bak_levels':[],
            'inscript_items':[],'twice_awake_stage':0}

def services(tid=10001144,pid=232001):
    p=PlayerState(player_id=str(pid),account_uid=str(pid),lev=100)
    p.heroes={str(pid):hero(pid,tid)}
    p.collected_heros={str(tid):{'table_id':tid,'star':5,'is_collected':1}}
    p.mana=999999
    commits=[]
    s=RequestServices(p,DATA,lambda:commits.append(1),catalog=CATALOG)
    return p,s,commits

def test_kongming_missing_live_recovery():
    p,s,_=services()
    first=s.awakening_missions.open_task({'mission_id':1144001,'awake_type':1})
    check(first.get('extra_drops_')==[{'table_id':50001397,'item_num':1}], 'KongMing first open grants event intermediate')
    check(s.inventory.get_item_num(50001397)==1, 'KongMing first intermediate durable')
    replay=s.awakening_missions.open_task({'mission_id':1144001,'awake_type':1})
    check(replay==first and s.inventory.get_item_num(50001397)==1, 'same-generation open replay cannot duplicate')

    s.awakening_missions.give_up({'mission_id':1144001,'awake_type':1})
    reopen=s.awakening_missions.open_task({'mission_id':1144001,'awake_type':1})
    check('extra_drops_' not in reopen and s.inventory.get_item_num(50001397)==1, 'reopen with live intermediate does not duplicate')

    s.awakening_missions.give_up({'mission_id':1144001,'awake_type':1})
    check(s.inventory.consume_item(50001397,1)==0, 'simulate external sale/disposal of event intermediate')
    recovered=s.awakening_missions.open_task({'mission_id':1144001,'awake_type':1})
    check(recovered.get('extra_drops_')==[{'table_id':50001397,'item_num':1}], 'missing LIVE entitlement is restored on reopen')
    check(s.inventory.get_item_num(50001397)==1, 'recovery restores exactly one live intermediate')
    ent=s.awakening_missions.state.event_entitlement(1,1144001) or {}
    check(ent.get('status')=='LIVE' and ent.get('restoration_count')==1, 'recovery accounting remains one-live entitlement')
    check(ent.get('last_restore_reason')=='MISSING_LIVE_ENTITLEMENT', 'recovery reason recorded')

    s.awakening_missions.give_up({'mission_id':1144001,'awake_type':1})
    check(s.inventory.consume_item(50001397,1)==0, 'consume recovered intermediate before derived-gear guard')
    s.inventory.add_items([{'item_id':20001278,'item_num':1}])
    guarded=s.awakening_missions.open_task({'mission_id':1144001,'awake_type':1})
    check('extra_drops_' not in guarded and s.inventory.get_item_num(50001397)==0, 'owned exclusive gear suppresses recovery grant')


def test_log_rollover():
    with tempfile.TemporaryDirectory(prefix='pass232_logs_') as td:
        root=Path(td)
        check(next_server_log_path(root).name=='server.txt', 'first console transcript uses server.txt')
        (root/'server.txt').write_text('preserve-me\n',encoding='utf-8')
        check(next_server_log_path(root).name=='server1.txt', 'second console transcript uses server1.txt')
        out=io.StringIO(); err=io.StringIO()
        rt=ConsoleRuntime(verbosity=1,log_path=next_server_log_path(root),stdout=out,stderr=err)
        rt.emit('basic','second-run')
        rt.close()
        check((root/'server.txt').read_text(encoding='utf-8')=='preserve-me\n', 'existing server.txt is never truncated')
        check((root/'server1.txt').read_text(encoding='utf-8')=='second-run\n', 'second run written to server1.txt')
        (root/'server2.txt').write_text('existing-two\n',encoding='utf-8')
        check(next_server_log_path(root).name=='server3.txt', 'rollover chooses next unused numeric suffix')


def main():
    test_kongming_missing_live_recovery()
    test_log_rollover()
    print(json.dumps({'pass':'232.0','status':'PASS','kongming_event_recovery':True,'server_log_rollover':True},indent=2,sort_keys=True))
    return 0

if __name__=='__main__': raise SystemExit(main())
