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
from gxb_backend.content.campaign_drop_source_catalog import CampaignDropSourceCatalog
from gxb_backend.state.campaign_drop_planner import CAMPAIGN_REPEAT_NAMESPACE
from gxb_backend.state.campaign_sweep_economy_policy import CampaignSweepEconomyPolicy
from gxb_backend.state.mid117_operation_receipt import RECEIPT_DOMAIN
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.response_projector import ResponseProjector
from gxb_backend.state.reward_transaction_service import RewardValidationError
from gxb_backend.testing.scripted_entropy import ScriptedEntropyDraw, ScriptedEntropyProvider

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
DROP_SOURCE = CampaignDropSourceCatalog(DATA)
META = json.loads((DATA / "campaign_economy_meta.json").read_text(encoding="utf-8"))
OWNERSHIP = json.loads((DATA / "pass75_campaign_ownership_meta.json").read_text(encoding="utf-8"))["campaigns"]
RAID_TICKET = 50001013
NORMAL_ID = 100001
SUPER_ID = 100019
UUIDS = [
    f"mid117-123e4567-e89b-42d3-a456-4266141741{i:02d}"
    for i in range(30)
]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def source_row(campaign_id: int) -> dict:
    return OWNERSHIP[str(campaign_id)]


def min_cumulative_exp(level: int) -> int:
    if level <= 1:
        return 0
    return int(META["player_levels"][str(level - 1)]["total_exp"])


def make_player(
    *,
    level: int = 18,
    exp: int | None = None,
    energy: int = 300,
    mana: int = 10_000,
    crystal: int = 100,
    tickets: int = 50,
    super_daily: int | None = None,
    announce_elite: bool = True,
) -> PlayerState:
    player = PlayerState(player_id="991310", account_uid="991310", player_name="Pass131", vip=15)
    player.lev = level
    player.max_lev = 100
    player.exp = min_cumulative_exp(level) if exp is None else int(exp)
    player.energy = energy
    player.max_energy = int(META["player_levels"][str(max(1, level))]["energy"])
    player.energy_time = 0
    player.mana = mana
    player.crystal = crystal
    player.func_ids = [31] if announce_elite else []
    player.backpack_items = [
        {"table_id": RAID_TICKET, "item_num": tickets, "time": 0},
        {"table_id": 50001001, "item_num": 0, "time": 0},
        {"table_id": 50001002, "item_num": 0, "time": 0},
    ]
    normal = {
        "campaign_id": NORMAL_ID,
        "star": 3,
        "daily_limit": 0,
        "reset_count": 0,
        "is_partner_drop": 0,
    }
    super_rows = []
    if super_daily is not None:
        super_rows.append({
            "campaign_id": SUPER_ID,
            "star": 3,
            "daily_limit": int(super_daily),
            "reset_count": 0,
            "is_partner_drop": 0,
        })
    player.world_map = {
        "normal": [normal],
        "super": super_rows,
        "challenge": [],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": 1,
            "normal_campaign_id": NORMAL_ID,
            "normal_stars": 3,
            "normal_bonus_id": 0,
            "super_chapter_id": 1 if super_rows else 0,
            "super_campaign_id": SUPER_ID if super_rows else 0,
            "super_stars": 3 if super_rows else 0,
            "super_bonus_id": 0,
        },
    }
    return player


def residual_draw_count(campaign_id: int) -> int:
    _pool, rows = DROP_SOURCE.pool_for(campaign_id, "repeat")
    return sum(1 for row in rows if int(row.increase_rate) % 10_000)


def miss_draws(campaign_id: int, sweep_num: int) -> list[ScriptedEntropyDraw]:
    per_run = residual_draw_count(campaign_id)
    return [
        ScriptedEntropyDraw(CAMPAIGN_REPEAT_NAMESPACE, i, 10_000, 9_999)
        for i in range(per_run * sweep_num)
    ]


def service(player: PlayerState, draws: list[ScriptedEntropyDraw], commits: list[int]):
    provider = ScriptedEntropyProvider(draws)
    svc = RequestServices(player, DATA, lambda: commits.append(1), catalog=CATALOG, entropy_provider=provider)
    return svc, provider


def req(
    op_id: str,
    *,
    campaign_id: int = NORMAL_ID,
    campaign_type: int = 1,
    sweep_num: int = 1,
    sweep_type: int = 1,
) -> dict:
    return {
        "campaign_sweep_op_id": op_id,
        "campaign_id": campaign_id,
        "campaign_type": campaign_type,
        "sweep_num": sweep_num,
        "sweep_type": sweep_type,
        "awake_mission": 0,
    }


def run_projected(svc: RequestServices, request: dict) -> dict:
    projector = ResponseProjector.capture(svc.player, resource_registry=svc.resource_registry)
    result = svc.world.sweep(request)
    result = svc.apply_semantic_deltas(result)
    journal = svc.uow.consume_journal()
    return projector.project(result, svc.player, committed_journal=journal, profile=None)


def test_policy_level10_crossing() -> None:
    plan = CampaignSweepEconomyPolicy.plan(
        base_exp=6,
        mana_gain=495,
        sweep_num=2,
        start_level=10,
        start_exp=96,
        normal_exp_multiplier=3,
        total_exp_threshold=lambda level: META["player_levels"][str(level)]["total_exp"],
    )
    require(plan.wire_economys() == [{"exp": 6, "mana": 495}, {"exp": 6, "mana": 495}], "wire rows are not raw source base values")
    require(plan.per_run_account_exp == (6, 18), f"low-level crossing multiplier drift: {plan.per_run_account_exp}")
    require(plan.total_player_exp_gain == 24 and plan.total_mana_gain == 990, "crossing totals drift")
    require(plan.simulated_start_level == 10 and plan.simulated_end_level == 11, "crossing simulated level drift")


def test_normal_one_sweep_level_gt10() -> None:
    player = make_player(level=18)
    commits: list[int] = []
    svc, provider = service(player, miss_draws(NORMAL_ID, 1), commits)
    before = (player.exp, player.mana, player.energy, svc.stack_inventory.quantity(RAID_TICKET))
    result = run_projected(svc, req(UUIDS[0]))
    row = source_row(NORMAL_ID)
    require(result.get("error_code", 0) == 0, f"Normal sweep rejected: {result}")
    require(result["economys"] == [{"exp": row["energy_cost"], "mana": row["mana_gain"]}], f"Normal wire economy drift: {result['economys']}")
    require(player.exp - before[0] == row["energy_cost"] * 3, "Normal cumulative player EXP delta drift")
    require(player.mana - before[1] == row["mana_gain"], "Normal cumulative Mana delta drift")
    require(player.energy == before[2] - row["energy_cost"], "Normal Energy cost drift without level-up")
    require(svc.stack_inventory.quantity(RAID_TICKET) == before[3] - 1, "Normal ticket cost drift")
    require(result["economy_"]["exp"] == player.exp and result["economy_"]["mana"] == player.mana and result["economy_"]["energy"] == player.energy, "Normal cumulative projection drift")
    provider.assert_exhausted()
    require(commits == [1], f"Normal one-sweep commit drift: {commits}")


def test_normal_ten_sweep_level_gt10() -> None:
    player = make_player(level=18, energy=500, tickets=50)
    commits: list[int] = []
    svc, provider = service(player, miss_draws(NORMAL_ID, 10), commits)
    before_exp, before_mana = player.exp, player.mana
    result = run_projected(svc, req(UUIDS[1], sweep_num=10))
    row = source_row(NORMAL_ID)
    require(len(result["economys"]) == 10 and all(e == {"exp": row["energy_cost"], "mana": row["mana_gain"]} for e in result["economys"]), "ten-sweep wire economy rows drift")
    require(player.exp - before_exp == row["energy_cost"] * 3 * 10, "ten-sweep cumulative EXP total drift")
    require(player.mana - before_mana == row["mana_gain"] * 10, "ten-sweep cumulative Mana total drift")
    provider.assert_exhausted()
    require(commits == [1], f"ten-sweep should commit once: {commits}")
    require(svc.uow.get_receipt(RECEIPT_DOMAIN, UUIDS[1]) is not None, "ten-sweep receipt missing")


def test_level10_crossing_uses_progression_owner_and_levelup_energy() -> None:
    player = make_player(level=10, exp=96, energy=100, tickets=10, announce_elite=False)
    commits: list[int] = []
    svc, provider = service(player, miss_draws(NORMAL_ID, 2), commits)
    result = run_projected(svc, req(UUIDS[2], sweep_num=2))
    row = source_row(NORMAL_ID)
    # 1st run: +6 at 1x crosses 102 -> level 11. 2nd run: +18 at 3x.
    require(player.exp == 120, f"level10 crossing cumulative EXP drift: {player.exp}")
    require(player.lev == 11, f"level10 crossing level drift: {player.lev}")
    expected_energy = 100 - row["energy_cost"] * 2 + int(META["player_levels"]["10"]["award_energy"])
    require(player.energy == expected_energy, f"level-up Energy owner drift: {player.energy} != {expected_energy}")
    require(result["economy_"]["energy"] == expected_energy and result["economy_"]["exp"] == 120 and result["economy_"]["lev"] == 11, f"crossing projection drift: {result.get('economy_')}")
    require(31 in result.get("new_funcs_", []), f"Function31 semantic delta missing on level11 crossing: {result}")
    require(result["economys"] == [{"exp": 6, "mana": 495}, {"exp": 6, "mana": 495}], "crossing wire rows must remain raw base values")
    provider.assert_exhausted()
    require(commits == [1], f"level crossing commit drift: {commits}")


def test_super_sweep_exp_mana_and_attempts_are_exactly_once() -> None:
    player = make_player(level=18, super_daily=3)
    commits: list[int] = []
    svc, provider = service(player, miss_draws(SUPER_ID, 2), commits)
    before_exp, before_mana = player.exp, player.mana
    request = req(UUIDS[3], campaign_id=SUPER_ID, campaign_type=2, sweep_num=2)
    first = run_projected(svc, request)
    row = source_row(SUPER_ID)
    require(int(player.world_map["super"][0]["daily_limit"]) == 1, "Super daily_limit did not decrement by batch")
    require(player.exp - before_exp == row["energy_cost"] * 3 * 2, "Super cumulative EXP drift")
    require(player.mana - before_mana == row["mana_gain"] * 2, "Super cumulative Mana drift")
    require(first["economys"] == [{"exp": row["energy_cost"], "mana": row["mana_gain"]}] * 2, "Super wire economys drift")
    provider.assert_exhausted()
    snapshot = (player.exp, player.mana, player.energy, svc.stack_inventory.quantity(RAID_TICKET), int(player.world_map["super"][0]["daily_limit"]))

    svc2, provider2 = service(player, [], commits)
    replay = run_projected(svc2, request)
    require((player.exp, player.mana, player.energy, svc2.stack_inventory.quantity(RAID_TICKET), int(player.world_map["super"][0]["daily_limit"])) == snapshot, "Super receipt replay mutated state")
    require(replay["economys"] == first["economys"] and replay["items"] == first["items"], "Super replay changed static sweep outcome")
    require(provider2.consumed == (), "Super replay consumed entropy")
    require(commits == [1], f"Super replay committed twice: {commits}")


def test_replay_refreshes_current_cumulative_exp_and_mana() -> None:
    player = make_player(level=18)
    commits: list[int] = []
    svc, provider = service(player, miss_draws(NORMAL_ID, 1), commits)
    request = req(UUIDS[4])
    first = run_projected(svc, request)
    provider.assert_exhausted()
    static_economys = copy.deepcopy(first["economys"])
    state_after_first = (player.exp, player.mana, player.energy)

    # Simulate later canonical operations: receipt replay must project current
    # cumulative owners, not stale totals captured when this MID117 committed.
    player.exp += 111
    player.mana += 222
    player.energy += 3
    current = (player.exp, player.mana, player.energy)
    svc2, provider2 = service(player, [], commits)
    replay = run_projected(svc2, request)
    require(replay["economys"] == static_economys, "replay did not freeze per-run economys")
    require(replay["economy_"]["exp"] == current[0], "replay did not refresh PlayerProgressionService-owned EXP")
    require(replay["economy_"]["mana"] == current[1], "replay did not refresh EconomyLedger-owned Mana")
    require(replay["economy_"]["energy"] == current[2], "replay did not refresh temporal Energy")
    require((player.exp, player.mana, player.energy) == current, "replay mutated cumulative owners")
    require(provider2.consumed == (), "replay consumed entropy")
    require(commits == [1], f"replay caused extra persistence: {commits}")
    require(state_after_first != current, "replay refresh test fixture did not move state")


def test_crystal_sweep_projects_all_cumulative_fields() -> None:
    player = make_player(level=18, crystal=25)
    commits: list[int] = []
    svc, provider = service(player, miss_draws(NORMAL_ID, 1), commits)
    before_crystal = player.crystal
    result = run_projected(svc, req(UUIDS[5], sweep_type=2))
    require(player.crystal == before_crystal - 1, "Crystal sweep cost drift")
    for key in ("energy", "crystal", "mana", "exp"):
        require(key in result.get("economy_", {}), f"Crystal sweep missing cumulative {key}: {result}")
    require(result["economy_"]["crystal"] == player.crystal, "Crystal projection stale")
    provider.assert_exhausted()
    require(commits == [1], f"Crystal sweep commit drift: {commits}")


def test_reward_validation_fails_before_entropy_or_cost() -> None:
    player = make_player(level=18)
    commits: list[int] = []
    svc, provider = service(player, miss_draws(NORMAL_ID, 1), commits)
    before = (player.exp, player.mana, player.energy, svc.stack_inventory.quantity(RAID_TICKET), copy.deepcopy(player.backpack_items))

    def reject(_plan):
        raise RewardValidationError("pass131 forced reward validation failure")

    svc.rewards.validate = reject  # type: ignore[method-assign]
    result = svc.world.sweep(req(UUIDS[6]))
    after = (player.exp, player.mana, player.energy, svc.stack_inventory.quantity(RAID_TICKET), player.backpack_items)
    require(result.get("error_code") == 1 and "forced reward validation failure" in result.get("msg", ""), f"reward validation did not fail closed: {result}")
    require(after == before, "reward validation failure mutated costs/rewards")
    require(provider.consumed == (), "reward validation failure consumed entropy")
    require(svc.uow.get_receipt(RECEIPT_DOMAIN, UUIDS[6]) is None, "reward validation failure staged receipt")
    require(commits == [], "reward validation failure persisted state")


def test_post_rng_progression_failure_rolls_back_all_mutation() -> None:
    player = make_player(level=18)
    commits: list[int] = []
    svc, provider = service(player, miss_draws(NORMAL_ID, 1), commits)
    before = (
        player.exp,
        player.mana,
        player.energy,
        player.crystal,
        svc.stack_inventory.quantity(RAID_TICKET),
        copy.deepcopy(player.backpack_items),
    )

    def explode(_amount, *, persist=False):
        raise RuntimeError("pass131 forced post-RNG progression failure")

    svc.player_progression.grant_exp = explode  # type: ignore[method-assign]
    result = svc.world.sweep(req(UUIDS[7]))
    after = (
        player.exp,
        player.mana,
        player.energy,
        player.crystal,
        svc.stack_inventory.quantity(RAID_TICKET),
        player.backpack_items,
    )
    require(result.get("error_code") == 1 and "forced post-RNG progression failure" in result.get("msg", ""), f"post-RNG owner failure did not fail closed: {result}")
    require(after == before, "outer PlayerUnitOfWork did not roll back costs/items/Mana after progression failure")
    require(provider.consumed != (), "post-RNG failure fixture did not actually reach Campaign entropy")
    require(svc.uow.get_receipt(RECEIPT_DOMAIN, UUIDS[7]) is None, "failed post-RNG transaction staged a durable receipt")
    require(commits == [], "failed post-RNG transaction persisted state")


def test_mentor_social_plane_is_not_part_of_core_policy() -> None:
    plan = CampaignSweepEconomyPolicy.plan(
        base_exp=12,
        mana_gain=930,
        sweep_num=1,
        start_level=50,
        start_exp=min_cumulative_exp(50),
        normal_exp_multiplier=3,
        total_exp_threshold=lambda level: META["player_levels"][str(level)]["total_exp"],
    )
    require(plan.total_player_exp_gain == 36, "core policy accidentally added non-core mentor/student EXP")


def main() -> int:
    tests = [
        test_policy_level10_crossing,
        test_normal_one_sweep_level_gt10,
        test_normal_ten_sweep_level_gt10,
        test_level10_crossing_uses_progression_owner_and_levelup_energy,
        test_super_sweep_exp_mana_and_attempts_are_exactly_once,
        test_replay_refreshes_current_cumulative_exp_and_mana,
        test_crystal_sweep_projects_all_cumulative_fields,
        test_reward_validation_fails_before_entropy_or_cost,
        test_post_rng_progression_failure_rolls_back_all_mutation,
        test_mentor_social_plane_is_not_part_of_core_policy,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    report = {
        "pass": "131.0",
        "status": "PASS",
        "scope": "Campaign MID117 player EXP + Mana settlement",
        "checks": [test.__name__ for test in tests],
        "source_contract": {
            "normal_100001": {"energy_cost": source_row(NORMAL_ID)["energy_cost"], "mana_gain": source_row(NORMAL_ID)["mana_gain"]},
            "super_100019": {"energy_cost": source_row(SUPER_ID)["energy_cost"], "mana_gain": source_row(SUPER_ID)["mana_gain"]},
            "low_level_policy": "1x while simulated pre-run level<=10; 3x after crossing; raw wire EXP remains energy_cost",
            "mentor_student": "deferred non-core social vertical",
        },
    }
    (ROOT / "docs/PASS131_CAMPAIGN_EXP_MANA_SELFTEST.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
