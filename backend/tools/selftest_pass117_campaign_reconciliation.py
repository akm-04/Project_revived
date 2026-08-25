#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.campaign_battle_operation_receipt import (
    STAGE_RECEIPT_DOMAIN,
    RESULT_RECEIPT_DOMAIN,
    RECEIPT_MODE,
    RETENTION_POLICY,
)
from gxb_backend.state.campaign_drop_planner import CAMPAIGN_FIRST_CLEAR_NAMESPACE
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.testing.scripted_entropy import ScriptedEntropyDraw, ScriptedEntropyProvider

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
DROP_SOURCE = json.loads((DATA / "campaign_drop_source_catalog.json").read_text(encoding="utf-8"))["campaigns"]
UUID1 = "mid113-123e4567-e89b-42d3-a456-426614174000"
UUID2 = "mid113-123e4567-e89b-42d3-a456-426614174001"
UUID3 = "mid113-123e4567-e89b-42d3-a456-426614174002"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def make_player(campaign_id: int, *, star: int = 0, chapter: int | None = None, energy: int = 100) -> PlayerState:
    chapter = int(chapter if chapter is not None else str(campaign_id)[:2] if campaign_id >= 1000000 else 1)
    p = PlayerState(player_id="991170", account_uid="991170", player_name="Pass117", vip=15)
    p.lev = 100
    p.max_lev = 100
    p.energy = energy
    p.max_energy = 160
    p.energy_time = 0
    p.crystal = 1000
    p.world_map = {
        "normal": [{"campaign_id": campaign_id, "star": star, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}],
        "super": [],
        "challenge": [],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": chapter,
            "normal_campaign_id": campaign_id,
            "super_chapter_id": 0,
            "super_campaign_id": 0,
            "normal_stars": star,
            "normal_bonus_id": 0,
            "super_stars": 0,
            "super_bonus_id": 0,
        },
    }
    return p


def make_super_player(campaign_id: int = 1600022, *, star: int = 0, daily_limit: int = 3, energy: int = 100) -> PlayerState:
    p = PlayerState(player_id="991171", account_uid="991171", player_name="Pass117Super", vip=15)
    p.lev = 100
    p.max_lev = 100
    p.energy = energy
    p.max_energy = 160
    p.energy_time = 0
    p.crystal = 1000
    p.world_map = {
        "normal": [{"campaign_id": 1600016, "star": 3, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}],
        "super": [{"campaign_id": campaign_id, "star": star, "daily_limit": daily_limit, "reset_count": 0, "is_partner_drop": 0}],
        "challenge": [],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": 16, "normal_campaign_id": 1600016,
            "super_chapter_id": 16, "super_campaign_id": campaign_id,
            "normal_stars": 3, "normal_bonus_id": 0, "super_stars": star, "super_bonus_id": 0,
        },
    }
    return p


def service(player: PlayerState, draws: list[ScriptedEntropyDraw], commits: list[int]) -> tuple[RequestServices, ScriptedEntropyProvider]:
    provider = ScriptedEntropyProvider(draws)
    svc = RequestServices(player, DATA, lambda: commits.append(1), catalog=CATALOG, entropy_provider=provider)
    return svc, provider


def begin_req(op_id: str, campaign_id: int, *, campaign_type: int = 1, formation: str = "") -> dict:
    return {
        "campaign_battle_op_id": op_id,
        "campaign_id": campaign_id,
        "campaign_type": campaign_type,
        "formation": formation,
    }


def result_req(op_id: str, campaign_id: int, star: int, *, campaign_type: int = 1, formation: str = "") -> dict:
    return {
        "campaign_battle_op_id": op_id,
        "campaign_id": campaign_id,
        "campaign_type": campaign_type,
        "formation": formation,
        "star": star,
    }


def first_clear_draws(campaign_id: int, value: int) -> list[ScriptedEntropyDraw]:
    rows = DROP_SOURCE[str(campaign_id)]["init_dropbox_rows"]
    intermediate = [row for row in rows if 0 < int(row["increase_rate"]) < 10000]
    return [
        ScriptedEntropyDraw(CAMPAIGN_FIRST_CLEAR_NAMESPACE, i, 10000, value)
        for i in range(len(intermediate))
    ]


def backpack_qty(player: PlayerState, item_id: int) -> int:
    total = 0
    for row in player.backpack_items:
        if int(row.get("table_id", 0) or 0) == int(item_id):
            total += int(row.get("item_num", 0) or 0)
    return total


def test_first_clear_policy_boundaries_and_repeat_disabled() -> None:
    player = make_player(1900019, star=0, chapter=19)
    commits: list[int] = []
    draws = first_clear_draws(1900019, 0)
    svc, provider = service(player, draws, commits)
    plan = svc.campaign_drop_planner.plan(campaign_id=1900019, wire_campaign_type=1, first_clear=True)
    source_rows = DROP_SOURCE["1900019"]["init_dropbox_rows"]
    require(len(plan.occurrences) == len(source_rows), "all-zero scripted Bernoulli did not grant every positive first-clear row")
    require(plan.policy_id == "campaign_first_clear_bernoulli_v1", "first-clear policy identity drift")
    provider.assert_exhausted()

    # Every source row in 100001 is guaranteed; it must consume no entropy.
    svc2, provider2 = service(make_player(100001), [], [])
    guaranteed = svc2.campaign_drop_planner.plan(campaign_id=100001, wire_campaign_type=1, first_clear=True)
    require(guaranteed.canonical_awards == ({"item_id": 20001001, "item_num": 1},), f"100001 guaranteed init pool drift: {guaranteed.canonical_awards}")
    require(provider2.consumed == (), "10000-rate first-clear row consumed entropy")

    repeat = svc2.campaign_drop_planner.plan(campaign_id=100001, wire_campaign_type=1, first_clear=False)
    require(repeat.status == "disabled_unknown" and repeat.canonical_awards == (), "MID113 repeat RNG was activated")
    require(provider2.consumed == (), "MID113 repeat policy consumed Campaign entropy")


def test_mid113_stage_replay_and_supersede() -> None:
    player = make_player(1900019, star=0, chapter=19)
    commits: list[int] = []
    svc1, provider1 = service(player, first_clear_draws(1900019, 0), commits)
    first = svc1.world.begin_fight(begin_req(UUID1, 1900019))
    require(first.get("error_code", 0) == 0 and isinstance(first.get("items"), list), f"MID113 stage failed: {first}")
    provider1.assert_exhausted()
    receipt = svc1.uow.get_receipt(STAGE_RECEIPT_DOMAIN, UUID1)
    require(receipt is not None and receipt["status"] == "COMMITTED", "MID113 permanent stage receipt missing")
    require(receipt["mode"] == RECEIPT_MODE and receipt["retention_policy"] == RETENTION_POLICY, "MID113 receipt mode/retention drift")

    svc2, provider2 = service(player, [], commits)
    replay = svc2.world.begin_fight(begin_req(UUID1, 1900019))
    require(replay == first, "MID113 transport retry did not replay exact staged battle response")
    require(provider2.consumed == (), "MID113 retry consumed entropy")

    # New legitimate battle gets a fresh stage and supersedes the prior active session.
    svc3, provider3 = service(player, first_clear_draws(1900019, 9999), commits)
    second = svc3.world.begin_fight(begin_req(UUID2, 1900019))
    require(second.get("error_code", 0) == 0, f"second MID113 stage failed: {second}")
    provider3.assert_exhausted()
    require(player.active_campaign_battle.get("operation_id") == UUID2, "new MID113 did not supersede active operation")

    svc4, provider4 = service(player, [], commits)
    stale = svc4.world.begin_fight(begin_req(UUID1, 1900019))
    require(stale.get("error_code") == 1 and "superseded" in stale.get("msg", ""), f"superseded MID113 was resurrected: {stale}")
    require(provider4.consumed == (), "superseded MID113 consumed entropy")


def test_mid114_victory_commits_stage_once_and_replays_live_state() -> None:
    player = make_player(100001, star=0, chapter=1, energy=100)
    commits: list[int] = []
    svc1, provider1 = service(player, [], commits)
    stage = svc1.world.begin_fight(begin_req(UUID1, 100001))
    require(stage.get("items") == [{"item_id": 20001001, "item_num": 1}], f"guaranteed first-clear staging drift: {stage}")
    require(provider1.consumed == (), "guaranteed first-clear stage consumed entropy")
    before_item = backpack_qty(player, 20001001)
    before_energy = player.energy

    svc2, provider2 = service(player, [], commits)
    win = svc2.world.commit_fight_result(result_req(UUID1, 100001, 1))
    require(win.get("error_code", 0) == 0 and win.get("is_win") == 1, f"MID114 victory failed: {win}")
    require(win.get("items") == [], "MID114 illegally echoed MID113 staged drop rows")
    require(backpack_qty(player, 20001001) == before_item + 1, "MID114 did not commit frozen first-clear item")
    require(player.energy < before_energy, "MID114 victory did not settle Campaign Energy")
    require(provider2.consumed == (), "MID114 result rerolled Campaign entropy")
    receipt = svc2.uow.get_receipt(RESULT_RECEIPT_DOMAIN, UUID1)
    require(receipt is not None and receipt["status"] == "COMMITTED", "MID114 permanent result receipt missing")
    require(player.active_campaign_battle.get("status") == "SETTLED_WIN", "active session did not enter SETTLED_WIN")
    committed_energy = player.energy
    committed_item = backpack_qty(player, 20001001)

    # Advance cumulative state after the commit; replay must keep static result but render current projection.
    player.energy = max(0, committed_energy - 3)
    svc3, provider3 = service(player, [], commits)
    replay = svc3.world.commit_fight_result(result_req(UUID1, 100001, 1))
    require(replay.get("is_win") == win.get("is_win") and replay.get("items") == win.get("items"), "MID114 replay static response drift")
    require(replay.get("economy_", {}).get("energy") == player.energy, f"MID114 replay did not render current Energy: {replay.get('economy_')}")
    require(backpack_qty(player, 20001001) == committed_item, "MID114 replay double-granted staged reward")
    require(provider3.consumed == (), "MID114 result replay consumed entropy")

    svc4, provider4 = service(player, [], commits)
    conflict = svc4.world.commit_fight_result(result_req(UUID1, 100001, 2))
    require(conflict.get("error_code") == 1 and "fingerprint" in conflict.get("msg", ""), f"MID114 fingerprint conflict not rejected: {conflict}")
    require(provider4.consumed == (), "MID114 fingerprint conflict consumed entropy")


def test_mid114_loss_discards_staged_first_clear_rewards() -> None:
    player = make_player(100001, star=0, chapter=1, energy=100)
    commits: list[int] = []
    svc1, provider1 = service(player, [], commits)
    stage = svc1.world.begin_fight(begin_req(UUID1, 100001))
    require(stage.get("items"), "loss test did not stage a first-clear reward")
    provider1.assert_exhausted()
    before_item = backpack_qty(player, 20001001)

    svc2, provider2 = service(player, [], commits)
    loss = svc2.world.commit_fight_result(result_req(UUID1, 100001, 0))
    require(loss.get("error_code", 0) == 0 and loss.get("is_win") == 0, f"MID114 loss failed: {loss}")
    require(loss.get("items") == [], "MID114 loss returned staged first-clear items")
    require(backpack_qty(player, 20001001) == before_item, "MID114 loss committed staged first-clear reward")
    require(player.active_campaign_battle.get("status") == "SETTLED_LOSS", "loss session did not become SETTLED_LOSS")
    require(provider2.consumed == (), "MID114 loss rerolled Campaign entropy")



def test_super_first_clear_pipeline_preserves_daily_limit_contract() -> None:
    player = make_super_player(1600022, star=0, daily_limit=3)
    commits: list[int] = []
    svc1, provider1 = service(player, first_clear_draws(1600022, 9999), commits)
    stage = svc1.world.begin_fight(begin_req(UUID2, 1600022, campaign_type=2))
    require(stage.get("error_code", 0) == 0, f"Super MID113 stage failed: {stage}")
    provider1.assert_exhausted()
    require(player.world_map["super"][0]["daily_limit"] == 3, "Super MID113 staging consumed daily_limit")

    svc2, provider2 = service(player, [], commits)
    result = svc2.world.commit_fight_result(result_req(UUID2, 1600022, 1, campaign_type=2))
    require(result.get("error_code", 0) == 0 and result.get("is_win") == 1, f"Super MID114 victory failed: {result}")
    row = next(r for r in player.world_map["super"] if int(r.get("campaign_id", 0)) == 1600022)
    require(int(row.get("daily_limit", -1)) == 2, f"Super MID114 did not decrement daily_limit exactly once: {row}")
    require(provider2.consumed == (), "Super MID114 rerolled Campaign entropy")

    svc3, provider3 = service(player, [], commits)
    replay = svc3.world.commit_fight_result(result_req(UUID2, 1600022, 1, campaign_type=2))
    row2 = next(r for r in player.world_map["super"] if int(r.get("campaign_id", 0)) == 1600022)
    require(int(row2.get("daily_limit", -1)) == 2, "Super MID114 retry double-consumed daily_limit")
    require(replay.get("is_win") == 1, "Super MID114 retry did not replay committed result")
    require(provider3.consumed == (), "Super MID114 retry consumed entropy")

def test_identity_required_before_first_clear_entropy() -> None:
    player = make_player(1900019, star=0, chapter=19)
    commits: list[int] = []
    svc, provider = service(player, first_clear_draws(1900019, 0), commits)
    result = svc.world.begin_fight({"campaign_id": 1900019, "campaign_type": 1, "formation": ""})
    require(result.get("error_code") == 1 and "identity_required" in result.get("msg", ""), f"missing MID113 identity did not fail closed: {result}")
    require(provider.consumed == (), "missing MID113 identity consumed first-clear entropy")
    require(svc.uow.get_receipt(STAGE_RECEIPT_DOMAIN, UUID1) is None, "missing identity somehow staged a receipt")


def test_challenge_projection_primary_and_fallback_rules() -> None:
    p1 = make_player(1600016, star=0, chapter=16)
    svc1, _ = service(p1, [], [])
    require(not any(int(r.get("campaign_id", 0)) == 24111 for r in svc1.world.payload().get("challenge", [])), "Challenge unlocked merely by entering Chapter 16")

    p2 = make_player(1600016, star=1, chapter=16)
    svc2, _ = service(p2, [], [])
    rows = svc2.world.payload().get("challenge")
    expected_roots = [24111, 24211, 24311, 24411, 24511, 24611, 24711]
    require([int(r.get("campaign_id", 0)) for r in rows] == expected_roots, f"Pass122 terminal clear did not seed all seven Challenge roots: {rows}")
    require(p2.world_map_payload().get("challenge") == rows, "bootstrap PlayerState world_map_payload did not preserve canonical Challenge projection")

    p3 = make_player(1700001, star=0, chapter=17)
    svc3, _ = service(p3, [], [])
    require(any(int(r.get("campaign_id", 0)) == 24111 for r in svc3.world.payload().get("challenge", [])), "legacy normal_chapter_id>16 fallback did not unlock Challenge")

    p4 = make_player(1600016, star=0, chapter=23)
    svc4, _ = service(p4, [], [])
    require(not any(int(r.get("campaign_id", 0)) == 24111 for r in svc4.world.payload().get("challenge", [])), "fallback overrode explicit uncleared terminal 1600016 row")


def test_live_mid114_terminal_clear_emits_all_challenge_roots() -> None:
    player = make_player(1600016, star=0, chapter=16, energy=100)
    commits: list[int] = []
    svc1, provider1 = service(player, first_clear_draws(1600016, 9999), commits)
    stage = svc1.world.begin_fight(begin_req(UUID3, 1600016))
    require(stage.get("error_code", 0) == 0, f"1600016 MID113 stage failed: {stage}")
    provider1.assert_exhausted()

    svc2, provider2 = service(player, [], commits)
    result = svc2.world.commit_fight_result(result_req(UUID3, 1600016, 1))
    require(result.get("error_code", 0) == 0, f"1600016 MID114 failed: {result}")
    challenge = [row for row in result.get("campaigns", []) if 24111 <= int(row.get("campaign_id", 0)) <= 24711]
    require([int(r.get("campaign_id", 0)) for r in challenge] == [24111, 24211, 24311, 24411, 24511, 24611, 24711], f"MID114 did not emit all seven live Challenge roots: {challenge}")
    require([int(r.get("campaign_id", 0)) for r in player.world_map.get("challenge", [])] == [24111, 24211, 24311, 24411, 24511, 24611, 24711], "canonical world map did not persist seven-root Challenge projection")
    require(provider2.consumed == (), "MID114 terminal clear consumed Campaign entropy")


def test_ota_16317_identity_bridge_and_application_error_guard() -> None:
    manifest = json.loads((ROOT / "local_assets/update_manifest.json").read_text(encoding="utf-8"))
    require(manifest.get("version") == "1.631.7", f"OTA version drift: {manifest.get('version')}")
    files = manifest.get("files") or []
    require(len(files) == 138, f"OTA cumulative file count expected 138 got {len(files)}")
    expected = {
        f"{arch}/{rel}"
        for arch in ("src_32", "src_64")
        for rel in (
            "app/windows/SelectTeamNewWindow.lua",
            "app/windows/SelectTeamWindow.lua",
            "app/scenes/BattleCreate.lua",
        )
    }
    require(expected.issubset(set(files)), "OTA missing one or more Campaign battle identity overrides")
    for arch in ("src_32", "src_64"):
        new = (ROOT / "local_assets" / arch / "app/windows/SelectTeamNewWindow.lua").read_text(encoding="utf-8")
        old = (ROOT / "local_assets" / arch / "app/windows/SelectTeamWindow.lua").read_text(encoding="utf-8")
        battle = (ROOT / "local_assets" / arch / "app/scenes/BattleCreate.lua").read_text(encoding="utf-8")
        require('"mid113-" .. xyd.generateUUID()' in new and 'campaign_battle_op_id' in new, f"{arch} new team window missing UUID injection")
        require('"mid113-" .. xyd.generateUUID()' in old and 'campaign_battle_op_id' in old, f"{arch} legacy team window missing UUID injection")
        # Identity insertion must remain inside startCampaignBattle, not Challenge start.
        challenge_prefix = new.split("function var_0_0.startCampaignBattle", 1)[0]
        require("campaign_battle_op_id" not in challenge_prefix[-12000:], f"{arch} Challenge battle path was polluted with campaign_battle_op_id")
        require("campaignBattleOpID = arg_1_1.campaign_battle_op_id" in battle, f"{arch} BattleCreate did not retain staged identity")
        require("var_98_2.campaign_battle_op_id = arg_98_0.campaignBattleOpID" in battle, f"{arch} MID114 did not carry staged identity")
        require("var_101_error ~= 0" in battle, f"{arch} MID114 application-error guard missing")

    volume = ROOT / "local_assets" / "updates" / "gxb-local-1.631.7.zip.001"
    require(volume.exists(), "OTA 1.631.7 cumulative volume missing")
    with zipfile.ZipFile(volume) as zf:
        require(len(zf.namelist()) == 138, f"OTA volume entry count expected 138 got {len(zf.namelist())}")
        require(set(zf.namelist()) == set(files), "OTA volume entries do not match manifest")


def main() -> None:
    # Pass123 intentionally retires the Pass117 cross-request Campaign UUID
    # authority and its permanent MID113/MID114 receipts. Preserve the
    # still-valid source/policy checks here; Pass123 owns current session/OTA
    # semantics in selftest_pass123_manual_battle_session.py.
    tests = [
        test_first_clear_policy_boundaries_and_repeat_disabled,
        test_challenge_projection_primary_and_fallback_rules,
        test_live_mid114_terminal_clear_emits_all_challenge_roots,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"PASS pass117 historical non-identity regression subset ({len(tests)} tests); UUID/receipt assertions superseded by Pass123")


if __name__ == "__main__":
    main()
