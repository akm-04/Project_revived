"""Tests for ops/worktree_index.py and ops/worktree_gc.py on a throwaway repo under tmp/fleet_ws/.

Run: cd ops && ../.toolchain/bin/python3 -B -m unittest test_worktree_tools
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

OPS = Path(__file__).resolve().parent
sys.path.insert(0, str(OPS))
import worktree_gc
import worktree_index

SCRATCH = OPS.parent / 'tmp' / 'fleet_ws'
CANONICAL_RELATIVE = 'work/backend_i7c4_full/backend'


class WorktreeFixture(unittest.TestCase):
    """One canonical repo plus worktrees covering every GC case; branch tips are dated so age is testable."""

    def setUp(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        self.root = Path(tempfile.mkdtemp(prefix='wt-tools-', dir=SCRATCH))
        self.addCleanup(shutil.rmtree, self.root, ignore_errors=True)
        self.repo = self.root / CANONICAL_RELATIVE
        self.repo.mkdir(parents=True)
        self.git(self.repo, 'init', '-b', 'i8-go1273')
        self.write_commit('base.txt', 'base', 40)
        self.base = self.head()
        self.make_branch('merged-old', 'merged.txt', 30)
        self.make_branch('unmerged', 'unmerged.txt', 30)
        self.make_branch('dirty-merged', 'dirty.txt', 30)
        self.make_branch('recent-merged', 'recent.txt', 1)
        self.make_branch('protected-branch', 'protected.txt', 30)
        self.make_branch('referenced-branch', 'referenced.txt', 30)
        self.make_branch('latest-branch', 'latest.txt', 30)
        self.make_branch('audit/A-001', 'audit.txt', 30)
        self.make_branch('i11a-only', 'i11a.txt', 30)
        for name, days in [('merged-old', 30), ('dirty-merged', 30), ('recent-merged', 1),
                           ('protected-branch', 30), ('referenced-branch', 30), ('latest-branch', 30)]:
            self.git(self.repo, 'merge', '--no-ff', '-m', f'merge {name}', name, days=days)
        self.make_i11a_branch()

        self.add_worktree('backend_merged_old', 'merged-old')
        self.add_worktree('backend_unmerged', 'unmerged')
        self.add_worktree('backend_dirty', 'dirty-merged')
        self.add_worktree('backend_recent', 'recent-merged')
        self.add_worktree('backend_audit_a001', 'audit/A-001')
        self.add_worktree('backend_protected', 'protected-branch')
        self.add_worktree('backend_referenced', 'referenced-branch')
        self.add_worktree('backend_in_latest', 'latest-branch')
        self.add_worktree('backend_i11a_only', 'i11a-only')
        self.add_worktree('backend_detached', None, detach=True)
        (self.root / 'work' / 'backend_dirty' / 'untracked.txt').write_text('scratch\n')

        (self.root / 'WORKSPACE_LAYOUT.json').write_text(json.dumps({
            'paths': {'protected_test': 'work/backend_protected'},
            'preserved_work_dependencies': {'backend_preserved_dep': 'test only'},
            'compatibility_links': [],
        }))
        (self.root / 'work' / 'LATEST_I11_CHECKPOINT.json').write_text(
            json.dumps({'path': 'checkpoints/active/I11/x.zip', 'mentions': 'work/backend_in_latest'}))
        stage = self.root / 'work' / 'i11' / 'notes'
        stage.mkdir(parents=True)
        (stage / 'queue.manifest.json').write_text('branch work/backend_referenced\n')

    def git(self, cwd, *arguments, days=None):
        environment = {**os.environ, 'GIT_AUTHOR_NAME': 'Test', 'GIT_AUTHOR_EMAIL': 'test@example.invalid',
                       'GIT_COMMITTER_NAME': 'Test', 'GIT_COMMITTER_EMAIL': 'test@example.invalid'}
        if days is not None:
            stamp = f'{int(time.time()) - days * 86400} +0000'
            environment.update({'GIT_AUTHOR_DATE': stamp, 'GIT_COMMITTER_DATE': stamp})
        completed = subprocess.run(['git', '-C', str(cwd), *arguments], capture_output=True, text=True,
                                   env=environment, check=True)
        return completed.stdout

    def head(self):
        return self.git(self.repo, 'rev-parse', 'HEAD').strip()

    def write_commit(self, name, content, days):
        (self.repo / name).write_text(content)
        self.git(self.repo, 'add', '--', name)
        self.git(self.repo, 'commit', '-m', f'commit {name}', days=days)

    def make_branch(self, name, filename, days):
        self.git(self.repo, 'checkout', '-b', name, self.base)
        self.write_commit(filename, name, days)
        self.git(self.repo, 'checkout', 'i8-go1273')

    def make_i11a_branch(self):
        tip = self.git(self.repo, 'rev-parse', 'i11a-only').strip()
        tree = self.git(self.repo, 'rev-parse', f'{tip}^{{tree}}').strip()
        merge = self.git(self.repo, 'commit-tree', tree, '-p', self.base, '-p', tip,
                         '-m', 'i11a merge', days=30).strip()
        self.git(self.repo, 'branch', 'i11a', merge)

    def add_worktree(self, name, branch, detach=False):
        path = self.root / 'work' / name
        if detach:
            self.git(self.repo, 'worktree', 'add', '--detach', str(path), 'HEAD')
        else:
            self.git(self.repo, 'worktree', 'add', str(path), branch)
        return path


class IndexTests(WorktreeFixture):
    def setUp(self):
        super().setUp()
        self.document = worktree_index.scan(self.root, with_sizes=False)
        self.records = {record['path']: record for record in self.document['worktrees']}

    def record(self, name):
        return self.records[f'work/{name}']

    def test_classification(self):
        cases = {
            (CANONICAL_RELATIVE, 'i8-go1273'): ('canonical', 'I8'),
            ('work/backend_i11a_l3', 'i11a-l3-commands'): ('phase', 'I11A'),
            ('work/backend_i9_10', 'i9-10'): ('phase', 'I9'),
            ('work/backend_i7c4c', 'i7c4c-research'): ('phase', 'I7C4'),
            ('work/backend_audit_a044', 'audit/A-044'): ('audit', 'AUDIT'),
            ('work/backend_playtest_1118', 'playtest-1118'): ('playtest', '-'),
            ('work/backend_gate_v2', 'gate-v2'): ('gate', '-'),
            ('work/backend_repair_r1', 'repair-r1'): ('repair', '-'),
            ('work/backend_mystery', 'mystery-branch'): ('misc', '-'),
            ('tmp/scratch', ''): ('scratch', '-'),
            ('/tmp/outside', ''): ('external', '-'),
        }
        for (path, branch), expected in cases.items():
            self.assertEqual(worktree_index.classify(path, branch, branch == ''), expected, path)

    def test_head_merge_and_dirty_facts(self):
        canonical = self.record('backend_i7c4_full/backend')
        self.assertEqual((canonical['lane'], canonical['phase']), ('canonical', 'I8'))
        self.assertTrue(canonical['merged_canonical'])
        self.assertEqual(canonical['dirty_files'], 0)

        merged = self.record('backend_merged_old')
        self.assertTrue(merged['merged_canonical'])
        self.assertFalse(merged['merged_i11a'])
        self.assertEqual(merged['dirty_files'], 0)

        i11a_only = self.record('backend_i11a_only')
        self.assertFalse(i11a_only['merged_canonical'])
        self.assertTrue(i11a_only['merged_i11a'])

        unmerged = self.record('backend_unmerged')
        self.assertFalse(unmerged['merged_canonical'] or unmerged['merged_i11a'])

        self.assertEqual(self.record('backend_dirty')['dirty_files'], 1)
        detached = self.record('backend_detached')
        self.assertTrue(detached['detached'])
        self.assertIsNone(detached['branch'])
        self.assertEqual(self.record('backend_audit_a001')['lane'], 'audit')

    def test_write_then_check_and_sizes_ignored(self):
        for record in self.document['worktrees']:
            record['size_mb'] = 111
        worktree_index.write(self.root, self.document)
        fresh = worktree_index.scan(self.root, with_sizes=False)
        self.assertEqual(worktree_index.stale(self.root, fresh), [])

        index_path = self.root / 'work' / 'INDEX.md'
        index_path.write_text(index_path.read_text().replace('backend_detached', 'backend_detached_edited'))
        self.assertTrue(worktree_index.stale(self.root, fresh))

    def test_check_reports_missing_index(self):
        self.assertTrue(worktree_index.stale(self.root, self.document))


class GcTests(WorktreeFixture):
    def setUp(self):
        super().setUp()
        self.document = worktree_index.scan(self.root, with_sizes=False)
        self.context = worktree_gc.build_context(self.root, min_age_days=14)
        self.reasons = {record['path']: worktree_gc.exclusion_reason(record, self.context)
                        for record in self.document['worktrees']}

    def reason(self, name):
        return self.reasons[f'work/{name}']

    def test_only_clean_merged_old_branches_are_candidates(self):
        eligible = sorted(path for path, reason in self.reasons.items() if reason is None)
        self.assertEqual(eligible, ['work/backend_i11a_only', 'work/backend_merged_old'])

    def test_exclusion_reasons(self):
        self.assertEqual(self.reason('backend_i7c4_full/backend'), 'canonical backend tree')
        self.assertEqual(self.reason('backend_detached'), 'detached HEAD (no branch)')
        self.assertEqual(self.reason('backend_audit_a001'), 'audit lane')
        self.assertEqual(self.reason('backend_unmerged'), 'branch not merged into canonical HEAD or i11a')
        self.assertTrue(self.reason('backend_dirty').startswith('dirty ('))
        self.assertIn('WORKSPACE_LAYOUT.json', self.reason('backend_protected'))
        self.assertIn('work/i11/notes/queue.manifest.json', self.reason('backend_referenced'))
        self.assertIn('LATEST_I11_CHECKPOINT.json', self.reason('backend_in_latest'))
        self.assertIn('newer than 14 days', self.reason('backend_recent'))

    def test_min_age_days_can_admit_young_branches(self):
        context = worktree_gc.build_context(self.root, min_age_days=0)
        reasons = {record['path']: worktree_gc.exclusion_reason(record, context)
                   for record in self.document['worktrees']}
        self.assertIsNone(reasons['work/backend_recent'])


if __name__ == '__main__':
    unittest.main()
