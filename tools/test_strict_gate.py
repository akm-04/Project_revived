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
from strict_gate import Gate

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

if '-list' in arguments:
    print('TestAlpha')
    print('TestBeta')
    print('ok   example.com/mod/internal/fake   0.001s')
elif '-json' in arguments:
    package = 'example.com/mod/internal/fake'
    run, skip = option('-run'), option('-skip')
    for name in ('TestAlpha', 'TestBeta'):
        if run is not None and not re.search(run, name):
            continue
        if skip is not None and re.search(skip, name):
            continue
        print(json.dumps({'Action': 'run', 'Package': package, 'Test': name}))
        print(json.dumps({'Action': 'pass', 'Package': package, 'Test': name}))
    print(json.dumps({'Action': 'pass', 'Package': package}))
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
    instance.environment = {'PATH': '/usr/bin:/bin', 'GATE_FAKE_LOG': str(log)}
    instance.database = lambda name, cwd=None, migrate=('up',), deploy=True: f'postgres://self-check/{name}'
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
tests_commands = [command for command in commands if '-json' in command]
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
print('strict gate self-check: PASS')
