#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import EmblemSourceCatalog, GameDataCatalog
from gxb_backend.state.account import AccountIdentity
from gxb_backend.state.emblem_outcome_planner import EmblemOutcomePlanner
from gxb_backend.state.emblem_policy import EmblemPolicyRegistry
from gxb_backend.state.emblem_state_repository import EmblemStateRepository
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.random_outcome_service import RandomOutcomeService
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.unit_of_work import OperationContext, PlayerUnitOfWork
from gxb_backend.testing.scripted_entropy import ScriptedEntropyDraw, ScriptedEntropyProvider


def req(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def blank_player(pid: str = "244001") -> PlayerState:
    p = PlayerState(player_id=pid, account_uid=pid, player_name="Pass244-I3")
    p.heroes = {}
    p.backpack_items = []
    p.emblem_state = EmblemStateRepository.default_state("emblem-v1")
    return p


def test_source_policy_boundary_and_fixed_point_ladders() -> None:
    source = EmblemSourceCatalog(DATA)
    policy = EmblemPolicyRegistry(DATA)
    req(policy.outer_scholarship_enabled is True, "I3 internal policy not enabled")
    req(policy.metadata["epistemic_class"] == "IMPLEMENTATION_COMPATIBILITY_DECISION", "policy epistemic class drift")
    req(policy.decision("outer_scholarship")["negative_claim"] == "not recovered official server math", "server-unknown guard lost")
    req(tuple((r["rate_suit"], r["rate_step"], r["max_num"]) for r in source.uninterpreted_rate_rows) == ((0, 0.1, 1000), (0, 1, 100)), "current-source rate rows drift")
    req(policy.scholarship_chance("forge", 0) == (1, 10, False), "Forge first-attempt fixed-point drift")
    req(policy.scholarship_chance("forge", 998) == (999, 9990, False), "Forge near-ceiling drift")
    req(policy.scholarship_chance("forge", 999) == (1000, 10000, True), "Forge hard ceiling drift")
    req(policy.scholarship_chance("reforge", 0) == (1, 100, False), "Reforge first-attempt fixed-point drift")
    req(policy.scholarship_chance("reforge", 98) == (99, 9900, False), "Reforge near-ceiling drift")
    req(policy.scholarship_chance("reforge", 99) == (100, 10000, True), "Reforge hard ceiling drift")


def test_entropy_topology_ordinary_miss_hit_and_hard_ceiling() -> None:
    source = EmblemSourceCatalog(DATA)
    policy = EmblemPolicyRegistry(DATA)

    ordinary_provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.forge.ordinary", 0, 84, 83),
    ])
    ordinary = EmblemOutcomePlanner(source, policy, RandomOutcomeService(ordinary_provider))
    draw = ordinary.generated_candidate(10001, lane="forge", misses_since_special=777)
    req(draw.item_id == 160100110 and draw.gate is None, "Lv1 ordinary draw topology drift")
    ordinary_provider.assert_exhausted()

    miss_provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.forge.scholarship_gate", 0, 10000, 10),
        ScriptedEntropyDraw("emblem.forge.ordinary", 0, 84, 0),
    ])
    miss_planner = EmblemOutcomePlanner(source, policy, RandomOutcomeService(miss_provider))
    miss = miss_planner.generated_candidate(10007, lane="forge", misses_since_special=0)
    req(not miss.scholarship and miss.item_id == 160100701, "Lv7 miss ordinary branch drift")
    req(miss.gate is not None and miss.gate.misses_after == 1 and miss.gate.entropy_consumed, "Lv7 miss gate-state drift")
    miss_provider.assert_exhausted()

    hit_provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.forge.scholarship_gate", 0, 10000, 0),
        ScriptedEntropyDraw("emblem.forge.scholarship_family", 0, 100, 69),
        ScriptedEntropyDraw("emblem.forge.scholarship_item", 0, 96, 0),
    ])
    hit_planner = EmblemOutcomePlanner(source, policy, RandomOutcomeService(hit_provider))
    hit = hit_planner.generated_candidate(10007, lane="forge", misses_since_special=0)
    req(hit.scholarship and hit.scholarship_family_id == 40001 and hit.item_id == 160400101, "Lv7 Scholarship hit branch drift")
    req(hit.gate is not None and hit.gate.misses_after == 0, "Lv7 hit did not reset counter")
    hit_provider.assert_exhausted()

    hard_provider = ScriptedEntropyProvider([
        # Hard gate intentionally consumes no scholarship_gate draw.
        ScriptedEntropyDraw("emblem.forge.scholarship_family", 0, 100, 99),
        ScriptedEntropyDraw("emblem.forge.scholarship_item", 0, 144, 143),
    ])
    hard_planner = EmblemOutcomePlanner(source, policy, RandomOutcomeService(hard_provider))
    hard = hard_planner.generated_candidate(10007, lane="forge", misses_since_special=999)
    req(hard.scholarship and hard.scholarship_family_id == 50001 and hard.item_id == 160500603, "hard-ceiling special branch drift")
    req(hard.gate is not None and hard.gate.chance_bp == 10000 and not hard.gate.entropy_consumed, "hard ceiling consumed entropy")
    hard_provider.assert_exhausted()


def test_reforge_excludes_current_and_invalid_plans_consume_zero_entropy() -> None:
    source = EmblemSourceCatalog(DATA)
    policy = EmblemPolicyRegistry(DATA)
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0),
    ])
    planner = EmblemOutcomePlanner(source, policy, RandomOutcomeService(provider))
    draw = planner.generated_candidate(10001, lane="reforge", misses_since_special=0, source_item_id=160100101)
    req(draw.item_id == 160100102, "reforge current-result exclusion drift")
    req(draw.item_id != 160100101 and draw.ordinary_exclude_item_id == 160100101, "current item was not excluded")
    provider.assert_exhausted()

    empty = ScriptedEntropyProvider([])
    invalid = EmblemOutcomePlanner(source, policy, RandomOutcomeService(empty))
    for call in (
        lambda: invalid.generated_candidate(40001, lane="forge", misses_since_special=0),
        lambda: invalid.generated_candidate(10001, lane="reforge", misses_since_special=0, source_item_id=160200101),
        lambda: invalid.generated_candidate(10001, lane="bogus", misses_since_special=0),
    ):
        try:
            call()
        except ValueError:
            pass
        else:
            raise AssertionError("invalid Emblem RNG plan unexpectedly succeeded")
    req(empty.consumed == (), "invalid Emblem RNG plan consumed entropy")
    empty.assert_exhausted()


def test_ten_rebuild_sequential_hit_reset_hit_and_latest_proposal_wins() -> None:
    # Reforge starts at 98 misses. Sequence: miss(attempt99), guaranteed hit
    # (attempt100, no gate entropy), immediate hit(attempt1), then seven misses.
    scripted = [
        ScriptedEntropyDraw("emblem.reforge.scholarship_gate", 0, 10000, 9999),
        ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0),
        ScriptedEntropyDraw("emblem.reforge.scholarship_family", 0, 100, 0),
        ScriptedEntropyDraw("emblem.reforge.scholarship_item", 0, 96, 0),
        ScriptedEntropyDraw("emblem.reforge.scholarship_gate", 1, 10000, 0),
        ScriptedEntropyDraw("emblem.reforge.scholarship_family", 1, 100, 99),
        ScriptedEntropyDraw("emblem.reforge.scholarship_item", 1, 144, 0),
    ]
    # Seven post-reset misses, plus ordinary selections. Gate ordinals continue
    # at 2 because the hard attempt100 consumed no gate entropy.
    for i in range(7):
        scripted.append(ScriptedEntropyDraw("emblem.reforge.scholarship_gate", i + 2, 10000, 9999))
        scripted.append(ScriptedEntropyDraw("emblem.reforge.ordinary", i + 1, 76, 0))
    # Next latest-wins proposal is Lv1 and only needs the ordinary namespace.
    scripted.append(ScriptedEntropyDraw("emblem.reforge.ordinary", 8, 76, 0))

    provider = ScriptedEntropyProvider(scripted)
    p = blank_player("244010")
    p.emblem_state["scholarship_rng"]["reforge"]["misses_since_special"] = 98
    game = GameDataCatalog.load(DATA / "game_data_catalog.json")
    services = RequestServices(p, DATA, lambda: None, catalog=game, entropy_provider=provider)

    with services.uow.transaction(OperationContext(actor_player_id=p.player_id, domain="emblem.i3", operation_name="ten_proposal")):
        pending = services.emblem._stage_rebuild_proposal_internal(
            source_item_id=160100701,
            rebuild_num=10,
            cost_type=2,
        )
    req(pending["generation"] == 1 and len(pending["candidates"]) == 10, "10x proposal shape drift")
    req(pending["candidates"][:3] == [160100702, 160400101, 160500101], "10x miss/hard-hit/reset-hit topology drift")
    req(pending["candidates"][3:] == [160100702] * 7, "10x post-reset ordinary topology drift")
    req(services.emblem_state.misses_since_special("reforge") == 7, "10x sequential pity state drift")

    with services.uow.transaction(OperationContext(actor_player_id=p.player_id, domain="emblem.i3", operation_name="replace_latest")):
        latest = services.emblem._stage_rebuild_proposal_internal(
            source_item_id=160100101,
            rebuild_num=1,
            cost_type=1,
        )
    req(latest["generation"] == 2, "latest proposal generation did not advance")
    req(latest["source_item_id"] == 160100101 and latest["candidates"] == [160100102], "latest proposal did not replace old candidates")
    req(services.emblem_state.pending_rebuild() == latest, "latest proposal is not durable authority")
    req(services.emblem_state.misses_since_special("reforge") == 7, "non-Lv7 proposal mutated pity")
    provider.assert_exhausted()


def test_proposal_persistence_policy_version_and_malformed_repair() -> None:
    source = EmblemSourceCatalog(DATA)
    policy = EmblemPolicyRegistry(DATA)
    p = blank_player("244020")
    p.emblem_state = {
        "schema_version": 1,
        "policy_version": "emblem-v0",
        "proposal_generation": 4,
        "pending_rebuild": {
            "generation": 4,
            "source_item_id": 160100701,
            "source_inscription_id": 10007,
            "rebuild_num": 1,
            "cost_type": 2,
            "candidates": [160400101],
            "policy_version": "emblem-v0",
        },
        "scholarship_rng": {"forge": {"misses_since_special": 7}, "reforge": {"misses_since_special": 8}},
    }
    repo = EmblemStateRepository(p, source, policy)
    repo.normalize()
    req(p.emblem_state["policy_version"] == "emblem-v1", "active policy version did not normalize current")
    req(repo.pending_rebuild()["policy_version"] == "emblem-v0", "frozen proposal policy version was rewritten")
    req(repo.pending_rebuild()["candidates"] == [160400101], "valid Lv7 special frozen proposal was lost")

    with tempfile.TemporaryDirectory() as td:
        db = JsonPlayerDatabase(Path(td) / "player.json")
        account = AccountIdentity(uid=p.account_uid)
        db.save(account, p)
        _, loaded = db.load(account, blank_player(p.player_id))
        req(loaded.emblem_state == p.emblem_state, "pending proposal/counters failed persistence roundtrip")

    # Cross-tier generated candidate is malformed and must not survive restart normalization.
    p.emblem_state["pending_rebuild"] = {
        "generation": 4,
        "source_item_id": 160100101,
        "source_inscription_id": 10001,
        "rebuild_num": 1,
        "cost_type": 2,
        "candidates": [160100201],
        "policy_version": "emblem-v1",
    }
    req(repo.normalize() is True and repo.pending_rebuild() is None, "cross-tier malformed proposal survived normalization")


def test_state_result_staleness_and_uow_rollback() -> None:
    source = EmblemSourceCatalog(DATA)
    policy = EmblemPolicyRegistry(DATA)
    p = blank_player("244030")
    commits: list[dict] = []
    uow = PlayerUnitOfWork(p, lambda: commits.append(copy.deepcopy(p.emblem_state)))
    repo = EmblemStateRepository(p, source, policy, uow=uow)
    with uow.transaction(OperationContext(actor_player_id=p.player_id, domain="emblem.i3", operation_name="miss")):
        req(repo.apply_scholarship_result("forge", misses_before=0, hit=False) == 1, "miss counter did not increment")
    req(repo.misses_since_special("forge") == 1, "committed miss state drift")
    before = copy.deepcopy(p.emblem_state)
    try:
        with uow.transaction(OperationContext(actor_player_id=p.player_id, domain="emblem.i3", operation_name="rollback")):
            repo.apply_scholarship_result("forge", misses_before=1, hit=True)
            raise RuntimeError("rollback")
    except RuntimeError:
        pass
    req(p.emblem_state == before, "I3 state mutation did not roll back with UoW")
    with uow.transaction(OperationContext(actor_player_id=p.player_id, domain="emblem.i3", operation_name="stale")):
        try:
            repo.apply_scholarship_result("forge", misses_before=0, hit=True)
        except ValueError:
            pass
        else:
            raise AssertionError("stale Scholarship result was accepted")
        uow.set_rollback_only()
    req(p.emblem_state == before, "stale-result rejection changed state")


def test_public_rng_routes_remain_fenced_and_entropy_inert() -> None:
    provider = ScriptedEntropyProvider([])
    p = blank_player("244040")
    game = GameDataCatalog.load(DATA / "game_data_catalog.json")
    services = RequestServices(p, DATA, lambda: None, catalog=game, entropy_provider=provider)
    for result in (
        services.emblem.make({"inscript_id": 10001, "make_num": 1}),
        services.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 2}),
        services.emblem.save_rebuild({"item_id": 160100102}),
        services.emblem.abandon_rebuild({}),
    ):
        req(result == {"error_code": 1, "msg": "advanced_progression_server_algorithm_unresolved"}, "I3 public RNG fence opened")
    req(provider.consumed == (), "fenced public RNG route consumed entropy")
    provider.assert_exhausted()


def main() -> int:
    tests = [
        test_source_policy_boundary_and_fixed_point_ladders,
        test_entropy_topology_ordinary_miss_hit_and_hard_ceiling,
        test_reforge_excludes_current_and_invalid_plans_consume_zero_entropy,
        test_ten_rebuild_sequential_hit_reset_hit_and_latest_proposal_wins,
        test_proposal_persistence_policy_version_and_malformed_repair,
        test_state_result_staleness_and_uow_rollback,
        test_public_rng_routes_remain_fenced_and_entropy_inert,
    ]
    for test in tests:
        test()
    report = {
        "pass": "244.0",
        "status": "PASS",
        "scope": "Emblem I3 internal RNG/policy/pending-proposal foundation; public RNG MIDs fenced",
        "checks": [test.__name__ for test in tests],
    }
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
