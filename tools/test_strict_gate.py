"""Self-check of the strict gate's classification rules and parallel units. Run: python3 -B tools/test_strict_gate.py"""
import collections
import json
import signal
import stat
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gate_pool
import strict_gate
from strict_gate import LATENCY_DEFAULTS, LATENCY_DEFERRED, Gate, GateFailure

DEBT = 'internal/a.TestDebt'
HELPER = 'internal/a.TestHelper'
PARENT = 'internal/a.TestParent'
SEEDED = 'internal/a.TestSeeded'
OPERATOR = 'internal/a.TestOperator'


def gate(runs, package_failures=None, known_debt=(DEBT,), blocked=None):
    instance = Gate.__new__(Gate)
    instance.select = None
    instance.red = []
    instance.runs = runs
    instance.package_failures = collections.defaultdict(list, package_failures or {})
    instance.known_debt = {test: {} for test in known_debt}
    instance.blocked = blocked or {}
    instance.pending_stores = []
    instance.unit_lock = threading.Lock()
    instance.allowlist = {HELPER: dict(test=HELPER, kind='child_helper', owners=[PARENT]),
                          SEEDED: dict(test=SEEDED, kind='recipe', owner='recipe:seed'),
                          OPERATOR: dict(test=OPERATOR, kind='operator', reason='manual proof')}
    return instance


def classified(runs, package_failures=None, known_debt=(DEBT,), blocked=None):
    instance = gate(runs, package_failures, known_debt, blocked)
    return instance.classify(), instance.red


green = {'suite:x': {DEBT: 'fail', HELPER: 'skip', PARENT: 'pass', SEEDED: 'skip'}, 'recipe:seed:one': {SEEDED: 'pass'}}
tests, red = classified(green)
assert not red, red
assert tests[DEBT]['status'] == 'KNOWN_DEBT_FAILING' and tests[HELPER]['status'] == 'ALLOWLISTED_SKIP', tests

_, red = classified({**green, 'suite:x': {**green['suite:x'], OPERATOR: 'skip'}})
assert not red, red

_, red = classified({**green, 'suite:x': {**green['suite:x'], OPERATOR: 'pass'}})
assert any('STALE_ALLOWLIST' in line for line in red), red

_, red = classified({**green, 'suite:x': {**green['suite:x'], 'internal/a.TestNew': 'fail'}})
assert any('NEW_FAILURE' in line for line in red), red

_, red = classified({**green, 'suite:x': {**green['suite:x'], DEBT: 'pass'}})
assert any('DEBT_REPAID' in line for line in red), red

_, red = classified({**green, 'suite:x': {**green['suite:x'], 'internal/a.TestQuiet': 'skip'}})
assert any('UNLISTED_SKIP' in line for line in red), red

_, red = classified({**green, 'suite:x': {**green['suite:x'], PARENT: 'skip'}})
assert any('CHILD_OWNER_NOT_RUN' in line for line in red), red

_, red = classified({**green, 'suite:x': {**green['suite:x'], SEEDED: 'pass'}})
assert any('STALE_ALLOWLIST' in line for line in red), red

_, red = classified({'suite:x': green['suite:x']})
assert any('no recipe:seed run ran it' in line for line in red), red

_, red = classified({**green, 'recipe:seed:one': {SEEDED: 'fail'}}, known_debt=(DEBT, SEEDED))
assert not red, red

_, red = classified({**green, 'recipe:seed:one': {SEEDED: 'fail'}})
assert any('NEW_FAILURE' in line for line in red), red

_, red = classified({'suite:x': green['suite:x']}, blocked={'recipe:seed': 'step one: [internal/a.TestEarlier]'})
assert not red, red

_, red = classified({**green, 'suite:x': {**green['suite:x'], 'internal/a.TestHung': 'incomplete'}})
assert any('INCOMPLETE' in line for line in red), red

_, red = classified(green, {'suite:x': ['internal/b']})
assert any('package internal/b failed' in line for line in red), red

FAKE_GO = '''#!/usr/bin/env python3
import json, os, re, sys
arguments = sys.argv[1:]
with open(os.environ['GATE_FAKE_LOG'], 'a') as log:
    log.write(json.dumps(arguments) + '\\n')

def option(name):
    return arguments[arguments.index(name) + 1] if name in arguments else None

def directory_files(directory, suffix):
    if not os.path.isdir(directory):
        return []
    return sorted(name for name in os.listdir(directory) if name.endswith(suffix) and not name.startswith('.'))

if arguments[0] == 'version':
    print('go version go1.27.3 linux/amd64')
elif arguments[0] == 'list':
    package = arguments[-1]
    if package.endswith('/...'):
        package = './internal/fake'
    relative = package.removeprefix('./')
    directory = os.path.join(os.environ.get('GATE_FAKE_SOURCE', '.'), relative)
    if option('-f') == '{{.ImportPath}}':
        print('example.com/mod/' + relative)
    else:
        go_files = [name for name in directory_files(directory, '.go') if not name.endswith('_test.go')]
        test_files = [name for name in directory_files(directory, '.go') if name.endswith('_test.go')]
        print(json.dumps({'ImportPath': 'example.com/mod/' + relative, 'Dir': directory, 'GoFiles': go_files,
                          'TestGoFiles': test_files, 'XTestGoFiles': [], 'CgoFiles': [], 'EmbedFiles': []}))
elif '-list' in arguments:
    print('TestAlpha')
    print('TestBeta')
    print('ok   example.com/mod/internal/fake   0.001s')
elif '-json' in arguments:
    package = 'example.com/mod/internal/fake'
    run, skip = option('-run'), option('-skip')
    mode = os.environ.get('GATE_FAKE_MODE', 'pass')
    for name in ('TestAlpha', 'TestBeta'):
        if mode == 'empty':
            continue
        if mode == 'partial' and name != 'TestAlpha':
            continue
        if run is not None and not re.search(run, name):
            continue
        if skip is not None and re.search(skip, name):
            continue
        record = os.environ.get('GXB_LATENCY_RECORD')
        if record and os.environ.get('GATE_FAKE_RECORD') != 'none':
            with open(record, 'a') as output:
                output.write('example.com/mod/internal/fake ' + name + '\\n')
        print(json.dumps({'Action': 'run', 'Package': package, 'Test': name}))
        if mode == 'incomplete':
            continue
        print(json.dumps({'Action': 'fail' if mode == 'fail' else 'pass', 'Package': package, 'Test': name}))
    print(json.dumps({'Action': 'fail' if mode == 'fail' else 'pass', 'Package': package}))
    sys.exit(1 if mode == 'fail' else 0)
'''


def fake_gate():
    directory = Path(tempfile.mkdtemp(prefix='strict-gate-self-check-'))
    binary = directory / 'bin/go'
    binary.parent.mkdir()
    binary.write_text(FAKE_GO)
    binary.chmod(0o755)
    log = directory / 'commands.jsonl'
    work = directory / 'work'
    (work / 'logs').mkdir(parents=True)
    (work / 'runs').mkdir()
    (work / 'media').mkdir()
    source = directory / 'source'
    source.mkdir()
    instance = Gate.__new__(Gate)
    instance.toolchain = directory
    instance.work = work
    instance.source = source
    instance.port = '55571'
    instance.module = 'example.com/mod'
    instance.steps = []
    instance.runs = {}
    instance.package_failures = collections.defaultdict(list)
    instance.red = []
    instance.unit_lock = threading.Lock()
    instance.census = {'dsn': ['GXB_FAKE_DSN']}
    instance.allowlist = {}
    instance.known_debt = {}
    instance.pending_stores = []
    instance.blocked = {}
    instance.section = 'general'
    instance.test_functions = {}
    instance.packages = None
    instance.previous = None
    instance.jobs = 1
    instance.parallel = gate_pool.EMPTY_PARALLEL
    instance.latency_reused = []
    instance.dsn_by_package = {}
    instance.environment = {'PATH': '/usr/bin:/bin', 'GATE_FAKE_LOG': str(log), 'GATE_FAKE_SOURCE': str(source)}
    instance.database = lambda name, cwd=None, migrate=('up',), deploy=True: f'postgres://self-check/{name}'
    instance.mode = 'parallel'
    instance.select = None
    instance.commit = 'self-check'
    instance.list_hashes = {'known_debt': 'self-check', 'skip_allowlist': 'self-check', 'parallel': 'self-check'}
    instance.reuse = False
    instance.reuse_store = directory / 'store'
    instance.reuse_in_run = {}
    instance.reuse_lock = threading.Lock()
    instance.reuse_ignored = []
    instance.reused_units = 0
    instance.run_units = 0
    instance.input_hashes = {}
    instance.code_cache = {}
    instance.template_cache = {}
    instance._go_version = None
    return instance, log


names = [f'TestExample{index:03d}' for index in range(50)]
shards = gate_pool.assign_shards(names, 6)
covered = [name for shard in shards for name in shard]
assert sorted(covered) == sorted(names) and len(covered) == len(set(covered)), shards
assert all(gate_pool.shard_of(name, 6) == index for index, shard in enumerate(shards) for name in shard)
units = gate_pool.build_units(['./internal/fake'], {'internal/fake': 6}, lambda package: names)
covered = [name for unit in units for name in (unit['tests'] or ())]
assert sorted(covered) == sorted(names) and len(covered) == len(set(covered)), units
assert len(units) <= 6 and all(unit['run'] for unit in units), units

serial_units = gate_pool.build_units(['./internal/fake'], {'internal/fake': 6}, lambda package: names,
                                     ['internal/fake.TestExample003'])
sharded = [name for unit in serial_units if not unit['serial'] for name in unit['tests']]
run_alone = [unit for unit in serial_units if unit['serial']]
assert 'TestExample003' not in sharded, serial_units
assert len(run_alone) == 1 and run_alone[0]['tests'] == ['TestExample003'], serial_units
assert run_alone[0]['run'] == '^(TestExample003)$', run_alone
assert sorted(sharded + run_alone[0]['tests']) == sorted(names), serial_units

instance, _ = fake_gate()
first = instance.unit_environment('postgres', {'package': './internal/fake', 'unit': 'alpha'}, {})
second = instance.unit_environment('postgres', {'package': './internal/fake', 'unit': 'beta'}, {})
roots = [Path(first['GXB_I7B5B_ASSET_ROOT']), Path(second['GXB_I7B5B_ASSET_ROOT'])]
assert roots[0] != roots[1], roots
assert all(root.is_dir() and stat.S_IMODE(root.stat().st_mode) == 0o700 for root in roots), roots

instance, log = fake_gate()
instance.packages = ['./internal/fake']
instance.parallel = dict(gate_pool.EMPTY_PARALLEL, shards={'internal/fake': 2},
                         serial_tests=['internal/fake.TestAlpha'])
instance.suite_parallel('unit', '')
commands = [json.loads(line) for line in log.read_text().splitlines()]
tests_commands = [command for command in commands if command[:2] == ['test', '-json']]
assert len(tests_commands) == 2, tests_commands
shard_command, serial_command = tests_commands
assert shard_command[shard_command.index('-run') + 1] == '^(TestBeta)$', shard_command
assert shard_command[shard_command.index('-skip') + 1] == '^(TestAlpha)$', shard_command
assert serial_command[serial_command.index('-run') + 1] == '^(TestAlpha)$' and '-skip' not in serial_command, serial_command
assert instance.runs['suite:unit'] == {'internal/fake.TestAlpha': 'pass', 'internal/fake.TestBeta': 'pass'}, instance.runs
assert not instance.red, instance.red

instance, log = fake_gate()
instance.merge_unit_outcomes('suite:postgres', 'unit_a', {'internal/a.TestOne': 'pass'}, {'internal/broken'})
instance.merge_unit_outcomes('suite:postgres', 'unit_b', {'internal/a.TestTwo': 'fail'}, set())
assert instance.runs['suite:postgres'] == {'internal/a.TestOne': 'pass', 'internal/a.TestTwo': 'fail'}, instance.runs
assert instance.package_failures['suite:postgres'] == ['internal/broken'], instance.package_failures
assert not instance.red, instance.red

instance, log = fake_gate()
instance.merge_unit_outcomes('suite:postgres', 'unit_a', {'internal/a.TestOne': 'pass'}, set())
instance.merge_unit_outcomes('suite:postgres', 'unit_b', {'internal/a.TestOne': 'pass'}, set())
assert any('seen in two units' in line for line in instance.red), instance.red
assert instance.runs['suite:postgres'] == {'internal/a.TestOne': 'pass'}, instance.runs

instance, log = fake_gate()
instance.suite('postgres', 'postgres socialintegration channelintegration')
commands = [json.loads(line) for line in log.read_text().splitlines()]
tags = 'postgres socialintegration channelintegration'
expected = [
    ['build', '-buildvcs=false', '-tags', tags, './...'],
    ['vet', '-tags', tags, './...'],
    ['test', '-json', '-count=1', '-timeout=150m', '-tags', tags, '-p=1',
     '-run', '^(TestPreparePublicationProcess|TestPreparePublicationRiver)$', './internal/integration/publication'],
    ['list', '-tags', tags, '-f', '{{.ImportPath}}', './...'],
    ['test', '-list', '.*', '-tags', tags, './internal/fake'],
    ['test', '-json', '-count=1', '-timeout=150m', '-tags', tags, '-p=1', './...'],
]
assert commands == expected, commands

instance, log = fake_gate()
instance.suite('unit', '')
commands = [json.loads(line) for line in log.read_text().splitlines()]
expected = [
    ['build', '-buildvcs=false', '-tags', '', './...'],
    ['vet', '-tags', '', './...'],
    ['list', '-tags', '', '-f', '{{.ImportPath}}', './...'],
    ['test', '-list', '.*', '-tags', '', './internal/fake'],
    ['test', '-json', '-count=1', '-timeout=150m', '-tags', '', './...'],
]
assert commands == expected, commands
assert not instance.red, instance.red

# Serial runs keep 150m; a parallel unit takes parallel.json's default, else the package override.
def parallel_test_commands(log):
    return [command for command in (json.loads(line) for line in log.read_text().splitlines())
            if command[:2] == ['test', '-json']]


def timeout_of(command):
    return next(argument for argument in command if argument.startswith('-timeout=')).removeprefix('-timeout=')


instance, log = fake_gate()
instance.packages = ['./internal/fake']
instance.suite_parallel('unit', '')
assert [timeout_of(command) for command in parallel_test_commands(log)] == ['20m'], log.read_text()

instance, log = fake_gate()
instance.packages = ['./internal/fake']
instance.parallel = dict(gate_pool.EMPTY_PARALLEL, timeout_minutes=25)
instance.suite_parallel('unit', '')
assert [timeout_of(command) for command in parallel_test_commands(log)] == ['25m'], log.read_text()

instance, log = fake_gate()
instance.packages = ['./internal/fake']
instance.parallel = dict(gate_pool.EMPTY_PARALLEL, timeout_minutes=25, timeouts={'./internal/fake': 40})
instance.suite_parallel('unit', '')
assert [timeout_of(command) for command in parallel_test_commands(log)] == ['40m'], log.read_text()

Gate.validate_parallel(dict(gate_pool.EMPTY_PARALLEL))
for document in (dict(gate_pool.EMPTY_PARALLEL, timeout_minutes=0),
                 dict(gate_pool.EMPTY_PARALLEL, timeout_minutes='20'),
                 dict(gate_pool.EMPTY_PARALLEL, timeouts=[]),
                 dict(gate_pool.EMPTY_PARALLEL, timeouts={'internal/fake': 0}),
                 dict(gate_pool.EMPTY_PARALLEL, timeouts={'internal/fake': '5'})):
    try:
        Gate.validate_parallel(document)
    except GateFailure:
        continue
    raise AssertionError(f'parallel.json must refuse {document}')

instance, _ = fake_gate()
instance.parallel = dict(gate_pool.EMPTY_PARALLEL, timeouts={'./internal/fake': 30})
instance.validate_timeout_packages(['./internal/fake'])
instance.parallel = dict(gate_pool.EMPTY_PARALLEL, timeouts={'internal/missing': 30})
try:
    instance.validate_timeout_packages(['./internal/fake'])
    raise AssertionError('a timeout for a package that does not exist must be refused')
except GateFailure as failure:
    assert 'internal/missing' in str(failure), failure

try:
    gate_pool.build_units(['./internal/fake'], {'internal/fake': 6}, lambda package: [])
    raise AssertionError('a sharded package with no tests must be refused')
except gate_pool.PoolError:
    pass
assert gate_pool.TEST_NAME.match('ExampleShard') and gate_pool.TEST_NAME.match('FuzzShard'), 'go test -list names'

instance, _ = fake_gate()
logs = instance.work / 'logs'
(logs / 'api.log').write_text('boot ok\nreply_conformance_violation mid=18 path=regions[].region_id\n')
try:
    instance.reply_conformance_scan(logs)
    raise AssertionError('a reply_conformance_violation line must make the scan RED')
except GateFailure as failure:
    assert 'api.log:2' in str(failure) and 'regions[].region_id' in str(failure), failure
(logs / 'api.log').write_text('boot ok\n')
nested = logs / 'runs' / 'one'
nested.mkdir(parents=True)
(nested / 'api.log').write_text('all replies conform\n')
instance.reply_conformance_scan(logs)
(nested / 'api.log').write_text('reply_conformance_violation mid=1 path=a\n')
try:
    instance.reply_conformance_scan(logs)
    raise AssertionError('a violation in a nested gxb-api log must make the scan RED')
except GateFailure as failure:
    assert 'runs/one/api.log:1' in str(failure), failure
empty = instance.work / 'empty-logs'
empty.mkdir()
try:
    instance.reply_conformance_scan(empty)
    raise AssertionError('a scan without gxb-api logs must be refused')
except GateFailure as failure:
    assert 'no gxb-api logs' in str(failure), failure

FINGERPRINT_TAGS = 'postgres socialintegration channelintegration'


def fingerprint_gate():
    """A fake gate over a small but complete source tree, so every fingerprint input class has a real input."""
    instance, log = fake_gate()
    source = instance.source
    (source / 'go.mod').write_text('module example.com/mod\n\ngo 1.27.3\n')
    (source / 'go.sum').write_text('example.com/dependency v1.0.0 h1:self-check\n')
    package = source / 'internal/fake'
    package.mkdir(parents=True)
    (package / 'fake.go').write_text('package fake\n')
    (package / 'fake_test.go').write_text(
        'package fake\n\nimport "os"\n\nfunc TestAlpha(t *testing.T) {\n\tos.ReadFile("golden/input.json")\n}\n')
    (package / 'golden').mkdir()
    (package / 'golden/input.json').write_text('{"value": 1}\n')
    (source / 'migrations').mkdir()
    (source / 'migrations/0001_init.sql').write_text('create table initial ();\n')
    generated = source / 'internal/content/builtin/generated'
    generated.mkdir(parents=True)
    for name in ('book_input_catalog.json', 'workshop_input_catalog.json', 'social_input_catalog.json', 'catalog.json'):
        (generated / name).write_text('{"content": 1}\n')
    provision = source / 'internal/integration/publication'
    provision.mkdir(parents=True)
    (provision / 'provision.go').write_text('package publication\n')
    river = source / 'internal/adapters/river'
    river.mkdir(parents=True)
    (river / 'deploy.go').write_text('package river\n')
    binaries = instance.work / 'binaries'
    binaries.mkdir()
    (binaries / 'fake-binary').write_bytes(b'binary')
    instance.environment['GXB_FAKE_BINARY'] = str(binaries / 'fake-binary')
    instance.environment['GATE_SELF_CHECK_VARIABLE'] = 'one'
    instance.census = {'dsn': ['GXB_FAKE_DSN'], 'binary': ['GXB_FAKE_BINARY']}
    return instance, log


def fake_unit(name='alpha'):
    return dict(package='./internal/fake', unit=name, tests=['TestAlpha', 'TestBeta'],
                run='^(TestAlpha|TestBeta)$', shard=None, serial=False)


def refingerprint(instance, unit=None):
    instance.code_cache.clear()
    instance.input_hashes.clear()
    instance.template_cache.clear()
    return instance.unit_fingerprint('postgres', FINGERPRINT_TAGS, unit or fake_unit(), {}, None)[0]


def altered(instance, path, content):
    original = path.read_bytes()
    path.write_bytes(content)
    try:
        return refingerprint(instance)
    finally:
        path.write_bytes(original)


def test_commands(log):
    return [command for command in (json.loads(line) for line in log.read_text().splitlines())
            if command[:2] == ['test', '-json']]


# Negative self-check: one changed byte in each input class 1-6 changes the fingerprint.
instance, _ = fingerprint_gate()
instance.dsn_by_package = {'internal/fake': frozenset({'GXB_FAKE_DSN'})}
base, _ = instance.unit_fingerprint('postgres', FINGERPRINT_TAGS, fake_unit(), {}, None)
assert altered(instance, instance.source / 'internal/fake/fake.go', b'package fake\n// changed\n') != base, 'class 1 code'
assert altered(instance, instance.source / 'internal/fake/golden/input.json', b'{"value": 2}\n') != base, 'class 2 runtime'
assert altered(instance, instance.source / 'go.sum', b'example.com/dependency v1.0.0 h1:changed\n') != base, 'class 3 external'
assert altered(instance, instance.source / 'migrations/0001_init.sql', b'create table changed ();\n') != base, 'class 4 database'
assert altered(instance, instance.work / 'binaries/fake-binary', b'changed') != base, 'class 5 binary'
instance.environment['GATE_SELF_CHECK_VARIABLE'] = 'two'
assert refingerprint(instance) != base, 'class 6 environment'
instance.environment['GATE_SELF_CHECK_VARIABLE'] = 'one'
assert refingerprint(instance) == base, 'fingerprint is stable'
assert refingerprint(instance, dict(fake_unit(), run='^(TestAlpha)$')) != base, 'class 6 run pattern'
instance.parallel = dict(gate_pool.EMPTY_PARALLEL, timeout_minutes=25)
assert refingerprint(instance) != base, 'class 6 timeout default'
instance.parallel = dict(gate_pool.EMPTY_PARALLEL, timeouts={'internal/fake': 30})
assert refingerprint(instance) != base, 'class 6 timeout override'

# S2: both database suites clone the river-provisioned template, so a package whose compiled files are equal under the two
# tag sets hashes equal across the suite labels; a changed file still changes the code input (class 1).
RIVER_FINGERPRINT_TAGS = 'postgres river socialintegration channelintegration'
instance, _ = fingerprint_gate()
instance.dsn_by_package = {'internal/fake': frozenset({'GXB_FAKE_DSN'})}
postgres_suite = instance.unit_fingerprint('postgres', FINGERPRINT_TAGS, fake_unit(), {}, None)[0]
river_suite = instance.unit_fingerprint('river', RIVER_FINGERPRINT_TAGS, fake_unit(), {}, None)[0]
assert postgres_suite == river_suite, 'equally compiled units must hash equal across the shared-template suites'

# In-run reuse: equal fingerprints run once, the second records reused_from the first.
instance, log = fingerprint_gate()
(instance.work / 'runs' / 'suite_postgres').mkdir()
(instance.work / 'runs' / 'suite_river').mkdir()
instance.run_unit('postgres', FINGERPRINT_TAGS, fake_unit('alpha'), {}, None)
instance.run_unit('river', FINGERPRINT_TAGS, fake_unit('beta'), {}, None)
assert len(test_commands(log)) == 1, test_commands(log)
reused = [row for row in instance.steps if 'reused_from' in row]
assert len(reused) == 1 and reused[0]['name'] == 'unit:river:beta', instance.steps
assert reused[0]['reused_from']['commit'] == 'self-check', reused
assert set(instance.runs['suite:river']) == {'internal/fake.TestAlpha', 'internal/fake.TestBeta'}, instance.runs
assert not instance.red, instance.red

# Store: a successful unit is stored, then reused without running; a different fingerprint is not used.
instance, log = fingerprint_gate()
(instance.work / 'runs' / 'suite_postgres').mkdir()
instance.run_unit('postgres', FINGERPRINT_TAGS, fake_unit('alpha'), {}, None)
assert len(test_commands(log)) == 1, test_commands(log)
assert not list(instance.reuse_store.glob('*.json')), 'nothing is stored before classification'
instance.classify()
assert len(list(instance.reuse_store.glob('*.json'))) == 1, list(instance.reuse_store.iterdir())
instance.reuse = True
instance.reuse_in_run = {}
instance.runs, instance.steps, instance.red = {}, [], []
instance.run_unit('postgres', FINGERPRINT_TAGS, fake_unit('alpha'), {}, None)
assert len(test_commands(log)) == 1, test_commands(log)
assert instance.reused_units == 1 and instance.run_units == 1, (instance.reused_units, instance.run_units)
assert instance.steps[0]['reused_from']['commit'] == 'self-check', instance.steps
instance.reuse_in_run = {}
instance.runs, instance.steps = {}, []
instance.run_unit('postgres', FINGERPRINT_TAGS, dict(fake_unit('alpha'), run='^(TestAlpha)$'), {}, None)
assert len(test_commands(log)) == 2, 'a store entry with a different fingerprint must not be used'
assert instance.run_units == 2, instance.run_units

# Store: a tampered entry whose inputs do not hash to its name is ignored and the unit runs.
fingerprint, inputs = instance.unit_fingerprint('postgres', FINGERPRINT_TAGS, fake_unit('alpha'), {}, None)
stored_path = instance.reuse_store / f'{fingerprint}.json'
document = json.loads(stored_path.read_text())
document['inputs']['unit']['run'] = 'tampered'
stored_path.write_text(json.dumps(document))
instance.reuse_in_run = {}
instance.runs, instance.steps = {}, []
instance.run_unit('postgres', FINGERPRINT_TAGS, fake_unit('alpha'), {}, None)
assert len(test_commands(log)) == 3, 'a tampered store entry must not be used'
assert any('ignoring store file' in line for line in instance.reuse_ignored), instance.reuse_ignored

# Store: a failing, incomplete, package-only or partial stream is never stored, even after classification.
for mode in ('fail', 'incomplete', 'empty', 'partial'):
    instance, log = fingerprint_gate()
    (instance.work / 'runs' / 'suite_postgres').mkdir()
    instance.environment['GATE_FAKE_MODE'] = mode
    unit = fake_unit('alpha')
    if mode == 'partial':
        unit = dict(unit, tests=['TestAlpha', 'TestBeta'], run='^(TestAlpha|TestBeta)$', shard=0)
    instance.run_unit('postgres', FINGERPRINT_TAGS, unit, {}, None)
    instance.classify()
    assert not list(instance.reuse_store.glob('*.json')), mode

# A package-only success stream is RED: the planned tests never reported.
instance, log = fingerprint_gate()
(instance.work / 'runs' / 'suite_postgres').mkdir()
instance.environment['GATE_FAKE_MODE'] = 'empty'
instance.run_unit('postgres', FINGERPRINT_TAGS, fake_unit('alpha'), {}, None)
assert any('did not report planned test' in line for line in instance.red), instance.red

# A shard planned for Alpha and Beta that only reports Alpha is RED.
instance, log = fingerprint_gate()
(instance.work / 'runs' / 'suite_postgres').mkdir()
instance.environment['GATE_FAKE_MODE'] = 'partial'
instance.run_unit('postgres', FINGERPRINT_TAGS,
                  dict(fake_unit('alpha'), tests=['TestAlpha', 'TestBeta'], run='^(TestAlpha|TestBeta)$', shard=0), {}, None)
assert any('did not report planned test' in line and 'TestBeta' in line for line in instance.red), instance.red

# An outcome outside the planned population is RED too, and never stored.
instance, log = fingerprint_gate()
(instance.work / 'runs' / 'suite_postgres').mkdir()
instance.run_unit('postgres', FINGERPRINT_TAGS, dict(fake_unit('alpha'), tests=['TestAlpha'], run=None), {}, None)
assert any('outside its planned population' in line and 'TestBeta' in line for line in instance.red), instance.red
instance.classify()
assert not list(instance.reuse_store.glob('*.json'))

# A stale allowlisted pass is RED after classification and its outcome is never written to the store.
instance, log = fingerprint_gate()
(instance.work / 'runs' / 'suite_postgres').mkdir()
instance.allowlist = {'internal/fake.TestAlpha': dict(test='internal/fake.TestAlpha', kind='operator', reason='manual proof')}
instance.run_unit('postgres', FINGERPRINT_TAGS, fake_unit('alpha'), {}, None)
assert not list(instance.reuse_store.glob('*.json')), 'a unit is stored only after classification'
instance.classify()
assert any('STALE_ALLOWLIST' in line for line in instance.red), instance.red
assert not list(instance.reuse_store.glob('*.json')), 'an outcome with findings is never stored'

# Serial mode with a populated store still runs every unit.
instance, log = fingerprint_gate()
fingerprint, inputs = instance.unit_fingerprint('postgres', FINGERPRINT_TAGS, fake_unit(), {}, None)
instance.store_unit(fingerprint, inputs, '2026-01-01T00:00:00+00:00', {'internal/fake.TestAlpha': 'pass'}, [],
                    ['internal/fake.TestAlpha'])
instance.reuse = True
instance.suite('unit', '')
assert len(test_commands(log)) == 1, test_commands(log)
assert instance.reused_units == 0 and not any('reused_from' in row for row in instance.steps), instance.steps

# A package whose enumeration proved it has no test is explicitly test-free; an empty stream alone never proves it.
units = gate_pool.build_units(['./internal/fake'], {}, lambda package: [])
assert len(units) == 1 and units[0]['tests'] == [] and gate_pool.unit_population(units[0], None) == [], units
unproven = gate_pool.build_units(['./internal/fake'], {}, lambda package: None)
assert unproven[0]['tests'] is None and gate_pool.unit_population(unproven[0], None) is None, unproven
instance, log = fingerprint_gate()
(instance.work / 'runs' / 'suite_postgres').mkdir()
instance.environment['GATE_FAKE_MODE'] = 'empty'
instance.run_unit('postgres', FINGERPRINT_TAGS, dict(fake_unit('alpha'), tests=[], run=None), {}, None)
assert not instance.red, instance.red
instance.classify()
entries = list(instance.reuse_store.glob('*.json'))
assert len(entries) == 1, entries
document = json.loads(entries[0].read_text())
assert document['population'] == [] and document['test_free'] is True, document
assert instance.stored_unit(document['fingerprint'])['outcomes'] == {}, document

# An unresolvable runtime path makes the package NOT_REUSABLE, naming its file:line.
instance, log = fingerprint_gate()
(instance.source / 'internal/fake/fake_test.go').write_text(
    'package fake\n\nfunc TestAlpha(t *testing.T) {\n\tpath := "golden" + suffix\n\tos.ReadFile(path)\n}\n')
try:
    instance.unit_fingerprint('postgres', FINGERPRINT_TAGS, fake_unit(), {}, None)
    raise AssertionError('an unresolvable runtime path must make the unit NOT_REUSABLE')
except gate_pool.NotReusable as failure:
    assert 'internal/fake/fake_test.go:5' in str(failure) and 'cannot resolve os.ReadFile' in str(failure), failure

LATENCY_TEST = 'internal/a.TestLatency'

# A dedicated latency test skips in the general section with an allowlisted latency_deferred entry, and that is not RED.
instance, _ = fake_gate()
instance.select = None
instance.section = 'general'
instance.latency_runs = {}
instance.allowlist = {LATENCY_TEST: dict(test=LATENCY_TEST, kind=LATENCY_DEFERRED, owner='latency:')}
instance.runs = {'suite:x': {LATENCY_TEST: 'skip'}}
assert not instance.classify() or instance.red == [], instance.red
assert not instance.red, instance.red


def clean_reading():
    return dict(at='self-check', load_average=(0.1,), temperatures_celsius={'k10temp:Tctl': 40.0},
                baseline_sha256_64mib_seconds=LATENCY_DEFAULTS['benchmark_reference_seconds'],
                worker_clusters=[], go_test_processes=[], breaches=[])


def latency_gate(breach_after=(), members=None):
    instance, log = fake_gate()
    import itertools
    counter = itertools.count()

    def reading():
        current = clean_reading()
        if next(counter) in breach_after:
            current['breaches'] = ['planted load']
        return current

    instance.select = None
    instance.blocked = {}
    instance.section = 'both'
    instance.latency_runs = {}
    instance.latency_red = []
    instance.latency_conditions = []
    instance.latency_verdict = None
    instance.latency = dict(LATENCY_DEFAULTS, cooldown_seconds=0, check_interval_seconds=0.001, wait_minutes=0,
                            members=members or [{'package': './internal/fake', 'test': 'TestAlpha', 'tags': ''}])
    instance.acquire_quiet_lock = lambda: object()
    instance.release_quiet_lock = lambda handle: None
    instance.latency_reading = reading
    return instance, log


# Quiet conditions run every member with GXB_LATENCY_SECTION=1 and give a GREEN latency section.
instance, log = latency_gate()
instance.latency_section()
assert instance.latency_verdict == 'GREEN', (instance.latency_verdict, instance.latency_red)
only = [row for row in instance.latency_runs.values()][0]
assert only == {'internal/fake.TestAlpha': 'pass'}, instance.latency_runs
commands = [json.loads(line) for line in log.read_text().splitlines()]
latency_test_command = [command for command in commands if command[:2] == ['test', '-json']][0]
assert latency_test_command[latency_test_command.index('-run') + 1] == '^(TestAlpha)$', latency_test_command
assert instance.overall_verdict() == 'GREEN', instance.overall_verdict()
assert instance.sections_report()['latency']['verdict'] == 'GREEN'

# A member that never reports an outcome makes the latency section RED.
instance, _ = latency_gate(members=[{'package': './internal/fake', 'test': 'TestGamma', 'tags': ''}])
instance.latency_section()
assert instance.latency_verdict == 'RED', instance.latency_verdict
assert any('TestGamma' in line and 'did not run' in line for line in instance.latency_red), instance.latency_red

# A latency_deferred allowlist entry that names no member is RED: the population and the allowlist cannot drift apart.
instance, _ = latency_gate()
instance.allowlist = {'internal/a.TestGhost': dict(test='internal/a.TestGhost', kind=LATENCY_DEFERRED, owner='latency:')}
instance.latency_section()
assert instance.latency_verdict == 'RED', instance.latency_verdict
assert any('names no latency-population member' in line for line in instance.latency_red), instance.latency_red

# Planted load keeps the conditions from ever holding: latency is NOT_RUN, never GREEN.
instance, _ = latency_gate(breach_after=(0,))
instance.latency_section()
assert instance.latency_verdict == 'NOT_RUN', instance.latency_verdict
assert instance.overall_verdict() == 'NOT_RUN', instance.overall_verdict()
assert not instance.report('self-check'), 'a NOT_RUN section must not exit green'
report = json.loads((instance.work / 'STRICT_GATE.json').read_text())
assert report['sections']['latency']['verdict'] == 'NOT_RUN', report['sections']

# A breach sampled during the run makes the section NOT_RUN even when every member passed.
instance, _ = latency_gate(breach_after=(1,))
original = instance.run_latency_members
def slow_members():
    original()
    threading.Event().wait(0.05)
instance.run_latency_members = slow_members
instance.latency_section()
assert instance.latency_verdict == 'NOT_RUN', (instance.latency_verdict, instance.latency_red)

# A general-only report has no latency section; a combined report carries both.
instance, _ = fake_gate()
instance.section = 'general'
instance.latency_verdict = None
assert 'latency' not in instance.sections_report() and instance.overall_verdict() == 'PARTIAL_GREEN'
instance.section = 'latency'
instance.latency_verdict = 'GREEN'
assert 'general' not in instance.sections_report() and instance.overall_verdict() == 'PARTIAL_GREEN'

# GATE_LATENCY_SECTION_V1 section 6: the helper's record, not a hand-maintained list, proves the general population.
def record_gate(member_tests, recording=True):
    instance, log = fake_gate()
    instance.section = 'general'
    instance.latency = dict(LATENCY_DEFAULTS,
                            members=[{'package': './internal/fake', 'test': test, 'tags': ''} for test in member_tests])
    instance.packages = ['./internal/fake']
    instance.parallel = dict(gate_pool.EMPTY_PARALLEL, shards={'internal/fake': 2},
                             serial_tests=['internal/fake.TestAlpha'])
    if not recording:
        instance.environment['GATE_FAKE_RECORD'] = 'none'
    return instance, log


instance, _ = record_gate(['TestAlpha'])
instance.suite_parallel('unit', '')
instance.check_latency_records()
assert any('TestBeta' in line and 'absent from latency.json members' in line for line in instance.red), instance.red
assert not any('TestAlpha' in line for line in instance.red), instance.red

instance, _ = record_gate(['TestAlpha', 'TestBeta'], recording=False)
instance.suite_parallel('unit', '')
instance.check_latency_records()
assert any('TestAlpha' in line and 'without recording' in line for line in instance.red), instance.red
assert any('TestBeta' in line and 'without recording' in line for line in instance.red), instance.red

instance, _ = record_gate(['TestAlpha', 'TestBeta'])
instance.suite_parallel('unit', '')
instance.check_latency_records()
assert not instance.red, instance.red

# A reused unit ran nothing, so the record lines stored with it stand in for the run, never its outcomes.
instance, _ = record_gate(['TestAlpha', 'TestBeta'])
instance.latency_reused = ['example.com/mod/internal/fake TestAlpha', 'example.com/mod/internal/fake TestBeta']
instance.runs = {'suite:unit': {'internal/fake.TestAlpha': 'pass', 'internal/fake.TestBeta': 'pass'}}
instance.check_latency_records()
assert not instance.red, instance.red

instance, _ = record_gate(['TestAlpha', 'TestBeta'])
instance.latency_reused = ['example.com/mod/internal/fake TestAlpha']
instance.runs = {'suite:unit': {'internal/fake.TestAlpha': 'pass', 'internal/fake.TestBeta': 'pass'}}
instance.check_latency_records()
assert any('TestBeta' in line and 'without recording' in line for line in instance.red), instance.red

# A record line the gate cannot read (empty import path) is RED, not dropped.
instance, _ = record_gate([])
instance.latency_reused = [' TestAlpha']
instance.check_latency_records()
assert any('is not "<import path> <root test name>"' in line for line in instance.red), instance.red

# A store file without latency_record (stored before the population record) is ignored: the unit runs again.
instance, log = fingerprint_gate()
fingerprint, inputs = instance.unit_fingerprint('postgres', FINGERPRINT_TAGS, fake_unit('alpha'), {}, None)
population = ['internal/fake.TestAlpha', 'internal/fake.TestBeta']
instance.store_unit(fingerprint, inputs, '2026-01-01T00:00:00+00:00',
                    {'internal/fake.TestAlpha': 'pass', 'internal/fake.TestBeta': 'pass'}, [], population)
path = instance.reuse_store / f'{fingerprint}.json'
document = json.loads(path.read_text())
assert instance.stored_unit(fingerprint)['latency_record'] == []
del document['latency_record']
path.write_text(json.dumps(document))
assert instance.stored_unit(fingerprint) is None and 'latency_record' in instance.reuse_ignored[-1], instance.reuse_ignored

# An entry written before the population proof existed is never reused; neither is one whose outcomes omit a planned test.
document['latency_record'] = []
del document['population']
path.write_text(json.dumps(document))
assert instance.stored_unit(fingerprint) is None and 'population' in instance.reuse_ignored[-1], instance.reuse_ignored
document['population'] = population
document['test_free'] = False
document['outcomes'].pop('internal/fake.TestBeta')
path.write_text(json.dumps(document))
assert instance.stored_unit(fingerprint) is None and 'population' in instance.reuse_ignored[-1], instance.reuse_ignored

# A stopped or failed pool starts none of its queued units.
started = []


def stop_at_first(unit):
    started.append(unit)
    raise SystemExit(143)


try:
    gate_pool.run_pool(['first', 'queued'], 1, stop_at_first)
except SystemExit:
    pass
assert started == ['first'], started

# Binaries are built with -trimpath, so the per-run export path never reaches their bytes or the unit fingerprints.
instance, log = fake_gate()
instance.census = {'binary': ['GXB_FAKE_API_BINARY']}
(instance.work / 'binaries').mkdir()
instance.build_binaries()
built = [json.loads(line) for line in log.read_text().splitlines()]
assert built and all('-trimpath' in command for command in built), built

# A unit that fails stops queued units on every pool thread, and a stopping gate starts no unit or clone.
started = []


def fail_first(unit):
    started.append(unit)
    if unit == 'first':
        raise SystemExit(143)


# A short switch interval widens the window between the failure and main's cancel (A-104 hit it 21 times in 500).
interval = sys.getswitchinterval()
sys.setswitchinterval(1e-6)
try:
    for attempt in range(500):
        started.clear()
        try:
            gate_pool.run_pool(['first', 'queued'], 1, fail_first)
        except SystemExit:
            pass
        assert started == ['first'], (attempt, started)
finally:
    sys.setswitchinterval(interval)
gate_pool.STOPPING.set()
try:
    gate_pool.run_pool(['a', 'b'], 2, started.append)
    assert started == ['first'], started
    try:
        gate_pool.clone_database('createdb', 1, 'tpl', 'db', {})
        raise AssertionError('a stopping gate cloned a database')
    except gate_pool.PoolError:
        pass
finally:
    gate_pool.STOPPING.clear()

# A start interrupted after the server launched still stops the cluster; init alone leaves nothing to stop.
actions = []
instance, log = fake_gate()


def interrupted_start(action):
    actions.append(action)
    if action == 'start':
        (instance.work / 'cluster/pgdata').mkdir(parents=True)
        (instance.work / 'cluster/pgdata/postmaster.pid').write_text('1\n')
        raise SystemExit(143)


instance.cluster = interrupted_start
try:
    instance.clustered(lambda: None)
    raise AssertionError('interrupted start did not propagate')
except SystemExit:
    pass
assert actions == ['init', 'start', 'stop'], actions

# A child that ignores TERM is killed after the grace; a process outside the snapshot is left alone.
stubborn = subprocess.Popen(['sh', '-c', 'trap "" TERM; sleep 60'])
later = subprocess.Popen(['sleep', '60'])
try:
    time.sleep(0.2)
    members = {member for member in strict_gate.group_members() if member[0] == stubborn.pid}
    assert len(members) == 1, members
    strict_gate.kill_survivors(members, 0)
    assert stubborn.wait(timeout=5) == -signal.SIGKILL
    assert later.poll() is None
finally:
    later.kill()
    later.wait()

import gate_compare  # noqa: E402
pair = {'pkg.TestA': dict(status='PASS', runs={'suite:postgres': 'pass', 'recipe:x': 'pass'})}
dropped = {'pkg.TestA': dict(status='PASS', runs={'recipe:x': 'pass'})}
assert gate_compare.differing_runs(pair, dropped) == ['pkg.TestA'], 'a test dropped from a suite must differ'
assert gate_compare.differing_runs(pair, pair) == []
print('strict gate self-check: PASS')
