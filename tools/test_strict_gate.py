"""Self-check of the strict gate's classification rules (tools/strict_gate.py). Run: python3 -B tools/test_strict_gate.py"""
import collections
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from strict_gate import Gate

DEBT = 'internal/a.TestDebt'
HELPER = 'internal/a.TestHelper'
PARENT = 'internal/a.TestParent'
SEEDED = 'internal/a.TestSeeded'


def gate(runs, package_failures=None, known_debt=(DEBT,), blocked=None):
    instance = Gate.__new__(Gate)
    instance.select = None
    instance.red = []
    instance.runs = runs
    instance.package_failures = collections.defaultdict(list, package_failures or {})
    instance.known_debt = {test: {} for test in known_debt}
    instance.blocked = blocked or {}
    instance.allowlist = {HELPER: dict(test=HELPER, kind='child_helper', owners=[PARENT]),
                          SEEDED: dict(test=SEEDED, kind='recipe', owner='recipe:seed')}
    return instance


def classified(runs, package_failures=None, known_debt=(DEBT,), blocked=None):
    instance = gate(runs, package_failures, known_debt, blocked)
    return instance.classify(), instance.red


green = {'suite:x': {DEBT: 'fail', HELPER: 'skip', PARENT: 'pass', SEEDED: 'skip'}, 'recipe:seed:one': {SEEDED: 'pass'}}
tests, red = classified(green)
assert not red, red
assert tests[DEBT]['status'] == 'KNOWN_DEBT_FAILING' and tests[HELPER]['status'] == 'ALLOWLISTED_SKIP', tests

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
print('strict gate classification self-check: PASS')
