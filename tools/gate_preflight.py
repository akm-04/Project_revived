"""Strict-gate preflight: catch registration and isolation defects at leaf close and merge, in minutes instead of a gate run.

Applies the strict gate's own rules (tools/strict_gate.py, known_debt.json, skip_allowlist.json, parallel.json) to a tree:
  - census: every os.Getenv/LookupEnv in a *_test.go must be provisioned, recipe-owned or set by a parent test (static, seconds);
  - format: gofmt -l over the changed Go files;
  - selection (ACCEPTANCE_V2_DESIGN section 3): the packages holding a changed file under internal/ or cmd/ (Go or embedded
    data) plus every package whose build or test imports reach one, from `go list -deps -test`, each printed with its reason;
    --changed-only keeps only the packages with changed Go files. Trigger paths (T1-T4) are printed with the gate they need;
  - packages: every selected package becomes units through tools/gate_pool.py, split like the strict gate's parallel mode. Each
    unit runs with the gate's full tag set, -p=1 and its own databases cloned from one migrated template, so cross-test pollution
    and unlisted skips show up here. Outcomes are judged like the gate: a failure outside known debt is NEW_FAILURE, a skip
    outside the allowlist is UNLISTED_SKIP. Packages in parallel.json `serial` and the `serial_tests` run after the pool.
It does not run recipes, the latency gate or unselected packages; a green preflight is a precondition for the gate, not a substitute.
The report's verdict is PARTIAL_GREEN or PARTIAL_RED, and it names `commit` only when the tree was clean.

Usage (after `export GXB_BACKEND=<tree>; source ops/testing/goenv.sh`):
  gate_preflight.py --base <ref> [--tree PATH] [--database <name>] [--jobs N] [--package ./internal/x ... | --changed-only]
                    [--static-only] [--plan]
The lists are read from PATH/tools/strict_gate/ when present, else from this tool's tools/strict_gate/, and the file used is
printed. Writes tmp/gate_preflight/<database>.json under the workspace and exits 1 when anything is red.
"""
import argparse
import ast
import collections
import json
import os
import subprocess
import sys
import threading
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gate_pool  # noqa: E402
import strict_gate  # noqa: E402

REPOSITORY = strict_gate.REPOSITORY
TOOL_LISTS = strict_gate.LISTS
WORKSPACE = Path('/home/akm/Chatgpt/EOL_Game')
DEFAULT_DATABASE_HOST = WORKSPACE / 'tmp/test-databases/i853_dev'
DEFAULT_DATABASE_PORT = '55853'
LIST_NAMES = ('known_debt.json', 'skip_allowlist.json', 'parallel.json')


def database_dsn(name):
    host = os.environ.get('GXB_TEST_PGHOST') or DEFAULT_DATABASE_HOST
    port = os.environ.get('GXB_TEST_PGPORT') or DEFAULT_DATABASE_PORT
    return f'postgres://postgres@/{name}?host={host}&port={port}'


def database_target():
    return str(os.environ.get('GXB_TEST_PGHOST') or DEFAULT_DATABASE_HOST), str(os.environ.get('GXB_TEST_PGPORT') or DEFAULT_DATABASE_PORT)


def orchestration_variables():
    """The recipe-owned set is a literal inside Gate.run; read it from there so the preflight never drifts from the gate."""
    tree = ast.parse(Path(strict_gate.__file__).read_text())
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and any(isinstance(target, ast.Attribute) and target.attr == 'orchestration_variables'
                                                 for target in node.targets) and isinstance(node.value, ast.Set):
            return {element.value for element in node.value.elts if isinstance(element, ast.Constant)}
    raise SystemExit('gate_preflight: Gate.run no longer assigns a literal orchestration_variables set')


def census_gate(source):
    gate = strict_gate.Gate.__new__(strict_gate.Gate)
    gate.source = source
    gate.orchestration_variables = orchestration_variables()
    gate.census_of_test_variables()
    return gate


def changed_files(base, tree):
    committed = subprocess.check_output(['git', 'diff', '--name-only', f'{base}...HEAD'], cwd=tree, text=True).split()
    working = subprocess.check_output(['git', 'status', '--porcelain'], cwd=tree, text=True).splitlines()
    return sorted({*committed, *(line[3:] for line in working)})


def changed_packages(files, tree):
    directories = {str(Path(name).parent) for name in files if name.endswith('.go') and (tree / name).exists()}
    return sorted('./' + directory for directory in directories if not directory.startswith(('virtualclient', 'tools')))


def go_list_records(tree):
    text = subprocess.check_output(['go', 'list', '-deps', '-test', '-json', '-tags', strict_gate.FULL_TAGS, './...'], cwd=tree, text=True)
    decoder, index, records = json.JSONDecoder(), 0, []
    while True:
        while index < len(text) and text[index].isspace():
            index += 1
        if index == len(text):
            return records
        record, index = decoder.raw_decode(text, index)
        records.append(record)


def package_graph(records, tree):
    """{directory: dependencies} per module package; a package's test binary (`<path>.test`) adds its test imports."""
    module = next(record['Module']['Path'] for record in records if record.get('Module', {}).get('Main'))
    directory_of, dependencies = {}, collections.defaultdict(set)
    for record in records:
        if record.get('Standard') or not record['ImportPath'].startswith(module):
            continue
        path = record['ImportPath'].split(' ')[0].removesuffix('.test').removesuffix('_test')
        if path == record['ImportPath']:
            directory_of[path] = str(Path(record['Dir']).relative_to(tree))
        dependencies[path].update(dependency.split(' ')[0] for dependency in record.get('Deps', ()))
    return {directory_of[path]: {directory_of[dependency] for dependency in found if dependency in directory_of}
            for path, found in dependencies.items() if path in directory_of}


def impacted_packages(files, graph):
    """ACCEPTANCE_V2_DESIGN section 3: a changed file under internal/ or cmd/ (Go or embedded data) marks the nearest package
    above it; every package whose build or test imports reach a marked one is selected too. {'./dir': reason}."""
    changed = set()
    for name in files:
        if not name.startswith(('internal/', 'cmd/')):
            continue
        directory = Path(name).parent
        while str(directory) not in graph and directory != Path('.'):
            directory = directory.parent
        if str(directory) in graph:
            changed.add(str(directory))
    selected = {}
    for directory, dependencies in sorted(graph.items()):
        if directory in changed:
            selected['./' + directory] = 'changed'
        elif dependencies & changed:
            selected['./' + directory] = 'imports ' + min(dependencies & changed)
    return selected


TRIGGERS = (('T1 schema: migration gate', ('migrations/',)),
            ('T2 shared transaction or reply core: full level-2 gate',
             ('internal/foundation/tx/', 'internal/foundation/receipt/', 'internal/adapters/stockruntime/failure.go',
              'internal/protocol/httpedge/')),
            ('T3 gate or toolchain: full level-2 gate', ('tools/strict_gate', 'tools/gate_preflight.py', 'go.mod', 'go.sum', '.toolchain/')),
            ('T4 composition: full level-2 gate', ('cmd/',)))


def triggers(files):
    """ACCEPTANCE_V2_DESIGN section 2: paths whose change needs a gate the preflight never replaces."""
    return [f'trigger {name} ({file})' for file in files for name, prefixes in TRIGGERS if file.startswith(prefixes)]


def unformatted(files, tree):
    go_files = [name for name in files if name.endswith('.go') and (tree / name).exists()]
    if not go_files:
        return []
    return subprocess.check_output(['gofmt', '-l', *go_files], cwd=tree, text=True).split()


def fresh_database(name, tree):
    subprocess.run(['bash', str(WORKSPACE / 'ops/testing/fresh_db.sh'), name], cwd=tree, check=True, stdout=subprocess.DEVNULL,
                   env={**os.environ, 'GXB_BACKEND': str(tree)})


def list_paths(tree):
    """Each list comes from the tree under test when it has one, else from this tool's own tools/strict_gate/."""
    return {name: (tree / 'tools/strict_gate' / name if (tree / 'tools/strict_gate' / name).is_file() else TOOL_LISTS / name)
            for name in LIST_NAMES}


def list_notes(paths):
    return [f'preflight list {name} {path}' for name, path in paths.items()]


def read_lists(paths):
    known_debt = {entry['test'] for entry in json.loads(paths['known_debt.json'].read_text())['entries']}
    allowlist = {entry['test']: entry for entry in json.loads(paths['skip_allowlist.json'].read_text())['entries']}
    parallel_path = paths['parallel.json']
    parallel = json.loads(parallel_path.read_text()) if parallel_path.is_file() else dict(gate_pool.EMPTY_PARALLEL)
    strict_gate.Gate.validate_parallel(parallel)
    return known_debt, allowlist, parallel


def build_preflight_units(packages, parallel, list_tests):
    serial_packages = {gate_pool.normalize_package(package) for package in parallel.get('serial', [])}
    shard_counts = {gate_pool.normalize_package(package): count for package, count in parallel.get('shards', {}).items()
                    if gate_pool.normalize_package(package) not in serial_packages}
    return gate_pool.build_units(packages, shard_counts, list_tests, parallel.get('serial_tests', ()))


def unit_databases(database, unit, dsn_by_package):
    variables = sorted(dsn_by_package.get(gate_pool.normalize_package(unit['package']), ()))
    return [(variable, gate_pool.database_name(database, unit['unit'], variable)) for variable in variables]


def base_environment(census_classes, tree, scratch):
    environment = dict(os.environ)
    for variable in census_classes.get('binary', []):
        command, tags = strict_gate.BINARY_COMMANDS[variable.removesuffix('_BINARY').rsplit('_', 1)[-1]]
        output = scratch / 'binaries' / command
        output.parent.mkdir(parents=True, exist_ok=True)
        if not output.exists():
            subprocess.run(['go', 'build', '-buildvcs=false', '-tags', tags, '-o', str(output), './cmd/' + command], cwd=tree, check=True)
        environment[variable] = str(output)
    return environment


def unit_environment(base, tree, scratch, unit, dsn_assignments):
    environment = dict(base)
    environment.update(strict_gate.suite_fixtures(tree))
    asset_root = scratch / 'media' / unit['unit']
    asset_root.mkdir(parents=True, exist_ok=True)
    asset_root.chmod(0o700)
    environment.update(GXB_LUAJIT=str(WORKSPACE / '.toolchain/bin/luajit'), GXB_I7B5B_ASSET_ROOT=str(asset_root),
                       GXB_I7A8_FULL_ROSTER_PROBE='1')
    environment.update(dsn_assignments)
    return environment


def drop_database(name, host, port):
    subprocess.run(['timeout', '60', 'dropdb', '--force', '-h', host, '-p', port, '-U', 'postgres', '--if-exists', name],
                   stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def clone_unit_databases(unit, database, host, port, dsn_by_package, clone_environment):
    assignments = {}
    for variable, name in unit_databases(database, unit, dsn_by_package):
        drop_database(name, host, port)
        gate_pool.clone_database('createdb', port, database, name, clone_environment)
        assignments[variable] = database_dsn(name)
    return assignments


def run_unit(unit, environment, stream, skip, tree, module, timeout_minutes):
    began = time.perf_counter()
    command = gate_pool.go_test_command('go', strict_gate.FULL_TAGS, [unit['package']], run=unit['run'], skip=skip,
                                        timeout_minutes=timeout_minutes)
    with stream.open('w') as output:
        code = subprocess.run(command, cwd=tree, env=environment, stdout=output, stderr=subprocess.STDOUT,
                              stdin=subprocess.DEVNULL).returncode
    outcomes, failed_packages = gate_pool.parse_go_test_json(stream, module)
    return code, outcomes, failed_packages, time.perf_counter() - began


def run_units(units, jobs, action, serial_packages=()):
    """The pool drains first; parallel.json serial packages and serial_tests run one at a time after it."""
    serial_packages = {gate_pool.normalize_package(package) for package in serial_packages}
    pooled = [unit for unit in units if not unit['serial'] and gate_pool.normalize_package(unit['package']) not in serial_packages]
    sequential = [unit for unit in units if not unit['serial'] and gate_pool.normalize_package(unit['package']) in serial_packages]
    serial_units = [unit for unit in units if unit['serial']]
    if pooled:
        gate_pool.run_pool(pooled, jobs, action)
    for unit in [*sequential, *serial_units]:
        action(unit)


def plan_lines(units, database, dsn_by_package, test_counts):
    for unit in units:
        databases = [name for _, name in unit_databases(database, unit, dsn_by_package)]
        shard = '-' if unit['shard'] is None else unit['shard']
        count = len(unit['tests'] or ()) if unit['tests'] is not None else test_counts.get(gate_pool.normalize_package(unit['package']), 0)
        yield f'plan {unit["package"]} unit={unit["unit"]} shard={shard} tests={count} databases={",".join(databases) or "-"}'


def strict_gate_module(tree):
    return next(line.split()[1] for line in (tree / 'go.mod').read_text().splitlines() if line.startswith('module '))


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
    parser.add_argument('--tree', default=str(REPOSITORY), help='tree under test (default: this repository)')
    parser.add_argument('--database', default='preflight', help='template database name (dropped and recreated)')
    parser.add_argument('--jobs', type=int, default=4, help='parallel units (default 4)')
    parser.add_argument('--package', action='append', help='package to run instead of the changed set (repeatable)')
    parser.add_argument('--static-only', action='store_true', help='census and gofmt only')
    parser.add_argument('--changed-only', action='store_true', help='only the packages holding changed Go files (no importers)')
    parser.add_argument('--plan', action='store_true', help='print the units and exit without touching PostgreSQL')
    arguments = parser.parse_args()
    if arguments.jobs < 1:
        parser.error('--jobs must be positive')
    tree = Path(arguments.tree).resolve()
    if not (tree / 'go.mod').is_file():
        parser.error(f'--tree {tree} has no go.mod')

    files = changed_files(arguments.base, tree)
    gate = census_gate(tree)
    classes = gate.census
    red = [f'census: {variable} is neither provisioned, recipe-owned nor set by a parent test' for variable in classes.get('unclassified', [])]
    red += [f'format: {name} needs gofmt' for name in unformatted(files, tree)]
    if arguments.package:
        selection = {package: 'named' for package in arguments.package}
    elif arguments.changed_only:
        selection = {package: 'changed' for package in changed_packages(files, tree)}
    else:
        selection = impacted_packages(files, package_graph(go_list_records(tree), tree))
    packages = sorted(selection)
    for package, reason in sorted(selection.items()):
        print(f'preflight select {package} {reason}', flush=True)
    trigger_lines = triggers(files)
    for line in trigger_lines:
        print(line, flush=True)
    scratch = WORKSPACE / 'tmp/gate_preflight' / arguments.database
    scratch.mkdir(parents=True, exist_ok=True)
    results, merged = {}, {}

    if arguments.plan:
        paths = list_paths(tree)
        for note in list_notes(paths):
            print(note, flush=True)
        _, _, parallel = read_lists(paths)
        dsn_by_package = gate_pool.dsn_variables_by_package(tree)

        def list_plan_tests(package):
            return gate_pool.test_names('go', dict(os.environ), tree, strict_gate.FULL_TAGS, package)

        try:
            units = build_preflight_units(packages, parallel, list_plan_tests)
        except gate_pool.PoolError as failure:
            print(f'plan: {failure}')
            sys.exit(1)
        try:
            for line in plan_lines(units, arguments.database, dsn_by_package, gate.test_counts_by_package()):
                print(line)
        except gate_pool.PoolError as failure:
            print(f'plan: {failure}')
            sys.exit(1)
        return

    if not arguments.static_only and packages:
        paths = list_paths(tree)
        for note in list_notes(paths):
            print(note, flush=True)
        known_debt, allowlist, parallel = read_lists(paths)
        gate.allowlist = allowlist
        gate.parallel = parallel
        module = strict_gate_module(tree)
        test_locations = {location for locations in gate.test_functions.values() for location in locations}
        red += [f'parallel: serial test {key} names no test function'
                for key in parallel.get('serial_tests', []) if key not in test_locations]
        environment = base_environment(classes, tree, scratch)
        fresh_database(arguments.database, tree)
        host, port = database_target()
        clone_environment = {**environment, 'PGHOST': host, 'PGUSER': 'postgres'}
        dsn_by_package = gate_pool.dsn_variables_by_package(tree)
        runs = scratch / 'runs'
        runs.mkdir(parents=True, exist_ok=True)
        results = {package: collections.Counter() for package in packages}
        unit_lock = threading.Lock()
        suite_skip = gate.suite_skip_pattern()

        def action(unit):
            try:
                assignments = clone_unit_databases(unit, arguments.database, host, port, dsn_by_package,
                                                   clone_environment)
                run_environment = unit_environment(environment, tree, scratch, unit, assignments)
                code, outcomes, failed_packages, seconds = run_unit(
                    unit, run_environment, runs / f'{unit["unit"]}.jsonl', gate.unit_skip(unit, suite_skip), tree, module,
                    gate_pool.unit_timeout(parallel, unit['package']))
            except (gate_pool.PoolError, OSError) as failure:
                with unit_lock:
                    red.append(f'{unit["unit"]}: {failure}')
                print(f'preflight {unit["unit"]} ERROR {failure}', flush=True)
                return
            with unit_lock:
                for test, outcome in outcomes.items():
                    if test in merged:
                        red.append(f'{test}: seen in two units ({unit["unit"]})')
                        continue
                    merged[test] = outcome
                red.extend(f'./{package}: failed without a failing test (build, TestMain or panic)' for package in failed_packages)
                if code != 0 and not outcomes and not failed_packages:
                    red.append(f'{unit["unit"]}: failed without a failing test (build, TestMain or panic)')
                results[unit['package']].update(outcomes.values())
                print(f'preflight {unit["unit"]} {dict(collections.Counter(outcomes.values()))} {round(seconds, 1)}s',
                      flush=True)

        def list_tests(package):
            try:
                return gate_pool.test_names('go', environment, tree, strict_gate.FULL_TAGS, package)
            except gate_pool.PoolError as failure:
                red.append(str(failure))
                return None

        try:
            units = build_preflight_units(packages, parallel, list_tests)
        except gate_pool.PoolError as failure:
            red.append(str(failure))
            units = []
        run_units(units, arguments.jobs, action, parallel.get('serial', ()))
        red += judge(merged, known_debt, allowlist)

    results = {package: dict(counter) for package, counter in results.items()}
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=tree, text=True).strip()
    # A run over uncommitted files is no evidence for HEAD, so only a clean tree names the commit gate_evidence.py checks.
    clean = not subprocess.check_output(['git', 'status', '--porcelain'], cwd=tree, text=True).strip()
    report = dict(base=arguments.base, head=head, commit=head if clean else None, selection=selection, triggers=trigger_lines,
                  packages=results, tests=merged, census=classes, red=red, verdict='PARTIAL_RED' if red else 'PARTIAL_GREEN')
    (scratch.parent / f'{arguments.database}.json').write_text(json.dumps(report, indent=1) + '\n')
    # fleet_queue.py reads this line; the report's PARTIAL_ verdict says it covers the selected packages only.
    print(f"GATE_PREFLIGHT {'RED' if red else 'GREEN'} red={len(red)}")
    for line in red:
        print('  ' + line)
    sys.exit(1 if red else 0)


if __name__ == '__main__':
    main()
