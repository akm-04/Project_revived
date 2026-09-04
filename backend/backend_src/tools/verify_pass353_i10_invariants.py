#!/usr/bin/env python3
"""Pass353 I10 OTA topology invariant verifier."""
from __future__ import annotations
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def sha(path:Path)->str:
    h=hashlib.sha256(); h.update(path.read_bytes()); return h.hexdigest()

def req(c:bool,m:str)->None:
    if not c: raise SystemExit('PASS353 I10 INVARIANTS: FAIL '+m)

def main()->None:
    v=json.loads((ROOT/'VERSION.json').read_text())
    req(v.get('pass')=='353.0','VERSION pass')
    req(v.get('backend_version')=='0.65.2','VERSION backend')
    r=json.loads((ROOT/'docs/json/PASS353_I10_OTA_TOPOLOGY_RECONCILIATION.json').read_text())
    req(r.get('status')=='CANDIDATE_PENDING_STOCK_RETEST','candidate status')
    bad=[]
    for rel,expected in r.get('candidate_hashes',{}).items():
        p=ROOT/rel; actual=sha(p) if p.is_file() else 'MISSING'
        if actual!=expected: bad.append((rel,expected,actual))
    req(not bad,'candidate hash drift '+json.dumps(bad[:20]))
    dev=(ROOT/'gxb-dev.sh').read_text()
    req('prepare_stock_updates "$py"' in dev and 'update_controller.py ensure' in dev,'pre-listener OTA ensure missing')
    req(dev.index('prepare_stock_updates "$py"') < dev.index('start_bg http "$VENV/bin/gunicorn"', dev.index('prepare_stock_updates "$py"')),'OTA ensure occurs after HTTP start')
    req('location /res/ { alias' not in dev,'nginx still bypasses catalog-aware /res gateway')
    routes=(ROOT/'gxb_backend/transport/routes_engine.py').read_text()
    req('@app.route("/res/<path:asset>"' in routes and 'resource_gateway.capture(request, asset)' in routes,'resource gateway route missing')
    wrapper=(ROOT/'tools/workspace/gxb_backend_workspace.sh').read_text()
    req('WRAPPER_VERSION="7"' in wrapper,'wrapper v7 missing')
    req('OTA_DIR="${GXB_OTA_HOME:-$RUNTIME_DIR/ota}"' in wrapper,'persistent OTA root missing')
    req('ln -s -- "$OTA_DIR/updates" "$root/local_assets/updates"' in wrapper,'persistent update volumes not wired')
    for name in ('release_registry.json','update_manifest.json','update_controller_state.json'):
        req(name in wrapper,f'persistent OTA metadata missing {name}')
    # Carry forward critical Pass349-352 safety boundaries.
    relational=(ROOT/'gxb_backend/runtime/state_repository.py').read_text()
    req('with self._lock' not in relational and 'del self._lock' in relational,'I9 relational global RLock returned')
    perimeter=(ROOT/'gxb_backend/auth/perimeter.py').read_text(); req('2_864' in perimeter,'Pass349 MID2864 scope lost')
    decoder=(ROOT/'gxb_backend/transport/decoder.py').read_text(); req('bytes(raw) == b"nil"' in decoder,'Pass351 exact nil boundary lost')
    login=(ROOT/'local_assets/src_64/app/windows/LoginWindow.lua').read_text(encoding='utf-8-sig')
    req('xyd.db.meta.regionID > 0 and not arg_1_0.isSDKLogin' in login,'Pass352 region revalidation lost')
    print('PASS353 I10 INVARIANTS: PASS ota=prelistener persistent edge=catalog-aware wrapper=v7 pg=unchanged')
if __name__=='__main__': main()
