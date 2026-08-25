#!/usr/bin/env python3
"""Pass96 focused Economy/VIP cleanup validation."""
from __future__ import annotations

import tempfile
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content.item_stack_limit_catalog import ItemStackLimitCatalog
from gxb_backend.state.inventory_repository import InventoryRepository
from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.player_progression_service import PlayerProgressionService
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.stack_inventory import StackCapacityExceeded
from gxb_backend.state.unit_of_work import OperationContext, UnitOfWork
from gxb_backend.state.vip_policy import VipPrivilegeResolver, VipProgressionPolicy
from gxb_backend.state.world_repository import WorldRepository
from gxb_backend.state.hero_repository import HeroRepository



def test_stack_catalog_and_uow() -> None:
    limits = ItemStackLimitCatalog(DATA)
    assert len(limits) == 5838
    assert limits.limit(100001001) == 999
    assert limits.limit(130001001) == 99

    player = PlayerState(account_uid="20000001", player_id="19700001")
    player.backpack_items = [{"table_id": 100001001, "item_num": 998, "time": 0}]
    commits = []
    uow = UnitOfWork(player, lambda: commits.append(1))
    inv = InventoryRepository(player, data_dir=DATA, uow=uow)
    ctx = OperationContext(actor_player_id=player.player_id, domain="test", operation_name="stack_cap")
    try:
        with uow.transaction(ctx):
            inv.apply_deltas({100001001: 1})
            assert inv.quantity(100001001) == 999
            inv.apply_deltas({100001001: 1})
    except StackCapacityExceeded as exc:
        assert exc.limit == 999
    else:
        raise AssertionError("source stack overflow should fail")
    assert inv.quantity(100001001) == 998, "outer UoW must roll back the first staged credit"
    assert commits == []

    # Legacy-overfull rows remain consumable so the new ceiling cannot trap an
    # old account. Positive additions stay blocked until it is below the cap.
    player.backpack_items = [{"table_id": 100001001, "item_num": 1000, "time": 0}]
    inv.apply_deltas({100001001: -1})
    assert inv.quantity(100001001) == 999
    try:
        inv.apply_deltas({100001001: 1})
    except StackCapacityExceeded:
        pass
    else:
        raise AssertionError("credit beyond 999 should remain blocked")


def test_academy_authority_and_max_exp() -> None:
    player = PlayerState(account_uid="20000002", player_id="19700002", lev=100, exp=700000, max_lev=200)
    progression = PlayerProgressionService(player, DATA)
    assert progression.highest_source_level() == 100
    assert progression.max_level_exp_ceiling() == 613614
    assert progression.normalize_source_authority()
    assert (player.lev, player.max_lev, player.exp) == (100, 100, 613614)

    # A max-level EXP grant becomes a no-op rather than making SelfPlayer step
    # to level101 before its maxTeamLev check.
    before = player.exp
    assert progression.grant_exp(999999) == {}
    assert player.exp == before

    # Crossing 99 -> 100 still works and preserves the source level-up reward.
    player2 = PlayerState(account_uid="20000003", player_id="19700003", lev=99, exp=579614, max_lev=100, energy=100)
    progression2 = PlayerProgressionService(player2, DATA, allow_legacy_direct_energy_mutation=True)
    out = progression2.grant_exp(999999)
    assert player2.lev == 100
    assert player2.exp == 613614
    assert player2.max_energy == 160
    assert player2.energy == 221  # level99 award_energy = 121
    assert out["lev"] == 100 and out["exp"] == 613614


def test_sandbox_one_shot_normalization() -> None:
    with tempfile.TemporaryDirectory(prefix="gxb-pass96-") as tmp:
        store = MultiUserDatabase(Path(tmp), DATA)
        player = PlayerState(account_uid="13371337", player_id="12525385", lev=99, exp=0, max_lev=200, max_energy=100)
        player.persistence_state = {
            "state_version": 0,
            "slice_revisions": {},
            "slice_schema_versions": {},
            "receipts": {},
            "claims": {},
            "migration": {},
            "migrations": {
                "pass72_debug_hero_inventory_seed_v1": {"applied": 1},
                "pass73_debug_advanced_progression_seed_v1": {"applied": 1},
                "pass75_debug_campaign_unlock_v1": {"applied": 1},
            },
        }
        player.backpack_items = [
            {"table_id": 100001001, "item_num": 1000, "time": 0},  # cap999 -> 900
            {"table_id": 130001001, "item_num": 1000, "time": 0},  # cap99 -> 90
            {"table_id": 100001002, "item_num": 500, "time": 0},   # consumed -> preserve
        ]
        assert store.normalize_player(player, persist=False)
        assert (player.lev, player.exp, player.max_lev, player.max_energy) == (100, 579615, 100, 160)
        qty = {int(r["table_id"]): int(r["item_num"]) for r in player.backpack_items}
        assert qty[100001001] == 900
        assert qty[130001001] == 90
        assert qty[100001002] == 500
        marker = player.persistence_state["migrations"]["pass96_debug_account_normalization_v1"]
        assert marker["applied"] == 1
        snapshot = [(r["table_id"], r["item_num"]) for r in player.backpack_items]
        assert not store._apply_pass96_debug_account_normalization(player)
        assert snapshot == [(r["table_id"], r["item_num"]) for r in player.backpack_items]


def test_vip_entitlements() -> None:
    policy = VipProgressionPolicy(DATA)
    player = PlayerState(account_uid="20000004", player_id="19700004", vip=0)
    vip = VipPrivilegeResolver(player, policy)
    assert vip.hero_preset_limit() == 10
    assert not vip.campaign_multi_sweep_enabled()
    player.privilege_left_card_day = 1
    assert vip.campaign_multi_sweep_enabled()
    player.privilege_left_card_day = 0
    player.vip = 4
    assert vip.campaign_multi_sweep_enabled()
    player.vip = 15
    assert vip.hero_preset_limit() == 20


def test_world_multi_sweep_gate() -> None:
    player = PlayerState(account_uid="20000005", player_id="19700005", vip=0)
    world = WorldRepository(player, DATA, inventory=InventoryRepository(player, data_dir=DATA))
    world.normalize()
    blocked = world.sweep({"campaign_id": 100001, "sweep_num": 10})
    assert blocked.get("error_code") == 1
    single = world.sweep({"campaign_id": 100001, "sweep_num": 1})
    assert single.get("error_code", 0) == 0
    player.vip = 4
    allowed = world.sweep({"campaign_id": 100001, "sweep_num": 10})
    assert allowed.get("error_code", 0) == 0
    player.vip = 0
    player.privilege_left_card_day = 1
    privileged = world.sweep({"campaign_id": 100001, "sweep_num": 10})
    assert privileged.get("error_code", 0) == 0


def _teams(n: int) -> str:
    return ":".join(str(i + 1) for i in range(n))


def test_hero_preset_gate() -> None:
    player = PlayerState(account_uid="20000006", player_id="19700006", vip=0)
    repo = HeroRepository(player, data_dir=DATA)
    ok = repo.save_presets(_teams(10), "|||".join(f"T{i}" for i in range(10)), "|".join("0" for _ in range(10)))
    assert ok.get("error_code", 0) == 0
    preserved = player.save_team
    blocked = repo.save_presets(_teams(11), "x", "0")
    assert blocked.get("error_code") == 1 and blocked.get("preset_num") == 10
    assert player.save_team == preserved
    player.vip = 15
    ok20 = repo.save_presets(_teams(20), "x", "0")
    assert ok20.get("error_code", 0) == 0
    blocked21 = repo.save_presets(_teams(21), "x", "0")
    assert blocked21.get("error_code") == 1 and blocked21.get("preset_num") == 20


def main() -> int:
    test_stack_catalog_and_uow()
    test_academy_authority_and_max_exp()
    test_sandbox_one_shot_normalization()
    test_vip_entitlements()
    test_world_multi_sweep_gate()
    test_hero_preset_gate()
    print("PASS96 Economy/VIP cleanup self-test: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
