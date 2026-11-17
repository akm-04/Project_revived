"""Reusable pieces of the strict gate's parallel mode (contract I85_STRICT_GATE_V1).

Unit building, the per-package DSN census, template clones, the thread pool and the go-test JSON parser. Nothing here imports
tools/strict_gate.py, so gate_preflight.py can reuse these functions without a Gate instance.
"""
import collections
import concurrent.futures
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path

TEST_VARIABLE = re.compile(r'os\.(?:Getenv|LookupEnv)\("([A-Z0-9_]+)"\)')
# go test -list prints Example and Fuzz functions as well; the serial suite runs them too.
TEST_NAME = re.compile(r'^(Test|Example|Fuzz)\w*$')
EMPTY_PARALLEL = {'serial': [], 'shards': {}, 'serial_tests': [], 'known_flaky': []}
MAXIMUM_DATABASE_BYTES = 63
DEFAULT_TIMEOUT_MINUTES = 20
SERIAL_TIMEOUT_MINUTES = 150


class PoolError(Exception):
    pass


def parse_go_test_json(stream, module):
    """Outcomes keyed `<package>.<Test>` and the packages whose go test event failed without a test."""
    outcomes, started, failed_packages = {}, set(), set()
    for line in stream.read_text().splitlines():
        try:
            event = json.loads(line)
        except ValueError:
            continue
        package = event.get('Package', '').removeprefix(module + '/')
        test = event.get('Test', '')
        action = event.get('Action')
        if action == 'fail' and not test:
            failed_packages.add(package)
        if not test or '/' in test:
            continue
        key = f'{package}.{test}'
        if action == 'run':
            started.add(key)
        if action in ('pass', 'fail', 'skip'):
            outcomes[key] = action
    for key in started - set(outcomes):
        outcomes[key] = 'incomplete'
    return outcomes, failed_packages


def dsn_variables_by_package(source):
    """Each DSN variable read by a *_test.go, keyed by the directory of the package that reads it."""
    variables = collections.defaultdict(set)
    for path in source.rglob('*_test.go'):
        directory = str(path.parent.relative_to(source))
        for variable in TEST_VARIABLE.findall(path.read_text()):
            if variable.endswith('_DSN'):
                variables[directory].add(variable)
    return {directory: frozenset(names) for directory, names in variables.items()}


def normalize_package(package):
    return package.removeprefix('./')


def unit_timeout(parallel, package):
    """The unit's timeout: its package override, else parallel.json's default."""
    overrides = {normalize_package(key): minutes for key, minutes in (parallel.get('timeouts') or {}).items()}
    return overrides.get(normalize_package(package), parallel.get('timeout_minutes', DEFAULT_TIMEOUT_MINUTES))


def go_test_command(go_binary, tags, packages, run=None, skip=None, package_limit=True,
                    timeout_minutes=SERIAL_TIMEOUT_MINUTES):
    """The serial suite's command shape; parallel units pass one package with a shard pattern."""
    arguments = [str(go_binary), 'test', '-json', '-count=1', f'-timeout={timeout_minutes}m', '-tags', tags]
    if package_limit:
        arguments.append('-p=1')
    if run:
        arguments += ['-run', run]
    if skip:
        arguments += ['-skip', skip]
    return arguments + list(packages)


def test_names(go_binary, environment, cwd, tags, package):
    completed = subprocess.run([str(go_binary), 'test', '-list', '.*', '-tags', tags, package],
                               cwd=cwd, env=environment, capture_output=True, text=True, stdin=subprocess.DEVNULL)
    if completed.returncode != 0:
        raise PoolError(f'go test -list failed for {package}: {(completed.stdout + completed.stderr).strip()[-2000:]}')
    return sorted({line.strip() for line in completed.stdout.splitlines() if TEST_NAME.match(line.strip())})


def shard_of(test_name, count):
    return int(hashlib.sha1(test_name.encode()).hexdigest(), 16) % count


def assign_shards(test_names, count):
    if count < 1:
        raise PoolError(f'shard count {count} must be positive')
    shards = [[] for _ in range(count)]
    for test_name in sorted(set(test_names)):
        shards[shard_of(test_name, count)].append(test_name)
    return shards


def unit_slug(package):
    path = normalize_package(package)
    clean = re.sub(r'[^a-z0-9]+', '_', path.lower()).strip('_')
    return f'{clean[:24]}_{hashlib.sha1(path.encode()).hexdigest()[:6]}'


def database_name(suite, unit, variable):
    short = variable.lower().removeprefix('gxb_').removesuffix('_dsn')
    name = f's{suite[0]}{unit}_{short}'
    if len(name.encode()) > MAXIMUM_DATABASE_BYTES:
        raise PoolError(f'database name {name} exceeds {MAXIMUM_DATABASE_BYTES} bytes')
    return name


def selected_test_names(names, run=None, skip=None):
    """The enumerated tests a unit's run and skip patterns select; the planned root-test population."""
    selected = []
    for name in names:
        if run is not None and not re.search(run, name):
            continue
        if skip is not None and re.search(skip, name):
            continue
        selected.append(name)
    return selected


def unit_population(unit, skip):
    """The outcome keys `<package>.<test>` a unit must observe: its enumerated names with run and skip applied.

    Returns None when the package's tests were never enumerated, so the caller can never mistake an unproven
    population for an empty one.
    """
    if unit.get('tests') is None:
        return None
    package = normalize_package(unit['package'])
    return sorted(f'{package}.{name}' for name in selected_test_names(unit['tests'], unit.get('run'), skip))


def build_units(packages, shard_counts, list_tests, serial_tests=()):
    """One unit per package; a package in shard_counts becomes one unit per non-empty shard.

    list_tests returns the package's test names, or None when the listing failed (the package then runs whole, without a
    provable population). Every unit carries its enumerated names in `tests`; an empty list is a package proven to have no
    test under these tags, never an absence inferred from a run. A `package.Test` entry in serial_tests is left out of the
    package's shards and becomes one `_serial` unit that the caller runs after the pool; together the shards and the serial
    unit must cover the package's whole listed set.
    """
    serial_by_package = collections.defaultdict(list)
    for key in serial_tests:
        serial_package, _, test_name = key.rpartition('.')
        serial_by_package[serial_package].append(test_name)
    units = []
    for package in packages:
        name = unit_slug(package)
        serial = sorted(serial_by_package.get(normalize_package(package), ()))
        count = shard_counts.get(normalize_package(package), 0)
        names = list_tests(package)
        if serial:
            units.append(dict(package=package, unit=f'{name}_serial', tests=serial,
                              run='^(' + '|'.join(serial) + ')$', shard=None, serial=True))
        if names is None:
            units.append(dict(package=package, unit=name, tests=None, run=None, shard=None, serial=False))
            continue
        if not count:
            units.append(dict(package=package, unit=name, tests=names, run=None, shard=None, serial=False))
            continue
        if not names:
            raise PoolError(f'{package} is sharded but go test -list found no test in it')
        runnable = [test_name for test_name in names if test_name not in set(serial)]
        shards = assign_shards(runnable, count)
        covered = [test_name for shard in shards for test_name in shard] + serial
        if sorted(covered) != sorted(names):
            raise PoolError(f'shards for {package} cover {len(covered)} names of {len(names)} (serial {serial})')
        for index, shard in enumerate(shards):
            # An empty shard would still start the package's TestMain with no test to run.
            if not shard:
                continue
            units.append(dict(package=package, unit=f'{name}_s{index}', tests=shard,
                              run='^(' + '|'.join(shard) + ')$', shard=index, serial=False))
    return units


def clone_database(createdb, port, template, name, environment):
    completed = subprocess.run([str(createdb), '-p', str(port), '-T', template, name], env=environment,
                               capture_output=True, text=True, stdin=subprocess.DEVNULL)
    if completed.returncode != 0:
        raise PoolError(f'createdb -T {template} {name} failed: {completed.stderr.strip()}')


def run_pool(units, jobs, action):
    if jobs < 1:
        raise PoolError(f'jobs {jobs} must be positive')
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        futures = [pool.submit(action, unit) for unit in units]
        for future in concurrent.futures.as_completed(futures):
            future.result()


class NotReusable(Exception):
    """A unit input cannot be established, so its result must never be reused."""


IDENTIFIER = re.compile(r'[A-Za-z_]\w*')
ASSIGNMENT = re.compile(r'^\s*([A-Za-z_]\w*)\s*(?:,\s*[A-Za-z_]\w*\s*)*:?=(?!=)\s*(.*)$')
DECLARATION = re.compile(r'^\s*(?:var|const)\s+([A-Za-z_]\w*)(?:\s+[^=\s]+)?\s*=(?!=)\s*(.*)$')
GO_KEYWORDS = {'break', 'case', 'chan', 'const', 'continue', 'default', 'defer', 'else', 'fallthrough', 'for', 'func',
               'go', 'goto', 'if', 'import', 'interface', 'map', 'package', 'range', 'return', 'select', 'struct',
               'switch', 'type', 'var'}
PATH_CALLS = ('os.ReadFile', 'os.Open')
SCRATCH_MARKERS = ('t.TempDir()', 'os.MkdirTemp(', 'os.CreateTemp(', 'os.Getenv(', 'os.LookupEnv(', 't.Name()', 'os.TempDir()')
EMBED_DIRECTIVE = re.compile(r'^[ \t]*//go:embed[ \t]+(.+)$', re.M)


def canonical_json(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False)


def sha256_file(path, cache=None):
    key = str(Path(path))
    if cache is not None and key in cache:
        return cache[key]
    try:
        digest = hashlib.sha256(Path(path).read_bytes()).hexdigest()
    except OSError as failure:
        raise NotReusable(f'missing input {key}: {failure}') from failure
    if cache is not None:
        cache[key] = digest
    return digest


def directory_files(directory, cache=None):
    root = Path(directory)
    if not root.is_dir():
        raise NotReusable(f'missing input directory {root}')
    return [[str(path.relative_to(root)), sha256_file(path, cache)] for path in sorted(root.rglob('*')) if path.is_file()]


def parse_json_stream(text):
    decoder = json.JSONDecoder()
    index = 0
    documents = []
    while index < len(text):
        while index < len(text) and text[index].isspace():
            index += 1
        if index >= len(text):
            break
        try:
            document, index = decoder.raw_decode(text, index)
        except ValueError as failure:
            raise NotReusable(f'go list emitted invalid JSON: {failure}') from failure
        documents.append(document)
    return documents


def code_inputs(go_list_stdout, source, cache=None):
    """The code closure record: every module package go list -deps -test named, with its file hashes."""
    root = Path(source).resolve()
    records = []
    for document in parse_json_stream(go_list_stdout):
        directory = document.get('Dir') or ''
        if not directory:
            continue
        resolved = Path(directory)
        if not resolved.is_relative_to(root):
            continue
        files = []
        for field in ('GoFiles', 'CgoFiles', 'TestGoFiles', 'XTestGoFiles', 'EmbedFiles'):
            for name in sorted(document.get(field) or ()):
                files.append([name, sha256_file(resolved / name, cache)])
        testdata = []
        if (resolved / 'testdata').is_dir():
            testdata = directory_files(resolved / 'testdata', cache)
        records.append(dict(package=document.get('ImportPath', ''), files=files, testdata=testdata))
    records.sort(key=lambda record: record['package'])
    if not records:
        raise NotReusable('go list named no package inside the module')
    return records


def mask_go_source(text):
    """Blank comments and string contents so call sites can be found without parsing them; offsets and newlines stay."""
    characters = list(text)
    index, length = 0, len(text)
    while index < length:
        character = text[index]
        if character == '/' and index + 1 < length and text[index + 1] == '/':
            while index < length and text[index] != '\n':
                characters[index] = ' '
                index += 1
            continue
        if character == '/' and index + 1 < length and text[index + 1] == '*':
            characters[index] = characters[index + 1] = ' '
            index += 2
            while index < length and not (text[index] == '*' and index + 1 < length and text[index + 1] == '/'):
                if text[index] != '\n':
                    characters[index] = ' '
                index += 1
            if index < length:
                characters[index] = characters[index + 1] = ' '
                index += 2
            continue
        if character in '"\'':
            quote = character
            index += 1
            while index < length and text[index] != quote:
                if text[index] == '\\' and index + 1 < length:
                    characters[index] = ' '
                    index += 1
                if text[index] != '\n':
                    characters[index] = ' '
                index += 1
            index += 1
            continue
        if character == '`':
            index += 1
            while index < length and text[index] != '`':
                if text[index] != '\n':
                    characters[index] = ' '
                index += 1
            index += 1
            continue
        index += 1
    return ''.join(characters)


def matching_parenthesis(masked, open_index):
    depth = 0
    for index in range(open_index, len(masked)):
        if masked[index] == '(':
            depth += 1
        elif masked[index] == ')':
            depth -= 1
            if depth == 0:
                return index
    return None


def split_arguments(masked, original):
    arguments, depth, start = [], 0, 0
    for index, character in enumerate(masked):
        if character in '([{':
            depth += 1
        elif character in ')]}':
            depth -= 1
        elif character == ',' and depth == 0:
            arguments.append(original[start:index])
            start = index + 1
    arguments.append(original[start:])
    return arguments


def call_sites(masked, original, name):
    pattern = re.compile(re.escape(name) + r'\s*\(')
    for match in pattern.finditer(masked):
        open_index = masked.index('(', match.start())
        close_index = matching_parenthesis(masked, open_index)
        if close_index is None:
            continue
        body_masked = masked[open_index + 1:close_index]
        body_original = original[open_index + 1:close_index]
        yield match.start(), split_arguments(body_masked, body_original)


def first_call_arguments(expression, name):
    masked = mask_go_source(expression)
    for _, arguments in call_sites(masked, expression, name):
        return arguments
    return None


def go_string_literal(expression):
    if len(expression) >= 2 and expression[0] == '`' and expression[-1] == '`':
        return expression[1:-1]
    match = re.fullmatch(r'"((?:[^"\\\n]|\\.)*)"', expression)
    if not match:
        return None
    try:
        return json.loads(expression)
    except ValueError:
        return None


def is_scratch_expression(expression):
    return any(marker in expression for marker in SCRATCH_MARKERS)


def resolve_join(arguments, package_directory, known):
    """Resolve filepath.Join to ('path', p), ('directory', p) when only a directory prefix is known, or None."""
    parts = [argument.strip() for argument in arguments]
    if any(is_scratch_expression(part) for part in parts):
        return ('scratch', None)
    prefix = Path(package_directory)
    for position, part in enumerate(parts):
        literal = go_string_literal(part)
        if literal is not None:
            prefix = Path(os.path.normpath(str(prefix / literal)))
            continue
        if IDENTIFIER.fullmatch(part):
            classification = known.get(part)
            if classification is not None:
                kind, value = classification
                if kind == 'scratch':
                    return ('scratch', None)
                if kind in ('path', 'directory'):
                    candidate = Path(value)
                    prefix = candidate if candidate.is_absolute() else Path(os.path.normpath(str(prefix / candidate)))
                    continue
        elif part.startswith('filepath.Join'):
            inner = first_call_arguments(part, 'filepath.Join')
            nested = resolve_join(inner, package_directory, known) if inner is not None else None
            if nested is not None and nested[0] == 'scratch':
                return ('scratch', None)
            if nested is not None:
                prefix = Path(nested[1])
                continue
        if position == 0:
            return None
        return ('directory', str(prefix))
    return ('path', str(prefix))


def resolve_path_expression(expression, package_directory, known):
    expression = expression.strip()
    if is_scratch_expression(expression):
        return ('scratch', None)
    literal = go_string_literal(expression)
    if literal is not None:
        return ('path', str(Path(package_directory) / literal))
    if IDENTIFIER.fullmatch(expression):
        classification = known.get(expression)
        if classification is None:
            return None
        kind, value = classification
        if kind == 'scratch':
            return ('scratch', None)
        if kind in ('path', 'directory'):
            return ('path', value)
        return None
    if expression.startswith('filepath.Join'):
        inner = first_call_arguments(expression, 'filepath.Join')
        return resolve_join(inner, package_directory, known) if inner is not None else None
    return None


def classify_expression(expression, package_directory, known):
    expression = expression.strip()
    if is_scratch_expression(expression):
        return ('scratch', None)
    literal = go_string_literal(expression)
    if literal is not None:
        return ('path', str(Path(package_directory) / literal))
    if IDENTIFIER.fullmatch(expression):
        return known.get(expression, ('unknown', None))
    if expression.startswith('filepath.Join'):
        inner = first_call_arguments(expression, 'filepath.Join')
        resolved = resolve_join(inner, package_directory, known) if inner is not None else None
        if resolved is not None and resolved[0] in ('path', 'directory'):
            return ('path', resolved[1])
        if resolved is not None and resolved[0] == 'scratch':
            return ('scratch', None)
    return ('unknown', None)


def assignment_classifications(text, masked, package_directory):
    """Per-file, per-name path classification; a name assigned two different ways becomes unknown (never guessed)."""
    known = {}
    for original, masked_line in zip(text.split('\n'), masked.split('\n')):
        match = DECLARATION.match(masked_line) or ASSIGNMENT.match(masked_line)
        if not match:
            continue
        name = match.group(1)
        if name in GO_KEYWORDS:
            continue
        classification = classify_expression(original[match.start(2):], package_directory, known)
        existing = known.get(name)
        if existing is None:
            known[name] = classification
        elif existing != classification:
            known[name] = ('unknown', None)
    return known


def add_resolved_path(records, source, result, cache):
    kind, value = result
    if kind == 'scratch':
        return
    path = Path(os.path.normpath(str(value)))
    if not path.is_relative_to(source):
        return
    if path.is_dir():
        for child in sorted(path.rglob('*')):
            if child.is_file():
                records[str(child.relative_to(source))] = sha256_file(child, cache)
        return
    relative = str(path.relative_to(source))
    records[relative] = sha256_file(path, cache) if path.is_file() else 'absent'


def runtime_file_inputs(source, package_directory, test_files, cache=None):
    """Repo files the package's tests name by literal path; an unresolvable path is NotReusable with its file:line."""
    root = Path(source).resolve()
    directory = Path(package_directory)
    records = {}
    for path in test_files:
        text = path.read_text()
        masked = mask_go_source(text)
        known = assignment_classifications(text, masked, directory)
        relative = str(Path(path).relative_to(root))
        for call_name in (*PATH_CALLS, 'filepath.Join'):
            for position, arguments in call_sites(masked, text, call_name):
                if call_name == 'filepath.Join':
                    result = resolve_join(arguments, directory, known)
                else:
                    result = resolve_path_expression(arguments[0] if arguments else '', directory, known)
                if result is None:
                    line = text.count('\n', 0, position) + 1
                    raise NotReusable(f'{relative}:{line}: cannot resolve {call_name} path')
                add_resolved_path(records, root, result, cache)
        for match in EMBED_DIRECTIVE.finditer(text):
            for pattern in match.group(1).split():
                paths = sorted(directory.glob(pattern))
                if not paths:
                    target = Path(os.path.normpath(str(directory / pattern)))
                    if target.is_relative_to(root):
                        records[str(target.relative_to(root))] = 'absent'
                for embedded in paths:
                    add_resolved_path(records, root, ('path', str(embedded)), cache)
    return [[name, records[name]] for name in sorted(records)]
