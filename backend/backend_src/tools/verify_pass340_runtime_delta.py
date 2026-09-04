#!/usr/bin/env python3
"""Verify Pass340 I1 changed only its frozen bounded runtime allow-list."""
from __future__ import annotations
import hashlib,json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/'docs/json/PASS340_RUNTIME_DELTA_MANIFEST.json'

def included_files() -> dict[str,Path]:
    out:dict[str,Path]={}
    for rr in ('gxb_backend','data','local_assets'):
        for p in (ROOT/rr).rglob('*'):
            if not p.is_file() or '__pycache__' in p.parts or p.suffix=='.pyc': continue
            rel=p.relative_to(ROOT).as_posix()
            if rel.startswith('gxb_backend/foundation/') or rel=='gxb_backend/version.py': continue
            out[rel]=p
    for rel in ('server.py','update_controller.py'):
        p=ROOT/rel
        if p.exists(): out[rel]=p
    return out

def sha(path:Path)->str: return hashlib.sha256(path.read_bytes()).hexdigest()

def root_digest(paths:dict[str,Path], selected:list[str])->tuple[str,int]:
    h=hashlib.sha256(); n=0
    for rel in sorted(selected):
        content=paths[rel].read_bytes(); rb=rel.encode(); n+=len(content)
        h.update(len(rb).to_bytes(4,'big'));h.update(rb);h.update(len(content).to_bytes(8,'big'));h.update(content)
    return h.hexdigest(),n

def main()->None:
    m=json.loads(MANIFEST.read_text())
    paths=included_files(); current=set(paths)
    baseline=dict(m['baseline_sha256_by_path']); modified=dict(m['allowed_modified_sha256']); added=dict(m['allowed_added_sha256'])
    wanted=set(baseline)|set(added)
    if current!=wanted:
        raise SystemExit(f"PASS340 RUNTIME DELTA: FAIL path_set added={sorted(current-wanted)} missing={sorted(wanted-current)}")
    failures=[]
    for rel,want in baseline.items():
        got=sha(paths[rel])
        if rel in modified:
            want=modified[rel]
        if got!=want: failures.append((rel,want,got))
    for rel,want in added.items():
        got=sha(paths[rel])
        if got!=want: failures.append((rel,want,got))
    if failures:
        raise SystemExit('PASS340 RUNTIME DELTA: FAIL hashes='+json.dumps(failures[:20]))
    unchanged=sorted(set(baseline)-set(modified))
    frozen_sha,frozen_bytes=root_digest(paths,unchanged)
    full_sha,full_bytes=root_digest(paths,sorted(paths))
    expected=(m['unchanged_root_sha256'],int(m['unchanged_content_bytes']),m['current_root_sha256'],int(m['current_content_bytes']))
    observed=(frozen_sha,frozen_bytes,full_sha,full_bytes)
    if observed!=expected:
        raise SystemExit(f'PASS340 RUNTIME DELTA: FAIL roots expected={expected} observed={observed}')
    print('PASS340 RUNTIME DELTA: PASS '
          f"baseline={len(baseline)} current={len(paths)} unchanged={len(unchanged)} "
          f"modified={len(modified)} added={len(added)} bytes={full_bytes} sha256={full_sha}")

if __name__=='__main__': main()
