import re
import subprocess
import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import system_map


SYSTEM_MAP = ROOT / "tools" / "system_map.py"
LOCK_CLAUSE_PATTERN = re.compile(r"(?:^|; )((?:conditional )?lock [^;]+)")


def trace(mid, full):
    command = [sys.executable, str(SYSTEM_MAP), "trace", str(mid)]
    if full:
        command.append("--full")
    completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, check=True)
    return completed.stdout


def sql_lines(output):
    return {
        line.strip()
        for line in output.splitlines()
        if line.strip().startswith("sql: ")
    }


def lock_clauses(output):
    return {
        clause
        for line in sql_lines(output)
        for clause in LOCK_CLAUSE_PATTERN.findall(line)
    }


class SystemMapTraceTest(unittest.TestCase):
    def test_compaction_keeps_fanout_unresolved_and_bound_markers(self):
        full = (
            "MID 1 handler fixture.Dispatcher fixture.go:1\n"
            "Dispatcher.Dispatch fixture.go:1\n"
            "  FANOUT Load has 2 implementers, not followed: fixture.First.Load, fixture.Second.Load\n"
            "  UNRESOLVED registered wrapper observing\n"
            "  BOUND depth 48 reached\n"
        )

        compact = system_map.compact_trace(full)

        for marker in ("FANOUT Load", "UNRESOLVED registered wrapper", "BOUND depth 48"):
            self.assertIn(marker, compact)

    def test_compact_trace_preserves_sql_and_lock_clauses(self):
        for mid in (836, 1, 191):
            with self.subTest(mid=mid):
                compact = trace(mid, full=False)
                full = trace(mid, full=True)
                self.assertEqual(sql_lines(compact), sql_lines(full))
                self.assertEqual(lock_clauses(compact), lock_clauses(full))
                self.assertLess(len(compact.splitlines()), len(full.splitlines()))
                self.assertEqual(
                    "shared auth path summarized" in compact,
                    "RealtimeAuthority.ResolveGameplayBearer" in full,
                )
                for local_function_value in (
                    "cancel", "release", "body", "acqCancel", "txCancel", "reconcileCancel",
                ):
                    self.assertNotIn("UNRESOLVED " + local_function_value, compact)
                for line in compact.splitlines():
                    fanout = re.match(r"FANOUT .* has (\d+) implementers, not followed: (.*)$", line.strip())
                    if fanout is None:
                        continue
                    implementer_count = int(fanout.group(1))
                    names = fanout.group(2).split(", ")
                    self.assertLessEqual(min(implementer_count, 5), len(names))
                    self.assertLessEqual(len(names), 6)
                    if implementer_count > 5:
                        self.assertEqual(names[-1], "... (+%d more)" % (implementer_count - 5))


if __name__ == "__main__":
    unittest.main()
