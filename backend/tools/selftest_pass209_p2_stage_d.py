#!/usr/bin/env python3
"""Pass209 P2 Stage D Campaign acquisition/final-trial characterization."""
from __future__ import annotations

import copy
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.super_campaign_catalog import SUPER_FUNCTION_ID, SuperCampaignCatalog
from gxb_backend.state.awakening_campaign_objective_validator import (
    ALONE_KILL,
    ALL_ALIVE,
    DAMAGE_ACHIEVE,
    SELF_KILL,
    AwakeningCampaignObjectiveValidator,
)
from gxb_backend.state.awakening_campaign_overlay_planner import (
    AWAKENING_CAMPAIGN_POLICY_ID,
    AWAKENING_CAMPAIGN_RATE_BASE,
)
from gxb_backend.state.mid117_operation_receipt import RECEIPT_DOMAIN
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.random_outcome_service import EntropyDrawRequest
from gxb_backend.state.request_services import RequestServices

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
SUPER = SuperCampaignCatalog(DATA)
RAID_TICKET = 50001013
ORD_STAGE1 = 1001001
ORD_STAGE2 = 1001003
ORD_TABLE = 10001001
ORD_GEAR = 20001185
ORD_ACQ_CAMPAIGN = 1200021
ORD_FINAL_CAMPAIGN = 1100006
BLOOD_STAGE1 = 2001001
BLOOD_TABLE = 11001001
BLOOD_ACQ_CAMPAIGN = 1300003
UUID_O = "mid117-209e4567-e89b-42d3-a456-426614174000"
UUID_B = "mid117-209e4567-e89b-42d3-a456-426614174001"
UUID_X = "mid117-209e4567-e89b-42d3-a456-426614174002"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


class ZeroEntropy:
    def __init__(self) -> None:
        self.requests: list[EntropyDrawRequest] = []

    def draw(self, request: EntropyDrawRequest) -> int:
        self.requests.append(request)
        return 0


class NoEntropy:
    def draw(self, request: EntropyDrawRequest) -> int:
        raise AssertionError(f"unexpected entropy draw on replay/gate: {request}")


def hero(pid: int, table_id: int) -> dict[str, Any]:
    return {
        "partner_id": pid,
        "table_id": table_id,
        "star": 5,
        "lev": 100,
        "exp": 0,
        "color": 15,
        "skills": [1] * 6,
        "equips": [0] * 6,
        "fumos": [0] * 6,
        "fumo_levels": [0] * 6,
        "element_equips": [0] * 4,
        "element_levels": [0] * 4,
        "element_bak_equips": [],
        "element_bak_levels": [],
        "inscript_items": [],
        "twice_awake_stage": 0,
    }


def world_normal(campaign_id: int, *, star: int = 3) -> dict[str, Any]:
    return {
        "normal": [{"campaign_id": campaign_id, "star": star, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}],
        "super": [],
        "challenge": [],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": max(1, campaign_id // 1000000),
            "normal_campaign_id": campaign_id,
            "super_chapter_id": 0,
            "super_campaign_id": 0,
            "normal_stars": star,
            "normal_bonus_id": 0,
            "super_stars": 0,
            "super_bonus_id": 0,
        },
    }


def world_super(campaign_id: int, *, star: int = 3) -> dict[str, Any]:
    anchor = SUPER.related_normal_id(campaign_id)
    require(anchor > 0, f"Super source relation missing for {campaign_id}")
    return {
        "normal": [{"campaign_id": anchor, "star": 3, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}],
        "super": [{"campaign_id": campaign_id, "star": star, "daily_limit": SUPER.daily_limit(campaign_id), "reset_count": 0, "is_partner_drop": 0}],
        "challenge": [],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": max(1, anchor // 1000000),
            "normal_campaign_id": anchor,
            "super_chapter_id": SUPER.chapter(campaign_id),
            "super_campaign_id": campaign_id,
            "normal_stars": 3,
            "normal_bonus_id": 0,
            "super_stars": star,
            "super_bonus_id": 0,
        },
    }


def player_with_hero(pid: int, table_id: int, *, super_campaign: int | None = None, normal_campaign: int | None = None, items: dict[int, int] | None = None) -> PlayerState:
    p = PlayerState(player_id=str(pid), account_uid=str(pid), player_name="Pass209", vip=15)
    p.lev = 100
    p.max_lev = 100
    p.exp = 0
    p.energy = 1000
    p.max_energy = 160
    p.energy_time = 0
    p.crystal = 1000
    p.mana = 999999999
    p.func_ids = [SUPER_FUNCTION_ID]
    p.heroes = {str(pid): hero(pid, table_id)}
    p.collected_heros = {str(table_id): {"table_id": table_id, "star": 5, "is_collected": 1}}
    stock = {RAID_TICKET: 50}
    stock.update(items or {})
    p.backpack_items = [{"table_id": iid, "item_num": num, "time": 0} for iid, num in stock.items()]
    if super_campaign is not None:
        p.world_map = world_super(super_campaign)
    elif normal_campaign is not None:
        p.world_map = world_normal(normal_campaign)
    else:
        p.world_map = world_normal(ORD_FINAL_CAMPAIGN)
    return p


def svc(p: PlayerState, commits: list[int], entropy=None) -> RequestServices:
    return RequestServices(p, DATA, lambda: commits.append(1), catalog=CATALOG, entropy_provider=entropy)


def activate_stage1(p: PlayerState, commits: list[int], mission_id: int, awake_type: int) -> dict[str, Any]:
    s = svc(p, commits, NoEntropy())
    out = s.awakening_missions.open_task({"mission_id": mission_id, "awake_type": awake_type})
    key = "awake_mission_" if awake_type == 1 else "twice_awake_mission_"
    require(out.get(key) and out[key][0]["is_complete"] == 0, f"stage1 activation failed: {out}")
    return out


def test_mid113_mid114_ordinary_overlay_frozen_and_replay_safe() -> None:
    pid = 209011
    p = player_with_hero(pid, ORD_TABLE, super_campaign=ORD_ACQ_CAMPAIGN)
    commits: list[int] = []
    activate_stage1(p, commits, ORD_STAGE1, 1)

    e = ZeroEntropy()
    s1 = svc(p, commits, e)
    resolution = s1.awakening_campaign_overlay.resolve(
        campaign_id=ORD_ACQ_CAMPAIGN,
        wire_campaign_type=2,
        ordinary_active=s1.awakening_missions.active_snapshot(1),
        blood_active=None,
    )
    require(len(resolution.resolved) == 1, "ordinary acquisition route did not resolve")
    fragment = resolution.resolved[0].item_id
    require(resolution.resolved[0].increase_rate == 6666, "ordinary recovered rate drift")
    stage = s1.world.begin_fight({"campaign_id": ORD_ACQ_CAMPAIGN, "campaign_type": 2, "formation": str(pid)})
    require(stage.get("error_code", 0) == 0, f"ordinary MID113 rejected: {stage}")
    require({"item_id": fragment, "item_num": 1} in stage.get("items", []), "ordinary special occurrence not exposed in MID113")
    frozen = copy.deepcopy(p.active_campaign_battle.get("awakening_overlay"))
    require(frozen and frozen["policy_id"] == AWAKENING_CAMPAIGN_POLICY_ID, "ordinary MID113 overlay not frozen")

    s2 = svc(p, commits, NoEntropy())
    before = s2.inventory.get_item_num(fragment)
    win = s2.world.commit_fight_result({"campaign_id": ORD_ACQ_CAMPAIGN, "campaign_type": 2, "formation": str(pid), "star": 1})
    require(win.get("is_win") == 1, f"ordinary MID114 failed: {win}")
    require(s2.inventory.get_item_num(fragment) == before + 1, "ordinary MID114 did not persist frozen special award")
    require(p.active_campaign_battle.get("awakening_overlay") == frozen, "ordinary terminal session changed frozen occurrence")

    s3 = svc(p, commits, NoEntropy())
    qty = s3.inventory.get_item_num(fragment)
    replay = s3.world.commit_fight_result({"campaign_id": ORD_ACQ_CAMPAIGN, "campaign_type": 2, "formation": str(pid), "star": 1})
    require(replay.get("error_code") == 30005, f"ordinary terminal replay shape drift: {replay}")
    require(s3.inventory.get_item_num(fragment) == qty, "ordinary MID114 replay double-granted fragment")


def test_mid113_mid114_first_clear_does_not_double_overlay() -> None:
    pid = 209016
    p = player_with_hero(pid, ORD_TABLE, super_campaign=ORD_ACQ_CAMPAIGN)
    # Force this recovered Super node to be a genuine first-clear candidate while
    # preserving its related Normal unlock row.
    p.world_map["super"][0]["star"] = 0
    commits: list[int] = []
    activate_stage1(p, commits, ORD_STAGE1, 1)

    s1 = svc(p, commits, ZeroEntropy())
    resolution = s1.awakening_campaign_overlay.resolve(
        campaign_id=ORD_ACQ_CAMPAIGN,
        wire_campaign_type=2,
        ordinary_active=s1.awakening_missions.active_snapshot(1),
        blood_active=None,
    )
    fragment = resolution.resolved[0].item_id
    stage = s1.world.begin_fight({"campaign_id": ORD_ACQ_CAMPAIGN, "campaign_type": 2, "formation": str(pid)})
    require(stage.get("error_code", 0) == 0, f"first-clear MID113 rejected: {stage}")
    session = p.active_campaign_battle
    require(session.get("items") == stage.get("items"), "combined MID113 item projection drift")
    require(session.get("awakening_overlay", {}).get("canonical_awards") == [{"item_id": fragment, "item_num": 1}], "first-clear overlay occurrence drift")
    base_awards = (session.get("drop_plan") or {}).get("canonical_awards") or []
    require(base_awards != session.get("items"), "first-clear session lost base-vs-overlay separation")

    s2 = svc(p, commits, NoEntropy())
    before = s2.inventory.get_item_num(fragment)
    out = s2.world.commit_fight_result({"campaign_id": ORD_ACQ_CAMPAIGN, "campaign_type": 2, "formation": str(pid), "star": 1})
    require(out.get("is_win") == 1, f"first-clear MID114 rejected: {out}")
    require(s2.inventory.get_item_num(fragment) == before + 1, "first-clear MID114 double-granted Awakening overlay")


def test_mid113_mid114_loss_does_not_commit_overlay() -> None:
    pid = 209017
    p = player_with_hero(pid, ORD_TABLE, super_campaign=ORD_ACQ_CAMPAIGN)
    commits: list[int] = []
    activate_stage1(p, commits, ORD_STAGE1, 1)
    s1 = svc(p, commits, ZeroEntropy())
    resolution = s1.awakening_campaign_overlay.resolve(
        campaign_id=ORD_ACQ_CAMPAIGN, wire_campaign_type=2,
        ordinary_active=s1.awakening_missions.active_snapshot(1), blood_active=None,
    )
    fragment = resolution.resolved[0].item_id
    stage = s1.world.begin_fight({"campaign_id": ORD_ACQ_CAMPAIGN, "campaign_type": 2, "formation": str(pid)})
    require({"item_id": fragment, "item_num": 1} in stage.get("items", []), "loss setup did not freeze overlay occurrence")
    before = s1.inventory.get_item_num(fragment)
    s2 = svc(p, commits, NoEntropy())
    out = s2.world.commit_fight_result({"campaign_id": ORD_ACQ_CAMPAIGN, "campaign_type": 2, "formation": str(pid), "star": 0})
    require(out.get("is_win") == 0, f"loss MID114 shape drift: {out}")
    require(s2.inventory.get_item_num(fragment) == before, "loss committed frozen Awakening overlay")
    s3 = svc(p, commits, NoEntropy())
    replay = s3.world.commit_fight_result({"campaign_id": ORD_ACQ_CAMPAIGN, "campaign_type": 2, "formation": str(pid), "star": 0})
    require(replay.get("error_code") == 30005 and s3.inventory.get_item_num(fragment) == before, "loss replay mutated overlay inventory")


def test_mid113_mid114_blood_overlay_resolves_without_wire_mission() -> None:
    pid = 209021
    p = player_with_hero(pid, BLOOD_TABLE, normal_campaign=BLOOD_ACQ_CAMPAIGN)
    commits: list[int] = []
    activate_stage1(p, commits, BLOOD_STAGE1, 2)
    e = ZeroEntropy()
    s1 = svc(p, commits, e)
    stage = s1.world.begin_fight({"campaign_id": BLOOD_ACQ_CAMPAIGN, "campaign_type": 1, "formation": str(pid)})
    require(stage.get("error_code", 0) == 0, f"Blood MID113 rejected: {stage}")
    frozen = p.active_campaign_battle.get("awakening_overlay") or {}
    rows = frozen.get("resolved") or []
    require(len(rows) == 1 and rows[0]["awake_type"] == 2 and rows[0]["mission_id"] == BLOOD_STAGE1, "Blood MID113 did not canonical-resolve mission")
    require(rows[0]["dropbox_id"] == 931001 and rows[0]["increase_rate"] == 2650, "Blood route did not use recovered referenced 931001/2650")
    fragment = rows[0]["item_id"]
    require({"item_id": fragment, "item_num": 1} in stage.get("items", []), "Blood special occurrence missing from battle")
    s2 = svc(p, commits, NoEntropy())
    before = s2.inventory.get_item_num(fragment)
    out = s2.world.commit_fight_result({"campaign_id": BLOOD_ACQ_CAMPAIGN, "campaign_type": 1, "formation": str(pid), "star": 1})
    require(out.get("is_win") == 1 and s2.inventory.get_item_num(fragment) == before + 1, "Blood MID114 settlement failed")


def test_mid117_ordinary_overlay_per_sweep_receipt_and_marker_crosscheck() -> None:
    pid = 209031
    p = player_with_hero(pid, ORD_TABLE, super_campaign=ORD_ACQ_CAMPAIGN)
    commits: list[int] = []
    activate_stage1(p, commits, ORD_STAGE1, 1)
    entropy = ZeroEntropy()
    s1 = svc(p, commits, entropy)
    req = {
        "campaign_sweep_op_id": UUID_O,
        "campaign_id": ORD_ACQ_CAMPAIGN,
        "campaign_type": 2,
        "sweep_num": 2,
        "sweep_type": 1,
        "awake_mission": ORD_STAGE1,
    }
    result = s1.world.sweep(req)
    require(result.get("error_code", 0) == 0 and len(result.get("items") or []) == 2, f"ordinary MID117 rejected: {result}")
    receipt = s1.uow.get_receipt(RECEIPT_DOMAIN, UUID_O)
    require(receipt is not None, "ordinary MID117 receipt missing")
    audit = receipt["replay_payload"]["audit"]["awakening_campaign_overlay"]
    require(audit["policy_id"] == AWAKENING_CAMPAIGN_POLICY_ID and audit["rate_base"] == AWAKENING_CAMPAIGN_RATE_BASE, "ordinary MID117 overlay policy audit drift")
    require(audit["resolved"][0]["mission_id"] == ORD_STAGE1 and audit["resolved"][0]["generation"] > 0, "ordinary MID117 did not freeze mission generation")
    fragment = audit["resolved"][0]["item_id"]
    require(all({"item_id": fragment, "item_num": 1} in rows for rows in result["items"]), "ordinary MID117 special occurrence not inside each sweep award")
    qty = s1.inventory.get_item_num(fragment)

    s2 = svc(p, commits, NoEntropy())
    replay = s2.world.sweep(copy.deepcopy(req))
    require(replay["items"] == result["items"], "ordinary MID117 retry did not replay frozen awards")
    require(s2.inventory.get_item_num(fragment) == qty, "ordinary MID117 retry double-granted fragment")

    # A different UUID with a conflicting ordinary mission marker must fail before entropy/cost mutation.
    before = (p.energy, s2.inventory.get_item_num(RAID_TICKET), s2.inventory.get_item_num(fragment))
    bad = dict(req)
    bad["campaign_sweep_op_id"] = UUID_X
    bad["sweep_num"] = 1
    bad["awake_mission"] = ORD_STAGE1 + 1
    s3 = svc(p, commits, NoEntropy())
    rejected = s3.world.sweep(bad)
    require(rejected.get("error_code") == 1 and "awake_mission" in rejected.get("msg", ""), f"ordinary marker mismatch did not fail closed: {rejected}")
    after = (p.energy, s3.inventory.get_item_num(RAID_TICKET), s3.inventory.get_item_num(fragment))
    require(after == before, "ordinary marker mismatch spent or awarded state")


def test_mid117_blood_freezes_server_canonical_identity_without_marker() -> None:
    pid = 209041
    p = player_with_hero(pid, BLOOD_TABLE, normal_campaign=BLOOD_ACQ_CAMPAIGN)
    commits: list[int] = []
    activate_stage1(p, commits, BLOOD_STAGE1, 2)
    s1 = svc(p, commits, ZeroEntropy())
    req = {
        "campaign_sweep_op_id": UUID_B,
        "campaign_id": BLOOD_ACQ_CAMPAIGN,
        "campaign_type": 1,
        "sweep_num": 1,
        "sweep_type": 1,
        "awake_mission": 0,
    }
    result = s1.world.sweep(req)
    require(result.get("error_code", 0) == 0, f"Blood MID117 rejected: {result}")
    receipt = s1.uow.get_receipt(RECEIPT_DOMAIN, UUID_B)
    audit = receipt["replay_payload"]["audit"]["awakening_campaign_overlay"]
    rows = audit["resolved"]
    require(len(rows) == 1 and rows[0]["awake_type"] == 2, "Blood MID117 did not freeze Blood identity")
    require(rows[0]["mission_id"] == BLOOD_STAGE1 and rows[0]["generation"] > 0, "Blood MID117 mission/generation not canonical")
    require(rows[0]["dropbox_id"] == 931001 and rows[0]["increase_rate"] == 2650, "Blood MID117 source mapping drift")
    require(receipt["replay_payload"]["request"]["awake_mission"] == 0, "Blood MID117 invented ordinary-style wire mission")


def advance_ordinary_to_stage2(p: PlayerState, commits: list[int], pid: int) -> None:
    activate_stage1(p, commits, ORD_STAGE1, 1)
    s1 = svc(p, commits, NoEntropy())
    s1.inventory.add_items([{"item_id": ORD_GEAR, "item_num": 1}])
    equipped = s1.awakening_equipment.set_hero_equip(pid, 1)
    require(equipped and equipped["awake_mission_"][0]["is_complete"] == 1, "ordinary stage1 gear completion setup failed")
    claimed = s1.awakening_missions.claim(ORD_STAGE1)
    require(claimed and claimed["awake_mission_"][0]["table_id"] == ORD_STAGE2, "ordinary stage2 setup claim failed")


def test_ordinary_final_trial_completion_and_terminal_replay() -> None:
    pid = 209051
    p = player_with_hero(pid, ORD_TABLE, normal_campaign=ORD_FINAL_CAMPAIGN)
    commits: list[int] = []
    advance_ordinary_to_stage2(p, commits, pid)
    s1 = svc(p, commits, ZeroEntropy())
    stage = s1.world.begin_fight({"campaign_id": ORD_FINAL_CAMPAIGN, "campaign_type": 1, "formation": str(pid)})
    require(stage.get("error_code", 0) == 0, f"ordinary final MID113 failed: {stage}")
    frozen = p.active_campaign_battle.get("awakening_objective") or {}
    require(frozen.get("mission_id") == ORD_STAGE2 and frozen.get("goal_type") == ALONE_KILL, "ordinary final objective not frozen")
    s2 = svc(p, commits, NoEntropy())
    result_req = {"campaign_id": ORD_FINAL_CAMPAIGN, "campaign_type": 1, "formation": str(pid), "star": 1, "awake_mission": ORD_STAGE2}
    out = s2.world.commit_fight_result(result_req)
    require(out.get("awake_mission_") and out["awake_mission_"][0]["is_complete"] == 1, f"ordinary final did not complete: {out}")
    rec = s2.awakening_missions.active_snapshot(1)
    require(rec and rec["mission_id"] == ORD_STAGE2 and rec["complete"], "ordinary final durable state not complete")
    frozen_delta = copy.deepcopy(out["awake_mission_"])
    s3 = svc(p, commits, NoEntropy())
    replay = s3.world.commit_fight_result(result_req)
    require(replay.get("error_code") == 30005 and replay.get("awake_mission_") == frozen_delta, f"ordinary final terminal replay lost frozen completion: {replay}")


def test_ordinary_final_solo_server_shape_blocks_false_attestation() -> None:
    pid = 209061
    p = player_with_hero(pid, ORD_TABLE, normal_campaign=ORD_FINAL_CAMPAIGN)
    p.heroes[str(pid + 1)] = hero(pid + 1, 10001002)
    commits: list[int] = []
    advance_ordinary_to_stage2(p, commits, pid)
    s1 = svc(p, commits, ZeroEntropy())
    formation = f"{pid}|{pid + 1}"
    stage = s1.world.begin_fight({"campaign_id": ORD_FINAL_CAMPAIGN, "campaign_type": 1, "formation": formation})
    require(stage.get("error_code", 0) == 0, "solo negative MID113 setup failed")
    s2 = svc(p, commits, NoEntropy())
    out = s2.world.commit_fight_result({"campaign_id": ORD_FINAL_CAMPAIGN, "campaign_type": 1, "formation": formation, "star": 1, "awake_mission": ORD_STAGE2})
    require("awake_mission_" not in out, f"server-checkable non-solo shape was incorrectly accepted: {out}")
    rec = s2.awakening_missions.active_snapshot(1)
    require(rec and not rec["complete"], "non-solo false attestation changed durable mission")
    audit = p.active_campaign_battle.get("awakening_objective_result") or {}
    require(audit.get("reason") == "awake_solo_shape_invalid", f"solo rejection audit drift: {audit}")


def test_objective_evidence_boundary_all_goal_types() -> None:
    validator = AwakeningCampaignObjectiveValidator()
    active = {"mission_id": 999003, "generation": 7, "stage": 2, "complete": False, "hero_partner_id": 77}
    base_req = {"campaign_id": 42, "campaign_type": 1, "formation": "77", "star": 1, "awake_mission": 999003}
    for goal in (SELF_KILL, DAMAGE_ACHIEVE, ALL_ALIVE, ALONE_KILL):
        row = {"go_ids": [42], "copy_challenge": goal, "challenge_num": 1}
        frozen = validator.freeze_context(active=active, mission_row=row, campaign_id=42, campaign_type=1, request=base_req)
        decision = validator.validate(request=base_req, session={"awakening_objective": frozen}, active=active, mission_row=row)
        require(decision.allowed, f"goal {goal} valid marker unexpectedly rejected: {decision}")
        if goal == ALONE_KILL:
            require(decision.evidence_class == "MIXED_SERVER_AND_CLIENT_ATTESTED", "solo evidence boundary drift")
        else:
            require(decision.evidence_class == "CLIENT_ATTESTED", f"goal {goal} was falsely promoted to server telemetry")


def test_exhaustive_stage_d_source_routes_and_final_objectives() -> None:
    service = svc(player_with_hero(209070, ORD_TABLE, normal_campaign=ORD_FINAL_CAMPAIGN), [], NoEntropy())
    planner = service.awakening_campaign_overlay

    root_counts = {1: 0, 2: 0}
    mapping_counts = {1: 0, 2: 0}
    expected_rates = {1: 6666, 2: 2650}
    for awake_type in (1, 2):
        for mission_id, mission in service.awakening_source.rows(awake_type).items():
            if int(mission.get("stage", 0) or 0) != 1:
                continue
            route = service.awakening_source.stage1_route(mission_id, awake_type)
            if not route or str(route.get("route_class")) != "CAMPAIGN":
                continue
            root_counts[awake_type] += 1
            active = {
                "awake_type": awake_type, "mission_id": int(mission_id),
                "generation": 17, "stage": 1, "complete": False,
            }
            for mapping in route.get("campaigns") or ():
                source_type = int(mapping.get("campaign_type", 0) or 0)
                wire_type = 1 if source_type in (1, 2) else 2 if source_type == 3 else 0
                require(wire_type in (1, 2), f"invalid source Campaign type {source_type} for {mission_id}")
                resolution = planner.resolve(
                    campaign_id=int(mapping.get("campaign_id", 0) or 0),
                    wire_campaign_type=wire_type,
                    ordinary_active=active if awake_type == 1 else None,
                    blood_active=active if awake_type == 2 else None,
                )
                require(len(resolution.resolved) == 1, f"route did not resolve uniquely: {awake_type}/{mission_id}/{mapping}")
                resolved = resolution.resolved[0]
                require(resolved.mission_id == int(mission_id) and resolved.generation == 17, "resolved mission identity drift")
                require(resolved.dropbox_id == int(mapping.get("dropbox_id", 0) or 0), "resolved dropbox drift")
                require(resolved.increase_rate == expected_rates[awake_type], f"resolved rate drift: {resolved}")
                mapping_counts[awake_type] += 1

    require(root_counts == {1: 131, 2: 74}, f"Campaign root census drift: {root_counts}")
    require(mapping_counts == {1: 262, 2: 20054}, f"Campaign mapping census drift: {mapping_counts}")

    blood_sets = []
    for mission_id, row in service.awakening_source.rows(2).items():
        if int(row.get("stage", 0) or 0) != 1:
            continue
        route = service.awakening_source.stage1_route(mission_id, 2)
        if not route or str(route.get("route_class")) != "CAMPAIGN":
            continue
        campaigns = tuple(sorted(int(entry.get("campaign_id", 0) or 0) for entry in (route.get("campaigns") or ())))
        require(len(campaigns) == 271, f"Blood Campaign eligibility width drift: {mission_id}/{len(campaigns)}")
        blood_sets.append(campaigns)
    require(len(set(blood_sets)) == 1, "74 recovered Blood missions no longer share the same 271-node Campaign eligibility set")

    validator = AwakeningCampaignObjectiveValidator()
    final_count = 0
    goal_counts = {SELF_KILL: 0, DAMAGE_ACHIEVE: 0, ALONE_KILL: 0, ALL_ALIVE: 0}
    for mission_id, row in service.awakening_source.rows(1).items():
        if int(row.get("stage", 0) or 0) != 2:
            continue
        final_count += 1
        goal = int(row.get("copy_challenge", 0) or 0)
        require(goal in goal_counts, f"unsupported final objective {mission_id}: {goal}")
        go_ids = [int(value) for value in (row.get("go_ids") or []) if int(value) > 0]
        require(go_ids, f"final objective missing Campaign route: {mission_id}")
        campaign_id = go_ids[0]
        active = {
            "awake_type": 1, "mission_id": int(mission_id), "generation": 19,
            "stage": 2, "complete": False, "hero_partner_id": 77,
            "hero_table_id": int(row.get("table_id", 0) or 0),
        }
        request = {
            "campaign_id": campaign_id, "campaign_type": 1, "formation": "77",
            "pet_id": 0, "star": 1, "awake_mission": int(mission_id),
        }
        frozen = validator.freeze_context(
            active=active, mission_row=row, campaign_id=campaign_id,
            campaign_type=1, request=request,
        )
        require(frozen is not None, f"final objective did not freeze: {mission_id}")
        decision = validator.validate(request=request, session={"awakening_objective": frozen}, active=active, mission_row=row)
        require(decision.allowed, f"final objective did not validate: {mission_id}/{decision}")
        goal_counts[goal] += 1

    require(final_count == 164, f"ordinary final objective census drift: {final_count}")
    require(goal_counts == {SELF_KILL: 20, DAMAGE_ACHIEVE: 3, ALONE_KILL: 15, ALL_ALIVE: 126}, f"ordinary final goal census drift: {goal_counts}")


def test_blood_4990_dropbox_is_not_an_executable_route() -> None:
    s = svc(player_with_hero(209071, BLOOD_TABLE, normal_campaign=BLOOD_ACQ_CAMPAIGN), [], NoEntropy())
    dropboxes: set[int] = set()
    rates: set[int] = set()
    routes = 0
    for mission_id, mission in s.awakening_source.rows(2).items():
        if int(mission.get("stage", 0) or 0) != 1:
            continue
        route = s.awakening_source.stage1_route(mission_id, 2)
        if not route or str(route.get("route_class")) != "CAMPAIGN":
            continue
        routes += 1
        for mapping in route.get("campaigns") or ():
            dropboxes.add(int(mapping.get("dropbox_id", 0) or 0))
            rows = s.awakening_source.dropbox(mapping.get("dropbox_id", 0))
            rates.update(int(row.get("increase_rate", 0) or 0) for row in rows)
    require(routes == 74, f"Blood Campaign route census drift: {routes}")
    require(dropboxes == {931001} and rates == {2650}, f"effective Blood route/dropbox census drift: {dropboxes}/{rates}")
    orphan = s.awakening_source.dropbox(931002)
    require(not orphan, "generated executable catalog unexpectedly exposes unreferenced 931002")


def main() -> int:
    tests = [
        test_mid113_mid114_ordinary_overlay_frozen_and_replay_safe,
        test_mid113_mid114_first_clear_does_not_double_overlay,
        test_mid113_mid114_loss_does_not_commit_overlay,
        test_mid113_mid114_blood_overlay_resolves_without_wire_mission,
        test_mid117_ordinary_overlay_per_sweep_receipt_and_marker_crosscheck,
        test_mid117_blood_freezes_server_canonical_identity_without_marker,
        test_ordinary_final_trial_completion_and_terminal_replay,
        test_ordinary_final_solo_server_shape_blocks_false_attestation,
        test_objective_evidence_boundary_all_goal_types,
        test_exhaustive_stage_d_source_routes_and_final_objectives,
        test_blood_4990_dropbox_is_not_an_executable_route,
    ]
    checks = []
    for test in tests:
        test()
        checks.append(test.__name__)
        print(f"PASS {test.__name__}")
    print(json.dumps({
        "pass": "209.0",
        "stage": "P2-D",
        "status": "PASS",
        "checks": checks,
        "ordinary_campaign_roots": 131,
        "blood_campaign_roots": 74,
        "blood_executable_dropbox": 931001,
        "blood_executable_rate": 2650,
        "unreferenced_source_dropbox_931002_rate": 4990,
        "broader_p2_release_fenced": True,
    }, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
