#!/usr/bin/env python3
"""Run queued tasks through one cc-fleet worker, in order, in one resumed session.

usage: fleet_queue.py <queue directory> [--profile slim-ro|slim] [--no-cluster] [--timeout 1800s] [--max-turns 80]
                      [--rotate-context 150000] [--allow-peak] [--route primary|fallback|codex|codex-strong] [--slots 3]

A task is <queue>/NN-name.prompt; its answer lands in NN-name.md, so a rerun skips finished tasks.
NN-name.fresh.prompt starts a new session (use it when the sources change). Every prompt starts with a
`Contract-Systems: <system>, ...` line (or `Contract-Systems: none - <why>`) and, for a worktree, `Contract-Tree: <dir>`;
the queue refuses a prompt without it, sends the generated contract manifest with the task, pins it in
NN-name.manifest.json, checks the worker's compliance section (one corrective follow-up) and records the outcome in the
registry's dispatches.jsonl (ops/contract_manifest.py). usage.jsonl records
every run. Tasks added while the worker runs are picked up. Exit: 0 queue empty, 1 task failed
(NN-name.error.json) or another model answered. DeepSeek routes wait out peak unless --allow-peak; codex
routes have no peak and retry a task through a spent usage window. Each pool (deepseek, codex) has its own
WORKER_SLOTS. See ops/FLEET_GUIDE.md.

`Post-Check: preflight --base <sha> --database <name>` makes the queue run tools/gate_preflight.py in the Contract-Tree
after the answer (one at a time, under tmp/preflight.lock, with goenv sourced); RED gets one follow-up to the same
session and a second run. Every worker child runs in its own process group, killed when the call returns, so nothing
the worker started outlives its task. A timed-out task records its session and commits (NN-name.error.json, a TIMEOUT
dispatch row) and keeps the session, so a following non-fresh prompt resumes it. A task whose contract check does not
PASS is HELD (NN-name.held.json); the queue goes on with tasks whose `Depends:` line does not name it.
"""
import argparse
import datetime
import email.utils
import fcntl
import hashlib
import json
import os
import pathlib
import re
import shlex
import signal
import subprocess
import sys
import tempfile
import time
import uuid

import contract_index
import contract_manifest
import fleet_models

ROOT = pathlib.Path(__file__).resolve().parent.parent
WORKER_LOCK_DIRECTORY = ROOT / "tmp" / "fleet_locks"
WORKER_SLOTS = 3
MAX_WORKER_SLOTS = 10  # the --slots ceiling for a temporary burst of independent read-only queues
SLOT_POLL_SECONDS = 30
LIMIT_POLL_SECONDS = 1200
PEAK_HOURS_UTC = ((1, 4), (6, 10))
EXIT_TASK_FAILED = 1
PEAK_POLL_SECONDS = 120
WORKER_RULES = ROOT / "ops" / "FLEET_RULES_WORKER.md"
PREFLIGHT_LOCK = ROOT / "tmp" / "preflight.lock"
PREFLIGHT_TIMEOUT_SECONDS = 4 * 3600
WORKER_CLUSTER = ROOT / "ops" / "testing" / "worker_cluster.sh"
ACTIVE_WORKER_CLUSTERS = set()
POST_CHECK_RE = re.compile(r"^Post-Check:[ \t]*preflight[ \t]+--base[ \t]+(\S+)[ \t]+--database[ \t]+(\w+)[ \t]*$", re.MULTILINE)
DEPENDS_RE = re.compile(r"^Depends:[ \t]*(.*)$", re.MULTILINE)
DISPATCH_MARKER = "Dispatch-Id: "
RESUMED_TASK_HEADER = "The session rules from your first message still apply.\n\nTask:\n"
# cc-fleet 0.4.5's codex conversion drops the arguments of every tool call that shares a response (5493 of 5493 measured, 2026-11-10).
CODEX_RULES = ("\n\n## Codex route: one tool call per message\n"
               "Make exactly one tool call in each message and wait for its result before the next. Never send two or more "
               "tool calls together: on this route every call that shares a message arrives with empty arguments and fails "
               "with InputValidationError, which spends a turn and returns nothing. This overrides the rule above about sending "
               "independent reads together. Bash can chain several read-only commands with && in one call.\n")


def task_message(body, fresh, rules):
    """cc-fleet has no system prompt flag, so a fresh session carries the rules in its first message and resumes inherit them."""
    return f"{rules}\n\nTask:\n{body}" if fresh else RESUMED_TASK_HEADER + body


def try_lock(lock_file):
    try:
        fcntl.flock(lock_file, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return False
    return True


def acquire_worker_slot(pool, slots=WORKER_SLOTS):
    """Blocks until one of the pool's first `slots` slots is free; the kernel frees it when the process exits."""
    while True:
        for slot in range(slots):
            slot_file = (WORKER_LOCK_DIRECTORY / f"{pool}-slot{slot}").open("w")
            if try_lock(slot_file):
                return slot_file
            slot_file.close()
        time.sleep(SLOT_POLL_SECONDS)


def is_peak(moment):
    if moment.weekday() >= 5:
        return False
    return any(start <= moment.hour < end for start, end in PEAK_HOURS_UTC)


def real_time():
    """The system clock may be forwarded for mode windows, so ask the provider's server."""
    headers = subprocess.run(["curl", "-sI", "--max-time", "20", "https://api-docs.deepseek.com"],
                             capture_output=True, text=True).stdout
    for line in headers.splitlines():
        if line.lower().startswith("date:"):
            return email.utils.parsedate_to_datetime(line.split(":", 1)[1].strip())
    return None


def wait_for_peak(wanted):
    """Blocks until real time is inside (True) or outside (False) peak hours. No answer from the clock keeps waiting."""
    while (moment := real_time()) is None or is_peak(moment) != wanted:
        time.sleep(PEAK_POLL_SECONDS)


def transcript_usage(path, start_line=0):
    """The envelope only covers the worker's last wake-up, so true totals come from its transcript.
    Streaming repeats a message id across lines; the last line of an id holds its final usage."""
    lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
    messages = {}
    invalid_tool_calls = compactions = 0
    for line in lines[start_line:]:
        entry = json.loads(line)
        compactions += entry.get("subtype") == "compact_boundary"
        if entry.get("type") == "assistant":
            messages[entry["message"].get("id")] = entry["message"].get("usage") or {}
        content = (entry.get("message") or {}).get("content") if entry.get("type") == "user" else None
        invalid_tool_calls += sum(1 for item in content if isinstance(item, dict) and item.get("type") == "tool_result"
                                  and "InputValidationError" in json.dumps(item.get("content"))) if isinstance(content, list) else 0
    total = lambda key: sum(usage.get(key) or 0 for usage in messages.values())
    last = list(messages.values())[-1] if messages else {}
    return {"turns": len(messages), "input": total("input_tokens"), "cache_read": total("cache_read_input_tokens"),
            "output": total("output_tokens"), "cache_write": total("cache_creation_input_tokens"),
            "context": sum(last.get(key) or 0 for key in ("input_tokens", "cache_read_input_tokens", "cache_creation_input_tokens")),
            "lines": len(lines), "invalid_tool_calls": invalid_tool_calls, "compactions": compactions}


def read_envelope(completed):
    """A bad flag exits non-zero with one stderr line and no JSON, so stdout alone cannot be trusted."""
    try:
        envelope = json.loads(completed.stdout)
    except json.JSONDecodeError:
        envelope = {"error_code": "NO_ENVELOPE", "stdout": completed.stdout[-2000:]}
    if completed.returncode == 0 and envelope.get("ok"):
        return envelope
    return {**envelope, "ok": False, "returncode": completed.returncode, "stderr": completed.stderr[-2000:]}


def task_name(prompt):
    return prompt.name.removesuffix(".prompt").removesuffix(".fresh")


def held_path(prompt):
    return prompt.with_name(task_name(prompt) + ".held.json")


def depends_on(prompt):
    match = DEPENDS_RE.search(prompt.read_text(encoding="utf-8"))
    return {name.strip() for name in match.group(1).split(",") if name.strip()} if match else set()


def next_task(queue):
    """The first unanswered, unheld task whose `Depends:` tasks are all answered and not held."""
    held = {task_name(prompt) for prompt in queue.glob("*.prompt") if held_path(prompt).exists()}
    answered = {task_name(prompt) for prompt in queue.glob("*.prompt") if answer_path(prompt).exists()}
    for prompt in sorted(queue.glob("*.prompt")):
        if answer_path(prompt).exists() or held_path(prompt).exists():
            continue
        if depends_on(prompt) - (answered - held):
            continue
        return prompt
    return None


def answer_path(prompt):
    return prompt.with_name(task_name(prompt) + ".md")


def contract_manifest_for(prompt):
    """(manifest, None) or (None, refusal envelope). A system task without an open stage registry cannot be dispatched."""
    body = prompt.read_text(encoding="utf-8")
    systems, none_reason, tree = contract_manifest.task_header(body)
    if systems is None:
        return None, {"ok": False, "error_code": "CONTRACT_HEADER_MISSING",
                      "error_msg": "the prompt needs a `Contract-Systems: <system>, ...` or `Contract-Systems: none - <why>` line"}
    if not systems and not none_reason:
        return None, {"ok": False, "error_code": "CONTRACT_HEADER_MISSING", "error_msg": "`Contract-Systems: none` needs a reason"}
    tree = (tree or contract_manifest.default_tree()).resolve()
    directory = contract_manifest.registry_for()
    if systems and not (directory / "registry.json").is_file():
        return None, {"ok": False, "error_code": "CONTRACT_REGISTRY_NOT_OPEN", "error_msg": f"run contract_registry.py open for {directory.parent.name}"}
    try:
        manifest = contract_manifest.build_manifest(directory, tree, systems, prompt.name, contract_manifest.named_contracts(body)) if systems else dict(
            task=prompt.name, tree=str(tree), systems=[], none_reason=none_reason, contracts=[])
    except ValueError as error:
        return None, {"ok": False, "error_code": "CONTRACT_SYSTEM_UNKNOWN", "error_msg": str(error)}
    return manifest, None


def manifest_path(prompt):
    return prompt.with_name(task_name(prompt) + ".manifest.json")


def fleet_command(prompt, session, arguments):
    command = ["nice", "-n", "19", "cc-fleet", "subagent", arguments.pin["provider"], "--model", arguments.pin["model"], "--label", f"queue-{prompt.stem}",
               "--profile", arguments.profile, "--timeout", arguments.timeout,
               "--max-turns", str(arguments.max_turns), "--prompt-file", "-", "--json"]
    if arguments.profile == "slim":
        command += ["--skills=false", "--mcp=false"]
    else:
        command += ["--disallowed-tools", "Bash"]
    if session:
        command += ["--resume", session]
    return command


def kill_group(process):
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def worker_cluster_name(queue, prompt):
    name = re.sub(r"[^a-z0-9_]+", "", f"q{queue.name}_{task_name(prompt)}".lower())
    if len(name) > 32:
        name = name[:25] + hashlib.sha1(name.encode()).hexdigest()[:7]
    return name or "qworker"


def worker_cluster_environment(name):
    completed = subprocess.run(["bash", str(WORKER_CLUSTER), "env", name], capture_output=True, text=True, check=True)
    environment = {}
    for line in completed.stdout.splitlines():
        for variable in ("GXB_TEST_PGHOST", "GXB_TEST_PGPORT"):
            prefix = f"export {variable}="
            if line.startswith(prefix):
                environment[variable] = line.removeprefix(prefix)
    return environment


def start_worker_cluster(queue, prompt):
    name = worker_cluster_name(queue, prompt)
    completed = subprocess.run(["bash", str(WORKER_CLUSTER), "start", name], capture_output=True, text=True)
    if completed.returncode != 0:
        raise RuntimeError(f"worker cluster {name} did not start: {completed.stderr.strip()}")
    ACTIVE_WORKER_CLUSTERS.add(name)
    return name, worker_cluster_environment(name)


def stop_worker_cluster(name):
    ACTIVE_WORKER_CLUSTERS.discard(name)
    completed = subprocess.run(["bash", str(WORKER_CLUSTER), "stop", "--remove", name], capture_output=True, text=True)
    if completed.returncode != 0:
        print(f"queue: worker cluster {name} did not stop: {completed.stderr.strip()}", file=sys.stderr)


def stop_active_worker_clusters():
    for name in sorted(ACTIVE_WORKER_CLUSTERS):
        stop_worker_cluster(name)


def termination_handler(signum, _frame):
    """A killed queue must not leave its writer task's cluster (and seat) behind."""
    stop_active_worker_clusters()
    raise SystemExit(128 + signum)


def install_termination_handlers():
    for signum in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(signum, termination_handler)


def send(command, message, environment=None):
    """The worker runs in its own process group; whatever it left running is killed when the call returns. Output goes
    to files, not pipes, so a leftover child holding the pipe open cannot keep the queue waiting."""
    with tempfile.TemporaryFile("w+") as stdin, tempfile.TemporaryFile("w+") as stdout, tempfile.TemporaryFile("w+") as stderr:
        stdin.write(message)
        stdin.seek(0)
        process = subprocess.Popen(command, stdin=stdin, stdout=stdout, stderr=stderr, text=True, cwd=ROOT, start_new_session=True,
                                   env={**os.environ, **(environment or {}), "CLAUDE_CODE_DISABLE_BACKGROUND_TASKS": "1"})
        try:
            process.wait()
        finally:
            kill_group(process)
        stdout.seek(0)
        stderr.seek(0)
        return read_envelope(subprocess.CompletedProcess(command, process.returncode, stdout.read(), stderr.read()))


def post_check(prompt):
    """(base, database) from the prompt's `Post-Check: preflight` line, or None."""
    match = POST_CHECK_RE.search(prompt.read_text(encoding="utf-8"))
    return match.groups() if match else None


def preflight_command(tree, base, database):
    return ["bash", "-c", f"export GXB_BACKEND={shlex.quote(str(tree))} && source {shlex.quote(str(ROOT / 'ops/testing/goenv.sh'))} && "
            f"exec {shlex.quote(str(ROOT / '.toolchain/bin/python3'))} -B tools/gate_preflight.py --base {shlex.quote(base)} "
            f"--database {shlex.quote(database)}"]


def preflight_verdict(log_text):
    """(GREEN | RED | NO_RESULT, the verdict line and the lines under it)."""
    lines = log_text.splitlines()
    starts = [index for index, line in enumerate(lines) if line.startswith("GATE_PREFLIGHT ")]
    if not starts:
        return "NO_RESULT", lines[-40:]
    tail = lines[starts[-1]:]
    return ("GREEN" if tail[0].startswith("GATE_PREFLIGHT GREEN") else "RED"), tail[:80]


def run_preflight(tree, base, database, log_path, timeout=PREFLIGHT_TIMEOUT_SECONDS, command=None, environment=None):
    """One preflight at a time on this machine; the whole process group dies on timeout or exit."""
    PREFLIGHT_LOCK.parent.mkdir(parents=True, exist_ok=True)
    with PREFLIGHT_LOCK.open("w") as lock, log_path.open("w") as log:
        fcntl.flock(lock, fcntl.LOCK_EX)
        process = subprocess.Popen(command or preflight_command(tree, base, database), stdout=log, stderr=subprocess.STDOUT,
                                   cwd=tree, start_new_session=True, env={**os.environ, **(environment or {})})
        try:
            process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            log.write(f"\nqueue: preflight killed after {timeout} s\n")
        finally:
            kill_group(process)
            process.wait()
    return preflight_verdict(log_path.read_text(encoding="utf-8", errors="replace"))


def enforce_preflight(prompt, manifest, session_id, arguments, answer, environment=None):
    """Runs the prompt's Post-Check; RED gets one follow-up in the same session and a second run.
    Returns (answer, verdict or None, session_id)."""
    check = post_check(prompt)
    if check is None:
        return answer, None, session_id
    tree = pathlib.Path(manifest["tree"])
    log_path = prompt.with_name(task_name(prompt) + ".preflight.log")
    verdict, lines = run_preflight(tree, *check, log_path, environment=environment)
    if verdict != "GREEN":
        follow_up = send(fleet_command(prompt, session_id, arguments), RESUMED_TASK_HEADER + (
            f"The queue ran the preflight on your branch ({log_path}); it ended {verdict}:\n" + "\n".join(lines) +
            "\n\nFix what your branch broke, commit, and reply with what you changed. Do not start the preflight yourself; the queue "
            "runs it again after your reply."), environment=environment)
        if follow_up.get("ok"):
            answer += "\n\n" + (follow_up.get("result") or "")
            session_id = follow_up["session_id"]
        verdict, lines = run_preflight(tree, *check, log_path.with_name(task_name(prompt) + ".preflight2.log"),
                                       environment=environment)
    answer += f"\n\n## Queue preflight\n{verdict}\n```\n" + "\n".join(lines) + "\n```\n"
    return answer, verdict, session_id


def dispatched_session(started_wall, dispatch_id):
    """The transcript whose first lines carry this task's dispatch marker, for a call that ended without an envelope."""
    if not fleet_models.TRANSCRIPTS.is_dir():
        return None
    for path in sorted(fleet_models.TRANSCRIPTS.glob("*.jsonl"), key=lambda path: path.stat().st_mtime, reverse=True):
        if path.stat().st_mtime < started_wall:
            break
        with path.open(encoding="utf-8", errors="replace") as transcript:
            head = "".join(line for _, line in zip(range(12), transcript))
        if DISPATCH_MARKER + dispatch_id in head:
            return path.stem
    return None


def run_task(prompt, session, arguments, manifest, dispatch_id, environment=None):
    fresh = session is None or prompt.name.endswith(".fresh.prompt")
    contract_index.write()
    rules = WORKER_RULES.read_text(encoding="utf-8")
    if fleet_models.pool(arguments.pin) == "codex":
        rules += CODEX_RULES
    body = prompt.read_text(encoding="utf-8")
    if manifest["systems"]:
        body = contract_manifest.render_manifest(manifest) + "\n" + body
    body += f"\n\n{DISPATCH_MARKER}{dispatch_id}\n"
    return fresh, send(fleet_command(prompt, None if fresh else session, arguments), task_message(body, fresh, rules),
                       environment=environment)


def enforce_contracts(prompt, manifest, envelope, arguments, environment=None):
    """Checks the compliance section; one corrective follow-up in the same session, then the verdict is final.
    Returns (answer, status, problems, session_id)."""
    answer = envelope.get("result") or ""
    session_id = envelope["session_id"]
    transcript = fleet_models.TRANSCRIPTS / (session_id + ".jsonl")
    problems = contract_manifest.verify(manifest, answer, transcript)
    if problems:
        follow_up = send(fleet_command(prompt, session_id, arguments), RESUMED_TASK_HEADER + (
            "The contract compliance check failed:\n- " + "\n- ".join(problems[:60]) + "\n\nOpen every contract document "
            "you mark APPLIED or CONFLICT with the Read tool, fix your work if a contract requires it, and reply with the "
            f"complete corrected `{contract_manifest.COMPLIANCE_HEADING}` section covering every manifest row."),
            environment=environment)
        if follow_up.get("ok"):
            answer += "\n\n" + (follow_up.get("result") or "")
            session_id = follow_up["session_id"]
            problems = contract_manifest.verify(manifest, answer, fleet_models.TRANSCRIPTS / (session_id + ".jsonl"))
        else:
            problems = problems + [f"the corrective follow-up failed: {follow_up.get('error_code')}"]
    status = contract_manifest.outcome(manifest, answer, problems)
    return answer, status, problems or contract_manifest.conflict_rows(answer), session_id


def window_spent(envelope, pin, waited_seconds):
    """A spent Codex 5-hour window answers 429 after claude's ~180 s of retries, indistinguishable from a short limit."""
    return envelope.get("error_code") == "RATE_LIMITED" and waited_seconds < pin.get("limit_wait_hours", 0) * 3600


def work(queue, arguments):
    session_file = queue / "session.json"
    state = json.loads(session_file.read_text()) if session_file.exists() else {}
    waited_seconds, held_any = 0, False
    while (prompt := next_task(queue)) is not None:
        if arguments.pin.get("peak", True) and not arguments.allow_peak:
            wait_for_peak(False)
        keep_session = (state.get("context", 0) <= arguments.rotate_context
                        and state.get("profile") == arguments.profile
                        and state.get("model") == arguments.pin["model"])
        started, started_wall, dispatch_id = time.monotonic(), time.time(), uuid.uuid4().hex
        manifest, refusal = contract_manifest_for(prompt)
        if refusal:
            prompt.with_name(prompt.stem + ".error.json").write_text(json.dumps(refusal, indent=1) + "\n")
            print(f"{prompt.name} refused: {refusal['error_code']}: {refusal['error_msg']}")
            return EXIT_TASK_FAILED
        manifest_path(prompt).write_text(json.dumps(manifest, indent=1) + "\n", encoding="utf-8")
        start_head = contract_manifest.tree_head(pathlib.Path(manifest["tree"]))
        cluster_name, cluster_environment = (None, {})
        if arguments.profile == "slim" and not arguments.no_cluster:
            cluster_name, cluster_environment = start_worker_cluster(queue, prompt)
        try:
            fresh, envelope = run_task(prompt, state.get("session_id") if keep_session else None, arguments, manifest, dispatch_id,
                                       environment=cluster_environment)
            if not envelope.get("ok") and window_spent(envelope, arguments.pin, waited_seconds):
                print(f"{prompt.name}: usage window spent, retrying in {LIMIT_POLL_SECONDS} s", flush=True)
                time.sleep(LIMIT_POLL_SECONDS)
                waited_seconds += LIMIT_POLL_SECONDS
                continue
            waited_seconds = 0
            if not envelope.get("ok"):
                record_failed_task(prompt, manifest, envelope, start_head, dispatched_session(started_wall, dispatch_id), state,
                                   session_file, arguments)
                return EXIT_TASK_FAILED
            answer, contract_status, problems, session_id = enforce_contracts(prompt, manifest, envelope, arguments,
                                                                              environment=cluster_environment)
            preflight = None
            if contract_status == "PASS" or not manifest["systems"]:
                answer, preflight, session_id = enforce_preflight(prompt, manifest, session_id, arguments, answer,
                                                                  environment=cluster_environment)
        finally:
            if cluster_name:
                stop_worker_cluster(cluster_name)
        if preflight not in (None, "GREEN") and contract_status == "PASS":
            contract_status, problems = "FAIL", problems + [f"queue preflight {preflight}"]
        envelope["session_id"] = session_id
        answer_path(prompt).write_text(answer, encoding="utf-8")
        if manifest["systems"]:
            contract_manifest.record_dispatch(manifest, manifest_path(prompt), contract_status, problems, session_id,
                                              fleet_models.pool(arguments.pin), arguments.pin["model"])
        transcript = fleet_models.TRANSCRIPTS / (envelope["session_id"] + ".jsonl")
        start_line = 0 if fresh else state.get("lines", 0)
        usage = transcript_usage(transcript, start_line)
        state = {"session_id": envelope["session_id"], "profile": arguments.profile, "model": arguments.pin["model"],
                 "context": usage["context"], "lines": usage["lines"]}
        session_file.write_text(json.dumps(state) + "\n")
        row = {"task": prompt.name, "model": arguments.pin["model"], "fresh_session": fresh, "session_id": envelope["session_id"],
               "rules_sha256": hashlib.sha256(WORKER_RULES.read_bytes()).hexdigest()[:12],
               "seconds": round(time.monotonic() - started), **usage, "preflight": preflight, "envelope_turns": envelope.get("num_turns"),
               "contract_systems": manifest["systems"], "contract_revision": manifest.get("revision"), "contract_status":
               contract_status if manifest["systems"] else "NONE_DECLARED"}
        with (queue / "usage.jsonl").open("a") as log:
            log.write(json.dumps(row) + "\n")
        print(json.dumps(row), flush=True)
        if usage["invalid_tool_calls"]:
            print(f"{prompt.name}: WARNING {usage['invalid_tool_calls']} tool calls failed InputValidationError "
                  "(on a codex route: the one-call rule did not hold, or the session compacted; see FLEET_GUIDE Codex routes)", flush=True)
        foreign = fleet_models.foreign_models(transcript, arguments.pin["model"], start_line)
        if foreign:
            print(f"{prompt.name} was answered by {foreign}, not the pinned {arguments.pin['model']}; stopping")
            return EXIT_TASK_FAILED
        if (manifest["systems"] and contract_status != "PASS") or preflight not in (None, "GREEN"):
            held_path(prompt).write_text(json.dumps({"contract_status": contract_status, "preflight": preflight,
                                                     "problems": problems[:20]}, indent=1) + "\n")
            print(f"{prompt.name}: HELD (contract {contract_status}, preflight {preflight}): {'; '.join(problems[:5])}; "
                  "continuing with tasks that do not depend on it", flush=True)
            held_any = True
    return EXIT_TASK_FAILED if held_any else 0


def record_failed_task(prompt, manifest, envelope, start_head, session_id, state, session_file, arguments):
    """A timeout or crash keeps what the worker made: its session (resumed by the next non-fresh prompt), its commits,
    and a dispatch row, so the merge check asks for a check task instead of reporting the systems UNCOVERED."""
    tree = pathlib.Path(manifest["tree"])
    end_head = contract_manifest.tree_head(tree)
    commits = subprocess.run(["git", "-C", str(tree), "log", "--format=%h %s", f"{start_head}..{end_head}"], capture_output=True,
                             text=True).stdout.splitlines() if start_head and end_head and start_head != end_head else []
    dirty = subprocess.run(["git", "-C", str(tree), "status", "--porcelain", "--untracked-files=normal"], capture_output=True,
                           text=True).stdout.splitlines() if start_head else []
    record = {**envelope, "session_id_found": session_id, "commits": commits, "uncommitted": dirty[:50]}
    prompt.with_name(prompt.stem + ".error.json").write_text(json.dumps(record, indent=1) + "\n")
    if session_id:
        session_file.write_text(json.dumps({**state, "session_id": session_id, "profile": arguments.profile,
                                            "model": arguments.pin["model"], "context": 0, "lines": 0}) + "\n")
    if manifest["systems"] and commits:
        status = "TIMEOUT" if envelope.get("error_code") == "SUBAGENT_TIMEOUT" else "FAILED"
        contract_manifest.record_dispatch(manifest, manifest_path(prompt), status, [f"task ended {envelope.get('error_code')}"],
                                          session_id, fleet_models.pool(arguments.pin), arguments.pin["model"])
    print(f"{prompt.name} failed: {envelope.get('error_code')}; session {session_id or 'not found'}; {len(commits)} commits, "
          f"{len(dirty)} uncommitted files; a non-fresh prompt next resumes the session", flush=True)


def notify_codex_completion(queue, thread, exit_status):
    message = (
        f"AUTOMATED_FLEET_COMPLETION: Queue {queue} exited with exit status {exit_status}. "
        "This is an automated completion event, not new user authorization or proof of success. "
        "Read the existing canonical lead state and completed reports/error files; adjudicate "
        "and continue within the existing scope. Do not poll or blindly repeat the queue."
    )
    record = {"thread": str(thread), "queue_exit_status": exit_status,
              "status": "QUEUE_OR_RESUME_UNCONFIRMED"}
    try:
        result = subprocess.run(["codex", "queue", "--thread", str(thread), "--message", message, "--resume"],
                                capture_output=True, text=True, timeout=20)
        record.update(returncode=result.returncode, stdout=result.stdout[-4000:], stderr=result.stderr[-4000:])
        if result.returncode == 0 and not result.stderr.strip():
            record["status"] = "QUEUED_DELIVERY_UNVERIFIED"
    except (OSError, subprocess.TimeoutExpired) as error:
        record["error"] = str(error)
    try:
        (queue / "codex_completion.json").write_text(json.dumps(record, indent=1) + "\n")
    except OSError as error:
        print(f"Cannot record Codex completion notification: {error}", file=sys.stderr)
    print(json.dumps(record), flush=True)


def self_check():
    fleet_models.self_check()
    utc = datetime.timezone.utc
    assert is_peak(datetime.datetime(2026, 10, 30, 1, 0, tzinfo=utc))
    assert not is_peak(datetime.datetime(2026, 10, 30, 4, 0, tzinfo=utc))
    assert is_peak(datetime.datetime(2026, 10, 30, 9, 59, tzinfo=utc))
    assert not is_peak(datetime.datetime(2026, 10, 31, 9, 0, tzinfo=utc))
    bad_flag = subprocess.CompletedProcess([], 1, stdout="", stderr="unknown flag")
    assert read_envelope(bad_flag)["error_code"] == "NO_ENVELOPE" and not read_envelope(bad_flag)["ok"]
    refused = subprocess.CompletedProcess([], 1, stdout='{"ok": true}', stderr="")
    assert not read_envelope(refused)["ok"]
    with tempfile.TemporaryDirectory() as directory:
        transcript = pathlib.Path(directory) / "t.jsonl"
        rows = [{"type": "assistant", "message": {"id": "a", "usage": {"input_tokens": 1}}},
                {"type": "assistant", "message": {"id": "a", "usage": {"input_tokens": 5, "output_tokens": 2}}},
                {"type": "user", "message": {"content": "next"}},
                {"type": "assistant", "message": {"id": "b", "usage": {"input_tokens": 1, "cache_read_input_tokens": 9}}}]
        transcript.write_text("".join(json.dumps(row) + "\n" for row in rows))
        assert transcript_usage(transcript) == {"turns": 2, "input": 6, "cache_read": 9, "output": 2, "cache_write": 0, "context": 10, "lines": 4,
                                                "invalid_tool_calls": 0, "compactions": 0}
        rejected = {"type": "tool_result", "is_error": True, "content": "<tool_use_error>InputValidationError: Read failed</tool_use_error>"}
        transcript.write_text(transcript.read_text() + json.dumps({"type": "user", "message": {"content": [rejected]}}) + "\n")
        assert transcript_usage(transcript)["invalid_tool_calls"] == 1
        assert transcript_usage(transcript, 2)["turns"] == 1
    limited, codex = {"error_code": "RATE_LIMITED"}, {"limit_wait_hours": 6}
    assert window_spent(limited, codex, 0) and not window_spent(limited, codex, 6 * 3600)
    assert not window_spent(limited, {}, 0) and not window_spent({"error_code": "SUBAGENT_FAILED"}, codex, 0)
    assert answer_path(pathlib.Path("q/02-a.fresh.prompt")) == pathlib.Path("q/02-a.md")
    assert worker_cluster_name(pathlib.Path("/x/queue9"), pathlib.Path("q/01-a.fresh.prompt")) == "qqueue9_01a"
    assert len(worker_cluster_name(pathlib.Path("/x/" + "z" * 40), pathlib.Path("q/01-a.fresh.prompt"))) == 32
    assert task_message("do it", True, "RULES").startswith("RULES") and task_message("do it", True, "RULES").endswith("do it")
    assert "RULES" not in task_message("do it", False, "RULES") and task_message("do it", False, "RULES").endswith("do it")
    assert WORKER_RULES.read_text(encoding="utf-8").strip()
    contract_manifest.self_check()
    with tempfile.TemporaryDirectory() as directory:
        prompt = pathlib.Path(directory) / "03-x.fresh.prompt"
        prompt.write_text("no header\n")
        assert contract_manifest_for(prompt)[1]["error_code"] == "CONTRACT_HEADER_MISSING"
        prompt.write_text("Contract-Systems: none\n")
        assert contract_manifest_for(prompt)[1]["error_code"] == "CONTRACT_HEADER_MISSING"
        prompt.write_text("Contract-Systems: none - asset files only\n")
        assert contract_manifest_for(prompt)[0]["systems"] == [] and manifest_path(prompt).name == "03-x.manifest.json"


def duration(text):
    if not re.fullmatch(r"\d+(?:ms|s|m|h)", text):
        raise argparse.ArgumentTypeError(f"{text!r} needs a unit, e.g. 3600s")
    return text


def main():
    self_check()
    install_termination_handlers()
    parser = argparse.ArgumentParser()
    parser.add_argument("queue", type=pathlib.Path, nargs="?")
    parser.add_argument("--wait", choices=("peak", "off-peak"), help="block until then and exit, without running a queue")
    parser.add_argument("--profile", default="slim-ro", choices=("slim-ro", "slim"))
    parser.add_argument("--no-cluster", action="store_true", help="slim without a PostgreSQL cluster or test seat: research and reports that run no native test")
    parser.add_argument("--timeout", default="1800s", type=duration, help="with a unit, e.g. 3600s; cc-fleet rejects a bare number")
    parser.add_argument("--max-turns", type=int, default=80)
    parser.add_argument("--rotate-context", type=int, default=150000)
    parser.add_argument("--allow-peak", action="store_true")
    parser.add_argument("--route", default="primary", choices=fleet_models.ROUTES)
    parser.add_argument("--slots", default=WORKER_SLOTS, type=int, choices=range(1, MAX_WORKER_SLOTS + 1), metavar=f"1..{MAX_WORKER_SLOTS}",
                        help="the pool slots this queue may take (default 3); raise only for a lead-approved burst of independent read-only tasks")
    parser.add_argument("--notify-codex-thread", type=uuid.UUID, help="queue one completion message and try resuming this exact Codex thread after a nonempty run")
    arguments = parser.parse_args()
    if arguments.wait:
        wait_for_peak(arguments.wait == "peak")
        return 0
    if arguments.queue is None:
        parser.error("a queue directory is required without --wait")
    arguments.pin = fleet_models.load()[arguments.route]
    WORKER_LOCK_DIRECTORY.mkdir(parents=True, exist_ok=True)
    queue_lock = (WORKER_LOCK_DIRECTORY / hashlib.sha256(str(arguments.queue.resolve()).encode()).hexdigest()).open("w")
    if not try_lock(queue_lock):
        parser.error(f"another run already holds {arguments.queue}")
    queue = arguments.queue.resolve()
    had_pending_task = next_task(queue) is not None
    exit_status = EXIT_TASK_FAILED
    try:
        with acquire_worker_slot(fleet_models.pool(arguments.pin), arguments.slots):
            exit_status = work(queue, arguments)
    finally:
        queue_lock.close()
        if had_pending_task and arguments.notify_codex_thread:
            notify_codex_completion(queue, arguments.notify_codex_thread, exit_status)
    return exit_status


if __name__ == "__main__":
    sys.exit(main())
