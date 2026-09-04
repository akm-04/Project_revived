#!/usr/bin/env python3
"""Pass230 sandbox-only P2 Awakening/Blood inventory cleanup self-test."""
from __future__ import annotations

import json
import tempfile
from pathlib import Path

from gxb_backend.state.multiuser_database import MultiUserDatabase, SANDBOX_UID
from gxb_backend.state.player_state import PlayerState

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def req(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def source_ids() -> tuple[set[int], set[int], set[int]]:
    payload = json.loads((DATA / "awakening_source_catalog.json").read_text(encoding="utf-8"))
    ordinary: set[int] = set()
    blood: set[int] = set()
    for bucket_name, target in (("ordinary_stage1_routes", ordinary), ("blood_stage1_routes", blood)):
        bucket = payload.get(bucket_name) or {}
        for row in bucket.values():
            if not isinstance(row, dict):
                continue
            for key in ("material_item", "fragment_item", "exclusive_gear_item"):
                value = int(row.get(key, 0) or 0)
                if value > 0:
                    target.add(value)
            for value in row.get("delete_items") or []:
                value = int(value or 0)
                if value > 0:
                    target.add(value)
    return ordinary, blood, ordinary | blood


def main() -> None:
    fixture = json.loads((DATA / "debug_guest_p2_smoke_cleanup_pass230.json").read_text(encoding="utf-8"))
    fixture_ids = {int(v) for v in fixture["item_ids"]}
    ordinary, blood, expected = source_ids()
    req(len(ordinary) == 491, f"ordinary census drift: {len(ordinary)}")
    req(len(blood) == 83, f"blood census drift: {len(blood)}")
    req(len(expected) == 574, f"total census drift: {len(expected)}")
    req(fixture_ids == expected, "fixture does not exactly match source-derived P2 item set")
    req(50005037 not in fixture_ids, "Wish Bottle must not be removed by Pass230")
    for known in (20001185, 60001043, 21001001, 50005001, 60005001):
        req(known in fixture_ids, f"known P2 item missing: {known}")

    with tempfile.TemporaryDirectory(prefix="gxb-pass230-") as td:
        db = MultiUserDatabase(Path(td), DATA)
        player = PlayerState(player_id="230001", account_uid=SANDBOX_UID, player_name="Sandbox")
        player.backpack_items = [
            {"table_id": 20001185, "item_num": 900, "time": 0},
            {"table_id": 60001043, "item_num": 900, "time": 0},
            {"table_id": 21001001, "item_num": 900, "time": 0},
            {"table_id": 50005001, "item_num": 900, "time": 0},
            {"table_id": 60005001, "item_num": 900, "time": 0},
            {"table_id": 50005037, "item_num": 2, "time": 0},
            {"table_id": 99999999, "item_num": 17, "time": 0},
        ]
        req(db._apply_pass230_debug_p2_awake_inventory_cleanup(player), "sandbox cleanup did not apply")
        by_id = {int(r["table_id"]): int(r["item_num"]) for r in player.backpack_items if isinstance(r, dict)}
        req(50005037 in by_id and by_id[50005037] == 2, "Wish Bottle was changed")
        req(99999999 in by_id and by_id[99999999] == 17, "unrelated inventory was changed")
        req(not (fixture_ids & set(by_id)), "P2 cleanup target survived")
        marker = fixture["_meta"]["migration_marker"]
        req(player.persistence_state["migrations"][marker]["applied"] == 1, "migration marker missing")

        # Legitimately acquired item after migration must survive all future normalizations.
        player.backpack_items.append({"table_id": 60001043, "item_num": 1, "time": 0})
        req(not db._apply_pass230_debug_p2_awake_inventory_cleanup(player), "one-shot cleanup ran twice")
        by_id = {int(r["table_id"]): int(r["item_num"]) for r in player.backpack_items if isinstance(r, dict)}
        req(by_id.get(60001043) == 1, "legitimate post-cleanup acquisition did not persist")

        credential = PlayerState(player_id="230002", account_uid="credential-user", player_name="Credential")
        credential.backpack_items = [{"table_id": 60001043, "item_num": 900, "time": 0}]
        req(not db._apply_pass230_debug_p2_awake_inventory_cleanup(credential), "cleanup leaked to non-sandbox account")
        req(credential.backpack_items[0]["item_num"] == 900, "non-sandbox inventory changed")

    print("PASS230_P2_SMOKE_CLEANUP_SELFTEST_OK")


if __name__ == "__main__":
    main()
