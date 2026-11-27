"""Cumulative, restore-tested working checkpoint of the current phase workspace (any phase; nothing hard-coded).

  checkpoint.py <rNN-slug>
  checkpoint.py <tag> --lane <name>  a side lane from ops/state.py LANES (audit, asset-recovery, asset-experimental): packs that lane's
                                     workspace into checkpoints/active/<NODE>, record work/LATEST_<NODE>_CHECKPOINT.json;
                                     the phase checkpoint is untouched
  checkpoint.py <aNN-slug> --audit   same as --lane audit (the independent auditor's lane)
A tag is a letter prefix, a number and an optional slug (r397-asset-catalogue, ar01-catalogue); anything else is refused.

Refreshes the generated layout facts (ops/state.py --write), writes <phase workspace>/CHECKPOINT_BINDING.json from them,
packs the phase workspace + ops/ + work/workspace_tools + the layout files over the latest sealed PassMap zip, restores it
into a scratch copy, records work/LATEST_<PHASE>_CHECKPOINT.json and rotates checkpoints/active/<PHASE>.
Unsealed backend commits live only in the canonical repository's .git, which every worktree shares, so each checkpoint
also writes <checkpoint>.bundle (every ref not in the sealed backend head; audit A-011), verifies it and records its
sha256. Restore: `git -C <backend> fetch <bundle> 'refs/*:refs/*'`.
Working recovery only: never authority, acceptance or a gate.
"""
import hashlib
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

W = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(W / 'work/workspace_tools'))
sys.path.insert(0, str(W / 'ops'))
from checkpoint_layout import checkpoint_paths, rotate
import state


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def run(args):
    result = subprocess.run([str(a) for a in args], text=True, capture_output=True)
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)


def backend_bundle(out, sealed_head):
    repository = W / 'work/backend_i7c4_full/backend'
    bundle = out.with_suffix('.bundle')
    subprocess.run(['git', '-C', repository, 'bundle', 'create', bundle, '--all', '--not', sealed_head], check=True, capture_output=True)
    subprocess.run(['git', '-C', repository, 'bundle', 'verify', bundle], check=True, capture_output=True)
    return dict(path=str(bundle.relative_to(W)), sha256=sha(bundle), excludes=sealed_head,
                restore=f"git -C work/backend_i7c4_full/backend fetch {bundle.relative_to(W)} 'refs/*:refs/*'")


def sealed_base(facts):
    """(generation, zip) of the finished seal a checkpoint restores from; a newer zip without a completion record is
    UNSEALED and never becomes the base (PROVENANCE_AND_COVERAGE_V1)."""
    generation, sealed_zip = facts['passmap']['sealed_generation'], facts['passmap']['sealed_zip']
    if not generation or not sealed_zip or not (W / sealed_zip).is_file():
        sys.exit('checkpoint refused: no finished seal (a zip without a completion record is UNSEALED)')
    return generation, W / sealed_zip


def binding(tag, facts, parent):
    _, sealed_zip = sealed_base(facts)
    return dict(
        schema_version=2, checkpoint_id=tag, role='WORKING_RECOVERY_NOT_AUTHORITY',
        rule='Does not supersede sealed authority, accept a candidate, authorize a node or satisfy a gate; reconcile at the next normal seal.',
        lineage=dict(parent_checkpoint=parent.get('checkpoint_id'), parent_sha256=parent.get('sha256')),
        facts=facts, sealed_zip_sha256=sha(sealed_zip),
        toolchain_manifest_sha256=sha(W / '.toolchain/TOOLCHAIN_MANIFEST.json'))


TAG = re.compile(r'[a-z]+\d+(?:-[a-z0-9]+)*')


def arguments(argv):
    """(tag, lane name or None); refuses before anything is written, so a mistyped flag never becomes a checkpoint."""
    if len(argv) < 2 or argv[1] in ('-h', '--help'):
        sys.exit(__doc__)
    tag, options = argv[1], argv[2:]
    if not TAG.fullmatch(tag):
        sys.exit(f'checkpoint refused: tag {tag!r} is not <letters><number>[-slug]')
    if options == ['--audit']:
        return tag, 'audit'
    if len(options) == 2 and options[0] == '--lane' and options[1] in state.LANES:
        return tag, options[1]
    if options:
        sys.exit(f'checkpoint refused: unknown options {options}; lanes: {sorted(state.LANES)}')
    return tag, None


if __name__ == '__main__':
    tag, lane = arguments(sys.argv)
    subprocess.run([sys.executable, '-B', str(W / 'ops/state.py'), '--write'], check=True, stdout=subprocess.DEVNULL)
    facts = state.facts()
    phase, phase_dir = facts['phase_workspace']['phase'], W / facts['phase_workspace']['path']
    record = W / facts['checkpoint']['record']
    if lane:
        # A side lane packs its own workspace and never touches the phase record or binding.
        phase, lane_path = state.LANES[lane]
        phase_dir, record = W / lane_path, W / f'work/LATEST_{phase}_CHECKPOINT.json'
    parent = json.loads(record.read_text()) if record.is_file() else {}
    (phase_dir / 'CHECKPOINT_BINDING.json').write_text(json.dumps(binding(tag, facts, parent), indent=1) + '\n')
    out, staging = checkpoint_paths(W, phase, tag)
    assert not staging.exists() and not out.exists(), 'checkpoint tag already used'
    layout = staging / 'layout'
    layout.mkdir(parents=True)
    for name in ['WORKSPACE_LAYOUT.json', 'CLAUDE.md', 'START_HERE.md']:
        shutil.copy2(W / name, layout / name)
    root_name = phase_dir.name.replace('-', '')
    shutil.copytree(phase_dir, staging / root_name, ignore=shutil.ignore_patterns('__pycache__', '*.pyc'))
    sealed_generation, sealed_zip = sealed_base(facts)
    base = W / f"work/authority_p{sealed_generation}"
    tool = W / 'ops/checkpoint_archive.py'
    roots = {root_name: staging / root_name, 'ops': W / 'ops', 'workspace_tools': W / 'work/workspace_tools', 'layout': layout}
    args = [sys.executable, tool, '--base', base, '--base-archive', sealed_zip]
    for name, path in roots.items():
        args += ['--root', f'{name}={path}']
    verification = run(args + ['--rules-file', W / 'RULES.md', '--rules-file', W / 'work/RULINGS.md', '--output', out])
    restored = staging.parent / (tag + '-restored')
    verification.update(restore=run([sys.executable, tool, '--base', base, '--restore', out, '--destination', restored]),
                        checkpoint_id=tag, base_pass=f"{sealed_generation}.0",
                        restore_roots={root_name: 'work/' + phase_dir.name, 'ops': 'ops', 'workspace_tools': 'work/workspace_tools', 'layout': '.'},
                        status='CRC_NEW_OBJECT_HASH_ALL_LOGICAL_FILES_RESTORE_PASS')
    verification['backend_bundle'] = backend_bundle(out, facts['backend']['head'])
    record.write_text(json.dumps(verification, indent=2) + '\n')
    out.with_suffix('.sha256').write_text(verification['sha256'] + '  ' + out.name + '\n')
    out.with_suffix('.verification.json').write_text(json.dumps(verification, indent=2) + '\n')
    verification['retention'] = rotate(W, phase)
    shutil.rmtree(staging)
    shutil.rmtree(restored)
    subprocess.run([sys.executable, '-B', str(W / 'ops/state.py'), '--write'], check=True, stdout=subprocess.DEVNULL)
    print(json.dumps({k: verification[k] for k in ['checkpoint_id', 'path', 'sha256', 'status', 'retention']}, indent=2))
