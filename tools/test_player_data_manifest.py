"""Unit checks for the R8 player data manifest (no database)."""
import copy
import json
import unittest

import player_data_manifest as manifest_tool


def fake_catalog():
    return manifest_tool.Catalog(
        tables=["players", "player_a", "player_b", "player_via", "shared"],
        columns={
            "players": ["player_id", "name"],
            "player_a": ["player_id", "state"],
            "player_b": ["player_id", "parent_id", "payload"],
            "player_via": ["player_id", "state"],
            "shared": ["player_low_id", "player_high_id", "state"],
        },
        foreign_keys={
            "player_a": [("player_id", "players")],
            "player_b": [("player_id", "players"), ("parent_id", "player_a")],
            "shared": [("player_low_id", "players"), ("player_high_id", "players")],
        },
        primary_keys={"players": ["player_id"], "player_a": ["player_id"],
                      "player_b": ["player_id"], "player_via": ["player_id"],
                      "shared": ["player_low_id", "player_high_id"]},
        json_columns={"player_b": ["payload"]},
    )


def fake_classes():
    return {
        "players": {"scope": "player", "owner": ["player_id"], "via": None, "kind": "state",
                    "backup": True, "references": [], "retention": None},
        "player_a": {"scope": "player", "owner": ["player_id"], "via": None, "kind": "state",
                     "backup": True, "references": [], "retention": None},
        "player_b": {"scope": "player", "owner": ["player_id"], "via": None, "kind": "state",
                     "backup": True, "references": [], "retention": None},
        "player_via": {"scope": "player", "owner": ["player_id"], "via": "player_a", "kind": "state",
                       "backup": True, "references": [], "retention": None},
        "shared": {"scope": "player", "owner": [], "via": None, "kind": "shared", "backup": False,
                   "references": ["player_low_id", "player_high_id"], "retention": None},
    }


class PlayerDataManifestTests(unittest.TestCase):
    def test_classified_catalog_passes(self):
        catalog = fake_catalog()
        classes = fake_classes()
        self.assertEqual(manifest_tool.check(catalog, classes, manifest_tool.build_manifest(catalog, classes)), [])

    def test_unclassified_table_fails_as_probe(self):
        catalog = fake_catalog()
        classes = fake_classes()
        del classes["player_a"]
        problems = manifest_tool.check(catalog, classes, manifest_tool.build_manifest(catalog, classes))
        self.assertTrue(any("player_a: catalog table has no data class" in problem for problem in problems))
        self.assertEqual(len(problems), 1)

    def test_class_for_missing_table_fails(self):
        catalog = fake_catalog()
        classes = fake_classes()
        classes["ghost"] = dict(classes["player_a"])
        problems = manifest_tool.check(catalog, classes, manifest_tool.build_manifest(catalog, classes))
        self.assertTrue(any("ghost: data class for a table missing from the catalog" in problem for problem in problems))

    def test_uncovered_player_column_fails(self):
        catalog = fake_catalog()
        classes = fake_classes()
        classes["player_a"]["owner"] = []
        problems = manifest_tool.check(catalog, classes, manifest_tool.build_manifest(catalog, classes))
        self.assertTrue(any("player_a.player_id: player column is in neither owner nor references" in problem
                            for problem in problems))

    def test_player_reference_without_a_key_fails(self):
        classes = {table: entry["data"] for table, entry in
                   json.loads(manifest_tool.CONTRACT_PATH.read_text())["tables"].items()
                   if table in ("players", "guild_campaign_copies")}
        catalog = manifest_tool.Catalog(
            ["players", "guild_campaign_copies"],
            {"players": ["player_id"], "guild_campaign_copies": ["guild_id", "holder_id", "settled_by"]},
            {"guild_campaign_copies": [("holder_id", "players")]}, {}, {})
        problems = manifest_tool.check(catalog, classes, manifest_tool.build_manifest(catalog, classes))
        self.assertTrue(any("settled_by" in problem for problem in problems))

    def test_child_before_parent_fails(self):
        catalog = fake_catalog()
        classes = fake_classes()
        manifest = manifest_tool.build_manifest(catalog, classes)
        entries = {entry["table"]: entry for entry in manifest["tables"]}
        entries["player_b"]["restore_order"] = entries["player_a"]["restore_order"]
        problems = manifest_tool.check(catalog, classes, manifest)
        self.assertTrue(any("player_b: restore order puts child before parent player_a" in problem
                            for problem in problems))

    def test_manifest_difference_fails(self):
        catalog = fake_catalog()
        classes = fake_classes()
        manifest = manifest_tool.build_manifest(catalog, classes)
        changed = copy.deepcopy(manifest)
        changed["tables"][0]["owner"] = []
        problems = manifest_tool.check(catalog, classes, changed)
        self.assertTrue(any("differs from the generated manifest" in problem for problem in problems))

    def test_via_table_comes_before_its_row(self):
        catalog = fake_catalog()
        position = manifest_tool.restore_positions(catalog, fake_classes())
        self.assertLess(position["player_a"], position["player_via"])

    def test_manifest_contains_player_rows_only(self):
        catalog = fake_catalog()
        classes = fake_classes()
        classes["players"]["scope"] = "content"
        manifest = manifest_tool.build_manifest(catalog, classes)
        self.assertNotIn("players", [entry["table"] for entry in manifest["tables"]])
        self.assertEqual([entry["table"] for entry in manifest["tables"]
                          if entry["table"] == "player_b"][0], "player_b")
        player_b = next(entry for entry in manifest["tables"] if entry["table"] == "player_b")
        self.assertEqual(player_b["payload_columns"], ["payload"])

    def test_owner_where_needs_an_owner_and_reaches_the_manifest(self):
        catalog = fake_catalog()
        classes = fake_classes()
        classes["shared"]["owner_where"] = "kind = 'player'"
        problems = manifest_tool.check(catalog, classes, manifest_tool.build_manifest(catalog, classes))
        self.assertIn("shared: owner_where without an owner column", problems)
        classes["player_a"]["owner_where"] = "kind = 'player'"
        player_a = next(entry for entry in manifest_tool.build_manifest(catalog, classes)["tables"]
                        if entry["table"] == "player_a")
        self.assertEqual(player_a["owner_where"], "kind = 'player'")


if __name__ == "__main__":
    unittest.main()
