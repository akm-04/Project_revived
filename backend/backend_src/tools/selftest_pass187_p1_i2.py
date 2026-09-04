from __future__ import annotations
import copy, json, sys, tempfile, types
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.white_album_source_catalog import WhiteAlbumSourceCatalog
from gxb_backend.protocol.mids import MID
from gxb_backend.protocol.mutation_contracts import MutationContractRegistry
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices

ROOT=Path(__file__).resolve().parents[1]
DATA=ROOT/'data'
CATALOG=GameDataCatalog.load(DATA/'game_data_catalog.json')

def req(cond,msg):
    if not cond: raise AssertionError(msg)

def hero(pid,tid,star=5,color=16,equips=None):
    return {
        'partner_id':pid,'table_id':tid,'star':star,'lev':100,'exp':0,'color':color,
        'skills':[1]*6,'equips':list(equips if equips is not None else [1]*6),'fumos':[0]*6,'fumo_levels':[0]*6,
        'element_equips':[0]*4,'element_levels':[0]*4,'element_bak_equips':[],'element_bak_levels':[],
        'inscript_items':[],'collect_quality_stage':0,'collect_star_stage':0,
    }

def services(heroes,lev=100,max_lev=100):
    p=PlayerState(player_id='998701',account_uid='998701',player_name='Pass187')
    p.lev=lev;p.max_lev=max_lev;p.heroes={str(h['partner_id']):copy.deepcopy(h) for h in heroes}
    p.collected_heros={str(h['table_id']):{'table_id':h['table_id'],'star':h['star'],'is_collected':1} for h in heroes}
    commits=[]
    s=RequestServices(p,DATA,lambda: commits.append(int(p.persistence_state.get('state_version',-1))),catalog=CATALOG)
    return p,s,commits

def test_white_album_source_and_normal_claim():
    w=WhiteAlbumSourceCatalog(DATA)
    req(len(w.normal)==132 and len(w.special)==23,'White Album census drift')
    req(w.quality_stages(10001001)==(1,2,4,7,12,15),'Aquaris quality thresholds drift')
    req(w.star_stages(10001001)==(4,5),'Aquaris star thresholds drift')
    p,s,c=services([hero(87001,10001001)])
    req(s.white_album.claim_normal(87001)=={},'normal claim rejected')
    h=s.heroes.get(87001); req((h['collect_quality_stage'],h['collect_star_stage'])==(6,2),'normal catch-up stages wrong')
    n=len(c); req(s.white_album.claim_normal(87001)=={} and len(c)==n,'duplicate normal claim not idempotent')

def test_white_album_awakened_lineage_and_special_super_mix():
    p,s,_=services([hero(87002,11001001)])
    req(s.white_album.claim_normal(87002)=={},'awakened normal claim rejected')
    req((s.heroes.get(87002)['collect_quality_stage'],s.heroes.get(87002)['collect_star_stage'])==(6,2),'awakened lineage did not map to origin')
    w=s.white_album_source
    # Set 2 intentionally mixes three Normal origins and Super IDs 11001/11002.
    ids=w.special_partner_ids(2); req(11001 in ids and 11002 in ids,'special source no longer tests Super ownership')
    hs=[]
    for i,tid in enumerate(ids,1): hs.append(hero(87100+i,tid))
    p2,s2,c2=services(hs)
    req(s2.white_album.special_info()['is_award']==[0]*23,'fresh special vector drift')
    req(s2.white_album.claim_special(2)=={},'special set with Super IDs rejected')
    req(s2.white_album.special_info()['is_award'][1]==1,'special claim did not persist')
    n=len(c2); req(s2.white_album.claim_special(2)=={} and len(c2)==n,'duplicate special claim not idempotent')
    p3,s3,_=services(hs[:-1]); bad=s3.white_album.claim_special(2)
    req(bad.get('error_code')==1,'incomplete special requirements accepted')

def _seed(p,*pairs):
    p.backpack_items=[{'table_id':int(item),'item_num':int(num),'time':0} for item,num in pairs]

def test_white_album_durable_roundtrip():
    from gxb_backend.state.multiuser_database import MultiUserDatabase
    with tempfile.TemporaryDirectory(prefix='pass187_album_roundtrip_') as td:
        p,s,_=services([hero(87501,10001001)])
        req(s.white_album.claim_normal(87501)=={},'roundtrip normal claim rejected')
        ids=s.white_album_source.special_partner_ids(1)
        p2,s2,_=services([hero(87600+i,tid) for i,tid in enumerate(ids,1)])
        req(s2.white_album.claim_special(1)=={},'roundtrip special claim rejected')
        db=MultiUserDatabase(Path(td),DATA)
        db.save_player(p); r=db.load_player(p.player_id); req(r is not None,'normal roundtrip load failed')
        rh=r.heroes.get('87501') or r.heroes.get(87501); req(rh and rh.get('collect_quality_stage')==6 and rh.get('collect_star_stage')==2,'normal Album stages lost on restart')
        db.save_player(p2); r2=db.load_player(p2.player_id); req(r2 is not None and int((r2.white_album_state.get('special_claims') or {}).get('1',0))==1,'special Album claim lost on restart')

def test_element_normal_common_gate_and_slot_types():
    # Generic Core row1/item20001407; generic Normal row7/item20001413; Aquaris SP row26/item20001432; mismatched SP row25.
    p,s,_=services([hero(87201,10001001)])
    _seed(p,(20001407,2),(20001413,2),(20001432,1),(20001431,1))
    req(s.hero_advanced.element_equip({'partner_id':87201,'equip_id':1,'equip_pos':1}).get('error_code')!=1,'Core slot1 rejected')
    req(s.hero_advanced.element_equip({'partner_id':87201,'equip_id':7,'equip_pos':1}).get('error_code')==1,'Normal accepted in slot1')
    req(s.hero_advanced.element_equip({'partner_id':87201,'equip_id':1,'equip_pos':2}).get('error_code')==1,'Core accepted in right slot')
    req(s.hero_advanced.element_equip({'partner_id':87201,'equip_id':7,'equip_pos':2}).get('error_code')!=1,'Normal right slot rejected')
    # Unload current Core then test SP lineage.
    req(s.hero_advanced.element_unload({'partner_id':87201,'equip_pos':1}).get('error_code')!=1,'Core unload rejected')
    req(s.hero_advanced.element_equip({'partner_id':87201,'equip_id':26,'equip_pos':1}).get('error_code')!=1,'matching Aquaris SP Core rejected')
    req(s.hero_advanced.element_unload({'partner_id':87201,'equip_pos':1}).get('error_code')!=1,'SP unload rejected')
    before=s.stack_inventory.quantity(20001431)
    req(s.hero_advanced.element_equip({'partner_id':87201,'equip_id':25,'equip_pos':1}).get('error_code')==1,'mismatched SP Core accepted')
    req(s.stack_inventory.quantity(20001431)==before,'mismatched SP rejection consumed inventory')

def test_element_gate_failures_and_backpack_decompose():
    # Player level gate.
    p,s,_=services([hero(87301,10001001)],lev=99,max_lev=100); _seed(p,(20001407,1))
    req(s.hero_advanced.element_equip({'partner_id':87301,'equip_id':1,'equip_pos':1}).get('error_code')==1,'below max-level Common accepted')
    # Hero color gate.
    p2,s2,_=services([hero(87302,10001001,color=15)]); _seed(p2,(20001407,1))
    req(s2.hero_advanced.element_equip({'partner_id':87302,'equip_id':1,'equip_pos':1}).get('error_code')==1,'below color16 Common accepted')
    # Ordinary equipment completion gate.
    p3,s3,_=services([hero(87303,10001001,equips=[0]*6)]); _seed(p3,(20001407,1))
    req(s3.hero_advanced.element_equip({'partner_id':87303,'equip_id':1,'equip_pos':1}).get('error_code')==1,'incomplete ordinary gear Common accepted')
    # MID2853 is backpack-only and deliberately outside Hero/Common eligibility.
    meta=json.loads((DATA/'hero_advanced_progression_meta.json').read_text()); row=meta['element_equips']['1']; item=int(row['item_id'])
    p4,s4,_=services([hero(87304,10001001,color=1,equips=[0]*6)],lev=1,max_lev=100); _seed(p4,(item,1))
    req(s4.hero_advanced.element_destroy_backpack({'equip_id':1})=={},'MID2853 incorrectly gated by Common eligibility')
    req(s4.stack_inventory.quantity(item)==0,'MID2853 did not debit element item')

def test_super_element_lane_preserved():
    # P1-I2 is the Normal Common retrofit. Preserve the already-accepted separate Super element lane.
    p,s,_=services([hero(87401,11001,color=1,equips=[0]*6)],lev=1,max_lev=100); _seed(p,(20001407,1))
    out=s.hero_advanced.element_equip({'partner_id':87401,'equip_id':1,'equip_pos':1})
    req(out.get('error_code')!=1,'P1-I2 accidentally broke legacy/Super element lane')

def test_dispatch_routes_and_firewall():
    fake=types.ModuleType('flask'); fake.Request=object; fake.jsonify=lambda data=None,**k:data; fake.make_response=lambda data=None,status=200,**k:data; fake.send_file=lambda *a,**k:None
    sys.modules.setdefault('flask',fake)
    from gxb_backend.config import Settings
    from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
    from gxb_backend.state.repository import StateRepository
    with tempfile.TemporaryDirectory(prefix='pass187_dispatch_') as td:
        root=Path(td); state=StateRepository(DATA/'player_db.json',profile='established',legacy_path=ROOT/'state/gxb_state.json',multiuser_root=root/'server_state')
        d=EngineDispatcher(state,Settings(multiuser_root=root/'server_state',runtime_log_dir=root/'logs'))
        req(getattr(d.handlers[MID.ALBUM_PARTNER_UNLOCK],'__name__','')=='album_partner_unlock','MID72 durable route missing')
        req(getattr(d.handlers[MID.ALBUM_SPECIAL_COLLECT_INFO],'__name__','')=='album_special_collect_info','MID2784 durable route missing')
        req(getattr(d.handlers[MID.ALBUM_SPECIAL_COLLECT_REWARD],'__name__','')=='album_special_collect_reward','MID2785 durable route missing')
    reg=MutationContractRegistry.load(DATA/'mutation_contract_registry.json')
    c=reg.contract(72); req(c is not None and not str(c.enforcement).startswith('BLOCK'),'MID72 mutation firewall still blocks durable implementation')

def main():
    tests=[test_white_album_source_and_normal_claim,test_white_album_awakened_lineage_and_special_super_mix,test_white_album_durable_roundtrip,test_element_normal_common_gate_and_slot_types,test_element_gate_failures_and_backpack_decompose,test_super_element_lane_preserved,test_dispatch_routes_and_firewall]
    for t in tests: t(); print('PASS',t.__name__,flush=True)
    print(f'PASS Pass187 P1-I2 White Album + Element retrofit ({len(tests)}/{len(tests)})',flush=True)

if __name__=='__main__': main()
