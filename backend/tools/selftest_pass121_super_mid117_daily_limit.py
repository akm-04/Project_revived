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

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.campaign_drop_planner import CAMPAIGN_REPEAT_NAMESPACE
from gxb_backend.state.mid117_operation_receipt import RECEIPT_DOMAIN
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.testing.scripted_entropy import ScriptedEntropyDraw, ScriptedEntropyProvider

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
RAID_TICKET = 50001013
SUPER_ID = 100019
NORMAL_ID = 100001
UUIDS = [
    f"mid117-123e4567-e89b-42d3-a456-4266141740{i:02d}"
    for i in range(20)
]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def make_player(*, daily_limit: int = 3, energy: int = 200, tickets: int = 20) -> PlayerState:
    player = PlayerState(player_id="991210", account_uid="991210", player_name="Pass121", vip=15)
    player.lev = 100
    player.max_lev = 100
    player.energy = energy
    player.max_energy = 160
    player.energy_time = 0
    player.crystal = 100
    # Pass128 canonical unlocked-Elite fixture: materialized Super state is no
    # longer sufficient authority without the server-announced Function31.
    player.func_ids = [31]
    player.backpack_items = [
        {"table_id": RAID_TICKET, "item_num": tickets, "time": 0},
        {"table_id": 50001001, "item_num": 0, "time": 0},
        {"table_id": 50001002, "item_num": 0, "time": 0},
    ]
    player.world_map = {
        "normal": [{"campaign_id": NORMAL_ID, "star": 3, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}],
        "super": [{"campaign_id": SUPER_ID, "star": 3, "daily_limit": daily_limit, "reset_count": 0, "is_partner_drop": 0}],
        "challenge": [],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": 1,
            "normal_campaign_id": NORMAL_ID,
            "super_chapter_id": 1,
            "super_campaign_id": SUPER_ID,
            "normal_stars": 3,
            "normal_bonus_id": 0,
            "super_stars": 3,
            "super_bonus_id": 0,
        },
    }
    return player


def service(player: PlayerState, draws: list[ScriptedEntropyDraw], commits: list[int]):
    provider = ScriptedEntropyProvider(draws)
    svc = RequestServices(player, DATA, lambda: commits.append(1), catalog=CATALOG, entropy_provider=provider)
    return svc, provider


def req(op_id: str, *, campaign_id: int = SUPER_ID, campaign_type: int = 2, sweep_num: int = 1, sweep_type: int = 1) -> dict:
    return {
        "campaign_sweep_op_id": op_id,
        "campaign_id": campaign_id,
        "campaign_type": campaign_type,
        "sweep_num": sweep_num,
        "sweep_type": sweep_type,
        "awake_mission": 0,
    }


def miss_draws(count: int) -> list[ScriptedEntropyDraw]:
    # Source Super 100019 has sixteen repeat rows with non-zero residual rates.
    return [
        ScriptedEntropyDraw(CAMPAIGN_REPEAT_NAMESPACE, i, 10000, 9999)
        for i in range(16 * count)
    ]


def daily(player: PlayerState) -> int:
    return int(player.world_map["super"][0]["daily_limit"])


def test_batch_consumes_exact_requested_attempts() -> None:
    cases = [(1, 2), (2, 1), (3, 0)]
    for index, (count, expected) in enumerate(cases):
        player = make_player(daily_limit=3)
        commits: list[int] = []
        svc, provider = service(player, miss_draws(count), commits)
        result = svc.world.sweep(req(UUIDS[index], sweep_num=count))
        require(result.get("error_code", 0) == 0, f"{count}x Super sweep rejected: {result}")
        require(daily(player) == expected, f"{count}x Super sweep expected remaining {expected}, got {daily(player)}")
        require(int(result["campaign"]["daily_limit"]) == expected, f"{count}x response did not project decremented row: {result['campaign']}")
        provider.assert_exhausted()
        require(svc.uow.get_receipt(RECEIPT_DOMAIN, UUIDS[index]) is not None, f"{count}x Super sweep missing receipt")
        require(commits == [1], f"{count}x Super sweep commit drift: {commits}")


def test_insufficient_attempts_fail_before_entropy_cost_or_receipt() -> None:
    player = make_player(daily_limit=2)
    commits: list[int] = []
    # A valid Campaign RNG script is deliberately available. None may be consumed.
    svc, provider = service(player, miss_draws(3), commits)
    before = (player.energy, player.crystal, svc.stack_inventory.quantity(RAID_TICKET), copy.deepcopy(player.backpack_items))
    result = svc.world.sweep(req(UUIDS[4], sweep_num=3))
    require(result.get("error_code") == 1 and result.get("msg") == "campaign_daily_limit_insufficient", f"attempt overflow did not fail closed: {result}")
    after = (player.energy, player.crystal, svc.stack_inventory.quantity(RAID_TICKET), player.backpack_items)
    require(after == before, "attempt overflow mutated cost/reward state")
    require(daily(player) == 2 and int(result["campaign"]["daily_limit"]) == 2, "attempt overflow changed/projected wrong remaining count")
    require(provider.consumed == (), "attempt overflow consumed Campaign entropy")
    require(svc.uow.get_receipt(RECEIPT_DOMAIN, UUIDS[4]) is None, "attempt overflow committed a receipt")
    require(commits == [], "attempt overflow committed player state")


def test_receipt_retry_is_exactly_once_for_attempts() -> None:
    player = make_player(daily_limit=3)
    commits: list[int] = []
    svc1, provider1 = service(player, miss_draws(2), commits)
    first = svc1.world.sweep(req(UUIDS[5], sweep_num=2))
    require(first.get("error_code", 0) == 0 and daily(player) == 1, f"setup 2x Super sweep failed: {first}")
    provider1.assert_exhausted()

    svc2, provider2 = service(player, [], commits)
    replay = svc2.world.sweep(req(UUIDS[5], sweep_num=2))
    require(replay.get("items") == first.get("items"), "receipt replay changed static rewards")
    require(daily(player) == 1, "receipt replay double-consumed Super attempts")
    require(int(replay["campaign"]["daily_limit"]) == 1, "receipt replay did not render current Super remaining count")
    require(provider2.consumed == (), "receipt replay consumed entropy")
    require(commits == [1], f"receipt replay created an extra commit: {commits}")


def test_fresh_uuid_at_zero_fails_without_mutation() -> None:
    player = make_player(daily_limit=0)
    commits: list[int] = []
    svc, provider = service(player, miss_draws(1), commits)
    before = (player.energy, svc.stack_inventory.quantity(RAID_TICKET), copy.deepcopy(player.backpack_items))
    result = svc.world.sweep(req(UUIDS[6]))
    require(result.get("error_code") == 1 and result.get("msg") == "campaign_daily_limit_insufficient", f"zero-attempt Super sweep did not fail closed: {result}")
    require((player.energy, svc.stack_inventory.quantity(RAID_TICKET), player.backpack_items) == before, "zero-attempt request mutated state")
    require(provider.consumed == (), "zero-attempt request consumed entropy")
    require(svc.uow.get_receipt(RECEIPT_DOMAIN, UUIDS[6]) is None, "zero-attempt request committed receipt")
    require(commits == [], "zero-attempt request committed state")


def test_super_mode_never_falls_back_to_normal_row() -> None:
    player = make_player(daily_limit=3)
    commits: list[int] = []
    svc, provider = service(player, [], commits)
    before = (player.energy, svc.stack_inventory.quantity(RAID_TICKET), daily(player))
    result = svc.world.sweep(req(UUIDS[7], campaign_id=NORMAL_ID, campaign_type=2))
    require(result.get("error_code") == 1 and result.get("msg") == "campaign_super_source_membership_invalid", f"cross-mode Super request did not fail source membership: {result}")
    require((player.energy, svc.stack_inventory.quantity(RAID_TICKET), daily(player)) == before, "cross-mode request mutated state")
    require(provider.consumed == (), "cross-mode request consumed entropy")
    require(commits == [], "cross-mode request committed state")


def test_normal_mid117_remains_unaffected() -> None:
    player = make_player(daily_limit=3)
    commits: list[int] = []
    # Normal 100001 has twenty-nine residual draws in the frozen Pass114 policy.
    draws = [ScriptedEntropyDraw(CAMPAIGN_REPEAT_NAMESPACE, i, 10000, 9999) for i in range(29)]
    svc, provider = service(player, draws, commits)
    result = svc.world.sweep(req(UUIDS[8], campaign_id=NORMAL_ID, campaign_type=1))
    require(result.get("error_code", 0) == 0, f"Normal MID117 regressed: {result}")
    require(daily(player) == 3, "Normal MID117 consumed Super daily_limit")
    provider.assert_exhausted()
    require(commits == [1], f"Normal MID117 commit drift: {commits}")


def main() -> int:
    tests = [
        test_batch_consumes_exact_requested_attempts,
        test_insufficient_attempts_fail_before_entropy_cost_or_receipt,
        test_receipt_retry_is_exactly_once_for_attempts,
        test_fresh_uuid_at_zero_fails_without_mutation,
        test_super_mode_never_falls_back_to_normal_row,
        test_normal_mid117_remains_unaffected,
    ]
    for test in tests:
        test()
    report = {
        "pass": "121.0",
        "status": "PASS",
        "scope": "Super Campaign MID117 daily-limit atomicity only",
        "checks": [
            "remaining3 count1 -> remaining2",
            "remaining3 count2 -> remaining1",
            "remaining3 count3 -> remaining0",
            "remaining2 count3 fails before entropy/cost/receipt",
            "same UUID retry consumes zero additional attempts and zero entropy",
            "fresh UUID at remaining0 fails before entropy/cost/receipt",
            "Super campaign_type=2 cannot borrow a Normal row",
            "Normal MID117 behavior remains unaffected",
        ],
    }
    (ROOT / "docs/PASS121_SUPER_MID117_DAILY_LIMIT_SELFTEST.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
