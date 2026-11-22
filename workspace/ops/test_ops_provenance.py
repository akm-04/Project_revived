"""Tests for the ops lifecycle guards (PROVENANCE_AND_COVERAGE_V1): a seal is sealed only after it finishes,
checkpoints restore from that seal, and the branch ledger tracks every branch.

Run: cd ops && ../.toolchain/bin/python3 -B -m unittest test_ops_provenance
"""
import contextlib
import hashlib
import io
import json
import pathlib
import subprocess
import sys
import tempfile
import types
import unittest
from unittest.mock import patch

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
# branch_ledger.py lives in the stage's contract_recovery (live) or at the copy's root (work/ops_fix).
for ledger_home in (pathlib.Path(__file__).resolve().parent.parent / "contract_recovery",
                    pathlib.Path(__file__).resolve().parent.parent / "work/i9/stages/I9-11/contract_recovery"):
    if (ledger_home / "branch_ledger.py").is_file():
        sys.path.insert(0, str(ledger_home))
# The workspace-tools sibling is not part of the tooling copy; the checkpoint logic under test does not use it.
layout = types.ModuleType("checkpoint_layout")
layout.checkpoint_paths = layout.rotate = lambda *arguments: None
sys.modules.setdefault("checkpoint_layout", layout)
import branch_ledger
import checkpoint
import contract_manifest
import state

OPS = pathlib.Path(__file__).resolve().parent


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


class SealCompletionTests(unittest.TestCase):
    """A generation counts as sealed only when its completion record names the zip's sha256 (row 1)."""

    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.base = pathlib.Path(self.temporary.name)
        (self.base / "outputs").mkdir()

    def tearDown(self):
        self.temporary.cleanup()

    def zip(self, generation, content=b"sealed zip"):
        path = self.base / "outputs" / f"gxb-backend-pass-{generation}.0-passmap.zip"
        path.write_bytes(content)
        return path, hashlib.sha256(content).hexdigest()

    def test_a_zip_without_a_completion_record_is_unsealed(self):
        path, sha = self.zip(799)
        (self.base / "outputs" / "gxb-backend-pass-799.0-passmap.verification.json").write_text(json.dumps({"sha256": sha}))
        with patch.object(state, "W", self.base):
            self.assertEqual(state.sealed_zip_generation(), (None, None))

    def test_a_matching_completion_record_seals_the_generation(self):
        path, sha = self.zip(799)
        (self.base / "outputs" / "gxb-backend-pass-799.0-passmap.complete.json").write_text(
            json.dumps({"generation": 799, "sha256": sha, "authority": "work/authority_p799"}))
        with patch.object(state, "W", self.base):
            self.assertEqual(state.sealed_zip_generation(), (799, path))

    def test_a_completion_record_with_another_digest_is_unsealed(self):
        self.zip(799)
        (self.base / "outputs" / "gxb-backend-pass-799.0-passmap.complete.json").write_text(
            json.dumps({"generation": 799, "sha256": "0" * 64}))
        with patch.object(state, "W", self.base):
            self.assertEqual(state.sealed_zip_generation(), (None, None))

    def test_a_damaged_completion_record_is_unsealed(self):
        self.zip(799)
        (self.base / "outputs" / "gxb-backend-pass-799.0-passmap.complete.json").write_text("{not json")
        with patch.object(state, "W", self.base):
            self.assertEqual(state.sealed_zip_generation(), (None, None))

    def test_the_798_seal_is_accepted_through_its_named_legacy_record(self):
        path, sha = self.zip(798)
        (self.base / "outputs" / "gxb-backend-pass-798.0-passmap.sha256").write_text(f"{sha}  {path.name}\n")
        with patch.object(state, "W", self.base):
            self.assertEqual(state.sealed_zip_generation(), (798, path))

    def test_only_798_is_accepted_from_the_legacy_siblings(self):
        path, sha = self.zip(797)
        (self.base / "outputs" / "gxb-backend-pass-797.0-passmap.verification.json").write_text(json.dumps({"sha256": sha}))
        with patch.object(state, "W", self.base):
            self.assertEqual(state.sealed_zip_generation(), (None, None))

    def test_a_newer_unsealed_zip_does_not_replace_the_sealed_generation(self):
        older, older_sha = self.zip(798)
        (self.base / "outputs" / "gxb-backend-pass-798.0-passmap.sha256").write_text(f"{older_sha}  {older.name}\n")
        self.zip(799)
        with patch.object(state, "W", self.base):
            self.assertEqual(state.sealed_zip_generation(), (798, older))


class CheckpointBaseTests(unittest.TestCase):
    """A checkpoint restores from the completed seal, never from a newer, unsealed zip (row 9)."""

    def test_the_base_is_the_sealed_generation_and_zip(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            (base / "outputs").mkdir()
            sealed = base / "outputs/gxb-backend-pass-798.0-passmap.zip"
            sealed.write_bytes(b"sealed")
            unsealed = base / "outputs/gxb-backend-pass-799.0-passmap.zip"
            unsealed.write_bytes(b"aborted")
            facts = {"passmap": {"sealed_generation": 798, "sealed_zip": "outputs/gxb-backend-pass-798.0-passmap.zip",
                                 "latest_zip": "outputs/gxb-backend-pass-799.0-passmap.zip", "latest_zip_generation": 799}}
            with patch.object(checkpoint, "W", base):
                self.assertEqual(checkpoint.sealed_base(facts), (798, sealed))
                self.assertEqual(digest(sealed), digest(sealed))

    def test_a_checkpoint_without_a_sealed_generation_is_refused(self):
        facts = {"passmap": {"sealed_generation": None, "sealed_zip": None,
                             "latest_zip": "outputs/gxb-backend-pass-799.0-passmap.zip", "latest_zip_generation": 799}}
        with tempfile.TemporaryDirectory() as temporary, patch.object(checkpoint, "W", pathlib.Path(temporary)):
            with self.assertRaises(SystemExit):
                checkpoint.sealed_base(facts)


class SealCheckSkipTests(unittest.TestCase):
    """A missing frontier registry is refused unless the caller declares a stage-start seal (row 2)."""

    def check(self, stage_start):
        with tempfile.TemporaryDirectory() as temporary:
            missing = pathlib.Path(temporary) / "REGISTRY"
            facts = {"phase_workspace": {"path": "work/i9"}, "frontier": {"stage": "I9-11"}}
            printed = io.StringIO()
            with patch.object(contract_manifest, "registry_for", return_value=missing), \
                 patch.object(state, "facts", return_value=facts), contextlib.redirect_stdout(printed):
                status = contract_manifest.seal_check(stage_start=stage_start)
            return status, printed.getvalue()

    def test_a_missing_registry_refuses_the_seal(self):
        status, printed = self.check(False)
        self.assertEqual(status, 1)
        self.assertIn(str(pathlib.Path("REGISTRY") / "registry.json"), printed)
        self.assertIn("--stage-start", printed)

    def test_an_explicit_stage_start_still_skips(self):
        status, printed = self.check(True)
        self.assertEqual(status, 0)
        self.assertIn("SEAL_CONTRACT_CHECK SKIP", printed)


class BranchLedgerTests(unittest.TestCase):
    """Row 6: every branch is tracked; unlanded work is reported unless it is declared superseded."""

    def git(self, tree, *arguments):
        return subprocess.run(["git", "-C", str(tree), *arguments], capture_output=True, text=True, check=True).stdout.strip()

    def commit(self, tree, name, message=None):
        (tree / f"{name}.txt").write_text(name)
        self.git(tree, "add", "-A")
        self.git(tree, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", message or name)
        return self.git(tree, "rev-parse", "HEAD")

    def build(self, base):
        tree = base / "repo"
        tree.mkdir()
        self.git(tree, "init", "-q", "-b", "i8-go1273")
        self.commit(tree, "base")
        self.git(tree, "checkout", "-q", "-b", "feature-outside")
        self.commit(tree, "feature")
        self.git(tree, "checkout", "-q", "-b", "integration", "i8-go1273")
        self.commit(tree, "integration-work")
        self.git(tree, "checkout", "-q", "-b", "superseded-old", "i8-go1273")
        superseding = self.commit(tree, "superseded")
        self.git(tree, "checkout", "-q", "-b", "repair-base", "i8-go1273")
        self.commit(tree, "repair")
        self.git(tree, "checkout", "-q", "-b", "repair-child")
        self.commit(tree, "repair-child")
        return tree, superseding

    def test_every_branch_is_tracked_and_undeclared_work_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            tree, superseding = self.build(base)
            out = base / "BRANCH_LEDGER.md"
            with patch.object(branch_ledger, "REPO", str(tree)), patch.object(branch_ledger, "OUT", out), \
                 patch.object(branch_ledger, "INTEGRATION_REFS", {"integration"}), patch.object(branch_ledger, "SUPERSEDED", {}), \
                 patch.object(branch_ledger, "SUPERSEDED_UNLANDED",
                              {"superseded-old": {"reason": "test supersession", "commit": superseding}}):
                branch_ledger.main()
            written = out.read_text()
            unlanded = written.split("## Unlanded", 1)[1].split("## Superseded, not landed", 1)[0]
            self.assertIn("feature-outside", unlanded)
            self.assertIn("repair-child", unlanded)
            self.assertNotIn("repair-base", unlanded, "a branch another branch contains is not a tip")
            self.assertNotIn("integration", written.split("| branch |", 1)[1].split("## ", 1)[0])
            self.assertNotIn("superseded-old", unlanded, "a declared supersession is not reported unlanded")
            self.assertIn("superseded-old | test supersession | " + superseding, written)


    def test_work_landed_by_cherry_pick_or_reviewed_equivalent_is_not_unlanded(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            tree, superseding = self.build(base)
            self.git(tree, "checkout", "-q", "-b", "picked", "i8-go1273")
            picked = self.commit(tree, "picked", "picked work")
            self.git(tree, "checkout", "-q", "-b", "rebased", "i8-go1273")
            old = self.commit(tree, "rebased-old", "rebased work")
            self.git(tree, "checkout", "-q", "integration")
            self.git(tree, "cherry-pick", picked)
            new = self.commit(tree, "rebased-new", "rebased work")
            out = base / "BRANCH_LEDGER.md"

            def unlanded_with(reviewed):
                with patch.object(branch_ledger, "REPO", str(tree)), patch.object(branch_ledger, "OUT", out), \
                     patch.object(branch_ledger, "INTEGRATION_REFS", {"integration"}), \
                     patch.object(branch_ledger, "SUPERSEDED", {}), patch.object(branch_ledger, "SUPERSEDED_UNLANDED", {}), \
                     patch.object(branch_ledger, "REVIEWED_EQUIVALENTS", reviewed):
                    branch_ledger.main()
                return out.read_text().split("## Unlanded", 1)[1].split("## Superseded, not landed", 1)[0]

            unlanded = unlanded_with({})
            self.assertNotIn("picked", unlanded, "the same patch in an integration ref is landed")
            self.assertIn("rebased", unlanded, "a matching subject with a different patch is not proof (A-090)")
            self.assertIn("feature-outside", unlanded)
            unlanded = unlanded_with({old[:8]: {"successor": new[:8], "reason": "test"}})
            self.assertNotIn("rebased", unlanded, "a reviewed equivalent contained in the integration ref is landed")

class SealScriptTests(unittest.TestCase):
    def test_the_completion_record_is_written_after_the_last_check(self):
        script = (OPS / "seal_passmap.sh").read_text()
        self.assertIn("complete.json", script)
        self.assertLess(script.index('state.py" --check'), script.rindex("complete.json"))

    def test_a_stage_start_seal_must_be_asked_for_explicitly(self):
        script = (OPS / "seal_passmap.sh").read_text()
        self.assertIn("GXB_SEAL_STAGE_START", script)
        self.assertIn("--stage-start", script)
        self.assertIn("GXB_SEAL_STAGE_START is not set", script)


if __name__ == "__main__":
    unittest.main()
