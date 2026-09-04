#!/usr/bin/env python3
from __future__ import annotations
import copy, sys, tempfile, types
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
DATA=ROOT/'data'
from gxb_backend.content import GameDataCatalog, HorcruxSourceCatalog
from gxb_backend.protocol.mids import MID
from gxb_backend.state.horcrux_service import HorcruxServiceError
from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.transport.result import EngineTransportResult
GAME=GameDataCatalog.load(DATA/'game_data_catalog.json')
SOURCE=HorcruxSourceCatalog(DATA,game_data=GAME)

def req(v,m):
    if not v: raise AssertionError(m)

def template_map():
    out={}
    for item_id in SOURCE.templates():
        t=SOURCE.template(item_id); model=SOURCE.model(t['model_id']) if t else None
        pos=int(model.get('pos',0)) if model else 0
        out.setdefault(pos,item_id)
    req(set(range(1,7)).issubset(out),'missing positional templates')
    return out
T=template_map()

def player(pid='167001'):
    p=PlayerState(player_id=pid,account_uid=pid,player_name='Pass167-H2')
    p.heroes={
        '10001':{'partner_id':10001,'table_id':10001001,'star':5,'spirit_equip':[0]*6},
        '10002':{'partner_id':10002,'table_id':10001002,'star':5,'spirit_equip':[0]*6},
    }
    p.spirit_list=[{'spirit_id':i,'table_id':T[i],'is_equip':0,'is_lock':0,'collo_count':0} for i in range(1,7)]
    p.spirit_list += [
        {'spirit_id':101,'table_id':T[1],'is_equip':0,'is_lock':0,'collo_count':0},
        {'spirit_id':102,'table_id':T[2],'is_equip':0,'is_lock':0,'collo_count':0},
    ]
    p.horcrux_state={}; p.hunqi_start_info={}
    return p

def services(pid='167001'):
    p=player(pid); commits=[]
    s=RequestServices(p,DATA,lambda:commits.append(1),catalog=GAME)
    s.heroes.normalize(); s.horcrux_repository.normalize()
    return p,s,commits

def rows(p): return {int(x['spirit_id']):x for x in p.spirit_list}

def test_source_limit_and_owner_migration():
    req(SOURCE.program_limit==20,'spirit_program_limit drift')
    p=player('167101'); p.heroes['10001']['spirit_equip']=[1,2,0,0,0,0]
    p.spirit_list[0]['is_equip']=1; p.spirit_list[1]['is_equip']=1
    s=RequestServices(p,DATA,lambda:None,catalog=GAME); s.heroes.normalize(); s.horcrux_repository.normalize()
    r=rows(p); req(r[1]['is_equip']==10001 and r[2]['is_equip']==10001,'owner mirror migration drift')

def test_lock_and_direct_equip():
    p,s,c=services('167102')
    req(s.horcrux.lock(1,locked=True)=={} and rows(p)[1]['is_lock']==1 and len(c)==1,'lock failed')
    s.horcrux.lock(1,locked=True); req(len(c)==1,'lock retry committed')
    s.horcrux.lock(1,locked=False); req(rows(p)[1]['is_lock']==0 and len(c)==2,'unlock failed')
    out=s.horcrux.equip(10001,1,1); req(out['spirit_equip']==[1,0,0,0,0,0],'equip wire drift')
    req(rows(p)[1]['is_equip']==10001,'equip mirror is not partner_id')
    s.horcrux.equip(10001,101,1); r=rows(p)
    req(r[1]['is_equip']==0 and r[101]['is_equip']==10001,'replacement mirrors drift')
    before=copy.deepcopy(vars(p)); n=len(c)
    for args in [(10002,101,1),(10001,2,1)]:
        try: s.horcrux.equip(*args); raise AssertionError('invalid equip succeeded')
        except HorcruxServiceError: pass
    req(vars(p)==before and len(c)==n,'rejected equip mutated')
    req(s.horcrux.equip(10001,0,1)['spirit_equip']==[0]*6,'unequip failed')

def test_one_key_unequip():
    p,s,c=services('167103'); s.horcrux.equip(10001,1,1); s.horcrux.equip(10001,2,2)
    req(s.horcrux.one_key_unequip(10001)=={'spirit_equip':[0]*6},'one-key wire drift')
    req(rows(p)[1]['is_equip']==0 and rows(p)[2]['is_equip']==0,'one-key mirror drift')
    n=len(c); s.horcrux.one_key_unequip(10001); req(len(c)==n,'one-key retry committed')

def test_collocation_crud_counts_and_limit():
    p,s,c=services('167104')
    cid=s.horcrux.save_collocation(name='Alpha',collocation='1|2|3|0|0|0')['id']
    req(s.horcrux.collocation_infos()==[{'id':cid,'name':'Alpha','collocation':[1,2,3,0,0,0]}],'GET collocation wire drift')
    r=rows(p); req([r[i]['collo_count'] for i in (1,2,3,101,102)]==[1,1,1,0,0],'create count drift')
    n=len(c); req(s.horcrux.save_collocation(name='Alpha',collocation='1|2|3|0|0|0')['id']==cid and len(c)==n,'create replay drift')
    s.horcrux.save_collocation(name='Alpha2',collocation='101|102|3|0|0|0',collocation_id=cid)
    r=rows(p); req([r[i]['collo_count'] for i in (1,2,3,101,102)]==[0,0,1,1,1],'edit count drift')
    s.horcrux.delete_collocation(cid); req(s.horcrux.collocation_infos()==[],'delete failed')
    req(all(rows(p)[i]['collo_count']==0 for i in (1,2,3,101,102)),'delete count drift')
    # 20 source-valid programs; alternating refs avoid needing generated instances.
    for i in range(20): s.horcrux.save_collocation(name=f'C{i}',collocation=f'{1 if i%2==0 else 101}|0|0|0|0|0')
    req(len(s.horcrux.collocation_infos())==20,'source program limit setup drift')
    try: s.horcrux.save_collocation(name='Overflow',collocation='1|0|0|0|0|0'); raise AssertionError('21st program succeeded')
    except HorcruxServiceError: pass
    req(len(s.horcrux.collocation_infos())==20,'limit rejection mutated')

def test_collocation_validation_and_apply_moves():
    p,s,c=services('167105'); before=copy.deepcopy(vars(p))
    for name,refs in [('', '1|0|0|0|0|0'),('TooLongName','1|0|0|0|0|0'),('Dup','1|1|0|0|0|0'),('Pos','2|0|0|0|0|0'),('Unknown','999|0|0|0|0|0'),('Empty','0|0|0|0|0|0')]:
        try: s.horcrux.save_collocation(name=name,collocation=refs); raise AssertionError('bad collocation succeeded')
        except HorcruxServiceError: pass
    req(vars(p)==before and c==[],'bad collocation mutated')
    s.horcrux.equip(10001,1,1); s.horcrux.equip(10002,2,2)
    cid=s.horcrux.save_collocation(name='Move',collocation='1|2|3|0|0|0')['id']
    req(s.horcrux.apply_collocation(cid,10002)=={},'apply wire drift')
    req(p.heroes['10001']['spirit_equip']==[0]*6,'source hero not cleared')
    req(p.heroes['10002']['spirit_equip']==[1,2,3,0,0,0],'target program not applied')
    r=rows(p); req(all(r[i]['is_equip']==10002 for i in (1,2,3)),'apply owner mirrors drift')
    n=len(c); s.horcrux.apply_collocation(cid,10002); req(len(c)==n,'apply retry committed')

def test_durable_roundtrip():
    with tempfile.TemporaryDirectory() as td:
        db=MultiUserDatabase(Path(td)/'server_state',DATA); p,s,_=services('167106')
        s.horcrux.equip(10001,1,1); cid=s.horcrux.save_collocation(name='Persist',collocation='1|2|0|0|0|0')['id']
        db.save_player(p); loaded=db.load_player(p.player_id); req(loaded is not None,'reload failed')
        req(loaded.heroes['10001']['spirit_equip']==[1,0,0,0,0,0],'slots changed on reload')
        req(rows(loaded)[1]['is_equip']==10001,'owner mirror changed on reload')
        req(loaded.horcrux_state['collocations'][str(cid)]['spirit_ids']==[1,2,0,0,0,0],'collocation changed on reload')

def test_dispatcher_bindings_and_transport_failure():
    fake=types.ModuleType('flask'); fake.Request=object; fake.jsonify=lambda data=None,**k:data; fake.make_response=lambda data=None,status=200,**k:data; fake.send_file=lambda *a,**k:None
    sys.modules.setdefault('flask',fake)
    from gxb_backend.config import Settings
    from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
    from gxb_backend.state.repository import StateRepository
    with tempfile.TemporaryDirectory(prefix='pass167_dispatch_') as td:
        root=Path(td); state=StateRepository(DATA/'player_db.json',profile='established',legacy_path=ROOT/'state/gxb_state.json',multiuser_root=root/'server_state')
        d=EngineDispatcher(state,Settings(multiuser_root=root/'server_state',runtime_log_dir=root/'logs'))
        expected={MID.HUNQI_LOCK:'lock',MID.HUNQI_UNLOCK:'unlock',MID.HUNQI_EQUIP:'equip',MID.HUNQI_ONE_KEY_UNEQUIP:'one_key_unequip',MID.HUNQI_GET_COLLOCATION_INFOS:'get_collocation_infos',MID.HUNQI_SAVE_COLLOCATION:'save_collocation',MID.DEL_COLLOCATION:'delete_collocation',MID.APPLY_COLLOCATION:'apply_collocation'}
        for mid,name in expected.items():
            h=d.handlers.get(mid); req(h is not None and getattr(h,'__self__',None) is d.horcrux and getattr(h,'__name__','')==name,f'MID {mid} route drift')
        req(MID.HUNQI_GET_COLLOCATION_INFOS in d.scalar_handlers,'MID3112 not raw-list projected')
    p,s,_=services('167107')
    from gxb_backend.handlers.context import HandlerContext
    from gxb_backend.handlers.horcrux import HorcruxHandlers
    class St: 
        def get_services(self): return s
    class Set: pass
    h=HorcruxHandlers(HandlerContext(state=St(),settings=Set(),resource_gateway=None))
    result=h.equip({'partner_id':10001,'spirit_id':2,'pos':1})
    req(isinstance(result,EngineTransportResult) and result.status_code==409 and result.body.get('error_code')==1,'logical failure not HTTP409')


def test_source_wire_and_hota_contract():
    src=ROOT/'source_evidence/src_64'
    detail=(src/'app/model/Backpack.lua').read_text(encoding='utf-8-sig')
    req('spiritList_' in detail,'source Backpack Spirit inventory contract missing')
    # HOTA-002 must remain the only Horcrux collocation client delta in both architecture trees.
    p32=(ROOT/'local_assets/src_32/app/windows/HunqiCombEditorWindow.lua').read_text(encoding='utf-8-sig')
    p64=(ROOT/'local_assets/src_64/app/windows/HunqiCombEditorWindow.lua').read_text(encoding='utf-8-sig')
    req(p32==p64,'HOTA-002 architecture copies diverged')
    req('addSpiritColloCount(iter_18_old_1, -1)' in p64,'HOTA-002 old collocation decrement missing')
    evidence=[x for x in (ROOT/'source_evidence/src_64').rglob('*') if x.is_file()]
    req(len(evidence)>=18,f'source-evidence corpus unexpectedly shrank {len(evidence)}')
    override_files=[x for tree in ('src_32','src_64') for x in (ROOT/'local_assets'/tree).rglob('*') if x.is_file()]
    req(len(override_files)>=140,f'OTA override corpus unexpectedly shrank {len(override_files)}')

def main():
    tests=[test_source_wire_and_hota_contract,test_source_limit_and_owner_migration,test_lock_and_direct_equip,test_one_key_unequip,test_collocation_crud_counts_and_limit,test_collocation_validation_and_apply_moves,test_durable_roundtrip,test_dispatcher_bindings_and_transport_failure]
    for t in tests: t(); print('PASS',t.__name__,flush=True)
    print(f'PASS Pass167 H2 Horcrux deterministic lifecycle ({len(tests)}/{len(tests)})',flush=True)
if __name__=='__main__': main()
