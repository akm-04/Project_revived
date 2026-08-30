#!/usr/bin/env python3
from __future__ import annotations

import copy
import hashlib
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

from gxb_backend.content import EmblemSourceCatalog, GameDataCatalog
from gxb_backend.state.account import AccountIdentity
from gxb_backend.state.emblem_outcome_planner import EmblemOutcomePlanner, EmblemPolicyNotEnabled
from gxb_backend.state.emblem_policy import EmblemPolicyRegistry
from gxb_backend.state.emblem_state_repository import EmblemStateRepository
from gxb_backend.state.player_database import JsonPlayerDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.random_outcome_service import EntropyDrawRequest, RandomOutcomeService
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.unit_of_work import OperationContext, PlayerUnitOfWork


def req(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


class SequenceEntropy:
    def __init__(self, values: list[int]) -> None:
        self.values = list(values)
        self.requests: list[EntropyDrawRequest] = []

    def draw(self, request: EntropyDrawRequest) -> int:
        self.requests.append(request)
        if not self.values:
            raise AssertionError("unexpected entropy draw")
        value = self.values.pop(0)
        if value >= request.upper_exclusive:
            value %= request.upper_exclusive
        return value


def blank_player(pid: str = "241001") -> PlayerState:
    p = PlayerState(player_id=pid, account_uid=pid, player_name="Pass241-I0")
    p.heroes = {}
    p.backpack_items = []
    p.emblem_state = {}
    return p


def test_catalog_builder_is_current_source_exact() -> None:
    with tempfile.TemporaryDirectory() as td:
        generated = Path(td) / "emblem_source_catalog.json"
        subprocess.run(
            [sys.executable, str(ROOT / "tools/build_emblem_source_catalog.py"), "--src64", str(SRC64), "--output", str(generated)],
            check=True,
            stdout=subprocess.DEVNULL,
        )
        req(generated.read_bytes() == (DATA / "emblem_source_catalog.json").read_bytes(), "packaged Emblem source catalog is stale")
    source = EmblemSourceCatalog(DATA)
    req(len(source.inscription_ids()) == 23, "Emblem inscription census drift")
    req(len(source.concrete_item_ids()) == 254, "Emblem concrete item census drift")
    req(len(source.set_ids()) == 12, "Emblem set census drift")
    req(source.rules["outer_scholarship_probability"] == "SERVER_UNKNOWN", "server unknown leaked into source facts")
    req(source.physical_position(160400101) == 1, "Scholarship slot1 mapping drift")
    req(source.physical_position(160400102) == 2, "Scholarship slot2 mapping drift")
    req(source.physical_position(160500103) == 3, "Scholarship slot3 mapping drift")
    orphans = [item_id for item_id in source.concrete_item_ids() if not source.is_generation_candidate(item_id)]
    req(len(orphans) == 14 and all(source.physical_position(item_id) == 2 for item_id in orphans), "14 Honor artifact boundary drift")
    req(source.heart_recipe == {"components": [{"count": 60, "item_id": 50001347}], "item_id": 50001346, "mana": 0}, "Heart recipe source drift")


def test_policy_is_separate_and_i3_gate_is_disabled() -> None:
    source = EmblemSourceCatalog(DATA)
    policy = EmblemPolicyRegistry(DATA)
    entropy = SequenceEntropy([0, 69, 0])
    ros = RandomOutcomeService(entropy)
    planner = EmblemOutcomePlanner(source, policy, ros)
    req(policy.version == "emblem-v1", "Emblem policy version drift")
    req(policy.outer_scholarship_enabled is False, "I0 unexpectedly enabled outer Scholarship policy")
    first = planner.ordinary_candidate(10001, namespace="emblem.forge.ordinary")
    req(first.item_id == 160100101, "ordinary source-weight selection drift")
    family = planner.scholarship_family(namespace="emblem.forge.scholarship_family")
    req(family == 40001, "70/30 Scholarship family topology drift")
    special = planner.scholarship_candidate(family, namespace="emblem.forge.scholarship_item")
    req(special.item_id == 160400101, "Scholarship concrete source-weight selection drift")
    before = len(entropy.requests)
    try:
        planner.scholarship_gate()
    except EmblemPolicyNotEnabled:
        pass
    else:
        raise AssertionError("I0 outer Scholarship gate did not fail closed")
    req(len(entropy.requests) == before, "disabled outer gate consumed entropy")


def test_state_roundtrip_canonical_clear_and_uow_rollback() -> None:
    source = EmblemSourceCatalog(DATA)
    policy = EmblemPolicyRegistry(DATA)
    p = blank_player()
    commits: list[dict] = []
    uow = PlayerUnitOfWork(p, lambda: commits.append(copy.deepcopy(p.emblem_state)))
    repo = EmblemStateRepository(p, source, policy, uow=uow)
    req(repo.normalize() is True, "empty Emblem state did not normalize")
    req(p.emblem_state == EmblemStateRepository.default_state("emblem-v1"), "Emblem default state drift")

    proposal = {
        "source_item_id": 160100101,
        "source_inscription_id": 10001,
        "rebuild_num": 1,
        "cost_type": 2,
        "candidates": [160100102],
        "policy_version": "emblem-v1",
    }
    before = copy.deepcopy(p.emblem_state)
    try:
        with uow.transaction(OperationContext(actor_player_id=p.player_id, domain="emblem.test", operation_name="rollback")):
            repo.replace_pending(proposal)
            repo.set_misses_since_special("forge", 9)
            raise RuntimeError("force rollback")
    except RuntimeError:
        pass
    req(p.emblem_state == before, "Emblem state did not roll back with UoW")
    req(commits == [], "rolled-back Emblem state committed")

    with uow.transaction(OperationContext(actor_player_id=p.player_id, domain="emblem.test", operation_name="commit_pending")):
        pending = repo.replace_pending(proposal)
        req(pending["generation"] == 1, "proposal generation drift")
        repo.set_misses_since_special("reforge", 7)
    req(len(commits) == 1, "Emblem pending commit count drift")
    req(repo.pending_rebuild()["candidates"] == [160100102], "pending proposal candidate drift")
    req(repo.misses_since_special("reforge") == 7, "reforge counter drift")

    # Persistence merger must treat player.domains.emblem_state as one complete
    # canonical dictionary. Clearing pending may never resurrect old children.
    existing = {
        "player": {
            "domains": {
                "emblem_state": {
                    "schema_version": 1,
                    "policy_version": "emblem-v1",
                    "proposal_generation": 99,
                    "pending_rebuild": {"candidates": [160100109], "legacy": "must_not_survive"},
                    "scholarship_rng": {"forge": {"misses_since_special": 99}},
                    "legacy_nested": {"resurrect": True},
                }
            }
        }
    }
    current = {"player": {"domains": {"emblem_state": {}}}}
    merged = JsonPlayerDatabase.merge_preserving_extensions(existing, current)
    req(merged["player"]["domains"]["emblem_state"] == {}, "canonical Emblem clear resurrected nested state")

    with uow.transaction(OperationContext(actor_player_id=p.player_id, domain="emblem.test", operation_name="clear_pending")):
        req(repo.clear_pending() is True, "pending clear did not mutate")
    req(repo.pending_rebuild() is None, "pending proposal not cleared")

    with tempfile.TemporaryDirectory() as td:
        db = JsonPlayerDatabase(Path(td) / "player.json")
        account = AccountIdentity(uid=p.account_uid)
        db.save(account, p)
        loaded_account, loaded = db.load(account, blank_player())
        req(loaded_account.uid == p.account_uid, "account roundtrip drift")
        req(loaded.emblem_state == p.emblem_state, "Emblem state roundtrip drift")
        req("emblem_state" in JsonPlayerDatabase.serialize_player(loaded)["domains"], "Emblem state not routed under player.domains")


def test_request_graph_and_public_behavior_remain_pass232() -> None:
    source = EmblemSourceCatalog(DATA)
    game = GameDataCatalog.load(DATA / "game_data_catalog.json")
    p = blank_player("241002")
    services = RequestServices(p, DATA, lambda: None, catalog=game, entropy_provider=SequenceEntropy([0]))
    req(services.emblem.source is services.emblem_source, "Emblem service/source split")
    req(services.emblem.policy is services.emblem_policy, "Emblem service/policy split")
    req(services.emblem.outcomes is services.emblem_outcomes, "Emblem service/outcome split")
    req(services.emblem.state is services.emblem_state, "Emblem service/state split")
    req(services.emblem.uow is services.uow, "Emblem service/UoW split")
    req(services.emblem.inventory is services.inventory, "Emblem service/inventory authority split")
    req(services.emblem.heroes is services.heroes, "Emblem service/Hero authority split")
    req(services.emblem.make({"inscript_id": 10001, "make_num": 1}) == {"error_code": 1, "msg": "advanced_progression_server_algorithm_unresolved"}, "I0 Emblem make did not remain fail-closed")
    req(services.emblem.rebuild({"item_id": 160100101})["error_code"] == 1, "I0 Emblem rebuild did not remain fail-closed")
    req(source.inscription(10001) == services.emblem_source.inscription(10001), "request graph catalog drift")

    expected_hashes = {
        "gxb_backend/dispatch/engine_dispatcher.py": "c7714cdf1ef45dd6fae5c3851cd31b6fc54ae3385801c9003582f197710a38df",
        "gxb_backend/state/hero_advanced_progression_repository.py": "a01589a0659ae85dd9e7361c4d3f1ed1867ec42836de51f2d0d09aae5c9f4558",
        "gxb_backend/handlers/heroes.py": "8c94b58d5fde7551483a080f5c69c669f99bba423de6e62ab1932733839842c5",
    }
    for rel, expected in expected_hashes.items():
        got = hashlib.sha256((ROOT / rel).read_bytes()).hexdigest()
        req(got == expected, f"I0 unexpectedly changed public Pass232 Emblem route owner: {rel}")


def main() -> int:
    test_catalog_builder_is_current_source_exact()
    test_policy_is_separate_and_i3_gate_is_disabled()
    test_state_roundtrip_canonical_clear_and_uow_rollback()
    test_request_graph_and_public_behavior_remain_pass232()
    print("PASS241 Emblem I0 foundation self-test: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
