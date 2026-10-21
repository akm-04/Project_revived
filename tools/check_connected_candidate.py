#!/usr/bin/env python3
from __future__ import annotations
import argparse,re,shutil,subprocess,sys,tempfile
from pathlib import Path
sys.dont_write_bytecode=True
from candidate_identity import tree_identity, verify_snapshot_manifest
ROOT=Path(__file__).resolve().parents[1]

def fail(msg): print('CONNECTED CANDIDATE PRESEAL: FAIL\n - '+msg); raise SystemExit(1)
def run(cmd,cwd=ROOT,env=None):
    print('+',' '.join(cmd)); subprocess.run(cmd,cwd=cwd,env=env,check=True)
def tree_digest(root:Path):
    # Single canonical identity algorithm shared with handoff/PassMap generation.
    return str(tree_identity(root)["product_tree_digest_sha256"])

def static_checks():
    try:
        snap=verify_snapshot_manifest(ROOT)
    except RuntimeError as exc:
        fail(str(exc))
    ident=tree_identity(ROOT)
    print('CONNECTED CANDIDATE IDENTITY:', ident['algorithm'], ident['product_tree_digest_sha256'], 'files', ident['file_count_excluding_git'], 'snapshot_entries', snap['snapshot_entry_count'])
    gm=(ROOT/'go.mod').read_text()
    if 'go 1.26.0' not in gm: fail('W1-resolved module language floor go 1.26.0 missing')
    if 'toolchain go1.27.3' not in gm: fail('toolchain go1.27.3 pin missing')
    if not (ROOT/'go.sum').exists(): fail('go.sum missing')
    for mod in ('github.com/go-chi/chi/v5','github.com/jackc/pgx/v5','github.com/riverqueue/river'):
        if not re.search(rf'^{re.escape(mod)}\s+v[^\s]+\s+h1:',(ROOT/'go.sum').read_text(),re.M): fail(f'content checksum missing for {mod}')
    manifest=(ROOT/'internal/projection/lobby/manifest.go').read_text()
    if 'func NewBootTracker() *BootTracker' not in manifest: fail('NewBootTracker constructor missing')
    for mf in ('migrations/00003_identity_account_uid_repair.sql','migrations/00004_player_directory_profile_bootstrap.sql'):
        t=(ROOT/mf).read_text(); pos=0
        while True:
            d=t.find('DO $$',pos)
            if d<0: break
            sb=t.rfind('-- +goose StatementBegin',0,d); se=t.find('-- +goose StatementEnd',d)
            if sb<0 or se<0: fail(f'Goose DO block unbounded in {mf}')
            pos=se+1
    # All canonical SQL migrations are Goose-managed and forward-only.  Checking
    # only individual historical migrations allowed 00032 to be valid raw SQL but
    # unparsable by the canonical migration runner.  Enforce the envelope across
    # the entire current inventory so future migrations cannot bypass the gate.
    for migration in sorted((ROOT/'migrations').glob('*.sql')):
        text=migration.read_text()
        if not text.startswith('-- +goose Up\n'):
            fail(f'{migration.name} missing explicit leading Goose Up marker')
        if '-- +goose Down' in text:
            fail(f'{migration.name} violates forward-only production migration law')
    pkgs=set()
    for p in (ROOT/'internal/adapters/river').glob('*.go'):
        m=re.search(r'^package\s+(\w+)',p.read_text(),re.M)
        if m: pkgs.add(m.group(1))
    if pkgs!={'riveradapter'}: fail(f'River package mismatch: {sorted(pkgs)}')
    subprocess.run([sys.executable,str(ROOT/'tools/check_sqlc_generation_policy.py')],check=True)
    subprocess.run([sys.executable,str(ROOT/'tools/check_dependency_policy.py')],check=True)
    subprocess.run([sys.executable,str(ROOT/'tools/generate_resolved_sbom.py'),'--check'],check=True)
    print('CONNECTED CANDIDATE STATIC PRESEAL: PASS')

def execute_checks():
    tools={'go':'go','sqlc':'sqlc'}
    for n,c in tools.items():
        if shutil.which(c) is None: fail(f'{n} not found for --execute')
    gv=subprocess.check_output(['go','version'],text=True).strip()
    if 'go1.27.3 ' not in gv: fail('exact Go 1.27.3 required for --execute, got '+gv)
    sv=subprocess.check_output(['sqlc','version'],text=True).strip()
    if '1.31.1' not in sv: fail('exact sqlc 1.31.1 required, got '+sv)
    with tempfile.TemporaryDirectory(prefix='gxb-connected-preseal-') as td:
        td=Path(td); copy=td/'backend'; shutil.copytree(ROOT,copy,ignore=shutil.ignore_patterns('.git'))
        before_mod=(copy/'go.mod').read_bytes(); before_sum=(copy/'go.sum').read_bytes()
        run(['go','mod','tidy'],copy)
        if (copy/'go.mod').read_bytes()!=before_mod or (copy/'go.sum').read_bytes()!=before_sum: fail('go mod tidy dirties committed module closure')
        run(['go','mod','verify'],copy)
        run(['go','test','-tags','postgres','./...'],copy)
        # Release/source archives intentionally contain no VCS metadata.  Make the
        # executable gate hermetic instead of inheriting ambient Git/worktree state.
        run(['go','build','-buildvcs=false','-tags','postgres','./cmd/gxb-api'],copy)
        run(['go','build','-buildvcs=false','-tags','postgres','./cmd/gxb-realtime'],copy)
        run(['go','test','-tags','postgres river','./...'],copy)
        # sqlc output is intentionally a sibling build artifact; source-tree bytes must remain unchanged.
        generated=td/'gxb-v2-sqlc-generated'; shutil.rmtree(generated,ignore_errors=True)
        before=tree_digest(copy); run(['sqlc','generate'],copy); after=tree_digest(copy)
        if before!=after: fail('sqlc generate changed candidate source tree')
        if not (generated/'kerneldb').is_dir() or not (generated/'i3db').is_dir(): fail('sqlc generated build artifacts missing')
    print('CONNECTED CANDIDATE EXECUTABLE PRESEAL: PASS')

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--execute',action='store_true'); a=ap.parse_args(); static_checks();
    if a.execute: execute_checks()
if __name__=='__main__': main()
