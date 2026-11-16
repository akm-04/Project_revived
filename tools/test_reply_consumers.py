"""Regression checks for the stock-client reply-consumer extractor."""
import json
import os
from pathlib import Path
import unittest
import zipfile

import reply_consumers

ARCHIVE_ENV = "GXB_REPLY_CONSUMERS_SOURCE_ARCHIVE"
DEFAULT_ARCHIVE = Path(__file__).resolve().parents[1] / "inputs/assets/Older/all-assest-rechecked-1.zip"


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
        mid: {reply_consumers.path_name(entry): reply_consumers.path_requirement(entry) for entry in record["paths"]}
        for mid, record in payload["mids"].items()
    }


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
