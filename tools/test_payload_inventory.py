"""Unit checks for the R8 payload column inventory merge and --check rules (no database)."""
import copy
import unittest

import payload_inventory as inventory_tool


def fake_columns():
    return [("arena_players", "defense"), ("arena_players", "record"), ("content_arena_catalogs", "payload")]


def fake_scopes():
    return {
        "arena_players": "player",
        "content_arena_catalogs": "content",
    }


def filled_entry(table, column, scope):
    return {
        "table": table,
        "column": column,
        "scope": scope,
        "decode": "struct",
        "decode_type": "arena.Lineup",
        "decode_sites": ["internal/adapters/postgres/arenastore/store.go:128"],
        "writers": ["internal/adapters/postgres/arenastore/store.go:144"],
        "sql_paths": [],
        "digest": False,
        "digest_sites": [],
        "batch": 6,
    }


class PayloadInventoryTests(unittest.TestCase):
    def test_merge_keeps_hand_filled_fields(self):
        inventory = {"columns": [filled_entry("arena_players", "defense", "player")]}
        merged = inventory_tool.merge(fake_columns(), fake_scopes(), inventory)
        entries = {(entry["table"], entry["column"]): entry for entry in merged["columns"]}
        self.assertEqual(entries[("arena_players", "defense")]["decode_type"], "arena.Lineup")
        self.assertEqual(entries[("arena_players", "defense")]["batch"], 6)
        self.assertTrue(entries[("arena_players", "defense")]["digest_sites"] == [])

    def test_new_column_is_added_unknown(self):
        merged = inventory_tool.merge(fake_columns(), fake_scopes(), {"columns": []})
        entries = {(entry["table"], entry["column"]): entry for entry in merged["columns"]}
        new = entries[("arena_players", "record")]
        self.assertEqual(new["decode"], inventory_tool.UNSET)
        self.assertEqual(new["digest"], inventory_tool.UNSET)
        self.assertEqual(new["batch"], inventory_tool.UNSET)
        self.assertEqual(new["scope"], "player")

    def test_vanished_column_is_dropped(self):
        inventory = {"columns": [filled_entry("arena_players", "gone", "player")]}
        merged = inventory_tool.merge(fake_columns(), fake_scopes(), inventory)
        names = {(entry["table"], entry["column"]) for entry in merged["columns"]}
        self.assertNotIn(("arena_players", "gone"), names)
        self.assertEqual(len(merged["columns"]), len(fake_columns()))

    def test_complete_inventory_passes_check(self):
        merged = inventory_tool.merge(fake_columns(), fake_scopes(), {"columns": []})
        entries = {(entry["table"], entry["column"]): entry for entry in merged["columns"]}
        for table, column in fake_columns():
            entries[(table, column)]["decode"] = "none"
            entries[(table, column)]["digest"] = False
            entries[(table, column)]["batch"] = 1
        self.assertEqual(inventory_tool.check(fake_columns(), merged), [])

    def test_catalog_column_missing_from_inventory_fails(self):
        inventory = {"columns": [filled_entry("arena_players", "defense", "player")]}
        problems = inventory_tool.check(fake_columns(), inventory)
        self.assertTrue(any("arena_players.record: catalog column missing from the inventory" in problem
                            for problem in problems))

    def test_inventory_column_missing_from_catalog_fails(self):
        merged = inventory_tool.merge(fake_columns(), fake_scopes(), {"columns": []})
        merged["columns"].append(filled_entry("ghost", "payload", "server"))
        problems = inventory_tool.check(fake_columns(), merged)
        self.assertTrue(any("ghost.payload: inventory column missing from the catalog" in problem
                            for problem in problems))

    def test_unknown_entry_fails_check(self):
        merged = inventory_tool.merge(fake_columns(), fake_scopes(), {"columns": []})
        problems = inventory_tool.check(fake_columns(), merged)
        self.assertTrue(any("decode is still UNKNOWN" in problem for problem in problems))
        self.assertTrue(any("digest is still UNKNOWN" in problem for problem in problems))
        self.assertTrue(any("batch is still UNKNOWN" in problem for problem in problems))

    def test_invalid_decode_kind_fails_check(self):
        merged = inventory_tool.merge(fake_columns(), fake_scopes(), {"columns": []})
        for entry in merged["columns"]:
            entry["decode"], entry["digest"], entry["batch"] = "blob", False, 1
        problems = inventory_tool.check(fake_columns(), merged)
        self.assertTrue(any("decode 'blob' is not one of" in problem for problem in problems))

    def test_unknown_scope_fails_check(self):
        scopes = copy.deepcopy(fake_scopes())
        del scopes["arena_players"]
        merged = inventory_tool.merge(fake_columns(), scopes, {"columns": []})
        for entry in merged["columns"]:
            entry["decode"], entry["digest"], entry["batch"] = "none", False, 1
        problems = inventory_tool.check(fake_columns(), merged)
        self.assertTrue(any("arena_players.defense: scope is unknown" in problem for problem in problems))


if __name__ == "__main__":
    unittest.main()
