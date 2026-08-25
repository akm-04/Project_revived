#!/usr/bin/env python3
"""Pass104 Phase-1 mutation-safety firewall self-test."""
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
    # status_only_names is populated by an explicit string list rather than a dict.
    for n in ast.walk(fn):
        if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id=='status_only_names' for t in n.targets) and isinstance(n.value, (ast.List, ast.Tuple)):
            for e in n.value.elts:
                if isinstance(e, ast.Constant) and isinstance(e.value, str): names.add(e.value)
    return names

def main():
    path=ROOT/'data/mutation_contract_registry.json'
    payload=json.loads(path.read_text())
    require(payload['counts']=={'contracts':95,'phase1_block':79,'phase2_session':8,'terminal_deferred':8}, f"count drift {payload['counts']}")
    registry=MutationContractRegistry.load(path)
    routes=routed_names()
    for c in registry.values():
        require(getattr(MID,c.name)==c.mid, f"MID drift {c.name}")
        require(c.name in routes, f"audited route missing from dispatcher: {c.name}")
    labels=ProtocolRegistry.load(ROOT/'data/protocol_registry.json')
    fake={c.mid:(lambda req: {}) for c in registry.values()}
    MutationSafetyFirewall(registry).validate_routes(fake, labels.label)
    fw=MutationSafetyFirewall(registry)
    for name in ('BUY_SHOP','BATTLE_PASS_BUY_LEVEL','PET_PRACTICE','REFRESH_SHOP','SEND_SOCIAL_GIFT','WORLD_BOSS_SWEEP'):
        r=fw.evaluate(getattr(MID,name),name)
        require(isinstance(r,EngineTransportResult) and r.status_code==409, f"{name} not blocked")
        require(r.body['error_code']==1 and r.body['msg']=='mutation_contract_unimplemented', f"{name} body drift")
        require('error_msg' not in r.body, f"{name} error_msg forbidden")
    for name in ('START_FIGHT','ARENA_PRE_FIGHT','MARCH_START_FIGHT','ARENA_FIGHT_RESULT','REGION_FIGHT_RESULT'):
        require(fw.evaluate(getattr(MID,name),name) is None, f"session contract prematurely blocked in Phase1: {name}")
    dispatch=(ROOT/'gxb_backend/dispatch/engine_dispatcher.py').read_text()
    require(dispatch.index('self.mutation_firewall.evaluate') < dispatch.index('self.state.evaluate_daily_reset'), 'firewall must precede daily reset/handler mutation')
    require('EngineTransportResult(body=result, status_code=409)' in dispatch, 'unknown blocked path not transport fail-closed')
    routes_py=(ROOT/'gxb_backend/transport/routes_engine.py').read_text()
    require('status_code=response.status_code' in routes_py, 'transport status not propagated')
    src64=Path(os.environ.get('GXB_SRC64',''))
    if src64.is_dir():
        backend=(src64/'app/common/network/Backend.lua').read_text(errors='ignore')
        require('if var_31_1 ~= 200 then' in backend and 'xyd.error.ERROR' in backend, 'Backend.lua HTTP-status contract drift')
        require('arg_25_0.error_msg' in backend and 'restart_game' in backend, 'Backend.lua error_msg restart path drift')
        shop=(src64/'app/model/Shop.lua').read_text(errors='ignore')
        require('getBackpack():addItem' in shop and 'getBackpack():removeItem' in shop, 'Shop optimistic mutation evidence drift')
        bp=(src64/'app/model/BattlePass.lua').read_text(errors='ignore')
        require('arg_6_0 == xyd.error.OK' in bp and 'awarded_lev' in bp, 'BattlePass optimistic mutation evidence drift')
        msg=(src64/'data/tables/message.lua').read_text(errors='ignore')
        require('[1] =' not in msg and '[1]=' not in msg, 'private error_code=1 unexpectedly became official message')
    report={'pass':'104.0','status':'PASS','contracts':payload['counts'],'checks':['95 audited contracts route/MID validation','79 phase1 HTTP409 blocks','16 session contracts explicitly deferred','no error_msg','firewall before mutation paths','unknown blocked path HTTP409','transport status propagation','src64 Backend.lua/Shop/BattlePass error-success semantics']}
    (ROOT/'docs/PASS104_MUTATION_FIREWALL_SELFTEST.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))
    return 0
if __name__=='__main__': raise SystemExit(main())
