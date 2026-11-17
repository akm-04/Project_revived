"""Self-check of the strict gate's classification rules and parallel units. Run: python3 -B tools/test_strict_gate.py"""
import collections
import json
import stat
import sys
import tempfile
import threading
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gate_pool
from strict_gate import Gate, GateFailure

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
    relative = package.removeprefix('./')
    directory = os.path.join(os.environ.get('GATE_FAKE_SOURCE', '.'), relative)
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
        if run is not None and not re.search(run, name):
            continue
        if skip is not None and re.search(skip, name):
            continue
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
    instance.test_functions = {}
    instance.packages = None
    instance.previous = None
    instance.jobs = 1
    instance.parallel = gate_pool.EMPTY_PARALLEL
    instance.dsn_by_package = {}
    instance.environment = {'PATH': '/usr/bin:/bin', 'GATE_FAKE_LOG': str(log), 'GATE_FAKE_SOURCE': str(source)}
    instance.database = lambda name, cwd=None, migrate=('up',), deploy=True: f'postgres://self-check/{name}'
    instance.mode = 'parallel'
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
    ['test', '-json', '-count=1', '-timeout=150m', '-tags', tags, '-p=1', './...'],
]
assert commands == expected, commands

instance, log = fake_gate()
instance.suite('unit', '')
commands = [json.loads(line) for line in log.read_text().splitlines()]
expected = [
    ['build', '-buildvcs=false', '-tags', '', './...'],
    ['vet', '-tags', '', './...'],
    ['test', '-json', '-count=1', '-timeout=150m', '-tags', '', './...'],
]
assert commands == expected, commands

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
    return dict(package='./internal/fake', unit=name, tests=None, run=None, shard=None, serial=False)


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

# Store: a failing or incomplete unit is never stored.
for mode in ('fail', 'incomplete'):
    instance, log = fingerprint_gate()
    (instance.work / 'runs' / 'suite_postgres').mkdir()
    instance.environment['GATE_FAKE_MODE'] = mode
    instance.run_unit('postgres', FINGERPRINT_TAGS, fake_unit('alpha'), {}, None)
    assert not list(instance.reuse_store.glob('*.json')), mode

# Serial mode with a populated store still runs every unit.
instance, log = fingerprint_gate()
fingerprint, inputs = instance.unit_fingerprint('postgres', FINGERPRINT_TAGS, fake_unit(), {}, None)
instance.store_unit(fingerprint, inputs, '2026-01-01T00:00:00+00:00', {'internal/fake.TestAlpha': 'pass'})
instance.reuse = True
instance.suite('unit', '')
assert len(test_commands(log)) == 1, test_commands(log)
assert instance.reused_units == 0 and not any('reused_from' in row for row in instance.steps), instance.steps

# An unresolvable runtime path makes the package NOT_REUSABLE, naming its file:line.
instance, log = fingerprint_gate()
(instance.source / 'internal/fake/fake_test.go').write_text(
    'package fake\n\nfunc TestAlpha(t *testing.T) {\n\tpath := "golden" + suffix\n\tos.ReadFile(path)\n}\n')
try:
    instance.unit_fingerprint('postgres', FINGERPRINT_TAGS, fake_unit(), {}, None)
    raise AssertionError('an unresolvable runtime path must make the unit NOT_REUSABLE')
except gate_pool.NotReusable as failure:
    assert 'internal/fake/fake_test.go:5' in str(failure) and 'cannot resolve os.ReadFile' in str(failure), failure

import gate_compare  # noqa: E402
pair = {'pkg.TestA': dict(status='PASS', runs={'suite:postgres': 'pass', 'recipe:x': 'pass'})}
dropped = {'pkg.TestA': dict(status='PASS', runs={'recipe:x': 'pass'})}
assert gate_compare.differing_runs(pair, dropped) == ['pkg.TestA'], 'a test dropped from a suite must differ'
assert gate_compare.differing_runs(pair, pair) == []
print('strict gate self-check: PASS')
