"""Strict-gate preflight: catch registration and isolation defects at leaf close and merge, in minutes instead of a gate run.

Applies the strict gate's own rules (tools/strict_gate.py, known_debt.json, skip_allowlist.json) to the working tree:
  - census: every os.Getenv/LookupEnv in a *_test.go must be provisioned, recipe-owned or set by a parent test (static, seconds);
  - format: gofmt -l over the changed Go files;
  - packages: every changed package runs whole (not -run filtered), with the gate's full tag set, -p=1 and one fresh database
    behind every DSN variable, so cross-test pollution and unlisted skips show up here. Outcomes are judged like the gate:
    a failure outside known debt is NEW_FAILURE, a skip outside the allowlist is UNLISTED_SKIP.
It does not run recipes, the latency gate or untouched packages; a green preflight is a precondition for the gate, not a substitute.

Usage (after `export GXB_BACKEND=<tree>; source ops/testing/goenv.sh`):
  gate_preflight.py --base <ref> [--database <name>] [--package ./internal/x ...] [--static-only]
Writes tmp/gate_preflight/<database>.json under the workspace and exits 1 when anything is red.
"""
import argparse
import ast
import collections
import json
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import strict_gate  # noqa: E402

REPOSITORY = strict_gate.REPOSITORY
WORKSPACE = Path('/home/akm/Chatgpt/EOL_Game')
DEFAULT_DATABASE_HOST = WORKSPACE / 'tmp/test-databases/i853_dev'
DEFAULT_DATABASE_PORT = '55853'


def database_dsn(name):
    host = os.environ.get('GXB_TEST_PGHOST') or DEFAULT_DATABASE_HOST
    port = os.environ.get('GXB_TEST_PGPORT') or DEFAULT_DATABASE_PORT
    return f'postgres://postgres@/{name}?host={host}&port={port}'


def orchestration_variables():
    """The recipe-owned set is a literal inside Gate.run; read it from there so the preflight never drifts from the gate."""
    tree = ast.parse(Path(strict_gate.__file__).read_text())
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and any(isinstance(target, ast.Attribute) and target.attr == 'orchestration_variables'
                                                 for target in node.targets) and isinstance(node.value, ast.Set):
            return {element.value for element in node.value.elts if isinstance(element, ast.Constant)}
    raise SystemExit('gate_preflight: Gate.run no longer assigns a literal orchestration_variables set')


def census_gate():
    gate = strict_gate.Gate.__new__(strict_gate.Gate)
    gate.source = REPOSITORY
    gate.orchestration_variables = orchestration_variables()
    gate.census_of_test_variables()
    gate.allowlist = {entry['test']: entry for entry in json.loads((strict_gate.LISTS / 'skip_allowlist.json').read_text())['entries']}
    return gate


def changed_files(base):
    committed = subprocess.check_output(['git', 'diff', '--name-only', f'{base}...HEAD'], cwd=REPOSITORY, text=True).split()
    working = subprocess.check_output(['git', 'status', '--porcelain'], cwd=REPOSITORY, text=True).splitlines()
    return sorted({*committed, *(line[3:] for line in working)})


def changed_packages(files):
    directories = {str(Path(name).parent) for name in files if name.endswith('.go') and (REPOSITORY / name).exists()}
    return sorted('./' + directory for directory in directories if not directory.startswith(('virtualclient', 'tools')))


def unformatted(files):
    go_files = [name for name in files if name.endswith('.go') and (REPOSITORY / name).exists()]
    if not go_files:
        return []
    return subprocess.check_output(['gofmt', '-l', *go_files], cwd=REPOSITORY, text=True).split()


def fresh_database(name):
    subprocess.run(['bash', str(WORKSPACE / 'ops/testing/fresh_db.sh'), name], cwd=REPOSITORY, check=True, stdout=subprocess.DEVNULL)
    return database_dsn(name)


def test_environment(census_classes, dsn, scratch):
    environment = dict(os.environ)
    environment.update({variable: dsn for variable in census_classes.get('dsn', [])})
    environment.update(GXB_LUAJIT=str(WORKSPACE / '.toolchain/bin/luajit'), GXB_I7B5B_ASSET_ROOT=str(scratch / 'media'),
                       GXB_I7A8_FULL_ROSTER_PROBE='1')
    (scratch / 'media').mkdir(parents=True, exist_ok=True)
    (scratch / 'media').chmod(0o700)
    for variable in census_classes.get('binary', []):
        command, tags = strict_gate.BINARY_COMMANDS[variable.removesuffix('_BINARY').rsplit('_', 1)[-1]]
        output = scratch / 'binaries' / command
        if not output.exists():
            subprocess.run(['go', 'build', '-buildvcs=false', '-tags', tags, '-o', str(output), './cmd/' + command], cwd=REPOSITORY, check=True)
        environment[variable] = str(output)
    return environment


def run_package(package, environment, log, skip):
    """go test -json for one whole package as the gate's suites run it; returns {package.Test: outcome} in the gate's key form."""
    command = ['go', 'test', '-json', '-count=1', '-p=1', '-timeout', '150m', '-tags', strict_gate.FULL_TAGS, *(['-skip', skip] if skip else []), package]
    completed = subprocess.run(command, cwd=REPOSITORY, env=environment, capture_output=True, text=True)
    log.write(completed.stdout)
    outcomes, started = {}, set()
    for line in completed.stdout.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        test = event.get('Test')
        if not test or '/' in test:
            continue
        key = f"{event['Package'].removeprefix(strict_gate_module() + '/')}.{test}"
        if event['Action'] == 'run':
            started.add(key)
        elif event['Action'] in ('pass', 'fail', 'skip'):
            outcomes[key] = event['Action']
    outcomes.update({key: 'incomplete' for key in started - outcomes.keys()})
    package_broken = completed.returncode != 0 and not any(outcome in ('fail', 'incomplete') for outcome in outcomes.values())
    return outcomes, package_broken


def strict_gate_module():
    return next(line.split()[1] for line in (REPOSITORY / 'go.mod').read_text().splitlines() if line.startswith('module '))


def judge(outcomes, known_debt, allowlist):
    findings = []
    for test, outcome in sorted(outcomes.items()):
        if outcome == 'incomplete':
            findings.append(f'{test}: INCOMPLETE (timeout or crash)')
        elif outcome == 'fail' and test not in known_debt:
            findings.append(f'{test}: NEW_FAILURE')
        elif outcome == 'skip' and test not in allowlist:
            findings.append(f'{test}: UNLISTED_SKIP')
        elif outcome == 'pass' and test in allowlist:
            findings.append(f'{test}: STALE_ALLOWLIST (ran and passed)')
    return findings


def main():
    parser = argparse.ArgumentParser(description=(__doc__ or '').split('\n\n')[0])
    parser.add_argument('--base', required=True, help='ref the change is measured against, e.g. the branch point')
    parser.add_argument('--database', default='preflight', help='fresh test database name (dropped and recreated)')
    parser.add_argument('--package', action='append', help='package to run instead of the changed set (repeatable)')
    parser.add_argument('--static-only', action='store_true', help='census and gofmt only')
    arguments = parser.parse_args()

    files = changed_files(arguments.base)
    gate = census_gate()
    classes = gate.census
    red = [f'census: {variable} is neither provisioned, recipe-owned nor set by a parent test' for variable in classes.get('unclassified', [])]
    red += [f'format: {name} needs gofmt' for name in unformatted(files)]
    packages = arguments.package or changed_packages(files)
    results = {}
    scratch = WORKSPACE / 'tmp/gate_preflight' / arguments.database
    scratch.mkdir(parents=True, exist_ok=True)
    if not arguments.static_only and packages:
        lists = REPOSITORY / 'tools/strict_gate'
        known_debt = {entry['test'] for entry in json.loads((lists / 'known_debt.json').read_text())['entries']}
        allowlist = gate.allowlist
        skip = gate.suite_skip_pattern()
        environment = test_environment(classes, fresh_database(arguments.database), scratch)
        with open(scratch / 'go_test.jsonl', 'w') as log:
            for package in packages:
                outcomes, broken = run_package(package, environment, log, skip)
                results[package] = dict(collections.Counter(outcomes.values()))
                red += judge(outcomes, known_debt, allowlist)
                if broken:
                    red.append(f'{package}: failed without a failing test (build, TestMain or panic)')
                print(f'preflight {package} {results[package]}', flush=True)
    report = dict(base=arguments.base, head=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPOSITORY, text=True).strip(),
                  packages=results, census=classes, red=red, verdict='RED' if red else 'GREEN')
    (scratch.parent / f'{arguments.database}.json').write_text(json.dumps(report, indent=1) + '\n')
    print(f"GATE_PREFLIGHT {report['verdict']} red={len(red)}")
    for line in red:
        print('  ' + line)
    sys.exit(1 if red else 0)


if __name__ == '__main__':
    main()
