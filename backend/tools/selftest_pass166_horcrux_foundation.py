#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"
SRC64 = ROOT / "source_evidence" / "src_64"

from gxb_backend.content import GameDataCatalog, HorcruxSourceCatalog
from gxb_backend.state.horcrux_policy import HorcruxPolicyRegistry
from gxb_backend.state.horcrux_repository import HorcruxRepository
from gxb_backend.state.hero_repository import HeroRepository
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.unit_of_work import OperationContext, PlayerUnitOfWork

GAME = GameDataCatalog.load(DATA / "game_data_catalog.json")


def req(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def player(pid: str) -> PlayerState:
    p = PlayerState(player_id=pid, account_uid=pid, player_name="Pass166-H1")
    p.heroes = {}
    p.spirit_list = []
    p.horcrux_state = {}
    p.hunqi_start_info = {}
    return p


def test_source_catalog_and_policy_separation() -> None:
    with tempfile.TemporaryDirectory() as td:
        out = Path(td) / "horcrux_source_catalog.json"
        subprocess.run(
            [sys.executable, str(ROOT / "tools/build_horcrux_source_catalog.py"), "--src64", str(SRC64), "--output", str(out)],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        req(out.read_bytes() == (DATA / "horcrux_source_catalog.json").read_bytes(), "packaged Horcrux source catalog is stale")
    source = HorcruxSourceCatalog(DATA, game_data=GAME)
    policy = HorcruxPolicyRegistry(DATA)
    req(len(source.models()) == 54, "model count drift")
    req(len(source.templates()) == 378, "template count drift")
    req(len(source.strengthening_rows()) == 90, "strength row count drift")
    req(sum(len(source.campaigns_for_day(day)) for day in range(1, 8)) == 42, "Trial stage count drift")
    req(policy.version == "horcrux_policy_v1", "policy registry version drift")
    overlay = policy.anomaly_overlay("dropbox_9199043")
    req(overlay is not None and overlay.get("raw_source_mutated") is False, "9199043 raw-source separation lost")
    req(sum(int(v) for v in overlay.get("effective_weights", [])) == 1000, "9199043 overlay weight drift")


def test_six_slot_hero_normalization_does_not_create_instances() -> None:
    p = player("166001")
    p.heroes = {
        "5": {"partner_id": 5, "table_id": 10001001, "star": 5, "spirit_equip": {}},
        "6": {"partner_id": 6, "table_id": 10001002, "star": 5, "spirit_equip": [9, "2", -3]},
        "7": {"partner_id": 7, "table_id": 10001003, "star": 5, "spirit_equip": "malformed"},
    }
    heroes = HeroRepository(p, data_dir=DATA, catalog=GAME)
    heroes.normalize()
    req(p.heroes["5"]["spirit_equip"] == [0, 0, 0, 0, 0, 0], "dict spirit_equip did not normalize to six slots")
    req(p.heroes["6"]["spirit_equip"] == [9, 2, 0, 0, 0, 0], "short/malformed spirit_equip normalization drift")
    req(p.heroes["7"]["spirit_equip"] == [0, 0, 0, 0, 0, 0], "non-list spirit_equip normalization drift")
    req(p.spirit_list == [], "Hero normalization fabricated Horcrux instances")


def test_allocator_repair_and_uow_rollback_nonreuse() -> None:
    p = player("166002")
    p.spirit_list = [{"spirit_id": 3, "table_id": 250000111}, {"spirit_id": 10, "table_id": 250000112}]
    p.horcrux_state = {"next_spirit_id": 2}
    commits: list[int] = []
    heroes = HeroRepository(p, data_dir=DATA, catalog=GAME)
    uow = PlayerUnitOfWork(p, lambda: commits.append(1))
    repo = HorcruxRepository(p, HorcruxSourceCatalog(DATA, game_data=GAME), heroes=heroes, uow=uow)
    repo.normalize()
    req(p.horcrux_state["next_spirit_id"] == 11, "cursor did not repair above existing spirit_id")
    before = copy.deepcopy(vars(p))
    context = OperationContext(actor_player_id=p.player_id, domain="horcrux.test", operation_name="rollback_allocator", server_time=123)
    try:
        with uow.transaction(context):
            req(repo.allocate_spirit_id() == 11, "allocator did not return repaired cursor")
            raise RuntimeError("force rollback")
    except RuntimeError:
        pass
    req(vars(p) == before, "allocator cursor did not roll back with PlayerUnitOfWork")
    req(commits == [], "rolled-back allocator committed")
    context2 = OperationContext(actor_player_id=p.player_id, domain="horcrux.test", operation_name="commit_allocator", server_time=124)
    with uow.transaction(context2):
        req(repo.allocate_spirit_id() == 11, "allocator changed after rollback")
    req(p.horcrux_state["next_spirit_id"] == 12, "successful allocation did not advance cursor")
    req(len(commits) == 1, "successful allocator did not commit exactly once")
    p.spirit_list = [row for row in p.spirit_list if int(row.get("spirit_id", 0)) != 10]
    context3 = OperationContext(actor_player_id=p.player_id, domain="horcrux.test", operation_name="nonreuse", server_time=125)
    with uow.transaction(context3):
        req(repo.allocate_spirit_id() == 12, "deleted spirit_id was reused")


def test_equip_mirror_reconciliation() -> None:
    p = player("166003")
    p.spirit_list = [
        {"spirit_id": 101, "table_id": 250000111, "is_equip": 0},
        {"spirit_id": 102, "table_id": 250000113, "is_equip": 0},
    ]
    p.heroes = {
        "20": {"partner_id": 20, "table_id": 10001002, "star": 5, "spirit_equip": [101, 0, 0, 0, 0, 0]},
        "10": {"partner_id": 10, "table_id": 10001001, "star": 5, "spirit_equip": [101, 999, 102, 0, 0, 0]},
    }
    heroes = HeroRepository(p, data_dir=DATA, catalog=GAME)
    heroes.normalize()
    repo = HorcruxRepository(p, HorcruxSourceCatalog(DATA, game_data=GAME), heroes=heroes)
    repo.normalize()
    req(p.heroes["10"]["spirit_equip"] == [101, 0, 102, 0, 0, 0], "first deterministic hero did not retain valid refs")
    req(p.heroes["20"]["spirit_equip"] == [0, 0, 0, 0, 0, 0], "duplicate cross-Hero ref did not collapse")
    by_id = {int(row["spirit_id"]): row for row in p.spirit_list}
    req(by_id[101]["is_equip"] == 10 and by_id[102]["is_equip"] == 10, "is_equip owner mirror was not rebuilt from Hero authority")


def test_collocation_count_rebuild() -> None:
    p = player("166004")
    p.spirit_list = [
        {"spirit_id": 101, "table_id": 250000111, "collo_count": 9},
        {"spirit_id": 102, "table_id": 250000112, "collo_count": 9},
    ]
    p.horcrux_state = {
        "collocations": {
            "1": {"id": 1, "name": "A", "spirit_ids": [101, 102, 0, 0, 0, 0]},
            "2": {"id": 2, "name": "B", "spirit_ids": [0, 102, 0, 0, 0, 0]},
            "broken": {"id": -1, "name": "legacy", "spirit_ids": [101, 101]},
        }
    }
    heroes = HeroRepository(p, data_dir=DATA, catalog=GAME)
    repo = HorcruxRepository(p, HorcruxSourceCatalog(DATA, game_data=GAME), heroes=heroes)
    repo.normalize()
    by_id = {int(row["spirit_id"]): row for row in p.spirit_list}
    req(by_id[101]["collo_count"] == 1, "spirit 101 collocation count drift")
    req(by_id[102]["collo_count"] == 2, "spirit 102 collocation count drift")
    req("broken" in p.horcrux_state["migration"].get("legacy_collocations_unactivated", {}), "incompatible legacy collocation was not preserved fail-closed")


def test_legacy_hunqi_stub_is_not_authority_and_mid3101_shape() -> None:
    p = player("166005")
    p.hunqi_start_info = {
        "auto_campaign": 999999,
        "auto_times": 777,
        "auto_start_time": 123,
        "awards": [{"table_id": 1, "item_num": 999}],
        "campaign_progress": {"999": {"win_count": 99}},
    }
    commits: list[int] = []
    services = RequestServices(p, DATA, lambda: commits.append(1), catalog=GAME)
    services.horcrux_repository.normalize()
    marker = p.horcrux_state["migration"]
    req(marker["legacy_hunqi_start_info_nonempty_ignored"] is True, "legacy stub audit marker missing")
    req(p.horcrux_state["trial"]["campaign_progress"] == {}, "legacy HUNQI stub created canonical progress")
    payload = services.gods_trial.startup_payload(materialize_temporal=False)
    req(payload == {"auto_campaign": 0, "auto_times": 0, "auto_start_time": 0}, f"MID3101 idle projection drift: {payload}")
    req("awards" not in payload, "legacy rewards leaked into MID3101")
    p.horcrux_state["trial"]["auto"] = {
        "status": "RUNNING", "run_id": 7, "campaign_id": 310001, "times": 3,
        "auto_start_time": 456, "complete_at": 1356,
    }
    req(services.gods_trial.startup_payload(materialize_temporal=False) == {"auto_campaign": 310001, "auto_times": 3, "auto_start_time": 456}, "running MID3101 projection drift")
    req(commits == [], "read-only MID3101 projection unexpectedly committed")


def test_persistence_routing_and_composition_identity() -> None:
    p = player("166006")
    p.horcrux_state = HorcruxRepository.default_state()
    serialized = JsonPlayerDatabase.serialize_player(p)
    req("horcrux_state" in serialized.get("domains", {}), "horcrux_state did not route to player.domains")
    req("horcrux" not in serialized, "parallel player.horcrux persistence section introduced")
    services = RequestServices(p, DATA, lambda: None, catalog=GAME)
    req(services.horcrux_repository.source is services.horcrux_source, "Horcrux repository/source split")
    req(services.horcrux_repository.heroes is services.heroes, "Horcrux repository/Hero authority split")
    req(services.horcrux_repository.uow is services.uow, "Horcrux repository/UoW split")
    req(services.horcrux.repository is services.horcrux_repository, "Horcrux service/repository split")
    req(services.horcrux.heroes is services.heroes, "Horcrux service/Hero authority split")
    req(services.gods_trial.repository is services.horcrux_repository, "Gods Trial/repository split")
    req(services.gods_trial.temporal is services.temporal, "Gods Trial/Temporal authority split")
    req(services.gods_trial.uow is services.uow, "Gods Trial/UoW split")



def test_durable_load_migration_roundtrip() -> None:
    with tempfile.TemporaryDirectory() as td:
        db = MultiUserDatabase(Path(td) / "server_state", DATA)
        p = player("166007")
        p.spirit_list = [{"spirit_id": 40, "table_id": 250000111, "is_equip": 0, "collo_count": 8}]
        p.heroes = {"90001": {"partner_id": 90001, "table_id": 10001001, "star": 5, "spirit_equip": [40]}}
        p.horcrux_state = {"next_spirit_id": 1, "collocations": {}}
        req(db.normalize_player(p, persist=False), "H1 durable normalizer reported no migration")
        req(p.horcrux_state["next_spirit_id"] == 41, "durable migration did not repair allocator")
        req(p.heroes["90001"]["spirit_equip"] == [40, 0, 0, 0, 0, 0], "durable migration did not normalize six slots")
        req(p.spirit_list[0]["is_equip"] == 90001, "durable migration did not rebuild equip owner mirror")
        db.save_player(p)
        loaded = db.load_player(p.player_id)
        req(loaded is not None, "saved H1 player did not reload")
        req(loaded.horcrux_state["next_spirit_id"] == 41, "horcrux_state did not persist under MultiUserDatabase")
        req(loaded.heroes["90001"]["spirit_equip"] == [40, 0, 0, 0, 0, 0], "six-slot state changed across reload")
        req(loaded.spirit_list[0]["is_equip"] == 90001, "instance equip owner mirror changed across reload")

def main() -> None:
    tests = [
        test_source_catalog_and_policy_separation,
        test_six_slot_hero_normalization_does_not_create_instances,
        test_allocator_repair_and_uow_rollback_nonreuse,
        test_equip_mirror_reconciliation,
        test_collocation_count_rebuild,
        test_legacy_hunqi_stub_is_not_authority_and_mid3101_shape,
        test_persistence_routing_and_composition_identity,
        test_durable_load_migration_roundtrip,
    ]
    for test in tests:
        test()
        print("PASS", test.__name__)
    print(f"PASS Pass166 H1 Horcrux foundation ({len(tests)}/{len(tests)})")


if __name__ == "__main__":
    main()
