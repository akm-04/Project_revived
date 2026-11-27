"""Negative regression tests for the contract workflow: each test plants one defect and checks that the registry,
the manifest lookup or the merge check catches it. Run: cd ops && ../.toolchain/bin/python3 -B -m unittest test_contract_workflow"""
import contextlib
import io
import importlib.util
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import types
import unittest
from unittest.mock import patch

import contract_manifest
import contract_registry
import state

PHASE = "i9"
DEEPSEEK = "Co-Authored-By: DeepSeek <noreply@deepseek.com>"
SYSTEMS = {
    "shop": {"name": "shop", "mids": [{"mid": 1072, "name": "SHOP_BUY"}, {"mid": 1091}], "tables": {"owned": ["shop_rows"]}},
    "march": {"name": "march", "mids": [{"mid": 336, "name": "LOAD_MARCH"}], "tables": {"owned": ["march_players"]}},
}


def git(tree, *arguments):
    return subprocess.run(["git", "-C", str(tree), *arguments], capture_output=True, text=True, check=True).stdout.strip()


def commit(tree, files, message=f"change\n\n{DEEPSEEK}"):
    for relative, content in files.items():
        path = tree / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content if isinstance(content, str) else json.dumps(content))
    git(tree, "add", "-A")
    git(tree, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", message)
    return git(tree, "rev-parse", "HEAD")


class Stage:
    """A backend repository with a two-system map, and a stage registry opened from a fake seal holding SHOP_V1
    (by MID array) and MARCH_V1 (by prose MID)."""

    def __init__(self, base):
        self.base = base
        self.tree = base / "backend"
        self.tree.mkdir()
        git(self.tree, "init", "-q", "-b", "main")
        files = {f"docs/architecture/system_map/systems/{name}.json": record for name, record in SYSTEMS.items()}
        files.update({f"internal/application/{name}/{name}.go": f"package {name}\n" for name in SYSTEMS})
        files["internal/application/shop/shop_test.go"] = "package shop\n\nfunc TestShopBuy(t *testing.T) {}\n"
        self.base_commit = commit(self.tree, files, "base")
        hot = base / "hot"
        (hot / "contracts").mkdir(parents=True)
        (hot / "contracts/SHOP.json").write_text(json.dumps({"contract_id": "SHOP_V1", "mids": [1072, 1073, 1074, 1091]}))
        (hot / "contracts/MARCH.md").write_text("# March\nMID 336 refuses a second claim.\n")
        (hot / "records").mkdir()
        (hot / "records/frontier.json").write_text(json.dumps({"stage": "I9-11"}))
        (hot / "records/contracts.json").write_text(json.dumps({"contracts": {
            "SHOP_V1": {"document": "contracts/SHOP.json", "status": "IN_FORCE"},
            "MARCH_V1": {"document": "contracts/MARCH.md", "status": "IN_FORCE"}}}))
        self.hot = hot
        self.inputs = base / "inputs"
        self.stage_contracts = base / "stage_contracts"
        self.directory = base / "REGISTRY"
        contract_registry.open_registry(self.directory, 798, hot, self.inputs, self.stage_contracts, "I9-11", base_commit=self.base_commit)
        contract_registry.set_integration(self.directory, self.tree)
        (self.directory / "verdicts.json").write_text("{}\n")

    def leaf(self, name):
        git(self.tree, "checkout", "-q", "-b", name, self.base_commit)

    def revision(self):
        return contract_registry.load(self.directory)["revision"]

    def dispatch(self, systems, status="PASS", pool="codex"):
        manifest = contract_manifest.build_manifest(self.directory, self.tree, systems, f"task-{len(systems)}-{pool}")
        path = self.base / f"manifest-{self.revision()}-{pool}-{git(self.tree, 'rev-parse', 'HEAD')[:8]}.json"
        path.write_text(json.dumps(manifest))
        contract_manifest.record_dispatch(manifest, path, status, [] if status == "PASS" else ["x: no row"], "session", pool, "model")

    def merge_check(self, absorbing=True):
        return contract_manifest.merge_check(self.directory, self.tree, self.base_commit, "HEAD", PHASE, absorbing)[0]


def kinds(problems):
    return sorted({problem.split()[0] for problem in problems})


class MidExtractionTests(unittest.TestCase):
    def test_every_mid_of_a_json_array(self):
        self.assertEqual(contract_manifest.document_mids('{"mids": [1072, 1073, 1074, 1091]}'), {1072, 1073, 1074, 1091})

    def test_keyed_string_and_scalar_mids(self):
        self.assertEqual(contract_manifest.document_mids('{"reply_mids": ["32", "33"], "request_mid": 7}'), {32, 33, 7})

    def test_prose_lists_names_and_ranges(self):
        self.assertEqual(contract_manifest.document_mids("MIDs 560-571, 600 SHOP_BUY / 601 & 602 or 603"),
                         set(range(560, 572)) | {600, 601, 602, 603})

    def test_glued_and_lowercase_forms(self):
        self.assertEqual(contract_manifest.document_mids('MID64, MID2336/2337, {mid:5,x}, "mid336": 1, cae-mid9-repair'),
                         {64, 2336, 2337, 5, 336, 9})

    def test_requirement_labels_are_not_mids(self):
        self.assertEqual(contract_manifest.document_mids("MID-01: refuse twice; MIDDLE 5; mid 7"), set())

    def test_a_contract_is_placed_by_its_last_array_mid(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            found = contract_manifest.lookup(stage.directory, stage.tree)
            self.assertIn("MID 1091", found["placed"]["SHOP_V1"]["shop"])
            self.assertEqual(found["unresolved"], [])


class RegistryIdentityTests(unittest.TestCase):
    def test_a_registered_file_name_does_not_hide_a_new_id(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            folder = stage.base / "scan"
            folder.mkdir()
            (folder / "SHOP.json").write_text(json.dumps({"contract_id": "SHOP_V2"}))
            self.assertEqual(contract_registry.check(stage.directory, [(folder, contract_registry.contract_identifier)]),
                             [f"UNREGISTERED SHOP_V2: {folder / 'SHOP.json'}"])

    def test_a_legacy_alias_with_other_content_diverges(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            registry = contract_registry.load(stage.directory)
            contract_registry.place(stage.directory, registry, "LEGACY", json.dumps({"policy_id": "LEGACY_DECLARED"}).encode(),
                                    "L.json", dict(origin="sealed_798", status="IN_FORCE"))
            contract_registry.save(stage.directory, registry, "test", ["LEGACY"])
            folder = stage.base / "scan"
            folder.mkdir()
            (folder / "L.json").write_text(json.dumps({"policy_id": "LEGACY_DECLARED", "changed": True}))
            self.assertEqual(kinds(contract_registry.check(stage.directory, [(folder, contract_registry.contract_identifier)])), ["DIVERGED"])

    def test_two_files_declaring_one_id_differently(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            folder = stage.base / "scan"
            folder.mkdir()
            (folder / "a.json").write_text(json.dumps({"contract_id": "SHOP_V1", "x": 1}))
            (folder / "b.json").write_text(json.dumps({"contract_id": "SHOP_V1", "x": 2}))
            self.assertIn("DUPLICATE", kinds(contract_registry.check(stage.directory, [(folder, contract_registry.contract_identifier)])))

    def test_an_edited_registry_document_is_caught(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            (stage.directory / contract_registry.load(stage.directory)["contracts"]["SHOP_V1"]["document"]).write_text("{}")
            self.assertTrue(any("changed without `add`" in problem for problem in contract_registry.check(stage.directory, [])))


class SweepTests(unittest.TestCase):
    def sweep(self, files, classified=None):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            docs = stage.base / "docs"
            for relative, content in files.items():
                (docs / relative).parent.mkdir(parents=True, exist_ok=True)
                (docs / relative).write_text(json.dumps(content))
            for key, reason in (classified or {}).items():
                contract_registry.classify(stage.directory, key, reason)
            return contract_registry.sweep(stage.directory, [("docs", docs)])

    def test_a_nested_policy_record_without_an_id_is_unclassified(self):
        self.assertEqual(kinds(self.sweep({"i7c2f/deep/SOURCE_PROFILE_AMENDMENT.json": {"rules": [1]}})), ["UNCLASSIFIED"])

    def test_a_nested_unregistered_id_is_unclassified(self):
        problems = self.sweep({"i7a/x/notes.json": {"policy_id": "NEW_POLICY_V1"}})
        self.assertEqual(problems, ["UNCLASSIFIED docs/i7a/x/notes.json: register it (`add` with --origin-*) or `classify` it with a reason"])

    def test_registered_content_id_or_name_passes(self):
        self.assertEqual(self.sweep({"a/SHOP_POLICY.json": {"contract_id": "SHOP_V1", "changed": True},
                                     "b/SHOP_V1.md": {"x": 1}, "c/plain.json": {"x": 1}}), [])

    def test_a_classified_document_passes_and_a_gone_one_is_stale(self):
        problems = self.sweep({"a/AUTHORIZATION.json": {}}, {"docs/a/AUTHORIZATION.json": "approval record",
                                                            "docs/gone/POLICY.json": "old"})
        self.assertEqual(problems, ["STALE_CLASSIFICATION docs/gone/POLICY.json: the document is gone; drop it from not_contracts.json"])

    def test_a_missing_root_fails_closed(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.assertEqual(kinds(contract_registry.sweep(stage.directory, [("hot", stage.base / "nowhere")])), ["SWEEP_ROOT_MISSING"])


class AbsorbTests(unittest.TestCase):
    def test_two_leaves_adding_the_same_file_name_keep_both_documents(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {f"docs/{PHASE}/POLICY.json": {"contract_id": "A_POLICY_V1", "rule": "a"}})
            self.assertEqual(contract_registry.absorb(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE), (["A_POLICY_V1"], []))
            stage.leaf("b")
            commit(stage.tree, {f"docs/{PHASE}/POLICY.json": {"contract_id": "B_POLICY_V1", "rule": "b"}})
            self.assertEqual(contract_registry.absorb(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE), (["B_POLICY_V1"], []))
            contracts = contract_registry.load(stage.directory)["contracts"]
            self.assertNotEqual(contracts["A_POLICY_V1"]["document"], contracts["B_POLICY_V1"]["document"])
            self.assertEqual(contract_registry.check(stage.directory, []), [])

    def test_markdown_needs_a_contract_id_line(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {f"docs/{PHASE}/SEAMS.md": "Contract-Id: I9_11_SEAMS_V1\n# seams\n",
                                f"docs/{PHASE}/RESEARCH.md": "# research notes, not a contract\n"})
            self.assertEqual(contract_registry.absorb(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE)[0], ["I9_11_SEAMS_V1"])

    def test_an_amended_registered_markdown_is_absorbed_by_its_name(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            commit(stage.tree, {f"docs/{PHASE}/MARCH_V1.md": (stage.hot / "contracts/MARCH.md").read_text()}, "base doc")
            stage.base_commit = git(stage.tree, "rev-parse", "HEAD")
            stage.leaf("a")
            commit(stage.tree, {f"docs/{PHASE}/MARCH_V1.md": "# March\nMID 336 refuses a third claim.\n"})
            registered, conflicts = contract_registry.absorb(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE)
            self.assertEqual((registered, conflicts), (["MARCH_V1"], []))

    def test_rewriting_a_registered_contract_the_base_lacked_conflicts(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {f"docs/{PHASE}/MARCH_V1.md": "# March\nMID 336 refuses a third claim.\n"})
            self.assertEqual(kinds(contract_registry.absorb(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE)[1]), ["CONFLICT"])

    def test_absorb_reads_the_commit_not_the_working_copy(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            committed = json.dumps({"contract_id": "X_V1", "rule": "committed"})
            commit(stage.tree, {f"docs/{PHASE}/X.json": committed})
            (stage.tree / f"docs/{PHASE}/X.json").write_text(json.dumps({"contract_id": "X_V1", "rule": "dirty"}))
            contract_registry.absorb(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE)
            entry = contract_registry.load(stage.directory)["contracts"]["X_V1"]
            self.assertEqual((stage.directory / entry["document"]).read_text(), committed)

    def test_an_absorbed_document_records_its_commit_source(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {f"docs/{PHASE}/X.json": {"contract_id": "X_V1"}})
            self.assertEqual(contract_registry.absorb(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE),
                             (["X_V1"], []))
            entry = contract_registry.load(stage.directory)["contracts"]["X_V1"]
            self.assertEqual((entry["provenance"]["source"], entry["provenance"]["sha256"]),
                             (f"docs/{PHASE}/X.json", entry["sha256"]))
            self.assertEqual(contract_registry.check(stage.directory, []), [])

    def test_a_duplicate_id_saves_nothing(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {f"docs/{PHASE}/A.json": {"contract_id": "D_V1", "x": 1}, f"docs/{PHASE}/B.json": {"contract_id": "D_V1", "x": 2},
                                f"docs/{PHASE}/C.json": {"contract_id": "OK_V1"}})
            before = (stage.directory / "registry.json").read_bytes()
            registered, conflicts = contract_registry.absorb(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE)
            self.assertEqual((registered, kinds(conflicts)), ([], ["DUPLICATE"]))
            self.assertEqual((stage.directory / "registry.json").read_bytes(), before)

    def test_both_sides_changing_a_contract_conflicts(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            commit(stage.tree, {f"docs/{PHASE}/SHOP.json": {"contract_id": "SHOP_V1", "mids": [1072]}}, "base doc")
            stage.base_commit = git(stage.tree, "rev-parse", "HEAD")
            amended = stage.base / "SHOP.json"
            amended.write_text(json.dumps({"contract_id": "SHOP_V1", "mids": [1072, 5]}))
            contract_registry.add(stage.directory, amended, "SHOP_V1", "shop", "IN_FORCE", [])
            stage.leaf("a")
            commit(stage.tree, {f"docs/{PHASE}/SHOP.json": {"contract_id": "SHOP_V1", "mids": [1072, 6]}})
            self.assertEqual(kinds(contract_registry.absorb(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE)[1]), ["CONFLICT"])


class ExportTests(unittest.TestCase):
    def test_export_names_files_by_id_and_refuses_a_sealed_name(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            source = stage.base / "anything.json"
            source.write_text(json.dumps({"contract_id": "NEW_V1"}))
            contract_registry.add(stage.directory, source, "NEW_V1", "new", "IN_FORCE", [])
            sealed = contract_registry.sealed_document_names(stage.hot)
            self.assertEqual(contract_registry.export(stage.directory, stage.inputs, sealed), ["NEW_V1"])
            self.assertTrue((stage.inputs / "contracts/NEW_V1.json").is_file())
            source.write_text(json.dumps({"contract_id": "SHOP"}))
            contract_registry.add(stage.directory, source, "SHOP", "clash", "IN_FORCE", [])
            with self.assertRaises(SystemExit):
                contract_registry.export(stage.directory, stage.inputs, sealed)

    def test_a_late_found_contract_keeps_the_stage_that_made_it(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            source = stage.base / "old.json"
            source.write_text(json.dumps({"policy_id": "OLD_V1"}))
            origin = {"stage": "I9-10", "phase": "I9", "commit": "9522d7f", "note": "found by the registry scan"}
            contract_registry.add(stage.directory, source, "OLD_V1", "old", "IN_FORCE", [], origin)
            entry = contract_registry.load(stage.directory)["contracts"]["OLD_V1"]
            self.assertEqual((entry["stage"], entry["phases"], entry["provenance"]["origin"]["commit"]), ("I9-10", ["I9"], "9522d7f"))
            contract_registry.export(stage.directory, stage.inputs, contract_registry.sealed_document_names(stage.hot))
            row = next(row for row in json.loads((stage.inputs / "CONTRACTS.json").read_text())["contracts"] if row["id"] == "OLD_V1")
            self.assertEqual((row["stage"], row["phases"], row["note"]), ("I9-10", ["I9"], "found by the registry scan"))


class ComplianceTests(unittest.TestCase):
    def answer(self, row):
        return f"{contract_manifest.COMPLIANCE_HEADING}\nid | verdict | evidence\n{row}\n"

    def check(self, row, opened=True, changed=True):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            manifest = contract_manifest.build_manifest(stage.directory, stage.tree, ["shop"], "task")
            if changed:
                commit(stage.tree, {"internal/application/shop/shop.go": "package shop\n// changed\n"})
            transcript = stage.base / "t.jsonl"
            documents = [row["document"] for row in manifest["contracts"]] if opened else []
            transcript.write_text("".join(json.dumps({"message": {"content": [
                {"type": "tool_use", "name": "Read", "input": {"file_path": path}}]}}) + "\n" for path in documents))
            return contract_manifest.verify(manifest, self.answer(row), transcript)

    def test_applied_with_code_and_test_passes(self):
        self.assertEqual(self.check("SHOP_V1 | APPLIED | internal/application/shop/shop.go:1, TestShopBuy"), [])

    def test_applied_without_a_test_fails(self):
        self.assertEqual(self.check("SHOP_V1 | APPLIED | internal/application/shop/shop.go:1"),
                         ["SHOP_V1: APPLIED without the test that proves it (an existing _test.go file:line or Test function)"])

    def test_a_test_file_is_not_the_implementation(self):
        self.assertIn("SHOP_V1: APPLIED without an existing file:line in the evidence",
                      self.check("SHOP_V1 | APPLIED | internal/application/shop/shop_test.go:3"))

    def test_a_missing_row_fails(self):
        self.assertEqual(self.check("OTHER_V1 | NOT_APPLICABLE | this task changes nothing in the shop"), ["SHOP_V1: no row"])

    def test_applied_without_opening_the_document_fails(self):
        self.assertTrue(self.check("SHOP_V1 | APPLIED | internal/application/shop/shop.go:1, TestShopBuy", opened=False)[0]
                        .endswith("was never opened"))


class TierTests(unittest.TestCase):
    INDEX_ID = "INDEX_RULE_V1"

    def add_index_contract(self, stage, note="implemented in internal/application/shop/"):
        source = stage.base / f"{self.INDEX_ID}.json"
        source.write_text(json.dumps({"contract_id": self.INDEX_ID, "note": note}))
        contract_registry.add(stage.directory, source, self.INDEX_ID, "shop", "IN_FORCE", [])

    def manifest(self, stage):
        return contract_manifest.build_manifest(stage.directory, stage.tree, ["shop"], "task")

    def transcript(self, stage, entries):
        path = stage.base / "t.jsonl"
        path.write_text("".join(json.dumps({"message": {"content": [entry]}}) + "\n" for entry in entries))
        return path

    def read(self, document):
        return {"type": "tool_use", "name": "Read", "input": {"file_path": document}}

    def rows(self, manifest):
        return {row["id"]: row for row in manifest["contracts"]}

    def test_a_package_path_only_contract_is_index_and_a_mid_contract_is_binding(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_index_contract(stage)
            rows = self.rows(self.manifest(stage))
            self.assertEqual(rows[self.INDEX_ID]["tier"], "index")
            self.assertEqual(rows["SHOP_V1"]["tier"], "binding")

    def test_a_contract_cited_only_in_the_systems_source_is_index(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            identifier = "CITED_RULE_V1"
            source = stage.base / f"{identifier}.json"
            source.write_text(json.dumps({"contract_id": identifier, "note": "a rule the code follows"}))
            contract_registry.add(stage.directory, source, identifier, "shop", "IN_FORCE", [])
            (stage.tree / "internal/application/shop/shop.go").write_text(f"package shop\n// {identifier}\n")
            self.assertEqual(self.rows(self.manifest(stage))[identifier]["tier"], "index")

    def test_verify_needs_no_row_for_an_index_contract(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_index_contract(stage)
            manifest = self.manifest(stage)
            shop = self.rows(manifest)["SHOP_V1"]["document"]
            problems = contract_manifest.verify(
                manifest, "## Contract compliance\nid | verdict | evidence\n"
                          "SHOP_V1 | NOT_APPLICABLE | this task changes no shop behaviour\n", self.transcript(stage, [self.read(shop)]))
            self.assertEqual(problems, [])

    def test_an_applied_binding_row_citing_an_unchanged_file_fails(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            manifest = self.manifest(stage)
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            shop = self.rows(manifest)["SHOP_V1"]["document"]
            problems = contract_manifest.verify(
                manifest, "## Contract compliance\nid | verdict | evidence\n"
                          "SHOP_V1 | APPLIED | internal/application/shop/shop.go:1, TestShopBuy\n",
                self.transcript(stage, [self.read(shop)]))
            self.assertTrue(any("changed" in problem for problem in problems), problems)

    def test_an_applied_binding_row_citing_a_changed_file_passes(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            manifest = self.manifest(stage)
            commit(stage.tree, {"internal/application/shop/shop.go": "package shop\n// changed\n"})
            shop = self.rows(manifest)["SHOP_V1"]["document"]
            self.assertEqual(contract_manifest.verify(
                manifest, "## Contract compliance\nid | verdict | evidence\n"
                          "SHOP_V1 | APPLIED | internal/application/shop/shop.go:1, TestShopBuy\n",
                self.transcript(stage, [self.read(shop)])), [])

    def test_a_document_named_only_in_a_bash_command_is_not_opened(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            manifest = self.manifest(stage)
            commit(stage.tree, {"internal/application/shop/shop.go": "package shop\n// changed\n"})
            shop = self.rows(manifest)["SHOP_V1"]["document"]
            problems = contract_manifest.verify(
                manifest, "## Contract compliance\nid | verdict | evidence\n"
                          "SHOP_V1 | APPLIED | internal/application/shop/shop.go:1, TestShopBuy\n",
                self.transcript(stage, [{"type": "tool_use", "name": "Bash", "input": {"command": f"cat {shop}"}}]))
            self.assertTrue(any("was never opened" in problem for problem in problems), problems)

    def test_reading_an_identical_copy_of_the_document_opens_it(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            manifest = self.manifest(stage)
            commit(stage.tree, {"internal/application/shop/shop.go": "package shop\n// changed\n"})
            shop = pathlib.Path(self.rows(manifest)["SHOP_V1"]["document"])
            copy = pathlib.Path(temporary) / "design_copy.md"
            copy.write_bytes(shop.read_bytes())
            altered = pathlib.Path(temporary) / "design_altered.md"
            altered.write_bytes(shop.read_bytes() + b"\nedited\n")
            answer = ("## Contract compliance\nid | verdict | evidence\n"
                      "SHOP_V1 | APPLIED | internal/application/shop/shop.go:1, TestShopBuy\n")
            self.assertEqual(contract_manifest.verify(manifest, answer, self.transcript(stage, [self.read(str(copy))])), [])
            problems = contract_manifest.verify(manifest, answer, self.transcript(stage, [self.read(str(altered))]))
            self.assertTrue(any("was never opened" in problem for problem in problems), problems)

    def test_an_index_row_the_worker_writes_is_checked_like_a_binding_row(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_index_contract(stage)
            manifest = self.manifest(stage)
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            documents = [row["document"] for row in manifest["contracts"]]
            problems = contract_manifest.verify(
                manifest, "## Contract compliance\nid | verdict | evidence\n"
                          "SHOP_V1 | NOT_APPLICABLE | this task changes no shop behaviour\n"
                          f"{self.INDEX_ID} | APPLIED | internal/application/shop/shop.go:1, TestShopBuy\n",
                self.transcript(stage, [self.read(document) for document in documents]))
            self.assertTrue(any(problem.startswith(f"{self.INDEX_ID}: ") and "changed" in problem for problem in problems), problems)

    def test_render_prints_index_rows_after_the_binding_list(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_index_contract(stage)
            rendered = contract_manifest.render_manifest(self.manifest(stage))
            self.assertIn("Index-tier", rendered)
            self.assertGreater(rendered.index(f"{self.INDEX_ID} |"), rendered.index("Index-tier"))
            self.assertLess(rendered.index("SHOP_V1 |"), rendered.index("Index-tier"))

    def test_an_old_manifest_without_tiers_verifies_as_before(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            document = stage.base / "OLD.json"
            document.write_text("{}")
            manifest = dict(systems=["shop"], tree=str(stage.tree),
                            contracts=[dict(id="SHOP_V1", document=str(document))])
            transcript = self.transcript(stage, [{"type": "tool_use", "name": "Bash", "input": {"command": f"cat {document}"}}])
            self.assertEqual(contract_manifest.verify(
                manifest, "## Contract compliance\nid | verdict | evidence\n"
                          "SHOP_V1 | APPLIED | internal/application/shop/shop.go:1, TestShopBuy\n", transcript), [])


class KindTests(unittest.TestCase):
    def add_contract(self, stage, identifier="MODE_V1", rule="a closed loop"):
        source = stage.base / f"{identifier}.json"
        source.write_text(json.dumps({"contract_id": identifier, "rule": rule}))
        contract_registry.add(stage.directory, source, identifier, "mode", "IN_FORCE", [])

    def test_a_kind_binding_places_a_contract_on_every_system_of_the_kind(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_contract(stage)
            contract_registry.define_kind(stage.directory, "market", ["shop", "march"], "systems that trade")
            contract_registry.bind(stage.directory, "MODE_V1", ["kind:market"], "applies wherever goods move")
            found = contract_manifest.lookup(stage.directory, stage.tree)
            self.assertEqual(sorted(found["placed"]["MODE_V1"]), ["march", "shop"])
            self.assertEqual(found["placed"]["MODE_V1"]["shop"], ["lead binding (kind market): applies wherever goods move"])
            self.assertEqual(found["stale_bindings"], [])

    def test_an_unknown_kind_is_a_stale_binding(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_registry.bind(stage.directory, "SHOP_V1", ["kind:missing"], "definition lands later")
            self.assertEqual(kinds(stage.merge_check()), ["STALE_BINDING"])
            self.assertIn("kind:missing", stage.merge_check()[0])

    def test_a_kind_naming_a_system_the_map_lacks_is_stale(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_registry.define_kind(stage.directory, "market", ["shop", "gone"], "systems that trade")
            contract_registry.bind(stage.directory, "SHOP_V1", ["kind:market"], "applies wherever goods move")
            self.assertEqual(kinds(stage.merge_check()), ["STALE_BINDING"])
            self.assertIn("gone", stage.merge_check()[0])


class ScopeAlarmTests(unittest.TestCase):
    def add_scope_contract(self, stage, text="This rule applies to every mode.", identifier="MODE_V1"):
        source = stage.base / f"{identifier}.json"
        source.write_text(json.dumps({"contract_id": identifier, "rule": text}))
        contract_registry.add(stage.directory, source, identifier, "mode", "IN_FORCE", [])

    def test_an_unbound_scope_contract_fails_check_until_bound(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_scope_contract(stage)
            problems = contract_registry.check(stage.directory, [])
            self.assertEqual(kinds(problems), ["SCOPE_ALARM"])
            self.assertIn("every mode", problems[0])
            contract_registry.bind(stage.directory, "MODE_V1", [], "a process rule with no code")
            self.assertEqual(contract_registry.check(stage.directory, []), [])

    def test_a_scope_phrase_is_matched_case_insensitively(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_scope_contract(stage, "Applies to ALL MODES of the game.")
            self.assertTrue(any(problem.startswith("SCOPE_ALARM MODE_V1:") for problem in contract_registry.check(stage.directory, [])))

    def test_coverage_lists_a_scope_contract_and_the_systems_it_reaches(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_scope_contract(stage)
            contract_registry.define_kind(stage.directory, "market", ["shop", "march"], "systems that trade")
            contract_registry.bind(stage.directory, "MODE_V1", ["kind:market"], "applies wherever goods move")
            contract_manifest.coverage(stage.directory, stage.tree)
            written = (stage.directory / "COVERAGE.md").read_text()
            self.assertIn("## Scope contracts", written)
            self.assertIn("- MODE_V1 | reaches 2 system(s) | bound", written)


class RulingTests(unittest.TestCase):
    def add_ruling(self, stage, identifier="R_MODES_V1", amends=("SHOP_V1:2",), kind="ruling"):
        source = stage.base / f"{identifier}.md"
        source.write_text(f"# {identifier}\n")
        contract_registry.add(stage.directory, source, identifier, "ruling", "IN_FORCE", [], kind=kind, amends=list(amends))

    def test_the_manifest_lists_a_ruling_that_amends_its_contracts(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_ruling(stage)
            manifest = contract_manifest.build_manifest(stage.directory, stage.tree, ["shop"], "task")
            rows = {row["id"]: row for row in manifest["contracts"]}
            self.assertIn("R_MODES_V1", rows)
            self.assertEqual(rows["R_MODES_V1"]["reasons"], ["amends SHOP_V1"])
            self.assertEqual(rows["R_MODES_V1"]["tier"], "binding")
            self.assertEqual(rows["R_MODES_V1"]["systems"], ["shop"])
            self.assertIn("AMENDED BY R_MODES_V1:2", contract_manifest.render_manifest(manifest))

    def test_a_ruling_for_another_system_is_not_added(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_ruling(stage, amends=["MARCH_V1"])
            manifest = contract_manifest.build_manifest(stage.directory, stage.tree, ["shop"], "task")
            self.assertNotIn("R_MODES_V1", [row["id"] for row in manifest["contracts"]])

    def test_an_amends_target_that_is_not_registered_fails_check(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_ruling(stage, amends=["NOPE_V1:4"])
            problems = contract_registry.check(stage.directory, [])
            self.assertEqual(kinds(problems), ["AMENDS_UNREGISTERED"])
            self.assertIn("NOPE_V1:4", problems[0])

    def test_amend_edits_the_list_on_an_existing_ruling(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_ruling(stage, amends=[])
            contract_registry.amend(stage.directory, "R_MODES_V1", ["MARCH_V1:3"])
            entry = contract_registry.load(stage.directory)["contracts"]["R_MODES_V1"]
            self.assertEqual((entry["kind"], entry["amends"]), ("ruling", ["MARCH_V1:3"]))
            self.assertEqual(contract_registry.check(stage.directory, []), [])

    def test_re_adding_a_ruling_without_amends_keeps_its_list(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_ruling(stage)
            self.add_ruling(stage, amends=[])
            entry = contract_registry.load(stage.directory)["contracts"]["R_MODES_V1"]
            self.assertEqual(entry["amends"], ["SHOP_V1:2"])

    def test_an_older_contract_amended_by_a_newer_ruling_warns_without_failing(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_ruling(stage)
            registry = contract_registry.load(stage.directory)
            registry["contracts"]["SHOP_V1"]["registered"] = "2020-01-01T00:00:00+00:00"
            contract_registry.save(stage.directory, registry, "test", ["SHOP_V1"])
            problems = contract_registry.check(stage.directory, [])
            self.assertTrue(any(problem.startswith("WARNING AMENDED_OLDER SHOP_V1:") for problem in problems), problems)
            self.assertEqual(contract_registry.failure_problems(problems), [])

    def test_verify_requires_a_row_for_the_ruling_row(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.add_ruling(stage)
            manifest = contract_manifest.build_manifest(stage.directory, stage.tree, ["shop"], "task")
            transcript = stage.base / "t.jsonl"
            document = next(row["document"] for row in manifest["contracts"] if row["id"] == "SHOP_V1")
            transcript.write_text(json.dumps({"message": {"content": [{"type": "tool_use", "input": {"file_path": document}}]}}) + "\n")
            answer = (f"{contract_manifest.COMPLIANCE_HEADING}\nid | verdict | evidence\n"
                      "SHOP_V1 | APPLIED | internal/application/shop/shop.go:1, TestShopBuy\n")
            self.assertIn("R_MODES_V1: no row", contract_manifest.verify(manifest, answer, transcript))


class MergeCheckTests(unittest.TestCase):
    def test_a_clean_audited_leaf_passes(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"}, "shop buy\n\n" + DEEPSEEK)
            stage.dispatch(["shop"], pool="codex")
            self.assertEqual(stage.merge_check(), [])

    def test_an_unaudited_system_is_uncovered(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            self.assertEqual(kinds(stage.merge_check()), ["UNCOVERED"])

    def test_the_author_pool_cannot_audit_itself(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"}, "shop buy\n\n" + DEEPSEEK)
            stage.dispatch(["shop"], pool="deepseek")
            self.assertEqual(kinds(stage.merge_check()), ["INDEPENDENT_AUDIT"])

    def test_the_lead_signoff_audits_deepseek_work(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"}, "shop buy\n\n" + DEEPSEEK)
            stage.dispatch(["shop"], pool="deepseek")
            review = stage.base / "review.md"
            with self.assertRaises(ValueError):
                contract_manifest.lead_signoff(stage.directory, stage.tree, ["shop"], review)
            review.write_text("read internal/application/shop/buy.go\n")
            (stage.tree / "internal/application/shop/buy.go").write_text("package shop\n// dirty\n")
            with self.assertRaises(ValueError):
                contract_manifest.lead_signoff(stage.directory, stage.tree, ["shop"], review)
            git(stage.tree, "checkout", "--", ".")
            contract_manifest.lead_signoff(stage.directory, stage.tree, ["shop"], review)
            self.assertEqual(stage.merge_check(), [])

    def test_code_changed_after_the_audit(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            stage.dispatch(["shop"])
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n// later\n"})
            self.assertEqual(kinds(stage.merge_check()), ["CHANGED_AFTER_CHECK"])

    def test_a_failed_latest_audit_blocks(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            stage.dispatch(["shop"], status="FAIL")
            self.assertIn("COMPLIANCE", kinds(stage.merge_check()))

    def test_a_dispatch_row_pins_its_manifest_digest(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            stage.dispatch(["shop"])
            row = json.loads((stage.directory / "dispatches.jsonl").read_text().splitlines()[-1])
            self.assertIn("manifest_sha256", row)
            manifest = pathlib.Path(row["manifest"])
            manifest.write_text(manifest.read_text() + " ")
            self.assertEqual(kinds(stage.merge_check()), ["MANIFEST_CHANGED"])

    def test_a_row_recorded_before_manifest_pinning_is_unpinned_not_a_pass(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            stage.dispatch(["shop"])
            ledger = stage.directory / "dispatches.jsonl"
            rows = [json.loads(line) for line in ledger.read_text().splitlines()]
            rows[-1].pop("manifest_sha256")
            ledger.write_text("".join(json.dumps(row) + "\n" for row in rows))
            problems, notes, _ = contract_manifest.merge_check(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE)
            self.assertEqual(problems, [])
            self.assertTrue(any(note.startswith("UNPINNED shop:") for note in notes), notes)

    def test_a_contract_amended_after_the_pin_needs_revalidation(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            stage.dispatch(["shop"])
            amended = stage.base / "SHOP.json"
            amended.write_text(json.dumps({"contract_id": "SHOP_V1", "mids": [1072, 1091], "rule": "new"}))
            contract_registry.add(stage.directory, amended, "SHOP_V1", "shop", "IN_FORCE", [])
            self.assertEqual(kinds(stage.merge_check()), ["REVALIDATE"])

    def test_an_unowned_file_blocks_until_the_lead_binds_its_path(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"tools/generate.py": "print()\n"})
            self.assertEqual(kinds(stage.merge_check()), ["UNMAPPED"])
            contract_registry.bind_path(stage.directory, "tools/*.py", [], "content generators")
            self.assertEqual(stage.merge_check(), [])

    def test_an_absorbed_contract_blocks_until_reviewed_and_placed(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {f"docs/{PHASE}/NEW.json": {"contract_id": "NEW_V1", "rule": "places nothing"}})
            self.assertEqual(kinds(stage.merge_check()), ["COVERAGE", "REVIEW_PENDING"])
            contract_registry.accept(stage.directory, "NEW_V1", "IN_FORCE")
            contract_registry.bind(stage.directory, "NEW_V1", [], "a process rule with no code")
            self.assertEqual(stage.merge_check(), [])

    def test_a_preview_absorbs_nothing(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {f"docs/{PHASE}/NEW.json": {"contract_id": "NEW_V1", "rule": "x"}})
            before = (stage.directory / "registry.json").read_bytes()
            stage.merge_check(absorbing=False)
            self.assertEqual((stage.directory / "registry.json").read_bytes(), before)

    def test_a_waiver_clears_only_the_named_contract(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {f"docs/{PHASE}/ONE.json": {"contract_id": "ONE_V1", "rule": "x"},
                                f"docs/{PHASE}/TWO.json": {"contract_id": "TWO_V1", "rule": "y"}})
            self.assertEqual(len(stage.merge_check()), 4)
            for identifier in ("ONE_V1", "TWO_V1"):
                contract_registry.accept(stage.directory, identifier, "IN_FORCE")
            contract_registry.waive(stage.directory, "COVERAGE ONE_V1", "system not built yet")
            self.assertEqual(stage.merge_check(), [stage.merge_check()[0]])
            self.assertTrue(stage.merge_check()[0].startswith("COVERAGE TWO_V1:"))

    def test_a_binding_to_a_missing_system_is_stale(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_registry.bind(stage.directory, "SHOP_V1", ["gone"], "old name")
            self.assertEqual(kinds(stage.merge_check()), ["STALE_BINDING"])

    def test_the_audit_still_counts_after_a_fast_forward_merge(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            stage.dispatch(["shop"])
            git(stage.tree, "checkout", "-q", "main")
            git(stage.tree, "merge", "-q", "--ff-only", "a")
            self.assertEqual(stage.merge_check(), [])

    def test_a_waiver_unblocks_and_is_reported(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            contract_registry.waive(stage.directory, "UNCOVERED shop", "lead audited it by hand")
            problems, notes, _ = contract_manifest.merge_check(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE)
            self.assertEqual(problems, [])
            self.assertTrue(notes[0].startswith("WAIVED UNCOVERED shop:"))


class MergeHookTests(unittest.TestCase):
    def run_hook(self, stage, worktree):
        cwd = os.getcwd()
        os.chdir(worktree)
        try:
            with patch.object(contract_manifest, "registry_for", return_value=stage.directory), \
                 patch.object(contract_manifest, "phase_name", return_value=PHASE):
                return contract_manifest.merge_hook()
        finally:
            os.chdir(cwd)

    def test_the_hook_blocks_only_merges_in_the_integration_tree(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            integration = stage.base / "integration"
            git(stage.tree, "worktree", "add", "-q", str(integration), "main")
            git(integration, "-c", "user.name=t", "-c", "user.email=t@t", "merge", "-q", "--no-ff", "--no-commit", "a")
            self.assertEqual(self.run_hook(stage, integration), 0)
            contract_registry.set_integration(stage.directory, integration)
            self.assertEqual(self.run_hook(stage, integration), 1)
            git(integration, "merge", "--abort")
            self.assertEqual(self.run_hook(stage, integration), 0)

    def test_a_missing_frontier_registry_refuses_a_merge_in_a_recorded_integration_tree(self):
        """Row 3: the integration tree is recorded in a stage registry even before the frontier stage opens one."""
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            leaf = commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            integration = stage.base / "integration"
            git(stage.tree, "worktree", "add", "-q", str(integration), "main")
            recorded = stage.base / "phase/stages/I9-10/REGISTRY"
            recorded.mkdir(parents=True)
            (recorded / "registry.json").write_text(json.dumps({"integration": str(integration)}))
            facts = {"phase_workspace": {"path": "phase"}, "frontier": {"stage": "I9-11"}}
            cwd = os.getcwd()
            os.chdir(integration)
            try:
                with patch.object(contract_manifest, "registry_for", return_value=stage.base / "phase/stages/I9-11/REGISTRY"), \
                     patch.object(contract_manifest, "ROOT", stage.base), patch.object(state, "facts", return_value=facts), \
                     patch.object(contract_manifest, "phase_name", return_value=PHASE), \
                     patch.dict(os.environ, {f"GITHEAD_{leaf}": "a", "GIT_REFLOG_ACTION": "merge a"}):
                    self.assertEqual(contract_manifest.merge_hook(), 1)
                with patch.object(contract_manifest, "registry_for", return_value=stage.base / "phase/stages/I9-11/REGISTRY"), \
                     patch.object(contract_manifest, "ROOT", stage.base), patch.object(state, "facts", return_value=facts), \
                     patch.object(contract_manifest, "phase_name", return_value=PHASE), \
                     patch.dict(os.environ, {"GIT_REFLOG_ACTION": "commit"}, clear=True):
                    self.assertEqual(contract_manifest.merge_hook(), 0, "a non-merge commit stays unchanged")
            finally:
                os.chdir(cwd)

    def test_a_leaf_is_not_charged_with_commits_the_integration_already_merged(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            shared = commit(stage.tree, {"tools/shared.py": "print()\n"})
            git(stage.tree, "checkout", "-q", "-b", "b", shared)
            leaf = commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            git(stage.tree, "checkout", "-q", "main")
            commit(stage.tree, {"internal/application/march/claim.go": "package march\n"}, "main moves on")
            git(stage.tree, "checkout", "-q", "b")
            git(stage.tree, "-c", "user.name=t", "-c", "user.email=t@t", "merge", "-q", "--no-edit", "main")
            stage.dispatch(["shop"])
            integration = stage.base / "integration"
            git(stage.tree, "worktree", "add", "-q", str(integration), "main")
            git(integration, "-c", "user.name=t", "-c", "user.email=t@t", "merge", "-q", "--no-ff", "--no-verify", "--no-edit", "a")
            contract_registry.set_integration(stage.directory, integration)
            self.assertIn("UNMAPPED tools/shared.py", " ".join(contract_manifest.merge_check(
                stage.directory, stage.tree, git(integration, "merge-base", "HEAD", "b"), "b", PHASE, False)[0]))
            with patch.dict(os.environ, {f"GITHEAD_{git(stage.tree, 'rev-parse', 'b')}": "b", "GIT_REFLOG_ACTION": "merge b"}):
                self.assertEqual(self.run_hook(stage, integration), 0, leaf)

    def test_already_merged_commits_do_not_count_as_the_leafs_authors(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            shared = commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"}, "a\n\nCo-Authored-By: Codex Luna")
            git(stage.tree, "checkout", "-q", "-b", "b", shared)
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop // b\n"}, f"b\n\n{DEEPSEEK}")
            files = ["internal/application/shop/buy.go"]
            self.assertEqual(contract_manifest.author_pools(stage.tree, stage.base_commit, "b", files), {"codex", "deepseek"})
            self.assertEqual(contract_manifest.author_pools(stage.tree, stage.base_commit, "b", files, "a"), {"deepseek"})

    def test_a_generic_claude_code_trailer_names_no_pool(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"}, "a\n\nCo-Authored-By: Claude Code <noreply@anthropic.com>")
            files = ["internal/application/shop/buy.go"]
            self.assertEqual(contract_manifest.author_pools(stage.tree, stage.base_commit, "a", files), {"unknown"})
            stage.dispatch(["shop"], pool="deepseek")
            self.assertEqual(kinds(stage.merge_check()), ["AUTHOR_UNKNOWN"])
            commit(stage.tree, {"internal/application/shop/sell.go": "package shop\n"}, "b\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>")
            self.assertEqual(contract_manifest.author_pools(stage.tree, stage.base_commit, "a", ["internal/application/shop/sell.go"]), {"lead"})

    def test_a_commit_without_a_pool_trailer_is_unknown(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"}, f"a\n\n{DEEPSEEK}")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop // b\n"}, "b without a trailer")
            files = ["internal/application/shop/buy.go"]
            self.assertEqual(contract_manifest.author_pools(stage.tree, stage.base_commit, "a", files), {"deepseek", "unknown"})
            stage.dispatch(["shop"], pool="codex")
            self.assertIn("AUTHOR_UNKNOWN", kinds(stage.merge_check()))

    def test_a_subject_line_is_not_a_trailer(self):
        """A-081: only git's trailer block names authors; a message that is just a trailer-shaped subject is unknown."""
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"}, "Co-Authored-By: Codex <noreply@openai.com>")
            files = ["internal/application/shop/buy.go"]
            self.assertEqual(contract_manifest.author_pools(stage.tree, stage.base_commit, "a", files), {"unknown"})
            stage.dispatch(["shop"], pool="deepseek")
            self.assertIn("AUTHOR_UNKNOWN", kinds(stage.merge_check()))

    def test_the_sol_trailer_is_codex(self):
        """A-081: the auditor's required trailer names the codex pool after a model prefix."""
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"}, "a\n\nCo-Authored-By: GPT-6.1 Sol (Codex) <noreply@openai.com>")
            files = ["internal/application/shop/buy.go"]
            self.assertEqual(contract_manifest.author_pools(stage.tree, stage.base_commit, "a", files), {"codex"})
            commit(stage.tree, {"internal/application/shop/sell.go": "package shop\n"}, "b\n\nCo-Authored-By: Claude Codex mix <x@y>")
            self.assertEqual(contract_manifest.author_pools(stage.tree, stage.base_commit, "a", ["internal/application/shop/sell.go"]), {"unknown"})

    def test_code_written_only_by_a_merge_is_unknown(self):
        """A-081: a file changed only by a merge resolution has no trailer author, so it is unknown, never trusted."""
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"}, f"a\n\n{DEEPSEEK}")
            git(stage.tree, "checkout", "-q", "-b", "side", stage.base_commit)
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop // side\n"}, f"side\n\n{DEEPSEEK}")
            git(stage.tree, "checkout", "-q", "a")
            subprocess.run(["git", "-C", str(stage.tree), "merge", "-q", "--no-ff", "side", "-m", "merge"], capture_output=True)
            (stage.tree / "internal/application/shop/buy.go").write_text("package shop // resolved\n")
            (stage.tree / "internal/application/shop/merge_only.go").write_text("package shop\n")
            git(stage.tree, "add", "-A")
            git(stage.tree, "-c", "core.hooksPath=/dev/null", "commit", "-q", "--no-edit")
            self.assertEqual(contract_manifest.author_pools(stage.tree, stage.base_commit, "a", ["internal/application/shop/merge_only.go"]), {"unknown"})

    def test_a_clean_merge_is_checked_before_git_writes_merge_head(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            stage.leaf("a")
            leaf = commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            integration = stage.base / "integration"
            git(stage.tree, "worktree", "add", "-q", str(integration), "main")
            contract_registry.set_integration(stage.directory, integration)
            with patch.dict(os.environ, {f"GITHEAD_{leaf}": "a", "GIT_REFLOG_ACTION": "merge a"}):
                self.assertEqual(self.run_hook(stage, integration), 1)
            with patch.dict(os.environ, {"GIT_REFLOG_ACTION": "merge a"}):
                self.assertEqual(self.run_hook(stage, integration), 1)
            stage.dispatch(["shop"])
            with patch.dict(os.environ, {f"GITHEAD_{leaf}": "a", "GIT_REFLOG_ACTION": "merge a"}):
                self.assertEqual(self.run_hook(stage, integration), 0)

    def test_real_git_merge_runs_the_hook(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            hooks = stage.base / "hooks"
            hooks.mkdir()
            command = f"PYTHONPATH={pathlib.Path(__file__).resolve().parent} {sys.executable} -B -c " + repr(
                "import sys, pathlib, contract_manifest; from unittest.mock import patch; "
                f"patch.object(contract_manifest, 'registry_for', return_value=pathlib.Path({str(stage.directory)!r})).start(); "
                f"patch.object(contract_manifest, 'phase_name', return_value={PHASE!r}).start(); "
                "sys.exit(contract_manifest.merge_hook())")
            (hooks / "pre-merge-commit").write_text(f"#!/bin/bash\ntop=$(pwd)\n(unset GIT_DIR GIT_INDEX_FILE GIT_WORK_TREE; cd \"$top\" && {command})\n")
            (hooks / "pre-merge-commit").chmod(0o755)
            git(stage.tree, "config", "core.hooksPath", str(hooks))
            stage.leaf("a")
            commit(stage.tree, {"internal/application/shop/buy.go": "package shop\n"})
            git(stage.tree, "checkout", "-q", "main")
            contract_registry.set_integration(stage.directory, stage.tree)
            merged = subprocess.run(["git", "-C", str(stage.tree), "-c", "user.name=t", "-c", "user.email=t@t", "merge", "--no-ff", "-m", "m", "a"],
                                    capture_output=True, text=True)
            self.assertNotEqual(merged.returncode, 0, merged.stdout + merged.stderr)
            self.assertIn("UNCOVERED shop", merged.stderr)
            self.assertEqual(git(stage.tree, "rev-parse", "HEAD"), stage.base_commit)


class NodeReferenceTests(unittest.TestCase):
    """Row 7: node references resolve against the sealed hot and the workspace, not only two hot prefixes."""

    def test_every_reference_resolves_at_a_named_root(self):
        maintain = StageLifecycleTests.maintain_tool()
        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            authority = base / "work/authority_p798"
            (authority / "hot/00_PASSMAP").mkdir(parents=True)
            (authority / "hot/00_PASSMAP/HOT.json").write_text("{}")
            (base / "work/i8_5").mkdir(parents=True)
            (base / "work/i8_5/EVIDENCE.json").write_text("{}")
            passmap = types.SimpleNamespace(authority=authority, hot=authority / "hot")
            nodes = {"N1": {"closure_record": "00_PASSMAP/HOT.json", "evidence": ["work/i8_5/EVIDENCE.json"]},
                     "N2": {"evidence": ["HISTORICAL_NAME.json"]}}
            self.assertEqual(maintain.unresolved_node_references(passmap, nodes, {"HISTORICAL_NAME.json": "moved"}), [])
            nodes["N3"] = {"evidence": ["work/gone/MISSING.json"]}
            findings = maintain.unresolved_node_references(passmap, nodes, {"HISTORICAL_NAME.json": "moved"})
            self.assertEqual(len(findings), 1)
            self.assertIn("node N3 reference work/gone/MISSING.json resolves nowhere", findings[0])

    def test_backend_reference_resolves_in_the_backend_tree(self):
        maintain = StageLifecycleTests.maintain_tool()
        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            authority = base / "work/authority_p799"
            (authority / "hot").mkdir(parents=True)
            backend = base / "work/backend"
            (backend / "internal/x").mkdir(parents=True)
            (backend / "internal/x/a_test.go").write_text("package x")
            passmap = types.SimpleNamespace(authority=authority, hot=authority / "hot")
            nodes = {"N1": {"evidence": ["backend internal/x/a_test.go"]}}
            self.assertEqual(maintain.unresolved_node_references(passmap, nodes, {}, backend), [])
            nodes["N2"] = {"evidence": ["backend internal/x/gone_test.go"]}
            findings = maintain.unresolved_node_references(passmap, nodes, {}, backend)
            self.assertEqual(len(findings), 1)
            self.assertIn("node N2 reference backend internal/x/gone_test.go resolves nowhere", findings[0])
            self.assertEqual(len(maintain.unresolved_node_references(passmap, nodes, {})), 2)

    def test_restored_copy_resolves_workspace_references_in_the_source_workspace(self):
        maintain = StageLifecycleTests.maintain_tool()
        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            (base / "work/i9").mkdir(parents=True)
            (base / "work/i9/PLAN.md").write_text("plan")
            restored = base / "logs/passmap-seal/799/package_799/restored"
            (restored / "hot").mkdir(parents=True)
            passmap = types.SimpleNamespace(authority=restored, hot=restored / "hot")
            nodes = {"N1": {"evidence": ["work/i9/PLAN.md"]}}
            self.assertEqual(len(maintain.unresolved_node_references(passmap, nodes, {})), 1)
            self.assertEqual(maintain.unresolved_node_references(passmap, nodes, {}, workspace=base), [])


class ReleaseAncestorTests(unittest.TestCase):
    """D520: the release path is checked on the real depends_on graph, against the sealed p798 roadmap."""

    REQUIRED = ["I11A_CONTROL_CORE", "I10_FULL_COMMERCE", "I10_5_SEASONAL_EVENTS", "I11"]

    @staticmethod
    def sealed_nodes():
        roadmap = max(pathlib.Path(__file__).resolve().parents[1].glob("work/authority_p*/hot/records/roadmap"))
        nodes = {}
        for path in roadmap.rglob("*.json"):
            if not path.name.startswith("_"):
                nodes.update(json.loads(path.read_text())["nodes"])
        return nodes

    def test_p798_edges_are_refused_on_i12_and_the_d520_edges_pass(self):
        maintain = StageLifecycleTests.maintain_tool()
        rule = {"roots": ["I12"], "required": self.REQUIRED}
        nodes = self.sealed_nodes()
        nodes["I11B_SELECTED_OWNER_INTEGRATION"]["depends_on"] = ["I11A_CONTROL_CORE", "RELEASE_SCOPE_CLOSURE"]
        nodes["I12"]["depends_on"] = ["I11B_SELECTED_OWNER_INTEGRATION"]
        findings = maintain.missing_release_ancestors(nodes, rule)
        self.assertIn("release node I12 lacks required ancestor I10_5_SEASONAL_EVENTS (D520)", findings)
        self.assertIn("release node I12 lacks required ancestor I11 (D520)", findings)
        nodes["I11B_SELECTED_OWNER_INTEGRATION"]["depends_on"].append("I10_5_SEASONAL_EVENTS")
        nodes["I12"]["depends_on"].append("I11")
        self.assertEqual(maintain.missing_release_ancestors(nodes, rule), [])

    def test_a_later_release_node_is_checked_without_being_listed(self):
        maintain = StageLifecycleTests.maintain_tool()
        nodes = {"I11": {"depends_on": []}, "I12": {"depends_on": ["I11"]}, "I16": {"depends_on": ["I12"]},
                 "SIDE": {"depends_on": []}, "I17": {"depends_on": ["I16", "SIDE"]}}
        self.assertEqual(maintain.missing_release_ancestors(nodes, {"roots": ["I12"], "required": ["I11"]}), [])
        nodes["I12"]["depends_on"] = []
        self.assertEqual(maintain.missing_release_ancestors(nodes, {"roots": ["I12"], "required": ["I11"]}),
                         [f"release node {node} lacks required ancestor I11 (D520)" for node in ("I12", "I16", "I17")])

    def test_a_missing_rule_is_a_finding(self):
        maintain = StageLifecycleTests.maintain_tool()
        self.assertEqual(len(maintain.missing_release_ancestors({}, None)), 1)


class DecisionParserTests(unittest.TestCase):
    """Row 5: every decision start in the real DECISIONS.md yields a row; bullets, ranges and reservations included."""

    DECISIONS = pathlib.Path("/home/akm/Chatgpt/EOL_Game/work/i9/passmap/inputs/DECISIONS.md")
    SEALED = pathlib.Path("/home/akm/Chatgpt/EOL_Game/work/authority_p798/hot/records/decisions/I9.json")
    NEW_IDS = ("D158 D159 D160 D161 D162 D163 D164 D165 D166 D167 D168 D169 "
               "D306 D307 D308 D309 D311 D312 D313 D314 D315 D450 "
               "D454 D455 D456 D457 D458 D459 D460 D461 D462 D463 D464 D465 D466 D467 D468 D469 "
               "D470 D471 D472 D473 D474 D475 D476 D477 D478 D479 D480 D481 D482 D483 D484 D485 "
               "D486 D487 D488 D489 D490 D491 D492 D493 D494 D495 D496 D497 D498 "
               "D499 D500 D501 D502 D503 D504 D505 D506 D507 D508 D509 D510 D511 D512 D513 D514 D515 D516 D517 D518 D519 D520 D521 D522 D523 D524").split()

    def rows(self):
        return StageLifecycleTests.maintain_tool().parse_decisions(self.DECISIONS.read_text())

    def test_every_decision_start_yields_a_row(self):
        rows = self.rows()
        sealed = {row["id"] for row in json.loads(self.SEALED.read_text())["decisions"]}
        self.assertEqual(len(sealed), 207)
        identifiers = {row["id"] for row in rows}
        self.assertEqual(len(rows), 207 + len(self.NEW_IDS))
        self.assertTrue(sealed <= identifiers)
        self.assertEqual(sorted(identifiers - sealed, key=lambda value: int(value[1:])), self.NEW_IDS)
        by_id = {row["id"]: row for row in rows}
        self.assertEqual((by_id["D75"]["who"], by_id["D75"]["date"]), ("user", "2026-10-24"))
        self.assertEqual(by_id["D450"]["date"], "2026-11-02")
        self.assertEqual(by_id["D306"]["who"], "PRIVATE_POLICY: Dodgeball")
        self.assertIn("reserved for the I9-3 close", by_id["D158"]["text"])

    def test_a_decision_start_that_yields_no_row_fails_the_sync(self):
        maintain = StageLifecycleTests.maintain_tool()
        with self.assertRaises(SystemExit) as raised:
            maintain.parse_decisions("D9-D3 backwards range\n")
        self.assertIn("line 1", str(raised.exception))


class SealCheckTests(unittest.TestCase):
    """A merge made with `git merge --no-verify` skips the hooks; the seal entry point must still refuse it."""

    def bypassed_merge(self, stage, files, message="leaf"):
        stage.leaf("a")
        commit(stage.tree, files, f"{message}\n\n{DEEPSEEK}")
        stage.dispatch(["shop"])
        git(stage.tree, "checkout", "-q", "main")
        contract_registry.set_integration(stage.directory, stage.tree)
        git(stage.tree, "-c", "user.name=t", "-c", "user.email=t@t", "merge", "-q", "--no-ff", "--no-verify", "--no-edit", "a")

    def seal(self, stage, ledger=False):
        """`ledger` False keeps the obligations ledger out of the way of the other seal rules."""
        root = stage.base / "root"
        if not root.exists():
            (root / "work/authority_p798").mkdir(parents=True)
            (root / "work/authority_p798/hot").symlink_to(stage.hot)
            (stage.hot / "00_PASSMAP").mkdir()
            (root / "work/authority_p798" / contract_registry.HOT_V1_ARCHIVE).mkdir(parents=True)
            (root / "work/i9").mkdir()
        facts = {"phase_workspace": {"path": "work/i9"}, "frontier": {"stage": "I9-11"}}
        printed = io.StringIO()
        with patch.object(contract_manifest, "registry_for", return_value=stage.directory), \
             patch.object(contract_manifest, "ROOT", root), patch.object(contract_registry, "ROOT", root), \
             patch.object(state, "facts", return_value=facts), patch.object(state, "BACKEND", stage.tree), \
             contextlib.redirect_stdout(printed), contextlib.ExitStack() as stack:
            if not ledger:
                stack.enter_context(patch.object(contract_manifest, "sealed_obligations", return_value=[]))
            status = contract_manifest.seal_check()
        return status, printed.getvalue().strip()

    def test_an_audited_leaf_seals(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.bypassed_merge(stage, {"internal/application/shop/buy.go": "package shop\n"})
            self.assertEqual(self.seal(stage), (0, "exported: \nSEAL_CONTRACT_CHECK PASS"))

    def test_the_obligations_ledger_gates_the_seal(self):
        """CONTROL_PLANE_OBLIGATIONS_V1 ruling 3: a missing ledger or a row due at this stage that is not DONE refuses."""
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.bypassed_merge(stage, {"internal/application/shop/buy.go": "package shop\n"})
            status, printed = self.seal(stage, ledger=True)
            self.assertEqual(status, 1)
            self.assertIn("OBLIGATIONS_MISSING", printed)
            ledger = stage.base / "CONTROL_PLANE_OBLIGATIONS_V1.md"
            ledger.write_text("| CPO-01 | shop | COMMAND | prices | I9-11 | OPEN | D476 |\n"
                              "| CPO-02 | shop | COMMAND | pools | OWNER_KNOB | OPEN | OPS |\n")
            contract_registry.add(stage.directory, ledger, "CONTROL_PLANE_OBLIGATIONS_V1", "obligations", "IN_FORCE", [])
            contract_registry.bind(stage.directory, "CONTROL_PLANE_OBLIGATIONS_V1", [contract_registry.GLOBAL], "every system")
            status, printed = self.seal(stage, ledger=True)
            self.assertEqual(status, 1)
            self.assertIn("OBLIGATION_DUE CPO-01", printed)
            self.assertNotIn("CPO-02", printed)
            ledger.write_text(ledger.read_text().replace("| I9-11 | OPEN |", "| I9-11 | DONE |"))
            contract_registry.add(stage.directory, ledger, "CONTROL_PLANE_OBLIGATIONS_V1", "obligations", "IN_FORCE", [])
            stage.dispatch(["shop"])  # a contract newly bound to shop needs a manifest task that carried it
            final = self.seal(stage, ledger=True)
            self.assertEqual(final[0], 0, final[1])

    def test_an_unaudited_bypassed_merge_is_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.bypassed_merge(stage, {"internal/application/march/claim.go": "package march\n"})
            status, printed = self.seal(stage)
            self.assertEqual(status, 1)
            self.assertIn("UNCOVERED march", printed)

    def test_a_missing_verdicts_file_is_refused(self):
        """Row 4: losing verdicts.json must not turn every VIOLATED finding into silence."""
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.bypassed_merge(stage, {"internal/application/shop/buy.go": "package shop\n"})
            (stage.directory / "verdicts.json").unlink()
            status, printed = self.seal(stage)
            self.assertEqual(status, 1)
            self.assertIn("VERDICTS_MISSING", printed)
            (stage.directory / "verdicts.json").write_text("{}\n")
            self.assertEqual(self.seal(stage)[0], 0)

    def test_a_missing_contract_is_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.bypassed_merge(stage, {"internal/application/shop/buy.go": "package shop\n",
                                        f"docs/{PHASE}/NEW.json": {"contract_id": "NEW_V1"},
                                        f"docs/{PHASE}/deep/LIMIT_POLICY.json": {"rules": [1]}})
            status, printed = self.seal(stage)
            self.assertEqual(status, 1)
            self.assertIn(f"UNREGISTERED NEW_V1: {stage.tree}/docs/{PHASE}/NEW.json", printed)
            self.assertIn(f"UNCLASSIFIED docs/{PHASE}/deep/LIMIT_POLICY.json", printed)

    def test_a_stale_contract_is_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.bypassed_merge(stage, {"internal/application/shop/buy.go": "package shop\n",
                                        f"docs/{PHASE}/SHOP.json": {"contract_id": "SHOP_V1", "mids": [1072], "amended": True}})
            status, printed = self.seal(stage)
            self.assertEqual(status, 1)
            self.assertIn("DIVERGED SHOP_V1", printed)
            registered = stage.directory / contract_registry.load(stage.directory)["contracts"]["MARCH_V1"]["document"]
            registered.write_text("# March\nedited in place\n")
            self.assertIn("MARCH_V1: documents/", self.seal(stage)[1])

    def test_an_unreviewed_contract_is_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.bypassed_merge(stage, {"internal/application/shop/buy.go": "package shop\n",
                                        f"docs/{PHASE}/NEW.json": {"contract_id": "NEW_V1", "mids": [1072]}})
            contract_registry.absorb(stage.directory, stage.tree, stage.base_commit, "HEAD", PHASE)
            status, printed = self.seal(stage)
            self.assertEqual(status, 1)
            self.assertIn("REVIEW_PENDING NEW_V1", printed)
            contract_registry.accept(stage.directory, "NEW_V1", "IN_FORCE")
            self.assertEqual(self.seal(stage)[0], 1, "NEW_V1 changed the shop contracts the audit pinned")

    def test_a_contract_the_v1_archive_preserved_is_not_registered(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.bypassed_merge(stage, {"internal/application/shop/buy.go": "package shop\n"})
            self.seal(stage)
            archive = stage.base / "root/work/authority_p798" / contract_registry.HOT_V1_ARCHIVE
            (archive / "PASS574_CA6_3_POLICY_REGISTER_AMENDMENT.json").write_text(json.dumps({"rules": ["base ledger"]}))
            (archive / "PASS663_I7B2A_IMPLEMENTATION_SPEC.json").write_text(json.dumps({"spec_id": "I7B2A_V1"}))
            status, printed = self.seal(stage)
            self.assertEqual(status, 1)
            self.assertIn("UNCLASSIFIED hot763/PASS574_CA6_3_POLICY_REGISTER_AMENDMENT.json", printed)
            self.assertIn("UNCLASSIFIED hot763/PASS663_I7B2A_IMPLEMENTATION_SPEC.json", printed)

    def test_the_seal_script_runs_the_check_before_anything_else(self):
        script = (pathlib.Path(__file__).resolve().parent / "seal_passmap.sh").read_text().splitlines()
        commands = [line for line in script if line and not line.startswith(("#", " ", "set ", "if ")) and "=" not in line.split()[0]]
        # Only refusal guards (clean tree, gate evidence) may run before the contract check.
        check = next(index for index, line in enumerate(commands) if "contract_manifest.py\" seal-check" in line)
        self.assertIn("contract_manifest.py\" seal-check $stage_flag > \"$logs/contracts_$generation.log\" 2>&1 \\", commands[check])
        self.assertIn("exit 1", script[script.index(commands[check]) + 1])
        self.assertEqual(commands[0], 'mkdir -p "$logs"')
        for guard in commands[1:check]:
            following = script[script.index(guard) + 1] if guard.endswith("\\") else guard
            self.assertIn("exit 1", following, guard)



UPHELD = {"id": "SHOP_V1", "verdict": "UPHELD", "systems": ["shop"], "evidence": ["internal/application/shop/shop.go:1"],
          "tests": [{"name": "TestShopBuy", "result": "PASS"}]}


class ComplianceMatrixTests(unittest.TestCase):
    def test_upheld_needs_evidence_and_a_passing_test(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            for row in ({**UPHELD, "tests": []}, {**UPHELD, "tests": [{"name": "TestShopBuy", "result": "FAIL"}]},
                        {**UPHELD, "evidence": []}, {**UPHELD, "verdict": "FINE"}, {**UPHELD, "id": "NOPE_V1"}):
                with self.assertRaises(SystemExit):
                    contract_manifest.record_verdicts(stage.directory, [row], "deepseek", False)
            self.assertEqual(contract_manifest.load_verdicts(stage.directory), {})
            contract_manifest.record_verdicts(stage.directory, [{**UPHELD, "verdict": "UPHELD_UNTESTED", "tests": []}], "deepseek", False)

    def test_only_a_declared_pool_can_record_verdicts(self):
        """Row 15: --by is not free text; a finding's author is deepseek, codex or lead."""
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            with self.assertRaises(SystemExit):
                contract_manifest.record_verdicts(stage.directory, [UPHELD], "haiku", False)
            self.assertEqual(contract_manifest.load_verdicts(stage.directory), {})
            verdicts = stage.base / "verdicts.json"
            verdicts.write_text(json.dumps([UPHELD]))
            with patch.object(sys, "argv", ["contract_manifest.py", "record-verdicts", str(verdicts), "--by", "haiku"]):
                with self.assertRaises(SystemExit):
                    contract_manifest.main()

    def test_counts_need_lead_review_and_every_bound_system(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            counts = contract_manifest.matrix(stage.directory, stage.tree)
            self.assertEqual((counts["registered"], counts["assessed"], counts["unknown"]), (2, 0, 2))
            contract_manifest.record_verdicts(stage.directory, [UPHELD], "deepseek", False)
            self.assertEqual(contract_manifest.matrix(stage.directory, stage.tree)["verified_upheld"], 0)
            contract_manifest.record_verdicts(stage.directory, [{**UPHELD, "systems": ["march"]}], "deepseek", True)
            self.assertEqual(contract_manifest.matrix(stage.directory, stage.tree)["verified_upheld"], 0, "march is not bound; shop unreviewed")
            contract_manifest.record_verdicts(stage.directory, [UPHELD], "deepseek", True)
            counts = contract_manifest.matrix(stage.directory, stage.tree)
            self.assertEqual((counts["assessed"], counts["verified_upheld"], counts["unknown"]), (1, 1, 1))
            row = json.loads((stage.directory / "COMPLIANCE_MATRIX.json").read_text())["contracts"][1]
            self.assertEqual((row["id"], row["mids"], row["production_paths"], row["test_files"]),
                             ("SHOP_V1", [1072, 1073, 1074, 1091], ["internal/application/shop/"], ["internal/application/shop/shop_test.go"]))

    def test_an_amended_contract_makes_its_verdict_stale(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_manifest.record_verdicts(stage.directory, [UPHELD], "deepseek", True)
            amended = stage.base / "SHOP.json"
            amended.write_text(json.dumps({"contract_id": "SHOP_V1", "mids": [1072], "amended": True}))
            contract_registry.add(stage.directory, amended, "SHOP_V1", "", "IN_FORCE", [])
            counts = contract_manifest.matrix(stage.directory, stage.tree)
            self.assertEqual((counts["assessed"], counts["stale"], counts["verified_upheld"]), (0, 1, 0))

    def test_a_violation_blocks_the_seal_until_reaudited_or_waived(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            seals = SealCheckTests()
            seals.bypassed_merge(stage, {"internal/application/shop/buy.go": "package shop\n"})
            contract_manifest.record_verdicts(stage.directory, [{**UPHELD, "verdict": "VIOLATED", "tests": []}], "deepseek", True)
            status, printed = seals.seal(stage)
            self.assertEqual(status, 1)
            self.assertIn("VIOLATED SHOP_V1", printed)
            self.assertIn("VIOLATED SHOP_V1@shop", printed)
            contract_registry.waive(stage.directory, "VIOLATED SHOP_V1@shop", "fix lands next stage")
            self.assertEqual(seals.seal(stage)[0], 0)
            (stage.directory / "waivers.json").unlink()
            contract_manifest.record_verdicts(stage.directory, [{**UPHELD, "systems": ["march"]}], "deepseek", True)
            self.assertEqual(seals.seal(stage)[0], 1, "another system's verdict does not clear the shop violation")
            contract_manifest.record_verdicts(stage.directory, [UPHELD], "deepseek", True)
            self.assertEqual(seals.seal(stage)[0], 0)

    def test_the_worst_system_verdict_is_the_contracts(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_manifest.record_verdicts(stage.directory, [UPHELD, {**UPHELD, "systems": ["march"], "verdict": "PARTIAL"}], "deepseek", True)
            counts = contract_manifest.matrix(stage.directory, stage.tree)
            self.assertEqual((counts["violated"], counts["verified_upheld"]), (1, 0))

    def test_every_bound_system_must_be_assessed(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_registry.bind(stage.directory, "SHOP_V1", ["march"], "march sells through the shop")
            contract_manifest.record_verdicts(stage.directory, [UPHELD], "deepseek", True)
            counts = contract_manifest.matrix(stage.directory, stage.tree)
            self.assertEqual((counts["verified_upheld"], counts["partly_assessed"]), (0, 1))

    def test_a_verdict_turns_stale_after_its_cited_file_changes(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_manifest.record_verdicts(stage.directory, [UPHELD], "deepseek", True)
            recorded = contract_manifest.load_verdicts(stage.directory)["SHOP_V1"]["systems"]["shop"]
            self.assertEqual(recorded["tree_head"], git(stage.tree, "rev-parse", "HEAD"))
            self.assertIn("internal/application/shop/shop.go", recorded["blobs"])
            commit(stage.tree, {"internal/application/shop/shop.go": "package shop\n\n// changed\n"})
            counts = contract_manifest.matrix(stage.directory, stage.tree)
            self.assertEqual((counts["stale"], counts["verified_upheld"]), (1, 0))

    def test_a_verdict_recorded_before_pinning_is_unpinned_not_stale(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_manifest.record_verdicts(stage.directory, [UPHELD], "deepseek", True)
            path = stage.directory / "verdicts.json"
            verdicts = json.loads(path.read_text(encoding="utf-8"))
            verdicts["SHOP_V1"]["systems"]["shop"].pop("blobs")
            verdicts["SHOP_V1"]["systems"]["shop"].pop("tree_head")
            path.write_text(json.dumps(verdicts))
            commit(stage.tree, {"internal/application/shop/shop.go": "package shop\n\n// changed\n"})
            counts = contract_manifest.matrix(stage.directory, stage.tree)
            self.assertEqual((counts["stale"], counts["unpinned"]), (0, 1))

    def test_reauditing_one_system_does_not_pin_another_systems_legacy_verdict(self):
        """A-086: pins belong to each system's finding, so a partial re-audit leaves an untouched legacy finding UNPINNED."""
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_registry.bind(stage.directory, "SHOP_V1", ["march"], "march sells through the shop")
            contract_manifest.record_verdicts(stage.directory, [UPHELD, {**UPHELD, "systems": ["march"]}], "deepseek", True)
            path = stage.directory / "verdicts.json"
            verdicts = json.loads(path.read_text(encoding="utf-8"))
            for finding in verdicts["SHOP_V1"]["systems"].values():
                finding.pop("blobs")
                finding.pop("tree_head")
            path.write_text(json.dumps(verdicts))
            contract_manifest.record_verdicts(stage.directory, [{**UPHELD, "systems": ["march"]}], "deepseek", True)
            counts = contract_manifest.matrix(stage.directory, stage.tree)
            self.assertEqual((counts["unpinned"], counts["verified_upheld"]), (1, 0))

    def test_a_verdict_is_pinned_to_the_head_it_judged_not_the_integration_head(self):
        """Law P: a row naming source_head pins the blobs it judged; a later integration change makes it STALE."""
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            judged = git(stage.tree, "rev-parse", "HEAD")
            commit(stage.tree, {"internal/application/shop/shop.go": "package shop\n\nvar changed = 1\n"})
            contract_manifest.record_verdicts(stage.directory, [{**UPHELD, "source_head": judged}], "codex", True)
            finding = contract_manifest.load_verdicts(stage.directory)["SHOP_V1"]["systems"]["shop"]
            self.assertEqual(finding["tree_head"], judged)
            self.assertEqual(contract_manifest.matrix(stage.directory, stage.tree)["stale"], 1)

    def test_a_verdict_names_a_head_and_revision_that_exist_or_is_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            for row in ({**UPHELD, "source_head": "0" * 40}, {**UPHELD, "document_sha256": "0" * 64}):
                with self.assertRaises(SystemExit):
                    contract_manifest.record_verdicts(stage.directory, [row], "codex", True)
            self.assertEqual(contract_manifest.load_verdicts(stage.directory), {})

    def test_a_missing_cited_path_refuses_the_whole_recording(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            all_missing = {**UPHELD, "evidence": ["internal/application/shop/deleted.go:1"]}
            mixed = {**UPHELD, "systems": ["march"],
                     "evidence": ["internal/application/shop/shop.go:1", "internal/application/shop/deleted.go:1"]}
            for row in (all_missing, mixed):
                with self.assertRaises(SystemExit):
                    contract_manifest.record_verdicts(stage.directory, [row], "deepseek", True)
            self.assertEqual(contract_manifest.load_verdicts(stage.directory), {})

    def test_a_path_introduced_after_the_pinned_head_is_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            commit(stage.tree, {"internal/application/shop/new.go": "package shop\n"})
            row = {**UPHELD, "source_head": stage.base_commit, "evidence": ["internal/application/shop/new.go:1"]}
            with self.assertRaises(SystemExit):
                contract_manifest.record_verdicts(stage.directory, [row], "deepseek", True)
            self.assertEqual(contract_manifest.load_verdicts(stage.directory), {})

    def test_a_no_code_row_records_and_is_not_unpinned(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            row = {**UPHELD, "verdict": "NOT_APPLICABLE", "evidence": [], "tests": []}
            contract_manifest.record_verdicts(stage.directory, [row], "deepseek", True)
            finding = contract_manifest.load_verdicts(stage.directory)["SHOP_V1"]["systems"]["shop"]
            self.assertEqual((finding["blobs"], finding["no_code_evidence"]), ({}, True))
            self.assertEqual(contract_manifest.matrix(stage.directory, stage.tree)["unpinned"], 0)
            path = stage.directory / "verdicts.json"
            verdicts = json.loads(path.read_text(encoding="utf-8"))
            verdicts["SHOP_V1"]["systems"]["shop"].pop("no_code_evidence")
            path.write_text(json.dumps(verdicts))
            self.assertEqual(contract_manifest.matrix(stage.directory, stage.tree)["unpinned"], 1)


class SourceDriftTests(unittest.TestCase):
    """A-082/A-088: every copy is tied to the mutable file it came from; a later edit there must be re-registered."""

    @staticmethod
    def empty_hot(base):
        hot = base / "hot"
        (hot / "records").mkdir(parents=True)
        (hot / "contracts").mkdir()
        (hot / "records/contracts.json").write_text(json.dumps({"contracts": {}}))
        return hot

    def test_a_phase_input_copy_is_tied_to_its_source(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            hot = self.empty_hot(base)
            inputs = base / "inputs"
            inputs.mkdir()
            source = inputs / "NEW_POLICY.md"
            source.write_text("Contract-Id: NEW_POLICY_V1\nThe shop cap is 5.\n")
            (inputs / "CONTRACTS.json").write_text(json.dumps({"contracts": [
                {"id": "NEW_POLICY_V1", "document": "NEW_POLICY.md", "status": "IN_FORCE"}]}))
            directory = base / "REGISTRY"
            contract_registry.open_registry(directory, 798, hot, inputs, base / "no_contracts", "I9-11")
            entry = contract_registry.load(directory)["contracts"]["NEW_POLICY_V1"]
            self.assertEqual((entry["provenance"]["source"], entry["provenance"]["sha256"]),
                             (str(source), contract_registry.digest(source)))
            self.assertEqual(contract_registry.check(directory, []), [])
            source.write_text("Contract-Id: NEW_POLICY_V1\nThe shop cap is 7.\n")
            self.assertEqual([p for p in contract_registry.check(directory, []) if "SOURCE_" in p],
                             [f"SOURCE_DRIFT NEW_POLICY_V1: {source} changed since it was registered; re-add it"])

    def test_a_stage_contract_copy_is_tied_to_its_source(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = pathlib.Path(temporary)
            hot = self.empty_hot(base)
            stage_contracts = base / "contracts"
            stage_contracts.mkdir()
            source = stage_contracts / "STAGE.md"
            source.write_text("Contract-Id: STAGE_V1\nThe stage rule.\n")
            directory = base / "REGISTRY"
            contract_registry.open_registry(directory, 798, hot, base / "no_inputs", stage_contracts, "I9-11")
            entry = contract_registry.load(directory)["contracts"]["STAGE_V1"]
            self.assertEqual((entry["provenance"]["source"], entry["provenance"]["sha256"]),
                             (str(source), contract_registry.digest(source)))
            source.write_text("Contract-Id: STAGE_V1\nThe stage rule changed.\n")
            self.assertEqual([p for p in contract_registry.check(directory, []) if "SOURCE_" in p],
                             [f"SOURCE_DRIFT STAGE_V1: {source} changed since it was registered; re-add it"])

    def test_a_mutable_copy_without_source_provenance_is_an_unsourced_warning(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            source = stage.base / "POLICY.md"
            source.write_text("Contract-Id: P_V1\nThe policy.\n")
            contract_registry.add(stage.directory, source, "P_V1", "p", "IN_FORCE", [])
            path = stage.directory / "registry.json"
            registry = json.loads(path.read_text(encoding="utf-8"))
            registry["contracts"]["P_V1"].pop("provenance")
            path.write_text(json.dumps(registry))
            problems = contract_registry.check(stage.directory, [])
            self.assertIn(f"{contract_registry.WARNING_PREFIX}UNSOURCED P_V1: no source provenance", " ".join(problems))
            self.assertEqual(contract_registry.failure_problems(problems), [])

    def test_an_edited_ruling_source_fails_the_check_until_re_added(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            source = stage.base / "DECISIONS.md"
            source.write_text("D1 (lead, 2026-11-16) The shop cap is 5.\n")
            contract_registry.add(stage.directory, source, "PHASE_DECISIONS", "decisions", "IN_FORCE", [], kind="ruling", amends=["SHOP_V1"])
            self.assertEqual([p for p in contract_registry.check(stage.directory, []) if "SOURCE_" in p], [])
            source.write_text(source.read_text() + "D2 (lead, 2026-11-16) The shop cap is 7.\n")
            self.assertEqual([p for p in contract_registry.check(stage.directory, []) if "SOURCE_" in p],
                             [f"SOURCE_DRIFT PHASE_DECISIONS: {source} changed since it was registered; re-add it"])
            contract_registry.add(stage.directory, source, "PHASE_DECISIONS", "decisions", "IN_FORCE", [], kind="ruling", amends=["SHOP_V1"])
            self.assertEqual([p for p in contract_registry.check(stage.directory, []) if "SOURCE_" in p], [])
            source.unlink()
            self.assertEqual([p for p in contract_registry.check(stage.directory, []) if "SOURCE_" in p],
                             [f"SOURCE_MISSING PHASE_DECISIONS: {source} is gone; restore it or record where it moved with `add`"])


class StageLifecycleTests(unittest.TestCase):
    """Scope survives export -> seal sync -> next-stage open (audit A-077, A-078)."""

    def test_kind_definitions_travel_with_inherited_bindings(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_registry.define_kind(stage.directory, "mode", ["shop", "march"], "every mode")
            contract_registry.bind(stage.directory, "SHOP_V1", ["kind:mode"], "bind every mode")
            following = stage.base / "next_REGISTRY"
            contract_registry.open_registry(following, 799, stage.hot, stage.inputs, stage.base / "no_contracts", "I9-12",
                                            contract_registry.load_bindings(stage.directory),
                                            contract_registry.load_path_bindings(stage.directory), stage.base_commit,
                                            contract_registry.load_kinds(stage.directory))
            self.assertEqual(contract_manifest.lookup(following, stage.tree)["stale_bindings"], [])

    @staticmethod
    def maintain_tool(directory=None):
        """passmap_maintain from `directory` (default ops/passmap_tools), loaded beside the sealed passmap.py it imports."""
        sealed_tools = max(pathlib.Path(__file__).resolve().parents[1].glob("work/authority_p*/hot/tools/passmap.py")).parent
        path = (directory or pathlib.Path(__file__).resolve().parent / "passmap_tools") / "passmap_maintain.py"
        sys.path.insert(0, str(sealed_tools))
        try:
            specification = importlib.util.spec_from_file_location(f"passmap_maintain_{abs(hash(path))}", path)
            module = importlib.util.module_from_spec(specification)
            specification.loader.exec_module(module)
            return module
        finally:
            del sys.path[0]

    def sealed_ruling(self, stage, maintain):
        ruling = stage.base / "RULING.md"
        ruling.write_text("Contract-Id: RULING_V1\nMID 336. The shop rule changes.\n")
        contract_registry.add(stage.directory, ruling, "RULING_V1", "ruling", "IN_FORCE", [], kind="ruling", amends=["SHOP_V1:2"])
        contract_registry.export(stage.directory, stage.inputs, contract_registry.sealed_document_names(stage.hot))
        record = lambda name: json.loads((stage.hot / "records" / name).read_text())
        maintain.apply_inputs(types.SimpleNamespace(hot=stage.hot, records=stage.hot / "records", record=record), stage.inputs, "I9")

    def test_a_ruling_reaches_its_amended_contract_after_the_seal_sync(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.sealed_ruling(stage, self.maintain_tool())
            following = stage.base / "next_REGISTRY"
            contract_registry.open_registry(following, 799, stage.hot, stage.base / "no_inputs", stage.base / "no_contracts", "I9-12",
                                            base_commit=stage.base_commit)
            reopened = contract_registry.load(following)["contracts"]["RULING_V1"]
            self.assertEqual((reopened["kind"], reopened["amends"]), ("ruling", ["SHOP_V1:2"]))
            manifest = contract_manifest.build_manifest(following, stage.tree, ["shop"], "after")
            self.assertIn("RULING_V1", [row["id"] for row in manifest["contracts"]])
            self.assertEqual(contract_registry.roundtrip(stage.directory, stage.hot), [])

    def test_the_seal_round_trip_reports_what_a_sync_dropped(self):
        sealed_798 = pathlib.Path(__file__).resolve().parents[1] / "work/authority_p798/hot/tools"
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.sealed_ruling(stage, self.maintain_tool(sealed_798))
            self.assertEqual(contract_registry.roundtrip(stage.directory, stage.hot),
                             ["ROUNDTRIP_CHANGED RULING_V1.kind: 'ruling' -> 'contract'",
                              "ROUNDTRIP_CHANGED RULING_V1.amends: ['SHOP_V1:2'] -> []",
                              "ROUNDTRIP_LOST scope: the sealed authority carries no records/contract_scope.json"])
            registry = contract_registry.load(stage.directory)
            registry["contracts"]["LOST_V1"] = dict(registry["contracts"]["RULING_V1"])
            contract_registry.write_json(stage.directory / "registry.json", registry)
            self.assertIn("ROUNDTRIP_LOST LOST_V1: the sealed registry does not hold it",
                          contract_registry.roundtrip(stage.directory, stage.hot))

    def test_the_scope_travels_through_the_seal_to_the_next_stage(self):
        """A-080: bindings, path bindings and kinds ride in the sealed authority, not in whichever registry folder is newest."""
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_registry.define_kind(stage.directory, "mode", ["shop", "march"], "every mode")
            contract_registry.bind(stage.directory, "SHOP_V1", ["kind:mode"], "bind every mode")
            self.sealed_ruling(stage, self.maintain_tool())
            self.assertEqual(contract_registry.roundtrip(stage.directory, stage.hot), [])
            following = stage.base / "next_REGISTRY"
            bindings, path_bindings, kinds, provenance = contract_registry.opening_scope(stage.hot, generation=798)
            self.assertEqual((provenance["source"], provenance["generation"]),
                             ("sealed", 798))
            contract_registry.open_registry(following, 799, stage.hot, stage.base / "no_inputs", stage.base / "no_contracts", "I9-12",
                                            bindings, path_bindings, stage.base_commit, kinds, scope_provenance=provenance)
            self.assertIn("march", contract_manifest.lookup(following, stage.tree)["placed"]["SHOP_V1"])
            self.assertEqual(contract_registry.roundtrip(stage.directory, stage.hot), [])

    def test_opening_without_a_sealed_scope_fails_closed(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_registry.bind(stage.directory, "SHOP_V1", ["march"], "march sells through the shop")
            with self.assertRaises(SystemExit):
                contract_registry.opening_scope(stage.hot, generation=798)
            bindings, _, _, provenance = contract_registry.opening_scope(stage.hot, stage.directory, 798)
            self.assertEqual(bindings["SHOP_V1"]["systems"], ["march"])
            self.assertEqual((provenance["source"], provenance["base_seal"], provenance["sha256"]),
                             ("predecessor", 798, contract_registry.digest(stage.directory / "registry.json")))

    def test_a_sealed_scope_cannot_be_overridden(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.sealed_ruling(stage, self.maintain_tool())
            with self.assertRaises(SystemExit):
                contract_registry.opening_scope(stage.hot, stage.directory, 798)

    def test_a_798_bootstrap_requires_a_predecessor_of_that_generation_with_every_map(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            with self.assertRaises(SystemExit):
                contract_registry.opening_scope(stage.hot, stage.base / "gone", 798)
            other = stage.base / "other_REGISTRY"
            contract_registry.open_registry(other, 797, stage.hot, stage.base / "no_inputs", stage.base / "no_contracts", "I9-10")
            with self.assertRaises(SystemExit):
                contract_registry.opening_scope(stage.hot, other, 798)
            wrong_phase = stage.base / "I10_REGISTRY"
            contract_registry.open_registry(wrong_phase, 798, stage.hot, stage.base / "no_inputs", stage.base / "no_contracts", "I10-1")
            with self.assertRaises(SystemExit, msg="another phase opened from the same seal is not the predecessor (A-087)"):
                contract_registry.opening_scope(stage.hot, wrong_phase, 798)
            (stage.hot / "records/frontier.json").unlink()
            with self.assertRaises(SystemExit, msg="no sealed frontier, no predecessor"):
                contract_registry.opening_scope(stage.hot, stage.directory, 798)
            (stage.hot / "records/frontier.json").write_text(json.dumps({"stage": "I9-11"}))
            (stage.directory / "kinds.json").unlink()
            with self.assertRaises(SystemExit):
                contract_registry.opening_scope(stage.hot, stage.directory, 798)

    def test_a_798_bootstrap_records_where_its_scope_came_from(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            contract_registry.bind(stage.directory, "SHOP_V1", ["march"], "march sells through the shop")
            bindings, path_bindings, kinds, provenance = contract_registry.opening_scope(stage.hot, stage.directory, 798)
            following = stage.base / "next_REGISTRY"
            contract_registry.open_registry(following, 798, stage.hot, stage.base / "no_inputs", stage.base / "no_contracts", "I9-11",
                                            bindings, path_bindings, stage.base_commit, kinds, scope_provenance=provenance)
            recorded = contract_registry.load(following)["scope_provenance"]
            self.assertEqual((recorded["source"], recorded["base_seal"], recorded["sha256"]),
                             ("predecessor", 798, contract_registry.digest(stage.directory / "registry.json")))

    def test_a_stage_opened_from_a_sealed_scope_may_add_bindings_but_not_lose_its_base(self):
        """Seal 801: the new seal carries the stage's grown scope; only the base seal's record is pinned."""
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            maintain = self.maintain_tool()
            self.sealed_ruling(stage, maintain)
            root = stage.base / "root"
            (root / "work/authority_p798").mkdir(parents=True)
            (root / "work/authority_p798/hot").symlink_to(stage.hot)
            following = stage.base / "next_REGISTRY"
            bindings, path_bindings, kinds, provenance = contract_registry.opening_scope(stage.hot, generation=798)
            contract_registry.open_registry(following, 798, stage.hot, stage.base / "no_inputs", stage.base / "no_contracts", "I9-12",
                                            bindings, path_bindings, stage.base_commit, kinds, scope_provenance=provenance)
            contract_registry.bind(following, "SHOP_V1", ["march"], "bound in the next stage")
            new_hot, new_inputs = stage.base / "hot_799", stage.base / "inputs_799"
            subprocess.run(["cp", "-a", str(stage.hot), str(new_hot)], check=True)
            new_inputs.mkdir()
            contract_registry.export(following, new_inputs, contract_registry.sealed_document_names(new_hot))
            record = lambda name: json.loads((new_hot / "records" / name).read_text())
            maintain.apply_inputs(types.SimpleNamespace(hot=new_hot, records=new_hot / "records", record=record), new_inputs, "I9")
            with patch.object(contract_registry, "ROOT", root):
                self.assertEqual(contract_registry.roundtrip(following, new_hot), [])
                (stage.hot / contract_registry.SCOPE_RECORD).write_text("{}")
                self.assertEqual(contract_registry.roundtrip(following, new_hot),
                                 ["ROUNDTRIP_CHANGED scope_provenance: the base seal's scope record changed since the registry opened"])

    def test_a_scope_changed_after_the_export_is_a_round_trip_failure(self):
        with tempfile.TemporaryDirectory() as temporary:
            stage = Stage(pathlib.Path(temporary))
            self.sealed_ruling(stage, self.maintain_tool())
            contract_registry.bind(stage.directory, "SHOP_V1", ["march"], "bound after the export")
            self.assertEqual(contract_registry.roundtrip(stage.directory, stage.hot),
                             ["ROUNDTRIP_CHANGED scope.bindings: SHOP_V1 differs"])

    def test_a_contract_superseded_by_one_that_sorts_before_it_survives_the_sync(self):
        sealed_798 = pathlib.Path(__file__).resolve().parents[1] / "work/authority_p798/hot/tools"
        for maintain, survives in ((self.maintain_tool(sealed_798), False), (self.maintain_tool(), True)):
            with tempfile.TemporaryDirectory() as temporary:
                stage = Stage(pathlib.Path(temporary))
                for identifier, supersedes in (("Z_OLD_V1", []), ("A_NEW_V1", ["Z_OLD_V1"])):
                    document = stage.base / f"{identifier}.md"
                    document.write_text(f"Contract-Id: {identifier}\nMID 336.\n")
                    contract_registry.add(stage.directory, document, identifier, identifier, "IN_FORCE", supersedes)
                contract_registry.export(stage.directory, stage.inputs, contract_registry.sealed_document_names(stage.hot))
                record = lambda name: json.loads((stage.hot / "records" / name).read_text())
                authority = types.SimpleNamespace(hot=stage.hot, records=stage.hot / "records", record=record)
                if not survives:
                    self.assertRaises(KeyError, maintain.apply_inputs, authority, stage.inputs, "I9")
                    continue
                maintain.apply_inputs(authority, stage.inputs, "I9")
                self.assertEqual(contract_registry.roundtrip(stage.directory, stage.hot), [])

    def test_a_new_authority_takes_the_ops_tool_versions(self):
        script = (pathlib.Path(__file__).resolve().parent / "seal_passmap.sh").read_text()
        overlay = script.index('ops/passmap_tools/*.py; do cp "$tool" "$tools/"; done')
        self.assertLess(script.index("tools=$authority/hot/tools"), overlay)
        self.assertLess(overlay, script.index('"$tools/passmap_maintain.py" sync'))
        roundtrip = script.index("contract_manifest.py\" seal-roundtrip \"$authority/hot\"")
        self.assertLess(script.index('"$tools/passmap_maintain.py" check'), roundtrip)
        self.assertLess(roundtrip, script.index('"$tools/passmap_maintain.py" package'))

if __name__ == "__main__":
    unittest.main()
