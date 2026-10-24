"""Provisioned strict gate (contract I85_STRICT_GATE_V1).

Exports one commit and runs, against a private PostgreSQL cluster:
  - every build tag set (unit, postgres, river) with its own freshly migrated and deployed databases for every test DSN, plus a
    build-only chi set; go build, go vet and go test -json for each;
  - the LuaJIT differential oracle (GXB_LUAJIT) inside the suites and the latency gate once, serially (this host is the reference host);
  - every upgrade/restore/seed-compare orchestration recipe on its own databases.
Every test outcome is classified against tools/strict_gate/known_debt.json and tools/strict_gate/skip_allowlist.json. Strict: a
missing tool, fixture, binary or database, a test environment variable nobody provisions, a failure outside the known debt, a skip
outside the allowlist, a repaid debt entry and a stale allowlist entry all make the gate RED. Writes <work>/STRICT_GATE.json.

Usage: strict_gate.py --toolchain <self-contained tool root> --cache <go/zig cache root> --work <new directory>
                      --populated59-dump <I7C3B F2_RECOVERY_EVIDENCE.dump> [--commit HEAD] [--port 55561] [--select REGEX]
"""
import argparse
import collections
import datetime
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
import time
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[1]
LISTS = REPOSITORY / 'tools/strict_gate'
TAG_SETS = {'unit': '', 'postgres': 'postgres socialintegration channelintegration',
            'river': 'postgres river socialintegration channelintegration'}
BUILD_ONLY_TAG_SETS = {'chi': 'chi'}
FULL_TAGS = TAG_SETS['river']
BINARY_COMMANDS = {'API': ('gxb-api', 'postgres,river'), 'REALTIME': ('gxb-realtime', 'postgres'),
                   'MAINT': ('gxb-profile-media-maint', 'postgres'), 'ACTIVATION': ('gxb-content-gift-activate', 'postgres')}
# Variables the gate itself provides to every run, and test outputs that are only written when a freeze tool asks for them.
MACHINE_VARIABLES = {'GXB_LUAJIT', 'GXB_I7B5B_ASSET_ROOT', 'GXB_I7A8_FULL_ROSTER_PROBE'}
OPTIONAL_OUTPUT_VARIABLES = {'GXB_I8_3B_SNAPSHOT_OUT'}
TOOLS = ['go', 'gofmt', 'goose', 'luajit', 'initdb', 'pg_ctl', 'createdb', 'psql', 'pg_dump', 'pg_restore', 'zig-cc', 'zig-c++']
ACCEPTED35_COMMIT = '52b31f6cb83b89eda2085635b205591ca4a72e7f'
ACCEPTED35_REVISION = '66dddbab1c548555e244c670bc994e9a17c604ba5462e38eb6610c956943b3af'
PREVIOUS_PRODUCT_COMMIT = '79d1a26a413dd27e14f9d7557cfaf184785d17cb'
POPULATED59_SHA256 = '1423a2014caca26acbfe6fe96c11c8417bd819afbc8827cbdb9705554b364560'
PREVIOUS_PRODUCT_POPULATE = ('^(TestI7C5ACombatOwnedStartResolveTerminalNative|TestI7C5ACombatCloseUnresolvedNative|'
                             'TestI7C5BTopFloorLadderFightSettlementNative|TestI7C5COneOnOneEntryMatchSettlementNative|'
                             'TestI7C5DArenaEntryFightSettlementNative)$')
GETENV = re.compile(r'os\.(?:Getenv|LookupEnv)\("([A-Z0-9_]+)"\)')
CHILD_SET = re.compile(r'"([A-Z0-9_]+)=|Setenv\("([A-Z0-9_]+)"')
TEST_FUNCTION = re.compile(r'^func (Test\w+)\(t \*testing\.T\)', re.M)


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
        self.populated59 = Path(arguments.populated59_dump).resolve()
        self.red = []
        self.steps = []
        self.runs = {}
        self.package_failures = collections.defaultdict(list)
        self.blocked = {}
        self.orchestration_variables = set()
        self.accepted35 = None
        self.work.mkdir(parents=True)
        for directory in ['logs', 'runs', 'binaries', 'recipes', 'exports', 'media']:
            (self.work / directory).mkdir()
        self.commit = subprocess.check_output(['git', 'rev-parse', arguments.commit], cwd=REPOSITORY, text=True).strip()
        self.source = self.export(self.commit, 'candidate')
        self.module = re.search(r'^module (\S+)', (self.source / 'go.mod').read_text(), re.M).group(1)
        self.known_debt = {entry['test']: entry for entry in json.loads((LISTS / 'known_debt.json').read_text())['entries']}
        self.allowlist = {entry['test']: entry for entry in json.loads((LISTS / 'skip_allowlist.json').read_text())['entries']}
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
            GXB_LUAJIT=str(self.toolchain / 'bin/luajit'), GXB_I7B5B_ASSET_ROOT=str(self.work / 'media'), GXB_I7A8_FULL_ROSTER_PROBE='1')
        (self.work / 'media').chmod(0o700)

    @staticmethod
    def only(paths):
        found = list(paths)
        require(len(found) == 1, f'expected exactly one of {found}')
        return found[0]

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
        with log.open('w') as output:
            code = subprocess.run([str(argument) for argument in arguments], cwd=cwd or self.source, env={**self.environment, **(extra or {})},
                                  stdout=output, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL).returncode
        self.steps.append(dict(name=name, exit=code, log=str(log.relative_to(self.work))))
        print(f'{name} {code}', flush=True)
        require(code == 0, f'step {name} exited {code} (log {log.relative_to(self.work)})')

    def sql(self, dsn, query):
        return subprocess.check_output([self.tool('psql'), dsn, '-X', '-At', '-v', 'ON_ERROR_STOP=1', '-c', query],
                                       env=self.environment, text=True, stdin=subprocess.DEVNULL).strip()

    def dsn(self, database):
        return f'postgres://{self.user}@127.0.0.1:{self.port}/{database}?sslmode=disable'

    def go_test(self, label, tags, packages, extra=None, run=None, skip=None, cwd=None, serial=True):
        stream = self.work / 'runs' / (label.replace(':', '_') + '.jsonl')
        arguments = [self.tool('go'), 'test', '-json', '-count=1', '-timeout=150m', '-tags', tags]
        arguments += ['-p=1'] * serial + ['-run', run] * bool(run) + ['-skip', skip] * bool(skip)
        with stream.open('w') as output:
            code = subprocess.run(arguments + packages, cwd=cwd or self.source, env={**self.environment, **(extra or {})},
                                  stdout=output, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL).returncode
        outcomes, started, failed_packages = {}, set(), set()
        for line in stream.read_text().splitlines():
            try:
                event = json.loads(line)
            except ValueError:
                continue
            package = event.get('Package', '').removeprefix(self.module + '/')
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
        failing_packages = {key.rsplit('.', 1)[0] for key, outcome in outcomes.items() if outcome in ('fail', 'incomplete')}
        self.package_failures[label] = sorted(failed_packages - failing_packages)
        self.runs[label] = outcomes
        self.steps.append(dict(name=label, exit=code, stream=str(stream.relative_to(self.work)), tests=len(outcomes)))
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
                 '-o', f'-h 127.0.0.1 -p {self.port} -c max_connections=300']
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
        extra = {}
        if name != 'unit':
            for variable in self.census['dsn']:
                database = f'{name}_' + variable.lower().removeprefix('gxb_').removesuffix('_dsn')
                extra[variable] = self.database(database)
            packages = ['./internal/integration/publication'] + ['./internal/adapters/river'] * ('river' in tags.split())
            self.go_test(f'provision:{name}:publication', tags, packages, {**extra, 'GXB_I7A9_PREPARE_PROCESS': '1'},
                         run='^(TestPreparePublicationProcess|TestPreparePublicationRiver)$')
        self.go_test(f'suite:{name}', tags, ['./...'], extra, skip=self.suite_skip_pattern(), serial=name != 'unit')

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

    def format(self):
        self.step('format', [self.tool('gofmt'), '-l', '.'])
        unformatted = (self.work / 'logs/format.log').read_text().split()
        require(not unformatted, f'gofmt -l lists {unformatted}')

    def latency(self):
        self.go_test('reference-host:latency', '', ['./internal/adapters/combatworker'], {'GXB_I8_LATENCY_GATE': '1'}, run='^TestResolverLatencyGate$')

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
        except (GateFailure, subprocess.CalledProcessError) as failure:
            self.red.append(f'{unit}: {failure}')

    def run(self):
        missing = [name for name in TOOLS if not (self.toolchain / 'bin' / name).exists()]
        require(not missing, f'toolchain lacks {missing}')
        self.orchestration_variables = {'GXB_I7A4B_RECOVERY_RECORD', 'GXB_I7A4C_RECOVERY_MODE', 'GXB_I7A4C_RECOVERY_EXPECTED', 'GXB_I7A7A_RECOVERY_MODE',
                                 'GXB_I7A7A_RECOVERY_OUTPUT', 'GXB_I7A7B_RECOVERY_MODE', 'GXB_I7A7B_RECOVERY_OUTPUT', 'GXB6B_MIGRATION_FIXTURE',
                                 'GXB_I7A4D_MODE', 'GXB_I7A4D_EXPECTED', 'GXB_I7A7A_UPGRADE_MODE', 'GXB_I7A7B_DEPLOYMENT_MODE',
                                 'GXB_I7C4A_UPGRADE_OLD_REVISION', 'GXB_I7B2B_RESTORED', 'GXB_I7B3A_RESTORED', 'GXB_BOOKMARK_RESTORED',
                                 'GXB_I7B4A_RESTORED', 'GXB_I7B4B_RESTORED', 'GXB_I7B2A_RESTORED', 'GXB_I7B5B_RESTORED', 'GXB_I7B4B_FINAL', 'GXB_I8_4_EXPECT_LEGACY', 'GXB_I7A9_PREPARE_PROCESS',
                                 'GXB_I8_LATENCY_GATE'}
        self.census_of_test_variables()
        self.red += [f'census: test variable {variable} is neither provisioned, recipe-owned nor set by a parent test'
                     for variable in self.census.get('unclassified', [])]
        self.build_binaries()
        self.cluster('init')
        self.cluster('start')
        try:
            self.guarded('format', self.format)
            for name, tags in BUILD_ONLY_TAG_SETS.items():
                self.guarded(f'build:{name}', self.step, f'build:{name}', [self.tool('go'), 'build', '-buildvcs=false', '-tags', tags, './...'])
            for name, tags in TAG_SETS.items():
                self.guarded(f'suite:{name}', self.suite, name, tags)
            self.guarded('reference-host:latency', self.latency)
            for name, recipe in self.recipes():
                self.guarded(f'recipe:{name}', recipe, name)
        finally:
            self.cluster('stop')

    def classify(self):
        seen = collections.defaultdict(dict)
        for label, outcomes in self.runs.items():
            for test, outcome in outcomes.items():
                seen[test][label] = outcome
        full = self.select is None
        tests = {}
        for test, runs in sorted(seen.items()):
            findings = []
            entry = self.allowlist.get(test)
            for label, outcome in runs.items():
                findings += self.finding(test, label, outcome, entry, seen)
            debt_failing = any(outcome == 'fail' for outcome in runs.values())
            if test in self.known_debt and full and not debt_failing:
                findings.append('DEBT_REPAID: passes everywhere; remove it from tools/strict_gate/known_debt.json')
            tests[test] = dict(runs=runs, status='RED' if findings else self.green_status(test, runs), findings=findings)
            self.red += [f'{test}: {finding}' for finding in findings]
        for test, entry in self.allowlist.items():
            owner_ran = any(label.startswith(entry.get('owner', '-')) and self.ran(test, outcome) for label, outcome in seen.get(test, {}).items())
            if full and entry['kind'] != 'child_helper' and not owner_ran and entry.get('owner') not in self.blocked:
                self.red.append(f'{test}: allowlisted for {entry["owner"]} but no {entry["owner"]} run ran it')
            if full and test not in seen:
                self.red.append(f'{test}: allowlist entry names a test no run saw')
        for test in self.known_debt:
            if full and test not in seen:
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

    def report(self, started):
        tests = self.classify()
        partial = self.select is not None
        verdict = ('PARTIAL_' if partial else '') + ('RED' if self.red else 'GREEN')
        report = dict(contract='I85_STRICT_GATE_V1', verdict=verdict, commit=self.commit, toolchain=str(self.toolchain), started=started,
                      finished=datetime.datetime.now(datetime.timezone.utc).isoformat(), selection=self.select.pattern if partial else None,
                      census=self.census, red=self.red, blocked_by_known_debt=self.blocked, steps=self.steps,
                      counts=dict(collections.Counter(row['status'] for row in tests.values())),
                      known_debt=dict(entries=len(self.known_debt), failing=sum(row['status'] == 'KNOWN_DEBT_FAILING' for row in tests.values())),
                      tests=tests)
        (self.work / 'STRICT_GATE.json').write_text(json.dumps(report, indent=1) + '\n')
        print(f'STRICT_GATE {verdict} {self.work / "STRICT_GATE.json"} red={len(self.red)} counts={report["counts"]}')
        return not self.red


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    for name in ['--toolchain', '--cache', '--work', '--populated59-dump']:
        parser.add_argument(name, required=True)
    parser.add_argument('--commit', default='HEAD')
    parser.add_argument('--port', default='55561')
    parser.add_argument('--select')
    arguments = parser.parse_args()
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
