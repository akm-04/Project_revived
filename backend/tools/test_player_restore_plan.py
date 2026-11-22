"""Unit checks for the R8 player restore plan and --check rules (no database)."""
import copy
import unittest

import player_restore_plan as plan_tool


def fake_catalog():
    return plan_tool.Catalog(
        tables=["players", "player_state", "player_ledger", "player_child", "player_shared",
                "player_shared_refs", "other_player_row", "guild_row"],
        column_types={
            ("players", "player_id"): "bigint",
            ("players", "state_version"): "bigint",
            ("player_state", "player_id"): "bigint",
            ("player_state", "state_version"): "bigint",
            ("player_state", "updated_at"): "timestamp with time zone",
            ("player_ledger", "player_id"): "bigint",
            ("player_child", "parent_id"): "bigint",
            ("player_child", "other_player_id"): "bigint",
            ("player_shared", "player_low_id"): "bigint",
            ("player_shared", "player_high_id"): "bigint",
            ("player_shared_refs", "low_player_id"): "bigint",
            ("player_shared_refs", "high_player_id"): "bigint",
            ("other_player_row", "player_id"): "bigint",
            ("other_player_row", "target_player_id"): "bigint",
            ("guild_row", "player_id"): "bigint",
        },
        foreign_keys=[
            fake_foreign_key("player_state_player_id_fkey", "player_state", ["player_id"],
                             "players", ["player_id"]),
            fake_foreign_key("player_ledger_player_id_fkey", "player_ledger", ["player_id"],
                             "player_state", ["player_id"]),
            fake_foreign_key("player_child_parent_id_fkey", "player_child", ["parent_id"],
                             "player_state", ["player_id"]),
            fake_foreign_key("player_child_other_player_id_fkey", "player_child", ["other_player_id"],
                             "players", ["player_id"]),
            fake_foreign_key("player_shared_low_fkey", "player_shared", ["player_low_id"],
                             "player_state", ["player_id"]),
            fake_foreign_key("player_shared_high_fkey", "player_shared", ["player_high_id"],
                             "player_state", ["player_id"]),
            fake_foreign_key("player_shared_refs_low_fkey", "player_shared_refs", ["low_player_id"],
                             "players", ["player_id"]),
            fake_foreign_key("player_shared_refs_high_fkey", "player_shared_refs", ["high_player_id"],
                             "players", ["player_id"]),
            fake_foreign_key("other_player_target_fkey", "other_player_row", ["target_player_id"],
                             "players", ["player_id"]),
            fake_foreign_key("other_player_own_fkey", "other_player_row", ["player_id"],
                             "players", ["player_id"]),
            fake_foreign_key("guild_row_player_id_fkey", "guild_row", ["player_id"],
                             "players", ["player_id"]),
        ],
    )


def fake_foreign_key(name, table, columns, target, target_columns):
    return {"constraint": name, "table": table, "columns": columns,
            "target": target, "target_columns": target_columns}


def fake_classes():
    return {
        "players": {"scope": "player", "owner": ["player_id"], "via": None, "kind": "state",
                    "backup": True, "references": []},
        "player_state": {"scope": "player", "owner": ["player_id"], "via": None, "kind": "state",
                         "backup": True, "references": []},
        "player_ledger": {"scope": "player", "owner": ["player_id"], "via": "player_state", "kind": "ledger",
                          "backup": True, "references": []},
        "player_child": {"scope": "player", "owner": [], "via": "player_state", "kind": "state",
                         "backup": True, "references": []},
        "player_shared": {"scope": "player", "owner": [], "via": "player_state", "kind": "shared",
                          "backup": True, "references": ["player_low_id", "player_high_id"]},
        "player_shared_refs": {"scope": "player", "owner": [], "via": None, "kind": "shared",
                               "backup": True, "references": ["low_player_id", "high_player_id"]},
        "other_player_row": {"scope": "player", "owner": ["player_id"], "via": None, "kind": "state",
                             "backup": True, "references": ["target_player_id"]},
        "guild_row": {"scope": "guild", "owner": [], "via": None, "kind": "state",
                      "backup": False, "references": []},
    }


def fake_manifest():
    order = ["players", "player_state", "player_ledger", "player_child", "player_shared",
             "player_shared_refs", "other_player_row"]
    entries = []
    for position, table in enumerate(order):
        data = fake_classes()[table]
        entries.append({
            "table": table,
            "scope": data["scope"],
            "owner": data["owner"],
            "via": data["via"],
            "kind": data["kind"],
            "backup": data["backup"],
            "references": data["references"],
            "restore_order": position,
        })
    return {"tables": entries}


def fake_plan():
    return plan_tool.build_plan(fake_manifest(), fake_classes(), fake_catalog())


def entry(plan, table):
    return next(item for item in plan["tables"] if item["table"] == table)


def constraints(plan, table):
    return {item["constraint"] for item in entry(plan, table)["inbound"]}


class PlayerRestorePlanTests(unittest.TestCase):
    def test_kind_selects_the_action(self):
        plan = fake_plan()
        self.assertEqual(entry(plan, "player_state")["action"], "restore")
        self.assertEqual(entry(plan, "player_ledger")["action"], "keep")
        self.assertEqual(entry(plan, "player_shared")["action"], "skip")

    def test_plan_is_in_restore_order(self):
        plan = fake_plan()
        self.assertEqual([item["table"] for item in plan["tables"]], [
            "players", "player_state", "player_ledger", "player_child", "player_shared",
            "player_shared_refs", "other_player_row"])

    def test_owner_select(self):
        self.assertEqual(entry(fake_plan(), "player_state")["select"],
                         'SELECT * FROM "player_state" WHERE "player_id" = $1::bigint')

    def test_via_select_joins_the_parent(self):
        select = entry(fake_plan(), "player_child")["select"]
        self.assertIn('FROM "player_child" c', select)
        self.assertIn('FROM "player_state" p', select)
        self.assertIn('c."parent_id" = p."player_id"', select)
        self.assertIn('p."player_id" = $1::bigint', select)

    def test_reference_select_uses_the_player_columns(self):
        select = entry(fake_plan(), "player_shared_refs")["select"]
        self.assertEqual(select, 'SELECT * FROM "player_shared_refs" WHERE '
                                 '"low_player_id" = $1::bigint OR "high_player_id" = $1::bigint')

    def test_owner_where_narrows_the_select(self):
        manifest = fake_manifest()
        manifest["tables"][1]["owner_where"] = "kind = 'player'"
        plan = plan_tool.build_plan(manifest, fake_classes(), fake_catalog())
        self.assertIn("AND (kind = 'player')", entry(plan, "player_state")["select"])

    def test_versioned_records_each_column(self):
        plan = fake_plan()
        self.assertEqual(entry(plan, "player_state")["versioned"],
                         {"state_version": True, "updated_at": True})
        self.assertEqual(entry(plan, "players")["versioned"],
                         {"state_version": True, "updated_at": False})

    def test_own_restore_key_is_not_inbound(self):
        found = constraints(fake_plan(), "players")
        self.assertNotIn("player_state_player_id_fkey", found)
        self.assertNotIn("other_player_own_fkey", found)

    def test_guild_and_foreign_reference_keys_are_inbound(self):
        found = constraints(fake_plan(), "players")
        self.assertIn("guild_row_player_id_fkey", found)
        self.assertIn("other_player_target_fkey", found)
        self.assertIn("player_child_other_player_id_fkey", found)

    def test_kept_and_shared_rows_are_inbound(self):
        self.assertIn("player_ledger_player_id_fkey", constraints(fake_plan(), "player_state"))
        self.assertIn("player_shared_low_fkey", constraints(fake_plan(), "player_state"))

    def test_restored_via_row_is_not_inbound(self):
        self.assertNotIn("player_child_parent_id_fkey", constraints(fake_plan(), "player_state"))

    def test_player_scoped_table_without_a_plan_entry_fails(self):
        plan = fake_plan()
        plan["tables"] = [item for item in plan["tables"] if item["table"] != "player_ledger"]
        problems = plan_tool.check(fake_manifest(), fake_classes(), fake_catalog(), plan)
        self.assertIn("player_ledger: player-scoped table has no plan entry", problems)

    def test_changed_plan_fails(self):
        plan = copy.deepcopy(fake_plan())
        entry(plan, "player_ledger")["action"] = "restore"
        problems = plan_tool.check(fake_manifest(), fake_classes(), fake_catalog(), plan)
        self.assertTrue(any("differs from the generated plan" in problem for problem in problems))

    def test_generated_plan_passes_check(self):
        self.assertEqual(plan_tool.check(fake_manifest(), fake_classes(), fake_catalog(), fake_plan()), [])


if __name__ == "__main__":
    unittest.main()
