#!/usr/bin/env python3
"""Cumulative work checkpoint archive bound to a sealed PassMap base (v1 or v2 layout).

  create:  --base <authority> --base-archive <zip> --root label=<dir> ... --rules-file PROJECT_AGENT_RULES.md --output <zip>
  restore: --base <restored authority> --restore <checkpoint.zip> --destination <new dir>

A work file whose bytes already exist in the base HOT or COLD is stored as a reference; every other file is stored once by
sha256. The base is identified by its hot and cold FILE_MANIFEST.sha256 digests, which both layouts carry.
"""
from pathlib import Path, PurePosixPath
import argparse, hashlib, json, shutil, tempfile, zipfile


def sha(path):
    with Path(path).open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest()


def safe(root, name):
    path = PurePosixPath(name)
    if not name or path.is_absolute() or '..' in path.parts or '\\' in name or str(path) != name:
        raise ValueError(f'unsafe path {name!r}')
    return Path(root) / name


def base_identity(base):
    generation_record = base / 'hot/GENERATION.json'
    generation = json.loads(generation_record.read_text())['generation'] if generation_record.is_file() else None
    return dict(generation=generation, hot_manifest_sha256=sha(base / 'hot/FILE_MANIFEST.sha256'),
                cold_manifest_sha256=sha(base / 'cold/FILE_MANIFEST.sha256'))


def base_index(base):
    index = {}
    for tier in ('hot', 'cold'):
        for line in (base / tier / 'FILE_MANIFEST.sha256').read_text().splitlines():
            digest, name = line.split('  ', 1)
            index.setdefault(digest, dict(tier=tier, path=name))
    return index


def work_files(roots):
    labels = set()
    for argument in roots:
        label, raw = argument.split('=', 1)
        if not label or '/' in label or label in ('.', '..') or label in labels:
            raise ValueError('invalid or duplicate root label')
        labels.add(label)
        root = Path(raw).resolve()
        if not root.is_dir():
            raise ValueError(f'root missing {root}')
        for path in sorted(root.rglob('*')):
            if path.is_symlink():
                raise ValueError(f'symlink in work input {path}')
            skipped = '.git' in path.relative_to(root).parts or '__pycache__' in path.parts or path.suffix in ('.pyc', '.pyo')
            if path.is_file() and not skipped:
                yield label + '/' + path.relative_to(root).as_posix(), path


def create(base, archive, roots, output, rules):
    if output.exists():
        raise ValueError('output exists')
    if not rules.is_file():
        raise ValueError('canonical rules file required')
    identity = dict(base_identity(base), archive=dict(filename=archive.name, sha256=sha(archive), bytes=archive.stat().st_size,
                                                      role='REQUIRED_EXTERNAL_RETAINED_SEALED_BASE'))
    index = base_index(base)
    files, objects = [], {}
    for name, path in [*work_files(roots), ('PROJECT_AGENT_RULES.md', rules)]:
        digest = sha(path)
        row = dict(path=name, sha256=digest, bytes=path.stat().st_size, mode=path.stat().st_mode & 0o777)
        reference = index.get(digest)
        if reference and sha(base / reference['tier'] / reference['path']) == digest:
            row['base_ref'] = reference
        else:
            objects.setdefault(digest, path)
        files.append(row)
    manifest = dict(format='GXB_CUMULATIVE_WORK_CHECKPOINT_V2', role='RECOVERY_NOT_NEW_ACCEPTANCE', base=identity, files=files,
                    object_count=len(objects), logical_bytes=sum(row['bytes'] for row in files),
                    base_reused_bytes=sum(row['bytes'] for row in files if 'base_ref' in row))
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
        bundle.writestr('CHECKPOINT.json', json.dumps(manifest, separators=(',', ':')) + '\n')
        bundle.writestr('START_HERE.txt', 'Restore the retained base PassMap first, then: python3 ops/checkpoint_archive.py --base <authority> '
                                          '--restore <this.zip> --destination <new dir>. No earlier checkpoint chain is needed.\n')
        for digest, path in sorted(objects.items()):
            bundle.write(path, 'objects/' + digest)
    with zipfile.ZipFile(output) as bundle:
        if bundle.testzip() is not None:
            raise ValueError('checkpoint CRC')
        for digest in objects:
            if hashlib.sha256(bundle.read('objects/' + digest)).hexdigest() != digest:
                raise ValueError(f'object {digest} unreadable')
    return dict(status='PASS_CRC_ALL_NEW_OBJECT_SHA256', path=str(output), sha256=sha(output), bytes=output.stat().st_size,
                logical_files=len(files), new_objects=len(objects), logical_bytes=manifest['logical_bytes'],
                base_reused_bytes=manifest['base_reused_bytes'])


def restore(base, archive, destination):
    if destination.exists():
        raise ValueError('destination exists')
    with zipfile.ZipFile(archive) as bundle:
        if bundle.testzip() is not None:
            raise ValueError('checkpoint CRC')
        manifest = json.loads(bundle.read('CHECKPOINT.json'))
        identity = base_identity(base)
        for key in ('generation', 'hot_manifest_sha256', 'cold_manifest_sha256'):
            if manifest['base'][key] != identity[key]:
                raise ValueError(f'wrong retained base {key}')
        names = [row['path'] for row in manifest['files']]
        if len(names) != len(set(names)):
            raise ValueError('duplicate work path')
        expected = {'objects/' + row['sha256'] for row in manifest['files'] if 'base_ref' not in row}
        if set(bundle.namelist()) != expected | {'CHECKPOINT.json', 'START_HERE.txt'}:
            raise ValueError('checkpoint object set')
        destination.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix='gxb-work-restore-', dir=destination.parent) as scratch:
            root = Path(scratch) / 'work'
            root.mkdir()
            for row in manifest['files']:
                target = safe(root, row['path'])
                target.parent.mkdir(parents=True, exist_ok=True)
                reference = row.get('base_ref')
                if reference:
                    if reference['tier'] not in ('hot', 'cold'):
                        raise ValueError('unknown base tier')
                    shutil.copyfile(safe(base / reference['tier'], reference['path']), target)
                else:
                    with bundle.open('objects/' + row['sha256']) as source, target.open('wb') as sink:
                        shutil.copyfileobj(source, sink)
                if target.stat().st_size != row['bytes'] or sha(target) != row['sha256']:
                    raise ValueError(f"work file bytes {row['path']}")
                target.chmod(row['mode'] & 0o777)
            root.rename(destination)
    return dict(status='PASS_ALL_CUMULATIVE_WORK_FILES_RESTORED', files=len(manifest['files']), base_generation=manifest['base']['generation'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--base', type=Path, required=True)
    parser.add_argument('--base-archive', type=Path)
    parser.add_argument('--root', action='append', default=[])
    parser.add_argument('--output', type=Path)
    parser.add_argument('--rules-file', type=Path)
    parser.add_argument('--restore', type=Path)
    parser.add_argument('--destination', type=Path)
    arguments = parser.parse_args()
    if arguments.restore:
        result = restore(arguments.base, arguments.restore, arguments.destination)
    elif arguments.base_archive and arguments.root and arguments.output and arguments.rules_file:
        result = create(arguments.base, arguments.base_archive, arguments.root, arguments.output, arguments.rules_file)
    else:
        parser.error('create requires --base-archive, --root, --output, --rules-file')
    print(json.dumps(result, indent=2))
