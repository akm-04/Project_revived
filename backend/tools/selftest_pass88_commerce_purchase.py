#!/usr/bin/env python3
"""Pass88 focused exactly-once Commerce purchase self-test."""
from __future__ import annotations

import copy
import tempfile
from pathlib import Path

from gxb_backend.content.recharge_catalog import RechargeSourceCatalog
from gxb_backend.state.account import AccountIdentity
from gxb_backend.state.commerce_purchase import (
    CommerceSettlementService,
    PurchaseReceiptConflict,
    UnsupportedPurchaseProduct,
)
from gxb_backend.state.commerce_service import CommerceEntitlementService
from gxb_backend.state.economy_ledger import EconomyLedger
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.resource_registry import ResourceRegistry
from gxb_backend.state.server_clock import ServerClock
from gxb_backend.state.unit_of_work import UnitOfWork
from gxb_backend.state.vip_policy import VipProgressionPolicy

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def check(name, condition, details=None):
    if not condition:
        raise AssertionError(f"{name}: {details or {}}")
    return {"name": name, "status": "PASS", "details": details or {}}


class FixedClock(ServerClock):
    def __init__(self, now_value: int):
        self.now_value = int(now_value)
    def now(self) -> int:
        return self.now_value


def build(player: PlayerState, save, now=1788000000):
    vip = VipProgressionPolicy(DATA)
    source = RechargeSourceCatalog(DATA)
    uow = UnitOfWork(player, save)
    ent = CommerceEntitlementService(player, vip, uow=uow)
    ledger = EconomyLedger(player, ResourceRegistry.load(DATA / "resource_registry.json"), uow=uow)
    svc = CommerceSettlementService(
        player, source, ent, ledger, vip, uow, clock=FixedClock(now)
    )
    return vip, source, uow, ent, ledger, svc


def main():
    checks = []
    saves = []
    p = PlayerState(
        account_uid="commerce_lab", player_id="880001", region=125,
        vip=0, charge=0, crystal=0,
    )
    _, _, uow, ent, _, svc = build(p, lambda: saves.append(copy.deepcopy(vars(p))))

    first = svc.settle({
        "intent_id": "p88-first-100", "charge_id": 80001007, "platform": "preservation_manual"
    })
    checks.append(check(
        "first_buy_atomic_source_shaped",
        first.status == "COMMITTED" and not first.replayed
        and p.crystal == 200 and p.charge == 100 and p.vip == 1
        and ent.product_history(80001007)["charge_count"] == 1
        and first.recharge_event["mid"] == 36857
        and first.recharge_event["params"]["delta"] == 200
        and first.recharge_event["params"]["total"] == 200
        and first.recharge_event["params"]["vip"] == 1
        and first.recharge_event["params"]["charge"] == 100,
        {"event": first.recharge_event, "history": ent.product_history(80001007)},
    ))
    version_after_first = uow.current_state_version
    receipt = uow.get_receipt("commerce_purchase", "p88-first-100")
    outbox = p.commerce_state.get("completion_outbox", {}).get("p88-first-100")
    checks.append(check(
        "permanent_receipt_and_outbox_committed",
        isinstance(receipt, dict) and receipt.get("status") == "COMMITTED"
        and receipt.get("retention_policy") == "PERMANENT_NO_EVICTION"
        and isinstance(outbox, dict) and outbox.get("status") == "COMMITTED_AVAILABLE",
    ))

    replay = svc.settle({
        "intent_id": "p88-first-100", "charge_id": 80001007, "platform": "preservation_manual"
    })
    checks.append(check(
        "same_intent_retry_exactly_once",
        replay.status == "REPLAYED" and replay.replayed
        and p.crystal == 200 and p.charge == 100 and p.vip == 1
        and ent.product_history(80001007)["charge_count"] == 1
        and uow.current_state_version == version_after_first
        and replay.recharge_event == first.recharge_event,
    ))

    second = svc.settle({
        "intent_id": "p88-second-100", "charge_id": 80001007, "platform": "preservation_manual"
    })
    checks.append(check(
        "repeat_buy_no_first_bonus",
        p.crystal == 300 and p.charge == 200 and p.vip == 1
        and second.settlement["crystal_delta"] == 100
        and second.settlement["first_purchase"] == 0
        and ent.product_history(80001007)["charge_count"] == 2,
    ))
    third = svc.settle({
        "intent_id": "p88-third-100", "charge_id": 80001007, "platform": "preservation_manual"
    })
    checks.append(check(
        "cumulative_charge_derives_vip2",
        p.crystal == 400 and p.charge == 300 and p.vip == 2
        and third.recharge_event["params"]["vip"] == 2,
    ))

    try:
        svc.settle({
            "intent_id": "p88-first-100", "charge_id": 80001006, "platform": "preservation_manual"
        })
        conflict = False
    except PurchaseReceiptConflict:
        conflict = True
    checks.append(check("intent_reuse_with_different_sku_rejected", conflict and p.crystal == 400))

    try:
        svc.settle({
            "intent_id": "p88-bad-sku", "charge_id": 123456, "platform": "preservation_manual"
        })
        unsupported = False
    except UnsupportedPurchaseProduct:
        unsupported = True
    checks.append(check("unadvertised_sku_rejected", unsupported and p.crystal == 400))

    try:
        svc.settle({
            "intent_id": "p88-ios-hidden", "charge_id": 80001030, "platform": "ios"
        })
        ios_hidden = False
    except UnsupportedPurchaseProduct:
        ios_hidden = True
    checks.append(check("ios_30000_pack_source_hidden", ios_hidden and p.crystal == 400))

    # Durable JSON roundtrip preserves receipt, history and completion outbox.
    with tempfile.TemporaryDirectory(prefix="pass88_db_") as td:
        path = Path(td) / "player.json"
        db = JsonPlayerDatabase(path)
        account = AccountIdentity(uid=p.account_uid, token="tok")
        db.save(account, p)
        _, loaded = db.load(account, PlayerState(account_uid=p.account_uid, player_id=p.player_id, region=125))
        checks.append(check(
            "purchase_state_persistence_roundtrip",
            loaded.crystal == 400 and loaded.charge == 300 and loaded.vip == 2
            and loaded.commerce_state.get("products", {}).get("80001007", {}).get("charge_count") == 3
            and "p88-first-100" in loaded.commerce_state.get("completion_outbox", {})
            and "p88-first-100" in loaded.persistence_state.get("receipts", {}).get("commerce_purchase", {}),
        ))

    # Commit failure must restore every mutable plane and leave no receipt/outbox.
    q = PlayerState(account_uid="rollback", player_id="880002", region=125, vip=0, charge=0, crystal=5)
    def fail_save():
        raise OSError("simulated durable write failure")
    _, _, q_uow, q_ent, _, q_svc = build(q, fail_save, now=1788001234)
    before = copy.deepcopy(vars(q))
    try:
        q_svc.settle({
            "intent_id": "p88-rollback", "charge_id": 80001007, "platform": "preservation_manual"
        })
        rolled_back = False
    except OSError:
        rolled_back = True
    checks.append(check(
        "commit_failure_rolls_back_all_planes",
        rolled_back and q.crystal == before["crystal"] and q.charge == before["charge"]
        and q.vip == before["vip"] and q.commerce_state == before["commerce_state"]
        and q_uow.get_receipt("commerce_purchase", "p88-rollback") is None,
    ))

    # Sandbox coherent VIP15 remains capped while cumulative charge can increase.
    s = PlayerState(account_uid="13371337", player_id="12525385", region=125, vip=15, charge=500000, crystal=1000)
    _, _, _, s_ent, _, s_svc = build(s, lambda: None)
    large = s_svc.settle({
        "intent_id": "p88-vip15", "charge_id": 80001002, "platform": "preservation_manual"
    })
    checks.append(check(
        "vip15_purchase_stays_capped",
        s.vip == 15 and s.charge == 510000 and s.crystal == 21000
        and large.settlement["crystal_delta"] == 20000
        and s_ent.product_history(80001002)["charge_count"] == 1,
    ))

    print({"pass": "88.0", "status": "PASS", "checks": checks})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
