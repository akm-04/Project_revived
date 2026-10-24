"""Cumulative, restore-tested working checkpoint of the current phase workspace (any phase; nothing hard-coded).

  checkpoint.py <rNN-slug>

Refreshes the generated layout facts (ops/state.py --write), writes <phase workspace>/CHECKPOINT_BINDING.json from them,
packs the phase workspace + ops/ + work/workspace_tools + the layout files over the latest sealed PassMap zip, restores it
into a scratch copy, records work/LATEST_<PHASE>_CHECKPOINT.json and rotates checkpoints/active/<PHASE>.
Working recovery only: never authority, acceptance or a gate.
"""
import hashlib
import json
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


def binding(tag, facts, parent):
    return dict(
        schema_version=2, checkpoint_id=tag, role='WORKING_RECOVERY_NOT_AUTHORITY',
        rule='Does not supersede sealed authority, accept a candidate, authorize a node or satisfy a gate; reconcile at the next normal seal.',
        lineage=dict(parent_checkpoint=parent.get('checkpoint_id'), parent_sha256=parent.get('sha256')),
        facts=facts, sealed_zip_sha256=sha(W / facts['passmap']['latest_zip']),
        toolchain_manifest_sha256=sha(W / '.toolchain/TOOLCHAIN_MANIFEST.json'))


if __name__ == '__main__':
    tag = sys.argv[1]
    subprocess.run([sys.executable, '-B', str(W / 'ops/state.py'), '--write'], check=True, stdout=subprocess.DEVNULL)
    facts = state.facts()
    phase, phase_dir = facts['phase_workspace']['phase'], W / facts['phase_workspace']['path']
    record = W / facts['checkpoint']['record']
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
    base = W / f"work/authority_p{facts['passmap']['latest_zip_generation']}"
    tool = W / 'ops/checkpoint_archive.py'
    roots = {root_name: staging / root_name, 'ops': W / 'ops', 'workspace_tools': W / 'work/workspace_tools', 'layout': layout}
    args = [sys.executable, tool, '--base', base, '--base-archive', W / facts['passmap']['latest_zip']]
    for name, path in roots.items():
        args += ['--root', f'{name}={path}']
    verification = run(args + ['--rules-file', W / 'PROJECT_AGENT_RULES.md', '--output', out])
    restored = staging.parent / (tag + '-restored')
    verification.update(restore=run([sys.executable, tool, '--base', base, '--restore', out, '--destination', restored]),
                        checkpoint_id=tag, base_pass=f"{facts['passmap']['latest_zip_generation']}.0",
                        restore_roots={root_name: 'work/' + phase_dir.name, 'ops': 'ops', 'workspace_tools': 'work/workspace_tools', 'layout': '.'},
                        status='CRC_NEW_OBJECT_HASH_ALL_LOGICAL_FILES_RESTORE_PASS')
    record.write_text(json.dumps(verification, indent=2) + '\n')
    out.with_suffix('.sha256').write_text(verification['sha256'] + '  ' + out.name + '\n')
    out.with_suffix('.verification.json').write_text(json.dumps(verification, indent=2) + '\n')
    verification['retention'] = rotate(W, phase)
    shutil.rmtree(staging)
    shutil.rmtree(restored)
    subprocess.run([sys.executable, '-B', str(W / 'ops/state.py'), '--write'], check=True, stdout=subprocess.DEVNULL)
    print(json.dumps({k: verification[k] for k in ['checkpoint_id', 'path', 'sha256', 'status', 'retention']}, indent=2))
