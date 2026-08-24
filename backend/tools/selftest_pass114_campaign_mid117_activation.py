#!/usr/bin/env python3
from __future__ import annotations

import copy
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.campaign_drop_planner import CAMPAIGN_REPEAT_NAMESPACE
from gxb_backend.state.mid117_operation_receipt import (
    RECEIPT_DOMAIN,
    RECEIPT_MODE,
    RETENTION_POLICY,
)
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.testing.scripted_entropy import ScriptedEntropyDraw, ScriptedEntropyProvider

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
RAID_TICKET = 50001013
CAMPAIGN_ID = 1300016
MISSING_CAMPAIGN_ID = 2200001
ZERO_POOL_CAMPAIGN_ID = 100002
UUID1 = "mid117-123e4567-e89b-42d3-a456-426614174000"
UUID2 = "mid117-123e4567-e89b-42d3-a456-426614174001"
UUID3 = "mid117-123e4567-e89b-42d3-a456-426614174002"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def make_player(campaign_id: int = CAMPAIGN_ID, *, energy: int = 200, crystal: int = 100, tickets: int = 20) -> PlayerState:
    player = PlayerState(player_id="991140", account_uid="991140", player_name="Pass114", vip=15)
    player.lev = 100
    player.max_lev = 100
    player.energy = energy
    player.max_energy = 160
    player.energy_time = 0
    player.crystal = crystal
    player.backpack_items = [
        {"table_id": RAID_TICKET, "item_num": tickets, "time": 0},
        {"table_id": 50001001, "item_num": 0, "time": 0},
        {"table_id": 50001002, "item_num": 0, "time": 0},
    ]
    player.world_map = {
        "normal": [{"campaign_id": campaign_id, "star": 3, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}],
        "super": [],
        "challenge": {},
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": 1,
            "normal_campaign_id": campaign_id,
            "super_chapter_id": 0,
            "super_campaign_id": 0,
            "normal_stars": 3,
            "normal_bonus_id": 0,
            "super_stars": 0,
            "super_bonus_id": 0,
        },
    }
    return player


def service(player: PlayerState, draws: list[ScriptedEntropyDraw], commits: list[int]) -> tuple[RequestServices, ScriptedEntropyProvider]:
    provider = ScriptedEntropyProvider(draws)
    svc = RequestServices(player, DATA, lambda: commits.append(1), catalog=CATALOG, entropy_provider=provider)
    return svc, provider


def request(op_id: str = UUID1, **overrides) -> dict:
    req = {
        "campaign_sweep_op_id": op_id,
        "campaign_id": CAMPAIGN_ID,
        "campaign_type": 1,
        "sweep_num": 1,
        "sweep_type": 1,
        "awake_mission": 0,
    }
    req.update(overrides)
    return req


def ten_draws(value: int) -> list[ScriptedEntropyDraw]:
    return [
        ScriptedEntropyDraw(CAMPAIGN_REPEAT_NAMESPACE, i, 10000, value)
        for i in range(10)
    ]


def test_missing_identity_fails_before_spend_and_entropy() -> None:
    player = make_player()
    commits: list[int] = []
    svc, provider = service(player, [], commits)
    before = (player.energy, player.crystal, svc.stack_inventory.quantity(RAID_TICKET))
    result = svc.world.sweep({
        "campaign_id": CAMPAIGN_ID,
        "campaign_type": 1,
        "sweep_num": 1,
        "sweep_type": 1,
    })
    require(result.get("error_code") == 1 and "identity_required" in result.get("msg", ""), f"missing identity did not fail closed: {result}")
    after = (player.energy, player.crystal, svc.stack_inventory.quantity(RAID_TICKET))
    require(after == before, "missing identity mutated cost state")
    require(provider.consumed == (), "missing identity consumed entropy")
    require(commits == [], "missing identity committed state")


def test_exactly_once_static_replay_and_live_projection() -> None:
    player = make_player()
    commits: list[int] = []

    # First request: all residual rows hit.
    svc1, provider1 = service(player, ten_draws(0), commits)
    first = svc1.world.sweep(request(UUID1))
    require(first.get("error_code", 0) == 0, f"first MID117 rejected: {first}")
    require(player.energy == 188, f"first Energy expected 188 got {player.energy}")
    require(svc1.stack_inventory.quantity(RAID_TICKET) == 19, "first Raid Ticket debit mismatch")
    require(len(first["items"]) == 1 and len(first["items"][0]) == 12, f"deterministic+repeat response shape drift: {first['items']}")
    require(first["items"][0][:2] == [{"item_id": 50001001, "item_num": 3}, {"item_id": 50001002, "item_num": 3}], "deterministic sweep rewards changed")
    provider1.assert_exhausted()
    receipt = svc1.uow.get_receipt(RECEIPT_DOMAIN, UUID1)
    require(receipt is not None and receipt["status"] == "COMMITTED", "MID117 receipt missing")
    require(receipt["mode"] == RECEIPT_MODE and receipt["retention_policy"] == RETENTION_POLICY, "MID117 receipt mode/retention drift")
    payload = receipt["replay_payload"]
    require(payload["static_response"]["items"] == first["items"], "receipt did not preserve exact item arrays")
    require("economy_" not in payload["static_response"] and "campaign" not in payload["static_response"], "cumulative projection leaked into static receipt")
    require(payload["projection"]["economy_keys"] == ["energy"], "ITEM_SWEEP economy projection descriptor drift")

    # A second legitimate operation advances canonical economy with a different outcome.
    svc2, provider2 = service(player, ten_draws(9999), commits)
    second = svc2.world.sweep(request(UUID2))
    require(second.get("error_code", 0) == 0, f"second MID117 rejected: {second}")
    require(player.energy == 176, "second legitimate sweep did not debit Energy")
    require(svc2.stack_inventory.quantity(RAID_TICKET) == 18, "second legitimate sweep did not debit Raid Ticket")
    provider2.assert_exhausted()

    # Retry first operation: exact first static outcome, but current Energy projection.
    svc3, provider3 = service(player, [], commits)
    replay = svc3.world.sweep(request(UUID1))
    require(replay["items"] == first["items"], "receipt retry rerolled/changed static items")
    require(replay["economys"] == first["economys"] and replay["additional"] == first["additional"], "receipt retry changed static non-item payload")
    require(replay.get("economy_", {}).get("energy") == 176, f"retry did not render current Energy: {replay.get('economy_')}")
    require(player.energy == 176 and svc3.stack_inventory.quantity(RAID_TICKET) == 18, "receipt retry double-spent")
    require(provider3.consumed == (), "receipt retry consumed entropy")
    require(commits == [1, 1], f"receipt retry created an extra commit: {commits}")


def test_uuid_fingerprint_conflict_fails_before_spend() -> None:
    player = make_player()
    commits: list[int] = []
    svc1, provider1 = service(player, ten_draws(9999), commits)
    ok = svc1.world.sweep(request(UUID1))
    require(ok.get("error_code", 0) == 0, "setup sweep failed")
    provider1.assert_exhausted()
    before = (player.energy, svc1.stack_inventory.quantity(RAID_TICKET))
    svc2, provider2 = service(player, [], commits)
    conflict = svc2.world.sweep(request(UUID1, sweep_num=2))
    require(conflict.get("error_code") == 1 and "fingerprint" in conflict.get("msg", ""), f"UUID conflict not rejected: {conflict}")
    require((player.energy, svc2.stack_inventory.quantity(RAID_TICKET)) == before, "UUID conflict mutated costs")
    require(provider2.consumed == (), "UUID conflict consumed entropy")
    require(commits == [1], "UUID conflict committed state")



def test_insufficient_cost_fails_before_entropy() -> None:
    player = make_player(energy=11, tickets=20)
    commits: list[int] = []
    # If cost preflight were incorrectly after RNG, this script would be consumed.
    svc, provider = service(player, ten_draws(0), commits)
    before = (player.energy, svc.stack_inventory.quantity(RAID_TICKET))
    result = svc.world.sweep(request(UUID1))
    require(result.get("error_code") == 1, f"insufficient-cost sweep unexpectedly succeeded: {result}")
    require((player.energy, svc.stack_inventory.quantity(RAID_TICKET)) == before, "insufficient cost partially mutated state")
    require(provider.consumed == (), "insufficient cost consumed Campaign entropy")
    require(svc.uow.get_receipt(RECEIPT_DOMAIN, UUID1) is None, "insufficient cost committed receipt")
    require(commits == [], "insufficient cost committed state")


def test_multi_sweep_preserves_per_sweep_arrays() -> None:
    player = make_player(energy=200, tickets=20)
    commits: list[int] = []
    draws = [ScriptedEntropyDraw(CAMPAIGN_REPEAT_NAMESPACE, i, 10000, 0 if i < 10 else 9999) for i in range(20)]
    svc, provider = service(player, draws, commits)
    result = svc.world.sweep(request(UUID1, sweep_num=2))
    require(result.get("error_code", 0) == 0, f"2x MID117 rejected: {result}")
    require(len(result.get("items") or []) == 2, "2x MID117 did not return two per-sweep item arrays")
    require(len(result["items"][0]) == 12 and len(result["items"][1]) == 2, "per-sweep independent RNG outcomes collapsed or reshaped")
    require(player.energy == 176 and svc.stack_inventory.quantity(RAID_TICKET) == 18, "2x MID117 cost settlement drift")
    provider.assert_exhausted()
    receipt = svc.uow.get_receipt(RECEIPT_DOMAIN, UUID1)
    require(receipt["replay_payload"]["static_response"]["items"] == result["items"], "2x receipt did not preserve exact array-of-arrays")


def test_missing_positive_pool_hard_fails_before_cost_or_entropy() -> None:
    player = make_player(MISSING_CAMPAIGN_ID)
    commits: list[int] = []
    svc, provider = service(player, [], commits)
    before = (player.energy, player.crystal, svc.stack_inventory.quantity(RAID_TICKET))
    before_items = copy.deepcopy(player.backpack_items)
    result = svc.world.sweep(request(UUID1, campaign_id=MISSING_CAMPAIGN_ID))
    require(result.get("error_code") == 1 and result.get("msg") == "campaign_repeat_pool_unavailable", f"missing pool did not use frozen hard-fail: {result}")
    after = (player.energy, player.crystal, svc.stack_inventory.quantity(RAID_TICKET))
    require(after == before and player.backpack_items == before_items, "missing pool partially mutated state")
    require(provider.consumed == (), "missing pool consumed entropy")
    require(svc.uow.get_receipt(RECEIPT_DOMAIN, UUID1) is None, "missing pool committed receipt")
    require(commits == [], "missing pool committed state")


def test_zero_pool_is_valid_and_consumes_no_entropy() -> None:
    player = make_player(ZERO_POOL_CAMPAIGN_ID)
    commits: list[int] = []
    svc, provider = service(player, [], commits)
    before_energy = player.energy
    result = svc.world.sweep(request(UUID1, campaign_id=ZERO_POOL_CAMPAIGN_ID))
    require(result.get("error_code", 0) == 0, f"zero pool sweep rejected: {result}")
    require(provider.consumed == (), "zero pool sweep consumed entropy")
    require(player.energy < before_energy, "zero pool sweep did not settle deterministic cost")
    require(svc.uow.get_receipt(RECEIPT_DOMAIN, UUID1) is not None, "zero pool sweep did not commit receipt")


def test_crystal_sweep_projection_and_replay() -> None:
    player = make_player(energy=50, crystal=9, tickets=0)
    commits: list[int] = []
    svc1, provider1 = service(player, ten_draws(9999), commits)
    first = svc1.world.sweep(request(UUID3, sweep_type=2))
    require(first.get("error_code", 0) == 0, f"Crystal sweep rejected: {first}")
    require(player.energy == 38 and player.crystal == 8, "Crystal sweep costs drifted")
    require(first.get("economy_") == {"energy": 38, "crystal": 8}, f"Crystal projection drift: {first.get('economy_')}")
    provider1.assert_exhausted()
    payload = svc1.uow.get_receipt(RECEIPT_DOMAIN, UUID3)["replay_payload"]
    require(payload["projection"]["economy_keys"] == ["crystal", "energy"], "Crystal receipt projection keys drifted")
    player.energy = 30
    player.crystal = 7
    svc2, provider2 = service(player, [], commits)
    replay = svc2.world.sweep(request(UUID3, sweep_type=2))
    require(replay["items"] == first["items"], "Crystal retry static outcome changed")
    require(replay.get("economy_") == {"crystal": 7, "energy": 30}, f"Crystal retry did not render current economy: {replay.get('economy_')}")
    require(provider2.consumed == (), "Crystal retry consumed entropy")


def test_mid113_repeat_policy_remains_disabled() -> None:
    player = make_player()
    commits: list[int] = []
    svc, provider = service(player, [], commits)
    legacy = svc.campaign_drop_planner.plan(campaign_id=100001, wire_campaign_type=1, first_clear=False)
    require(legacy.status == "disabled_unknown" and legacy.canonical_awards == (), "MID113 repeat RNG accidentally activated")
    require(provider.consumed == (), "legacy MID113 planner consumed Campaign ROS")


def test_ota_16316_bridge_and_guard() -> None:
    manifest = json.loads((ROOT / "local_assets/update_manifest.json").read_text(encoding="utf-8"))
    require(manifest.get("version") == "1.631.8", f"OTA version drift: {manifest.get('version')}")
    require(len(manifest.get("files") or []) == 138, f"OTA expected 138 cumulative overrides after Pass123 rollback: {len(manifest.get('files') or [])}")
    for arch in ("src_32", "src_64"):
        rel = f"{arch}/app/windows/SweepWindow.lua"
        require(rel in manifest["files"], f"{rel} missing from OTA manifest")
        text = (ROOT / "local_assets" / rel).read_text(encoding="utf-8-sig")
        require(text.count('campaign_sweep_op_id = "mid117-" .. xyd.generateUUID()') == 1, f"{arch} UUID injection count drift")
        branch_pos = text.index("if arg_26_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN")
        uuid_pos = text.index("if var_26_0 == xyd.mid.SWEEP_CAMPAIGN then")
        request_pos = text.index("xyd.Backend.get():request(var_26_0, var_26_1")
        require(branch_pos < uuid_pos < request_pos, f"{arch} UUID bridge does not run after actual MID resolution")
        require('var_26_0 ~= xyd.mid.SWEEP_CAMPAIGN or not arg_27_1 or not arg_27_1.error_code or arg_27_1.error_code == 0' in text, f"{arch} ordinary MID117 application-error local-mutation guard missing")
    require(
        hashlib.sha256((ROOT / "local_assets/src_32/app/windows/SweepWindow.lua").read_bytes()).hexdigest()
        == hashlib.sha256((ROOT / "local_assets/src_64/app/windows/SweepWindow.lua").read_bytes()).hexdigest(),
        "src_32/src_64 SweepWindow overrides differ",
    )


def main() -> int:
    test_missing_identity_fails_before_spend_and_entropy()
    test_exactly_once_static_replay_and_live_projection()
    test_uuid_fingerprint_conflict_fails_before_spend()
    test_insufficient_cost_fails_before_entropy()
    test_multi_sweep_preserves_per_sweep_arrays()
    test_missing_positive_pool_hard_fails_before_cost_or_entropy()
    test_zero_pool_is_valid_and_consumes_no_entropy()
    test_crystal_sweep_projection_and_replay()
    test_mid113_repeat_policy_remains_disabled()
    test_ota_16316_bridge_and_guard()
    report = {
        "pass": "114.0",
        "status": "PASS",
        "scope": "Campaign MID117 RNG Phase C2 activation",
        "checks": [
            "missing source-native UUID fails before spend/entropy",
            "first MID117 request atomically commits deterministic+repeat stacks+costs+receipt",
            "receipt retry replays exact static items/economys/additional with current Energy projection",
            "same UUID with changed request tuple fails before spend/entropy",
            "insufficient cost fails before Campaign entropy",
            "multi-sweep preserves independent per-sweep array-of-arrays outcomes",
            "24-class positive missing pool hard-fails before cost/entropy/receipt",
            "repeat_dropbox_id=0 remains valid deterministic-only",
            "CRYSTAL_SWEEP receipt replays current Energy+Crystal projection",
            "legacy MID113 repeat RNG remains disabled_unknown",
            "OTA 1.631.8 preserves cumulative MID117 override within 138-entry package",
            "SweepWindow UUID injection occurs only after actual MID resolution",
            "ordinary MID117 app-error callback guard prevents local Ticket/reward mutation",
        ],
    }
    (ROOT / "docs/PASS114_CAMPAIGN_MID117_ACTIVATION_SELFTEST.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
