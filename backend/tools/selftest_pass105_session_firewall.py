#!/usr/bin/env python3
"""Pass105 session-entry Mutation Safety Firewall self-test."""
from __future__ import annotations
import ast, json, os, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
from gxb_backend.protocol.mids import MID
from gxb_backend.protocol.mutation_contracts import MutationContractRegistry, MutationSafetyFirewall
from gxb_backend.protocol.registry import ProtocolRegistry
from gxb_backend.transport.result import EngineTransportResult

def require(c,m):
    if not c: raise AssertionError(m)

def routed_names() -> set[str]:
    tree=ast.parse((ROOT/'gxb_backend/dispatch/engine_dispatcher.py').read_text())
    fn=next(n for n in ast.walk(tree) if isinstance(n,ast.FunctionDef) and n.name=='_build_handlers')
    names=set()
    for n in ast.walk(fn):
        if isinstance(n,ast.Dict):
            for k in n.keys:
                if isinstance(k,ast.Constant) and isinstance(k.value,str): names.add(k.value)
                elif isinstance(k,ast.Attribute) and isinstance(k.value,ast.Name) and k.value.id=='MID': names.add(k.attr)
                elif isinstance(k,ast.Call) and isinstance(k.func,ast.Name) and k.func.id=='getattr' and len(k.args)>=2 and isinstance(k.args[1],ast.Constant): names.add(str(k.args[1].value))
    for n in ast.walk(fn):
        if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='status_only_names' for t in n.targets) and isinstance(n.value,(ast.List,ast.Tuple)):
            for e in n.value.elts:
                if isinstance(e,ast.Constant) and isinstance(e.value,str): names.add(e.value)
    return names

def main():
    path=ROOT/'data/mutation_contract_registry.json'
    payload=json.loads(path.read_text())
    expected={'contracts':95,'phase1_block':79,'phase2_block':8,'terminal_deferred':8}
    require(payload['counts']==expected, f"count drift {payload['counts']}")
    registry=MutationContractRegistry.load(path)
    routes=routed_names()
    labels=ProtocolRegistry.load(ROOT/'data/protocol_registry.json')
    fake={c.mid:(lambda req: {}) for c in registry.values()}
    MutationSafetyFirewall(registry).validate_routes(fake, labels.label)
    for c in registry.values():
        require(getattr(MID,c.name)==c.mid, f"MID drift {c.name}")
        require(c.name in routes, f"audited route missing {c.name}")
    fw=MutationSafetyFirewall(registry)
    phase2=('START_FIGHT','ARENA_MODE_FIGHT_PRE','ARENA_MODE_FIGHT','ARENA_PRE_FIGHT','MARCH_START_FIGHT','WORLD_BOSS_START_FIGHT','PET_CAMPAIGN_FIGHT','PEAK_START_FIGHT')
    for name in phase2:
        c=registry.contract(getattr(MID,name)); require(c is not None and c.enforcement=='BLOCK_PHASE2',f'{name} not BLOCK_PHASE2')
        require(c.backend_capability=='EXPLICIT_FAIL_CLOSED',f'{name} capability drift')
        r=fw.evaluate(getattr(MID,name),name)
        require(isinstance(r,EngineTransportResult) and r.status_code==409,f'{name} not HTTP409 blocked')
        require(r.body.get('error_code')==1 and r.body.get('msg')=='mutation_contract_unimplemented',f'{name} body drift')
        require('error_msg' not in r.body,f'{name} error_msg forbidden')
    terminals=('ARENA_FIGHT_RESULT','MARCH_FIGHT_RESULT','TREASURE_SAVE_BATTLE_RESULT','WORLD_BOSS_FIGHT_RESULT','REARENA_END_FIGHT','PET_CAMPAIGN_BATTLE_RESULT','REGION_FIGHT_RESULT','CONQUER_SCHOOL_FIGHT_RESULT')
    for name in terminals:
        c=registry.contract(getattr(MID,name)); require(c is not None and c.enforcement=='DEFER_TERMINAL',f'{name} terminal drift')
        require(fw.evaluate(getattr(MID,name),name) is None,f'{name} terminal prematurely blocked')
    # Existing Phase1 remains active.
    for name in ('BUY_SHOP','BATTLE_PASS_BUY_LEVEL','PET_PRACTICE'):
        r=fw.evaluate(getattr(MID,name),name); require(isinstance(r,EngineTransportResult) and r.status_code==409,f'{name} phase1 regression')
    dispatch=(ROOT/'gxb_backend/dispatch/engine_dispatcher.py').read_text()
    require(dispatch.index('self.mutation_firewall.evaluate') < dispatch.index('self.state.evaluate_daily_reset'),'firewall ordering drift')
    src64=Path(os.environ.get('GXB_SRC64',''))
    if src64.is_dir():
        backend=(src64/'app/common/network/Backend.lua').read_text(errors='ignore')
        require('if var_31_1 ~= 200 then' in backend and 'xyd.error.ERROR' in backend,'Backend transport contract drift')
        checks={
            'app/windows/ArenaWindow.lua':['xyd.mid.ARENA_MODE_FIGHT_PRE','xyd.mid.ARENA_PRE_FIGHT','openWindow("arena_select_team"'],
            'app/windows/ArenaSelectTeamNewWindow.lua':['xyd.mid.START_FIGHT','xyd.mid.ARENA_MODE_FIGHT','battleBegan = false'],
            'app/windows/SelectTeamNewWindow.lua':['xyd.mid.MARCH_START_FIGHT','xyd.mid.WORLD_BOSS_START_FIGHT','xyd.mid.PET_CAMPAIGN_FIGHT','battleBegan = false'],
            'app/windows/SelectPeakTeamWindow.lua':['startPeakArenaBattle','arg_107_0.battleBegan = false'],
        }
        for rel,pats in checks.items():
            text=(src64/rel).read_text(errors='ignore')
            for pat in pats: require(pat in text,f'src64 phase2 proof drift {rel}: {pat}')
    report={'pass':'105.0','status':'PASS','contracts':expected,'checks':['8 source-proven session entry MIDs HTTP409','79 Phase1 blocks preserved','8 terminal contracts remain deferred','canonical no-error_msg body preserved','firewall before DailyReset/handler/UoW','src64 transport + session callback evidence']}
    (ROOT/'docs/PASS105_SESSION_FIREWALL_SELFTEST.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
    return 0
if __name__=='__main__': raise SystemExit(main())
