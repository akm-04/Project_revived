#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.content.item_stack_limit_catalog import ItemStackLimitCatalog
from gxb_backend.state.defaults import default_player
from gxb_backend.state.multiuser_database import MultiUserDatabase, SANDBOX_UID

DATA = ROOT / "data"
SEED_FILE = DATA / "debug_guest_mid241_qa_seed_pass141.json"
MAP_FILE = ROOT / "docs" / "PASS141_MID241_RANDOM_QA_MAP.json"
MARKER = "pass141_debug_mid241_qa_seed_v1"


def require(cond: bool, msg: str) -> None:
    if not cond:
        raise AssertionError(msg)


def item_map(player):
    return {
        int(row.get("table_id", 0) or 0): int(row.get("item_num", 0) or 0)
        for row in player.backpack_items
        if isinstance(row, dict)
    }


def main() -> int:
    seed = json.loads(SEED_FILE.read_text(encoding="utf-8"))
    qa_map = json.loads(MAP_FILE.read_text(encoding="utf-8"))
    specs = seed["items"]
    random_specs = [x for x in specs if x["qa_role"] == "PHASE3_RANDOM_ALL"]
    deterministic_specs = [x for x in specs if x["qa_role"] == "PHASE2_DETERMINISTIC_SMOKE"]

    require(len(specs) == 103, "Pass141 must seed exactly 100 random + 3 deterministic smoke packages")
    require(len(random_specs) == 100, "all 100 Phase3 random source items must be seeded")
    require(len({x["item_id"] for x in random_specs}) == 100, "random source item ids must be unique")
    require(len(deterministic_specs) == 3, "three deterministic smoke packages expected")
    require({x["item_id"] for x in deterministic_specs} == {50001172, 50001173, 50005206}, "deterministic smoke ids drifted")
    require(qa_map["phase3_random_operations"] == 100, "QA operation map must cover all 100 random operations")
    require(len(qa_map["unique_dropbox_ids"]) == 96, "QA operation map must cover all 96 unique dropbox ids")
    require(sum(x["ordered_draw_count"] for x in qa_map["operations"]) == 134, "QA operation map must preserve 134 ordered draw occurrences")

    limits = ItemStackLimitCatalog(DATA)
    for spec in specs:
        limit = limits.limit(int(spec["item_id"]))
        require(limit is not None and limit > 0, f"missing stack cap for {spec['item_id']}")
        require(0 < int(spec["target_quantity"]) <= limit, f"seed target exceeds source stack for {spec['item_id']}")

    with tempfile.TemporaryDirectory() as td:
        db = MultiUserDatabase(Path(td), DATA)
        player = default_player()
        player.account_uid = SANDBOX_UID
        player.backpack_items = []
        player.persistence_state = {}

        require(db._apply_pass141_debug_mid241_qa_seed(player), "sandbox first seed should apply")
        inv = item_map(player)
        require(all(inv.get(int(x["item_id"])) == min(int(x["target_quantity"]), int(x["source_stack"])) for x in specs), "seeded quantities mismatch")
        require(MARKER in player.persistence_state.get("migrations", {}), "migration marker missing")
        marker = player.persistence_state["migrations"][MARKER]
        require(marker["phase3_random_source_item_count"] == 100, "marker random count mismatch")
        require(marker["phase3_unique_dropbox_count"] == 96, "marker pool count mismatch")
        require(marker["phase3_ordered_drop_occurrence_count"] == 134, "marker occurrence count mismatch")

        # Non-replenishing: consume one package, rerun migration, and confirm it stays consumed.
        probe = int(random_specs[0]["item_id"])
        row = next(r for r in player.backpack_items if int(r.get("table_id", 0) or 0) == probe)
        row["item_num"] = int(row["item_num"]) - 1
        after_consume = int(row["item_num"])
        require(not db._apply_pass141_debug_mid241_qa_seed(player), "migration must not reapply after marker")
        require(int(row["item_num"]) == after_consume, "consumed QA package was replenished")

        # Credential accounts must never receive the private QA seed.
        other = default_player()
        other.account_uid = "20000001"
        other.backpack_items = []
        other.persistence_state = {}
        require(not db._apply_pass141_debug_mid241_qa_seed(other), "non-sandbox account received QA seed")
        require(not other.backpack_items, "non-sandbox inventory changed")

    print("PASS141 phase4 QA prep selftest: PASS")
    print("seed_items=103 random_source_items=100 unique_dropboxes=96 ordered_occurrences=134")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
