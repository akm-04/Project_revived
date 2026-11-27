"""Retire clean, merged leaf worktrees of the canonical backend.

  worktree_gc.py                       dry run: list candidates and their total apparent size
  worktree_gc.py --explain             dry run, printing the reason for every registered tree
  worktree_gc.py --apply               remove the candidates with `git worktree remove` (never --force)

A tree is a candidate only when all hold:
  - it is a registered worktree under work/ at a branch (not detached, not canonical);
  - not the audit lane (backend_audit*, branch audit/*), an asset lane, or any path listed in
    WORKSPACE_LAYOUT.json (path values, preserved_work_dependencies, compatibility_links);
  - its branch tip is an ancestor of the canonical HEAD or of branch i11a;
  - `git status --porcelain` is empty;
  - its path is not mentioned in any work/LATEST_*_CHECKPOINT.json, work/REPAIR_LANE_SEQUENCE.md, or any
    *.manifest.json / *.prompt modified in the last 14 days under work/i11/;
  - no process has its working directory inside it;
  - its branch tip is older than --min-age-days (default 14).

The branch is always kept. Every removal appends one JSON line to logs/worktree-gc-<date>.jsonl
(path, branch, head, size_mb, containing canonical/i11a commit) so the checkout stays traceable.
"""
import argparse
import json
import os
import posixpath
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path

import worktree_index

REFERENCE_DAYS = 14
PROCESS_SCAN_ENABLED = True


class Context:
    def __init__(self, workspace, canonical, protected, preserved_names, references, cwds, min_age_days, now):
        self.workspace = workspace
        self.canonical = canonical
        self.protected = protected
        self.preserved_names = preserved_names
        self.references = references
        self.cwds = cwds
        self.min_age_days = min_age_days
        self.now = now


def _strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for key, item in value.items():
            yield key
            yield from _strings(item)
    elif isinstance(value, list):
        for item in value:
            yield from _strings(item)


def _normalize(text):
    text = text.strip().replace('\\', '/')
    if not text or '\n' in text:
        return None
    if text.startswith('./'):
        text = text[2:]
    normalized = posixpath.normpath(text)
    return None if normalized in ('.', '') else normalized


def layout_protection(workspace):
    """(paths, names) that WORKSPACE_LAYOUT.json pins: every path value plus preserved and compatibility names."""
    layout_path = workspace / 'WORKSPACE_LAYOUT.json'
    protected, preserved = set(), set()
    try:
        layout = json.loads(layout_path.read_text())
    except (OSError, ValueError):
        return protected, preserved
    for value in _strings(layout):
        normalized = _normalize(value)
        if normalized:
            protected.add(normalized)
    for key in layout.get('preserved_work_dependencies', {}):
        preserved.add(key)
        protected.add(posixpath.join('work', key))
    for link in layout.get('compatibility_links', []):
        for field in ('path', 'target'):
            normalized = _normalize(str(link.get(field, '')))
            if normalized:
                protected.add(normalized)
                preserved.add(posixpath.basename(normalized))
    return protected, preserved


def _reads(path):
    try:
        return path.read_bytes()
    except OSError:
        return b''


def reference_documents(workspace, days=REFERENCE_DAYS):
    """Documents a path mention in which pins it: lane checkpoint records, the repair sequence and recent stage inputs."""
    paths = sorted((workspace / 'work').glob('LATEST_*_CHECKPOINT.json'))
    repair_sequence = workspace / 'work' / 'REPAIR_LANE_SEQUENCE.md'
    if repair_sequence.is_file():
        paths.append(repair_sequence)
    stage = workspace / 'work' / 'i11'
    if stage.is_dir():
        cutoff = time.time() - days * 86400
        for candidate in stage.rglob('*'):
            if not candidate.is_file():
                continue
            if not (candidate.name.endswith('.manifest.json') or candidate.name.endswith('.prompt')):
                continue
            try:
                if candidate.stat().st_mtime >= cutoff:
                    paths.append(candidate)
            except OSError:
                continue
    return [(path.relative_to(workspace).as_posix(), _reads(path)) for path in paths]


def process_cwds():
    cwds = []
    try:
        entries = list(Path('/proc').iterdir())
    except OSError:
        return cwds
    for entry in entries:
        if not entry.name.isdigit():
            continue
        try:
            cwds.append(os.path.realpath(entry / 'cwd'))
        except OSError:
            continue
    return cwds


def build_context(workspace=None, min_age_days=14, reference_days=REFERENCE_DAYS):
    workspace = Path(workspace or worktree_index.workspace_root())
    protected, preserved = layout_protection(workspace)
    return Context(
        workspace=workspace,
        canonical=os.path.realpath(worktree_index.canonical_path(workspace)),
        protected=protected,
        preserved_names=preserved,
        references=reference_documents(workspace, reference_days),
        cwds=process_cwds() if PROCESS_SCAN_ENABLED else [],
        min_age_days=min_age_days,
        now=time.time(),
    )


def _absolute(context, record):
    path = Path(record['path'])
    return path if path.is_absolute() else context.workspace / path


def _protected(record, context):
    path = record['path']
    if posixpath.basename(path.rstrip('/')) in context.preserved_names:
        return True
    for pinned in context.protected:
        if path == pinned or path.startswith(pinned + '/') or pinned.startswith(path + '/'):
            return True
    return False


def _mention(record, context):
    absolute = str(_absolute(context, record))
    needles = {record['path'], absolute, posixpath.basename(record['path'].rstrip('/'))}
    for label, blob in context.references:
        for needle in needles:
            if needle.encode('utf-8') in blob:
                return label
    return None


def _cwd_inside(absolute, context):
    target = os.path.realpath(absolute)
    for cwd in context.cwds:
        if cwd == target or cwd.startswith(target + os.sep):
            return cwd
    return None


def exclusion_reason(record, context):
    """None when the record may be removed; otherwise one sentence saying why it is kept."""
    path = record['path']
    name = posixpath.basename(path.rstrip('/'))
    if not path.startswith('work/'):
        return 'outside work/'
    if os.path.realpath(_absolute(context, record)) == context.canonical:
        return 'canonical backend tree'
    if record['detached']:
        return 'detached HEAD (no branch)'
    if (record['lane'] == 'audit' or name.startswith('backend_audit') or path.startswith('work/audit/')
            or (record['branch'] or '').startswith('audit/')):
        return 'audit lane'
    if (record['lane'] == 'asset' or name.startswith(('backend_asset', 'asset_'))
            or path.startswith(('work/asset_recovery', 'work/asset_experimental'))):
        return 'asset lane'
    if _protected(record, context):
        return 'listed in WORKSPACE_LAYOUT.json'
    if not (record['merged_canonical'] or record['merged_i11a']):
        return 'branch not merged into canonical HEAD or i11a'
    if record['dirty_files'] is None:
        return 'git status could not be read'
    if record['dirty_files']:
        return f"dirty ({record['dirty_files']} changed paths)"
    mention = _mention(record, context)
    if mention:
        return f'referenced by {mention}'
    cwd = _cwd_inside(_absolute(context, record), context)
    if cwd:
        return f'a process working directory is inside ({cwd})'
    if record['head_epoch'] is None:
        return 'branch tip date unknown'
    age_days = (context.now - record['head_epoch']) / 86400
    if age_days < context.min_age_days:
        return f"branch tip newer than {context.min_age_days} days ({age_days:.0f}d)"
    return None


def candidates(records, context):
    eligible = []
    for record in records:
        if exclusion_reason(record, context) is None:
            eligible.append(record)
    return sorted(eligible, key=lambda record: (-(record['size_mb'] or 0), record['path']))


def ledger_entry(record, context, document):
    canonical_head = document['canonical']['head'] if record['merged_canonical'] else None
    i11a_head = document['canonical']['i11a_head'] if record['merged_i11a'] else None
    return {
        'removed_at': datetime.now().astimezone().isoformat(timespec='seconds'),
        'path': record['path'],
        'branch': record['branch'],
        'head': record['head'],
        'size_mb': record['size_mb'],
        'containing': {'canonical_head': canonical_head, 'i11a_head': i11a_head},
    }


def _print_candidate(record):
    print(f"  {record['size_mb'] if record['size_mb'] is not None else '?'} MB  {record['path']}  "
          f"{record['branch']}  {record['head_short']}  {record['lane']}/{record['phase']}")


def main(argv=None):
    parser = argparse.ArgumentParser(description='Retire clean, merged leaf worktrees (dry run by default).')
    parser.add_argument('--apply', action='store_true', help='actually run git worktree remove (never --force)')
    parser.add_argument('--dry-run', action='store_true', help='explicit dry run (the default)')
    parser.add_argument('--explain', action='store_true', help='print the reason every registered tree is kept')
    parser.add_argument('--min-age-days', type=int, default=14, help='minimum branch-tip age in days (default 14)')
    arguments = parser.parse_args(argv)

    workspace = worktree_index.workspace_root()
    document = worktree_index.scan(workspace, with_sizes=True)
    context = build_context(workspace, arguments.min_age_days)

    reasons = {record['path']: exclusion_reason(record, context) for record in document['worktrees']}
    if arguments.explain:
        for record in document['worktrees']:
            reason = reasons[record['path']]
            print(f"{'KEEP      ' if reason else 'CANDIDATE '}  {record['path']}  [{record['branch'] or 'detached'}]  "
                  f"{reason or 'eligible'}")

    eligible = [record for record in document['worktrees'] if reasons[record['path']] is None]
    eligible.sort(key=lambda record: (-(record['size_mb'] or 0), record['path']))
    total_mb = sum(record['size_mb'] or 0 for record in eligible)
    print(f"\n{len(eligible)} candidates, {total_mb} MB apparent")
    for record in eligible:
        _print_candidate(record)

    if not arguments.apply:
        print('dry run: nothing removed (pass --apply to remove)')
        return 0

    ledger_path = workspace / 'logs' / f'worktree-gc-{datetime.now().strftime("%Y-%m-%d")}.jsonl'
    ledger_path.parent.mkdir(parents=True, exist_ok=True)
    removed = failed = 0
    for record in eligible:
        absolute = str(_absolute(context, record))
        try:
            completed = subprocess.run(['git', '-C', str(worktree_index.canonical_path(workspace)),
                                        'worktree', 'remove', absolute], capture_output=True, text=True)
        except OSError as error:
            print(f'FAILED {record["path"]}: {error}')
            failed += 1
            continue
        if completed.returncode != 0:
            print(f'FAILED {record["path"]}: {completed.stderr.strip()}')
            failed += 1
            continue
        with ledger_path.open('a', encoding='utf-8') as ledger:
            ledger.write(json.dumps(ledger_entry(record, context, document)) + '\n')
        removed += 1
        print(f'removed {record["path"]} ({record["size_mb"]} MB)')
    print(f'removed {removed}, failed {failed}; ledger {ledger_path.relative_to(workspace).as_posix()}')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
