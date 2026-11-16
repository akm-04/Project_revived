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
        entry["path"]
        for entry in payload["mids"][str(mid)]["paths"]
        if entry["requirement"] == "REQUIRED"
    }


class ReplyConsumerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = archive_path()
        if not archive.exists():
            raise unittest.SkipTest(f"source archive not supplied: {archive}")
        with zipfile.ZipFile(archive) as bundle:
            cls.blobs = reply_consumers.lua_blobs(bundle)
        cls.payload = reply_consumers.build(cls.blobs)

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

    def test_every_sent_mid_has_a_callback_record(self):
        for mid in ("118", "176", "185", "532", "628", "1292", "1839"):
            self.assertIn(mid, self.payload["mids"])
            callbacks = self.payload["mids"][mid]["callbacks"]
            self.assertTrue(callbacks, mid)
            for callback in callbacks:
                self.assertIn(callback["status"], {"CHECKED", "UNKNOWN"}, mid)

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
