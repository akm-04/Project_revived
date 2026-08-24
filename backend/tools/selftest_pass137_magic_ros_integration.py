#!/usr/bin/env python3
"""Pass137 Phase 1: Magic MID70 request-scoped ROS integration regression."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.random_outcome_service import (
    EntropyDrawRequest,
    NamespacedRandbelowAdapter,
)
from gxb_backend.state.request_services import RequestServices

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
TARGET_ID = 11001

UNCHANGED_MAGIC_HASHES = {
    "gxb_backend/state/magic_summon_private_policy.py": "53b064287b72a67d0fdc6eb6318a390684369f59a372b0f0c3372cfbd736731e",
    "gxb_backend/state/summon_repository.py": "7c3f601e3c44570eb0da54f9faa56906a79270ecba6b1198d4a85ab479df5de6",
    "data/magic_summon_private_policy.json": "997589319b04ab296e6ad1830cde79a40ea383b2890bf3b2b9da4ceb41dc6856",
    "data/magic_summon_source_catalog.json": "725084492853db2aea5483d34eb8849d59af130fe909daa56ad47c65b28f5ff1",
}


def require(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class RecordingZeroEntropy:
    def __init__(self) -> None:
        self.requests: list[EntropyDrawRequest] = []

    def draw(self, request: EntropyDrawRequest) -> int:
        self.requests.append(request)
        return 0


def make_services(*, directional_target: bool = False) -> tuple[PlayerState, RequestServices, list[str], RecordingZeroEntropy]:
    player = apply_established_profile(PlayerState())
    player.account_uid = "13700001"
    player.player_id = "13700001"
    player.player_name = "Pass137 Magic ROS"
    player.crystal = 999_999
    player.vip = 15
    player.heroes = {
        "90001": {
            "partner_id": 90001,
            "table_id": TARGET_ID,
            "star": 1,
            "lev": 1,
        }
    }
    player.summon = dict(player.summon or {})
    player.summon["directional_show_id"] = TARGET_ID if directional_target else 0
    commits: list[str] = []
    entropy = RecordingZeroEntropy()
    services = RequestServices(
        player,
        DATA,
        lambda: commits.append("commit"),
        catalog=CATALOG,
        entropy_provider=entropy,
    )
    return player, services, commits, entropy


def test_nonchange_hashes() -> None:
    for rel, expected in UNCHANGED_MAGIC_HASHES.items():
        require(sha256(ROOT / rel) == expected, f"Phase 1 changed frozen Magic behavior/policy file: {rel}")


def test_production_composition_identity() -> None:
    _player, services, _commits, entropy = make_services()
    adapter = services.magic_summon_planner.random
    require(isinstance(adapter, NamespacedRandbelowAdapter), "Magic production planner lacks ROS adapter")
    require(adapter._namespace == "summon.magic", "Magic ROS namespace drift")
    require(adapter._service is services.random_outcomes, "Magic planner does not share request ROS identity")
    require(services.random_outcomes._entropy is entropy, "request ROS does not own injected entropy provider")


def test_mid71_is_deterministic_and_consumes_zero_entropy() -> None:
    player, services, _commits, entropy = make_services(directional_target=False)
    before_crystal = player.crystal
    response = services.summon.magic_switch_hero({"partner_id": TARGET_ID})
    require(response == {"partner_id": TARGET_ID}, f"MID71 source-valid switch failed: {response}")
    require(player.summon.get("directional_show_id") == TARGET_ID, "MID71 did not persist selected target")
    require(player.crystal == before_crystal, "MID71 changed Crystal")
    require(entropy.requests == [], "MID71 consumed gameplay entropy")


def test_mid70_single_uses_exact_request_ros_namespace() -> None:
    player, services, _commits, entropy = make_services(directional_target=True)
    before_crystal = player.crystal
    response = services.summon.magic_summon_hero({"partner_id": TARGET_ID, "summon_time": 1})
    require(response.get("error_code", 0) == 0, f"MID70 x1 failed: {response}")
    require(len(response.get("result") or []) == 1, "MID70 x1 result multiplicity changed")
    require(len(response.get("stick_items") or []) == 1, "MID70 x1 fragment channel changed")
    require(player.crystal == before_crystal - 500, "MID70 x1 Crystal cost changed")
    require(len(entropy.requests) == 1, f"MID70 x1 entropy topology changed: {len(entropy.requests)} draws")
    draw = entropy.requests[0]
    require(draw.namespace == "summon.magic", "MID70 x1 used wrong namespace")
    require(draw.ordinal == 0, "MID70 x1 first namespace ordinal drift")


def test_mid70_ten_uses_request_ros_for_all_random_choices() -> None:
    player, services, _commits, entropy = make_services(directional_target=True)
    before_crystal = player.crystal
    response = services.summon.magic_summon_hero({"partner_id": TARGET_ID, "summon_time": 10})
    require(response.get("error_code", 0) == 0, f"MID70 x10 failed: {response}")
    require(len(response.get("result") or []) == 10, "MID70 x10 byproduct multiplicity changed")
    require(len(response.get("stick_items") or []) == 1, "MID70 x10 fragment channel changed")
    require(player.crystal == before_crystal - 5000, "MID70 x10 Crystal cost changed")
    # Private Magic v1 source/policy topology: ten byproduct rolls + one
    # selected-fragment crit-table roll. Phase 1 changes only entropy owner.
    require(len(entropy.requests) == 11, f"MID70 x10 entropy topology changed: {len(entropy.requests)} draws")
    require(all(r.namespace == "summon.magic" for r in entropy.requests), "MID70 x10 escaped summon.magic")
    require([r.ordinal for r in entropy.requests] == list(range(11)), "MID70 x10 namespace ordinals drift")


def main() -> None:
    tests = [
        test_nonchange_hashes,
        test_production_composition_identity,
        test_mid71_is_deterministic_and_consumes_zero_entropy,
        test_mid70_single_uses_exact_request_ros_namespace,
        test_mid70_ten_uses_request_ros_for_all_random_choices,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    report = {
        "pass": "137.0",
        "phase": 1,
        "status": "STATIC_REGRESSION_ACCEPTED",
        "tests": len(tests),
        "magic_namespace": "summon.magic",
        "mid71_entropy_draws": 0,
        "mid70_x1_entropy_draws": 1,
        "mid70_x10_entropy_draws": 11,
        "behavior_policy_hashes_unchanged": True,
    }
    (ROOT / "docs/PASS137_MAGIC_ROS_SELFTEST.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    print(f"PASS Pass137 Magic ROS integration ({len(tests)} tests)")


if __name__ == "__main__":
    main()
