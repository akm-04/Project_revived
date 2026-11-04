#!/usr/bin/env python3
from __future__ import annotations

import base64
import hashlib
import json
import os
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import generate_builtin_content as gen  # noqa: E402


class ParserTests(unittest.TestCase):
    def test_generated_lua_table_fixture(self) -> None:
        data = b'''return { keys = {"id", "name"}, rows = { {"2", "b"}, {"1", "a\\nq"} } }'''
        self.assertEqual(
            gen.parse_generated_lua_table(data),
            [{"id": "2", "name": "b"}, {"id": "1", "name": "a\nq"}],
        )

    def test_generated_lua_table_rejects_expression(self) -> None:
        data = b'''return { keys = {"id"}, rows = { {tostring(1)} } }'''
        with self.assertRaises(gen.CompileError):
            gen.parse_generated_lua_table(data)

    def test_encoded_item_fixture(self) -> None:
        payload = "desc\tid\ttype\tstack\tstack_exceed_mail\tpartner_id\nid\ttype\tstack\tstack_exceed_mail\tpartner_id\n1\t3\t99\t1\t123\n"
        encoded = base64.b64encode(payload.encode()).decode()
        rows = gen.parse_encoded_item_table(f'return "{encoded}"'.encode())
        self.assertEqual(rows[0]["id"], "1")
        self.assertEqual(rows[0]["partner_id"], "123")

    def test_source_archive_hash_mismatch_fails(self) -> None:
        with tempfile.NamedTemporaryFile() as f:
            f.write(b"not the source archive")
            f.flush()
            with self.assertRaises(gen.CompileError):
                gen.SourceArchive(Path(f.name))

    def test_member_hash_mismatch_fails_even_when_outer_hash_matches_test_archive(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "src.zip"
            with zipfile.ZipFile(p, "w", compression=zipfile.ZIP_STORED) as zf:
                zf.writestr(gen.SOURCE_PREFIX + gen.SOURCE_MANIFEST[0][0], b"tampered")
            outer = hashlib.sha256(p.read_bytes()).hexdigest()
            with mock.patch.object(gen, "EXPECTED_SOURCE_ARCHIVE_SHA256", outer):
                archive = gen.SourceArchive(p)
                with self.assertRaises(gen.CompileError) as ctx:
                    archive.read_verified()
            self.assertIn("source SHA-256 mismatch", str(ctx.exception))


class ExactArchiveTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("GXB_R4A_SOURCE_ARCHIVE"), "exact source archive not supplied")
    def test_exact_archive_is_deterministic_and_matches_checked_in(self) -> None:
        archive = Path(os.environ["GXB_R4A_SOURCE_ARCHIVE"])
        a = gen.compile_archive(archive)
        b = gen.compile_archive(archive)
        self.assertEqual(
            {k: gen.canonical_json_bytes(v) for k, v in a.items()},
            {k: gen.canonical_json_bytes(v) for k, v in b.items()},
        )
        output = Path(__file__).resolve().parents[1] / "internal/content/builtin/generated"
        for name, value in a.items():
            self.assertEqual(output.joinpath(name).read_bytes(), gen.canonical_json_bytes(value), name)

    @unittest.skipUnless(os.environ.get("GXB_R4A_SOURCE_ARCHIVE"), "exact source archive not supplied")
    def test_library_template_card_metadata_is_parsed_from_source(self) -> None:
        a = gen.compile_archive(Path(os.environ["GXB_R4A_SOURCE_ARCHIVE"]))
        templates = {row["table_id"]: row for row in a["library_input_catalog.json"]["templates"]}
        self.assertEqual(len(templates), 568)
        self.assertEqual(
            (templates[10001001]["model_id"], templates[10001001]["awaken"], templates[10001001]["awaken_table_id"]),
            (10001001, 1, 11001001),
        )
        self.assertEqual(
            (templates[11001001]["model_id"], templates[11001001]["awaken"], templates[11001001]["awaken_table_id"]),
            (11001001, 1, 0),
        )
        self.assertEqual(
            (templates[10001042]["model_id"], templates[10001042]["awaken"], templates[10001042]["awaken_table_id"]),
            (10001042, 0, 11001042),
        )
        for table_id in range(11001, 11015):
            row = templates[table_id]
            self.assertEqual((row["model_id"], row["awaken"], row["awaken_table_id"]), (table_id, 0, 0))
        for row in templates.values():
            self.assertGreater(row["model_id"], 0)
            self.assertIn(row["awaken"], (0, 1))
            self.assertGreaterEqual(row["awaken_table_id"], 0)

    @unittest.skipUnless(os.environ.get("GXB_R4A_SOURCE_ARCHIVE"), "exact source archive not supplied")
    def test_library_dialog_graph_is_parsed_from_source(self) -> None:
        a = gen.compile_archive(Path(os.environ["GXB_R4A_SOURCE_ARCHIVE"]))
        catalog = a["library_input_catalog.json"]
        nodes = {(row["relationship_source_id"], row["dialog_group"], row["node_id"]): row for row in catalog["dialog_nodes"]}
        self.assertEqual(len(nodes), 13281)
        self.assertEqual(catalog["dialog_source_unknowns"], [11001209])
        self.assertFalse(any(group == 0 or node == 0 for _, group, node in nodes))

        branch = nodes[(10001006, 2, 201004)]
        self.assertEqual(branch["turn_ids"], [202001, 203001])
        self.assertEqual(nodes[(10001006, 2, 202001)]["is_reward"], 3)
        self.assertEqual(nodes[(10001006, 2, 203001)]["is_reward"], 2)

        self.assertEqual(nodes[(10001006, 4, 403001)]["is_reward"], 0)
        terminal = nodes[(10001001, 12, 1201001)]
        self.assertEqual((terminal["is_reward"], terminal["turn_ids"]), (5, [-1]))
        self.assertEqual(nodes[(10001100, 2, 203003)]["turn_ids"], [203005])
        self.assertNotIn("is_reward", nodes[(10001044, 7, 701005)])
        self.assertEqual(sum(1 for row in nodes.values() if len(row["turn_ids"]) > 1), 403)


if __name__ == "__main__":
    unittest.main(verbosity=2)
