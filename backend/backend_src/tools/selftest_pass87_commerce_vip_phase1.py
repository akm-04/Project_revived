#!/usr/bin/env python3
"""Pass87 focused Commerce/VIP Phase 1 self-test."""
from __future__ import annotations

import copy
import json
import shutil
import tempfile
from pathlib import Path

from gxb_backend.content.recharge_catalog import RechargeSourceCatalog
from gxb_backend.handlers.context import HandlerContext
from gxb_backend.handlers.system import SystemHandlers
from gxb_backend.config import Settings
from gxb_backend.state.commerce_service import (
    CommerceEntitlementService,
    PASS87_SANDBOX_MIGRATION,
    RechargeCatalogService,
)
from gxb_backend.state.multiuser_database import SANDBOX_SID
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.repository import StateRepository
from gxb_backend.state.server_clock import ServerClock
from gxb_backend.state.skill_point_policy import SkillPointPolicy
from gxb_backend.state.temporal_policy_service import TemporalPolicyService
from gxb_backend.state.vip_policy import VipPrivilegeResolver, VipProgressionPolicy

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
EXPECTED_IDS = (80001002, 80001003, 80001004, 80001005, 80001006, 80001007, 80001030)
EXPECTED_THRESHOLDS = {
    0: 0, 1: 30, 2: 300, 3: 900, 4: 1500, 5: 3000, 6: 6000, 7: 9000,
    8: 15000, 9: 20000, 10: 30000, 11: 45000, 12: 60000, 13: 100000,
    14: 250000, 15: 500000,
}


def check(name: str, condition: bool, details: dict | None = None) -> dict:
    if not condition:
        raise AssertionError(f"{name}: {details or {}}")
    return {"name": name, "status": "PASS", "details": details or {}}


def main() -> int:
    checks = []
    vip_policy = VipProgressionPolicy(DATA)
    catalog = RechargeSourceCatalog(DATA)

    checks.append(check(
        "source_vip_thresholds_exact",
        all(vip_policy.threshold(level) == threshold for level, threshold in EXPECTED_THRESHOLDS.items()),
        {"thresholds": EXPECTED_THRESHOLDS},
    ))
    boundary_cases = {
        0: 0, 29: 0, 30: 1, 299: 1, 300: 2, 899: 2, 900: 3,
        499999: 14, 500000: 15, 999999999: 15,
    }
    checks.append(check(
        "charge_derives_vip_boundary_exact",
        all(vip_policy.derive_vip(charge) == level for charge, level in boundary_cases.items()),
        {"cases": boundary_cases},
    ))
    checks.append(check(
        "direct_crystal_catalog_exact",
        catalog.advertised_ids() == EXPECTED_IDS,
        {"ids": list(catalog.advertised_ids())},
    ))
    p100 = catalog.require(80001007)
    p10000 = catalog.require(80001002)
    p30000 = catalog.require(80001030)
    checks.append(check(
        "direct_product_source_values",
        (p100.base_crystal, p100.first_extra_crystal, p10000.base_crystal,
         p10000.first_extra_crystal, p30000.base_crystal, p30000.first_extra_crystal)
        == (100, 100, 10000, 10000, 30000, 3000),
    ))

    # Central policy facade representative facts recovered from vip.lua.
    player = PlayerState(vip=2, charge=300)
    resolver = VipPrivilegeResolver(player, vip_policy)
    checks.append(check(
        "vip_privilege_resolver_representative",
        resolver.daily_sweep_card_quantity() == 30
        and resolver.super_campaign_paid_reset_limit() == 1
        and resolver.skill_point_purchase_enabled()
        and resolver.skill_point_natural_cap() == 10
        and resolver.meets_level(2)
        and not resolver.meets_level(3),
        {"vip": resolver.level()},
    ))

    # Existing Skill Point policy must now consume the central resolver, not the
    # legacy generated vip_skill_* maps. Mutate only a copied metadata file to
    # make drift observable.
    with tempfile.TemporaryDirectory(prefix="pass87_skill_") as td:
        td = Path(td)
        for name in ("hero_skill_regen_meta.json", "vip_source_meta.json"):
            shutil.copy2(DATA / name, td / name)
        drift = json.loads((td / "hero_skill_regen_meta.json").read_text())
        drift["vip_skill_max"]["2"] = 999
        drift["vip_skill_buy"]["2"] = 0
        (td / "hero_skill_regen_meta.json").write_text(json.dumps(drift), encoding="utf-8")
        skill = SkillPointPolicy(player, td)
        checks.append(check(
            "skill_policy_autowired_to_vip_resolver",
            skill.max_points() == 10 and skill.can_buy() is True,
            {"max_points": skill.max_points(), "can_buy": skill.can_buy()},
        ))

    # Sandbox migration must be a pure state normalization, idempotent and
    # preserve first-buy history as unused.
    legacy = PlayerState(account_uid="13371337", vip=15, charge=0, crystal=777777)
    entitlements = CommerceEntitlementService(legacy, vip_policy)
    before_crystal = legacy.crystal
    first_changed = entitlements.maintenance_normalize()
    second_changed = entitlements.maintenance_normalize()
    marker = legacy.commerce_state.get("migrations", {}).get(PASS87_SANDBOX_MIGRATION)
    checks.append(check(
        "sandbox_vip15_charge0_normalization",
        first_changed and not second_changed and legacy.vip == 15 and legacy.charge == 500000
        and legacy.crystal == before_crystal and legacy.commerce_state.get("products") == {}
        and isinstance(marker, dict) and marker.get("classification") == "STATE_NORMALIZATION_NOT_PURCHASE",
        {"vip": legacy.vip, "charge": legacy.charge, "crystal": legacy.crystal, "marker": marker},
    ))

    # MID354 read model starts every unpurchased direct product at 0/0 and uses
    # one server clock authority.
    class FixedClock(ServerClock):
        def now(self) -> int:
            return 1788000000
    service = RechargeCatalogService(legacy, catalog, entitlements, clock=FixedClock())
    q = service.query_charge_data()
    checks.append(check(
        "mid354_projection_contract",
        tuple(row["charge_id"] for row in q["charges"]) == EXPECTED_IDS
        and all(row["charge_count"] == 0 and row["last_buy_time"] == 0 for row in q["charges"])
        and q["giftbags"] == [] and q["server_time"] == 1788000000,
        {"charge_count": len(q["charges"]), "server_time": q["server_time"]},
    ))

    # Persistence round-trip: commerce_state is server-only under domains and
    # history survives exactly without entering player_info wire projection.
    with tempfile.TemporaryDirectory(prefix="pass87_persist_") as td:
        path = Path(td) / "player.json"
        from gxb_backend.state.defaults import default_account
        acct = default_account()
        legacy.commerce_state["products"]["80001007"] = {"charge_count": 2, "last_buy_time": 12345}
        db = JsonPlayerDatabase(path)
        db.save(acct, legacy)
        _, loaded = db.load(acct, PlayerState())
        wire = loaded.player_info_payload()
        checks.append(check(
            "commerce_state_persistence_roundtrip",
            loaded.commerce_state["products"]["80001007"] == {"charge_count": 2, "last_buy_time": 12345}
            and "commerce_state" not in wire and wire["vip"] == 15 and wire["charge"] == 500000,
        ))

    # Full repository import proves the packaged legacy singleton is normalized
    # once at the actual multi-user migration boundary and SystemHandlers MID354
    # reads the request-scoped canonical service graph.
    with tempfile.TemporaryDirectory(prefix="pass87_repo_") as td:
        td = Path(td)
        data_copy = td / "data"
        shutil.copytree(DATA, data_copy)
        repo = StateRepository(
            path=data_copy / "player_db.json",
            profile="established",
            multiuser_root=data_copy / "server_state",
            server_clock=FixedClock(),
        )
        sandbox = repo.store.sandbox_player()
        checks.append(check(
            "repository_import_executes_sandbox_normalization",
            sandbox.vip == 15 and sandbox.charge == 500000
            and sandbox.commerce_state.get("migrations", {}).get(PASS87_SANDBOX_MIGRATION, {}).get("applied") == 1,
        ))
        req = {"mid": 354, "sid": SANDBOX_SID, "region": 125}
        with repo.request_scope(req):
            ctx = HandlerContext(state=repo, settings=Settings())
            response = SystemHandlers(ctx).query_charge_data(req)
        checks.append(check(
            "system_mid354_uses_recharge_catalog_service",
            tuple(row["charge_id"] for row in response["charges"]) == EXPECTED_IDS
            and response["server_time"] == 1788000000,
        ))

    report = {
        "pass": "87.0",
        "status": "PASS",
        "checks": checks,
        "direct_crystal_ids": list(EXPECTED_IDS),
        "backend_phase": "Commerce/VIP Phase 1; purchase intent/settlement deferred",
    }
    out = ROOT / "docs/PASS87_COMMERCE_VIP_PHASE1_SELFTEST.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
