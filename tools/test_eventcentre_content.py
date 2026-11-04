import hashlib
import json
import os
import unittest
from pathlib import Path

import generate_builtin_content as compiler
from eventcentre_content import build_administrator, build_workshop

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


class WorkshopContentCompilerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = os.environ.get("GXB_R4A_SOURCE_ARCHIVE")
        if not archive:
            raise unittest.SkipTest("exact source archive not supplied")
        cls.blobs = compiler.SourceArchive(Path(archive)).read_verified()
        cls.items = compiler.parse_encoded_item_table(cls.blobs["data/tables/item.lua"].data)
        cls.pet_keys, cls.pet_rows = compiler.parse_base64_indexed_lua_table(
            cls.blobs["data/tables/pet.lua"].data
        )

    def build(self, parse_table=compiler.parse_generated_lua_table,
              parse_indexed=compiler.parse_base64_indexed_lua_table,
              parse_items=compiler.parse_encoded_item_table):
        return build_workshop(self.blobs, parse_table, parse_indexed, parse_items, compiler.CompileError)

    def build_with_table(self, path, rows):
        original = self.blobs[path].data

        def parse_table(data):
            return rows if data == original else compiler.parse_generated_lua_table(data)

        return self.build(parse_table=parse_table)

    def build_with_pet_rows(self, rows):
        original = self.blobs["data/tables/pet.lua"].data
        pet_keys = self.pet_keys

        def parse_indexed(data):
            return (pet_keys, rows) if data == original else compiler.parse_base64_indexed_lua_table(data)

        return self.build(parse_indexed=parse_indexed)

    def build_with_items(self, items):
        original = self.blobs["data/tables/item.lua"].data

        def parse_items(data):
            return items if data == original else compiler.parse_encoded_item_table(data)

        return self.build(parse_items=parse_items)

    def source_rows(self, path):
        return compiler.parse_generated_lua_table(self.blobs[path].data)

    def test_source_counts_and_level_identities(self):
        catalog = self.build()
        self.assertEqual(catalog["schema_version"], 1)
        self.assertEqual([rule["level"] for rule in catalog["desk"]], list(range(1, 9)))
        self.assertEqual([rule["level"] for rule in catalog["recycle"]], list(range(1, 7)))
        self.assertEqual([rule["level"] for rule in catalog["board"]], list(range(1, 6)))
        self.assertEqual(len(catalog["missions"]), 273)
        self.assertEqual(len(catalog["hero_profiles"]), 91)
        self.assertEqual(len(catalog["awards"]), 29)
        self.assertEqual(len(catalog["item_recipes"]), 268)

    def test_desk_per_level_craftable_ids_and_cut_maketime(self):
        desk = self.build()["desk"]
        self.assertEqual([len(rule["craftable_item_ids"]) for rule in desk], [10, 9, 9, 8, 9, 5, 9, 8])
        self.assertEqual([rule["cut_maketime"] for rule in desk], [0, 3600, 7200, 10800, 14400, 18000, 21600, 25200])
        self.assertEqual(desk[0]["craftable_item_ids"][0], 20001102)
        self.assertEqual(desk[7]["craftable_item_ids"], [20001296, 20001297, 20001298, 20001299, 20001300, 20001302, 20001304, 20001305])
        all_ids = [identifier for rule in desk for identifier in rule["craftable_item_ids"]]
        self.assertEqual(len(all_ids), len(set(all_ids)))

    def test_recycle_literal_fields_preserve_decimal_strings(self):
        recycle = {(rule["level"]): rule for rule in self.build()["recycle"]}
        self.assertEqual([len(rule["recount_item_ids"]) for rule in recycle.values()], [45, 47, 45, 44, 45, 15])
        self.assertEqual(recycle[1]["energy_limit"], 0)
        self.assertEqual(recycle[1]["cut_cost_energy"], "0")
        self.assertEqual(recycle[1]["crit_up"], "0")
        self.assertEqual(recycle[3]["energy_limit"], 1000)
        self.assertEqual(recycle[3]["cut_cost_energy"], "0.04")
        self.assertEqual(recycle[3]["crit_up"], "0.1")
        self.assertEqual(recycle[5]["crit_up"], "0.2")
        self.assertEqual(recycle[6]["energy_limit"], 2000)
        self.assertEqual(recycle[6]["cut_cost_energy"], "0.08")
        self.assertEqual(len(recycle[6]["recount_item_ids"]), 15)

    def test_notice_board_task_limit_and_gold_task(self):
        board = self.build()["board"]
        self.assertEqual([rule["task_limit"] for rule in board], [6, 7, 8, 9, 11])
        self.assertEqual([rule["gold_task"] for rule in board], [0, 0, 0, 0, 2])

    def test_missions_keep_hero_identity_enemy_display_and_fight_id(self):
        catalog = self.build()
        missions = {rule["id"]: rule for rule in catalog["missions"]}
        self.assertEqual(missions[10001], {
            "id": 10001,
            "hero_name": "Aquaris",
            "hero_id": 10001001,
            "name": "Come Forward",
            "enemy_ids": [80000080, 80000086, 80000074, 80000082, 80000097],
            "monster_stars": [2, 2, 2, 2, 2],
            "monster_qualities": [9, 9, 9, 9, 9],
            "monster_levels": [90, 90, 90, 90, 90],
            "fight_id": 9600101,
            "fighting": 2000,
            "duration": 21600,
            "deposit": 50000,
        })
        self.assertEqual(len({rule["fight_id"] for rule in missions.values()}), 273)
        self.assertEqual(missions[10923]["hero_name"], "Sisha ")
        self.assertEqual(missions[10923]["fight_id"], 9600379)

    def test_hero_profiles_keep_three_missions_and_thresholds_without_name_normalization(self):
        catalog = self.build()
        profiles = {rule["hero_id"]: rule for rule in catalog["hero_profiles"]}
        self.assertEqual(profiles[10001001]["mission_ids"], [10001, 10002, 10003])
        self.assertEqual(profiles[10001001]["force_thresholds"], [1500, 4000, 8000])
        self.assertEqual(profiles[10001001]["partner_name"], "Aquaris")
        self.assertEqual(profiles[10001006]["partner_name"], "Iron Fist")
        missions = {rule["id"]: rule for rule in catalog["missions"]}
        self.assertEqual(missions[10051]["hero_name"], "Ironfist")
        covered = [identifier for rule in profiles.values() for identifier in rule["mission_ids"]]
        self.assertEqual(sorted(covered), sorted(missions))

    def test_awards_keep_item_and_material_rewards_and_reject_mission_mapping(self):
        catalog = self.build()
        awards = {rule["id"]: rule for rule in catalog["awards"]}
        self.assertEqual(awards[10001], {
            "id": 10001,
            "grade": 1,
            "item_id": 60001020,
            "item_count": 1,
            "material_ids": [11, 12],
            "material_amounts": [3250, 3200],
            "gold": 500000,
        })
        self.assertEqual(awards[10006]["material_ids"], [])
        self.assertEqual(awards[10007]["item_id"], 0)
        self.assertEqual(awards[10007]["item_count"], 0)
        self.assertEqual(awards[10007]["material_ids"], [11, 12])
        self.assertEqual(awards[10007]["material_amounts"], [10540, 11045])
        grades = {}
        for rule in awards.values():
            grades[rule["grade"]] = grades.get(rule["grade"], 0) + 1
        self.assertEqual(grades, {1: 10, 2: 10, 3: 9})
        self.assertEqual(sorted(set(awards) & {rule["id"] for rule in catalog["missions"]}), [10001, 10002, 10003])
        self.assertNotIn("award_id", catalog["missions"][0])
        self.assertNotIn("mission_id", awards[10001])

    def test_item_recipes_include_desk_recycle_and_pet_selection_items(self):
        catalog = self.build()
        recipes = {rule["item_id"]: rule for rule in catalog["item_recipes"]}
        self.assertEqual(recipes[20001222], {
            "item_id": 20001222,
            "make_resource_ids": [11, 12, 13],
            "make_quantities": [14000, 13000, 190],
            "make_time": 468000,
            "resolve_resource_ids": [11, 12, 13],
            "resolve_quantities": [11246, 11456, 66],
            "resolve_energy": 1837,
        })
        self.assertEqual(recipes[20001001]["make_resource_ids"], [])
        self.assertEqual(recipes[20001001]["make_time"], 0)
        self.assertEqual(recipes[20001001]["resolve_resource_ids"], [11, 12])
        self.assertEqual(recipes[20001001]["resolve_quantities"], [5, 13])
        self.assertEqual(recipes[80001009]["make_resource_ids"], [50001094, 50001086])
        self.assertEqual(recipes[80001009]["make_quantities"], [2, 14])
        self.assertEqual(recipes[80001009]["resolve_resource_ids"], [])
        pet_item_ids = {
            identifier
            for row_id in self.pet_rows
            for level_items in compiler.indexed_field(self.pet_keys, self.pet_rows[row_id], "table_item_id", row_id=row_id).split("@")
            for identifier in (int(part) for part in level_items.split("|") if part)
        }
        self.assertTrue(pet_item_ids.issubset(recipes))
        desk_item_ids = {identifier for rule in catalog["desk"] for identifier in rule["craftable_item_ids"]}
        recycle_item_ids = {identifier for rule in catalog["recycle"] for identifier in rule["recount_item_ids"]}
        self.assertTrue(desk_item_ids.issubset(recipes))
        self.assertTrue(recycle_item_ids.issubset(recipes))

    def test_misc_uses_exact_source_keys(self):
        misc = self.build()["misc"]
        self.assertEqual(misc, {
            "event_centre_saturation_init": 10000,
            "event_centre_saturation_time": 15,
            "event_centre_accelerate_item": 50005024,
            "event_centre_accelerate_time": 300,
            "event_centre_pet_cost_item": [50001086, 50001094],
            "event_centre_pet_color_accelerate_time": 1800,
        })

    def test_compilation_is_deterministic_and_writes_scratch_payload(self):
        first = compiler.canonical_json_bytes(self.build())
        second = compiler.canonical_json_bytes(self.build())
        self.assertEqual(first, second)
        destination = os.environ.get("GXB_I9_10A_SCRATCH_JSON")
        if destination:
            path = Path(destination)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(first)
            Path(destination + ".sha256").write_text(hashlib.sha256(first).hexdigest() + "\n")
        catalog = json.loads(first)
        self.assertEqual(len(catalog["missions"]), 273)

    def test_rejects_malformed_workshop_sources(self):
        desk = self.source_rows("data/tables/event_centre_table.lua")
        recycle = self.source_rows("data/tables/event_centre_recycle.lua")
        board = self.source_rows("data/tables/event_centre_notice_board.lua")
        missions = self.source_rows("data/tables/event_centre_mission.lua")
        heroes = self.source_rows("data/tables/event_centre_hero.lua")
        awards = self.source_rows("data/tables/event_centre_mission_award.lua")

        def mutate(rows, index, field, value):
            changed = [dict(row) for row in rows]
            changed[index][field] = value
            return changed

        tests = [
            ("duplicate desk level", self.build_with_table, "data/tables/event_centre_table.lua", mutate(desk, 1, "id", "1")),
            ("unknown desk item", self.build_with_table, "data/tables/event_centre_table.lua", mutate(desk, 0, "item_id", "99999999")),
            ("repeated desk item", self.build_with_table, "data/tables/event_centre_table.lua", mutate(desk, 1, "item_id", desk[0]["item_id"])),
            ("unknown recycle item", self.build_with_table, "data/tables/event_centre_recycle.lua", mutate(recycle, 0, "recount_item", "99999999")),
            ("nonfinite recycle coefficient", self.build_with_table, "data/tables/event_centre_recycle.lua", mutate(recycle, 1, "cut_cost_energy", "NaN")),
            ("negative recycle coefficient", self.build_with_table, "data/tables/event_centre_recycle.lua", mutate(recycle, 1, "crit_up", "-0.04")),
            ("negative item quantity", self.build_with_table, "data/tables/event_centre_recycle.lua", mutate(recycle, 0, "energy_limit", "-1")),
            ("empty board task limit", self.build_with_table, "data/tables/event_centre_notice_board.lua", mutate(board, 0, "task_limit", "0")),
            ("duplicate mission id", self.build_with_table, "data/tables/event_centre_mission.lua", mutate(missions, 1, "id", missions[0]["id"])),
            ("unaligned enemy display", self.build_with_table, "data/tables/event_centre_mission.lua", mutate(missions, 0, "monster_star", "2|2")),
            ("unknown mission hero", self.build_with_table, "data/tables/event_centre_mission.lua", mutate(missions, 0, "hero_id", "10001002")),
            ("negative mission duration", self.build_with_table, "data/tables/event_centre_mission.lua", mutate(missions, 0, "time", "-1")),
            ("duplicate hero profile", self.build_with_table, "data/tables/event_centre_hero.lua", mutate(heroes, 1, "hero_id", heroes[0]["hero_id"])),
            ("hero profile short missions", self.build_with_table, "data/tables/event_centre_hero.lua", mutate(heroes, 0, "mission_id", "10001|10002")),
            ("unknown award grade", self.build_with_table, "data/tables/event_centre_mission_award.lua", mutate(awards, 0, "grade", "4")),
            ("unaligned award material vector", self.build_with_table, "data/tables/event_centre_mission_award.lua", mutate(awards, 6, "reward_resource", "10540")),
            ("zero mixed into award material vector", self.build_with_table, "data/tables/event_centre_mission_award.lua", mutate(awards, 0, "reward_id", "0|11")),
            ("duplicate award id", self.build_with_table, "data/tables/event_centre_mission_award.lua", mutate(awards, 1, "id", awards[0]["id"])),
        ]
        for name, build, path, rows in tests:
            with self.subTest(name=name):
                with self.assertRaises(compiler.CompileError):
                    build(path, rows)

        malformed_items = [dict(row) for row in self.items]
        recipe_index = next(index for index, row in enumerate(malformed_items) if row["id"] == "20001222")
        malformed_items[recipe_index]["make_res_num"] = "14000|13000"
        with self.subTest(name="unaligned item recipe"):
            with self.assertRaises(compiler.CompileError):
                self.build_with_items(malformed_items)

        malformed_pet_rows = {row_id: list(values) for row_id, values in self.pet_rows.items()}
        first_pet = sorted(malformed_pet_rows)[0]
        item_index = self.pet_keys["table_item_id"] - 1
        malformed_pet_rows[first_pet][item_index] = "99999999"
        with self.subTest(name="unknown pet selection item"):
            with self.assertRaises(compiler.CompileError):
                self.build_with_pet_rows(malformed_pet_rows)


if __name__ == "__main__":
    unittest.main(verbosity=2)
