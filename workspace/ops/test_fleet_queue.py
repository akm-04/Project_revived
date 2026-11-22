import fcntl
import json
import os
from pathlib import Path
import signal
import subprocess
import tempfile
import types
import unittest
from unittest.mock import patch

import fleet_queue


class CompletionNotificationTests(unittest.TestCase):
    def test_completion_is_queued_once_to_the_exact_thread(self):
        with tempfile.TemporaryDirectory() as directory:
            queue = Path(directory)
            response = subprocess.CompletedProcess([], 0, 'Queued message probe.\n', '')
            with patch.object(fleet_queue.subprocess, 'run', return_value=response) as run:
                fleet_queue.notify_codex_completion(queue, '01a13ac0-6c18-71a1-9f71-36c4c9b863f6', 1)
            run.assert_called_once()
            command = run.call_args.args[0]
            self.assertEqual(command[:4], ['codex', 'queue', '--thread', '01a13ac0-6c18-71a1-9f71-36c4c9b863f6'])
            self.assertIn('--resume', command)
            self.assertIn('exit status 1', command[command.index('--message') + 1])
            self.assertIn('not new user authorization', command[command.index('--message') + 1])
            record = json.loads((queue / 'codex_completion.json').read_text())
            self.assertEqual(record['status'], 'QUEUED_DELIVERY_UNVERIFIED')
            self.assertEqual(record['queue_exit_status'], 1)

    def test_successful_exit_with_resume_warning_is_not_delivery(self):
        with tempfile.TemporaryDirectory() as directory:
            queue = Path(directory)
            response = subprocess.CompletedProcess([], 0, 'Queued message probe.', 'Warning: could not resume thread')
            with patch.object(fleet_queue.subprocess, 'run', return_value=response):
                fleet_queue.notify_codex_completion(queue, 'thread', 0)
            record = json.loads((queue / 'codex_completion.json').read_text())
            self.assertEqual(record['status'], 'QUEUE_OR_RESUME_UNCONFIRMED')

    def test_empty_queue_does_not_wake_the_lead(self):
        with tempfile.TemporaryDirectory() as directory:
            queue = Path(directory)
            arguments = ['fleet_queue.py', str(queue), '--notify-codex-thread', '01a13ac0-6c18-71a1-9f71-36c4c9b863f6']
            with patch.object(fleet_queue.sys, 'argv', arguments), patch.object(fleet_queue, 'self_check'), patch.object(fleet_queue.fleet_models, 'load', return_value={'primary': {'provider': 'OpenCode'}}), patch.object(fleet_queue, 'WORKER_LOCK_DIRECTORY', queue / 'locks'), patch.object(fleet_queue, 'notify_codex_completion') as notify:
                self.assertEqual(fleet_queue.main(), 0)
            notify.assert_not_called()

    def test_timeout_is_recorded_without_retry_or_exception(self):
        with tempfile.TemporaryDirectory() as directory:
            queue = Path(directory)
            with patch.object(fleet_queue.subprocess, 'run', side_effect=subprocess.TimeoutExpired('codex', 20)) as run:
                fleet_queue.notify_codex_completion(queue, 'thread', 0)
            run.assert_called_once()
            record = json.loads((queue / 'codex_completion.json').read_text())
            self.assertEqual(record['status'], 'QUEUE_OR_RESUME_UNCONFIRMED')



class LoopTests(unittest.TestCase):
    def test_send_kills_what_the_worker_left_running(self):
        with tempfile.TemporaryDirectory() as directory:
            pid_file = Path(directory) / 'orphan.pid'
            script = f'sleep 300 & echo $! > {pid_file}; echo \'{{"ok": true, "result": "done"}}\''
            envelope = fleet_queue.send(['bash', '-c', script], '')
            self.assertTrue(envelope['ok'])
            orphan = int(pid_file.read_text())
            import time
            for _ in range(50):
                try:
                    import os
                    os.kill(orphan, 0)
                except ProcessLookupError:
                    break
                time.sleep(0.1)
            else:
                self.fail('the backgrounded child outlived its task')

    def test_preflight_verdict(self):
        self.assertEqual(fleet_queue.preflight_verdict('x\nGATE_PREFLIGHT GREEN\n')[0], 'GREEN')
        verdict, lines = fleet_queue.preflight_verdict('a\nGATE_PREFLIGHT RED red=1\n  pkg.TestX: NEW_FAILURE\n')
        self.assertEqual(verdict, 'RED')
        self.assertIn('  pkg.TestX: NEW_FAILURE', lines)
        self.assertEqual(fleet_queue.preflight_verdict('crashed\n')[0], 'NO_RESULT')

    def test_run_preflight_kills_the_group_on_timeout(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(fleet_queue, 'PREFLIGHT_LOCK', root / 'preflight.lock'):
                verdict, lines = fleet_queue.run_preflight(root, 'base', 'db', root / 'log', timeout=1,
                                                           command=['bash', '-c', 'sleep 60 & wait'])
                self.assertEqual(verdict, 'NO_RESULT')
                self.assertTrue(any('killed after 1 s' in line for line in lines))
                verdict, _ = fleet_queue.run_preflight(root, 'base', 'db', root / 'log2',
                                                       command=['bash', '-c', 'echo GATE_PREFLIGHT GREEN'])
                self.assertEqual(verdict, 'GREEN')

    def test_post_check_header(self):
        with tempfile.TemporaryDirectory() as directory:
            prompt = Path(directory) / '01-a.fresh.prompt'
            prompt.write_text('Contract-Systems: ranking\nPost-Check: preflight --base 6aefbdd --database r7_pf\n')
            self.assertEqual(fleet_queue.post_check(prompt), ('6aefbdd', 'r7_pf'))
            prompt.write_text('Contract-Systems: ranking\nPost-Check: preflight --base 6aefbdd --database r7;rm\n')
            self.assertIsNone(fleet_queue.post_check(prompt))

    def test_held_task_blocks_only_its_dependents(self):
        with tempfile.TemporaryDirectory() as directory:
            queue = Path(directory)
            (queue / '01-a.fresh.prompt').write_text('x\n')
            (queue / '02-b.prompt').write_text('Depends: 01-a\n')
            (queue / '03-c.prompt').write_text('x\n')
            self.assertEqual(fleet_queue.next_task(queue).name, '01-a.fresh.prompt')
            fleet_queue.held_path(queue / '01-a.fresh.prompt').write_text('{}')
            self.assertEqual(fleet_queue.next_task(queue).name, '03-c.prompt')
            (queue / '03-c.md').write_text('done')
            self.assertIsNone(fleet_queue.next_task(queue))
            fleet_queue.held_path(queue / '01-a.fresh.prompt').unlink()
            (queue / '01-a.md').write_text('done')
            self.assertEqual(fleet_queue.next_task(queue).name, '02-b.prompt')

    def test_dispatched_session_finds_the_marked_transcript(self):
        with tempfile.TemporaryDirectory() as directory:
            transcripts = Path(directory)
            (transcripts / 'other.jsonl').write_text('{"message": "Dispatch-Id: zzz"}\n')
            (transcripts / 'mine.jsonl').write_text('{"message": "Dispatch-Id: abc"}\n')
            with patch.object(fleet_queue.fleet_models, 'TRANSCRIPTS', transcripts):
                self.assertEqual(fleet_queue.dispatched_session(0, 'abc'), 'mine')
                self.assertIsNone(fleet_queue.dispatched_session(0, 'nope'))


if __name__ == '__main__':
    unittest.main()


class WorkerSlotTests(unittest.TestCase):
    def test_a_burst_queue_takes_a_slot_past_the_default_three(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(fleet_queue, 'WORKER_LOCK_DIRECTORY', Path(directory)):
            held = [fleet_queue.acquire_worker_slot('deepseek') for _ in range(fleet_queue.WORKER_SLOTS)]
            with patch.object(fleet_queue.time, 'sleep', side_effect=TimeoutError):
                with self.assertRaises(TimeoutError):
                    fleet_queue.acquire_worker_slot('deepseek')
                burst = fleet_queue.acquire_worker_slot('deepseek', 6)
            self.assertTrue(burst.name.endswith('deepseek-slot3'))
            for slot in held + [burst]:
                slot.close()

    def test_slots_are_capped(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(fleet_queue.sys, 'argv', ['fleet_queue.py', directory, '--slots', '11']), \
                patch.object(fleet_queue, 'self_check'), patch.object(fleet_queue, 'WORKER_LOCK_DIRECTORY', Path(directory) / 'locks'), \
                patch.object(fleet_queue, 'work', side_effect=AssertionError('--slots 11 was accepted')), self.assertRaises(SystemExit):
            fleet_queue.main()

    def test_the_queue_takes_its_slot_from_the_slots_flag(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(fleet_queue.sys, 'argv', ['fleet_queue.py', directory, '--slots', '6']), \
                patch.object(fleet_queue, 'self_check'), patch.object(fleet_queue, 'WORKER_LOCK_DIRECTORY', Path(directory) / 'locks'), \
                patch.object(fleet_queue, 'work', return_value=0), patch.object(fleet_queue, 'acquire_worker_slot') as acquire:
            fleet_queue.main()
        self.assertEqual(acquire.call_args.args[1], 6)


class WorkerClusterTaskTests(unittest.TestCase):
    """Writer tasks (slim) get a private cluster; a read-only profile and every failure path must not leak it."""

    def queue_with_prompt(self, directory):
        queue = Path(directory)
        (queue / '01-a.fresh.prompt').write_text('Contract-Systems: none - self-check\n')
        return queue

    def arguments(self, profile):
        return types.SimpleNamespace(pin={'provider': 'OpenCode', 'model': 'probe', 'peak': False}, allow_peak=False,
                                     profile=profile, rotate_context=150000)

    def run_work(self, queue, arguments, events, failure=None):
        envelope = {'ok': True, 'result': 'done', 'session_id': 'probe'}
        manifest = {'systems': [], 'tree': str(queue)}
        (queue / 'rules.md').write_text('rules\n')

        def start(_queue, _prompt):
            events.append('start')
            return 'qprobe_01a', {'GXB_TEST_PGHOST': '/tmp/qprobe_01a', 'GXB_TEST_PGPORT': '56100'}

        def run_task(_prompt, _session, _arguments, _manifest, _dispatch, environment=None):
            events.append(('worker', environment))
            if failure:
                events.append('timeout')
                raise failure
            return True, envelope

        with patch.object(fleet_queue, 'contract_index'), patch.object(fleet_queue, 'contract_manifest_for', return_value=(manifest, None)), \
                patch.object(fleet_queue, 'WORKER_RULES', queue / 'rules.md'), \
                patch.object(fleet_queue.contract_manifest, 'tree_head', return_value=None), \
                patch.object(fleet_queue, 'run_task', side_effect=run_task), \
                patch.object(fleet_queue, 'enforce_contracts', return_value=('done', 'PASS', [], 'probe')), \
                patch.object(fleet_queue, 'enforce_preflight', return_value=('done', None, 'probe')), \
                patch.object(fleet_queue, 'transcript_usage', return_value={'turns': 0, 'input': 0, 'cache_read': 0, 'output': 0,
                                                                             'cache_write': 0, 'context': 0, 'lines': 0,
                                                                             'invalid_tool_calls': 0, 'compactions': 0}), \
                patch.object(fleet_queue.fleet_models, 'foreign_models', return_value=[]), \
                patch.object(fleet_queue, 'start_worker_cluster', side_effect=start), \
                patch.object(fleet_queue, 'stop_worker_cluster', side_effect=lambda name: events.append(('stop', name))):
            return fleet_queue.work(queue, arguments)

    def test_a_writer_cluster_starts_before_the_worker_and_stops_after_it(self):
        with tempfile.TemporaryDirectory() as directory:
            events = []
            self.assertEqual(self.run_work(self.queue_with_prompt(directory), self.arguments('slim'), events), 0)
        self.assertEqual(events[0], 'start')
        self.assertEqual(events[1], ('worker', {'GXB_TEST_PGHOST': '/tmp/qprobe_01a', 'GXB_TEST_PGPORT': '56100'}))
        self.assertEqual(events[2], ('stop', 'qprobe_01a'))

    def test_a_worker_that_times_out_still_stops_its_cluster(self):
        with tempfile.TemporaryDirectory() as directory:
            events = []
            with self.assertRaises(subprocess.TimeoutExpired):
                self.run_work(self.queue_with_prompt(directory), self.arguments('slim'), events,
                              failure=subprocess.TimeoutExpired('cc-fleet', 1800))
        self.assertEqual(events[-1], ('stop', 'qprobe_01a'))

    def test_a_killed_queue_stops_its_active_clusters(self):
        with patch.object(fleet_queue, 'ACTIVE_WORKER_CLUSTERS', {'qprobe_01a'}), \
                patch.object(fleet_queue, 'stop_worker_cluster') as stop:
            with self.assertRaises(SystemExit):
                fleet_queue.termination_handler(signal.SIGTERM, None)
        stop.assert_called_once_with('qprobe_01a')

    def test_a_read_only_profile_gets_no_cluster(self):
        with tempfile.TemporaryDirectory() as directory:
            events = []
            self.assertEqual(self.run_work(self.queue_with_prompt(directory), self.arguments('slim-ro'), events), 0)
        self.assertEqual(events[0], ('worker', {}))


class WorkerClusterScriptTests(unittest.TestCase):
    """The shell owner: fake PostgreSQL binaries, so no real cluster is started."""

    def fake_binaries(self, root):
        binaries = root / 'bin'
        binaries.mkdir()
        (binaries / 'pg_ctl').write_text('#!/bin/bash\ncase " $* " in\n  *" status "*) exit 1 ;;\n  *) exit 0 ;;\nesac\n')
        (binaries / 'initdb').write_text('#!/bin/bash\nwhile [ $# -gt 0 ]; do\n  if [ "$1" = -D ]; then mkdir -p "$2"; touch "$2/PG_VERSION"; shift 2; '
                                         'else shift; fi\ndone\n')
        for name in ('pg_ctl', 'initdb'):
            (binaries / name).chmod(0o755)

    def run_script(self, root, *arguments, seats=None, wait=None):
        environment = {**os.environ, 'GXB_WORKER_CLUSTERS_ROOT': str(root), 'GXB_PG_BIN': str(root / 'bin')}
        if seats is not None:
            environment['GXB_TEST_SEATS'] = str(seats)
        if wait is not None:
            environment['GXB_TEST_SEAT_WAIT_SECONDS'] = str(wait)
        return subprocess.run(['bash', str(fleet_queue.WORKER_CLUSTER), *arguments], capture_output=True, text=True, env=environment)

    def test_port_selection_skips_a_held_port(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.fake_binaries(root)
            (root / 'held').mkdir()
            (root / 'held' / '.s.PGSQL.56100.lock').touch()
            started = self.run_script(root, 'start', 'qprobe')
            self.assertEqual(started.returncode, 0, started.stderr)
            self.assertEqual((root / 'qprobe' / 'port').read_text().strip(), '56101')
            exported = self.run_script(root, 'env', 'qprobe')
            self.assertIn(f'export GXB_TEST_PGHOST={root}/qprobe', exported.stdout)
            self.assertIn('export GXB_TEST_PGPORT=56101', exported.stdout)
            self.run_script(root, 'stop', '--remove', 'qprobe')
            self.assertFalse((root / 'qprobe').exists())

    def test_start_refuses_when_every_seat_is_taken(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.fake_binaries(root)
            (root / 'seats').mkdir()
            with open(root / 'seats' / '1.lock', 'w') as seat:
                fcntl.flock(seat, fcntl.LOCK_EX | fcntl.LOCK_NB)
                completed = self.run_script(root, 'start', 'qprobe', seats=1, wait=1)
        self.assertNotEqual(completed.returncode, 0)
        self.assertIn('no free seat', completed.stderr)
