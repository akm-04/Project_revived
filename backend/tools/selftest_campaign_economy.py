#!/usr/bin/env python3
"""Offline state test for v0.8.3 Campaign economy/level-up synchronization."""
from __future__ import annotations

import tempfile
from pathlib import Path

from gxb_backend.state.economy_repository import EconomyRepository
from gxb_backend.state.hero_progression_repository import HeroProgressionRepository
from gxb_backend.state.inventory_repository import InventoryRepository
from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.profiles import make_fresh_player
from gxb_backend.state.summon_repository import SummonRepository
from gxb_backend.state.world_repository import WorldRepository


ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def count_item(player, item_id: int) -> int:
    total = 0
    for row in player.backpack_items:
        if isinstance(row, dict) and int(row.get("table_id", row.get("item_id", 0))) == item_id:
            total += int(row.get("item_num", 0))
    return total



def persistence_test() -> None:
    with tempfile.TemporaryDirectory(prefix="gxb-v083-") as temp_dir:
        store = MultiUserDatabase(Path(temp_dir), DATA)
        player = store.create_fresh_player(
            uid="20008888", region=197, region_name="Local-197"
        )

        def save() -> None:
            store.save_player(player)

        summon = SummonRepository(player, DATA, save)
        assert summon.summon_hero({"summon_type": 1, "summon_index": 1}).get("result")
        assert summon.summon_hero({"summon_type": 3, "summon_index": 1}).get("result")

        world = WorldRepository(
            player,
            DATA,
            save,
            inventory=InventoryRepository(player),
            economy=EconomyRepository(player, DATA),
            hero_progression=HeroProgressionRepository(player, DATA),
        )
        fight = {"campaign_id": 100001, "campaign_type": 1, "formation": "1|2|3"}
        result = {**fight, "star": 3}
        world.begin_fight(fight)
        committed = world.commit_fight_result(result)

        player_id = str(player.player_id)
        loaded = store.load_player(player_id)
        assert loaded is not None
        assert loaded.mana == 495
        assert loaded.exp == 18
        assert loaded.lev == 4
        assert loaded.energy == 78
        assert loaded.max_energy == 64
        assert loaded.invitation is None
        assert "invitation" not in loaded.player_info_payload()
        assert count_item(loaded, 20001001) == 1
        assert all(int(loaded.heroes[str(pid)]["exp"]) == 75 for pid in (1, 2, 3))

        # The committed MID114 receipt is persisted too, so a retry after a
        # backend restart/reload still cannot duplicate the reward transaction.
        loaded_world = WorldRepository(
            loaded,
            DATA,
            lambda: store.save_player(loaded),
            inventory=InventoryRepository(loaded),
            economy=EconomyRepository(loaded, DATA),
            hero_progression=HeroProgressionRepository(loaded, DATA),
        )
        retry = loaded_world.commit_fight_result(result)
        assert retry == committed
        assert loaded.mana == 495
        assert loaded.exp == 18
        assert loaded.energy == 78
        assert count_item(loaded, 20001001) == 1
        assert all(int(loaded.heroes[str(pid)]["exp"]) == 75 for pid in (1, 2, 3))


def main() -> int:
    player = make_fresh_player(
        account_uid="20009999",
        player_id="19799999",
        region=197,
        region_name="Local-197",
    )
    summon = SummonRepository(player, DATA)
    assert summon.normalize(fresh_credential=True)
    assert summon.summon_hero({"summon_type": 1, "summon_index": 1}).get("result")
    assert summon.summon_hero({"summon_type": 3, "summon_index": 1}).get("result")
    assert sorted(int(k) for k in player.heroes) == [1, 2, 3]

    world = WorldRepository(
        player,
        DATA,
        inventory=InventoryRepository(player),
        economy=EconomyRepository(player, DATA),
        hero_progression=HeroProgressionRepository(player, DATA),
    )
    world.normalize()

    fight = {"campaign_id": 100001, "campaign_type": 1, "formation": "1|2|3"}
    result = {**fight, "star": 3}

    start = world.begin_fight(fight)
    assert start["items"] == [{"item_id": 20001001, "item_num": 1}]
    out = world.commit_fight_result(result)

    assert out["items"] == [{"item_id": 20001001, "item_num": 1}]
    assert out["economy_"] == {"mana": 495, "exp": 18, "lev": 4, "energy": 78}
    assert out["exps"] == [
        {"partner_id": 1, "exp": 75},
        {"partner_id": 2, "exp": 75},
        {"partner_id": 3, "exp": 75},
    ]
    assert player.mana == 495
    assert player.exp == 18
    assert player.lev == 4
    assert player.energy == 78
    assert player.max_energy == 64
    assert player.invitation is None
    assert "invitation" not in player.player_info_payload()
    assert count_item(player, 20001001) == 1
    for pid in (1, 2, 3):
        hero = player.heroes[str(pid)]
        assert int(hero["exp"]) == 75
        assert int(hero["lev"]) == 3

    # Network retry: exact same MID114 returns the committed receipt and must
    # not duplicate any scalar/item/Hero reward.
    retry = world.commit_fight_result(result)
    assert retry == out
    assert player.mana == 495
    assert player.exp == 18
    assert count_item(player, 20001001) == 1
    assert all(int(player.heroes[str(pid)]["exp"]) == 75 for pid in (1, 2, 3))

    # A real replay is preceded by a new MID113. Scalar EXP/Mana are repeatable,
    # but the source-certain first-clear Toy Hammer is not.
    replay_start = world.begin_fight(fight)
    assert replay_start["items"] == []
    replay = world.commit_fight_result(result)
    assert replay["items"] == []
    assert replay["economy_"] == {"mana": 990, "exp": 36, "lev": 7, "energy": 96}
    assert player.mana == 990
    assert player.exp == 36
    assert player.lev == 7
    assert player.energy == 96
    assert player.max_energy == 67
    assert count_item(player, 20001001) == 1
    assert all(int(player.heroes[str(pid)]["exp"]) == 150 for pid in (1, 2, 3))

    persistence_test()
    print("PASS: v0.8.3 Campaign economy/level-up state + persistence test")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
