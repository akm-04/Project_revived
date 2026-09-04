#!/usr/bin/env python3
from __future__ import annotations
import copy, json, sys, tempfile, types
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
DATA=ROOT/'data'; SRC=ROOT/'source_evidence'/'src_64'
from gxb_backend.content import GameDataCatalog
from gxb_backend.content.vow_source_catalog import VowSourceCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.vow_service import VowServiceError
from gxb_backend.transport.result import EngineTransportResult
from gxb_backend.protocol.mids import MID
from gxb_backend.state.multiuser_database import MultiUserDatabase
GAME=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(v,m):
    if not v: raise AssertionError(m)

def make_services(pid='172001', *, balder_stars=(5,4,4,4,4), awaken_first=False, essence=0):
    p=PlayerState(player_id=pid,account_uid='172',player_name='VowTest')
    row=VowSourceCatalog(DATA).require(11002)
    heroes={}; nxt=10001
    for i,(tid,star) in enumerate(zip(row.material_hero,balder_stars)):
        actual=tid
        if i==0 and awaken_first:
            actual=int(GAME.row('partner',tid).get('awaken_table_id',0))
        heroes[str(nxt)]={'partner_id':nxt,'table_id':actual,'star':star,'lev':100}
        nxt+=1
    p.heroes=heroes; p.hero_next_partner_id=nxt
    if essence: p.backpack_items=[{'table_id':50001666,'item_num':essence,'time':0}]
    commits=[]
    s=RequestServices(p,DATA,lambda:commits.append(1),catalog=GAME)
    return p,s,commits

def test_source_catalog_and_client_contract():
    c=VowSourceCatalog(DATA); req(len(c.rows())==14,'Vow count drift'); b=c.require(11002)
    req(b.name=='Balder' and b.material_hero==(10001015,10001030,10001017,10001029,10001040),'Balder material drift')
    req(b.scroll_id==41002 and c.essence_item_id==50001666 and c.exchange_cost==100,'Vow exchange source facts drift')
    w=(SRC/'app/windows/SuperPartnerWindow.lua').read_text(encoding='utf-8-sig')
    sp=(SRC/'app/model/SelfPlayer.lua').read_text(encoding='utf-8-sig')
    ex=(SRC/'app/windows/SuperPartnerExchangeWindow.lua').read_text(encoding='utf-8-sig')
    req('var_0_4:materialHero(var_19_0)' in w and 'getStar() == xyd.MAX_STAR_LEVEL' in w,'Vow prerequisite UI contract drift')
    req('xyd.mid.SUMMON_SUPER_HERO' in sp and 'arg_144_1.partner_info' in sp,'MID305 response contract drift')
    req('xyd.mid.SUPER_HERO_STONE_EXCHANGE' in ex and 'arg_9_1.awards' in ex,'MID306 response contract drift')

def test_balder_dynamic_star_and_no_sacrifice():
    p,s,c=make_services(balder_stars=(5,5,5,4,4)); before=copy.deepcopy(p.heroes)
    out=s.vows.summon_super_hero(11002); hero=out['partner_info']
    req(hero['table_id']==11002 and hero['star']==3 and hero.get('partner_type')==2,'dynamic initial Vow star/type drift')
    req(all(str(k) in p.heroes and p.heroes[str(k)]['table_id']==v['table_id'] for k,v in before.items()),'prerequisite Girls were consumed')
    req(len(p.heroes)==6 and c==[1],'Vow summon did not commit exactly once')

def test_awakened_material_is_ownership_only_not_five_star():
    p,s,_=make_services(balder_stars=(6,5,5,5,5),awaken_first=True)
    out=s.vows.summon_super_hero(11002)
    req(out['partner_info']['star']==4,'awakened >5-star prerequisite incorrectly counted as exact 5-star')

def test_missing_and_zero_five_star_fail_atomic():
    p,s,c=make_services(balder_stars=(4,4,4,4,4)); s.heroes.normalize(); snap=copy.deepcopy(vars(p))
    try: s.vows.summon_super_hero(11002); raise AssertionError('zero-five-star summon succeeded')
    except VowServiceError: pass
    req(vars(p)==snap and not c,'zero-five-star failure mutated state')
    p2,s2,c2=make_services(); s2.heroes.normalize(); p2.heroes.pop('10003'); snap2=copy.deepcopy(vars(p2))
    try: s2.vows.summon_super_hero(11002); raise AssertionError('missing-material summon succeeded')
    except VowServiceError: pass
    req(vars(p2)==snap2 and not c2,'missing prerequisite failure mutated state')

def test_duplicate_retry_returns_same_partner():
    p,s,c=make_services(); first=s.vows.summon_super_hero(11002); n=len(p.heroes); second=s.vows.summon_super_hero(11002)
    req(first['partner_info']['partner_id']==second['partner_info']['partner_id'],'duplicate Vow retry allocated new entity')
    req(len(p.heroes)==n and c==[1],'duplicate Vow retry committed')

def test_durable_roundtrip():
    with tempfile.TemporaryDirectory(prefix='pass172_vow_') as td:
        db=MultiUserDatabase(Path(td)/'server_state',DATA); p,s,_=make_services(pid='172006',balder_stars=(5,5,5,5,5)); created=s.vows.summon_super_hero(11002)['partner_info']; db.save_player(p)
        q=db.load_player(p.player_id); req(q is not None,'Vow reload failed'); rows=[h for h in q.heroes.values() if isinstance(h,dict) and int(h.get('table_id',0))==11002]
        req(len(rows)==1 and rows[0]['partner_id']==created['partner_id'] and rows[0]['star']==5 and rows[0].get('partner_type')==2,'Vow persistence drift')

def test_essence_exchange_atomic_and_wire():
    p,s,c=make_services(essence=350); out=s.vows.exchange_essence(11002,3)
    req(out=={'awards':[{'table_id':41002,'item_num':3}]},'MID306 award wire drift')
    req(s.stack_inventory.quantity(50001666)==50 and s.stack_inventory.quantity(41002)==3 and c==[1],'essence exchange mutation drift')
    snap=copy.deepcopy(vars(p)); n=len(c)
    try: s.vows.exchange_essence(11002,1); raise AssertionError('insufficient exchange succeeded')
    except VowServiceError: pass
    req(vars(p)==snap and len(c)==n,'insufficient essence mutated state')

def test_dispatcher_and_fail_closed():
    fake=types.ModuleType('flask'); fake.Request=object; fake.jsonify=lambda data=None,**k:data; fake.make_response=lambda data=None,status=200,**k:data; fake.send_file=lambda *a,**k:None
    sys.modules.setdefault('flask',fake)
    from gxb_backend.config import Settings
    from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
    from gxb_backend.state.repository import StateRepository
    with tempfile.TemporaryDirectory(prefix='pass172_dispatch_') as td:
        root=Path(td); state=StateRepository(DATA/'player_db.json',profile='established',legacy_path=ROOT/'state/gxb_state.json',multiuser_root=root/'server_state'); d=EngineDispatcher(state,Settings(multiuser_root=root/'server_state',runtime_log_dir=root/'logs'))
        req(getattr(d.handlers[MID.SUMMON_SUPER_HERO],'__name__','')=='summon_super_hero','MID305 route missing')
        req(getattr(d.handlers[MID.SUPER_HERO_STONE_EXCHANGE],'__name__','')=='super_hero_stone_exchange','MID306 route missing')
    p,s,_=make_services(balder_stars=(4,4,4,4,4))
    from gxb_backend.handlers.context import HandlerContext
    from gxb_backend.handlers.summon import SummonHandlers
    class St:
        def get_services(self): return s
    class Set: pass
    h=SummonHandlers(HandlerContext(state=St(),settings=Set(),resource_gateway=None))
    bad=h.summon_super_hero({'table_id':11002}); req(isinstance(bad,EngineTransportResult) and bad.status_code==409,'MID305 failure not HTTP409')

def main():
    tests=[test_source_catalog_and_client_contract,test_balder_dynamic_star_and_no_sacrifice,test_awakened_material_is_ownership_only_not_five_star,test_missing_and_zero_five_star_fail_atomic,test_duplicate_retry_returns_same_partner,test_durable_roundtrip,test_essence_exchange_atomic_and_wire,test_dispatcher_and_fail_closed]
    for t in tests: t(); print('PASS',t.__name__,flush=True)
    print(f'PASS Pass172 Vow acquisition/tab closure ({len(tests)}/{len(tests)})',flush=True)
if __name__=='__main__': main()
