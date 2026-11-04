import json
import os
from pathlib import Path
import unittest

import generate_builtin_content as gen
from dorm_content import build_glue


class DormGlueCompilerTests(unittest.TestCase):
    def test_named_columns_not_row_positions(self):
        misc = {"glue_time_get": "100", "glue_buy_number": "50", "glue_buy_limit": "300"}
        vip_rows = [
            {"num_glue": "2", "id": "1", "charge_req": "0"},
            {"charge_req": "0", "num_glue": "1", "id": "0"},
        ]
        refresh_rows = [
            {"buy_glue_cost": "100", "id": "2"},
            {"id": "1", "other_cost": "7", "buy_glue_cost": "50"},
        ]
        self.assertEqual(
            build_glue(misc, vip_rows, refresh_rows, gen.CompileError),
            {
                "daily_floor": 100,
                "purchase_amount": 50,
                "purchase_start_limit": 300,
                "vip_daily_caps": [{"vip": 0, "cap": 1}, {"vip": 1, "cap": 2}],
                "purchase_costs": [{"ordinal": 1, "cost": 50}, {"ordinal": 2, "cost": 100}],
            },
        )


class DormGlueExactSourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get("GXB_R4A_SOURCE_ARCHIVE")
        if not archive:
            raise unittest.SkipTest("exact source archive not supplied")
        cls.artifact = gen.compile_archive(Path(archive))["dorm_input_catalog.json"]

    def test_schema_v2_glue_from_exact_pinned_source(self):
        catalog = self.artifact
        self.assertEqual(catalog["schema_version"], 2)
        self.assertEqual(
            catalog["glue"],
            {
                "daily_floor": 100,
                "purchase_amount": 50,
                "purchase_start_limit": 300,
                "vip_daily_caps": [{"vip": vip, "cap": vip + 1} for vip in range(16)],
                "purchase_costs": [
                    {"ordinal": 1, "cost": 50},
                    {"ordinal": 2, "cost": 50},
                    {"ordinal": 3, "cost": 100},
                    {"ordinal": 4, "cost": 100},
                    {"ordinal": 5, "cost": 100},
                    {"ordinal": 6, "cost": 100},
                    {"ordinal": 7, "cost": 200},
                    {"ordinal": 8, "cost": 200},
                    {"ordinal": 9, "cost": 200},
                    {"ordinal": 10, "cost": 200},
                    {"ordinal": 11, "cost": 400},
                ] + [{"ordinal": ordinal, "cost": 400} for ordinal in range(12, 331)],
            },
        )

    def test_existing_selected_source_facts_unchanged(self):
        catalog = self.artifact
        self.assertEqual(len(catalog["rooms"]), 16)
        self.assertEqual(len(catalog["types"]), 4)
        self.assertEqual(len(catalog["keys"]), 18)
        self.assertEqual(len(catalog["expansions"]), 3)
        self.assertEqual(len(catalog["furniture"]), 267)
        self.assertEqual(len(catalog["hero_equipment"]), 568)
        self.assertEqual(catalog["lounge_policy_id"], "C2C_LOUNGE_EXP_V1")
        self.assertEqual(catalog["random_key_policy_id"], "C2C_RANDOM_KEY_V1")
        self.assertFalse(catalog["original_server_policy_recovered"])

    def test_every_retained_source_fact_matches_accepted_artifact(self):
        accepted = json.loads(
            (Path(__file__).resolve().parents[1] / "internal/content/builtin/generated/dorm_input_catalog.json").read_text()
        )
        for name, value in accepted.items():
            if name in ("schema_version", "glue"):
                continue
            self.assertEqual(self.artifact[name], value, name)


if __name__ == "__main__":
    unittest.main(verbosity=2)
