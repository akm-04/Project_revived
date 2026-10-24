"""Where the workspace stands, derived from disk facts only: phase workspace, sealed PassMap, backend checkout, checkpoint, tools.

  state.py           print the status (read this first in a new session)
  state.py --write   regenerate every copy of these facts: WORKSPACE_LAYOUT.json "current" and the live "paths" keys, the
                     generated blocks of CLAUDE.md and START_HERE.md, hard links of the latest PassMap zip in
                     inputs/memory_bank and of the newest sealed backend pair (ops/package_backend.sh) in inputs/backend
  state.py --check   exit 1 when any copy is stale (ops/seal_passmap.sh and ops/checkpoint.py run it)

Administrative only: the sealed PassMap selects authority (v2: hot/records/frontier.json; v1 up to 763:
CANONICAL_CURRENT_STATE); this mirrors it.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

W = Path(__file__).resolve().parents[1]
LAYOUT = W / 'WORKSPACE_LAYOUT.json'
TESTING_PATHS = {
    'test_runtime': 'tmp/test-databases/i853_dev (PostgreSQL dev cluster, port 55853, user postgres; ops/TESTING_GUIDE.md section 0)',
    'testing_guide': 'ops/TESTING_GUIDE.md (test layers, closure rule D72) with run scripts in ops/testing',
    'virtual_client': 'backend virtualclient/ (nested Go module); runtime inputs, binaries and runs in tmp/virtualclient',
    'android_emulator': 'tmp/android (SDK, AVD gxb30, APK build, run logs); ops/testing/emulator_smoke.sh',
    'recovery_guide': 'inputs/RECOVERY.md (rebuild from inputs/ and checkpoints/ alone)',
    'backend_archives': 'inputs/backend (hard links of the sealed backend zips, with and without Git)',
    'debug_tools': 'inputs/tools (r4 toolchain, virtual client kit, Android emulator bundle)',
    'client_baseline': 'inputs/client_baseline (unmodified base.apk apktool decode + plaintext Lua zips; work/client_baseline is its working copy)',
    'supplemental_v1_repo': 'inputs/Supplimental_Materials/gxb_workshop: main = v1 Flask backend, app_repack, decompiled src; branch v2 (v2 only, own root) = v2 backend with history under backend/, app_repack/patch_game_v2.sh + origin_lua/, split tools (tools/assemble.sh)',
}
BACKEND = W / 'work/backend_i7c4_full/backend'
DELTAS = W / 'work/i7c4c'
MEMORY_BANK = W / 'inputs/memory_bank'
BACKEND_INPUTS = W / 'inputs/backend'
BACKEND_ARCHIVE = r'gxb-backend-v2-.+-p(\d+)-[0-9a-f]{7}-(?:frozen-candidate|working-with-git)\.zip'
BEGIN, END = '<!-- ops/state.py:begin -->', '<!-- ops/state.py:end -->'


def generation_of(path, pattern):
    match = re.fullmatch(pattern, path.name)
    return int(match.group(1)) if match else None


def phase_of(path):
    """(major, minor) of a phase workspace: i8 -> (8, 0), i8_5 (an inserted phase such as I8.5) -> (8, 5)."""
    match = re.fullmatch(r'i(\d+)(?:_(\d+))?', path.name)
    return (int(match.group(1)), int(match.group(2) or 0)) if match else None


def latest(paths, pattern):
    found = sorted((generation_of(p, pattern), p) for p in paths if generation_of(p, pattern) is not None)
    return found[-1] if found else (None, None)


def git(*args):
    return subprocess.check_output(['git', *args], cwd=BACKEND, text=True).strip()


def sealed_authority():
    """(generation, authority facts) of the newest seal: a v2 package verification in outputs/ or a v1 authority delta."""
    version_two, verification = latest(W.glob('outputs/gxb-backend-pass-*.0-passmap.verification.json'),
                                       r'gxb-backend-pass-(\d+)\.0-passmap\.verification\.json')
    version_one, delta = latest(DELTAS.glob('*_AUTHORITY_*_DELTA.json'), r'[A-Z0-9]+_AUTHORITY_(\d+)_DELTA\.json')
    if version_two and (version_one is None or version_two > version_one):
        records = W / f'work/authority_p{version_two}/hot/records'
        frontier = json.loads((records / 'frontier.json').read_text())
        backend = json.loads((records / 'backend.json').read_text())
        stage_shard = json.loads((records.parent / 'ROUTES.json').read_text())['nodes'][frontier['stage']]
        stage_status = json.loads((records.parent / stage_shard).read_text())['nodes'][frontier['stage']]['status']
        return version_two, dict(
            delta=None, restore=f'.toolchain/bin/python3 -B work/authority_p{version_two}/hot/tools/passmap_maintain.py restore '
                                f'--bundle outputs/gxb-backend-pass-{version_two}.0-passmap.zip --destination <dir>',
            frontier=dict(pass_id=f'{version_two}.0', node=frontier['node'], stage=frontier['stage'], step=frontier['step'],
                          status=f"{frontier['stage']} {stage_status}", next_action=frontier['next_action']),
            working_archive=None, working_head=backend['head'])
    state = json.loads((W / f'work/authority_p{version_one}/hot/00_PASSMAP/CANONICAL_CURRENT_STATE.json').read_text())
    lifecycle = state['phase_lifecycle']
    working = state['artifacts']['backend_latest_working']
    return version_one, dict(
        delta=rel(delta), restore=f'.toolchain/bin/python3 -B work/i7c4c/scripts/restore_full4_authority.py --base-authority work/authority_p724 --work work/i7c4c --destination <dir> --metadata {delta.name}',
        frontier=dict(pass_id=state['pass'], node=lifecycle['current_node'], stage=lifecycle['current_internal_stage'], step=lifecycle['current_step'],
                      status=state['status'], next_action=state['next_action']),
        working_archive=working.get('archive') or working.get('artifact'), working_head=working.get('git_head') or working.get('git', {}).get('working_head'))


def facts():
    sealed, authority_facts = sealed_authority()
    prepared, _ = latest(W.glob('work/authority_p*'), r'authority_p(\d+)')
    zipped, zip_path = latest(W.glob('outputs/gxb-backend-pass-*.0-passmap.zip'), r'gxb-backend-pass-(\d+)\.0-passmap\.zip')
    authority = W / f'work/authority_p{sealed}'
    phase_number, phase_dir = max((phase_of(p), p) for p in W.glob('work/i*') if p.is_dir() and phase_of(p))
    phase = 'I' + '_'.join(str(part) for part in phase_number if part)
    checkpoint_record = W / f'work/LATEST_{phase}_CHECKPOINT.json'
    checkpoint = json.loads(checkpoint_record.read_text()) if checkpoint_record.is_file() else {}
    migrations = sorted(p.name for p in (BACKEND / 'migrations').glob('*.sql'))
    return dict(
        rule='Generated by ops/state.py --write from disk facts; never edit by hand. The sealed PassMap selects authority.',
        phase_workspace=dict(phase=phase, path=rel(phase_dir), handoff=rel(phase_dir / 'START_HERE.md'), scripts=rel(phase_dir / 'scripts')),
        passmap=dict(sealed_generation=sealed, sealed_authority=rel(authority),
                     sealed_delta=authority_facts['delta'], restore=authority_facts['restore'],
                     latest_zip=rel(zip_path) if zip_path else None, latest_zip_generation=zipped,
                     zip_is_current=zipped == sealed, prepared_unsealed=rel(W / f'work/authority_p{prepared}') if prepared and prepared > sealed else None),
        frontier=authority_facts['frontier'],
        backend=dict(path=rel(BACKEND), head=git('rev-parse', 'HEAD'), branch=git('rev-parse', '--abbrev-ref', 'HEAD'), clean=not git('status', '--porcelain'),
                     version=(BACKEND / 'VERSION').read_text().strip(), migration_high_water=migrations[-1],
                     sealed_working_archive=authority_facts['working_archive'], sealed_working_head=authority_facts['working_head']),
        checkpoint=dict(record=rel(checkpoint_record), id=checkpoint.get('checkpoint_id'), path=rel(Path(checkpoint['path'])) if checkpoint.get('path') else None,
                        sha256=checkpoint.get('sha256'), command=f'.toolchain/bin/python3 -B ops/checkpoint.py <rNN-slug>'),
        tools=dict(toolchain=rel(Path(os.path.realpath(W / '.toolchain'))), python='.toolchain/bin/python3', seal='ops/seal_passmap.sh <generation> <phase>'))


def rel(path):
    return str(Path(path).relative_to(W))


def summary(f):
    p, b, c, fr = f['passmap'], f['backend'], f['checkpoint'], f['frontier']
    dirty = '' if b['clean'] else ' (DIRTY)'
    unsealed = f"; prepared but unsealed: {p['prepared_unsealed']}" if p['prepared_unsealed'] else ''
    zip_note = p['latest_zip'] if p['zip_is_current'] else f"{p['latest_zip']} (older than the sealed generation)"
    return '\n'.join([
        f"Phase workspace: {f['phase_workspace']['path']} (handoff {f['phase_workspace']['handoff']}).",
        f"Sealed PassMap: owned {p['sealed_generation']} at {p['sealed_authority']}; frontier {fr['node']}/{fr['stage']}/{fr['step']}, status {fr['status']}{unsealed}.",
        f"Latest sealed PassMap zip: {zip_note}.",
        f"Backend: {b['path']} {b['branch']} {b['head'][:7]}{dirty}, {b['version']}, migration {b['migration_high_water'][:5]}.",
        f"Latest checkpoint: {c['id']} {c['sha256']}." if c['id'] else 'Latest checkpoint: none for this phase yet.',
        f"Tools: {f['tools']['python']}; seal with {f['tools']['seal']}; checkpoint with {c['command']}; status with .toolchain/bin/python3 -B ops/state.py.",
    ])


def block(text, f):
    generated = f'{BEGIN}\n{summary(f)}\n{END}'
    if BEGIN in text:
        return re.sub(re.escape(BEGIN) + '.*?' + re.escape(END), lambda _: generated, text, flags=re.S)
    return text.rstrip('\n') + '\n\n' + generated + '\n'


def targets(f):
    layout = json.loads(LAYOUT.read_text())
    layout['current'] = f
    layout['paths'].update(current_handoff=f['phase_workspace']['handoff'], working_backend=f['backend']['path'], **TESTING_PATHS)
    if f['passmap']['latest_zip']:
        layout['paths'].update(sealed_passmap=f['passmap']['latest_zip'], authority_work_base=f'work/authority_p{f["passmap"]["latest_zip_generation"]}')
    out = {LAYOUT: json.dumps(layout, indent=2, ensure_ascii=False) + '\n'}
    for name in ['CLAUDE.md', 'START_HERE.md']:
        out[W / name] = block((W / name).read_text(), f)
    return out


def wanted_links(f):
    """inputs/ copies of the newest sealed outputs: hard links, so a backup of inputs/ holds the bytes and survives a lost outputs/."""
    wanted = {MEMORY_BANK: [W / f['passmap']['latest_zip']] if f['passmap']['zip_is_current'] else []}
    archives = [(generation_of(p, BACKEND_ARCHIVE), p) for p in W.glob('outputs/gxb-backend-v2-*.zip') if generation_of(p, BACKEND_ARCHIVE) is not None]
    newest = max((generation for generation, _ in archives), default=None)
    wanted[BACKEND_INPUTS] = sorted(p for generation, p in archives if generation == newest)
    return wanted


def managed_links(directory):
    """Symlinks (the pre-769 form) and hard links of an outputs/ file; real supplied archives such as the pinned 724 base stay."""
    def linked(p):
        source = W / 'outputs' / p.name
        return p.is_symlink() or (source.is_file() and os.path.samefile(p, source))
    return [p for p in directory.glob('gxb-backend-*.zip') if linked(p)]


def stale(f):
    found = [rel(p) for p, text in targets(f).items() if p.read_text() != text]
    for directory, sources in wanted_links(f).items():
        current = sorted(p.name for p in managed_links(directory) if not p.is_symlink())
        if current != sorted(source.name for source in sources) or any((directory / s.name).is_symlink() for s in sources):
            found.append(rel(directory) + ' links')
    return found


def write(f):
    for p, text in targets(f).items():
        p.write_text(text)
    for directory, sources in wanted_links(f).items():
        for p in managed_links(directory):
            p.unlink()
        for source in sources:
            destination = directory / source.name
            destination.unlink(missing_ok=True)
            os.link(source, destination)


if __name__ == '__main__':
    current = facts()
    mode = sys.argv[1] if len(sys.argv) > 1 else ''
    if mode == '--write':
        write(current)
    problems = stale(current)
    print(summary(current))
    if problems:
        print('STALE: ' + ', '.join(problems))
    sys.exit(1 if mode in ('--check', '--write') and problems else 0)
