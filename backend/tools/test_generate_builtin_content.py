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


if __name__ == "__main__":
    unittest.main(verbosity=2)
