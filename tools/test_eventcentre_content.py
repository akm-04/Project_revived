import os
import unittest
from pathlib import Path

import generate_builtin_content as compiler
from eventcentre_content import build_administrator

SOURCE_COLUMNS = {"gold": 1, "diamond": 2, "dust": 11, "liquor": 12, "power": 13}
DESTINATIONS = (11, 12, 13)


class AdministratorContentCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get("GXB_R4A_SOURCE_ARCHIVE")
        if not archive:
            raise unittest.SkipTest("exact source archive not supplied")
        cls.blobs = compiler.SourceArchive(Path(archive)).read_verified()

    def build(self, parse=compiler.parse_generated_lua_table):
        return build_administrator(self.blobs, parse, compiler.CompileError)

    def build_with_rows(self, rows):
        source = self.blobs["data/tables/event_centre_conversion.lua"].data

        def parse(data):
            return rows if data == source else compiler.parse_generated_lua_table(data)

        return self.build(parse)

    def source_rows(self):
        return compiler.parse_generated_lua_table(
            self.blobs["data/tables/event_centre_conversion.lua"].data
        )

    def test_schema1_emits_all_180_rows_sorted_by_destination_then_ordinal(self):
        catalog = self.build()
        self.assertEqual(catalog["schema_version"], 1)
        rules = catalog["rules"]
        self.assertEqual(len(rules), 180)
        self.assertEqual([rule["destination"] for rule in rules], [destination for destination in DESTINATIONS for _ in range(60)])
        self.assertEqual([rule["ordinal"] for rule in rules], list(range(1, 61)) * 3)
        pairs = {(source_id, rule["destination"]) for rule in rules for source_id in map(int, rule["costs"])}
        self.assertEqual(len(pairs), 12)
        self.assertEqual(set(map(int, rules[0]["costs"])), {1, 2, 12, 13})

    def test_first_and_last_literal_prices_and_credit(self):
        rules = {(rule["destination"], rule["ordinal"]): rule for rule in self.build()["rules"]}
        self.assertEqual(rules[(11, 1)], {
            "destination": 11,
            "ordinal": 1,
            "credit": 50000,
            "costs": {"1": 600000, "2": 300, "12": 60000, "13": 240},
        })
        self.assertEqual(rules[(11, 60)], {
            "destination": 11,
            "ordinal": 60,
            "credit": 50000,
            "costs": {"1": 12000000, "2": 6000, "12": 1200000, "13": 4800},
        })
        self.assertEqual(rules[(12, 1)]["costs"], {"1": 600000, "2": 300, "11": 60000, "13": 240})
        self.assertEqual(rules[(12, 60)]["costs"], {"1": 12000000, "2": 6000, "11": 1200000, "13": 4800})
        self.assertEqual(rules[(13, 1)], {
            "destination": 13,
            "ordinal": 1,
            "credit": 100,
            "costs": {"1": 250000, "2": 60, "11": 25000, "12": 25000},
        })
        self.assertEqual(rules[(13, 60)], {
            "destination": 13,
            "ordinal": 60,
            "credit": 100,
            "costs": {"1": 5000000, "2": 1200, "11": 500000, "12": 500000},
        })

    def test_decimal_literal_is_normalized_exactly(self):
        rules = {(rule["destination"], rule["ordinal"]): rule for rule in self.build()["rules"]}
        self.assertEqual(rules[(13, 2)]["costs"]["11"], 27500)
        self.assertEqual(rules[(13, 2)]["costs"]["12"], 27500)

    def test_self_currency_column_is_excluded_and_cross_currency_zero_cost_rejected(self):
        rules = {(rule["destination"], rule["ordinal"]): rule for rule in self.build()["rules"]}
        for (destination, _), rule in rules.items():
            self.assertNotIn(str(destination), rule["costs"])
            self.assertTrue(all(amount > 0 for amount in rule["costs"].values()))
        self.assertEqual(rules[(11, 1)]["costs"]["12"], 60000)
        malformed = self.source_rows()
        malformed[0]["liquor"] = "0"
        with self.assertRaises(compiler.CompileError):
            self.build_with_rows(malformed)

    def test_rejects_duplicate_ids(self):
        rows = self.source_rows()
        rows[1]["id"] = rows[0]["id"]
        with self.assertRaises(compiler.CompileError):
            self.build_with_rows(rows)

    def test_rejects_missing_ids(self):
        with self.assertRaises(compiler.CompileError):
            self.build_with_rows(self.source_rows()[:-1])

    def test_rejects_unknown_destination(self):
        rows = self.source_rows()
        rows[0]["id"] = "1401"
        with self.assertRaises(compiler.CompileError):
            self.build_with_rows(rows)

    def test_rejects_ordinal_outside_range(self):
        for identifier in ("1100", "1161"):
            with self.subTest(identifier=identifier):
                rows = self.source_rows()
                rows[0]["id"] = identifier
                with self.assertRaises(compiler.CompileError):
                    self.build_with_rows(rows)

    def test_rejects_nonpositive_credit(self):
        for value in ("0", "-1"):
            with self.subTest(value=value):
                rows = self.source_rows()
                rows[0]["c_resource"] = value
                with self.assertRaises(compiler.CompileError):
                    self.build_with_rows(rows)

    def test_rejects_invalid_numeric_values(self):
        for field, value in (("c_resource", "abc"), ("gold", "12x"), ("diamond", "1.5"), ("dust", "")):
            with self.subTest(field=field, value=value):
                rows = self.source_rows()
                rows[0][field] = value
                with self.assertRaises(compiler.CompileError):
                    self.build_with_rows(rows)

    def test_rejects_negative_cost(self):
        rows = self.source_rows()
        rows[0]["gold"] = "-1"
        with self.assertRaises(compiler.CompileError):
            self.build_with_rows(rows)

    def test_rejects_malformed_row_shape(self):
        mutations = [
            lambda row: row.pop("gold"),
            lambda row: row.update({"extra": "1"}),
            lambda row: row.update({"id": "11a1"}),
        ]
        for mutate in mutations:
            with self.subTest(mutate=mutate):
                rows = self.source_rows()
                mutate(rows[0])
                with self.assertRaises(compiler.CompileError):
                    self.build_with_rows(rows)

    def test_rejects_nonzero_self_currency_column(self):
        rows = self.source_rows()
        rows[0]["dust"] = "1"
        with self.assertRaises(compiler.CompileError):
            self.build_with_rows(rows)


if __name__ == "__main__":
    unittest.main(verbosity=2)
