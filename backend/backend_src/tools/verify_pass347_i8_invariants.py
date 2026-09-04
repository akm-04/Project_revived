#!/usr/bin/env python3
from __future__ import annotations
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def sha(path:Path)->str:
    h=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
    return h.hexdigest()

def main()->None:
    manifest=json.loads((ROOT/'docs/json/PASS347_I8_RUNTIME_MANIFEST.json').read_text())
    bad=[]
    for rel,expected in manifest['sha256_by_path'].items():
        path=ROOT/rel; actual=sha(path) if path.is_file() else 'MISSING'
        if actual!=expected: bad.append((rel,expected,actual))
    if bad: raise SystemExit('PASS347 I8 INVARIANTS: FAIL '+json.dumps(bad[:20]))
    state=(ROOT/'gxb_backend/runtime/state_repository.py').read_text()
    authority=(ROOT/'gxb_backend/runtime/authority.py').read_text()
    migration=(ROOT/'migrations/versions/0008_pass347_i8_runtime_cutover.py').read_text()
    gunicorn=(ROOT/'deploy/gunicorn.conf.py').read_text()
    if 'MultiUserDatabase' in state or 'threading.RLock()' not in state:
        raise SystemExit('PASS347 I8 INVARIANTS: FAIL relational adapter authority/lock')
    for required in ('OPEN POSTGRESQL TRAFFIC PERMANENTLY','legacy JSON runtime is permanently disabled'):
        if required not in authority: raise SystemExit('PASS347 I8 INVARIANTS: FAIL missing '+required)
    for required in ('runtime_authority_no_reversal','migration_run_no_traffic_reversal','cannot downgrade after TRAFFIC_OPEN'):
        if required not in migration: raise SystemExit('PASS347 I8 INVARIANTS: FAIL missing '+required)
    if 'workers != 1' not in gunicorn or 'worker_class = "gthread"' not in gunicorn:
        raise SystemExit('PASS347 I8 INVARIANTS: FAIL worker gate')
    source=json.loads((ROOT/'docs/json/PASS347_SOURCE_BACKEND_CROSSCHECK.json').read_text())
    for row in source['source_facts']:
        if sha(ROOT/row['path'])!=row['sha256']: raise SystemExit('PASS347 I8 INVARIANTS: FAIL source drift '+row['path'])
    if sha(ROOT/'gxb_backend/state/multiuser_database.py')!='af43acc4a8e9d133f3c99fe65846459cab92aebb3f505b2d8725f947ee68fde3':
        raise SystemExit('PASS347 I8 INVARIANTS: FAIL legacy migration source drift')
    print(f"PASS347 I8 INVARIANTS: PASS hashes={len(manifest['sha256_by_path'])} workers=1 rlock=retained postgres=canonical-after-open")

if __name__=='__main__': main()
