"""Provisioned strict gate (contract I85_STRICT_GATE_V1).

Exports one commit and runs, against a private PostgreSQL cluster:
  - every build tag set (unit, postgres, river) with its own freshly migrated and deployed databases for every test DSN, plus a
    build-only chi set; go build, go vet and go test -json for each;
  - the LuaJIT differential oracle (GXB_LUAJIT) inside the suites and the latency gate once, serially (this host is the reference host);
  - every upgrade/restore/seed-compare orchestration recipe on its own databases;
  - after the suites, the e2e/VC gxb-api logs under --api-logs contain zero reply_conformance_violation lines.
Every test outcome is classified against tools/strict_gate/known_debt.json and tools/strict_gate/skip_allowlist.json. Strict: a
missing tool, fixture, binary or database, a test environment variable nobody provisions, a failure outside the known debt, a skip
outside the allowlist, a repaid debt entry and a stale allowlist entry all make the gate RED. Writes <work>/STRICT_GATE.json.

Usage: strict_gate.py --toolchain <self-contained tool root> --cache <go/zig cache root> --work <new directory>
                      --populated59-dump <I7C3B F2_RECOVERY_EVIDENCE.dump> [--commit HEAD] [--port 55561] [--select REGEX]
                      [--mode serial|parallel] [--section both|general|latency] [--jobs N] [--package PATH ...]
                      [--previous STRICT_GATE.json] [--api-logs DIR] [--reuse] [--reuse-store DIR]
"""
import argparse
import collections
import datetime
import fcntl
import hashlib
import io
import json
import os
import re
import signal
import socket
import subprocess
import sys
import tarfile
import threading
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gate_pool  # noqa: E402

REPOSITORY = Path(__file__).resolve().parents[1]
WORKSPACE = Path('/home/akm/Chatgpt/EOL_Game')
LISTS = REPOSITORY / 'tools/strict_gate'
DEFAULT_REUSE_STORE = WORKSPACE / 'tmp/gate_results'
TAG_SETS = {'unit': '', 'postgres': 'postgres socialintegration channelintegration',
            'river': 'postgres river socialintegration channelintegration'}
# The 2026-11-17 measurement found tpl_postgres_pub and tpl_river_pub identical (schema, table set, row counts and data
# up to build timestamps; the deploy already runs the river migrations), so both database suites clone the river one.
SHARED_TEMPLATE_SUITE = 'river'
BUILD_ONLY_TAG_SETS = {'chi': 'chi'}
FULL_TAGS = TAG_SETS['river']
BINARY_COMMANDS = {'API': ('gxb-api', 'postgres,river'), 'REALTIME': ('gxb-realtime', 'postgres'),
                   'MAINT': ('gxb-profile-media-maint', 'postgres'), 'ACTIVATION': ('gxb-content-broadcast-deploy', 'postgres,river')}
# Variables the gate itself provides to every run, and test outputs that are only written when a freeze tool asks for them.
MACHINE_VARIABLES = {'GXB_LUAJIT', 'GXB_I7B5B_ASSET_ROOT', 'GXB_I7A8_FULL_ROSTER_PROBE'}
SUITE_FIXTURE_VARIABLES = {'GXB_BOOK_COMPILER_PAYLOAD', 'GXB_I9_10A_SCRATCH_JSON', 'GXB_SOCIAL_CATALOG_PATH'}


def suite_fixtures(source):
    generated = source / 'internal/content/builtin/generated'
    return {
        'GXB_BOOK_COMPILER_PAYLOAD': str(generated / 'book_input_catalog.json'),
        'GXB_I9_10A_SCRATCH_JSON': str(generated / 'workshop_input_catalog.json'),
        'GXB_SOCIAL_CATALOG_PATH': str(generated / 'social_input_catalog.json'),
    }


# Parallel units clone these DSN variables from the publication-prepared template; all others from the plain template.
PREPARED_VARIABLES = {'GXB_I7A9_DSN'}
OPERATOR_VARIABLES = {'GXB_I910C_MIG127_PREDECESSOR_DATABASE', 'GXB_I910C_OLD_EVIDENCE', 'GXB_I9_10B_PRODUCTION_WAKE_PROBE', 'GXB_MENTOR_CATALOG_PATH', 'GXB_MID1_GOLDEN_UPDATE', 'GXB_SOCIAL17_EVIDENCE'}
OPTIONAL_OUTPUT_VARIABLES = {'GXB_I8_3B_SNAPSHOT_OUT', 'GXB_I910C_UPGRADE_EVIDENCE', 'GXB_SOCIAL17_UPGRADE_EVIDENCE'}


def suite_fixtures(source):
    generated = source / 'internal/content/builtin/generated'
    return {
        'GXB_BOOK_COMPILER_PAYLOAD': str(generated / 'book_input_catalog.json'),
        'GXB_I9_10A_SCRATCH_JSON': str(generated / 'workshop_input_catalog.json'),
        'GXB_SOCIAL_CATALOG_PATH': str(generated / 'social_input_catalog.json'),
    }


TOOLS = ['go', 'gofmt', 'goose', 'luajit', 'initdb', 'pg_ctl', 'createdb', 'psql', 'pg_dump', 'pg_restore', 'zig-cc', 'zig-c++']
ACCEPTED35_COMMIT = '52b31f6cb83b89eda2085635b205591ca4a72e7f'
ACCEPTED35_REVISION = '66dddbab1c548555e244c670bc994e9a17c604ba5462e38eb6610c956943b3af'
PREVIOUS_PRODUCT_COMMIT = '79d1a26a413dd27e14f9d7557cfaf184785d17cb'
# The last I9-4A commit: content generation 47 (5ca02bec...), schema 00086. Its mission instances pin the generation the 4B upgrade must keep.
MISSION_CONTENT47_COMMIT = '93ae7889916a0db78e5c1ecad5da7b670a1cac6f'
MISSION_CONTENT47_TESTS = '^(TestActivityNativePinned47ConsumersAndCanonicalSpend|TestActivityNativeMissingRequiredPayloadIsRefused)$'
FORUM_LEGACY_MIGRATIONS_COMMIT = 'd1f521e1c2d44251f31a6644ec287207c04474a8'
POPULATED59_SHA256 = '1423a2014caca26acbfe6fe96c11c8417bd819afbc8827cbdb9705554b364560'
PREVIOUS_PRODUCT_POPULATE = ('^(TestI7C5ACombatOwnedStartResolveTerminalNative|TestI7C5ACombatCloseUnresolvedNative|'
                             'TestI7C5BTopFloorLadderFightSettlementNative|TestI7C5COneOnOneEntryMatchSettlementNative|'
                             'TestI7C5DArenaEntryFightSettlementNative)$')
GETENV = re.compile(r'os\.(?:Getenv|LookupEnv)\("([A-Z0-9_]+)"\)')
CHILD_SET = re.compile(r'"([A-Z0-9_]+)=|Setenv\("([A-Z0-9_]+)"')
TEST_FUNCTION = re.compile(r'^func (Test\w+)\(t \*testing\.T\)', re.M)


LATENCY_REPETITIONS = 3
BASELINE_WORK = b'\0' * (64 << 20)
REPLY_CONFORMANCE_VIOLATION = 'reply_conformance_violation '
QUIET_LOCK = WORKSPACE / 'tmp/worker_clusters/quiet.lock'
LATENCY_DEFAULTS = dict(
    benchmark_reference_seconds=0.0426,
    benchmark_tolerance=0.1,
    check_interval_seconds=30,
    cooldown_seconds=300,
    general_ceiling_factor=10,
    load_average_max=1.5,
    temperature_celsius_max=65,
    wait_minutes=60,
    members=[],
)
LATENCY_DEFERRED = 'latency_deferred'


def host_conditions():
    """CPU temperatures, clocks, load and a fixed single-thread hash benchmark (best of 5) at one instant."""
    temperatures = {}
    for sensor in Path('/sys/class/hwmon').glob('hwmon*/temp*_input'):
        name = (sensor.parent / 'name').read_text().strip()
        label = sensor.with_name(sensor.name.replace('_input', '_label'))
        key = f"{name}:{label.read_text().strip() if label.exists() else sensor.name}"
        temperatures[key] = int(sensor.read_text()) / 1000
    frequencies = [int(path.read_text()) / 1000 for path in Path('/sys/devices/system/cpu').glob('cpu[0-9]*/cpufreq/scaling_cur_freq')]
    timings = []
    for _ in range(5):
        began = time.perf_counter()
        hashlib.sha256(BASELINE_WORK).digest()
        timings.append(time.perf_counter() - began)
    return dict(at=datetime.datetime.now(datetime.timezone.utc).isoformat(), temperatures_celsius=temperatures,
                mean_frequency_mhz=round(sum(frequencies) / len(frequencies)) if frequencies else None,
                load_average=os.getloadavg(), baseline_sha256_64mib_seconds=round(min(timings), 4))

class GateFailure(Exception):
    pass


class BlockedByKnownDebt(Exception):
    """A recipe step failed only on known-debt tests, so the recipe's later steps cannot run until I8.5-6 repairs them."""


def require(condition, message):
    if not condition:
        raise GateFailure(message)


def free_address():
    with socket.socket() as probe:
        probe.bind(('127.0.0.1', 0))
        return f'127.0.0.1:{probe.getsockname()[1]}'


class Gate:
    def __init__(self, arguments):
        self.toolchain = Path(arguments.toolchain).resolve()
        self.work = Path(arguments.work).resolve()
        self.port = arguments.port
        self.select = re.compile(arguments.select) if arguments.select else None
        self.packages = arguments.package or None
        self.mode = arguments.mode
        self.jobs = arguments.jobs
        self.previous = Path(arguments.previous).resolve() if arguments.previous else None
        self.api_logs = Path(arguments.api_logs).resolve() if arguments.api_logs else None
        self.reuse = arguments.reuse
        self.reuse_store = Path(arguments.reuse_store).resolve()
        self.reuse_in_run = {}
        self.reuse_lock = threading.Lock()
        self.reuse_ignored = []
        self.reused_units = 0
        self.run_units = 0
        self.input_hashes = {}
        self.code_cache = {}
        self.template_cache = {}
        self.built_templates = set()
        self._go_version = None
        self.max_connections = 900 if self.mode == 'parallel' else 300
        self.populated59 = Path(arguments.populated59_dump).resolve()
        self.red = []
        self.steps = []
        self.runs = {}
        self.package_failures = collections.defaultdict(list)
        self.unit_lock = threading.Lock()
        self.blocked = {}
        self.orchestration_variables = set()
        self.dsn_by_package = {}
        self.accepted35 = None
        self.work.mkdir(parents=True)
        for directory in ['logs', 'runs', 'binaries', 'recipes', 'exports', 'media']:
            (self.work / directory).mkdir()
        self.commit = subprocess.check_output(['git', 'rev-parse', arguments.commit], cwd=REPOSITORY, text=True).strip()
        self.source = self.export(self.commit, 'candidate')
        self.module = re.search(r'^module (\S+)', (self.source / 'go.mod').read_text(), re.M).group(1)
        self.known_debt, self.allowlist, self.parallel, self.latency, self.list_hashes = self.load_lists()
        self.section = arguments.section
        self.latency_red = []
        self.latency_runs = {}
        self.latency_conditions = []
        self.latency_verdict = None
        cache = Path(arguments.cache).resolve()
        go_root = self.only(self.toolchain.glob('opt/go-*'))
        postgres_root = self.only(self.toolchain.glob('opt/postgresql-*'))
        self.user = subprocess.check_output(['id', '-un'], text=True).strip()
        self.environment = dict(
            HOME=os.environ['HOME'], GOROOT=str(go_root), GOMODCACHE=str(cache / 'go-mod'), GOCACHE=str(cache / 'go-build'),
            GOTOOLCHAIN='local', GOPROXY=f'file://{self.toolchain}/cache/go-mod/cache/download', GOSUMDB='off', GOTELEMETRY='off',
            GOFLAGS='-mod=readonly', CGO_ENABLED='1', CC=str(self.toolchain / 'bin/zig-cc'), CXX=str(self.toolchain / 'bin/zig-c++'),
            ZIG_GLOBAL_CACHE_DIR=str(cache / 'zig'), ZIG_LOCAL_CACHE_DIR=str(cache / 'zig'), PGHOST='127.0.0.1',
            PATH=f'{self.toolchain}/bin:{postgres_root}/bin:{go_root}/bin:/usr/bin:/bin', GXB_E2E_TOOL_ROOT=str(self.toolchain),
            GXB_LUAJIT=str(self.toolchain / 'bin/luajit'), GXB_I7B5B_ASSET_ROOT=str(self.work / 'media'), GXB_I7A8_FULL_ROSTER_PROBE='1',
            GXB_LATENCY_GENERAL_CEILING_FACTOR=str(self.latency_settings()['general_ceiling_factor']))
        (self.work / 'media').chmod(0o700)

    @staticmethod
    def only(paths):
        found = list(paths)
        require(len(found) == 1, f'expected exactly one of {found}')
        return found[0]

    def load_lists(self):
        """Lists come from the exported candidate; a candidate without parallel.json gets the empty one."""
        documents, hashes = {}, {}
        for name, required in (('known_debt.json', True), ('skip_allowlist.json', True), ('parallel.json', False),
                               ('latency.json', False)):
            path = self.source / 'tools/strict_gate' / name
            if path.exists():
                text = path.read_text()
            elif name == 'latency.json':
                text = json.dumps(LATENCY_DEFAULTS)
            else:
                require(not required, f'candidate lacks tools/strict_gate/{name}')
                text = json.dumps(gate_pool.EMPTY_PARALLEL)
            documents[name] = json.loads(text)
            hashes[name.removesuffix('.json')] = hashlib.sha256(text.encode()).hexdigest()
        parallel = documents['parallel.json']
        if self.mode == 'parallel':
            self.validate_parallel(parallel)
        self.validate_latency(documents['latency.json'])
        return ({entry['test']: entry for entry in documents['known_debt.json']['entries']},
                {entry['test']: entry for entry in documents['skip_allowlist.json']['entries']}, parallel,
                documents['latency.json'], hashes)

    @staticmethod
    def validate_latency(document):
        require(isinstance(document, dict), 'latency.json must be an object')
        for name in ('benchmark_reference_seconds', 'benchmark_tolerance', 'check_interval_seconds',
                     'cooldown_seconds', 'general_ceiling_factor', 'load_average_max', 'temperature_celsius_max'):
            value = document.get(name)
            require(isinstance(value, (int, float)) and not isinstance(value, bool) and value > 0,
                    f'latency.json {name} must be a positive number')
        wait_minutes = document.get('wait_minutes')
        require(isinstance(wait_minutes, int) and not isinstance(wait_minutes, bool) and wait_minutes >= 0,
                'latency.json wait_minutes must be a non-negative integer')
        members = document.get('members')
        require(isinstance(members, list), 'latency.json members must be a list')
        for member in members:
            require(isinstance(member, dict) and isinstance(member.get('package'), str)
                    and isinstance(member.get('test'), str) and isinstance(member.get('tags'), str),
                    'latency.json members need package, test and tags strings')

    def latency_settings(self):
        return {**LATENCY_DEFAULTS, **(self.latency or {})}

    @staticmethod
    def validate_parallel(document):
        require(isinstance(document.get('serial'), list), 'parallel.json serial must be a list')
        require(isinstance(document.get('shards'), dict), 'parallel.json shards must be an object')
        require(all(isinstance(count, int) and count >= 1 for count in document['shards'].values()),
                'parallel.json shard counts must be positive integers')
        serial_tests = document.get('serial_tests', [])
        require(isinstance(serial_tests, list), 'parallel.json serial_tests must be a list')
        require(all(isinstance(key, str) and '.' in key for key in serial_tests),
                'parallel.json serial_tests entries must be package.TestName')
        require(isinstance(document.get('known_flaky'), list), 'parallel.json known_flaky must be a list')
        timeout_minutes = document.get('timeout_minutes', gate_pool.DEFAULT_TIMEOUT_MINUTES)
        require(isinstance(timeout_minutes, int) and timeout_minutes >= 1,
                'parallel.json timeout_minutes must be a positive integer')
        timeouts = document.get('timeouts', {})
        require(isinstance(timeouts, dict), 'parallel.json timeouts must be an object')
        require(all(isinstance(package, str) for package in timeouts),
                'parallel.json timeout keys must be package paths')
        require(all(isinstance(minutes, int) and minutes >= 1 for minutes in timeouts.values()),
                'parallel.json timeout values must be positive integers')

    def validate_timeout_packages(self, packages):
        """Every timeout names a package the candidate contains, or the list is wrong."""
        known = {gate_pool.normalize_package(package) for package in packages}
        missing = sorted(package for package in self.parallel.get('timeouts', {})
                         if gate_pool.normalize_package(package) not in known)
        require(not missing, f'parallel.json timeouts names package(s) the candidate does not contain: {missing}')

    def selected(self, unit):
        return self.select is None or bool(self.select.search(unit))

    def export(self, commit, name):
        destination = self.work / 'exports' / name
        archive = subprocess.run(['git', 'archive', '--format=tar', commit], cwd=REPOSITORY, check=True, capture_output=True).stdout
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            tar.extractall(destination, filter='data')
        return destination

    def tool(self, name):
        return str(self.toolchain / 'bin' / name)

    def step(self, name, arguments, extra=None, cwd=None):
        log = self.work / 'logs' / (name.replace(':', '_') + '.log')
        began = time.perf_counter()
        with log.open('w') as output:
            code = subprocess.run([str(argument) for argument in arguments], cwd=cwd or self.source, env={**self.environment, **(extra or {})},
                                  stdout=output, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL).returncode
        self.steps.append(dict(name=name, exit=code, log=str(log.relative_to(self.work)),
                               seconds=round(time.perf_counter() - began, 3)))
        print(f'{name} {code}', flush=True)
        require(code == 0, f'step {name} exited {code} (log {log.relative_to(self.work)})')

    def sql(self, dsn, query):
        return subprocess.check_output([self.tool('psql'), dsn, '-X', '-At', '-v', 'ON_ERROR_STOP=1', '-c', query],
                                       env=self.environment, text=True, stdin=subprocess.DEVNULL).strip()

    def dsn(self, database):
        return f'postgres://{self.user}@127.0.0.1:{self.port}/{database}?sslmode=disable'

    def go_test(self, label, tags, packages, extra=None, run=None, skip=None, cwd=None, serial=True, record=True):
        stream = self.work / 'runs' / (label.replace(':', '_') + '.jsonl')
        arguments = gate_pool.go_test_command(self.tool('go'), tags, packages, run=run, skip=skip, package_limit=serial)
        began = time.perf_counter()
        with stream.open('w') as output:
            code = subprocess.run(arguments, cwd=cwd or self.source, env={**self.environment, **(extra or {})},
                                  stdout=output, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL).returncode
        outcomes, failed_packages = gate_pool.parse_go_test_json(stream, self.module)
        failing_packages = {key.rsplit('.', 1)[0] for key, outcome in outcomes.items() if outcome in ('fail', 'incomplete')}
        if record:
            self.package_failures[label] = sorted(failed_packages - failing_packages)
            self.runs[label] = outcomes
        self.steps.append(dict(name=label, exit=code, stream=str(stream.relative_to(self.work)), tests=len(outcomes),
                               seconds=round(time.perf_counter() - began, 3)))
        print(f'{label} {code} {dict(collections.Counter(outcomes.values()))}', flush=True)
        return outcomes

    def database(self, name, cwd=None, migrate=('up',), deploy=True):
        self.step(f'create:{name}', [self.tool('createdb'), '-p', self.port, name])
        dsn = self.dsn(name)
        self.step(f'migrate:{name}', [self.tool('goose'), '-dir', 'migrations', 'postgres', dsn, *migrate], cwd=cwd)
        if deploy:
            self.deploy(name, dsn)
        return dsn

    def deploy(self, name, dsn, cwd=None):
        self.step(f'deploy:{name}', [self.tool('go'), 'run', '-tags', 'postgres,river', './cmd/gxb-content-broadcast-deploy'],
                  {'GXB_POSTGRES_DSN': dsn}, cwd=cwd)

    def migrate_current(self, name, dsn):
        self.step(f'migrate-current:{name}', [self.tool('goose'), '-dir', 'migrations', 'postgres', dsn, 'up'])

    def dump(self, name, dsn):
        path = self.work / 'recipes' / f'{name}.dump'
        self.step(f'dump:{name}', [self.tool('pg_dump'), '-Fc', '-f', path, dsn])
        return path

    def restore(self, name, dump):
        self.step(f'create:{name}', [self.tool('createdb'), '-p', self.port, name])
        dsn = self.dsn(name)
        self.step(f'restore:{name}', [self.tool('pg_restore'), '--no-owner', '--no-acl', '--exit-on-error', '-d', dsn, dump])
        return dsn

    def cluster(self, action):
        data = self.work / 'cluster/pgdata'
        commands = {'init': [self.tool('initdb'), '-D', data, '--auth=trust', '--no-locale', '--encoding=UTF8'],
                    'stop': [self.tool('pg_ctl'), '-D', data, '-m', 'fast', '-t', '600', '-w', 'stop']}
        start = [self.tool('pg_ctl'), '-D', data, '-l', self.work / 'cluster/postgresql.log', '-t', '600', '-w',
                 '-o', f'-h 127.0.0.1 -p {self.port} -c max_connections={self.max_connections}']
        commands['start'] = [*start, 'start']
        commands['restart'] = [*start, '-m', 'fast', 'restart']
        self.step(f'cluster:{action}:{len(self.steps)}', commands[action])

    def every_dsn(self, dsn):
        return {variable: dsn for variable in self.census['dsn']}

    def census_of_test_variables(self):
        reads, child_set, functions = collections.defaultdict(set), set(), collections.defaultdict(list)
        for path in self.source.rglob('*_test.go'):
            text = path.read_text()
            relative = str(path.relative_to(self.source))
            for match in GETENV.finditer(text):
                reads[match.group(1)].add(relative)
            for match in CHILD_SET.finditer(text):
                child_set.add(match.group(1) or match.group(2))
            for name in TEST_FUNCTION.findall(text):
                functions[name].append(f'{path.parent.relative_to(self.source)}.{name}')
        classes = collections.defaultdict(list)
        for variable in sorted(reads):
            classes[self.variable_class(variable, child_set)].append(variable)
        self.census = dict(classes)
        self.test_functions = functions
        for variable in classes.get('binary', []):
            require(variable.removesuffix('_BINARY').rsplit('_', 1)[-1] in BINARY_COMMANDS, f'binary variable {variable} names no known command')

    def variable_class(self, variable, child_set):
        if variable.endswith('_DSN'):
            return 'dsn'
        if variable.endswith('_BINARY'):
            return 'binary'
        if variable in MACHINE_VARIABLES:
            return 'machine'
        if variable in SUITE_FIXTURE_VARIABLES:
            return 'suite_fixture'
        if variable in OPERATOR_VARIABLES:
            return 'operator'
        if variable in OPTIONAL_OUTPUT_VARIABLES:
            return 'optional_output'
        if variable in self.orchestration_variables:
            return 'recipe'
        if variable in child_set:
            return 'child'
        return 'unclassified'

    def build_binaries(self):
        for variable in self.census['binary']:
            command, tags = BINARY_COMMANDS[variable.removesuffix('_BINARY').rsplit('_', 1)[-1]]
            output = self.work / 'binaries' / command
            if not output.exists():
                self.step(f'build-binary:{command}', [self.tool('go'), 'build', '-buildvcs=false', '-tags', tags, '-o', output, './cmd/' + command])
            self.environment[variable] = str(output)

    def suite_skip_pattern(self):
        names = sorted({entry['test'].rsplit('.', 1)[1] for entry in self.allowlist.values() if entry.get('excluded_from_suites')})
        for name in names:
            require(len(self.test_functions.get(name, [])) == 1, f'suite exclusion {name} must name exactly one test function')
        return '^(' + '|'.join(names) + ')$' if names else None

    def suite(self, name, tags):
        tag_arguments = ['-tags', tags]
        self.step(f'build:{name}', [self.tool('go'), 'build', '-buildvcs=false', *tag_arguments, './...'])
        self.step(f'vet:{name}', [self.tool('go'), 'vet', *tag_arguments, './...'])
        extra = suite_fixtures(self.source)
        if name != 'unit':
            for variable in self.census['dsn']:
                database = f'{name}_' + variable.lower().removeprefix('gxb_').removesuffix('_dsn')
                extra[variable] = self.database(database)
            packages = ['./internal/integration/publication'] + ['./internal/adapters/river'] * ('river' in tags.split())
            self.go_test(f'provision:{name}:publication', tags, packages, {**extra, 'GXB_I7A9_PREPARE_PROCESS': '1'},
                         run='^(TestPreparePublicationProcess|TestPreparePublicationRiver)$')
        self.go_test(f'suite:{name}', tags, self.packages or ['./...'], extra, skip=self.suite_skip_pattern(), serial=name != 'unit')

    def suite_parallel(self, name, tags):
        tag_arguments = ['-tags', tags]
        self.step(f'build:{name}', [self.tool('go'), 'build', '-buildvcs=false', *tag_arguments, './...'])
        self.step(f'vet:{name}', [self.tool('go'), 'vet', *tag_arguments, './...'])
        extra = suite_fixtures(self.source)
        if name != 'unit':
            self.ensure_template(self.suite_template(name), extra)
        serial_packages = {gate_pool.normalize_package(package) for package in self.parallel['serial']}
        shard_counts = {gate_pool.normalize_package(package): count for package, count in self.parallel['shards'].items()
                        if gate_pool.normalize_package(package) not in serial_packages}
        units = gate_pool.build_units(self.parallel_packages(tags), shard_counts, self.test_lister(name, tags),
                                      self.parallel.get('serial_tests', ()))
        counts = self.test_counts_by_package()
        for unit in units:
            unit['test_count'] = len(unit['tests'] or ()) or counts.get(gate_pool.normalize_package(unit['package']), 0)
        (self.work / 'runs' / f'suite_{name}').mkdir()
        skip = self.suite_skip_pattern()
        pooled = [unit for unit in units if not unit['serial'] and gate_pool.normalize_package(unit['package']) not in serial_packages]
        sequential = [unit for unit in units if not unit['serial'] and gate_pool.normalize_package(unit['package']) in serial_packages]
        serial_units = [unit for unit in units if unit['serial']]
        gate_pool.run_pool(self.ordered_units(name, pooled), self.jobs,
                           lambda unit: self.run_unit(name, tags, unit, extra, self.unit_skip(unit, skip)))
        for unit in sequential:
            self.run_unit(name, tags, unit, extra, self.unit_skip(unit, skip))
        for unit in serial_units:
            self.run_unit(name, tags, unit, extra, self.unit_skip(unit, skip))

    def serial_skip(self, package):
        """The skip pattern for a package's serial_tests, or None when it has none."""
        package_path = gate_pool.normalize_package(package)
        names = sorted({key.rpartition('.')[2] for key in self.parallel.get('serial_tests', [])
                        if key.rpartition('.')[0] == package_path})
        return '^(' + '|'.join(names) + ')$' if names else None

    def unit_skip(self, unit, suite_skip):
        """Serial tests run alone, so their own unit must not skip them."""
        if unit['serial']:
            return suite_skip
        return '|'.join(pattern for pattern in (suite_skip, self.serial_skip(unit['package'])) if pattern) or None

    def prepared_template(self, name, tags, extra):
        """The plain template's clone after the publication provision step, which prepared-variable units clone from."""
        prepared = f'tpl_{name}_pub'
        gate_pool.clone_database(self.tool('createdb'), self.port, f'tpl_{name}', prepared, self.environment)
        variables = {variable: self.dsn(prepared) for variable in self.census['dsn']}
        packages = ['./internal/integration/publication'] + ['./internal/adapters/river'] * ('river' in tags.split())
        self.go_test(f'provision:{name}:publication', tags, packages, {**extra, **variables, 'GXB_I7A9_PREPARE_PROCESS': '1'},
                     run='^(TestPreparePublicationProcess|TestPreparePublicationRiver)$')

    def parallel_packages(self, tags):
        if self.packages:
            return list(self.packages)
        return self.all_packages(tags)

    def all_packages(self, tags):
        completed = subprocess.run([self.tool('go'), 'list', '-tags', tags, '-f', '{{.ImportPath}}', './...'],
                                   cwd=self.source, env=self.environment, capture_output=True, text=True, stdin=subprocess.DEVNULL)
        require(completed.returncode == 0, f'go list failed: {(completed.stdout + completed.stderr).strip()[-2000:]}')
        prefix = self.module + '/'
        return ['./' + line.removeprefix(prefix) for line in completed.stdout.split() if line.startswith(prefix)]

    def existing_packages(self):
        """Every package the candidate lists under any suite tag set; a timeout may name any of them."""
        packages = set()
        for tags in TAG_SETS.values():
            packages.update(self.all_packages(tags))
        return sorted(packages)

    def test_lister(self, name, tags):
        def list_tests(package):
            try:
                return gate_pool.test_names(self.tool('go'), self.environment, self.source, tags, package)
            except gate_pool.PoolError as failure:
                self.red.append(f'suite:{name}: {failure}')
                return None
        return list_tests

    def test_counts_by_package(self):
        counts = collections.Counter()
        for locations in self.test_functions.values():
            for location in locations:
                counts[location.rsplit('.', 1)[0]] += 1
        return counts

    def ordered_units(self, name, units):
        durations = self.previous_durations()
        return sorted(units, key=lambda unit: (-durations.get(f'unit:{name}:{unit["unit"]}', 0), -unit['test_count']))

    def previous_durations(self):
        if self.previous is None:
            return {}
        require(self.previous.is_file(), f'previous report {self.previous} missing')
        document = json.loads(self.previous.read_text())
        return {row['name']: row.get('seconds', 0) for row in document.get('steps', [])}

    @staticmethod
    def suite_template(name):
        """Both database suites clone the river-provisioned template (measurement, GATE_SPEEDUP_V1 section 2)."""
        return SHARED_TEMPLATE_SUITE if name in ('postgres', 'river') else name

    def ensure_template(self, suite, extra):
        if suite in self.built_templates:
            return
        self.database(f'tpl_{suite}')
        self.prepared_template(suite, TAG_SETS[suite], extra)
        self.built_templates.add(suite)

    def unit_environment(self, name, unit, extra):
        environment = {**self.environment, **extra}
        asset_root = self.work / 'media' / unit['unit']
        asset_root.mkdir(mode=0o700, exist_ok=True)
        environment['GXB_I7B5B_ASSET_ROOT'] = str(asset_root)
        if name == 'unit':
            return environment
        template_name = self.suite_template(name)
        variables = self.dsn_by_package.get(gate_pool.normalize_package(unit['package']), frozenset())
        for variable in sorted(variables):
            template = f'tpl_{template_name}_pub' if variable in PREPARED_VARIABLES else f'tpl_{template_name}'
            database = gate_pool.database_name(name, unit['unit'], variable)
            gate_pool.clone_database(self.tool('createdb'), self.port, template, database, self.environment)
            environment[variable] = self.dsn(database)
        return environment

    def unit_fingerprint(self, suite, tags, unit, extra, skip):
        """The sha256 of every input that can change this unit's outcome; raises NotReusable when one is unknown."""
        package = gate_pool.normalize_package(unit['package'])
        package_directory = self.source / package
        inputs = dict(
            code=self.code_inputs(tags, package),
            runtime=gate_pool.runtime_file_inputs(self.source, package_directory,
                                                  sorted(package_directory.glob('*_test.go')), self.input_hashes),
            fixtures=self.fixture_inputs(),
            external=self.external_inputs(),
            database=self.database_inputs(suite, package),
            binaries=self.binary_inputs(),
            unit=self.unit_inputs(suite, tags, unit, extra, skip))
        return hashlib.sha256(gate_pool.canonical_json(inputs).encode()).hexdigest(), inputs

    def code_inputs(self, tags, package):
        key = (tags, package)
        cached = self.code_cache.get(key)
        if isinstance(cached, str):
            raise gate_pool.NotReusable(cached)
        if cached is not None:
            return cached
        completed = subprocess.run([self.tool('go'), 'list', '-deps', '-test', '-json', '-tags', tags, './' + package],
                                   cwd=self.source, env=self.environment, capture_output=True, text=True,
                                   stdin=subprocess.DEVNULL)
        if completed.returncode != 0:
            reason = f'go list -deps -test failed for ./{package}: {(completed.stdout + completed.stderr).strip()[-500:]}'
            self.code_cache[key] = reason
            raise gate_pool.NotReusable(reason)
        try:
            records = gate_pool.code_inputs(completed.stdout, self.source, self.input_hashes)
        except gate_pool.NotReusable as failure:
            self.code_cache[key] = str(failure)
            raise
        self.code_cache[key] = records
        return records

    def fixture_inputs(self):
        records = []
        for name, path in sorted(suite_fixtures(self.source).items()):
            records.append([name, str(Path(path).relative_to(self.source)),
                            gate_pool.sha256_file(path, self.input_hashes)])
        return records

    def external_inputs(self):
        tools = {}
        for path in (Path(__file__).resolve(), Path(gate_pool.__file__).resolve()):
            tools[path.name] = gate_pool.sha256_file(path, self.input_hashes)
        return dict(go_sum=gate_pool.sha256_file(self.source / 'go.sum', self.input_hashes),
                    go_mod=gate_pool.sha256_file(self.source / 'go.mod', self.input_hashes),
                    go_version=self.go_version(), toolchain=str(self.toolchain), tools=tools,
                    lists=dict(sorted(self.list_hashes.items())))

    def go_version(self):
        if self._go_version is None:
            completed = subprocess.run([self.tool('go'), 'version'], cwd=self.source, env=self.environment,
                                       capture_output=True, text=True, stdin=subprocess.DEVNULL)
            require(completed.returncode == 0, f'go version failed: {(completed.stdout + completed.stderr).strip()[-500:]}')
            self._go_version = completed.stdout.strip()
        return self._go_version

    def database_inputs(self, suite, package):
        # The unit suite creates no databases, so its units receive no DSN and the template is not an input.
        if suite == 'unit' or not self.dsn_by_package.get(package):
            return None
        return dict(template=self.template_key(TAG_SETS[self.suite_template(suite)]))

    def template_key(self, tags):
        cached = self.template_cache.get(tags)
        if cached is not None:
            if 'reason' in cached:
                raise gate_pool.NotReusable(cached['reason'])
            return cached['key']
        try:
            provision = ['internal/integration/publication']
            if 'river' in tags.split():
                provision.append('internal/adapters/river')
            key = hashlib.sha256(gate_pool.canonical_json(dict(
                migrations=gate_pool.directory_files(self.source / 'migrations', self.input_hashes),
                content=gate_pool.directory_files(self.source / 'internal/content/builtin/generated', self.input_hashes),
                provision=[hashlib.sha256(gate_pool.canonical_json(self.code_inputs(tags, package)).encode()).hexdigest()
                           for package in provision])).encode()).hexdigest()
        except gate_pool.NotReusable as failure:
            self.template_cache[tags] = dict(reason=str(failure))
            raise
        self.template_cache[tags] = dict(key=key)
        return key

    def binary_inputs(self):
        records = []
        for variable in sorted(self.census.get('binary', ())):
            path = self.environment.get(variable)
            if not path:
                continue
            records.append([variable, self.normalized_value(path), gate_pool.sha256_file(path, self.input_hashes)])
        return records

    def unit_inputs(self, suite, tags, unit, extra, skip):
        package = gate_pool.normalize_package(unit['package'])
        return dict(tags=self.build_tags(suite, tags), run=unit.get('run'), skip=skip, shard=unit.get('shard'),
                    shard_count=self.shard_count(package, unit),
                    timeout=gate_pool.unit_timeout(self.parallel, unit['package']),
                    environment=self.normalized_environment(package, extra))

    def build_tags(self, suite, tags):
        """A shared template's tags; -tags itself only selects files, which the code input already hashes."""
        if suite == 'unit':
            return tags
        return TAG_SETS[self.suite_template(suite)]

    def shard_count(self, package, unit):
        if unit.get('shard') is None:
            return 1
        counts = {gate_pool.normalize_package(key): value for key, value in self.parallel.get('shards', {}).items()}
        return counts.get(package, 1)

    def normalized_environment(self, package, extra):
        pairs = {**self.environment, **extra}
        pairs['GXB_I7B5B_ASSET_ROOT'] = '<MEDIA_ROOT>'
        for variable in sorted(self.dsn_by_package.get(package, ())):
            pairs[variable] = '<DATABASE_DSN>'
        return [[name, self.normalized_value(value)] for name, value in sorted(pairs.items())]

    def normalized_value(self, value):
        return str(value).replace(str(self.work), '<WORK>').replace(str(self.port), '<PORT>')

    def reserve_fingerprint(self, fingerprint, started):
        with self.reuse_lock:
            holder = self.reuse_in_run.get(fingerprint)
            if holder is not None:
                return holder, False
            holder = dict(event=threading.Event(), started=started, outcomes=None)
            self.reuse_in_run[fingerprint] = holder
            return holder, True

    def stored_unit(self, fingerprint):
        path = self.reuse_store / f'{fingerprint}.json'
        if not path.is_file():
            return None
        try:
            document = json.loads(path.read_text())
            if not isinstance(document, dict):
                raise ValueError('not a JSON object')
            if document.get('fingerprint') != fingerprint:
                raise ValueError('fingerprint field differs from the file name')
            if hashlib.sha256(gate_pool.canonical_json(document['inputs']).encode()).hexdigest() != fingerprint:
                raise ValueError('stored inputs do not hash to the file name')
            outcomes = document['outcomes']
            if not isinstance(outcomes, dict) or not all(isinstance(outcome, str) for outcome in outcomes.values()):
                raise ValueError('outcomes are not a test-to-outcome object')
            source = {name: document[name] for name in ('commit', 'report', 'started')}
            if not all(isinstance(value, str) for value in source.values()):
                raise ValueError('commit, report and started must be strings')
        except (OSError, ValueError, KeyError, TypeError) as failure:
            message = f'reuse: ignoring store file {path}: {failure}'
            self.reuse_ignored.append(message)
            print(message, flush=True)
            return None
        return {**source, 'outcomes': outcomes}

    def store_unit(self, fingerprint, inputs, started, outcomes):
        document = dict(fingerprint=fingerprint, inputs=inputs, commit=self.commit,
                        report=str(self.work / 'STRICT_GATE.json'), started=started, outcomes=outcomes)
        self.reuse_store.mkdir(parents=True, exist_ok=True)
        path = self.reuse_store / f'{fingerprint}.json'
        temporary = self.reuse_store / f'.{fingerprint}.{threading.get_ident()}.tmp'
        temporary.write_text(json.dumps(document, indent=1, sort_keys=True) + '\n')
        temporary.replace(path)

    def storable(self, code, outcomes, broken_packages):
        if code != 0 or broken_packages:
            return False
        return all(outcome == 'pass' or (outcome == 'skip' and test in self.allowlist)
                   for test, outcome in outcomes.items())

    def record_reuse(self, name, unit, source, began):
        outcomes = source['outcomes']
        self.merge_unit_outcomes(f'suite:{name}', unit['unit'], outcomes, set())
        row = dict(name=f'unit:{name}:{unit["unit"]}', exit=0, tests=len(outcomes),
                   reused_from=dict(commit=source['commit'], report=source['report'], started=source['started']),
                   seconds=round(time.perf_counter() - began, 3))
        with self.unit_lock:
            self.steps.append(row)
            self.reused_units += 1
        print(f'{row["name"]} reused {dict(collections.Counter(outcomes.values()))}', flush=True)

    def run_unit(self, name, tags, unit, extra, skip):
        label = f'suite:{name}'
        stream = self.work / 'runs' / f'suite_{name}' / f'{unit["unit"]}.jsonl'
        began = time.perf_counter()
        started = datetime.datetime.now(datetime.timezone.utc).isoformat()
        fingerprint = inputs = None
        holder, runner = None, False
        try:
            fingerprint, inputs = self.unit_fingerprint(name, tags, unit, extra, skip)
        except (gate_pool.NotReusable, OSError) as failure:
            print(f'reuse: unit {unit["unit"]} NOT_REUSABLE: {failure}', flush=True)
        if fingerprint is not None:
            if self.reuse:
                stored = self.stored_unit(fingerprint)
                if stored is not None:
                    self.record_reuse(name, unit, stored, began)
                    return
            holder, runner = self.reserve_fingerprint(fingerprint, started)
            if not runner:
                holder['event'].wait()
                first = holder['outcomes']
                if first is not None:
                    self.record_reuse(name, unit, dict(commit=self.commit, report=str(self.work / 'STRICT_GATE.json'),
                                                       started=holder['started'], outcomes=first), began)
                    return
        storable_outcomes = None
        try:
            try:
                environment = self.unit_environment(name, unit, extra)
                arguments = gate_pool.go_test_command(self.tool('go'), tags, [unit['package']], run=unit['run'], skip=skip,
                                                      timeout_minutes=gate_pool.unit_timeout(self.parallel, unit['package']))
                with stream.open('w') as output:
                    code = subprocess.run(arguments, cwd=self.source, env=environment, stdout=output,
                                          stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL).returncode
                outcomes, failed_packages = gate_pool.parse_go_test_json(stream, self.module)
            except (gate_pool.PoolError, OSError) as failure:
                with self.unit_lock:
                    self.red.append(f'{label}: unit {unit["unit"]}: {failure}')
                    self.steps.append(dict(name=f'unit:{name}:{unit["unit"]}', exit=None, error=str(failure),
                                           seconds=round(time.perf_counter() - began, 3)))
                return
            if code != 0 and not outcomes and not failed_packages:
                # A unit killed without events (OOM, SIGKILL) would otherwise drop its tests silently.
                with self.unit_lock:
                    self.red.append(f'{label}: unit {unit["unit"]} exited {code} without test events')
            failing_packages = {key.rsplit('.', 1)[0] for key, outcome in outcomes.items() if outcome in ('fail', 'incomplete')}
            self.merge_unit_outcomes(label, unit['unit'], outcomes, failed_packages - failing_packages)
            row = dict(name=f'unit:{name}:{unit["unit"]}', exit=code, stream=str(stream.relative_to(self.work)),
                       tests=len(outcomes), seconds=round(time.perf_counter() - began, 3))
            with self.unit_lock:
                self.steps.append(row)
                self.run_units += 1
            print(f'{row["name"]} {code} {dict(collections.Counter(outcomes.values()))}', flush=True)
            if fingerprint is not None and self.storable(code, outcomes, failed_packages - failing_packages):
                self.store_unit(fingerprint, inputs, started, outcomes)
                storable_outcomes = outcomes
        finally:
            if holder is not None:
                with self.reuse_lock:
                    holder['outcomes'] = storable_outcomes
                    holder['event'].set()

    def merge_unit_outcomes(self, label, unit_name, outcomes, broken_packages):
        with self.unit_lock:
            merged = self.runs.setdefault(label, {})
            for test, outcome in outcomes.items():
                if test in merged:
                    self.red.append(f'{test}: seen in two units of {label} ({unit_name})')
                    continue
                merged[test] = outcome
            for package in sorted(broken_packages):
                if package not in self.package_failures[label]:
                    self.package_failures[label].append(package)

    def recipe_test(self, recipe, step, package, pattern, extra, cwd=None):
        outcomes = self.go_test(f'recipe:{recipe}:{step}', FULL_TAGS, [package], extra, run=pattern, cwd=cwd)
        unexpected = {key: outcome for key, outcome in outcomes.items() if outcome != 'pass' and not (outcome == 'skip' and key in self.allowlist)}
        only_debt = unexpected and all(outcome == 'fail' and key in self.known_debt for key, outcome in unexpected.items())
        if only_debt:
            raise BlockedByKnownDebt(f'step {step}: {sorted(unexpected)}')
        require('pass' in outcomes.values() and not unexpected, f'recipe {recipe} step {step}: {unexpected or outcomes}')

    def seed_restart_restore(self, recipe, package, seed, check, seed_extra, check_extra):
        dsn = self.database(recipe.replace('-', '_'))
        self.recipe_test(recipe, 'seed', package, seed, {**self.every_dsn(dsn), **seed_extra})
        dump = self.dump(recipe, dsn)
        self.cluster('restart')
        self.recipe_test(recipe, 'restart', package, check, {**self.every_dsn(dsn), **check_extra})
        restored = self.restore(recipe.replace('-', '_') + '_restored', dump)
        self.recipe_test(recipe, 'restore', package, check, {**self.every_dsn(restored), **check_extra})

    def recipe_directory(self, recipe):
        directory = self.work / 'recipes' / recipe
        directory.mkdir(exist_ok=True)
        return directory

    def recipe_socialrelation_recovery(self, recipe):
        record = {'GXB_I7A4B_RECOVERY_RECORD': str(self.recipe_directory(recipe) / 'record')}
        self.seed_restart_restore(recipe, './internal/integration/socialrelation', '^TestRecoverySeed$',
                                  '^TestRecoveryReadOnlyReplayProof$', record, record)

    def recipe_socialprojection_recovery(self, recipe):
        expected = {'GXB_I7A4C_RECOVERY_EXPECTED': str(self.recipe_directory(recipe) / 'expected.json')}
        self.seed_restart_restore(recipe, './internal/integration/socialprojection', '^TestC21RecoverySeed$', '^TestC21RecoveryCompare$',
                                  {**expected, 'GXB_I7A4C_RECOVERY_MODE': 'seed'}, {**expected, 'GXB_I7A4C_RECOVERY_MODE': 'compare'})

    def recipe_gift_recovery(self, recipe):
        output = {'GXB_I7A7A_RECOVERY_OUTPUT': str(self.recipe_directory(recipe))}
        self.seed_restart_restore(recipe, './internal/integration/socialactivation', '^Test7A_RecoverySeedCompare$', '^Test7A_RecoverySeedCompare$',
                                  {**output, 'GXB_I7A7A_RECOVERY_MODE': 'seed'}, {**output, 'GXB_I7A7A_RECOVERY_MODE': 'compare'})

    def recipe_combined_recovery(self, recipe):
        output = {'GXB_I7A7B_RECOVERY_OUTPUT': str(self.recipe_directory(recipe))}
        pattern = '^Test7B_CombinedRecoverySeedCompare$'
        self.seed_restart_restore(recipe, './internal/integration/socialactivation', pattern, pattern,
                                  {**output, 'GXB_I7A7B_RECOVERY_MODE': 'seed'}, {**output, 'GXB_I7A7B_RECOVERY_MODE': 'compare'})

    def recipe_dm_migration_fixture(self, recipe):
        pattern = '^Test6B_G07MigrationRecoveryFixture$'
        self.seed_restart_restore(recipe, './internal/integration/socialactivation', pattern, pattern,
                                  {'GXB6B_MIGRATION_FIXTURE': 'seed'}, {'GXB6B_MIGRATION_FIXTURE': 'restore'})

    def recipe_populated32_upgrade(self, recipe):
        dsn = self.database('populated32_upgrade', migrate=('up-to', '32'), deploy=False)
        extra = {**self.every_dsn(dsn), 'GXB_I7A4D_EXPECTED': str(self.recipe_directory(recipe) / 'expected.json')}
        package = './internal/integration/socialactivation'
        self.recipe_test(recipe, 'seed', package, '^TestD12UpgradePopulated32Seed$', {**extra, 'GXB_I7A4D_MODE': 'upgrade_seed'})
        self.migrate_current(recipe, dsn)
        self.recipe_test(recipe, 'compare', package, '^TestD12UpgradePopulated32Compare$', {**extra, 'GXB_I7A4D_MODE': 'upgrade_compare'})
        self.migrate_current(recipe + '-repeat', dsn)

    def accepted35_dump(self):
        """Database at migration 00035 with the content the accepted 00035 product installed at API startup (revision 66dddbab...)."""
        if self.accepted35:
            return self.accepted35
        old = self.export(ACCEPTED35_COMMIT, 'accepted35')
        dsn = self.database('accepted35_build', cwd=old, deploy=False)
        binary = self.work / 'binaries/accepted35-gxb-api'
        self.step('build-binary:accepted35-gxb-api', [self.tool('go'), 'build', '-buildvcs=false', '-tags', 'postgres', '-o', binary, './cmd/gxb-api'], cwd=old)
        api, world = free_address(), free_address()
        secrets = {'GXB_CREDENTIAL_DIGEST_SECRET': 'strict-gate-digest-secret-long', 'GXB_GAMEPLAY_BEARER_SECRET': 'strict-gate-bearer-secret-long',
                   'GXB_REDEEM_DIGEST_SECRET': 'strict-gate-redeem-secret-long', 'GXB_DERIVATION_KEY_ID': 'fixture'}
        process_environment = {**self.environment, **secrets, 'GXB_POSTGRES_DSN': dsn, 'GXB_HTTP_ADDR': api, 'GXB_PUBLIC_ENGINE_URL': f'http://{api}/',
                               'GXB_REALTIME_ADDR': world, 'GXB_REALTIME_PUBLIC_HOST': '127.0.0.1', 'GXB_REALTIME_PUBLIC_PORT': world.split(':')[1]}
        log = (self.work / 'logs/accepted35-api.log').open('w')
        process = subprocess.Popen([str(binary)], cwd=old, env=process_environment, stdout=log, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL)
        try:
            revision = ''
            for _ in range(240):
                revision = self.sql(dsn, 'SELECT coalesce(max(revision_id), \'\') FROM gxb_content_activation')
                if revision or process.poll() is not None:
                    break
                time.sleep(0.5)
        finally:
            process.terminate()
            process.wait(timeout=60)
            log.close()
        require(revision == ACCEPTED35_REVISION, f'accepted35 API startup installed revision {revision!r}')
        self.accepted35 = self.dump('accepted35', dsn)
        return self.accepted35

    def recipe_accepted35_upgrade(self, recipe):
        dsn = self.restore('accepted35_upgrade', self.accepted35_dump())
        self.migrate_current(recipe, dsn)
        self.recipe_test(recipe, 'upgraded', './internal/integration/socialactivation', '^Test7A_UpgradeActivationCompatibility$',
                         {**self.every_dsn(dsn), 'GXB_I7A7A_UPGRADE_MODE': '1'})

    def recipe_populated35_deployment(self, recipe):
        dsn = self.restore('populated35_deployment', self.accepted35_dump())
        self.recipe_test(recipe, 'seed', './internal/integration/socialactivation', '^Test7B_DeploymentPopulated35Seed$',
                         {**self.every_dsn(dsn), 'GXB_I7A7B_DEPLOYMENT_MODE': 'seed'})
        self.migrate_current(recipe, dsn)
        self.deploy(recipe, dsn)
        self.recipe_test(recipe, 'deployed', './internal/integration/socialactivation',
                         '^Test7B_ExplicitDeploymentActivationPreservesStartupContract$', {**self.every_dsn(dsn), 'GXB_I7A7B_DEPLOYMENT_MODE': '1'})

    def recipe_populated59_upgrade(self, recipe):
        require(self.populated59.is_file(), f'populated59 dump {self.populated59} missing')
        require(hashlib.file_digest(self.populated59.open('rb'), 'sha256').hexdigest() == POPULATED59_SHA256, 'populated59 dump sha256 mismatch')
        dsn = self.restore('populated59_upgrade', self.populated59)
        old = self.sql(dsn, 'SELECT revision_id FROM gxb_content_activation')
        self.migrate_current(recipe, dsn)
        self.deploy(recipe, dsn)
        require(self.sql(dsn, 'SELECT revision_id FROM gxb_content_activation') != old, 'content deploy kept the populated59 revision')
        self.recipe_test(recipe, 'upgraded', './internal/integration/playerdisplay', '^TestI7C4ANativeUpgradeTemporalUsesOriginalDescriptor$',
                         {**self.every_dsn(dsn), 'GXB_I7C4A_UPGRADE_OLD_REVISION': old})

    def restored_reload(self, recipe, package, seed_extra, checks):
        dsn = self.database(recipe.replace('-', '_'))
        outcomes = self.go_test(f'recipe:{recipe}:seed-suite', FULL_TAGS, [package], {**self.every_dsn(dsn), **seed_extra})
        unexpected = {key: outcome for key, outcome in outcomes.items() if outcome in ('fail', 'incomplete') and key not in self.known_debt}
        require(outcomes and not unexpected, f'recipe {recipe} seed suite failures outside known debt: {unexpected}')
        dump = self.dump(recipe, dsn)
        self.cluster('restart')
        for variable, pattern in checks:
            self.recipe_test(recipe, f'restart-{variable}', package, pattern, {**self.every_dsn(dsn), variable: '1'})
        restored = self.restore(recipe.replace('-', '_') + '_restored', dump)
        for variable, pattern in checks:
            self.recipe_test(recipe, f'restore-{variable}', package, pattern, {**self.every_dsn(restored), variable: '1'})

    def recipe_restored_reload_publicprofilecommands(self, recipe):
        self.restored_reload(recipe, './internal/integration/publicprofilecommands', {},
                             [('GXB_I7B2B_RESTORED', '^TestRestoredTypedOwnerPolicyReceiptReload$')])

    def recipe_restored_reload_publicshowcase(self, recipe):
        self.restored_reload(recipe, './internal/integration/publicshowcase', {},
                             [('GXB_I7B3A_RESTORED', '^TestRestoredSelectionPolicyReceiptReload$'), ('GXB_BOOKMARK_RESTORED', '^TestBookmarkRestoredReload$')])

    def recipe_restored_reload_profilefeedback(self, recipe):
        self.restored_reload(recipe, './internal/integration/profilefeedback', {'GXB_I7B4B_FINAL': '1'},
                             [('GXB_I7B4A_RESTORED', '^TestPraiseRestoredReload$'), ('GXB_I7B4B_RESTORED', '^TestCommentRestoredReload$')])

    def recipe_restored_reload_publicprofilefoundation(self, recipe):
        self.restored_reload(recipe, './internal/integration/publicprofilefoundation', {}, [('GXB_I7B2A_RESTORED', '^TestRestoredOwnerReload$')])

    def recipe_restored_reload_profilemedia(self, recipe):
        self.restored_reload(recipe, './internal/integration/profilemedia', {}, [('GXB_I7B5B_RESTORED', '.')])

    def recipe_league_recovered(self, recipe):
        dsn = self.database('league_recovered')
        package = './internal/integration/playerdisplay'
        self.recipe_test(recipe, 'populate', package, '^TestI7C5FLeague(Genuine|Daily|Bubble|Admission)', self.every_dsn(dsn))
        restored = self.restore('league_recovered_restored', self.dump(recipe, dsn))
        self.cluster('restart')
        self.recipe_test(recipe, 'restored', package, '^TestI7C5FLeagueRecoveredRowsNative$', self.every_dsn(restored))

    def recipe_legacy_combat_upgrade(self, recipe):
        previous = self.export(PREVIOUS_PRODUCT_COMMIT, 'previous-product')
        dsn = self.database('legacy_combat_upgrade', cwd=previous, deploy=False)
        self.deploy(recipe + '-previous', dsn, cwd=previous)
        self.recipe_test(recipe, 'populate-previous', './internal/integration/playerdisplay', PREVIOUS_PRODUCT_POPULATE, self.every_dsn(dsn), cwd=previous)
        self.migrate_current(recipe, dsn)
        self.deploy(recipe, dsn)
        self.recipe_test(recipe, 'upgraded', './internal/integration/playerdisplay', '^TestI8_4UpgradedRowsReadableNative$',
                         {**self.every_dsn(dsn), 'GXB_I8_4_EXPECT_LEGACY': '1'})

    def recipe_mission_content47_upgrade(self, recipe):
        previous = self.export(MISSION_CONTENT47_COMMIT, 'mission-content47')
        dsn = self.database('mission_content47_upgrade', cwd=previous, deploy=False)
        self.deploy(recipe + '-previous', dsn, cwd=previous)
        self.migrate_current(recipe, dsn)
        self.deploy(recipe, dsn)
        self.recipe_test(recipe, 'upgraded', './internal/integration/missions', MISSION_CONTENT47_TESTS, self.every_dsn(dsn))

    def recipe_forum_legacy_upgrade(self, recipe):
        previous = self.export(FORUM_LEGACY_MIGRATIONS_COMMIT, 'forum-legacy-schema111')
        legacy_migrations = previous / 'migrations'
        require(legacy_migrations.is_dir(), f'legacy forum migrations missing from {FORUM_LEGACY_MIGRATIONS_COMMIT}')
        dsn = self.database(recipe.replace('-', '_'))
        self.recipe_test(recipe, 'upgrade', './internal/integration/playerdisplay',
                         '^(TestI9_10BForumLegacy111To118Upgrade|TestI9_10BForumLegacyMismatchAborts)$',
                         {**self.every_dsn(dsn), 'GXB_I9_10B_LEGACY_MIGRATIONS': str(legacy_migrations)})

    def format(self):
        self.step('format', [self.tool('gofmt'), '-l', '.'])
        unformatted = (self.work / 'logs/format.log').read_text().split()
        require(not unformatted, f'gofmt -l lists {unformatted}')

    def reply_conformance_scan(self, directory):
        """The e2e/VC gxb-api logs must contain no reply_conformance_violation line (C3 item 5)."""
        root = Path(directory).resolve()
        logs = sorted(path for path in root.rglob('*.log') if path.is_file())
        require(logs, f'reply-conformance: no gxb-api logs under {root}')
        violations = []
        for path in logs:
            for number, line in enumerate(path.read_text(errors='replace').splitlines(), 1):
                if REPLY_CONFORMANCE_VIOLATION in line:
                    violations.append(f'{path.relative_to(root)}:{number}: {line.strip()}')
        require(not violations, f'reply-conformance: {len(violations)} violation line(s): ' + ' | '.join(violations[:10]))
        print(f'reply-conformance: {len(logs)} gxb-api log(s), zero violations', flush=True)

    @staticmethod
    def cpu_temperature(temperatures):
        for name, value in temperatures.items():
            if name.endswith('Tctl'):
                return value
        return max(temperatures.values(), default=0.0)

    @staticmethod
    def running_worker_clusters():
        found = []
        for pid_file in (WORKSPACE / 'tmp/worker_clusters').glob('*/data/postmaster.pid'):
            try:
                pid = int(pid_file.read_text().splitlines()[0])
            except (OSError, ValueError, IndexError):
                continue
            if Path(f'/proc/{pid}').exists():
                found.append(str(pid_file))
        return found

    @staticmethod
    def process_parent(pid):
        try:
            return int(Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()[1])
        except (OSError, ValueError, IndexError):
            return None

    def descendant_of_gate(self, pid):
        while pid and pid > 1:
            if pid == os.getpid():
                return True
            pid = self.process_parent(pid)
        return False

    def other_go_test_processes(self):
        found = []
        for command_line in Path('/proc').glob('[0-9]*/cmdline'):
            try:
                pid = int(command_line.parent.name)
                parts = [part.decode(errors='replace') for part in command_line.read_bytes().split(b'\0') if part]
            except (OSError, ValueError):
                continue
            if len(parts) < 2 or Path(parts[0]).name != 'go' or 'test' not in parts[1:4]:
                continue
            if self.descendant_of_gate(pid):
                continue
            found.append(f'{pid}: {" ".join(parts[:4])}')
        return found

    def latency_breaches(self, reading):
        settings = self.latency_settings()
        found = []
        load = reading.get('load_average') or (0,)
        if load[0] >= settings['load_average_max']:
            found.append(f'load average {load[0]:.2f} >= {settings["load_average_max"]}')
        temperature = self.cpu_temperature(reading.get('temperatures_celsius') or {})
        if temperature >= settings['temperature_celsius_max']:
            found.append(f'temperature {temperature:.1f} C >= {settings["temperature_celsius_max"]} C')
        reference = settings['benchmark_reference_seconds']
        measured = reading.get('baseline_sha256_64mib_seconds')
        if measured:
            deviation = abs(measured - reference) / reference
            if deviation > settings['benchmark_tolerance']:
                found.append(f'benchmark {measured}s differs from reference {reference}s by {deviation:.1%}')
        if reading.get('worker_clusters'):
            found.append('worker cluster running: ' + ', '.join(reading['worker_clusters']))
        if reading.get('go_test_processes'):
            found.append('other go test process: ' + '; '.join(reading['go_test_processes']))
        return found

    def latency_reading(self):
        reading = host_conditions()
        reading['worker_clusters'] = self.running_worker_clusters()
        reading['go_test_processes'] = self.other_go_test_processes()
        reading['breaches'] = self.latency_breaches(reading)
        return reading

    @staticmethod
    def acquire_quiet_lock():
        QUIET_LOCK.parent.mkdir(parents=True, exist_ok=True)
        handle = QUIET_LOCK.open('a')
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            handle.close()
            return None
        return handle

    @staticmethod
    def release_quiet_lock(handle):
        if handle is None:
            return
        try:
            fcntl.flock(handle, fcntl.LOCK_UN)
        finally:
            handle.close()

    def wait_for_latency_conditions(self):
        """Hold the host quiet lock and wait until every condition has held for the cool-down, or the wait expires."""
        settings = self.latency_settings()
        deadline = time.monotonic() + settings['wait_minutes'] * 60
        held_since, readings, handle = None, [], None
        while True:
            if handle is None:
                handle = self.acquire_quiet_lock()
            reading = self.latency_reading()
            if handle is None:
                reading['breaches'].append('quiet lock not held by the gate')
            readings.append(reading)
            if not reading['breaches']:
                if held_since is None:
                    held_since = time.monotonic()
                if time.monotonic() - held_since >= settings['cooldown_seconds']:
                    return handle, readings, True
            else:
                held_since = None
                self.release_quiet_lock(handle)
                handle = None
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                self.release_quiet_lock(handle)
                return None, readings, False
            time.sleep(min(settings['check_interval_seconds'], remaining))

    def monitor_latency_conditions(self, stop, breaches):
        while not stop.wait(self.latency_settings()['check_interval_seconds']):
            reading = self.latency_reading()
            if reading['breaches']:
                breaches.append(reading)
                return
        return

    def latency_groups(self):
        groups = collections.OrderedDict()
        for member in self.latency_settings()['members']:
            groups.setdefault((member['package'], member['tags']), []).append(member['test'])
        return groups

    def run_latency_members(self):
        settings = self.latency_settings()
        member_keys = {f'{gate_pool.normalize_package(member["package"])}.{member["test"]}'
                       for member in settings['members']}
        for test, entry in sorted(self.allowlist.items()):
            if entry['kind'] == LATENCY_DEFERRED and test not in member_keys:
                self.latency_red.append(f'{test}: latency_deferred allowlist entry names no latency-population member')
        for index, ((package, tags), tests) in enumerate(self.latency_groups().items()):
            extra = dict(suite_fixtures(self.source))
            extra.update({'GXB_LATENCY_SECTION': '1',
                          'GXB_LATENCY_GENERAL_CEILING_FACTOR': str(settings['general_ceiling_factor']),
                          'GXB_I8_LATENCY_REPETITIONS': str(LATENCY_REPETITIONS)})
            asset_root = self.work / 'media' / f'latency_{index}'
            asset_root.mkdir(mode=0o700, exist_ok=True)
            extra['GXB_I7B5B_ASSET_ROOT'] = str(asset_root)
            for variable in sorted(self.dsn_by_package.get(gate_pool.normalize_package(package), ())):
                extra[variable] = self.database(gate_pool.database_name('latency', f'{index:02d}', variable))
            label = f'latency:{index}'
            outcomes = self.go_test(label, tags, [package], extra, run='^(' + '|'.join(tests) + ')$', record=False)
            self.latency_runs[label] = outcomes
            for test in tests:
                key = f'{gate_pool.normalize_package(package)}.{test}'
                outcome = outcomes.get(key, 'did not run')
                if outcome != 'pass':
                    self.latency_red.append(f'{key}: {outcome}')

    def latency_section(self):
        """The population runs only while the measured host conditions hold; a breach makes the section NOT_RUN, never RED."""
        self.latency_red, self.latency_runs = [], {}
        handle, readings, held = self.wait_for_latency_conditions()
        self.latency_conditions = readings
        if not held:
            self.latency_verdict = 'NOT_RUN'
            return
        breaches, stop = [], threading.Event()
        monitor = threading.Thread(target=self.monitor_latency_conditions, args=(stop, breaches), daemon=True)
        monitor.start()
        try:
            self.run_latency_members()
        finally:
            stop.set()
            monitor.join()
            after = self.latency_reading()
            self.latency_conditions.append(after)
            self.release_quiet_lock(handle)
        if breaches or after['breaches']:
            self.latency_verdict = 'NOT_RUN'
            return
        self.latency_verdict = 'RED' if self.latency_red else 'GREEN'

    def recipes(self):
        return [(name.removeprefix('recipe_').replace('_', '-'), getattr(self, name)) for name in dir(self) if name.startswith('recipe_')
                and name not in ('recipe_test', 'recipe_directory')]

    def guarded(self, unit, action, *arguments):
        if not self.selected(unit):
            return
        try:
            action(*arguments)
        except BlockedByKnownDebt as blocked:
            self.blocked[unit] = str(blocked)
        except (GateFailure, subprocess.CalledProcessError, gate_pool.PoolError) as failure:
            self.red.append(f'{unit}: {failure}')

    def run(self):
        missing = [name for name in TOOLS if not (self.toolchain / 'bin' / name).exists()]
        require(not missing, f'toolchain lacks {missing}')
        self.orchestration_variables = {'GXB_I7A4B_RECOVERY_RECORD', 'GXB_I7A4C_RECOVERY_MODE', 'GXB_I7A4C_RECOVERY_EXPECTED', 'GXB_I7A7A_RECOVERY_MODE',
                                 'GXB_I7A7A_RECOVERY_OUTPUT', 'GXB_I7A7B_RECOVERY_MODE', 'GXB_I7A7B_RECOVERY_OUTPUT', 'GXB6B_MIGRATION_FIXTURE',
                                 'GXB_I7A4D_MODE', 'GXB_I7A4D_EXPECTED', 'GXB_I7A7A_UPGRADE_MODE', 'GXB_I7A7B_DEPLOYMENT_MODE',
                                 'GXB_I7C4A_UPGRADE_OLD_REVISION', 'GXB_I7B2B_RESTORED', 'GXB_I7B3A_RESTORED', 'GXB_BOOKMARK_RESTORED',
                                 'GXB_I9_10B_LEGACY_MIGRATIONS', 'GXB_I7B4A_RESTORED', 'GXB_I7B4B_RESTORED', 'GXB_I7B2A_RESTORED', 'GXB_I7B5B_RESTORED', 'GXB_I7B4B_FINAL', 'GXB_I8_4_EXPECT_LEGACY', 'GXB_I7A9_PREPARE_PROCESS',
                                 'GXB_I8_LATENCY_REPETITIONS'}
        self.census_of_test_variables()
        self.dsn_by_package = gate_pool.dsn_variables_by_package(self.source)
        self.red += [f'census: test variable {variable} is neither provisioned, recipe-owned nor set by a parent test'
                     for variable in self.census.get('unclassified', [])]
        test_locations = {location for locations in self.test_functions.values() for location in locations}
        if self.mode == 'parallel':
            self.red += [f'parallel: serial test {key} names no test function'
                         for key in self.parallel.get('serial_tests', []) if key not in test_locations]
            if self.parallel.get('timeouts'):
                self.validate_timeout_packages(self.existing_packages())
        self.build_binaries()
        self.cluster('init')
        self.cluster('start')
        try:
            if self.section in ('general', 'both'):
                self.general_section()
            if self.section in ('latency', 'both'):
                try:
                    self.latency_section()
                except (GateFailure, subprocess.CalledProcessError, gate_pool.PoolError) as failure:
                    self.latency_red.append(f'latency: {failure}')
                    self.latency_verdict = 'RED'
        finally:
            self.cluster('stop')

    def general_section(self):
        self.guarded('format', self.format)
        for name, tags in BUILD_ONLY_TAG_SETS.items():
            self.guarded(f'build:{name}', self.step, f'build:{name}', [self.tool('go'), 'build', '-buildvcs=false', '-tags', tags, './...'])
        for name, tags in TAG_SETS.items():
            if self.mode == 'parallel':
                self.guarded(f'suite:{name}', self.suite_parallel, name, tags)
            else:
                self.guarded(f'suite:{name}', self.suite, name, tags)
        if self.api_logs:
            self.guarded('reply-conformance', self.reply_conformance_scan, self.api_logs)
        else:
            print('reply-conformance: no --api-logs given; e2e/VC log scan skipped', flush=True)
        for name, recipe in self.recipes():
            self.guarded(f'recipe:{name}', recipe, name)

    def classify(self):
        seen = collections.defaultdict(dict)
        for label, outcomes in {**self.runs, **getattr(self, 'latency_runs', {})}.items():
            for test, outcome in outcomes.items():
                seen[test][label] = outcome
        full = self.select is None
        complete_general = getattr(self, 'section', 'both') in ('general', 'both')
        tests = {}
        for test, runs in sorted(seen.items()):
            findings = []
            entry = self.allowlist.get(test)
            for label, outcome in runs.items():
                if label.startswith('latency:'):
                    continue
                findings += self.finding(test, label, outcome, entry, seen)
            debt_failing = any(outcome == 'fail' for outcome in runs.values())
            if test in self.known_debt and full and not debt_failing:
                findings.append('DEBT_REPAID: passes everywhere; remove it from tools/strict_gate/known_debt.json')
            tests[test] = dict(runs=runs, status='RED' if findings else self.green_status(test, runs), findings=findings)
            self.red += [f'{test}: {finding}' for finding in findings]
        for test, entry in self.allowlist.items():
            if entry['kind'] == LATENCY_DEFERRED:
                # The latency section verifies its own members ran; a general-only run cannot see that report.
                continue
            owner_ran = any(label.startswith(entry.get('owner', '-')) and self.ran(test, outcome) for label, outcome in seen.get(test, {}).items())
            if full and complete_general and entry['kind'] not in ('child_helper', 'operator') and not owner_ran and entry.get('owner') not in self.blocked:
                self.red.append(f'{test}: allowlisted for {entry["owner"]} but no {entry["owner"]} run ran it')
            if full and complete_general and test not in seen and entry['kind'] != 'operator':
                self.red.append(f'{test}: allowlist entry names a test no run saw')
        for test in self.known_debt:
            if full and complete_general and test not in seen:
                self.red.append(f'{test}: known-debt entry names a test no run saw')
        for label, packages in self.package_failures.items():
            self.red += [f'{label}: package {package} failed without a failing test (build, TestMain or panic)' for package in packages]
        return tests

    def finding(self, test, label, outcome, entry, seen):
        if outcome == 'incomplete':
            return [f'INCOMPLETE in {label} (timeout or crash)']
        if outcome == 'fail' and test not in self.known_debt:
            return [f'NEW_FAILURE in {label}']
        if outcome == 'pass' and entry and label.startswith('suite:'):
            return [f'STALE_ALLOWLIST: ran and passed in {label}']
        if outcome != 'skip':
            return []
        if not entry:
            return [f'UNLISTED_SKIP in {label}']
        if entry['kind'] != 'child_helper':
            return []
        owner_outcomes = {owner: seen.get(owner, {}).get(label) for owner in entry['owners']}
        owner_ran = any(self.ran(owner, outcome) for owner, outcome in owner_outcomes.items())
        return [] if owner_ran else [f'CHILD_OWNER_NOT_RUN in {label}: {owner_outcomes}']

    def ran(self, test, outcome):
        return outcome == 'pass' or (outcome == 'fail' and test in self.known_debt)

    def green_status(self, test, runs):
        if any(outcome == 'fail' for outcome in runs.values()):
            return 'KNOWN_DEBT_FAILING'
        if any(outcome == 'skip' for outcome in runs.values()):
            return 'ALLOWLISTED_SKIP'
        return 'PASS'

    def sections_report(self):
        sections = {}
        if self.section in ('general', 'both'):
            sections['general'] = dict(verdict='RED' if self.red else 'GREEN')
        if self.section in ('latency', 'both'):
            sections['latency'] = dict(verdict=self.latency_verdict or 'RED',
                                       conditions=getattr(self, 'latency_conditions', []))
        return sections

    def overall_verdict(self):
        if self.section == 'general':
            return 'RED' if self.red else 'PARTIAL_GREEN'
        if self.section == 'latency':
            return 'PARTIAL_GREEN' if self.latency_verdict == 'GREEN' else (self.latency_verdict or 'RED')
        if self.red or self.latency_verdict == 'RED':
            return 'RED'
        if self.latency_verdict != 'GREEN':
            return 'NOT_RUN'
        if self.select is not None or self.packages is not None:
            return 'PARTIAL_GREEN'
        return 'GREEN'

    def report(self, started):
        tests = self.classify()
        verdict = self.overall_verdict()
        report = dict(contract='I85_STRICT_GATE_V1', verdict=verdict, commit=self.commit, toolchain=str(self.toolchain), started=started,
                      finished=datetime.datetime.now(datetime.timezone.utc).isoformat(), mode=self.mode, jobs=self.jobs,
                      sections=self.sections_report(),
                      lists=self.list_hashes, selection=self.select.pattern if self.select else None,
                      packages=self.packages,
                      reuse=dict(reused_units=self.reused_units, run_units=self.run_units,
                                 store=str(self.reuse_store), ignored=list(self.reuse_ignored)),
                      census=self.census, red=self.red + self.latency_red, latency_red=self.latency_red,
                      blocked_by_known_debt=self.blocked, steps=self.steps,
                      counts=dict(collections.Counter(row['status'] for row in tests.values())),
                      known_debt=dict(entries=len(self.known_debt), failing=sum(row['status'] == 'KNOWN_DEBT_FAILING' for row in tests.values())),
                      tests=tests)
        (self.work / 'STRICT_GATE.json').write_text(json.dumps(report, indent=1) + '\n')
        print(f'STRICT_GATE {verdict} {self.work / "STRICT_GATE.json"} red={len(report["red"])} counts={report["counts"]}')
        return verdict in ('GREEN', 'PARTIAL_GREEN')


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    for name in ['--toolchain', '--cache', '--work', '--populated59-dump']:
        parser.add_argument(name, required=True)
    parser.add_argument('--commit', default='HEAD')
    parser.add_argument('--port', default='55561')
    parser.add_argument('--select')
    parser.add_argument('--mode', choices=('serial', 'parallel'), default='serial')
    parser.add_argument('--section', choices=('both', 'general', 'latency'), default='both',
                        help='general excludes the latency population; latency runs it alone after checked conditions')
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--package', action='append')
    parser.add_argument('--previous')
    parser.add_argument('--api-logs', help='directory holding the e2e/VC gxb-api *.log files to scan for reply_conformance_violation')
    parser.add_argument('--reuse', action='store_true', help='parallel mode only: reuse stored unit results whose fingerprint matches')
    parser.add_argument('--reuse-store', default=str(DEFAULT_REUSE_STORE),
                        help='directory holding <fingerprint>.json unit results (default tmp/gate_results)')
    arguments = parser.parse_args()
    if arguments.jobs < 1:
        parser.error('--jobs must be positive')
    if arguments.reuse and arguments.mode != 'parallel':
        parser.error('--reuse requires --mode parallel; serial mode never reads the store')
    # SystemExit unwinds through run()'s finally, so a stopped gate still stops its cluster.
    signal.signal(signal.SIGTERM, lambda number, frame: sys.exit(128 + number))
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    gate = Gate(arguments)
    try:
        gate.run()
    except GateFailure as failure:
        gate.red.append(f'gate: {failure}')
    sys.exit(0 if gate.report(started) else 1)


if __name__ == '__main__':
    main()
