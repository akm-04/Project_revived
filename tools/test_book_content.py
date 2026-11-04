import json
import os
import unittest
from pathlib import Path

import generate_builtin_content as compiler
from book_content import build_book

GENERATED = Path(__file__).resolve().parents[1] / "internal/content/builtin/generated/book_input_catalog.json"


class BookContentCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get("GXB_R4A_SOURCE_ARCHIVE")
        if not archive:
            raise unittest.SkipTest("exact source archive not supplied")
        cls.blobs = compiler.SourceArchive(Path(archive)).read_verified()

    def build(self, parse=compiler.parse_generated_lua_table) -> dict:
        items = compiler.parse_encoded_item_table(self.blobs["data/tables/item.lua"].data)
        return build_book(self.blobs, parse, items)

    def test_schema2_emits_all_135_source_building_rows(self):
        catalog = self.build()
        self.assertEqual(catalog["schema_version"], 2)
        self.assertEqual(catalog["recipe_policy_id"], "C2D_FRAGMENT_RECIPES_V1")
        self.assertEqual(catalog["policy_id"], "C2D_V1_BUILDING_SEEDS_AND_JOB_REFUNDS_V1")
        counts = (len(catalog["buildings"]), len(catalog["books"]), len(catalog["skills"]), len(catalog["costs"]))
        self.assertEqual(counts, (135, 54, 399, 24))
        per_type = {}
        for row in catalog["buildings"]:
            per_type[row["Type"]] = per_type.get(row["Type"], 0) + 1
        self.assertEqual(per_type, {1: 6, 2: 8, 3: 6, 4: 100, 5: 5, 6: 5, 7: 5})
        self.assertEqual(sorted(row["Level"] for row in catalog["buildings"] if row["Type"] == 2), list(range(1, 9)))

    def test_existing_source_facts_unchanged(self):
        catalog = self.build()
        old = json.loads(GENERATED.read_text())
        for source_type in (1, 3, 4):
            expected = [row for row in old["buildings"] if row["Type"] == source_type]
            actual = [row for row in catalog["buildings"] if row["Type"] == source_type]
            self.assertEqual(actual, expected)
        self.assertEqual({key: catalog[key] for key in ("books", "skills", "costs")}, {key: old[key] for key in ("books", "skills", "costs")})

    def test_workbench_cut_maketime_is_not_cut_time(self):
        catalog = self.build()
        rows = {(row["Type"], row["Level"]): row for row in catalog["buildings"]}
        self.assertEqual(rows[(2, 2)]["CutTime"], 0)
        self.assertEqual(rows[(2, 8)]["Duration"], 0)
        self.assertEqual(rows[(2, 8)]["Resources"], {})
        self.assertEqual(rows[(2, 8)]["Attributes"], ["0", "0", "0"])
        self.assertEqual(rows[(7, 1)]["RequiresType"], 2)

    def test_duplicate_source_building_keys_rejected(self):
        source = self.blobs["data/tables/event_centre_table.lua"].data
        rows = compiler.parse_generated_lua_table(source)
        rows.append(dict(rows[0]))

        def parse(data):
            return rows if data == source else compiler.parse_generated_lua_table(data)

        with self.assertRaises(AssertionError):
            self.build(parse)

    def test_zero_quantity_does_not_waive_cost_shape(self):
        mutations = [
            ("table", 0, {"resources_num": "0"}),
            ("table", 7, {"resources_id": "99|12|13"}),
            ("table", 7, {"time": "60"}),
            ("skillcost", 0, {"cost_res_type1": "11|12|13", "cost_res_num1": "0"}),
        ]
        for table_name, row_index, changes in mutations:
            with self.subTest(table=table_name, row=row_index, changes=changes):
                source = self.blobs["data/tables/event_centre_" + table_name + ".lua"].data
                rows = compiler.parse_generated_lua_table(source)
                rows[row_index].update(changes)

                def parse(data):
                    return rows if data == source else compiler.parse_generated_lua_table(data)

                with self.assertRaises(AssertionError):
                    self.build(parse)


if __name__ == "__main__":
    unittest.main(verbosity=2)
