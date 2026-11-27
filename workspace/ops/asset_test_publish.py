#!/usr/bin/env python3
"""Publish one asset-experimental tree to the real-client test harness.

The wrapper points the OTA recovered_res_path at a task's res folder, builds a
silent code release with the lazy refresh and publishes it, keeping the accepted
tree in work/asset_experimental/LIVE.json.
"""

import argparse
import fcntl
import json
import os
import re
import subprocess
import sys
import tempfile
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
LANE_ROOT = REPO_ROOT / "work" / "asset_experimental"
LIVE_FILE = LANE_ROOT / "LIVE.json"
LOCK_FILE = LANE_ROOT / ".live.lock"
OPERATOR_BINARY = REPO_ROOT / "test_harness" / "runtime" / "bin" / "gxb-operator"
AGENT_ROOT = REPO_ROOT / "test_harness" / "runtime" / "agent"
PASSWORD_FILE = REPO_ROOT / "test_harness" / "runtime" / "state" / "operator_password"

TASK_ID_PATTERN = re.compile(r"x\d{2}-[a-z0-9-]+")


class Refused(Exception):
    pass


def filter_password(text, password):
    if not password:
        return text
    return "".join(line for line in text.splitlines(keepends=True) if password not in line)


def resolve_task_tree(task_id, lane_root):
    if not isinstance(task_id, str) or not TASK_ID_PATTERN.fullmatch(task_id):
        raise Refused(f"task id {task_id!r} is not xNN-slug lowercase")
    base = Path(lane_root).resolve()
    tree = base
    for part in (task_id, "res", "web"):
        tree = tree / part
        if tree.is_symlink():
            raise Refused(f"{tree} is a symlink")
    try:
        resolved = tree.resolve(strict=True)
    except FileNotFoundError:
        raise Refused(f"{tree} does not exist")
    except OSError as error:
        raise Refused(f"{tree} cannot be resolved: {error}")
    if not resolved.is_dir():
        raise Refused(f"{resolved} is not a directory")
    if not resolved.is_relative_to(base):
        raise Refused(f"{resolved} is outside {base}")
    entries = list(resolved.rglob("*"))
    linked = next((entry for entry in entries if entry.is_symlink()), None)
    if linked is not None:
        raise Refused(f"{linked} is a symlink")
    if not any(entry.is_file() for entry in entries):
        raise Refused(f"{resolved} has no regular files")
    return resolved, resolved.parent


def resolve_restore_tree(accepted_res_path):
    if not accepted_res_path:
        raise Refused("LIVE.json has no accepted_res_path to restore")
    root = Path(accepted_res_path)
    if not root.is_absolute():
        raise Refused(f"accepted_res_path {accepted_res_path!r} is not absolute")
    try:
        resolved = root.resolve(strict=True)
    except FileNotFoundError:
        raise Refused(f"accepted_res_path {accepted_res_path!r} does not exist")
    except OSError as error:
        raise Refused(f"accepted_res_path {accepted_res_path!r} cannot be resolved: {error}")
    if not resolved.is_dir():
        raise Refused(f"{resolved} is not a directory")
    if not (resolved / "web").is_dir():
        raise Refused(f"{resolved} has no web folder")
    return resolved


def load_live():
    if not LIVE_FILE.exists():
        return {}
    try:
        document = json.loads(LIVE_FILE.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise Refused(f"{LIVE_FILE} is unreadable: {error}")
    if not isinstance(document, dict):
        raise Refused(f"{LIVE_FILE} is not a JSON object")
    return document


def record_accepted(live, current_recovered_res_path):
    # An empty accepted path is still a recorded answer; re-recording would accept an experimental tree.
    if "accepted_res_path" in live:
        return False
    live["accepted_res_path"] = current_recovered_res_path
    return True


def write_live(live):
    LIVE_FILE.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(dir=LIVE_FILE.parent, prefix=".LIVE-", suffix=".json")
    try:
        with os.fdopen(descriptor, "w") as handle:
            json.dump(live, handle, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, LIVE_FILE)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


@contextmanager
def lane_lock():
    LANE_ROOT.mkdir(parents=True, exist_ok=True)
    handle = open(LOCK_FILE, "a+")
    try:
        try:
            fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise Refused("another publish is running")
        yield
    finally:
        handle.close()


def read_password():
    try:
        text = PASSWORD_FILE.read_text()
    except OSError as error:
        raise Refused(f"cannot read {PASSWORD_FILE}: {error}")
    lines = text.splitlines()
    if not lines or not lines[0]:
        raise Refused(f"{PASSWORD_FILE} is empty")
    return lines[0]


def run_operator(arguments, password, stdin_text=None):
    if not OPERATOR_BINARY.is_file():
        raise Refused(f"{OPERATOR_BINARY} is missing")
    command = [str(OPERATOR_BINARY), "--root", str(AGENT_ROOT), *arguments]
    options = {"input": stdin_text, "capture_output": True, "text": True}
    if stdin_text is None:
        options["stdin"] = subprocess.DEVNULL
    try:
        completed = subprocess.run(command, **options)
    except OSError as error:
        raise Refused(f"cannot run {OPERATOR_BINARY}: {error}")
    if completed.returncode == 0:
        return completed.stdout
    shown = filter_password(completed.stdout + completed.stderr, password)
    if shown.strip():
        print(shown.rstrip("\n"))
    raise Refused(f"{arguments[0]} failed with exit code {completed.returncode}")


def json_objects(text):
    decoder = json.JSONDecoder()
    objects = []
    index = 0
    while index < len(text):
        while index < len(text) and text[index].isspace():
            index += 1
        if index >= len(text):
            break
        try:
            value, end = decoder.raw_decode(text, index)
        except json.JSONDecodeError:
            newline = text.find("\n", index)
            if newline < 0:
                break
            index = newline + 1
            continue
        objects.append(value)
        index = end
    return objects


def read_status(password):
    output = run_operator(["read", "ota.status"], password)
    try:
        status = json.loads(output)
    except json.JSONDecodeError as error:
        shown = filter_password(output, password)
        if shown.strip():
            print(shown.rstrip("\n"))
        raise Refused(f"ota.status did not answer JSON: {error}")
    settings = status.get("settings")
    if not isinstance(settings, dict):
        raise Refused("ota.status answered no settings object")
    return status, settings


def set_recovered_res_path(settings, path_text, reason, password):
    next_settings = dict(settings)
    next_settings["recovered_res_path"] = path_text
    run_operator(
        ["cmd", "ota.settings.set", "--reason", reason, json.dumps(next_settings)],
        password,
    )


def build_code_release(version, password):
    output = run_operator(
        ["ota", "build", "--lane", "code", "--version", version, "--lazy-refresh"],
        password,
    )
    objects = json_objects(output)
    if not objects:
        raise Refused("ota build printed no operation document")
    operation = objects[-1]
    if not isinstance(operation, dict):
        raise Refused("ota build printed no operation document")
    if operation.get("state") != "DONE":
        detail = operation.get("error") or "the build operation did not finish"
        raise Refused(f"ota build is {operation.get('state')}: {detail}")
    result = operation.get("result")
    report = result.get("report") if isinstance(result, dict) else None
    if not isinstance(report, dict):
        raise Refused("the build operation carried no build report")
    recovered_lazy_rows = report.get("lazy_recovered")
    if not isinstance(recovered_lazy_rows, int):
        raise Refused("the build report has no lazy_recovered count")
    release_version = report.get("version") or version
    return release_version, recovered_lazy_rows


def publish_release(version, reason, password):
    run_operator(["ota", "publish", version, "--reason", reason], password)


def print_summary(label, res_tree, release_version, recovered_lazy_rows):
    print(f"task: {label}")
    print(f"res path: {res_tree}")
    print(f"release: {release_version}")
    print(f"recovered lazy rows: {recovered_lazy_rows}")
    print("OK")


def publish(task_id, restore=False):
    live = load_live()
    if restore:
        res_root = resolve_restore_tree(live.get("accepted_res_path"))
        res_tree = res_root / "web"
        label = "restore"
    else:
        res_tree, res_root = resolve_task_tree(task_id, LANE_ROOT)
        label = task_id
    with lane_lock():
        live = load_live()
        password = read_password()
        logged_in = False
        try:
            run_operator(["login"], password, stdin_text=password + "\n")
            logged_in = True
            reason = "asset test restore accepted tree" if restore else f"asset test publish {label}"
            status, settings = read_status(password)
            current_recovered_res_path = settings.get("recovered_res_path")
            if not isinstance(current_recovered_res_path, str):
                raise Refused("ota.status settings carry no recovered_res_path")
            if record_accepted(live, current_recovered_res_path):
                write_live(live)
            next_version = status.get("next_version")
            if not isinstance(next_version, str) or not next_version:
                raise Refused("no OTA release exists yet; the lead publishes the first release before asset tests")
            set_recovered_res_path(settings, str(res_root), reason, password)
            release_version, recovered_lazy_rows = build_code_release(next_version, password)
            publish_release(release_version, reason, password)
            live.update(
                {
                    "live_task": None if restore else task_id,
                    "live_res_path": str(res_root),
                    "release": release_version,
                    "at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                }
            )
            write_live(live)
            print_summary(label, res_tree, release_version, recovered_lazy_rows)
        finally:
            if logged_in:
                try:
                    run_operator(["logout"], password)
                except Refused:
                    pass


def print_status():
    live = load_live()
    if not live:
        print("no live record")
        return
    print(json.dumps(live, indent=2, sort_keys=True))


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Publish an asset-experimental tree through a silent OTA code release."
    )
    parser.add_argument("task_id", nargs="?", help="asset-experimental task id (xNN-slug)")
    parser.add_argument("--restore", action="store_true", help="switch back to the accepted tree and publish")
    parser.add_argument("--status", action="store_true", help="print the live record without a CLI login")
    arguments = parser.parse_args(argv)
    chosen = [arguments.task_id is not None, arguments.restore, arguments.status]
    if sum(chosen) != 1:
        parser.error("give one task id, --restore or --status")
    try:
        if arguments.status:
            print_status()
            return 0
        publish(arguments.task_id, restore=arguments.restore)
        return 0
    except Refused as error:
        print(f"refused: {error}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
