#!/usr/bin/env python3
"""Validate the current portable-development packaging overlay."""
from __future__ import annotations
import hashlib, json, subprocess
from pathlib import Path
from pass_artifact_resolver import resolve_pass_artifact

ROOT=Path(__file__).resolve().parents[1]

def sha(path:Path)->str:
    h=hashlib.sha256();
    with path.open('rb') as f:
        for b in iter(lambda:f.read(1024*1024),b''): h.update(b)
    return h.hexdigest()

def main()->None:
    root_pass=list(ROOT.glob('PASS*'))
    if root_pass: raise SystemExit(f'PORTABLE PACKAGE: FAIL root PASS artifacts remain: {[p.name for p in root_pass[:20]]}')
    for rel in ('gxb-dev.sh','tools/workspace/gxb_backend_workspace.sh','docs/guides/PORTABLE_DEV_WORKSPACE.md','vendor/README-PORTABLE.md'):
        if not (ROOT/rel).is_file(): raise SystemExit('PORTABLE PACKAGE: FAIL missing '+rel)
    subprocess.run(['bash','-n',str(ROOT/'gxb-dev.sh')],check=True)
    subprocess.run(['bash','-n',str(ROOT/'tools/workspace/gxb_backend_workspace.sh')],check=True)
    dev=(ROOT/'gxb-dev.sh').read_text(encoding='utf-8')
    helper=(ROOT/'tools/workspace/gxb_backend_workspace.sh').read_text(encoding='utf-8')
    required_dev=(
        '(cd "$ROOT" && GXB_DATABASE_URL="$(admin_database_url)" "$py" tools/pass346_i7_migrate.py migrate',
        'db_backup()', 'legacy_normalize_sandbox()', 'player_export()', 'player_import()',
        'scratch_candidate()', 'prepare_latest_migration()',
    )
    missing=[marker for marker in required_dev if marker not in dev]
    if missing: raise SystemExit('PORTABLE PACKAGE: FAIL dev3 marker(s) missing '+repr(missing))
    if 'update_workspace()' not in helper or 'db-backup "pre-update-$stamp"' not in helper:
        raise SystemExit('PORTABLE PACKAGE: FAIL update transaction missing')
    if 'WRAPPER_VERSION="7"' not in helper or 'OTA_DIR="${GXB_OTA_HOME:-$RUNTIME_DIR/ota}"' not in helper:
        raise SystemExit('PORTABLE PACKAGE: FAIL persistent OTA wrapper v7 missing')
    # Historical Pass348 exact hashes remain immutable provenance, but later
    # stock-client reconciliation intentionally changes a bounded set of runtime
    # seams. Validate the current Pass351 seal instead of pretending those
    # authorized deltas never happened.
    subprocess.run([str(ROOT/'tools/verify_pass353_i10_invariants.py')],check=True)
    moved_json=len(list((ROOT/'docs/json').glob('PASS*.json')))
    moved_reports=len(list((ROOT/'docs/pass-reports').glob('PASS*')))
    print(f'PORTABLE PACKAGE: PASS current=pass353 root_pass=0 json={moved_json} reports={moved_reports}')

if __name__=='__main__': main()
