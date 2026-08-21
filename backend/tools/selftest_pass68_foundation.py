#!/usr/bin/env python3
"""Pass68 foundation characterization: persistence/UoW/ResourceRegistry."""
from __future__ import annotations

import json
import tempfile
from pathlib import Path

from gxb_backend.content.game_data_catalog import GameDataCatalog
from gxb_backend.state.defaults import default_account, default_player
from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.persistence_state import ensure_persistence_state
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.resource_registry import ResourceRegistry, ResourceRegistryError
from gxb_backend.state.unit_of_work import OperationContext, PlayerUnitOfWork, StateVersionConflict

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def check_singleton_merge_and_uow(tmp: Path) -> dict[str, object]:
    path = tmp / "player_db.json"
    seed = {
        "_meta": {"schema": 4, "future_meta": {"keep": True}},
        "account": {"uid": "13371337", "future_account": "keep"},
        "future_root": {"keep": [1, 2, 3]},
        "player": {
            "economy": {"mana": 1000, "future_balance": 77},
            "domains": {
                "future_domain": {"opaque": "keep"},
                "persistence_state": {"future_persistence": "keep"},
            },
        },
    }
    path.write_text(json.dumps(seed, indent=2) + "\n", encoding="utf-8")
    db = JsonPlayerDatabase(path)
    account, player = db.load(default_account(), default_player())
    assert player.mana == 1000
    assert ensure_persistence_state(player)["state_version"] == 0
    db.save(account, player)
    after_save = json.loads(path.read_text(encoding="utf-8"))
    assert after_save["future_root"] == seed["future_root"]
    assert after_save["_meta"]["future_meta"] == {"keep": True}
    assert after_save["account"]["future_account"] == "keep"
    assert after_save["player"]["economy"]["future_balance"] == 77
    assert after_save["player"]["domains"]["future_domain"] == {"opaque": "keep"}
    assert after_save["player"]["domains"]["persistence_state"]["future_persistence"] == "keep"

    uow = PlayerUnitOfWork(player, lambda: db.save(account, player))
    with uow.transaction(OperationContext(
        actor_player_id=str(player.player_id),
        domain="pass68_selftest",
        operation_name="debit_mana",
        idempotency_key="receipt-1",
        idempotency_mode="DOMAIN_RECEIPT",
        expected_state_version=0,
        server_time=1_700_000_000,
    )):
        player.mana -= 25
        uow.touch_slice("scalar_economy")
        uow.stage_receipt(
            domain="pass68_selftest",
            operation="debit_mana",
            key="receipt-1",
            request_fingerprint="fp-a",
            replay_payload={"economy_": {"mana": player.mana}},
        )
        uow.request_save()

    state = ensure_persistence_state(player)
    assert state["state_version"] == 1
    assert state["slice_revisions"]["scalar_economy"] == 1
    receipt = state["receipts"]["pass68_selftest"]["receipt-1"]
    assert receipt["status"] == "COMMITTED"
    assert receipt["state_version_before"] == 0 and receipt["state_version_after"] == 1
    assert receipt["committed_at"] == 1_700_000_000
    persisted = json.loads(path.read_text(encoding="utf-8"))
    assert persisted["player"]["domains"]["persistence_state"]["state_version"] == 1
    assert persisted["player"]["domains"]["persistence_state"]["receipts"]["pass68_selftest"]["receipt-1"]["status"] == "COMMITTED"
    assert persisted["future_root"] == seed["future_root"]

    return {
        "unknown_extensions_preserved": True,
        "state_version": state["state_version"],
        "slice_revision": state["slice_revisions"]["scalar_economy"],
        "receipt_status": receipt["status"],
    }


def check_rollback() -> dict[str, object]:
    player = default_player()
    player.mana = 500
    ensure_persistence_state(player)

    def fail_commit() -> None:
        raise OSError("synthetic disk failure")

    uow = PlayerUnitOfWork(player, fail_commit)
    try:
        with uow.transaction(OperationContext(
            actor_player_id=str(player.player_id),
            domain="pass68_selftest",
            operation_name="rollback",
            server_time=1_700_000_001,
        )):
            player.mana = 1
            uow.stage_receipt(domain="pass68_selftest", operation="rollback", key="r2")
            uow.touch_slice("scalar_economy")
            uow.request_save()
    except OSError:
        pass
    else:
        raise AssertionError("synthetic commit failure did not escape")

    state = ensure_persistence_state(player)
    assert player.mana == 500
    assert state["state_version"] == 0
    assert not state["receipts"]
    assert not state["slice_revisions"]

    try:
        with uow.transaction(OperationContext(
            actor_player_id=str(player.player_id),
            domain="pass68_selftest",
            operation_name="version-conflict",
            expected_state_version=9,
        )):
            raise AssertionError("unreachable")
    except StateVersionConflict:
        pass
    else:
        raise AssertionError("state-version mismatch did not fail closed")

    return {"rollback_restored_state": True, "version_conflict_fail_closed": True}


def check_multiuser_merge(tmp: Path) -> dict[str, object]:
    db = MultiUserDatabase(tmp / "server_state", DATA)
    player = default_player()
    player.player_id = "12599999"
    player.account_uid = "99999"
    db.save_player(player)
    path = db.player_path(player.player_id)
    raw = json.loads(path.read_text(encoding="utf-8"))
    raw["future_root"] = {"multi": True}
    raw["player"].setdefault("domains", {})["future_multi_domain"] = {"keep": 42}
    path.write_text(json.dumps(raw, indent=2) + "\n", encoding="utf-8")
    loaded = db.load_player(player.player_id)
    assert loaded is not None
    loaded.crystal += 1
    db.save_player(loaded)
    final = json.loads(path.read_text(encoding="utf-8"))
    assert final["future_root"] == {"multi": True}
    assert final["player"]["domains"]["future_multi_domain"] == {"keep": 42}
    return {"unknown_extensions_preserved": True, "schema": final["_meta"]["schema"]}


def check_registry() -> dict[str, object]:
    registry = ResourceRegistry.load(DATA / "resource_registry.json")
    assert len(registry.all()) == 47
    assert len(registry.scalar_keys()) == 30
    for key in ("mana", "crystal", "energy", "exp", "lev"):
        registry.assert_legacy_economy_field(key)
    assert registry.require("daily_updates").mutation_capability == "CONTROL_ENVELOPE_ONLY"
    assert registry.require("point").mutation_capability == "FAIL_CLOSED"
    try:
        registry.require("not_a_real_resource")
    except ResourceRegistryError:
        pass
    else:
        raise AssertionError("unknown resource did not fail closed")
    return {
        "descriptors": 47,
        "scalar": 30,
        "regenerating": sorted(registry.REGENERATING_KEYS),
        "unknown_fail_closed": True,
    }


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="gxb-pass68-") as tmp_raw:
        tmp = Path(tmp_raw)
        report = {
            "pass": "68.0",
            "backend": "0.9.0",
            "status": "PASS",
            "singleton": check_singleton_merge_and_uow(tmp),
            "rollback": check_rollback(),
            "multiuser": check_multiuser_merge(tmp),
            "resource_registry": check_registry(),
        }
    out = ROOT / "docs" / "PASS68_FOUNDATION_SELFTEST.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
