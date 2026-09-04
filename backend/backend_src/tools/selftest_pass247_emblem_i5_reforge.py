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
from gxb_backend.state.emblem_policy import EmblemPolicyRegistry
from gxb_backend.state.emblem_state_repository import EmblemStateRepository
from gxb_backend.state.mutation_settlement_service import MutationSettlementError
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.projection_profiles import ProjectionProfileRegistry
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.response_projector import ResponseProjector
from gxb_backend.testing.scripted_entropy import ScriptedEntropyDraw, ScriptedEntropyProvider

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def req(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def blank_player(pid: str = "247001") -> PlayerState:
    p = PlayerState(player_id=pid, account_uid=pid, player_name="Pass247-I5")
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


def services(
    p: PlayerState,
    provider: ScriptedEntropyProvider,
    commits: list[int] | None = None,
) -> RequestServices:
    target = commits if commits is not None else []
    return RequestServices(
        p,
        DATA,
        lambda: target.append(int(p.persistence_state.get("state_version", -1))),
        catalog=CATALOG,
        entropy_provider=provider,
    )


def test_current_source_reforge_contract_and_policy_boundary() -> None:
    source = EmblemSourceCatalog(DATA)
    policy = EmblemPolicyRegistry(DATA)
    row1 = source.require_inscription(10001)
    row7 = source.require_inscription(10007)
    req(int(row1["change_gold"]) == 100000 and int(row1["change_crystal"]) == 20, "Lv1 Reforge cost drift")
    req(int(row7["change_gold"]) == 1000000 and int(row7["change_crystal"]) == 40, "Lv7 Reforge cost drift")
    req(policy.metadata["status"] == "I5_FORGE_AND_REFORGE_PUBLIC_ENABLED", "I5 policy activation drift")
    req(policy.decision("outer_scholarship")["negative_claim"] == "not recovered official server math", "official-math negative claim lost")
    req(policy.exclude_current_reforge_item is True, "same-result exclusion policy drift")
    proposal = policy.decision("pending_proposal")
    req(proposal["latest_proposal_wins"] is True and proposal["persist_across_restart"] is True, "proposal policy drift")
    req(proposal["stale_source_save_clears_pending"] is True and proposal["abandon_without_pending_success"] is True, "proposal cleanup policy drift")


def test_invalid_insufficient_and_unowned_rebuild_are_entropy_inert() -> None:
    provider = ScriptedEntropyProvider([])
    p = blank_player("247010")
    p.mana = 99999
    p.crystal = 19
    seed(p, (160100101, 1), (160400101, 1))
    s = services(p, provider)
    before_state = copy.deepcopy(p.emblem_state)
    before_inventory = copy.deepcopy(p.backpack_items)

    invalid = (
        {"item_id": 0, "rebuild_num": 1, "cost_type": 2},
        {"item_id": 160100101, "rebuild_num": 2, "cost_type": 2},
        {"item_id": 160100101, "rebuild_num": 1, "cost_type": 3},
        {"item_id": 160400101, "rebuild_num": 1, "cost_type": 2},
        {"item_id": 160100101, "rebuild_num": 1, "cost_type": 2},
        {"item_id": 160100101, "rebuild_num": 1, "cost_type": 1},
        {"item_id": 160100102, "rebuild_num": 1, "cost_type": 2},
    )
    for payload in invalid:
        req(s.emblem.rebuild(payload).get("error_code") == 1, f"invalid/insufficient Reforge accepted: {payload}")
    req(provider.consumed == (), "invalid/insufficient Reforge consumed entropy")
    req(p.mana == 99999 and p.crystal == 19, "invalid/insufficient Reforge spent resources")
    req(p.emblem_state == before_state, "invalid/insufficient Reforge mutated proposal/pity")
    req(p.backpack_items == before_inventory, "invalid/insufficient Reforge mutated inventory")
    req(not s.uow.consume_journal(), "invalid/insufficient Reforge published journal")
    provider.assert_exhausted()


def test_single_mana_rebuild_is_paid_latest_proposal_without_source_debit() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0),
    ])
    p = blank_player("247020")
    p.mana = 100000
    seed(p, (160100101, 1))
    commits: list[int] = []
    s = services(p, provider, commits)
    projector = ResponseProjector.capture(p, resource_registry=s.resource_registry)
    out = s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 2})
    journal = s.uow.consume_journal()
    req(out == {"inscript_items": [160100102]}, "single Mana Reforge response drift")
    req(p.mana == 0, "single Mana Reforge cost not debited")
    req(s.stack_inventory.quantity(160100101) == 1, "proposal generation debited original source")
    req(s.stack_inventory.quantity(160100102) == 0, "proposal generation prematurely credited candidate")
    pending = s.emblem_state.pending_rebuild()
    req(pending is not None and pending["generation"] == 1 and pending["candidates"] == [160100102], "single pending proposal drift")
    req(pending["source_item_id"] == 160100101 and pending["rebuild_num"] == 1 and pending["cost_type"] == 2, "single pending source/cost shape drift")
    req([row["category"] for row in journal] == ["RESOURCE"], "single proposal journal should contain cost only")
    req(len(commits) == 1, "single proposal did not commit exactly once")

    profile = ProjectionProfileRegistry.load(DATA / "projection_profile_registry.json").resolve(
        mid=1401, label="INSCRIPTION_REBUILD", transport="engine_web"
    )
    projected = projector.project(out, p, committed_journal=journal, profile=profile)
    req(projected["inscript_items"] == [160100102], "raw proposal IDs lost in projection")
    req(projected.get("economy_") == {"mana": 0}, "Mana cumulative projection drift")
    req("awards" not in projected and "extra_drops_" not in projected, "proposal incorrectly projected a candidate reward")
    provider.assert_exhausted()


def test_wire_identical_repeat_is_second_paid_latest_wins_proposal() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0),
        ScriptedEntropyDraw("emblem.reforge.ordinary", 1, 76, 8),
    ])
    p = blank_player("247030")
    p.crystal = 40
    seed(p, (160100101, 1))
    s = services(p, provider)
    first = s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 1})
    s.uow.consume_journal()
    second = s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 1})
    s.uow.consume_journal()
    req(first == {"inscript_items": [160100102]}, "first paid proposal drift")
    req(second == {"inscript_items": [160100103]}, "second paid proposal drift")
    req(p.crystal == 0, "wire-identical repeat was not charged twice")
    pending = s.emblem_state.pending_rebuild()
    req(pending is not None and pending["generation"] == 2 and pending["candidates"] == [160100103], "latest proposal did not replace prior")
    req(s.stack_inventory.quantity(160100101) == 1, "repeat proposal consumed original source")
    receipts = (p.persistence_state.get("receipts") or {}).get("emblem") or {}
    req(not receipts, "MID1401 incorrectly staged nonce/receipt state")
    provider.assert_exhausted()


def test_ten_lv7_rebuild_is_sequential_and_charged_once() -> None:
    scripted = [
        ScriptedEntropyDraw("emblem.reforge.scholarship_gate", 0, 10000, 9999),
        ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0),
        # attempt100 hard-special: no gate entropy
        ScriptedEntropyDraw("emblem.reforge.scholarship_family", 0, 100, 0),
        ScriptedEntropyDraw("emblem.reforge.scholarship_item", 0, 96, 0),
        ScriptedEntropyDraw("emblem.reforge.scholarship_gate", 1, 10000, 0),
        ScriptedEntropyDraw("emblem.reforge.scholarship_family", 1, 100, 99),
        ScriptedEntropyDraw("emblem.reforge.scholarship_item", 1, 144, 0),
    ]
    for i in range(7):
        scripted.append(ScriptedEntropyDraw("emblem.reforge.scholarship_gate", i + 2, 10000, 9999))
        scripted.append(ScriptedEntropyDraw("emblem.reforge.ordinary", i + 1, 76, 0))
    provider = ScriptedEntropyProvider(scripted)
    p = blank_player("247040")
    p.mana = 10_000_000
    p.emblem_state["scholarship_rng"]["reforge"]["misses_since_special"] = 98
    seed(p, (160100701, 1))
    s = services(p, provider)
    out = s.emblem.rebuild({"item_id": 160100701, "rebuild_num": 10, "cost_type": 2})
    s.uow.consume_journal()
    expected = [160100702, 160400101, 160500101] + [160100702] * 7
    req(out == {"inscript_items": expected}, "10x sequential proposal output drift")
    req(p.mana == 0, "10x proposal did not debit exactly 10x row Mana cost")
    req(s.stack_inventory.quantity(160100701) == 1, "10x proposal consumed original")
    req(s.emblem_state.misses_since_special("reforge") == 7, "10x sequential Reforge pity state drift")
    pending = s.emblem_state.pending_rebuild()
    req(pending is not None and pending["rebuild_num"] == 10 and pending["candidates"] == expected, "10x frozen pending drift")
    provider.assert_exhausted()


def test_save_commits_frozen_candidate_without_reroll_or_double_projection() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0),
    ])
    p = blank_player("247050")
    p.mana = 100000
    seed(p, (160100101, 1))
    s = services(p, provider)
    proposal = s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 2})
    s.uow.consume_journal()
    req(proposal == {"inscript_items": [160100102]}, "save setup proposal drift")
    projector = ResponseProjector.capture(p, resource_registry=s.resource_registry)
    out = s.emblem.save_rebuild({"item_id": 160100102})
    journal = s.uow.consume_journal()
    req(out == {"rebuild_items": [{"table_id": 160100102, "item_num": 1}]}, "MID1405 reward wire shape drift")
    req(s.stack_inventory.quantity(160100101) == 0, "MID1405 did not debit original source")
    req(s.stack_inventory.quantity(160100102) == 1, "MID1405 did not credit selected candidate")
    req(s.emblem_state.pending_rebuild() is None, "MID1405 did not clear pending")
    req([row["category"] for row in journal] == ["STACK", "STACK"], "MID1405 journal topology drift")

    profile = ProjectionProfileRegistry.load(DATA / "projection_profile_registry.json").resolve(
        mid=1405, label="INSCRIPTION_SAVE_REBUILD", transport="engine_web"
    )
    projected = projector.project(out, p, committed_journal=journal, profile=profile)
    req(projected["rebuild_items"] == [{"table_id": 160100102, "item_num": 1}], "explicit rebuild reward lost")
    req("awards" not in projected and "extra_drops_" not in projected, "saved candidate double-projected generically")
    provider.assert_exhausted()


def test_superseded_candidate_and_repeated_save_fail_without_mutation() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0),
        ScriptedEntropyDraw("emblem.reforge.ordinary", 1, 76, 8),
    ])
    p = blank_player("247060")
    p.crystal = 40
    seed(p, (160100101, 1))
    s = services(p, provider)
    first = s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 1})
    s.uow.consume_journal()
    second = s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 1})
    s.uow.consume_journal()
    req(first["inscript_items"] == [160100102] and second["inscript_items"] == [160100103], "supersession setup drift")
    before = copy.deepcopy(vars(p))
    req(s.emblem.save_rebuild({"item_id": 160100102}).get("error_code") == 1, "superseded candidate committed")
    req(p.backpack_items == before["backpack_items"] and p.emblem_state == before["emblem_state"], "superseded save mutated state")
    req(not s.uow.consume_journal(), "superseded save published journal")
    good = s.emblem.save_rebuild({"item_id": 160100103})
    s.uow.consume_journal()
    req(good.get("rebuild_items") == [{"table_id": 160100103, "item_num": 1}], "latest candidate did not commit")
    after_good = copy.deepcopy(vars(p))
    req(s.emblem.save_rebuild({"item_id": 160100103}).get("error_code") == 1, "repeated save unexpectedly replayed")
    req(p.backpack_items == after_good["backpack_items"] and p.emblem_state == after_good["emblem_state"], "repeated save mutated state")
    provider.assert_exhausted()


def test_stale_source_save_clears_pending_without_free_candidate() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0),
    ])
    p = blank_player("247070")
    p.mana = 100000
    seed(p, (160100101, 1))
    s = services(p, provider)
    out = s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 2})
    s.uow.consume_journal()
    req(out == {"inscript_items": [160100102]}, "stale-source setup drift")
    p.backpack_items = []
    version_before = int(p.persistence_state.get("state_version", 0))
    req(s.emblem.save_rebuild({"item_id": 160100102}).get("error_code") == 1, "stale source save succeeded")
    req(s.emblem_state.pending_rebuild() is None, "stale source did not clear pending")
    req(s.stack_inventory.quantity(160100102) == 0, "stale source granted selected candidate")
    req(int(p.persistence_state.get("state_version", 0)) == version_before + 1, "stale clear was not durable")
    req(not s.uow.consume_journal(), "stale clear should publish no economy/stack journal")
    provider.assert_exhausted()


def test_abandon_clears_pending_no_refund_and_repeat_is_noop() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0),
    ])
    p = blank_player("247080")
    p.crystal = 20
    seed(p, (160100101, 1))
    s = services(p, provider)
    s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 1})
    s.uow.consume_journal()
    req(p.crystal == 0 and s.emblem_state.pending_rebuild() is not None, "abandon setup drift")
    version_before = int(p.persistence_state.get("state_version", 0))
    req(s.emblem.abandon_rebuild({}) == {}, "MID1406 abandon failed")
    req(s.emblem_state.pending_rebuild() is None, "MID1406 did not clear pending")
    req(p.crystal == 0 and s.stack_inventory.quantity(160100101) == 1, "MID1406 refunded or mutated inventory")
    req(int(p.persistence_state.get("state_version", 0)) == version_before + 1, "MID1406 clear did not commit")
    repeat_version = int(p.persistence_state.get("state_version", 0))
    req(s.emblem.abandon_rebuild({}) == {}, "repeated MID1406 no-op failed")
    req(int(p.persistence_state.get("state_version", 0)) == repeat_version, "repeated MID1406 no-op created a commit")
    provider.assert_exhausted()


def test_pending_persists_restart_and_old_policy_version_saves_without_reroll() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0),
    ])
    p = blank_player("247090")
    p.mana = 100000
    seed(p, (160100101, 1))
    s = services(p, provider)
    out = s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 2})
    s.uow.consume_journal()
    req(out == {"inscript_items": [160100102]}, "restart setup proposal drift")
    p.emblem_state["pending_rebuild"]["policy_version"] = "emblem-v0"

    with tempfile.TemporaryDirectory() as td:
        db = JsonPlayerDatabase(Path(td) / "player.json")
        account = AccountIdentity(uid=p.account_uid)
        db.save(account, p)
        _, loaded = db.load(account, blank_player(p.player_id))
        no_entropy = ScriptedEntropyProvider([])
        restarted = RequestServices(loaded, DATA, lambda: None, catalog=CATALOG, entropy_provider=no_entropy)
        pending = restarted.emblem_state.pending_rebuild()
        req(pending is not None and pending["policy_version"] == "emblem-v0", "frozen pending policy version lost on restart")
        saved = restarted.emblem.save_rebuild({"item_id": 160100102})
        restarted.uow.consume_journal()
        req(saved == {"rebuild_items": [{"table_id": 160100102, "item_num": 1}]}, "restart frozen proposal did not save")
        req(restarted.stack_inventory.quantity(160100101) == 0 and restarted.stack_inventory.quantity(160100102) == 1, "restart save inventory drift")
        req(restarted.emblem_state.pending_rebuild() is None, "restart save did not clear pending")
        no_entropy.assert_exhausted()
    provider.assert_exhausted()


def test_post_entropy_rebuild_settlement_failure_rolls_back_cost_counter_and_pending() -> None:
    provider = ScriptedEntropyProvider([
        ScriptedEntropyDraw("emblem.reforge.scholarship_gate", 0, 10000, 9999),
        ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0),
    ])
    p = blank_player("247100")
    p.mana = 1_000_000
    seed(p, (160100701, 1))
    s = services(p, provider)
    before_state = copy.deepcopy(p.emblem_state)
    before_inventory = copy.deepcopy(p.backpack_items)
    before_version = int(p.persistence_state.get("state_version", 0))
    original_apply = s.mutation_settlement.apply

    def fail_after_entropy(plan):
        raise MutationSettlementError("forced I5 post-entropy settlement failure")

    s.mutation_settlement.apply = fail_after_entropy
    try:
        out = s.emblem.rebuild({"item_id": 160100701, "rebuild_num": 1, "cost_type": 2})
    finally:
        s.mutation_settlement.apply = original_apply
    req(out.get("error_code") == 1, "forced Reforge settlement failure did not fail closed")
    req(p.mana == 1_000_000, "failed Reforge settlement leaked cost")
    req(p.backpack_items == before_inventory, "failed Reforge settlement mutated inventory")
    req(p.emblem_state == before_state, "failed Reforge settlement leaked pity/pending")
    req(int(p.persistence_state.get("state_version", 0)) == before_version, "failed Reforge settlement advanced version")
    req(not s.uow.consume_journal(), "failed Reforge settlement published journal")
    provider.assert_exhausted()


def test_i5_public_routes_open_without_touching_other_emblem_routes() -> None:
    dispatch_src = (ROOT / "gxb_backend/dispatch/engine_dispatcher.py").read_text(encoding="utf-8")
    hero_src = (ROOT / "gxb_backend/handlers/heroes.py").read_text(encoding="utf-8")
    expected = {
        "INSCRIPTION_MAKE": "inscription_make",
        "INSCRIPTION_REBUILD": "inscription_rebuild",
        "INSCRIPTION_SAVE_REBUILD": "inscription_save_rebuild",
        "INSCRIPTION_ABANDON_REBUILD": "inscription_abandon_rebuild",
    }
    for symbol, handler in expected.items():
        req(f'"{symbol}": self.heroes.{handler}' in dispatch_src, f"{symbol} not routed to EmblemService owner")
        req(f"def {handler}(self, req: dict) -> dict:" in hero_src, f"{handler} handler missing")
    req('"INSCRIPTION_RESOLVE": self.heroes.inscription_resolve' in dispatch_src, "MID1404 route drift")
    req('"EXCHANGE_MATERIALS": self.heroes.inscription_exchange_materials' in dispatch_src, "MID1407 route drift")


def main() -> int:
    tests = [
        test_current_source_reforge_contract_and_policy_boundary,
        test_invalid_insufficient_and_unowned_rebuild_are_entropy_inert,
        test_single_mana_rebuild_is_paid_latest_proposal_without_source_debit,
        test_wire_identical_repeat_is_second_paid_latest_wins_proposal,
        test_ten_lv7_rebuild_is_sequential_and_charged_once,
        test_save_commits_frozen_candidate_without_reroll_or_double_projection,
        test_superseded_candidate_and_repeated_save_fail_without_mutation,
        test_stale_source_save_clears_pending_without_free_candidate,
        test_abandon_clears_pending_no_refund_and_repeat_is_noop,
        test_pending_persists_restart_and_old_policy_version_saves_without_reroll,
        test_post_entropy_rebuild_settlement_failure_rolls_back_cost_counter_and_pending,
        test_i5_public_routes_open_without_touching_other_emblem_routes,
    ]
    for test in tests:
        test()
        print("PASS", test.__name__)
    print(json.dumps({
        "pass": "247.0",
        "status": "PASS",
        "scope": "Emblem I5 MID1401/MID1405/MID1406 Reforge lifecycle",
        "checks": [test.__name__ for test in tests],
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
