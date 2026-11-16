"""Unit checks for the R8 retention reference lists and --check rules (no database)."""
import copy
import unittest

import retention_references as references_tool


def fake_catalog():
    return references_tool.Catalog(
        columns={
            ("arena_matches", "attempt_id"): "uuid",
            ("guild_broadcast_sources", "source_receipt_id"): "uuid",
            ("player_login_observations", "source_operation_id"): "uuid",
        },
        foreign_keys={("arena_matches", "attempt_id")},
    )


def fake_rule_table():
    return ("arena_matches.attempt_id guild_broadcast_sources.source_receipt_id "
            "player_login_observations.source_operation_id")


class RetentionReferencesTests(unittest.TestCase):
    def test_catalog_with_one_column_per_list_passes(self):
        document = references_tool.build_document(fake_catalog())
        self.assertEqual(references_tool.check(fake_catalog(), document, fake_rule_table()), [])
        self.assertEqual([item["table"] for item in document["attempt_ids"]], ["arena_matches"])
        self.assertEqual([item["table"] for item in document["receipt_ids"]], ["guild_broadcast_sources"])
        self.assertEqual([item["table"] for item in document["operation_ids"]], ["player_login_observations"])
        self.assertEqual(document["attempt_ids"][0]["type"], "uuid")
        self.assertTrue(document["attempt_ids"][0]["foreign_key"])
        self.assertFalse(document["receipt_ids"][0]["foreign_key"])

    def test_probe_column_missing_from_rule_table_fails(self):
        document = references_tool.build_document(fake_catalog())
        rule_table = "arena_matches.attempt_id guild_broadcast_sources.source_receipt_id"
        problems = references_tool.check(fake_catalog(), document, rule_table)
        self.assertIn("player_login_observations.source_operation_id: "
                      "listed reference column is not cited by a retention rule", problems)

    def test_absent_rule_table_skips_the_citation_check(self):
        document = references_tool.build_document(fake_catalog())
        self.assertEqual(references_tool.check(fake_catalog(), document, None), [])

    def test_file_difference_fails(self):
        document = references_tool.build_document(fake_catalog())
        changed = copy.deepcopy(document)
        changed["receipt_ids"][0]["table"] = "ghost"
        problems = references_tool.check(fake_catalog(), changed, fake_rule_table())
        self.assertTrue(any("differs from the generated reference lists" in problem for problem in problems))

    def test_combat_chain_key_columns_are_excluded(self):
        catalog = fake_catalog()
        catalog.columns.update({
            ("combat_attempts", "attempt_id"): "uuid",
            ("combat_attempts", "supersedes_attempt_id"): "uuid",
            ("combat_attempt_members", "attempt_id"): "uuid",
        })
        tables = [(item["table"], item["column"])
                  for item in references_tool.build_document(catalog)["attempt_ids"]]
        self.assertNotIn(("combat_attempts", "attempt_id"), tables)
        self.assertNotIn(("combat_attempt_members", "attempt_id"), tables)
        self.assertIn(("combat_attempts", "supersedes_attempt_id"), tables)
        self.assertIn(("arena_matches", "attempt_id"), tables)

    def test_lead_approved_text_attempt_ids_are_listed_as_text(self):
        catalog = fake_catalog()
        catalog.columns[("worldboss_attempts", "attempt_id")] = "text"
        attempts = {(item["table"], item["column"]): item
                    for item in references_tool.build_document(catalog)["attempt_ids"]}
        self.assertEqual(attempts[("worldboss_attempts", "attempt_id")]["type"], "text")
        self.assertFalse(attempts[("worldboss_attempts", "attempt_id")]["foreign_key"])

    def test_other_text_attempt_id_stops(self):
        catalog = fake_catalog()
        catalog.columns[("conquer_school_reports", "attempt_id")] = "text"
        with self.assertRaises(references_tool.CatalogProblem) as raised:
            references_tool.build_document(catalog)
        self.assertIn("conquer_school_reports.attempt_id: text attempt-id column is not in the lead's text list",
                      str(raised.exception))

    def test_receipts_own_operation_id_is_excluded(self):
        catalog = fake_catalog()
        catalog.columns[("gxb_operation_receipts", "operation_id")] = "uuid"
        operations = [(item["table"], item["column"])
                      for item in references_tool.build_document(catalog)["operation_ids"]]
        self.assertNotIn(("gxb_operation_receipts", "operation_id"), operations)

    def test_text_receipt_ids_are_listed_without_a_key(self):
        catalog = fake_catalog()
        catalog.columns[("combat_attempts", "semantic_receipt_id")] = "text"
        receipts = {(item["table"], item["column"]): item
                    for item in references_tool.build_document(catalog)["receipt_ids"]}
        self.assertEqual(receipts[("combat_attempts", "semantic_receipt_id")]["type"], "text")
        self.assertFalse(receipts[("combat_attempts", "semantic_receipt_id")]["foreign_key"])


if __name__ == "__main__":
    unittest.main()
