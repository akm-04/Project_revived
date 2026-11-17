"""Regression checks for the stock-client reply-consumer extractor."""
import json
import os
from pathlib import Path
import re
import unittest
import zipfile

import reply_consumers

ARCHIVE_ENV = "GXB_REPLY_CONSUMERS_SOURCE_ARCHIVE"
DEFAULT_ARCHIVE = Path(__file__).resolve().parents[1] / "inputs/assets/Older/all-assest-rechecked-1.zip"
ACCESS_NAME = re.compile(r"\.\s*([A-Za-z_][A-Za-z0-9_]*)|\[\s*[\"']([A-Za-z_][A-Za-z0-9_]*)[\"']\s*\]")


def archive_path():
    return Path(os.environ.get(ARCHIVE_ENV) or DEFAULT_ARCHIVE)


def required_paths(payload, mid):
    return {
        reply_consumers.path_name(entry)
        for entry in payload["mids"][str(mid)]["paths"]
        if reply_consumers.path_requirement(entry) == "REQUIRED"
    }


def obligation_map(payload):
    return {
        mid: {
            "paths": {reply_consumers.path_name(entry): reply_consumers.path_requirement(entry) for entry in record["paths"]},
            "branches": {
                key: {
                    value: {
                        reply_consumers.path_name(entry): reply_consumers.path_requirement(entry)
                        for entry in branch["paths"]
                    }
                    for value, branch in values.items()
                }
                for key, values in record.get("branches", {}).items()
            },
        }
        for mid, record in payload["mids"].items()
    }


def branch_requirements(payload, mid, discriminator, value):
    branch = payload["mids"][str(mid)]["branches"][discriminator][value]
    return {reply_consumers.path_name(entry): reply_consumers.path_requirement(entry) for entry in branch["paths"]}


def repeated_segment_names(path):
    names = [part for part in path.replace("[]", "").split(".") if part]
    seen: set[str] = set()
    repeated: list[str] = []
    for name in names:
        if name in seen and name not in repeated:
            repeated.append(name)
        seen.add(name)
    return repeated


def normalised_access_names(line):
    return {
        (first or second).replace("_", "").lower()
        for first, second in ACCESS_NAME.findall(line)
    }


def fixture_payload():
    blobs = {
        "app/common/network/mid.lua": "xyd.mid.LOOP_FIXTURE = 9001\n",
        "app/common/enums.lua": "",
        "data/tables/model_define.lua": "",
        "app/common/network/Backend.lua": "",
        "app/model/LoopFixture.lua": (
            'local var_0_0 = class("LoopFixture")\n'
            "\n"
            "function var_0_0.load(arg_1_0)\n"
            "\txyd.Backend.get():request(xyd.mid.LOOP_FIXTURE, {}, function(arg_2_0, arg_2_1)\n"
            "\t\targ_1_0.info = arg_2_1\n"
            "\t\targ_1_0.send_gift_count = arg_2_1.send_gift_count\n"
            "\t\targ_1_0:updateDetail(arg_2_1.detail)\n"
            "\tend)\n"
            "end\n"
            "\n"
            "function var_0_0.updateDetail(arg_3_0, arg_3_1)\n"
            "\targ_3_0.team = arg_3_1\n"
            "end\n"
            "\n"
            "function var_0_0.bump(arg_4_0)\n"
            "\targ_4_0.info.send_gift_count[1] = arg_4_0.info.send_gift_count[1] + 1\n"
            "\targ_4_0.team.challenge_times[1] = arg_4_0.team.challenge_times[1] + 1\n"
            "end\n"
        ),
    }
    return reply_consumers.build(blobs, collapse=False)


class StorageBindingCycleTests(unittest.TestCase):
    def test_a_storage_binding_is_followed_at_most_once_per_path(self):
        payload = fixture_payload()
        paths = [reply_consumers.path_name(entry) for entry in payload["mids"]["9001"]["paths"]]
        repeated = [path for path in paths if repeated_segment_names(path)]
        self.assertEqual([], repeated)
        self.assertIn("send_gift_count", paths)
        self.assertIn("send_gift_count[]", paths)
        self.assertIn("detail.challenge_times[]", paths)


class ReplyConsumerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = archive_path()
        if not archive.exists():
            raise unittest.SkipTest(f"source archive not supplied: {archive}")
        with zipfile.ZipFile(archive) as bundle:
            cls.blobs = reply_consumers.lua_blobs(bundle)
        cls.uncollapsed = reply_consumers.build(cls.blobs, collapse=False)
        cls.payload = reply_consumers.compact_payload(reply_consumers.collapse_sites(cls.uncollapsed))

    def test_r1_crash_class_is_required(self):
        self.assertIn("award", required_paths(self.payload, 532))
        self.assertIn("comment_list[].from_player_info", required_paths(self.payload, 1839))
        self.assertIn("A_pet_info", required_paths(self.payload, 1292))
        self.assertIn("B_pet_info", required_paths(self.payload, 1292))
        self.assertIn("pre_info", required_paths(self.payload, 628))
        self.assertIn("count", required_paths(self.payload, 176))
        self.assertIn("list", required_paths(self.payload, 176))
        self.assertIn("player_id", required_paths(self.payload, 177))
        self.assertTrue({"player_info"} <= required_paths(self.payload, 185) or "list[].player_info" in required_paths(self.payload, 185))

    def test_activity_obligations_are_split_by_the_selected_table_id(self):
        record = self.payload["mids"]["234"]
        self.assertEqual("table_id", next(iter(record["branches"])))
        unconditional = required_paths(self.payload, 234)
        self.assertNotIn("details.server_support", unconditional)
        self.assertEqual("REQUIRED", branch_requirements(self.payload, 234, "table_id", "1129")["details.server_support"])
        self.assertNotIn("1129", [path for path in unconditional])
        unknown = record["branches"]["table_id"]["unknown"]
        self.assertEqual("UNKNOWN", unknown["status"])
        self.assertTrue(unknown["reason"])
        self.assertTrue(unknown["paths"])

    def test_branch_sites_are_the_activity_window_selected_by_the_client(self):
        branch = self.payload["mids"]["234"]["branches"]["table_id"]["1129"]
        entry = next(entry for entry in branch["paths"] if reply_consumers.path_name(entry) == "details.server_support")
        files = {self.payload["site_files"][site[0]] for site in entry[2]}
        self.assertEqual({"app/windows/activities/Activity1129.lua"}, files)

    def test_site_collapse_keeps_every_obligation_and_output_under_five_megabytes(self):
        self.assertEqual(obligation_map(self.uncollapsed), obligation_map(self.payload))
        size = len(json.dumps(self.payload, sort_keys=True, separators=(",", ":")).encode())
        self.assertLess(size, 5 * 1024 * 1024, f"REPLY_CONSUMERS.json is {size} bytes")

    def test_site_collapse_merges_one_entry_per_file_and_line(self):
        for record in self.payload["mids"].values():
            for entry in record["paths"]:
                keys = [(site[0], site[1]) for site in entry[2]]
                self.assertEqual(len(keys), len(set(keys)))

    def test_every_sent_mid_has_a_callback_record(self):
        for mid in ("118", "176", "185", "532", "628", "1292", "1839"):
            self.assertIn(mid, self.payload["mids"])
            callbacks = self.payload["mids"][mid]["callbacks"]
            self.assertTrue(callbacks, mid)
            for callback in callbacks:
                self.assertIn(callback["status"], {"CHECKED", "UNKNOWN"}, mid)

    def test_write_outputs_carry_the_embedded_copy(self):
        outputs = reply_consumers.written_outputs(self.payload)
        self.assertEqual(
            set(outputs),
            {reply_consumers.CONSUMERS_PATH, reply_consumers.EMBED_PATH},
        )
        self.assertEqual(outputs[reply_consumers.EMBED_PATH], reply_consumers.serialise(self.payload))

    def test_generation_is_deterministic(self):
        again = reply_consumers.build(self.blobs)
        self.assertEqual(
            json.dumps(self.payload, sort_keys=True),
            json.dumps(again, sort_keys=True),
        )

    def test_every_repeated_segment_is_read_at_a_cited_site(self):
        for mid, record in self.payload["mids"].items():
            for entry in record["paths"]:
                path = reply_consumers.path_name(entry)
                repeated = repeated_segment_names(path)
                if not repeated:
                    continue
                lines = [
                    self.blobs[self.payload["site_files"][site[0]]].splitlines()[site[1] - 1]
                    for site in entry[2]
                ]
                accessed = set()
                for line in lines:
                    accessed |= normalised_access_names(line)
                for name in repeated:
                    self.assertIn(
                        name.replace("_", "").lower(),
                        accessed,
                        f"MID {mid} path {path} repeats {name} but no site line reads it: {lines}",
                    )

    def test_waiver_needs_reason_and_client_site(self):
        payload = {
            "mids": {
                "532": {
                    "paths": [
                        {"path": "award", "requirement": "REQUIRED"},
                    ]
                }
            }
        }
        problems = reply_consumers.validate_waivers(
            {"waivers": [{"mid": 532, "path": "award", "reason": "", "client": "app/windows/TreasureWindow.lua:561"}]},
            payload,
            self.blobs,
        )
        self.assertTrue(any("reason" in problem for problem in problems))
        problems = reply_consumers.validate_waivers(
            {"waivers": [{"mid": 532, "path": "award", "reason": "guarded at the call", "client": "missing.lua:1"}]},
            payload,
            self.blobs,
        )
        self.assertTrue(any("client" in problem for problem in problems))

    def test_waiver_marks_a_required_path_waived(self):
        payload = {
            "mids": {
                "532": {"paths": [{"path": "award", "requirement": "REQUIRED"}]}
            }
        }
        waived = reply_consumers.apply_waivers(
            {"waivers": [{"mid": 532, "path": "award", "reason": "guarded at the call", "client": "app/windows/TreasureWindow.lua:561"}]},
            payload,
        )
        self.assertEqual(waived["mids"]["532"]["paths"][0]["requirement"], "WAIVED")


if __name__ == "__main__":
    unittest.main()
