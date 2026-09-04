#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import EmblemSourceCatalog, GameDataCatalog
from gxb_backend.state.emblem_policy import EmblemPolicyRegistry
from gxb_backend.state.emblem_state_repository import EmblemStateRepository
from gxb_backend.state.mutation_settlement_service import MutationSettlementError
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.projection_profiles import ProjectionProfileRegistry
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.response_projector import ResponseProjector
from gxb_backend.testing.scripted_entropy import ScriptedEntropyDraw, ScriptedEntropyProvider

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def req(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def blank_player(pid: str = "246001") -> PlayerState:
    p = PlayerState(player_id=pid, account_uid=pid, player_name="Pass246-I4")
    p.heroes = {
        "10001": {
            "partner_id": 10001, "table_id": 11001001, "star": 6,
            "lev": 100, "twice_awake_stage": 3, "inscript_items": [],
        }
    }
    p.backpack_items = []
    p.emblem_state = EmblemStateRepository.default_state("emblem-v1")
    return p


def seed(p: PlayerState, *pairs: tuple[int, int]) -> None:
    p.backpack_items = [
        {"table_id": int(item_id), "item_num": int(count), "time": 0}
        for item_id, count in pairs
        if int(count) > 0
    ]


def services(p: PlayerState, provider: ScriptedEntropyProvider, commits: list[int] | None = None) -> RequestServices:
    target = commits if commits is not None else []
    return RequestServices(
        p,
        DATA,
        lambda: target.append(int(p.persistence_state.get("state_version", -1))),
        catalog=CATALOG,
        entropy_provider=provider,
    )


def test_current_source_cost_topology_and_policy_boundary() -> None:
    source = EmblemSourceCatalog(DATA)
    policy = EmblemPolicyRegistry(DATA)
    req(policy.version == "emblem-v1", "Emblem policy version drift")
    req(policy.metadata["epistemic_class"] == "IMPLEMENTATION_COMPATIBILITY_DECISION", "policy classification drift")
    req(policy.decision("outer_scholarship")["negative_claim"] == "not recovered official server math", "official-math negative claim lost")
    ordinary = [source.require_inscription(i) for i in source.inscription_ids() if int(source.require_inscription(i)["special"]) == 0]
    req(len(ordinary) == 21, "ordinary forge row census drift")
    for row in ordinary:
        level = int(row["level"])
        req(int(row["item_type"]) in (1, 2, 3), "ordinary Forge item_type drift")
        req(int(row["compound_material"]) in (19, 20, 21), "Forge scalar certificate material drift")
        req(int(row["compound_num"]) > 0, "Forge scalar certificate cost drift")
        if level == 7:
            req(int(row["compound_num"]) == 2130, "Lv7 scalar cost drift")
            req(int(row["compound_item"]) == 50001346 and int(row["compound_item_num"]) == 1, "Lv7 Heart cost drift")
        else:
            req(int(row["compound_item"]) == 0 and int(row["compound_item_num"]) == 0, "non-Lv7 Heart cost drift")


def test_invalid_and_insufficient_costs_are_entropy_inert() -> None:
    provider = ScriptedEntropyProvider([])
    p = blank_player("246010")
    p.degree_cer = 89
    s = services(p, provider)
    before = copy.deepcopy(vars(p))
    for payload in (
        {"inscript_id": 10001, "make_num": 0},
        {"inscript_id": 40001, "make_num": 1},
        {"inscript_id": 99999, "make_num": 1},
        {"inscript_id": 10001, "make_num": 1},
    ):
        req(s.emblem.make(payload).get("error_code") == 1, f"invalid/insufficient Forge accepted: {payload}")
    req(provider.consumed == (), "invalid/insufficient ordinary Forge consumed entropy")
    req(p.degree_cer == 89 and p.emblem_state == before["emblem_state"], "invalid ordinary Forge mutated state")
    req(not s.uow.consume_journal(), "invalid ordinary Forge staged journal")

    p.degree_cer = 2130
    seed(p)  # no Heart
    before_state = copy.deepcopy(p.emblem_state)
    req(s.emblem.make({"inscript_id": 10007, "make_num": 1}).get("error_code") == 1, "Heartless Lv7 Forge accepted")
    req(provider.consumed == (), "Heartless Lv7 Forge consumed entropy")
    req(p.degree_cer == 2130 and p.emblem_state == before_state, "Heartless Lv7 Forge mutated cost/pity")
    provider.assert_exhausted()


def test_ordinary_forge_atomic_cost_credit_and_stock_projection() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.forge.ordinary", 0, 84, 83),
    ])
    p = blank_player("246020")
    p.degree_cer = 90
    commits: list[int] = []
    s = services(p, provider, commits)
    projector = ResponseProjector.capture(p, resource_registry=s.resource_registry)
    out = s.emblem.make({"inscript_id": 10001, "make_num": 1})
    journal = s.uow.consume_journal()
    req(out == {"inscript_items": [160100110]}, "ordinary Forge wire response drift")
    req(p.degree_cer == 0, "ordinary Forge certificate debit drift")
    req(s.stack_inventory.quantity(160100110) == 1, "ordinary Forge medal credit drift")
    req(s.emblem_state.misses_since_special("forge") == 0, "non-Lv7 Forge changed pity")
    req([row["category"] for row in journal] == ["RESOURCE", "STACK"], "ordinary Forge journal topology drift")
    req(len(commits) == 1, "ordinary Forge did not commit exactly once")

    profile = ProjectionProfileRegistry.load(DATA / "projection_profile_registry.json").resolve(
        mid=1400, label="INSCRIPTION_MAKE", transport="engine_web"
    )
    projected = projector.project(out, p, committed_journal=journal, profile=profile)
    req(projected["inscript_items"] == [160100110], "raw inscript_items lost in projection")
    req(projected.get("economy_") == {"degree_cer": 0}, "certificate cumulative projection drift")
    req("awards" not in projected and "extra_drops_" not in projected, "generated medal was double-projected generically")
    provider.assert_exhausted()


def test_lv7_miss_consumes_heart_and_advances_forge_counter() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.forge.scholarship_gate", 0, 10000, 10),
        ScriptedEntropyDraw("emblem.forge.ordinary", 0, 84, 0),
    ])
    p = blank_player("246030")
    p.degree_cer = 2130
    seed(p, (50001346, 1))
    s = services(p, provider)
    out = s.emblem.make({"inscript_id": 10007, "make_num": 1})
    journal = s.uow.consume_journal()
    req(out == {"inscript_items": [160100701]}, "Lv7 miss ordinary output drift")
    req(p.degree_cer == 0 and s.stack_inventory.quantity(50001346) == 0, "Lv7 miss costs not atomically consumed")
    req(s.stack_inventory.quantity(160100701) == 1, "Lv7 miss medal not credited")
    req(s.emblem_state.misses_since_special("forge") == 1, "Lv7 miss did not advance Forge pity")
    req([row["category"] for row in journal] == ["RESOURCE", "STACK", "STACK"], "Lv7 miss journal topology drift")
    provider.assert_exhausted()


def test_lv7_hard_scholarship_uses_no_gate_entropy_and_resets_counter() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.forge.scholarship_family", 0, 100, 99),
        ScriptedEntropyDraw("emblem.forge.scholarship_item", 0, 144, 143),
    ])
    p = blank_player("246040")
    p.degree_cer = 2130
    p.emblem_state["scholarship_rng"]["forge"]["misses_since_special"] = 999
    seed(p, (50001346, 1))
    s = services(p, provider)
    out = s.emblem.make({"inscript_id": 10007, "make_num": 1})
    req(out == {"inscript_items": [160500603]}, "hard Scholarship Forge output drift")
    req(s.emblem_state.misses_since_special("forge") == 0, "Scholarship Forge did not reset counter")
    req(s.stack_inventory.quantity(160500603) == 1 and s.stack_inventory.quantity(50001346) == 0, "hard Scholarship settlement drift")
    provider.assert_exhausted()


def test_final_settlement_failure_rolls_back_cost_and_pity() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.forge.scholarship_gate", 0, 10000, 9999),
        ScriptedEntropyDraw("emblem.forge.ordinary", 0, 84, 0),
    ])
    p = blank_player("246050")
    p.degree_cer = 2130
    seed(p, (50001346, 1))
    s = services(p, provider)
    before_state = copy.deepcopy(p.emblem_state)
    before_version = int(p.persistence_state.get("state_version", 0))
    original_apply = s.mutation_settlement.apply

    def fail_after_entropy(plan):
        raise MutationSettlementError("forced I4 post-entropy settlement failure")

    s.mutation_settlement.apply = fail_after_entropy
    try:
        out = s.emblem.make({"inscript_id": 10007, "make_num": 1})
    finally:
        s.mutation_settlement.apply = original_apply
    req(out.get("error_code") == 1, "forced settlement failure did not fail closed")
    req(p.degree_cer == 2130 and s.stack_inventory.quantity(50001346) == 1, "failed settlement leaked cost mutation")
    req(p.emblem_state == before_state, "failed settlement leaked pity mutation")
    req(int(p.persistence_state.get("state_version", 0)) == before_version, "failed settlement advanced state version")
    req(not s.uow.consume_journal(), "failed settlement published journal")
    provider.assert_exhausted()


def test_wire_identical_repeat_is_second_paid_forge_without_receipt() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.forge.ordinary", 0, 84, 0),
        ScriptedEntropyDraw("emblem.forge.ordinary", 1, 84, 8),
    ])
    p = blank_player("246060")
    p.degree_cer = 180
    s = services(p, provider)
    first = s.emblem.make({"inscript_id": 10001, "make_num": 1})
    s.uow.consume_journal()
    second = s.emblem.make({"inscript_id": 10001, "make_num": 1})
    s.uow.consume_journal()
    req(first == {"inscript_items": [160100101]} and second == {"inscript_items": [160100102]}, "repeat Forge draw drift")
    req(p.degree_cer == 0, "repeat Forge did not charge twice")
    req(s.stack_inventory.quantity(160100101) == 1 and s.stack_inventory.quantity(160100102) == 1, "repeat Forge medals not independently credited")
    receipts = (p.persistence_state.get("receipts") or {}).get("emblem") or {}
    req(not receipts, "MID1400 incorrectly staged nonce/receipt state")
    provider.assert_exhausted()


def test_only_mid1400_public_route_opens_in_i4() -> None:
    dispatch_src = (ROOT / "gxb_backend/dispatch/engine_dispatcher.py").read_text(encoding="utf-8")
    hero_src = (ROOT / "gxb_backend/handlers/heroes.py").read_text(encoding="utf-8")
    req('"INSCRIPTION_MAKE": self.heroes.inscription_make' in dispatch_src, "MID1400 dispatcher route not opened")
    for symbol in ("INSCRIPTION_REBUILD", "INSCRIPTION_SAVE_REBUILD", "INSCRIPTION_ABANDON_REBUILD"):
        req(f'"{symbol}": self.heroes.advanced_hidden_fail_closed' in dispatch_src, f"{symbol} fence opened during I4")
    req("get_emblem_service().make(req)" in hero_src, "Hero handler does not delegate MID1400 to EmblemService")

    provider = ScriptedEntropyProvider([])
    p = blank_player("246070")
    s = services(p, provider)
    for result in (
        s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 2}),
        s.emblem.save_rebuild({"item_id": 160100102}),
        s.emblem.abandon_rebuild({}),
    ):
        req(result == {"error_code": 1, "msg": "advanced_progression_server_algorithm_unresolved"}, "I5 route opened during I4")
    req(provider.consumed == (), "fenced I5 route consumed entropy")
    provider.assert_exhausted()


def main() -> int:
    tests = [
        test_current_source_cost_topology_and_policy_boundary,
        test_invalid_and_insufficient_costs_are_entropy_inert,
        test_ordinary_forge_atomic_cost_credit_and_stock_projection,
        test_lv7_miss_consumes_heart_and_advances_forge_counter,
        test_lv7_hard_scholarship_uses_no_gate_entropy_and_resets_counter,
        test_final_settlement_failure_rolls_back_cost_and_pity,
        test_wire_identical_repeat_is_second_paid_forge_without_receipt,
        test_only_mid1400_public_route_opens_in_i4,
    ]
    for test in tests:
        test()
        print("PASS", test.__name__)
    print(json.dumps({
        "pass": "246.0",
        "status": "PASS",
        "scope": "Emblem I4 MID1400 Forge only",
        "checks": [test.__name__ for test in tests],
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
