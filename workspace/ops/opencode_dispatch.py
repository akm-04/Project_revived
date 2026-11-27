#!/usr/bin/env python3
"""Run one prompt file through the native OpenCode CLI, headless.

usage: opencode_dispatch.py --model <provider/model> --cwd <dir> [--label <text>] [--timeout 3600]
       [--out <dir>] [--background] [--allow-free] [--ignore-peak] <name>.prompt
       opencode_dispatch.py --status <name> [--out <dir>]

The prompt file is read and sent as the message, with ops/FLEET_RULES_WORKER.md prepended exactly as the queue does
for a fresh session. The output directory (default: beside the prompt) receives <name>.result.md (the final assistant
message), <name>.events.jsonl (raw `--format json` events) and, on failure, <name>.error.json. --background detaches,
writes <name>.pid and returns at once; --status reports running, done or failed.

Model policy: contributor models are always refused (they train on prompts); a model whose id ends in "-free" needs
--allow-free and prints that free tiers may log prompts; a DeepSeek model is refused during DeepSeek peak hours
(01:00-04:00 and 06:00-10:00 UTC, Monday-Friday) unless --ignore-peak. Peak time comes from the Date header of
https://api.deepseek.com; if that is unavailable the system clock is used with a warning.

Exit: 0 success, 1 task failure (TIMEOUT, EXIT_NONZERO, NO_RESULT, MODEL_REFUSED), 2 usage error (bad or missing
arguments, missing prompt, cwd outside the workspace).
"""
import argparse
import datetime
import email.utils
import json
import os
import signal
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[1]
WORKER_RULES = WORKSPACE / 'ops' / 'FLEET_RULES_WORKER.md'
DEFAULT_OPENCODE_BIN = '/home/akm/.opencode/bin/opencode'
CLOCK_URL = 'https://api.deepseek.com'
CLOCK_TIMEOUT_SECONDS = 5
PEAK_HOURS_UTC = ((1, 4), (6, 10))
DEFAULT_TIMEOUT_SECONDS = 3600
EXIT_FAILURE = 1
EXIT_USAGE = 2


def opencode_bin():
    return os.environ.get('OPENCODE_BIN') or DEFAULT_OPENCODE_BIN


def utc_now():
    return datetime.datetime.now(datetime.timezone.utc)


def real_time():
    """Peak hours are judged by the provider's Date header; the system clock may be forwarded for mode windows."""
    date_value = None
    try:
        request = urllib.request.Request(CLOCK_URL, method='HEAD', headers={'User-Agent': 'gxb-opencode-dispatch'})
        with urllib.request.urlopen(request, timeout=CLOCK_TIMEOUT_SECONDS) as response:
            date_value = response.headers.get('Date')
    except urllib.error.HTTPError as error:
        date_value = error.headers.get('Date') if error.headers else None
    except (urllib.error.URLError, OSError, ValueError):
        date_value = None
    if date_value:
        try:
            return email.utils.parsedate_to_datetime(date_value).astimezone(datetime.timezone.utc)
        except (TypeError, ValueError):
            pass
    print('WARNING: no Date header from https://api.deepseek.com; using the system clock, which may be forwarded',
          file=sys.stderr)
    return utc_now()


def is_peak(moment):
    if moment is None or moment.weekday() >= 5:
        return False
    return any(start <= moment.hour < end for start, end in PEAK_HOURS_UTC)


def model_policy(model, allow_free=False, ignore_peak=False, now=None):
    """(error_code, message) for a refusal, or (None, warning). now is only consulted for DeepSeek models."""
    lowered = model.lower()
    if 'contributor' in lowered:
        return 'MODEL_REFUSED', ('model id contains "contributor": these models train on prompts, '
                                 'so project source must never be sent')
    warning = ''
    if lowered.endswith('-free'):
        if not allow_free:
            return 'MODEL_REFUSED', 'free models may log prompts; pass --allow-free to accept'
        warning = 'WARNING: free tiers may log prompts'
    if 'deepseek' in lowered and not ignore_peak and is_peak(now):
        return 'MODEL_REFUSED', ('DeepSeek peak hours (01:00-04:00 and 06:00-10:00 UTC, Monday-Friday); '
                                 'pass --ignore-peak to override')
    return None, warning


def task_name(prompt):
    name = prompt.name
    for suffix in ('.prompt', '.fresh'):
        if name.endswith(suffix):
            name = name[:-len(suffix)]
    return name


def resolve_cwd(raw):
    path = Path(raw).expanduser().resolve()
    if not path.is_dir():
        return None, f'--cwd is not a directory: {path}'
    try:
        path.relative_to(WORKSPACE)
    except ValueError:
        return None, f'--cwd must be inside {WORKSPACE}: {path}'
    return path, None


def final_text(events):
    """The last assistant message that has text parts, joined; intermediate narration is ignored."""
    messages, order = {}, []
    for line in events.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        part = event.get('part') or {}
        if part.get('type') != 'text' or not part.get('text'):
            continue
        key = part.get('messageID') or f'line-{len(order)}'
        if key not in messages:
            messages[key] = []
            order.append(key)
        messages[key].append(part['text'])
    if not order:
        return ''
    return '\n'.join(messages[order[-1]]).strip()


def write_error(out, name, code, message, **details):
    payload = {'error_code': code, 'error_msg': message, 'name': name, 'at': utc_now().isoformat(timespec='seconds')}
    payload.update(details)
    (out / f'{name}.error.json').write_text(json.dumps(payload, indent=2, ensure_ascii=False) + '\n')


def write_pid(out, name, pid):
    (out / f'{name}.pid').write_text(f'{pid}\n')


def process_alive(pid):
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def report_status(out, name):
    error_path = out / f'{name}.error.json'
    result_path = out / f'{name}.result.md'
    finished = []
    if error_path.is_file():
        try:
            code = json.loads(error_path.read_text()).get('error_code', 'UNKNOWN')
        except (OSError, ValueError):
            code = 'UNKNOWN'
        finished.append((error_path.stat().st_mtime, 'failed', code))
    if result_path.is_file():
        finished.append((result_path.stat().st_mtime, 'done', None))
    if finished:
        _, state, code = max(finished, key=lambda item: item[0])
        print(f'{name}: {state}' + (f' ({code})' if code else ''))
        return 0
    pid_path = out / f'{name}.pid'
    if pid_path.is_file():
        try:
            pid = int(pid_path.read_text().strip())
        except (OSError, ValueError):
            pid = None
        if pid is not None and process_alive(pid):
            print(f'{name}: running (pid {pid})')
        else:
            print(f'{name}: failed (process is gone and no result or error was written)')
        return 0
    print(f'{name}: unknown (no pid, result or error in {out})')
    return 1


def build_message(prompt_path):
    body = prompt_path.read_text(encoding='utf-8')
    rules = WORKER_RULES.read_text(encoding='utf-8')
    return f'{rules}\n\nTask:\n{body}'


def launch_background(out, name, arguments):
    command = [sys.executable, '-B', str(Path(__file__).resolve())]
    command += [argument for argument in arguments if argument != '--background']
    process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL, start_new_session=True, close_fds=True)
    write_pid(out, name, process.pid)
    print(f'started {name} in the background (pid {process.pid})')
    return 0


def run_foreground(model, cwd, label, message, out, name, timeout):
    write_pid(out, name, os.getpid())
    command = [opencode_bin(), 'run', '--model', model, '--format', 'json', '--archived',
               '--title', label, '--auto', message]
    try:
        process = subprocess.Popen(command, cwd=str(cwd), stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, text=True, start_new_session=True)
    except OSError as error:
        write_error(out, name, 'EXIT_NONZERO', f'could not start {opencode_bin()}: {error}', returncode=None)
        return EXIT_FAILURE
    timed_out = False
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        os.killpg(process.pid, signal.SIGKILL)
        stdout, stderr = process.communicate()
    (out / f'{name}.events.jsonl').write_text(stdout, encoding='utf-8')

    if timed_out:
        write_error(out, name, 'TIMEOUT', f'killed the process group after {timeout}s', timeout_seconds=timeout)
        print(f'{name}: TIMEOUT after {timeout}s', file=sys.stderr)
        return EXIT_FAILURE
    if process.returncode != 0:
        write_error(out, name, 'EXIT_NONZERO', f'opencode exited {process.returncode}',
                    returncode=process.returncode, stderr=stderr[-4000:])
        print(f'{name}: opencode exited {process.returncode}', file=sys.stderr)
        return EXIT_FAILURE
    text = final_text(stdout)
    if not text:
        write_error(out, name, 'NO_RESULT', 'opencode exited 0 but produced no assistant text',
                    stderr=stderr[-4000:])
        print(f'{name}: no assistant text', file=sys.stderr)
        return EXIT_FAILURE
    (out / f'{name}.result.md').write_text(text + '\n', encoding='utf-8')
    print(f'{name}: done ({len(text)} chars)')
    return 0


def build_parser():
    parser = argparse.ArgumentParser(description='Run one prompt file through the native OpenCode CLI.')
    parser.add_argument('prompt', nargs='?', help='prompt file to send')
    parser.add_argument('--model', help='provider/model, for example opencode-go/deepseek-v4.1-flash')
    parser.add_argument('--cwd', help='working directory for opencode (required; must be inside the workspace)')
    parser.add_argument('--label', help='session title (default: the task name)')
    parser.add_argument('--timeout', type=int, default=DEFAULT_TIMEOUT_SECONDS, help='wall-clock seconds (default 3600)')
    parser.add_argument('--out', help='output directory (default: beside the prompt)')
    parser.add_argument('--background', action='store_true', help='detach, write <name>.pid and return')
    parser.add_argument('--status', metavar='NAME', help='report running, done or failed for NAME')
    parser.add_argument('--allow-free', action='store_true', help='accept a model whose id ends in "-free"')
    parser.add_argument('--ignore-peak', action='store_true', help='run a DeepSeek model during peak hours')
    return parser


def main(argv=None):
    arguments = list(sys.argv[1:] if argv is None else argv)
    parser = build_parser()
    parsed = parser.parse_args(arguments)

    if parsed.status:
        out = Path(parsed.out).expanduser().resolve() if parsed.out else Path.cwd()
        return report_status(out, parsed.status)

    if not parsed.prompt:
        parser.error('a prompt file is required')
    if not parsed.model:
        parser.error('--model is required')
    if not parsed.cwd:
        parser.error('--cwd is required')
    if parsed.timeout <= 0:
        parser.error('--timeout must be positive')

    prompt_path = Path(parsed.prompt).expanduser().resolve()
    if not prompt_path.is_file():
        parser.error(f'prompt file not found: {prompt_path}')
    cwd, problem = resolve_cwd(parsed.cwd)
    if problem:
        print(problem, file=sys.stderr)
        return EXIT_USAGE

    name = task_name(prompt_path)
    if not name:
        parser.error('the prompt file name must not be empty after removing .prompt/.fresh')

    out = Path(parsed.out).expanduser().resolve() if parsed.out else prompt_path.parent
    out.mkdir(parents=True, exist_ok=True)

    now = real_time() if ('deepseek' in parsed.model.lower() and not parsed.ignore_peak) else None
    code, notice = model_policy(parsed.model, parsed.allow_free, parsed.ignore_peak, now)
    if code:
        write_error(out, name, code, notice, model=parsed.model)
        print(f'{name}: {code}', file=sys.stderr)
        return EXIT_FAILURE
    if notice:
        print(notice, file=sys.stderr)

    message = build_message(prompt_path)
    if parsed.background:
        return launch_background(out, name, arguments)
    label = parsed.label or name
    return run_foreground(parsed.model, cwd, label, message, out, name, parsed.timeout)


if __name__ == '__main__':
    sys.exit(main())
