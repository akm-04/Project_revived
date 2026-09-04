#!/usr/bin/env python3
"""Verify Pass344 I5 remains a bounded realtime/outbox/liveness wave over sealed Pass343."""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from pass_artifact_resolver import resolve_pass_artifact

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0,str(ROOT))

RUNTIME=ROOT/'docs/json/PASS344_RUNTIME_DELTA_MANIFEST.json'
I5=ROOT/'docs/json/PASS344_I5_REALTIME_MANIFEST.json'
P343=ROOT/'docs/json/PASS343_SOURCE_BACKEND_CROSSCHECK.json'
EXPECTED_BASELINE_ROOT='acf9220097059037be2699dac33640757dd1a853fadb10df9e7b99c427a70eaa'
EXPECTED_CURRENT_ROOT='4a76b2101a70a5d95f2517496916223b42adf2c922295d968b8bae73ddc86039'
EXPECTED_CURRENT_BYTES=83565877
ALLOWED_RUNTIME_MODIFIED={
    'gxb_backend/realtime/contracts.py',
    'gxb_backend/realtime/control.py',
    'gxb_backend/realtime/server.py',
    'gxb_backend/realtime/session.py',
}


def sha(path:Path)->str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def root_digest(paths:dict[str,Path])->tuple[str,int]:
    d=hashlib.sha256(); total=0
    for rel in sorted(paths):
        content=paths[rel].read_bytes(); rb=rel.encode(); total+=len(content)
        d.update(len(rb).to_bytes(4,'big')); d.update(rb)
        d.update(len(content).to_bytes(8,'big')); d.update(content)
    return d.hexdigest(),total


def verify_runtime()->tuple[int,str,int]:
    data=json.loads(RUNTIME.read_text())
    if data['baseline_root_sha256']!=EXPECTED_BASELINE_ROOT or data['baseline_files']!=495:
        raise SystemExit('PASS344 I5 INVARIANTS: FAIL baseline runtime authority')
    baseline=data['baseline_sha256_by_path']; changed=[]; observed={}
    for rel,want in baseline.items():
        p=ROOT/rel
        if not p.is_file(): raise SystemExit(f'PASS344 I5 INVARIANTS: FAIL missing runtime {rel}')
        got=sha(p); observed[rel]=p
        if got!=want: changed.append(rel)
    if set(changed)!=ALLOWED_RUNTIME_MODIFIED:
        raise SystemExit(f'PASS344 I5 INVARIANTS: FAIL runtime delta {changed}')
    for rel,want in data['allowed_modified_sha256'].items():
        if sha(resolve_pass_artifact(ROOT, rel))!=want: raise SystemExit(f'PASS344 I5 INVARIANTS: FAIL modified hash {rel}')
    digest,total=root_digest(observed)
    if digest!=EXPECTED_CURRENT_ROOT or total!=EXPECTED_CURRENT_BYTES:
        raise SystemExit(f'PASS344 I5 INVARIANTS: FAIL runtime root/bytes {digest}/{total}')
    return len(observed),digest,total


def verify_src64_and_mature_seams()->None:
    data=json.loads(P343.read_text())
    for row in data['client_runtime_rechecked']:
        if sha(ROOT/row['path'])!=row['sha256']:
            raise SystemExit(f"PASS344 I5 INVARIANTS: FAIL src64 drift {row['path']}")
    rows={row['path']:row for row in data['backend_runtime_rechecked']}
    for rel in ('gxb_backend/state/repository.py','gxb_backend/state/multiuser_database.py','gxb_backend/dispatch/engine_dispatcher.py','gxb_backend/auth/perimeter.py'):
        if sha(resolve_pass_artifact(ROOT, rel))!=rows[rel]['sha256']:
            raise SystemExit(f'PASS344 I5 INVARIANTS: FAIL mature seam drift {rel}')
    repo=(ROOT/'gxb_backend/state/repository.py').read_text()
    if 'threading.RLock()' not in repo:
        raise SystemExit('PASS344 I5 INVARIANTS: FAIL global RLock retired early')


def verify_i5_manifest()->int:
    data=json.loads(I5.read_text())
    failures=[]
    for rel,want in data['sha256_by_path'].items():
        p=ROOT/rel; got=sha(p) if p.is_file() else 'MISSING'
        if got!=want: failures.append((rel,want,got))
    if failures:
        raise SystemExit('PASS344 I5 INVARIANTS: FAIL I5 hashes='+json.dumps(failures[:20]))
    return len(data['sha256_by_path'])


def verify_scope()->None:
    app=(ROOT/'gxb_backend/app_factory.py').read_text()
    run=(ROOT/'gxb_backend/run.py').read_text()
    if 'gxb_backend.realtime.gateway' in app or 'RealtimeGateway(' in app or 'RealtimeGateway(' in run:
        raise SystemExit('PASS344 I5 INVARIANTS: FAIL dedicated gateway wired into default app before runtime cutover')
    if 'RealtimeRuntime(settings.chat_host, settings.chat_port, repo)' not in app:
        raise SystemExit('PASS344 I5 INVARIANTS: FAIL legacy default realtime runtime changed unexpectedly')
    session=(ROOT/'gxb_backend/realtime/session.py').read_text()
    if 'gameplay_token' in session or ' token:' in session:
        raise SystemExit('PASS344 I5 INVARIANTS: FAIL raw gameplay bearer retained in realtime session')
    durable=(ROOT/'gxb_backend/realtime/durable.py').read_text()
    if 'DeliveryClass.DURABLE_USER_DELIVERY' in durable:
        raise SystemExit('PASS344 I5 INVARIANTS: FAIL gateway claims durable-user delivery')
    migration=(ROOT/'migrations/versions/0005_pass344_i5_realtime_wakeup.py').read_text()
    for forbidden in ('CREATE TABLE','mail_items','scheduled_jobs','global_projections','realtime_sessions'):
        if forbidden in migration:
            raise SystemExit(f'PASS344 I5 INVARIANTS: FAIL I5 schema creep {forbidden}')
    if "FOR EACH STATEMENT" not in migration or "pg_notify('gxb_outbox', 'wake')" not in migration:
        raise SystemExit('PASS344 I5 INVARIANTS: FAIL wakeup trigger contract')
    control=(ROOT/'gxb_backend/realtime/control.py').read_text()
    if 'close_context_room' not in control:
        raise SystemExit('PASS344 I5 INVARIANTS: FAIL durable room invalidation gateway resolution missing')
    if 'PRIVATE_SERVER_CONTROL_MID = 65_000' not in control:
        raise SystemExit('PASS344 I5 INVARIANTS: FAIL private control MID drift')


def main()->None:
    count,digest,total=verify_runtime(); verify_src64_and_mature_seams(); hashes=verify_i5_manifest(); verify_scope()
    print(f'PASS344 I5 INVARIANTS: PASS runtime_files={count} runtime_bytes={total} runtime_root={digest} i5_hashes={hashes}')

if __name__=='__main__': main()
