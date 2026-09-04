from __future__ import annotations

import copy
import json
from pathlib import Path

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.state.mutation_plan import (
    ActorRef,
    IdempotencySpec,
    MutationOrigin,
    MutationPlan,
    StackMutation,
    TemporalTransition,
)
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.projection_profiles import ProjectionProfileRegistry
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.response_projector import ResponseProjector
from gxb_backend.state.server_clock import ServerClock
from gxb_backend.state.temporal_policy_service import TemporalPolicyUnavailable
from gxb_backend.state.unit_of_work import OperationContext

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def require(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def make_services(now: int = 2201) -> tuple[PlayerState, RequestServices, list[int]]:
    player = PlayerState(player_id="990710", account_uid="990710", player_name="Pass71")
    commits: list[int] = []

    def commit() -> None:
        commits.append(int(player.persistence_state.get("state_version", -1)))

    services = RequestServices(player, DATA, commit, catalog=CATALOG)
    services.server_clock = ServerClock(lambda: now)
    services.temporal.clock = services.server_clock
    return player, services, commits


def settle(services: RequestServices, plan_id: str, operations, mid: int = 27) -> None:
    plan = MutationPlan(
        schema_version=1,
        plan_id=plan_id,
        origin=MutationOrigin("selftest", plan_id, protocol_mid=mid),
        actor=ActorRef(str(services.player.player_id), str(services.player.account_uid)),
        expected_state_version=services.uow.current_state_version,
        idempotency=IdempotencySpec(mode="NONE"),
        preconditions=(),
        operations=tuple(operations),
    )
    with services.uow.transaction(OperationContext(
        actor_player_id=str(services.player.player_id),
        domain="selftest",
        operation_name=plan_id,
        protocol_mid=mid,
        server_time=services.server_clock.now(),
    )):
        services.mutation_settlement.apply(plan)


def main() -> None:
    player, services, commits = make_services(2201)
    temporal = services.temporal

    # 1) Energy: whole intervals only; partial interval is preserved.
    player.lev = 1
    player.energy = 50
    player.energy_time = 1000
    change = temporal.materialize("energy")
    require(change.after.natural_cap == 60, "level-derived Energy cap drift")
    require(player.energy == 54 and player.energy_time == 2200, "Energy offline catch-up mismatch")

    # 2) Spirit Energy: fixed source cap=180 and 360-second cadence.
    services.server_clock = ServerClock(lambda: 1800)
    temporal.clock = services.server_clock
    player.spirit_energy = 178
    player.spirit_energy_time = 1000
    spirit = temporal.materialize("spirit_energy")
    require(spirit.after.natural_cap == 180, "Spirit Energy cap drift")
    require(player.spirit_energy == 180 and player.spirit_energy_time == 0, "Spirit catch-up/cap sentinel mismatch")

    # 3) Skill Point: VIP + monthly privilege cap and zero full-pool sentinel.
    services.server_clock = ServerClock(lambda: 1601)
    temporal.clock = services.server_clock
    player.vip = 15
    player.privilege_left_card_day = 1
    player.skill_point = 88
    player.skill_time = 1000
    skill = temporal.materialize("skill_point")
    require(skill.after.natural_cap == 90, "Skill Point VIP/monthly cap mismatch")
    require(player.skill_point == 90 and player.skill_time == 0, "Skill Point catch-up mismatch")

    # 4) Natural caps stop regeneration but never clamp explicit grants.
    services.server_clock = ServerClock(lambda: 1300)
    temporal.clock = services.server_clock
    player.energy = 59
    player.energy_time = 1000
    granted = temporal.credit("energy", 6)
    require(player.energy == 66 and player.energy_time == 0, "Energy grant was incorrectly hard-capped")
    services.server_clock = ServerClock(lambda: 1400)
    temporal.clock = services.server_clock
    spent = temporal.debit("energy", 10)
    require(player.energy == 56 and player.energy_time == 1400, "Energy debit did not rearm below-cap timer")
    require(granted.after.balance == 66 and spent.after.balance == 56, "temporal change summaries drifted")

    # 5) Invitation remains explicitly fail-closed due effective-source drift.
    try:
        temporal.materialize("invitation")
    except TemporalPolicyUnavailable:
        invitation_fail_closed = True
    else:
        invitation_fail_closed = False
    require(invitation_fail_closed, "Arena Invitation source drift was accidentally activated")
    require(not temporal.projection_allowed("invitation"), "Invitation projection should remain suppressed")

    # 6) TEMPORAL MutationPlan rows commit and Pass70 projects cumulative state.
    services.server_clock = ServerClock(lambda: 2201)
    temporal.clock = services.server_clock
    player.energy = 50
    player.energy_time = 2000
    projector = ResponseProjector.capture(player, resource_registry=services.resource_registry)
    version_before = services.uow.current_state_version
    settle(services, "temporal-energy-debit", (TemporalTransition("energy", "DEBIT", 3),))
    require(services.uow.current_state_version == version_before + 1, "pure TEMPORAL plan did not commit state_version")
    journal = services.uow.consume_journal()
    require(any(row.get("category") == "TEMPORAL" for row in journal), "committed TEMPORAL journal row missing")
    profiles = ProjectionProfileRegistry.load(DATA / "projection_profile_registry.json")
    projected = projector.project({}, player, committed_journal=journal, profile=profiles.get("WEB_GLOBAL_ENVELOPE"))
    require(projected.get("economy_", {}).get("energy") == player.energy == 47, "TEMPORAL projector did not emit cumulative Energy")
    require(set(projected["economy_"]) == {"energy"}, "TEMPORAL projection fabricated unrelated economy fields")

    # 7) Mixed STACK + TEMPORAL plan is atomic; item grants can exceed natural cap.
    fries = CATALOG.get(ContentRef(CatalogNamespace.ITEM, 50001014))
    require(int(fries.get("energy", 0) or 0) == 6, "source catalog Fries Energy value drift")
    player.backpack_items = [{"table_id": 50001014, "item_num": 2, "time": 0}]
    player.energy = 59
    player.energy_time = 0
    settle(services, "energy-item-shape", (
        StackMutation(50001014, "DEBIT", 2),
        TemporalTransition("energy", "CREDIT", 12),
    ))
    require(services.inventory.get_item_num(50001014) == 0, "energy item stack debit failed")
    require(player.energy == 71 and player.energy_time == 0, "energy item TEMPORAL credit was hard-capped")
    mixed_journal = services.uow.consume_journal()
    require([row.get("category") for row in mixed_journal] == ["STACK", "TEMPORAL"], "mixed temporal journal shape drift")

    # 8) UoW rollback restores both amount/anchor and hides staged temporal journal.
    snapshot = copy.deepcopy(vars(player))
    try:
        plan = MutationPlan(
            schema_version=1,
            plan_id="temporal-rollback",
            origin=MutationOrigin("selftest", "temporal-rollback"),
            actor=ActorRef(str(player.player_id)),
            expected_state_version=services.uow.current_state_version,
            idempotency=IdempotencySpec(),
            preconditions=(),
            operations=(TemporalTransition("energy", "DEBIT", 1),),
        )
        with services.uow.transaction(OperationContext(
            actor_player_id=str(player.player_id), domain="selftest", operation_name="temporal-rollback"
        )):
            services.mutation_settlement.apply(plan)
            raise RuntimeError("force rollback")
    except RuntimeError:
        pass
    require(vars(player) == snapshot, "TEMPORAL rollback failed to restore PlayerState")
    require(services.uow.consume_journal() == [], "rolled-back TEMPORAL journal leaked")

    # 9) MID17 anchor projection preserves the source zero sentinel.
    player.energy = 60
    player.energy_time = 0
    player.spirit_energy = 180
    player.spirit_energy_time = 0
    payload = player.player_info_payload()
    require(payload["energy_time"] == 0 and payload["spirit_energy_time"] == 0, "MID17 fabricated active anchors at natural cap")

    report = {
        "pass": "71.0",
        "status": "PASS",
        "source_policies": {
            "energy": {"interval_seconds": 300, "level1_cap": 60},
            "spirit_energy": {"interval_seconds": 360, "natural_cap": 180},
            "skill_point": {"interval_seconds": 300, "vip15_monthly_cap": 90},
            "invitation": {"interval_seconds": 1800, "enabled": False, "projection": "SUPPRESSED"},
        },
        "whole_interval_offline_catchup": True,
        "partial_interval_preserved": True,
        "natural_cap_not_hard_ceiling": True,
        "below_cap_debit_rearms_timer": True,
        "temporal_mutation_plan_journal": True,
        "cumulative_response_projection": True,
        "mixed_stack_temporal_atomic": True,
        "rollback_journal_silent": True,
        "mid17_zero_anchor_sentinel": True,
        "commit_callbacks": len(commits),
    }
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
