from __future__ import annotations

import copy
import json
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def require(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def make_services() -> tuple[PlayerState, RequestServices, list[int]]:
    player = PlayerState(player_id="990691", account_uid="990691", player_name="Pass69.1")
    player.mana = 1000
    player.crystal = 100
    player.backpack_items = [
        {"table_id": 50001011, "item_num": 3, "time": 0},  # PSP: 500k Mana
        {"table_id": 50001012, "item_num": 2, "time": 0},  # Cushion: 20k Mana; absent from compact GameDataCatalog
        {"table_id": 50000000, "item_num": 1, "time": 0},  # crystal-sale fallback sample
        {"table_id": 250001001, "item_num": 1, "time": 0}, # Horcrux template must fail closed
    ]
    commits: list[int] = []

    def commit() -> None:
        commits.append(int(player.persistence_state.get("state_version", -1)))

    return player, RequestServices(player, DATA, commit, catalog=CATALOG), commits


def main() -> None:
    player, services, commits = make_services()
    require(len(services.item_sale_catalog) == 4564, "sale catalog row count drift")

    # MID82: one ordinary sale becomes one atomic STACK debit + Mana credit.
    v0 = services.uow.current_state_version
    result = services.inventory_sales.sell_one({"item_id": 50001011, "item_num": 1})
    projected = services.apply_semantic_deltas(result)
    require(projected.get("error_code") is None, "ordinary sale rejected")
    require(projected.get("awards") == [], "SELL_ITEM awards shape drift")
    require(projected.get("economy_", {}).get("mana") == 501000, "PSP Mana projection wrong")
    require(player.mana == 501000, "PSP Mana credit not persisted")
    require(services.stack_inventory.quantity(50001011) == 2, "PSP stack debit failed")
    require(services.uow.current_state_version == v0 + 1, "SELL_ITEM must commit once")
    revisions = player.persistence_state["slice_revisions"]
    require(revisions.get("scalar_economy") == 1, "scalar slice not touched")
    require(revisions.get("backpack_stacks") == 1, "Backpack slice not touched")

    # Item absent from compact GameDataCatalog still debits safely when it is an
    # existing stack and ItemSaleCatalog supplies the domain-specific authority.
    v1 = services.uow.current_state_version
    result = services.inventory_sales.sell_one({"item_id": 50001012, "item_num": 1})
    projected = services.apply_semantic_deltas(result)
    require(projected.get("economy_", {}).get("mana") == 521000, "Cushion Mana projection wrong")
    require(player.mana == 521000, "Cushion Mana credit failed")
    require(services.stack_inventory.quantity(50001012) == 1, "Cushion stack debit failed")
    require(services.uow.current_state_version == v1 + 1, "Cushion sale commit count wrong")

    # MID86: aggregate mixed sale rows and crystal fallback under one commit.
    v2 = services.uow.current_state_version
    result = services.inventory_sales.sell_many({"items": [
        {"item_id": 50001011, "item_num": 2},
        {"item_id": 50001012, "item_num": 1},
        {"item_id": 50000000, "item_num": 1},
    ]})
    projected = services.apply_semantic_deltas(result)
    require(projected.get("economy_", {}).get("mana") == 1_541_000, "MID86 Mana aggregate wrong")
    require(projected.get("economy_", {}).get("crystal") == 988, "MID86 crystal fallback wrong")
    require(player.mana == 1_541_000 and player.crystal == 988, "MID86 scalar persistence wrong")
    require(services.stack_inventory.quantity(50001011) == 0, "MID86 PSP debit wrong")
    require(services.stack_inventory.quantity(50001012) == 0, "MID86 Cushion debit wrong")
    require(services.stack_inventory.quantity(50000000) == 0, "MID86 crystal item debit wrong")
    require(services.uow.current_state_version == v2 + 1, "MID86 must commit once")

    # Specialized generated-instance sale metadata must not authorize generic MID82.
    before = copy.deepcopy(vars(player))
    commit_count = len(commits)
    result = services.inventory_sales.sell_one({"item_id": 250001001, "item_num": 1})
    require(result.get("error_code") == 1, "Horcrux generic sale did not fail closed")
    require(vars(player) == before, "rejected specialized sale mutated state")
    require(len(commits) == commit_count, "rejected specialized sale committed")

    # Insufficient stack quantity must fail atomically with no currency grant.
    before = copy.deepcopy(vars(player))
    commit_count = len(commits)
    result = services.inventory_sales.sell_one({"item_id": 50001011, "item_num": 99})
    require(result.get("error_code") == 1, "insufficient stack sale did not fail closed")
    require(vars(player) == before, "insufficient stack sale mutated state")
    require(len(commits) == commit_count, "insufficient stack sale committed")

    print(json.dumps({
        "pass": "69.1",
        "status": "PASS",
        "sell_catalog_rows": len(services.item_sale_catalog),
        "mid82_stack_resource_atomic": True,
        "mid86_aggregate_atomic": True,
        "mana_price_primary": True,
        "crystal_fallback": True,
        "compact_catalog_missing_debit_supported": True,
        "specialized_sale_fail_closed": True,
        "insufficient_stack_fail_closed": True,
        "final_state_version": services.uow.current_state_version,
        "commits": len(commits),
    }, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
