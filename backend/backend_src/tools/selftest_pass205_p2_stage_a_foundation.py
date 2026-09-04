#!/usr/bin/env python3
"""Pass205 P2 Stage A foundation characterization and invariants."""
from __future__ import annotations

import copy
import json
import tempfile
from dataclasses import replace
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.awakening_source_catalog import AwakeningSourceCatalog
from gxb_backend.state.awakening_projection_builder import AwakeningProjectionBuilder
from gxb_backend.state.awakening_state_v2 import AwakeningStateV2
from gxb_backend.state.derived_mutation_rules import DerivedMutationRuleRegistry
from gxb_backend.state.mutation_plan import ActorRef, IdempotencySpec, MutationOrigin, MutationPlan
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.unit_of_work import OperationContext, PlayerUnitOfWork

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def req(cond, message):
    if not cond:
        raise AssertionError(message)


def hero(pid=205001, tid=10001001):
    return {
        "partner_id": pid, "table_id": tid, "star": 5, "lev": 100, "exp": 0,
        "color": 15, "skills": [1] * 6, "equips": [1] * 6, "fumos": [0] * 6,
        "fumo_levels": [0] * 6, "element_equips": [0] * 4, "element_levels": [0] * 4,
        "element_bak_equips": [], "element_bak_levels": [], "inscript_items": [],
        "twice_awake_stage": 0,
    }


def test_source_catalog():
    source = AwakeningSourceCatalog(DATA)
    req(source.counts["ordinary_rows"] == 465 and source.counts["blood_rows"] == 162, "source census")
    req(source.counts["ordinary_route_campaign"] == 131, "ordinary campaign census")
    req(source.counts["ordinary_route_occult"] == 22, "ordinary occult census")
    req(source.counts["ordinary_route_event_outlier"] == 11, "ordinary event census")
    req(source.counts["blood_route_campaign"] == 74 and source.counts["blood_route_event_outlier"] == 7, "blood census")
    req(source.stage1_route(1001001, 1)["route_class"] == "CAMPAIGN", "ordinary route")
    req(source.stage1_route(2001001, 2)["route_class"] == "CAMPAIGN", "blood route")
    # Recursive immutability: nested source vectors must not be writable.
    row = source.mission(1001001, 1)
    try:
        row["delete_items"].append(999)  # tuple has no append
        raise AssertionError("nested source authority remained mutable")
    except (AttributeError, TypeError):
        pass
    try:
        row["stage"] = 99
        raise AssertionError("source row remained mutable")
    except TypeError:
        pass


def test_state_v2_and_replay():
    player = PlayerState(player_id="205001", account_uid="205001")
    player.awakening_state = {
        "schema_version": 1,
        "active": {"1": {"mission_id": 1001001, "awake_type": 1, "stage": 1, "complete": True}},
        "future_extension": {"keep": True},
    }
    commits = []
    uow = PlayerUnitOfWork(player, lambda: commits.append(1))
    state = AwakeningStateV2(player, uow)
    root, changed = state.normalize()
    req(changed and root["schema_version"] == 2, "v1 migration")
    req(root["active"]["1"]["generation"] == 1 and root["next_generation"]["1"] == 2, "generation migration")
    req(root["future_extension"] == {"keep": True}, "unknown root extension")

    with uow.transaction(OperationContext(actor_player_id=player.player_id, domain="test", operation_name="generation")):
        gen = state.allocate_generation(1)
        req(gen == 2, "generation allocation")
        state.remember_transition(
            awake_type=1, generation=gen, mission_id=1001001, operation="claim_stage1",
            request_fingerprint="abc", replay_payload={"awake_mission_": [{"table_id": 1001003}]},
        )
    replay = state.find_replay(
        awake_type=1, generation=2, mission_id=1001001, operation="claim_stage1", request_fingerprint="abc"
    )
    req(replay == {"awake_mission_": [{"table_id": 1001003}]}, "transition replay")
    req(commits == [1], "generation/replay single transaction commit")

    # Rollback must restore the complete aggregate, including generation counters.
    before = copy.deepcopy(player.awakening_state)
    try:
        with uow.transaction(OperationContext(actor_player_id=player.player_id, domain="test", operation_name="rollback")):
            state.allocate_generation(1)
            raise RuntimeError("rollback")
    except RuntimeError:
        pass
    req(player.awakening_state == before, "awakening aggregate rollback")


def test_canonical_replacement():
    existing = {
        "player": {
            "domains": {
                "awakening_state": {"schema_version": 1, "active": {"1": {"stale": True}}, "ghost": 1},
                "occult_state": {"stale": {"nested": True}},
                "future_domain": {"keep": True},
            }
        }
    }
    canonical = {
        "player": {
            "domains": {
                "awakening_state": {"schema_version": 2, "active": {}},
                "occult_state": {},
                "future_domain": {"new": 2},
            }
        }
    }
    merged = JsonPlayerDatabase.merge_preserving_extensions(existing, canonical)
    req(merged["player"]["domains"]["awakening_state"] == canonical["player"]["domains"]["awakening_state"], "awakening replacement")
    req(merged["player"]["domains"]["occult_state"] == {}, "occult replacement")
    req(merged["player"]["domains"]["future_domain"] == {"keep": True, "new": 2}, "extension preservation")


def test_projection_shapes():
    b = AwakeningProjectionBuilder()
    rec = {"mission_id": 2001001, "awake_type": 2, "complete": True, "count": 1}
    req(b.mission_delta(2, [rec]) == {"twice_awake_mission_": [{
        "table_id": 2001001, "awake_type": 2, "is_going": 1, "is_complete": 1,
        "is_open": 1, "is_reward": 0, "count": 1,
    }]}, "blood task projection")
    req(b.twice_awake_stage(table_id=11001001, stage=2) == {"twice_awake_stage_": {"table_id": 11001001, "stage": 2}}, "blood stage projection")
    req(b.extra_drops([{"item_id": 50005001, "item_num": 1}]) == {"extra_drops_": [{"item_id": 50005001, "item_num": 1}]}, "extra drops projection")


def test_derived_registry_and_composition_root():
    p = PlayerState(player_id="205002", account_uid="205002")
    commits = []
    services = RequestServices(p, DATA, lambda: commits.append(1), catalog=CATALOG)
    req(services.derived_mutation_rules.names == (), "Stage A must register zero derived rules")
    req(services.mutation_settlement.derived_rules is services.derived_mutation_rules, "settlement registry identity")
    req(services.awakening_missions.source is services.awakening_source, "source catalog composition")
    req(services.awakening_missions.projection is services.awakening_projection, "projection composition")
    req(services.awakening_source.counts["ordinary_stage1"] == 164, "composition source readiness")

    plan = MutationPlan(
        schema_version=1, plan_id="noop", origin=MutationOrigin(domain="test", operation="noop"),
        actor=ActorRef(player_id=p.player_id), expected_state_version=None,
        idempotency=IdempotencySpec(), preconditions=(), operations=(),
    )
    req(services.derived_mutation_rules.augment(plan, player=p, uow=services.uow) is plan, "empty registry must preserve plan identity")

    class BadRule:
        name = "bad"
        def augment(self, plan, context):
            context.player.crystal += 1
            return replace(plan)
    reg = DerivedMutationRuleRegistry(); reg.register(BadRule())
    before = p.crystal
    try:
        reg.augment(plan, player=p, uow=services.uow)
        raise AssertionError("mutating derived rule was accepted")
    except RuntimeError:
        pass
    # Registry detects impurity; caller/UoW owns rollback. Restore here because this
    # direct unit test intentionally invokes the rule outside a transaction.
    p.crystal = before


def test_stage_a_behavior_neutrality():
    # Stage A intentionally does NOT fix the stale Pass74 lifecycle yet. Keeping
    # this characterization proves foundation wiring did not accidentally expose
    # Stage B semantics before the roadmap authorizes them.
    p = PlayerState(player_id="205003", account_uid="205003", lev=100)
    h = hero(pid=205003, tid=10001001)
    p.heroes = {str(h["partner_id"]): h}
    p.collected_heros = {str(h["table_id"]): {"table_id": h["table_id"], "star": 5, "is_collected": 1}}
    commits = []
    s = RequestServices(p, DATA, lambda: commits.append(1), catalog=CATALOG)
    response = s.awakening_missions.open_task({"mission_id": 1001001, "awake_type": 1})
    row = response["awake_mission_"][0]
    req(row["is_complete"] == 1, "Stage A accidentally changed Pass74 outward lifecycle")
    req(p.awakening_state["schema_version"] == 2, "Stage A did not persist v2 in-memory state")
    req(p.awakening_state["active"]["1"]["generation"] == 1, "new activation lacks generation")


def main() -> int:
    test_source_catalog()
    test_state_v2_and_replay()
    test_canonical_replacement()
    test_projection_shapes()
    test_derived_registry_and_composition_root()
    test_stage_a_behavior_neutrality()
    report = {
        "pass": "205.0", "stage": "P2-A", "status": "PASS",
        "source_catalog_immutable": True,
        "awakening_state_v2_migration": True,
        "generation_replay_framework": True,
        "canonical_replacement_paths": ["awakening_state", "occult_state"],
        "projection_shapes": True,
        "derived_rule_registry_empty": True,
        "pass74_outward_behavior_preserved": True,
    }
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
