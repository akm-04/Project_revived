"""Self-check of the strict gate's classification rules and parallel units. Run: python3 -B tools/test_strict_gate.py"""
import collections
import json
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
import json, os, sys
arguments = sys.argv[1:]
with open(os.environ['GATE_FAKE_LOG'], 'a') as log:
    log.write(json.dumps(arguments) + '\\n')
if '-list' in arguments:
    print('TestAlpha')
    print('TestBeta')
    print('ok   example.com/mod/internal/fake   0.001s')
elif '-json' in arguments:
    print(json.dumps({'Action': 'run', 'Package': 'example.com/mod/internal/fake', 'Test': 'TestAlpha'}))
    print(json.dumps({'Action': 'pass', 'Package': 'example.com/mod/internal/fake', 'Test': 'TestAlpha'}))
    print(json.dumps({'Action': 'pass', 'Package': 'example.com/mod/internal/fake'}))
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
