"""Index every registered git worktree of the canonical backend: work/INDEX.md and work/index.json.

  worktree_index.py            print a summary from a fresh git scan (no sizes)
  worktree_index.py --write    scan with apparent sizes and write work/INDEX.md and work/index.json
  worktree_index.py --check    exit 1 when either generated file is stale against a fresh scan (sizes ignored)

Administrative only: directory names and placement confer no authority; the sealed PassMap selects authority.
Facts come from git and du: `git worktree list --porcelain`, one `git log -1` and `git status --porcelain -z`
per tree, ancestor membership against the canonical HEAD and branch i11a, and `du --apparent-size -sm`.
"""
import argparse
import json
import os
import posixpath
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_WORKSPACE = Path(__file__).resolve().parents[1]
CANONICAL_RELATIVE = posixpath.join('work', 'backend_i7c4_full', 'backend')
INTEGRATION_BRANCH = 'i11a'
INDEX_MARKDOWN = 'INDEX.md'
INDEX_JSON = 'index.json'
FORMAT = 'GXB_WORK_INDEX_V1'
LANE_ORDER = ['canonical', 'phase', 'audit', 'asset', 'playtest', 'repair', 'gate', 'misc', 'scratch', 'external']

# Names the branch/path convention misses. Keys are branches (after stripping a leading "wip/").
BRANCH_OVERRIDES = {
    'i8-go1273': ('canonical', 'I8'),
    'audit-fable': ('audit', 'AUDIT'),
}

_PHASE = re.compile(r'^i(\d+)([a-z])?(\d+)?')


def workspace_root():
    return DEFAULT_WORKSPACE


def canonical_path(workspace):
    return workspace / CANONICAL_RELATIVE


def git(cwd, *arguments, timeout=300):
    """stdout of a git command, or None when it fails, times out or git is missing."""
    try:
        completed = subprocess.run(['git', '-C', str(cwd), *arguments], capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if completed.returncode != 0:
        return None
    return completed.stdout


def list_worktrees(canonical):
    output = git(canonical, 'worktree', 'list', '--porcelain')
    if output is None:
        raise RuntimeError(f'git worktree list failed in {canonical}')
    entries, current = [], {}
    for line in output.splitlines() + ['']:
        if not line:
            if current:
                entries.append(current)
                current = {}
            continue
        key, _, value = line.partition(' ')
        if key == 'worktree':
            current = {'path': value}
        elif key == 'HEAD':
            current['head'] = value
        elif key == 'branch':
            prefix = 'refs/heads/'
            current['branch'] = value[len(prefix):] if value.startswith(prefix) else value
        elif key == 'detached':
            current['detached'] = True
    return entries


def head_facts(path):
    output = git(path, 'log', '-1', '--format=%H%x00%h%x00%cI%x00%ct%x00%s')
    if output is None:
        return {}
    fields = output.rstrip('\n').split('\x00')
    if len(fields) < 5:
        return {}
    try:
        epoch = int(fields[3])
    except ValueError:
        epoch = None
    return {'head': fields[0], 'head_short': fields[1], 'head_date': fields[2],
            'head_epoch': epoch, 'subject': fields[4]}


def dirty_files(path):
    output = git(path, 'status', '--porcelain=v1', '-z')
    if output is None:
        return None
    return len([entry for entry in output.split('\x00') if entry])


def reachable_commits(canonical, reference):
    output = git(canonical, 'rev-list', reference)
    return set(output.split()) if output is not None else set()


def phase_from(text):
    if not text:
        return None
    stripped = text[4:] if text.startswith('wip/') else text
    match = _PHASE.match(stripped)
    if not match:
        return None
    major, letter, minor = match.groups()
    return f'I{major}{letter.upper() if letter else ""}{minor or ""}'


def classify(relative_path, branch, detached):
    """(lane, phase) from the branch and path prefix; BRANCH_OVERRIDES covers names the convention misses."""
    path = relative_path.replace(os.sep, '/')
    name = posixpath.basename(path.rstrip('/'))
    normalized_branch = (branch or '')
    normalized_branch = normalized_branch[4:] if normalized_branch.startswith('wip/') else normalized_branch

    if path == CANONICAL_RELATIVE:
        return 'canonical', phase_from(normalized_branch) or '-'
    if normalized_branch in BRANCH_OVERRIDES:
        return BRANCH_OVERRIDES[normalized_branch]
    if (normalized_branch.startswith(('audit/', 'audit-')) or name.startswith('backend_audit')
            or path.startswith('work/audit/')):
        return 'audit', 'AUDIT'
    if (name.startswith(('backend_asset', 'asset_')) or path.startswith('work/asset_recovery')
            or path.startswith('work/asset_experimental')):
        return 'asset', 'ASSET'
    if path.startswith('tmp/'):
        return 'scratch', '-'
    if not path.startswith('work/'):
        return 'external', '-'
    if name.startswith('backend_playtest') or normalized_branch.startswith('playtest'):
        return 'playtest', '-'
    if name.startswith('backend_repair') or normalized_branch.startswith('repair'):
        return 'repair', '-'
    if name.startswith('backend_gate') or normalized_branch.startswith('gate'):
        return 'gate', '-'
    phase = phase_from(normalized_branch) or phase_from(name)
    if phase:
        return 'phase', phase
    return 'misc', '-'


def display_path(workspace, absolute):
    candidate = Path(absolute)
    try:
        return candidate.relative_to(workspace).as_posix()
    except ValueError:
        return str(candidate)


def _du_batch(paths):
    try:
        completed = subprocess.run(['du', '--apparent-size', '-sm', '--', *paths],
                                   capture_output=True, text=True, timeout=600)
    except (OSError, subprocess.TimeoutExpired):
        return {}
    sizes = {}
    for line in completed.stdout.splitlines():
        size, _, path = line.partition('\t')
        try:
            sizes[path] = int(size)
        except ValueError:
            continue
    return sizes


def apparent_sizes(paths, workers=8, batch=32):
    batches = [paths[index:index + batch] for index in range(0, len(paths), batch)]
    sizes = {}
    with ThreadPoolExecutor(max_workers=workers) as pool:
        for partial in pool.map(_du_batch, batches):
            sizes.update(partial)
    return sizes


def _inspect(entry):
    path = Path(entry['path'])
    facts = head_facts(path)
    if not facts:
        head = entry.get('head', '')
        facts = {'head': head, 'head_short': head[:7], 'head_date': None, 'head_epoch': None, 'subject': None}
    facts['path'] = entry['path']
    facts['branch'] = entry.get('branch')
    facts['detached'] = 'branch' not in entry
    facts['dirty_files'] = dirty_files(path)
    return facts


def scan(workspace=None, with_sizes=True, git_workers=16, size_workers=8):
    workspace = Path(workspace or workspace_root())
    canonical = canonical_path(workspace)
    canonical_head = (git(canonical, 'rev-parse', 'HEAD') or '').strip()
    canonical_branch = (git(canonical, 'rev-parse', '--abbrev-ref', 'HEAD') or '').strip()
    i11a_head = (git(canonical, 'rev-parse', '--verify', INTEGRATION_BRANCH) or '').strip() or None
    canonical_commits = reachable_commits(canonical, 'HEAD')
    i11a_commits = reachable_commits(canonical, INTEGRATION_BRANCH) if i11a_head else set()

    listed = list_worktrees(canonical)
    with ThreadPoolExecutor(max_workers=git_workers) as pool:
        inspected = list(pool.map(_inspect, listed))

    records = []
    for item in inspected:
        relative = display_path(workspace, item['path'])
        head = item['head'] or ''
        lane, phase = classify(relative, item['branch'], item['detached'])
        records.append({
            'path': relative,
            'absolute': item['path'],
            'lane': lane,
            'phase': phase,
            'branch': item['branch'],
            'head': head,
            'head_short': item['head_short'],
            'head_date': item['head_date'],
            'head_epoch': item['head_epoch'],
            'subject': item['subject'],
            'detached': item['detached'],
            'merged_canonical': head in canonical_commits,
            'merged_i11a': head in i11a_commits,
            'dirty_files': item['dirty_files'],
            'size_mb': None,
        })

    if with_sizes:
        sizes = apparent_sizes([record['absolute'] for record in records], workers=size_workers)
        for record in records:
            record['size_mb'] = sizes.get(record['absolute'], 0)

    records.sort(key=lambda record: (LANE_ORDER.index(record['lane']) if record['lane'] in LANE_ORDER else len(LANE_ORDER),
                                     record['phase'], record['path']))
    document = {
        'format': FORMAT,
        'administrative': 'Not authority: directory names and placement confer none; the sealed PassMap selects authority.',
        'generated_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        'workspace': str(workspace),
        'canonical': {
            'path': CANONICAL_RELATIVE,
            'branch': canonical_branch,
            'head': canonical_head,
            'head_short': canonical_head[:7],
            'i11a_head': i11a_head,
            'i11a_head_short': (i11a_head or '')[:7],
        },
        'counts': counts(records),
        'worktrees': records,
    }
    return document


def counts(records):
    return {
        'total': len(records),
        'at_branch': sum(1 for record in records if not record['detached']),
        'detached': sum(1 for record in records if record['detached']),
        'merged_canonical': sum(1 for record in records if record['merged_canonical']),
        'merged_i11a': sum(1 for record in records if record['merged_i11a']),
        'dirty': sum(1 for record in records if record['dirty_files']),
        'apparent_mb': sum(record['size_mb'] or 0 for record in records),
        'lanes': {lane: sum(1 for record in records if record['lane'] == lane) for lane in LANE_ORDER
                  if any(record['lane'] == lane for record in records)},
    }


def _yes(value):
    return 'yes' if value else 'no'


def _cell(value):
    return str(value).replace('\n', ' ').replace('|', '\\|')


def render_markdown(document, include_sizes=True):
    canonical = document['canonical']
    found = document['counts']
    lines = [
        '# work/ index',
        '',
        'Administrative, not authority: directory placement confers none; the sealed PassMap selects authority.',
        'Generated by `ops/worktree_index.py --write`; do not edit. Machine-readable copy: `work/index.json`.',
        '',
        f"Generated: {document['generated_at']}",
        f"Canonical: `{canonical['path']}` @ `{canonical['head_short']}` ({canonical['branch']}); "
        f"`{INTEGRATION_BRANCH}` @ `{canonical['i11a_head_short'] or '-'}`",
        f"Worktrees: {found['total']} ({found['at_branch']} at a branch, {found['detached']} detached); "
        f"merged into canonical HEAD: {found['merged_canonical']}; into {INTEGRATION_BRANCH}: {found['merged_i11a']}; "
        f"dirty: {found['dirty']}"
        + (f"; apparent size: {found['apparent_mb']} MB" if include_sizes else ''),
        '',
        '| Lane | Phase | Path | Branch | HEAD | HEAD date | Subject | Detached | Merged canonical | Merged '
        f'{INTEGRATION_BRANCH} | Dirty | Size MB |',
        '|---|---|---|---|---|---|---|---|---|---|---|---|',
    ]
    for record in document['worktrees']:
        head_date = (record['head_date'] or '')[:10] or '-'
        size = str(record['size_mb']) if include_sizes and record['size_mb'] is not None else '-'
        cells = [
            record['lane'], record['phase'], f"`{record['path']}`", record['branch'] or '-',
            record['head_short'] or '-', head_date, record['subject'] or '-', _yes(record['detached']),
            _yes(record['merged_canonical']), _yes(record['merged_i11a']),
            str(record['dirty_files']) if record['dirty_files'] is not None else '?', size,
        ]
        lines.append('| ' + ' | '.join(_cell(cell) for cell in cells) + ' |')
    return '\n'.join(lines) + '\n'


def _mask(markdown):
    """Drop the generated line and the last table cell (the size), so staleness ignores time and sizes."""
    masked = []
    for line in markdown.splitlines():
        if line.startswith('Generated:'):
            continue
        line = re.sub(r'; apparent size: \d+ MB', '', line)
        if line.startswith('|'):
            cells = line.split('|')
            if len(cells) >= 4:
                del cells[-2]
                line = '|'.join(cells)
        masked.append(line)
    return '\n'.join(masked)


def _comparable(document):
    canonical = {key: document.get('canonical', {}).get(key) for key in ('path', 'branch', 'head', 'i11a_head')}
    records = sorted(tuple(sorted((key, value) for key, value in record.items() if key != 'size_mb'))
                     for record in document.get('worktrees', []))
    return canonical, records


def stale(workspace, document):
    markdown_path = workspace / 'work' / INDEX_MARKDOWN
    json_path = workspace / 'work' / INDEX_JSON
    missing = [path.name for path in (markdown_path, json_path) if not path.is_file()]
    if missing:
        return [f"missing work/{name}" for name in missing]
    try:
        stored = json.loads(json_path.read_text())
    except (OSError, ValueError):
        return [f'work/{INDEX_JSON} is unreadable']
    if _comparable(stored) != _comparable(document):
        return [f'work/{INDEX_JSON} differs from a fresh scan (sizes ignored)']
    if _mask(markdown_path.read_text()) != _mask(render_markdown(document, include_sizes=False)):
        return [f'work/{INDEX_MARKDOWN} differs from a fresh scan (sizes ignored)']
    return []


def write(workspace, document):
    work = workspace / 'work'
    (work / INDEX_JSON).write_text(json.dumps(document, indent=2, ensure_ascii=False) + '\n')
    (work / INDEX_MARKDOWN).write_text(render_markdown(document))


def summary(document):
    canonical = document['canonical']
    found = document['counts']
    lanes = ', '.join(f'{lane} {count}' for lane, count in found['lanes'].items())
    return (f"canonical {canonical['path']} @ {canonical['head_short']} ({canonical['branch']}); "
            f"{INTEGRATION_BRANCH} @ {canonical['i11a_head_short'] or '-'}\n"
            f"worktrees {found['total']} ({found['at_branch']} at a branch, {found['detached']} detached); "
            f"merged canonical {found['merged_canonical']}, merged {INTEGRATION_BRANCH} {found['merged_i11a']}, "
            f"dirty {found['dirty']}" + (f", {found['apparent_mb']} MB apparent" if document['worktrees'] and
                                         document['worktrees'][0]['size_mb'] is not None else '') + '\n'
            f"lanes: {lanes}")


def main(argv=None):
    parser = argparse.ArgumentParser(description='Index the canonical backend worktrees.')
    parser.add_argument('--write', action='store_true', help='write work/INDEX.md and work/index.json')
    parser.add_argument('--check', action='store_true', help='exit 1 when the generated files are stale')
    arguments = parser.parse_args(argv)
    workspace = workspace_root()
    document = scan(workspace, with_sizes=arguments.write)
    if arguments.write:
        write(workspace, document)
    problems = stale(workspace, document) if arguments.check else []
    print(summary(document))
    if arguments.write:
        print(f'wrote work/{INDEX_MARKDOWN} and work/{INDEX_JSON}')
    if problems:
        print('STALE: ' + '; '.join(problems))
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
