"""Tests for ops/opencode_dispatch.py with a fake opencode executable.

Run: cd ops && ../.toolchain/bin/python3 -B -m unittest test_opencode_dispatch
"""
import contextlib
import email.message
import io
import json
import os
import shutil
import sys
import tempfile
import time
import unittest
import urllib.error
from datetime import datetime, timezone
from pathlib import Path
from unittest import mock

OPS = Path(__file__).resolve().parent
sys.path.insert(0, str(OPS))
import opencode_dispatch

SCRATCH = OPS.parent / 'tmp' / 'fleet_ws'
PEAK_MOMENT = datetime(2026, 11, 27, 2, 0, tzinfo=timezone.utc)
OFF_PEAK_MOMENT = datetime(2026, 11, 27, 19, 0, tzinfo=timezone.utc)

FAKE_BODY = '''
import json, os, subprocess, sys, time
mode = os.environ.get('FAKE_OPENCODE_MODE', 'success')
marker = os.environ.get('FAKE_OPENCODE_MARKER')
if marker:
    with open(marker, 'a') as handle:
        handle.write('called\\n')
if mode == 'success':
    print(json.dumps({'type': 'text', 'part': {'type': 'text', 'messageID': 'm1', 'text': 'OK'}}))
    sys.exit(0)
if mode == 'noresult':
    print(json.dumps({'type': 'step_start', 'part': {'type': 'step-start'}}))
    sys.exit(0)
if mode == 'nonzero':
    print('boom', file=sys.stderr)
    sys.exit(3)
if mode == 'timeout':
    child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(30)'])
    with open(os.environ['FAKE_CHILD_PID_FILE'], 'w') as handle:
        handle.write(str(child.pid))
    time.sleep(30)
    sys.exit(0)
sys.exit(9)
'''


class OpenCodeDispatchTests(unittest.TestCase):
    def setUp(self):
        SCRATCH.mkdir(parents=True, exist_ok=True)
        self.root = Path(tempfile.mkdtemp(prefix='oc-dispatch-', dir=SCRATCH))
        self.addCleanup(shutil.rmtree, self.root, ignore_errors=True)
        self.prompt = self.root / '01-smoke.prompt'
        self.prompt.write_text('Reply with the word OK and nothing else.\n')
        self.fake = self.root / 'fake-opencode'
        self.fake.write_text(f'#!{sys.executable}\n' + FAKE_BODY)
        self.fake.chmod(0o755)
        self.marker = self.root / 'called.txt'
        self.out = self.root / 'out'
        self.child_pid_file = self.root / 'child.pid'

    def run_dispatch(self, mode='success', model='opencode-go/glm-5.3', extra=(), out_dir=None,
                     cwd=None, timeout=10):
        environment = {
            'OPENCODE_BIN': str(self.fake),
            'FAKE_OPENCODE_MODE': mode,
            'FAKE_OPENCODE_MARKER': str(self.marker),
            'FAKE_CHILD_PID_FILE': str(self.child_pid_file),
        }
        arguments = ['--model', model, '--cwd', str(cwd or self.root), '--timeout', str(timeout), '--label', 'test']
        if out_dir is not None:
            arguments += ['--out', str(out_dir)]
        arguments += list(extra)
        arguments.append(str(self.prompt))
        stderr = io.StringIO()
        with mock.patch.dict(os.environ, environment), contextlib.redirect_stderr(stderr), \
                contextlib.redirect_stdout(io.StringIO()):
            code = opencode_dispatch.main(arguments)
        return code, stderr.getvalue()

    def error_code(self, out=None):
        payload = json.loads(((out or self.out) / '01-smoke.error.json').read_text())
        return payload['error_code']

    def dead(self, pid, seconds=3.0):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            if not opencode_dispatch.process_alive(pid):
                return True
            time.sleep(0.05)
        return False

    def test_success_writes_result_and_events(self):
        code, _ = self.run_dispatch('success', out_dir=self.out)
        self.assertEqual(code, 0)
        self.assertEqual((self.out / '01-smoke.result.md').read_text().strip(), 'OK')
        self.assertTrue((self.out / '01-smoke.events.jsonl').read_text().strip())
        self.assertFalse((self.out / '01-smoke.error.json').exists())
        self.assertTrue(self.marker.exists())

    def test_default_output_beside_the_prompt(self):
        code, _ = self.run_dispatch('success')
        self.assertEqual(code, 0)
        self.assertEqual((self.root / '01-smoke.result.md').read_text().strip(), 'OK')

    def test_timeout_kills_the_process_group(self):
        started = time.monotonic()
        code, _ = self.run_dispatch('timeout', out_dir=self.out, timeout=1)
        self.assertLess(time.monotonic() - started, 15)
        self.assertEqual(code, 1)
        self.assertEqual(self.error_code(), 'TIMEOUT')
        child_pid = int(self.child_pid_file.read_text())
        self.assertTrue(self.dead(child_pid), f'grandchild {child_pid} survived the timeout kill')

    def test_nonzero_exit(self):
        code, _ = self.run_dispatch('nonzero', out_dir=self.out)
        self.assertEqual(code, 1)
        payload = json.loads((self.out / '01-smoke.error.json').read_text())
        self.assertEqual(payload['error_code'], 'EXIT_NONZERO')
        self.assertEqual(payload['returncode'], 3)
        self.assertIn('boom', payload['stderr'])

    def test_no_result(self):
        code, _ = self.run_dispatch('noresult', out_dir=self.out)
        self.assertEqual(code, 1)
        self.assertEqual(self.error_code(), 'NO_RESULT')

    def test_contributor_refused_before_running(self):
        code, _ = self.run_dispatch('success', model='opencode-go/muse-spark-1.3-contributor', out_dir=self.out)
        self.assertEqual(code, 1)
        self.assertEqual(self.error_code(), 'MODEL_REFUSED')
        self.assertFalse(self.marker.exists())
        self.assertFalse((self.out / '01-smoke.events.jsonl').exists())

    def test_free_model_requires_allow_free(self):
        code, _ = self.run_dispatch('success', model='opencode/beam-free', out_dir=self.out)
        self.assertEqual(code, 1)
        self.assertEqual(self.error_code(), 'MODEL_REFUSED')
        self.assertFalse(self.marker.exists())

        allowed_out = self.root / 'allowed'
        code, stderr = self.run_dispatch('success', model='opencode/beam-free', extra=['--allow-free'],
                                         out_dir=allowed_out)
        self.assertEqual(code, 0)
        self.assertIn('free tiers may log prompts', stderr)
        self.assertEqual((allowed_out / '01-smoke.result.md').read_text().strip(), 'OK')

    def test_peak_refusal_and_ignore_peak(self):
        with mock.patch.object(opencode_dispatch, 'real_time', return_value=PEAK_MOMENT):
            code, _ = self.run_dispatch('success', model='deepseek/deepseek-flash', out_dir=self.out)
        self.assertEqual(code, 1)
        self.assertEqual(self.error_code(), 'MODEL_REFUSED')
        self.assertFalse(self.marker.exists())

        allowed_out = self.root / 'allowed'
        with mock.patch.object(opencode_dispatch, 'real_time', return_value=PEAK_MOMENT):
            code, _ = self.run_dispatch('success', model='deepseek/deepseek-flash', extra=['--ignore-peak'],
                                        out_dir=allowed_out)
        self.assertEqual(code, 0)
        self.assertEqual((allowed_out / '01-smoke.result.md').read_text().strip(), 'OK')

        off_peak_out = self.root / 'off-peak'
        with mock.patch.object(opencode_dispatch, 'real_time', return_value=OFF_PEAK_MOMENT):
            code, _ = self.run_dispatch('success', model='deepseek/deepseek-flash', out_dir=off_peak_out)
        self.assertEqual(code, 0)

    def test_is_peak_boundaries(self):
        def moment(hour, day=27):
            return datetime(2026, 11, day, hour, 0, tzinfo=timezone.utc)
        self.assertTrue(opencode_dispatch.is_peak(moment(1)))
        self.assertFalse(opencode_dispatch.is_peak(moment(4)))
        self.assertTrue(opencode_dispatch.is_peak(moment(6)))
        self.assertFalse(opencode_dispatch.is_peak(moment(10)))
        self.assertFalse(opencode_dispatch.is_peak(moment(2, day=28)))
        self.assertFalse(opencode_dispatch.is_peak(None))

    def test_real_time_reads_date_from_an_error_response(self):
        headers = email.message.Message()
        headers['Date'] = 'Fri, 27 Nov 2026 19:37:07 GMT'
        error = urllib.error.HTTPError('https://api.deepseek.com', 401, 'Unauthorized', headers, None)
        with mock.patch.object(opencode_dispatch.urllib.request, 'urlopen', side_effect=error):
            moment = opencode_dispatch.real_time()
        self.assertEqual(moment, datetime(2026, 11, 27, 19, 37, 7, tzinfo=timezone.utc))

    def test_real_time_falls_back_to_the_system_clock_with_a_warning(self):
        stderr = io.StringIO()
        with mock.patch.object(opencode_dispatch.urllib.request, 'urlopen',
                               side_effect=urllib.error.URLError('offline')), \
                contextlib.redirect_stderr(stderr):
            moment = opencode_dispatch.real_time()
        self.assertIsNotNone(moment.tzinfo)
        self.assertIn('WARNING', stderr.getvalue())

    def test_cwd_outside_workspace_refused(self):
        code, stderr = self.run_dispatch('success', cwd=Path('/home/akm/Chatgpt'), out_dir=self.out)
        self.assertEqual(code, 2)
        self.assertIn('must be inside', stderr)
        self.assertFalse(self.marker.exists())

    def test_status_reports_done_and_failed(self):
        self.run_dispatch('success', out_dir=self.out)
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            code = opencode_dispatch.main(['--status', '01-smoke', '--out', str(self.out)])
        self.assertEqual(code, 0)
        self.assertIn('done', stdout.getvalue())

        failed_out = self.root / 'failed'
        self.run_dispatch('nonzero', out_dir=failed_out)
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            code = opencode_dispatch.main(['--status', '01-smoke', '--out', str(failed_out)])
        self.assertEqual(code, 0)
        self.assertIn('failed', stdout.getvalue())
        self.assertIn('EXIT_NONZERO', stdout.getvalue())

        with contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(opencode_dispatch.main(['--status', 'missing', '--out', str(self.out)]), 1)

    def test_background_returns_and_writes_pid(self):
        code, _ = self.run_dispatch('success', extra=['--background'], out_dir=self.out)
        self.assertEqual(code, 0)
        self.assertTrue((self.out / '01-smoke.pid').is_file())
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            if (self.out / '01-smoke.result.md').is_file():
                break
            time.sleep(0.05)
        self.assertTrue((self.out / '01-smoke.result.md').is_file(),
                        (self.out / '01-smoke.error.json').read_text()
                        if (self.out / '01-smoke.error.json').is_file() else 'background run produced nothing')
        self.assertEqual((self.out / '01-smoke.result.md').read_text().strip(), 'OK')

    def test_final_text_uses_the_last_message(self):
        events = '\n'.join([
            json.dumps({'part': {'type': 'text', 'messageID': 'm1', 'text': 'thinking out loud'}}),
            json.dumps({'part': {'type': 'step_finish', 'messageID': 'm1'}}),
            json.dumps({'part': {'type': 'text', 'messageID': 'm2', 'text': 'OK'}}),
            'not json',
        ])
        self.assertEqual(opencode_dispatch.final_text(events), 'OK')
        self.assertEqual(opencode_dispatch.final_text(''), '')


if __name__ == '__main__':
    unittest.main()
