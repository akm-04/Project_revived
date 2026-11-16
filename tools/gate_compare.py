"""Compare two strict gate reports: tests found in only one and tests whose status differs.

Usage: gate_compare.py A/STRICT_GATE.json B/STRICT_GATE.json
Exits 1 when a difference is not a known_flaky entry of tools/strict_gate/parallel.json.
"""
import json
import sys
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
PARALLEL = REPOSITORY / 'tools/strict_gate/parallel.json'


def load_tests(path):
    return json.loads(Path(path).read_text())['tests']


def only_in(first, second):
    return sorted(set(first) - set(second))


def differing_status(first, second):
    return sorted(test for test in set(first) & set(second) if first[test].get('status') != second[test].get('status'))


def differing_runs(first, second):
    """Tests whose per-label outcomes differ: a test dropped from one suite can still classify PASS overall."""
    return sorted(test for test in set(first) & set(second)
                  if first[test].get('status') == second[test].get('status') and first[test].get('runs') != second[test].get('runs'))


def flaky_reasons():
    if not PARALLEL.exists():
        return {}
    return {entry['test']: entry.get('reason', '') for entry in json.loads(PARALLEL.read_text())['known_flaky']}


def line(prefix, test, flaky, detail=''):
    note = f' (known_flaky: {flaky[test]})' if test in flaky else ''
    print(f'{prefix} {test}{detail}{note}')


def main():
    if len(sys.argv) != 3:
        raise SystemExit('usage: gate_compare.py A/STRICT_GATE.json B/STRICT_GATE.json')
    first, second = (load_tests(path) for path in sys.argv[1:])
    flaky = flaky_reasons()
    missing_first, missing_second = only_in(first, second), only_in(second, first)
    differing = differing_status(first, second)
    for test in missing_first:
        line('ONLY_IN_A', test, flaky)
    for test in missing_second:
        line('ONLY_IN_B', test, flaky)
    for test in differing:
        line('STATUS_DIFFERS', test, flaky, f' {first[test].get("status")} {second[test].get("status")}')
    differing_labels = differing_runs(first, second)
    for test in differing_labels:
        line('RUNS_DIFFER', test, flaky, f' {first[test].get("runs")} {second[test].get("runs")}')
    compared = [*missing_first, *missing_second, *differing, *differing_labels]
    failing = [test for test in compared if test not in flaky]
    print(f'GATE_COMPARE {"MISMATCH" if failing else "MATCH"} differences={len(compared)} failing={len(failing)}')
    return 1 if failing else 0


if __name__ == '__main__':
    sys.exit(main())
