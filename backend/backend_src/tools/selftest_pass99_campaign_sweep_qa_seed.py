#!/usr/bin/env python3
"""Pass99 focused Campaign sweep-cost + QA seed validation."""
from __future__ import annotations

import json
import tempfile
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
CAMPAIGN_ID = 1300016
RAID_TICKET = 50001013


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def make_services(*, energy: int = 200, crystal: int = 100, tickets: int = 20):
    player = PlayerState(player_id="9999001", account_uid="9999001", player_name="Pass99", vip=15)
    player.lev = 100
    player.max_lev = 100
    player.energy = energy
    player.max_energy = 160
    player.energy_time = 0
    player.crystal = crystal
    player.backpack_items = [
        {"table_id": RAID_TICKET, "item_num": tickets, "time": 0},
        {"table_id": 50001001, "item_num": 0, "time": 0},
        {"table_id": 50001002, "item_num": 0, "time": 0},
    ]
    player.world_map = {
        "normal": [{"campaign_id": CAMPAIGN_ID, "star": 3, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}],
        "super": [],
        "challenge": {},
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": 13,
            "normal_campaign_id": CAMPAIGN_ID,
            "super_chapter_id": 1,
            "super_campaign_id": 100002,
            "normal_stars": 3,
            "normal_bonus_id": 0,
            "super_stars": 0,
            "super_bonus_id": 0,
        },
    }
    commits: list[int] = []
    svc = RequestServices(player, DATA, lambda: commits.append(1), catalog=CATALOG)
    return player, svc, commits


def test_item_sweep_costs() -> None:
    player, svc, commits = make_services()
    require(svc.world._campaign_entry_energy_cost(CAMPAIGN_ID) == 12, "source energy cost drift")
    result = svc.world.sweep({
        "campaign_id": CAMPAIGN_ID,
        "campaign_type": 1,
        "sweep_num": 10,
        "sweep_type": 1,
    })
    require(result.get("error_code", 0) == 0, f"valid item sweep rejected: {result}")
    require(player.energy == 80, f"10x sweep Energy expected 80, got {player.energy}")
    require(svc.stack_inventory.quantity(RAID_TICKET) == 10, "Raid Ticket debit mismatch")
    require(player.crystal == 100, "item sweep must not debit Crystal")
    require(len(result.get("items") or []) == 10, "10x response item rows missing")
    semantic = svc.apply_semantic_deltas(result)
    require(semantic.get("economy_", {}).get("energy") == 80, "Energy cumulative projection missing")
    journal = svc.uow.consume_journal()
    require(any(r.get("category") == "TEMPORAL" and r.get("subject", {}).get("resource_key") == "energy" for r in journal), "Energy journal missing")
    require(any(r.get("category") == "STACK" and r.get("subject", {}).get("item_id") == RAID_TICKET and r.get("action") == "DEBIT" for r in journal), "Raid Ticket debit journal missing")
    require(commits == [1], "sweep should be one durable UoW commit")


def test_crystal_sweep_costs() -> None:
    player, svc, commits = make_services(energy=50, crystal=9, tickets=0)
    result = svc.world.sweep({
        "campaign_id": CAMPAIGN_ID,
        "campaign_type": 1,
        "sweep_num": 1,
        "sweep_type": 2,
    })
    require(result.get("error_code", 0) == 0, f"valid crystal sweep rejected: {result}")
    require(player.energy == 38, "1x sweep Energy debit mismatch")
    require(player.crystal == 8, "1x CRYSTAL_SWEEP must cost exactly one Crystal")
    semantic = svc.apply_semantic_deltas(result)
    require(semantic.get("economy_", {}).get("energy") == 38, "crystal sweep Energy projection missing")
    require(semantic.get("economy_", {}).get("crystal") == 8, "crystal sweep Crystal projection missing")
    svc.uow.consume_journal()
    require(commits == [1], "crystal sweep should be one durable UoW commit")


def test_sweep_failure_is_atomic() -> None:
    player, svc, commits = make_services(energy=119, crystal=100, tickets=20)
    before = (player.energy, player.crystal, svc.stack_inventory.quantity(RAID_TICKET), list(player.backpack_items))
    result = svc.world.sweep({
        "campaign_id": CAMPAIGN_ID,
        "campaign_type": 1,
        "sweep_num": 10,
        "sweep_type": 1,
    })
    require(result.get("error_code") == 1, "insufficient Energy sweep should fail")
    after = (player.energy, player.crystal, svc.stack_inventory.quantity(RAID_TICKET), list(player.backpack_items))
    require(before == after, "failed sweep partially mutated state")
    require(commits == [], "failed sweep must not commit")
    require(svc.uow.consume_journal() == [], "failed sweep emitted journal")


def test_pass99_qa_seed() -> None:
    with tempfile.TemporaryDirectory(prefix="gxb-pass99-") as tmp:
        store = MultiUserDatabase(Path(tmp), DATA)
        player = PlayerState(account_uid="13371337", player_id="12525385")
        player.persistence_state = {"migrations": {}}
        require(store._apply_pass99_debug_qa_consumables_seed(player), "Pass99 QA seed did not apply")
        qty = {int(r["table_id"]): int(r["item_num"]) for r in player.backpack_items}
        require(qty[50001013] == 900, "Raid Ticket QA seed wrong")
        for iid in (50001014, 50001015, 50001016):
            require(qty[iid] == 90, f"cap-99 food {iid} must seed to 90")
        for iid in range(50001120, 50001132):
            require(qty[iid] == 900, f"magic consumable {iid} QA seed wrong")
        marker = player.persistence_state["migrations"]["pass99_debug_qa_consumables_seed_v1"]
        require(marker["applied"] == 1 and len(marker["seeded_targets"]) == 16, "QA seed marker incomplete")
        qty[50001015] = 89
        for row in player.backpack_items:
            if int(row.get("table_id", 0) or 0) == 50001015:
                row["item_num"] = 89
        require(not store._apply_pass99_debug_qa_consumables_seed(player), "QA seed must be one-shot")
        require(next(int(r["item_num"]) for r in player.backpack_items if int(r.get("table_id", 0) or 0) == 50001015) == 89, "one-shot seed replenished consumed Kanto")


def main() -> None:
    test_item_sweep_costs()
    test_crystal_sweep_costs()
    test_sweep_failure_is_atomic()
    test_pass99_qa_seed()
    print(json.dumps({
        "pass": "99.0",
        "status": "PASS",
        "campaign_mid114_runtime_debit_preserved": True,
        "campaign_mid117_energy_cost": "campaign.energy_cost * sweep_num",
        "campaign_mid117_item_sweep_cost": "50001013 * sweep_num",
        "campaign_mid117_crystal_sweep_cost": "1 crystal * sweep_num",
        "qa_seed_rows": 16,
        "mid97": "research_only_due_empty_request_retry_ambiguity",
    }, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
