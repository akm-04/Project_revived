"""Reusable pieces of the strict gate's parallel mode (contract I85_STRICT_GATE_V1).

Unit building, the per-package DSN census, template clones, the thread pool and the go-test JSON parser. Nothing here imports
tools/strict_gate.py, so gate_preflight.py can reuse these functions without a Gate instance.
"""
import collections
import concurrent.futures
import hashlib
import json
import re
import subprocess

TEST_VARIABLE = re.compile(r'os\.(?:Getenv|LookupEnv)\("([A-Z0-9_]+)"\)')
# go test -list prints Example and Fuzz functions as well; the serial suite runs them too.
TEST_NAME = re.compile(r'^(Test|Example|Fuzz)\w*$')
EMPTY_PARALLEL = {'serial': [], 'shards': {}, 'serial_tests': [], 'known_flaky': []}
MAXIMUM_DATABASE_BYTES = 63


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


def go_test_command(go_binary, tags, packages, run=None, skip=None, package_limit=True):
    """The serial suite's command shape; parallel units pass one package with a shard pattern."""
    arguments = [str(go_binary), 'test', '-json', '-count=1', '-timeout=150m', '-tags', tags]
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


def build_units(packages, shard_counts, list_tests, serial_tests=()):
    """One unit per package; a package in shard_counts becomes one unit per non-empty shard.

    list_tests returns the package's test names, or None when the listing failed (the package then runs whole).
    A `package.Test` entry in serial_tests is left out of the package's shards and becomes one `_serial` unit that the
    caller runs after the pool; together the shards and the serial unit must cover the package's whole listed set.
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
        names = list_tests(package) if count else None
        if serial:
            units.append(dict(package=package, unit=f'{name}_serial', tests=serial,
                              run='^(' + '|'.join(serial) + ')$', shard=None, serial=True))
        if not count or names is None:
            units.append(dict(package=package, unit=name, tests=None, run=None, shard=None, serial=False))
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
