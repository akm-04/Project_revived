#!/usr/bin/env python3
"""Pass94 Global Economy strangler closure self-test."""
from __future__ import annotations

import copy
import json
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.maintenance_services import PlayerMaintenanceServices
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.reward_transaction_service import EconomyGrant, RewardOrigin, RewardPlan
from gxb_backend.state.unit_of_work import OperationContext

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def fresh_player() -> PlayerState:
    return PlayerState(
        account_uid="pass94",
        player_id="19400001",
        lev=1,
        exp=0,
        max_lev=200,
        energy=60,
        max_energy=60,
        func_ids=[],
        function_state={},
    )


def services_for(player: PlayerState, commit_callback):
    return RequestServices(
        player,
        DATA,
        commit_callback,
        catalog=GameDataCatalog.load(DATA / "game_data_catalog.json"),
    )


def main() -> int:
    checks: list[dict] = []

    player = fresh_player()
    commits: list[dict] = []
    services = services_for(player, lambda: commits.append(copy.deepcopy(vars(player))))

    require(services.resource_registry.require("exp").owner_service == "PlayerProgressionService", "exp owner drift")
    require(services.resource_registry.require("lev").owner_service == "PlayerProgressionService", "lev owner drift")
    require(services.economy.progression is services.player_progression, "EconomyRepository does not delegate to canonical progression owner")
    require(services.rewards.progression is services.player_progression, "RewardTransactionService does not use canonical progression owner")
    require(services.economy.allow_legacy_direct_mutation is False, "live economy direct fallback is not fenced")
    require(services.player_progression.allow_legacy_direct_energy_mutation is False, "live progression energy fallback is not fenced")
    checks.append({"name": "owner_graph", "status": "PASS"})

    # src_64/player.lua levels 1..3 use cumulative thresholds 6/12/18 and
    # award_energy=6 each. 18 cumulative EXP therefore reaches level 4 and
    # credits 18 Energy; level 4 max Energy is 64.
    with services.uow.transaction(OperationContext(
        actor_player_id=str(player.player_id),
        domain="pass94_selftest",
        operation_name="reward_player_exp",
        server_time=1_700_000_094,
    )):
        result = services.rewards.apply(RewardPlan(
            origin=RewardOrigin("pass94_selftest", "player_exp"),
            economy=(EconomyGrant("player_exp", 18),),
        ))

    require(result.economy == {"exp": 18, "lev": 4, "energy": 78}, f"unexpected projection {result.economy}")
    require((player.exp, player.lev, player.energy, player.max_energy) == (18, 4, 78, 64), "source progression math drift")
    require(len(commits) == 1, "progression did not commit exactly once")
    progression_journal = [row for row in services.uow.consume_journal() if row.get("owner") == "PlayerProgressionService"]
    require(len(progression_journal) == 1, f"expected one progression journal row, got {progression_journal}")
    checks.append({
        "name": "source_progression_semantics",
        "status": "PASS",
        "projection": result.economy,
        "state": {"exp": player.exp, "lev": player.lev, "energy": player.energy, "max_energy": player.max_energy},
    })

    # The old public facade remains behavior-compatible but is no longer the
    # owner: its EXP method delegates to the exact same progression instance.
    with services.uow.transaction(OperationContext(
        actor_player_id=str(player.player_id),
        domain="pass94_selftest",
        operation_name="legacy_facade_delegate",
        server_time=1_700_000_095,
    )):
        compat = services.economy.grant_player_exp(6)
    require(compat.get("exp") == 24, f"legacy facade delegation failed: {compat}")
    require(player.exp == 24, "delegated EXP did not mutate canonical progression state")
    checks.append({"name": "compatibility_delegates_not_owns", "status": "PASS"})

    # Durable failure must roll back EXP, level, level-up Energy and Function
    # state together under the outer PlayerUnitOfWork.
    failing = fresh_player()
    failed_services = services_for(failing, lambda: (_ for _ in ()).throw(OSError("synthetic commit failure")))
    before = copy.deepcopy(vars(failing))
    raised = False
    try:
        with failed_services.uow.transaction(OperationContext(
            actor_player_id=str(failing.player_id),
            domain="pass94_selftest",
            operation_name="rollback_progression",
            server_time=1_700_000_096,
        )):
            failed_services.rewards.apply(RewardPlan(
                origin=RewardOrigin("pass94_selftest", "rollback"),
                economy=(EconomyGrant("player_exp", 18),),
            ))
    except OSError:
        raised = True
    require(raised, "synthetic commit failure did not escape")
    require(vars(failing) == before, "UoW did not roll back progression state")
    checks.append({"name": "durable_failure_atomic_rollback", "status": "PASS"})

    # Offline maintenance graph must also fence direct economy mutation because
    # it has no request-scoped Ledger/Temporal owners.
    maintenance_player = fresh_player()
    maintenance = PlayerMaintenanceServices(maintenance_player, DATA)
    require(maintenance.economy.allow_legacy_direct_mutation is False, "maintenance direct fallback not fenced")
    require(maintenance.player_progression.allow_legacy_direct_energy_mutation is False, "maintenance progression fallback not fenced")
    require(maintenance.economy.spend_mana(1) is False, "maintenance facade unexpectedly performed direct Mana mutation")
    require(maintenance_player.mana == fresh_player().mana, "maintenance Mana mutated")
    checks.append({"name": "maintenance_mutation_fence", "status": "PASS"})

    # Static ownership check: direct runtime Player exp/lev assignment belongs to
    # PlayerProgressionService. Profiles and migration normalization are seed/
    # hydration concerns and are intentionally outside this runtime mutation gate.
    offenders: list[str] = []
    state_root = ROOT / "gxb_backend" / "state"
    for path in state_root.glob("*.py"):
        if path.name in {"player_progression_service.py", "profiles.py", "multiuser_database.py"}:
            continue
        text = path.read_text(encoding="utf-8")
        if "self.player.exp =" in text or "self.player.lev =" in text:
            offenders.append(path.name)
    require(not offenders, f"direct progression writes remain: {offenders}")
    checks.append({"name": "no_runtime_dual_progression_owner", "status": "PASS"})

    report = {
        "pass": "94.0",
        "backend": "0.12.0",
        "status": "PASS",
        "checks": checks,
    }
    out = ROOT / "docs" / "PASS94_PLAYER_PROGRESSION_SELFTEST.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
