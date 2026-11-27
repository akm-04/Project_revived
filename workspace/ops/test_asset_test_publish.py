#!/usr/bin/env python3
"""Tests for ops/asset_test_publish.py; the operator CLI is a fake executable."""

import contextlib
import fcntl
import importlib.util
import io
import json
import stat
import sys
import tempfile
import unittest
from pathlib import Path

PASSWORD = "sup3rSecret!"

FAKE_OPERATOR = r'''#!{interpreter}
import json
import sys
from pathlib import Path

directory = Path(__file__).resolve().parent
arguments = sys.argv[1:]
rest = []
index = 0
while index < len(arguments):
    if arguments[index] == "--root":
        index += 2
        continue
    rest.append(arguments[index])
    index += 1
stdin_text = sys.stdin.readline() if rest and rest[0] == "login" else ""
with (directory / "calls.jsonl").open("a") as log:
    log.write(json.dumps({{"arguments": rest, "stdin": stdin_text}}) + "\n")
behaviour = {{}}
behaviour_path = directory / "behaviour.json"
if behaviour_path.exists():
    behaviour = json.loads(behaviour_path.read_text())
command = rest[0]
if behaviour.get("fail_on") == command:
    sys.stderr.write(behaviour.get("error", "boom") + "\n")
    sys.exit(1)
if command == "login":
    print("logged in; the session expires at 2030-01-01T00:00:00Z")
elif command == "logout":
    print('{{"state": "logged out"}}')
elif command == "read":
    print(json.dumps({{
        "revision": 4,
        "next_version": "1.631.3",
        "settings": {{
            "lazy_fetch": "auto",
            "res_path": "/srv/res",
            "apk_res_path": "",
            "recovered_res_path": "/srv/accepted",
            "download_base_seconds": 5,
            "download_min_kib_per_second": 100,
            "cache_max_age_seconds": 60,
            "serving_refresh_seconds": 5,
            "volume_mb": 99,
        }},
    }}))
elif command == "cmd":
    print(json.dumps({{"revision": 5}}))
elif command == "ota":
    action = rest[1]
    if action == "build":
        print(json.dumps({{"operation_id": "a" * 32}}))
        print(json.dumps({{
            "id": "a" * 32,
            "kind": "ota.build",
            "state": "DONE",
            "steps": [],
            "result": {{
                "release": {{"version": "1.631.3"}},
                "report": {{"version": "1.631.3", "lazy_recovered": 7}},
            }},
        }}))
    else:
        print(json.dumps({{"activation_id": 1, "version": rest[2], "action": "PUBLISH", "state": "ACTIVE"}}))
'''


def load_module():
    path = Path(__file__).with_name("asset_test_publish.py")
    spec = importlib.util.spec_from_file_location("asset_test_publish", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


module = load_module()


class ScratchLaneCase(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.saved = {}
        for name in ("LANE_ROOT", "LIVE_FILE", "LOCK_FILE", "OPERATOR_BINARY", "AGENT_ROOT", "PASSWORD_FILE"):
            self.saved[name] = getattr(module, name)
        self.lane = self.root / "lane"
        self.lane.mkdir()
        module.LANE_ROOT = self.lane
        module.LIVE_FILE = self.lane / "LIVE.json"
        module.LOCK_FILE = self.lane / ".live.lock"
        self.agent = self.root / "agent"
        self.agent.mkdir()
        module.AGENT_ROOT = self.agent
        self.password_file = self.root / "state" / "operator_password"
        self.password_file.parent.mkdir()
        self.password_file.write_text(PASSWORD + "\n")
        module.PASSWORD_FILE = self.password_file

    def tearDown(self):
        for name, value in self.saved.items():
            setattr(module, name, value)
        self.temporary.cleanup()

    def install_fake_operator(self):
        binary = self.root / "bin" / "gxb-operator"
        binary.parent.mkdir()
        binary.write_text(FAKE_OPERATOR.format(interpreter=sys.executable))
        binary.chmod(binary.stat().st_mode | stat.S_IXUSR)
        module.OPERATOR_BINARY = binary
        return binary

    def set_behaviour(self, **behaviour):
        (module.OPERATOR_BINARY.parent / "behaviour.json").write_text(json.dumps(behaviour))

    def calls(self):
        path = module.OPERATOR_BINARY.parent / "calls.jsonl"
        if not path.exists():
            return []
        return [json.loads(line) for line in path.read_text().splitlines()]

    def make_task(self, task_id="x01-sound", files=("a.png",)):
        tree = self.lane / task_id / "res" / "web"
        tree.mkdir(parents=True)
        for name in files:
            (tree / name).write_bytes(b"asset")
        return tree

    def live(self):
        return json.loads(module.LIVE_FILE.read_text())

    def capture(self, action):
        output = io.StringIO()
        error = io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(error):
            result = action()
        return result, output.getvalue(), error.getvalue()


class TaskTreeValidationTest(ScratchLaneCase):
    def test_valid_tree_resolves_to_web_and_res(self):
        tree = self.make_task()
        resolved, res_root = module.resolve_task_tree("x01-sound", self.lane)
        self.assertEqual(resolved, tree.resolve())
        self.assertEqual(res_root, tree.resolve().parent)

    def test_traversal_ids_are_refused(self):
        for task_id in ("x01-../../evil", "../x01-evil", "x1-short", "x01-Upper", "x01-a_b", ""):
            with self.subTest(task_id=task_id):
                with self.assertRaises(module.Refused):
                    module.resolve_task_tree(task_id, self.lane)

    def test_missing_tree_is_refused(self):
        with self.assertRaises(module.Refused):
            module.resolve_task_tree("x01-missing", self.lane)

    def test_symlinked_web_is_refused(self):
        real = self.lane / "shared" / "web"
        real.mkdir(parents=True)
        (real / "a.png").write_bytes(b"asset")
        tree = self.lane / "x01-sound" / "res"
        tree.mkdir(parents=True)
        (tree / "web").symlink_to(real)
        with self.assertRaises(module.Refused):
            module.resolve_task_tree("x01-sound", self.lane)

    def test_symlinked_res_is_refused(self):
        real = self.lane / "shared"
        (real / "web").mkdir(parents=True)
        (real / "web" / "a.png").write_bytes(b"asset")
        task = self.lane / "x01-sound"
        task.mkdir()
        (task / "res").symlink_to(real)
        with self.assertRaises(module.Refused):
            module.resolve_task_tree("x01-sound", self.lane)

    def test_symlinked_task_directory_outside_lane_is_refused(self):
        outside = self.root / "outside"
        (outside / "res" / "web").mkdir(parents=True)
        (outside / "res" / "web" / "a.png").write_bytes(b"asset")
        (self.lane / "x01-sound").symlink_to(outside)
        with self.assertRaises(module.Refused):
            module.resolve_task_tree("x01-sound", self.lane)

    def test_symlinked_file_inside_tree_is_refused(self):
        outside = self.root / "secret.json"
        outside.write_bytes(b"secret")
        web = self.lane / "x01-sound" / "res" / "web" / "sound"
        web.mkdir(parents=True)
        (web / "a.mp3").write_bytes(b"asset")
        (web / "b.mp3").symlink_to(outside)
        with self.assertRaises(module.Refused):
            module.resolve_task_tree("x01-sound", self.lane)

    def test_empty_tree_is_refused(self):
        self.make_task(files=())
        with self.assertRaises(module.Refused):
            module.resolve_task_tree("x01-sound", self.lane)

    def test_web_file_is_refused(self):
        tree = self.lane / "x01-sound" / "res"
        tree.mkdir(parents=True)
        (tree / "web").write_bytes(b"not a directory")
        with self.assertRaises(module.Refused):
            module.resolve_task_tree("x01-sound", self.lane)

    def test_restore_requires_a_web_folder(self):
        accepted = self.root / "accepted"
        accepted.mkdir()
        with self.assertRaises(module.Refused):
            module.resolve_restore_tree(str(accepted))
        with self.assertRaises(module.Refused):
            module.resolve_restore_tree("")
        with self.assertRaises(module.Refused):
            module.resolve_restore_tree("relative/path")


class PasswordFilterTest(unittest.TestCase):
    def test_lines_with_the_password_are_dropped(self):
        text = "first\nleak sup3rSecret! here\nlast\n"
        self.assertEqual(module.filter_password(text, PASSWORD), "first\nlast\n")

    def test_text_without_the_password_is_unchanged(self):
        self.assertEqual(module.filter_password("plain\n", PASSWORD), "plain\n")

    def test_empty_password_does_not_drop_everything(self):
        self.assertEqual(module.filter_password("plain\n", ""), "plain\n")

    def test_json_objects_ignores_separating_whitespace(self):
        objects = module.json_objects('{"one": 1}\n {"two": 2}\n')
        self.assertEqual(objects, [{"one": 1}, {"two": 2}])


class LiveRecordTest(ScratchLaneCase):
    def test_accepted_path_is_seeded_only_when_missing(self):
        live = {}
        self.assertTrue(module.record_accepted(live, "/srv/accepted"))
        self.assertEqual(live, {"accepted_res_path": "/srv/accepted"})
        self.assertFalse(module.record_accepted(live, "/other/accepted"))
        self.assertEqual(live["accepted_res_path"], "/srv/accepted")
        lead_edited = {"accepted_res_path": "/lead/accepted"}
        self.assertFalse(module.record_accepted(lead_edited, "/other/accepted"))
        self.assertEqual(lead_edited["accepted_res_path"], "/lead/accepted")
        empty_recorded = {}
        self.assertTrue(module.record_accepted(empty_recorded, ""))
        self.assertFalse(module.record_accepted(empty_recorded, "/experimental/x01/res"))
        self.assertEqual(empty_recorded["accepted_res_path"], "")

    def test_write_and_load_round_trip(self):
        module.write_live({"accepted_res_path": "/srv/accepted"})
        self.assertEqual(module.load_live(), {"accepted_res_path": "/srv/accepted"})

    def test_malformed_live_file_is_refused(self):
        module.LIVE_FILE.write_text("not json")
        with self.assertRaises(module.Refused):
            module.load_live()


class PublishFlowTest(ScratchLaneCase):
    def setUp(self):
        super().setUp()
        self.install_fake_operator()
        self.tree = self.make_task()

    def test_publish_switches_builds_publishes_and_records_live(self):
        result, output, error = self.capture(lambda: module.publish("x01-sound"))
        self.assertIsNone(result)
        self.assertIn("task: x01-sound", output)
        self.assertIn("recovered lazy rows: 7", output)
        self.assertIn("OK", output)
        self.assertEqual(error, "")

        calls = self.calls()
        self.assertEqual([call["arguments"][0] for call in calls], ["login", "read", "cmd", "ota", "ota", "logout"])
        login = calls[0]
        self.assertEqual(login["stdin"], PASSWORD + "\n")
        for call in calls:
            self.assertNotIn(PASSWORD, " ".join(call["arguments"]))

        settings_call = calls[2]["arguments"]
        self.assertEqual(settings_call[:2], ["cmd", "ota.settings.set"])
        payload = json.loads(settings_call[-1])
        self.assertEqual(payload["recovered_res_path"], str(self.tree.parent))
        self.assertEqual(payload["res_path"], "/srv/res")
        self.assertEqual(payload["volume_mb"], 99)

        build = calls[3]["arguments"]
        for token in ("--lane", "code", "--version", "1.631.3", "--lazy-refresh"):
            self.assertIn(token, build)
        self.assertEqual(calls[4]["arguments"][:3], ["ota", "publish", "1.631.3"])

        live = self.live()
        self.assertEqual(live["accepted_res_path"], "/srv/accepted")
        self.assertEqual(live["live_task"], "x01-sound")
        self.assertEqual(live["live_res_path"], str(self.tree.parent))
        self.assertEqual(live["release"], "1.631.3")
        self.assertIn("at", live)

    def test_accepted_path_is_never_overwritten(self):
        module.write_live({"accepted_res_path": "/lead/accepted", "release": "1.631.1"})
        self.capture(lambda: module.publish("x01-sound"))
        self.assertEqual(self.live()["accepted_res_path"], "/lead/accepted")
        self.assertEqual(self.live()["release"], "1.631.3")

    def test_cli_failure_prints_filtered_error_and_keeps_live_fields(self):
        self.set_behaviour(fail_on="cmd", error="leaked " + PASSWORD + "\ncommand failed after that")
        output = io.StringIO()
        error = io.StringIO()
        with self.assertRaises(module.Refused), contextlib.redirect_stdout(output), contextlib.redirect_stderr(error):
            module.publish("x01-sound")
        self.assertNotIn(PASSWORD, output.getvalue() + error.getvalue())
        self.assertIn("command failed after that", output.getvalue())
        live = self.live()
        self.assertEqual(live["accepted_res_path"], "/srv/accepted")
        self.assertNotIn("release", live)
        self.assertNotIn("live_task", live)
        self.assertNotIn("live_res_path", live)
        self.assertEqual(self.calls()[-1]["arguments"][0], "logout")

    def test_another_publish_holding_the_lock_is_refused(self):
        handle = open(module.LOCK_FILE, "a+")
        try:
            fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            with self.assertRaises(module.Refused):
                module.publish("x01-sound")
        finally:
            handle.close()
        self.assertEqual(self.calls(), [])

    def test_empty_password_file_is_refused(self):
        module.PASSWORD_FILE.write_text("\n")
        with self.assertRaises(module.Refused):
            module.publish("x01-sound")
        self.assertEqual(self.calls(), [])

    def test_restore_switches_to_the_accepted_tree(self):
        accepted = self.root / "accepted"
        (accepted / "web").mkdir(parents=True)
        (accepted / "web" / "a.png").write_bytes(b"asset")
        module.write_live({"accepted_res_path": str(accepted)})
        self.capture(lambda: module.publish(None, restore=True))
        calls = self.calls()
        settings_call = calls[2]["arguments"]
        payload = json.loads(settings_call[-1])
        self.assertEqual(payload["recovered_res_path"], str(accepted))
        live = self.live()
        self.assertIsNone(live["live_task"])
        self.assertEqual(live["live_res_path"], str(accepted))

    def test_restore_without_an_accepted_tree_is_refused(self):
        with self.assertRaises(module.Refused):
            module.publish(None, restore=True)
        self.assertEqual(self.calls(), [])

    def test_status_prints_the_live_record_without_the_cli(self):
        module.write_live({"accepted_res_path": "/srv/accepted", "release": "1.631.2"})
        result, output, error = self.capture(lambda: module.main(["--status"]))
        self.assertEqual(result, 0)
        self.assertEqual(error, "")
        self.assertIn('"release": "1.631.2"', output)
        self.assertEqual(self.calls(), [])

    def test_status_without_a_record_says_so(self):
        result, output, _ = self.capture(lambda: module.main(["--status"]))
        self.assertEqual(result, 0)
        self.assertIn("no live record", output)


if __name__ == "__main__":
    unittest.main(verbosity=2)
