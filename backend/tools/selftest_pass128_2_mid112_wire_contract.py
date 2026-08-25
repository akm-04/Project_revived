#!/usr/bin/env python3
from __future__ import annotations

import copy
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.super_campaign_catalog import SUPER_FUNCTION_ID
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.testing.scripted_entropy import ScriptedEntropyProvider

GAME = GameDataCatalog.load(DATA / "game_data_catalog.json")
MANDATORY_CHAPTER_KEYS = {
    "normal_chapter_id",
    "normal_campaign_id",
    "super_chapter_id",
    "super_campaign_id",
    "normal_stars",
    "normal_bonus_id",
    "super_stars",
    "super_bonus_id",
}
SUPER_ZERO_KEYS = {
    "super_chapter_id",
    "super_campaign_id",
    "super_stars",
    "super_bonus_id",
}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def fresh_player(level: int) -> PlayerState:
    p = PlayerState(player_id=f"991282{level}", account_uid=f"991282{level}", player_name="Pass128.2", vip=0)
    p.lev = int(level)
    p.max_lev = 100
    p.func_ids = []
    p.function_state = {}
    # Reproduce the Pass128 runtime failure: persisted chapter_info is a legal
    # low-level state except that the mandatory zero-valued Super cursor keys are
    # absent. Login/bootstrap masks this via PlayerState.world_map_payload(), while
    # explicit MID112 returns WorldRepository.payload().
    p.world_map = {
        "normal": [{
            "campaign_id": 100001,
            "star": 0,
            "daily_limit": 0,
            "reset_count": 0,
            "is_partner_drop": 0,
        }],
        "super": [],
        "challenge": [],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": 1,
            "normal_campaign_id": 100001,
            "normal_stars": 0,
            "normal_bonus_id": 0,
            # super_* intentionally absent
        },
    }
    return p


def service(player: PlayerState, commits: list[int]) -> RequestServices:
    return RequestServices(
        player,
        DATA,
        lambda: commits.append(1),
        catalog=GAME,
        entropy_provider=ScriptedEntropyProvider([]),
    )


def assert_closed_super_wire(payload: dict, *, label: str) -> None:
    chapter = payload.get("chapter_info")
    require(isinstance(chapter, dict), f"{label}: chapter_info missing")
    missing = sorted(MANDATORY_CHAPTER_KEYS - set(chapter))
    require(not missing, f"{label}: mandatory chapter_info keys missing: {missing}")
    for key in SUPER_ZERO_KEYS:
        require(chapter.get(key) == 0, f"{label}: {key} must be numeric zero, got {chapter.get(key)!r}")


def test_fresh_level1_explicit_mid112_materializes_zero_keys_once() -> None:
    p = fresh_player(1)
    commits: list[int] = []
    svc = service(p, commits)
    payload = svc.world.payload()
    assert_closed_super_wire(payload, label="level1 explicit MID112")
    require(SUPER_FUNCTION_ID not in svc.function_state.announced_ids(), "level1 unexpectedly opened Function31")
    require(commits == [1], f"level1 wire self-heal should persist exactly once: {commits}")

    before = copy.deepcopy(payload)
    payload2 = svc.world.payload()
    assert_closed_super_wire(payload2, label="level1 repeated MID112")
    require(payload2 == before, "level1 repeated MID112 drifted canonical projection")
    require(commits == [1], f"level1 repeated MID112 ghost-saved: {commits}")


def test_level10_function31_closed_explicit_mid112_materializes_zero_keys_once() -> None:
    p = fresh_player(10)
    commits: list[int] = []
    svc = service(p, commits)
    payload = svc.world.payload()
    assert_closed_super_wire(payload, label="level10 explicit MID112")
    require(SUPER_FUNCTION_ID not in svc.function_state.announced_ids(), "level10 unexpectedly opened Function31")
    require(payload.get("super") == [], "level10 closed Function31 unexpectedly materialized a Super row")
    require(commits == [1], f"level10 wire self-heal should persist exactly once: {commits}")


def test_bootstrap_and_explicit_mid112_chapter_schema_parity() -> None:
    p = fresh_player(1)
    bootstrap = p.world_map_payload()
    assert_closed_super_wire(bootstrap, label="bootstrap MID112")
    bootstrap_keys = set(bootstrap["chapter_info"])

    commits: list[int] = []
    svc = service(p, commits)
    explicit = svc.world.payload()
    assert_closed_super_wire(explicit, label="explicit MID112")
    explicit_keys = set(explicit["chapter_info"])
    require(
        bootstrap_keys == explicit_keys,
        f"bootstrap/explicit chapter_info schema drift: bootstrap_only={sorted(bootstrap_keys-explicit_keys)} explicit_only={sorted(explicit_keys-bootstrap_keys)}",
    )


def test_existing_numeric_zero_state_is_idempotent() -> None:
    p = fresh_player(1)
    p.world_map["chapter_info"].update({key: 0 for key in SUPER_ZERO_KEYS})
    commits: list[int] = []
    svc = service(p, commits)
    payload = svc.world.payload()
    assert_closed_super_wire(payload, label="canonical zero state")
    require(commits == [], f"canonical zero-valued state should not be persisted again: {commits}")


def main() -> None:
    tests = [
        test_fresh_level1_explicit_mid112_materializes_zero_keys_once,
        test_level10_function31_closed_explicit_mid112_materializes_zero_keys_once,
        test_bootstrap_and_explicit_mid112_chapter_schema_parity,
        test_existing_numeric_zero_state_is_idempotent,
    ]
    for test in tests:
        test()
    print(f"PASS128.2 MID112 wire-contract self-test: {len(tests)}/{len(tests)} passed")


if __name__ == "__main__":
    main()
