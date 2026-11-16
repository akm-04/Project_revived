import json
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import mid_effects


def record(writes, **extra):
    return {"mid": extra.pop("mid", 900), "writes": writes, **extra}


class MidEffectTest(unittest.TestCase):
    def test_traced_write_is_state(self):
        row = record("state", state_writes=["internal/application/i5/missions.go:240"])
        self.assertEqual(mid_effects.mid_effect(row), "state")

    def test_no_trace_is_unknown(self):
        row = record("UNKNOWN", unknown=["inactive fallback registration: no dispatcher route to trace"])
        self.assertEqual(mid_effects.mid_effect(row), "unknown")

    def test_trace_without_write_is_read(self):
        row = record("none", transactions=[{"function": "Service.List", "read_only": "true"}])
        self.assertEqual(mid_effects.mid_effect(row), "read")

    def test_receipt_write_is_state(self):
        row = record("receipt", receipt_writes=["internal/application/i5/awakening.go:176"])
        self.assertEqual(mid_effects.mid_effect(row), "state")

    def test_state_writes_without_class_still_state(self):
        row = record("none", state_writes=["internal/application/eventcentre/board.go:313"])
        self.assertEqual(mid_effects.mid_effect(row), "state")

    def test_effect_document_sorts_and_rejects_duplicates(self):
        document = mid_effects.effect_document({"mids": [record("none", mid=2), record("state", mid=1)]})
        self.assertEqual([row["mid"] for row in document["mids"]], [1, 2])
        with self.assertRaisesRegex(SystemExit, "duplicate mid"):
            mid_effects.effect_document({"mids": [record("none", mid=1), record("none", mid=1)]})

    def test_committed_effects_match_the_system_map(self):
        document = mid_effects.effect_document(mid_effects.load_mid_classes())
        self.assertTrue(mid_effects.OUTPUT.is_file(), "run tools/mid_effects.py --write")
        self.assertEqual(mid_effects.OUTPUT.read_text(encoding="utf-8"), mid_effects.json_text(document))

    def test_check_detects_stale_and_accepts_current(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "MID_CLASSES.json"
            output = Path(directory) / "MID_EFFECTS.json"
            source.write_text(json.dumps({"mids": [record("state")]}), encoding="utf-8")
            output.write_text("{}\n", encoding="utf-8")
            with patch.object(mid_effects, "MID_CLASSES", source), patch.object(mid_effects, "OUTPUT", output), \
                    patch.object(sys, "argv", ["mid_effects.py", "--check"]), redirect_stdout(StringIO()) as captured:
                self.assertEqual(mid_effects.main(), 1)
            self.assertIn("stale: %s" % output, captured.getvalue())
            with patch.object(mid_effects, "MID_CLASSES", source), patch.object(mid_effects, "OUTPUT", output), \
                    patch.object(sys, "argv", ["mid_effects.py", "--write"]), redirect_stdout(StringIO()):
                self.assertEqual(mid_effects.main(), 0)
            with patch.object(mid_effects, "MID_CLASSES", source), patch.object(mid_effects, "OUTPUT", output), \
                    patch.object(sys, "argv", ["mid_effects.py", "--check"]), redirect_stdout(StringIO()):
                self.assertEqual(mid_effects.main(), 0)


if __name__ == "__main__":
    unittest.main()
