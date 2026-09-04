#!/usr/bin/env python3
"""Pass352 I10 stock-runtime reconciliation invariant verifier."""
from __future__ import annotations
import hashlib, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def sha(path:Path)->str:
    h=hashlib.sha256()
    with path.open('rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
    return h.hexdigest()

def require(c:bool,m:str)->None:
    if not c: raise SystemExit('PASS352 I10 INVARIANTS: FAIL '+m)

def main()->None:
    v=json.loads((ROOT/'VERSION.json').read_text())
    require(v.get('pass')=='352.0','VERSION pass')
    require(v.get('backend_version')=='0.65.1','VERSION backend')
    r=json.loads((ROOT/'docs/json/PASS352_I10_STOCK_RUNTIME_RECONCILIATION.json').read_text())
    require(r.get('status')=='CANDIDATE_PENDING_STOCK_RETEST','candidate status')
    bad=[]
    for rel,expected in r.get('candidate_hashes',{}).items():
        p=ROOT/rel; actual=sha(p) if p.is_file() else 'MISSING'
        if actual!=expected: bad.append((rel,expected,actual))
    require(not bad,'candidate hash drift '+json.dumps(bad[:20]))

    relational=(ROOT/'gxb_backend/runtime/state_repository.py').read_text()
    legacy=(ROOT/'gxb_backend/state/repository.py').read_text()
    require('with self._lock' not in relational and 'del self._lock' in relational,'PostgreSQL request RLock returned')
    require('threading.RLock()' in legacy and 'with self._lock' in legacy,'legacy JSON RLock changed')
    perimeter=(ROOT/'gxb_backend/auth/perimeter.py').read_text()
    require('2_864' in perimeter and 'PUBLIC_MIDS' in perimeter,'Pass349 MID2864 fix missing')
    normalize=(ROOT/'tools/dev_legacy_sandbox_normalize.py').read_text()
    require('LEGACY_SANDBOX_REGION_PLAYER_ID_REMAP' in normalize,'Pass350 sandbox remap missing')
    routes=(ROOT/'gxb_backend/transport/routes_engine.py').read_text()
    decoder=(ROOT/'gxb_backend/transport/decoder.py').read_text()
    require('def is_legacy_nil_payload' in decoder and 'bytes(raw) == b"nil"' in decoder,'Pass351 nil predicate')
    require('if is_legacy_nil_payload(raw):' in routes and 'status_code=400' in routes,'Pass351 malformed boundary')
    require('except PlayerAggregateNotMaterialized:' in relational and 'self._aggregates.materialize' in relational,'Pass351 stub repair missing')

    maintenance=(ROOT/'gxb_backend/state/maintenance_services.py').read_text()
    require('def normalize_player_domain(' in maintenance,'shared durable normalizer missing')
    require('SkillPointPolicy(fresh, self._data_dir()).initialize_fresh_full_pool()' in relational,'fresh skill pool missing')
    require(relational.count('normalize_player_domain(')>=2 and 'self._player_store.save(player)' in relational,'PostgreSQL load repair missing')
    dev=(ROOT/'gxb-dev.sh').read_text()
    require('emit_export GXB_STATIC_ASSET_ROOT "$ROOT/local_assets"' in dev,'OTA static root still nested')
    require('db_restore()' in dev and 'db-restore) db_restore' in dev,'PostgreSQL restore command missing')
    login=(ROOT/'local_assets/src_64/app/windows/LoginWindow.lua').read_text(encoding='utf-8-sig')
    require('xyd.db.meta.regionID > 0 and not arg_1_0.isSDKLogin' in login,'SDK MID18 revalidation missing')
    require('if #var_2_2 == 1 then' in login and 'arg_1_0.currentRegion = nil' in login,'ambiguous region guard missing')
    wrapper=(ROOT/'tools/workspace/gxb_backend_workspace.sh').read_text()
    require('WRAPPER_VERSION="7"' in wrapper,'Pass352 lifecycle not carried into current wrapper v7')
    require('clear_runtime_logs()' in wrapper and 'workspace_backup()' in wrapper and 'workspace_restore()' in wrapper,'wrapper clean-update/backup/restore lifecycle missing')
    require('no legacy JSON remigration' in wrapper,'backup authority boundary missing')
    print('PASS352 I10 INVARIANTS: PASS sealed_hashes=%d fresh=normalized ota=root-fixed regions=account-revalidated wrapper=v6 pg_backup_restore=enabled' % len(r.get('candidate_hashes',{})))
if __name__=='__main__': main()
