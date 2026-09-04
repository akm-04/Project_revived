from __future__ import annotations

import copy
import json
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.projection_profiles import ProjectionProfileRegistry
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.response_projector import ResponseProjector

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")

PARTNER_ID = 10001119  # Shamoke; effective partner.lua star=2
STONE_ID = 40001119
STONE_NUM = 30
MANA_COST = 50_000      # effective data/tables/star.lua star=2 summon_price


def require(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def make_services(*, mana: int) -> tuple[PlayerState, RequestServices, list[int]]:
    player = PlayerState(player_id="990701", account_uid="990701", player_name="Pass70.1")
    player.mana = int(mana)
    player.backpack_items = [{"table_id": STONE_ID, "item_num": STONE_NUM, "time": 0}]
    commits: list[int] = []

    def commit() -> None:
        commits.append(int(player.persistence_state.get("state_version", -1)))

    return player, RequestServices(player, DATA, commit, catalog=CATALOG), commits


def projected_stone_summon(player: PlayerState, services: RequestServices) -> dict:
    projector = ResponseProjector.capture(player, resource_registry=services.resource_registry)
    result = services.summon.stone_summon_hero({
        "table_id": PARTNER_ID,
        "stone": STONE_ID,
        "stone_num": STONE_NUM,
        "mid": 59,
    })
    result = services.apply_semantic_deltas(result)
    journal = services.uow.consume_journal()
    profiles = ProjectionProfileRegistry.load(DATA / "projection_profile_registry.json")
    return projector.project(
        result,
        player,
        committed_journal=journal,
        profile=profiles.resolve(mid=59, label="STONE_SUMMON_HERO", transport="engine_web"),
    )


def main() -> None:
    expected_prices = {1: 1_000, 2: 50_000, 3: 200_000, 4: 500_000, 5: 1_300_000}
    require(services_costs := getattr(__import__(
        "gxb_backend.state.summon_repository", fromlist=["SummonRepository"]
    ).SummonRepository, "_STONE_MANA_BY_STAR", None), "stone summon Mana map missing")
    require(dict(services_costs) == expected_prices, "stone summon Mana price map drift")

    # Successful MID59: one UoW atomically debits Mana + fragments and creates Hero.
    player, services, commits = make_services(mana=100_000)
    v0 = services.uow.current_state_version
    result = projected_stone_summon(player, services)
    require(result.get("error_code") is None, "valid MID59 rejected")
    require(result.get("table_id") == PARTNER_ID, "MID59 hero body drift")
    require(result.get("economy_") == {"mana": 50_000}, "MID59 cumulative Mana projection wrong")
    require(player.mana == 50_000, "MID59 Mana was not debited")
    require(services.stack_inventory.quantity(STONE_ID) == 0, "MID59 fragments were not debited")
    require(any(
        isinstance(hero, dict) and int(hero.get("table_id", 0)) == PARTNER_ID
        for hero in player.heroes.values()
    ), "MID59 Hero was not created")
    require(services.uow.current_state_version == v0 + 1, "MID59 must commit exactly once")
    require(len(commits) == 1, "MID59 commit callback count wrong")

    # Insufficient Mana: fragments + Hero creation must roll back/fail closed.
    player2, services2, commits2 = make_services(mana=MANA_COST - 1)
    before = copy.deepcopy(vars(player2))
    result2 = projected_stone_summon(player2, services2)
    require(result2.get("error_code") == 1, "insufficient-Mana MID59 did not fail closed")
    require(vars(player2) == before, "insufficient-Mana MID59 mutated player state")
    require(len(commits2) == 0, "insufficient-Mana MID59 committed")
    require(services2.uow.consume_journal() == [], "failed MID59 leaked journal")

    print(json.dumps({
        "pass": "70.1",
        "status": "PASS",
        "mid59_source_mana_cost": MANA_COST,
        "mid59_atomic_mana_fragment_hero": True,
        "mid59_cumulative_economy_projection": True,
        "mid59_insufficient_mana_fail_closed": True,
        "star_price_map": expected_prices,
    }, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
