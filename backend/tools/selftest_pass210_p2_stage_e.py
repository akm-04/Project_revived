#!/usr/bin/env python3
"""Pass210 P2 Stage E Blood ritual/terminal/KongMing/bootstrap characterization."""
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.unit_of_work import OperationContext
from gxb_backend.state.kongming_awake_skill_service import KongMingAwakeSkillService

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def require(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def hero(pid: int, table_id: int, *, twice_stage: int = 0) -> dict[str, Any]:
    return {
        "partner_id": pid, "table_id": table_id, "star": 5, "lev": 100, "exp": 0,
        "color": 15, "skills": [1] * 6, "skill_ids": [0] * 6,
        "equips": [0] * 6, "fumos": [0] * 6, "fumo_levels": [0] * 6,
        "element_equips": [0] * 4, "element_levels": [0] * 4,
        "element_bak_equips": [], "element_bak_levels": [], "inscript_items": [],
        "twice_awake_stage": twice_stage,
    }


def services(pid: int, table_id: int, *, twice_stage: int = 0, items: dict[int, int] | None = None):
    p = PlayerState(player_id=str(pid), account_uid=str(pid), lev=100)
    p.heroes = {str(pid): hero(pid, table_id, twice_stage=twice_stage)}
    p.collected_heros = {str(table_id): {"table_id": table_id, "star": 5, "is_collected": 1}}
    p.backpack_items = [
        {"table_id": int(item_id), "item_num": int(count), "time": 0}
        for item_id, count in (items or {}).items()
    ]
    commits: list[int] = []
    s = RequestServices(p, DATA, lambda: commits.append(1), catalog=CATALOG)
    return p, s, commits


def seed_active(s: RequestServices, awake_type: int, rec: dict[str, Any]) -> None:
    ctx = OperationContext(
        actor_player_id=str(s.player.player_id), domain="pass210_test",
        operation_name="seed_active", protocol_mid=None,
    )
    with s.uow.transaction(ctx):
        s.awakening_missions._set_active(awake_type, rec)


def test_blood_trial_session_terminal_envelope_replay_and_claim() -> None:
    pid = 210011
    p, s, _ = services(pid, 11001001, twice_stage=2)
    rec = {
        "mission_id": 2001002, "awake_type": 2, "hero_partner_id": pid,
        "hero_table_id": 11001001, "stage": 2, "generation": 7,
        "complete": False, "count": 0, "opened_at": p.now(),
    }
    seed_active(s, 2, rec)

    no_start = s.awakening_missions.unlimited_result({
        "twice_awake_mission": 2001002, "incubus_id": 2001002, "num": 20, "npc_ids": [],
    })
    require(no_start.get("error_code") == 1 and no_start.get("msg") == "blood_awake_trial_session_missing", "MID867 accepted without MID866 session")

    started = s.awakening_missions.unlimited_start({"twice_awake_mission": 2001002, "incubus_id": 2001002})
    require(started == {}, f"MID866 start failed: {started}")
    active = s.awakening_missions.active_snapshot(2) or {}
    session = active.get("trial_session") or {}
    require(session.get("generation") == 7 and session.get("mission_id") == 2001002 and "roster" not in session, f"Blood session drift: {session}")

    bad_num = s.awakening_missions.unlimited_result({
        "twice_awake_mission": 2001002, "incubus_id": 2001002, "num": 19, "npc_ids": [],
    })
    require(bad_num.get("error_code") == 1, "MID867 accepted nonterminal num")
    bad_npc = s.awakening_missions.unlimited_result({
        "twice_awake_mission": 2001002, "incubus_id": 2001002, "num": 20, "npc_ids": [1],
    })
    require(bad_npc.get("error_code") == 1, "MID867 accepted nonempty Blood npc_ids")

    good_req = {"twice_awake_mission": 2001002, "incubus_id": 2001002, "num": 20, "npc_ids": []}
    result = s.awakening_missions.unlimited_result(good_req)
    require(result.get("items") == [], f"Blood result items shape drift: {result}")
    row = result.get("twice_awake_mission_", [{}])[0]
    require(row.get("table_id") == 2001002 and row.get("is_complete") == 1, f"Blood result mission projection drift: {result}")
    require(s.awakening_missions.unlimited_result(good_req) == result, "MID867 completion replay mismatch")

    claim = s.awakening_missions.claim(2001002)
    require(claim == {"twice_awake_stage_": {"table_id": 11001001, "stage": 3}}, f"Blood terminal claim projection drift: {claim}")
    require(p.heroes[str(pid)]["twice_awake_stage"] == 3, "Blood terminal stage not persisted")
    require(s.awakening_missions.active_snapshot(2) is None, "Blood terminal mission not cleared")
    require(s.awakening_missions.claim(2001002) == claim, "Blood MID161 terminal replay mismatch")
    require(s.awakening_missions.unlimited_start({"twice_awake_mission": 2001002, "incubus_id": 2001002}).get("error_code") == 1, "Blood trial restart accepted after terminal claim")


def test_kongming_terminal_books_callback_order_and_mid2144() -> None:
    pid = 210021
    # Existing Wind ownership must not be duplicated; four missing tokens should be granted.
    p, s, _ = services(pid, 10001144, items={50000005: 1})
    rec = {
        "mission_id": 1144003, "awake_type": 1, "hero_partner_id": pid,
        "hero_table_id": 10001144, "stage": 2, "generation": 11,
        "complete": True, "count": 1, "opened_at": p.now(),
    }
    seed_active(s, 1, rec)
    claim = s.awakening_missions.claim(1144003)
    require("hero" not in claim and "partner" not in claim and "table_id" not in claim, f"ordinary terminal leaked pre-callback Hero projection: {claim}")
    require(p.heroes[str(pid)]["table_id"] == 11001144, "KongMing durable table transformation missing")
    drops = claim.get("extra_drops_") or []
    require({int(r["table_id"]) for r in drops} == {50000010, 50000015, 50000020, 50000025}, f"KongMing newly-granted Book-V projection drift: {drops}")
    for book in KongMingAwakeSkillService.ownership_books():
        require(s.inventory.get_item_num(book) == 1, f"KongMing Book-V ownership missing/duplicated: {book}")
    replay = s.awakening_missions.claim(1144003)
    require(replay == claim, "ordinary terminal replay changed response")
    for book in KongMingAwakeSkillService.ownership_books():
        require(s.inventory.get_item_num(book) == 1, f"terminal replay duplicated Book-V: {book}")

    before_fire = s.inventory.get_item_num(50000020)
    switched = s.kongming_awake_skills.change({"partner_id": pid, "skill_index": 5, "skill_item": 50000020})
    require(switched.get("skill_ids", [0] * 5)[4] == 60040144, f"MID2144 raw Fire skill persistence drift: {switched}")
    require(p.heroes[str(pid)]["skill_ids"][4] == 60040144, "MID2144 raw skill ID not persisted")
    require(s.inventory.get_item_num(50000020) == before_fire, "MID2144 consumed persistent Book-V ownership")
    require(s.kongming_awake_skills.change({"partner_id": pid, "skill_index": 4, "skill_item": 50000020}).get("error_code") == 1, "MID2144 accepted non-Awake slot")
    require(s.kongming_awake_skills.change({"partner_id": pid, "skill_index": 5, "skill_item": 50000021}).get("error_code") == 1, "MID2144 accepted unsupported Book/skill mapping")

    # RequestServices reconstitution is a relog-equivalent ownership/projection check.
    s2 = RequestServices(p, DATA, lambda: None, catalog=CATALOG)
    payload = s2.heroes.payload()["heros"][str(pid)]
    require(payload["table_id"] == 11001144 and payload["skill_ids"][4] == 60040144, f"KongMing relog hydration drift: {payload}")
    for book in KongMingAwakeSkillService.ownership_books():
        require(s2.inventory.get_item_num(book) == 1, f"KongMing relog book ownership drift: {book}")



def test_ordinary_terminal_transform_and_replay() -> None:
    pid = 210025
    p, s, _ = services(pid, 10001001)
    rec = {
        "mission_id": 1001003, "awake_type": 1, "hero_partner_id": pid,
        "hero_table_id": 10001001, "stage": 2, "generation": 12,
        "complete": True, "count": 1, "opened_at": p.now(),
    }
    seed_active(s, 1, rec)
    row = s.awakening_source.mission(1001003, 1) or {}
    target = int(row.get("awaken_table_id", 0) or 0)
    require(target > 0, f"ordinary source target missing: {row}")
    claim = s.awakening_missions.claim(1001003)
    require(claim == {}, f"ordinary terminal must not project Hero table before stock callback: {claim}")
    require(p.heroes[str(pid)]["table_id"] == target, f"ordinary durable terminal transform drift: {p.heroes[str(pid)]}")
    require(s.awakening_missions.active_snapshot(1) is None, "ordinary terminal mission not cleared")
    require(s.awakening_missions.claim(1001003) == claim, "ordinary terminal replay mismatch")


def test_blood_trial_session_is_generation_bound() -> None:
    pid = 210027
    p, s, _ = services(pid, 11001001, twice_stage=2)
    seed_active(s, 2, {
        "mission_id": 2001002, "awake_type": 2, "hero_partner_id": pid,
        "hero_table_id": 11001001, "stage": 2, "generation": 40,
        "complete": False, "count": 0, "opened_at": p.now(),
    })
    require(s.awakening_missions.unlimited_start({"twice_awake_mission": 2001002, "incubus_id": 2001002}) == {}, "generation-40 MID866 start failed")
    # Simulate a later re-activation/reconciliation generation of the same source mission.
    seed_active(s, 2, {
        "mission_id": 2001002, "awake_type": 2, "hero_partner_id": pid,
        "hero_table_id": 11001001, "stage": 2, "generation": 41,
        "complete": False, "count": 0, "opened_at": p.now(),
    })
    stale = s.awakening_missions.unlimited_result({
        "twice_awake_mission": 2001002, "incubus_id": 2001002, "num": 20, "npc_ids": [],
    })
    require(stale.get("error_code") == 1 and stale.get("msg") == "blood_awake_trial_session_missing", f"stale Blood trial session crossed generation: {stale}")


def test_mid2144_rejects_preawakened_kongming() -> None:
    pid = 210031
    _p, s, _ = services(pid, 10001144, items={50000005: 1})
    out = s.kongming_awake_skills.change({"partner_id": pid, "skill_index": 5, "skill_item": 50000005})
    require(out.get("error_code") == 1 and out.get("msg") == "kongming_not_awakened", f"pre-Awakening KongMing MID2144 not fenced: {out}")


def test_bootstrap_authority_and_relog_active_missions() -> None:
    pid = 210041
    p, s, _ = services(pid, 11001001, twice_stage=2)
    p.missions["awake"] = [{"table_id": 9990001, "is_going": 1}]
    p.missions["twice_awake"] = [{"table_id": 9990002, "is_going": 1}]
    seed_active(s, 1, {
        "mission_id": 1001003, "awake_type": 1, "hero_partner_id": pid,
        "hero_table_id": 10001001, "stage": 2, "generation": 31,
        "complete": False, "count": 0, "opened_at": p.now(),
    })
    seed_active(s, 2, {
        "mission_id": 2001002, "awake_type": 2, "hero_partner_id": pid,
        "hero_table_id": 11001001, "stage": 2, "generation": 32,
        "complete": True, "count": 1, "opened_at": p.now(),
    })
    legacy = p.task_bootstrap_payload()
    legacy.update(s.awakening_missions.bootstrap_channels())
    require(legacy["awake_mission_"][0]["table_id"] == 1001003 and legacy["twice_awake_mission_"][0]["table_id"] == 2001002, f"LOAD_MISSION canonical overlay drift: {legacy}")
    require(9990001 not in [r.get("table_id") for r in legacy["awake_mission_"]], "legacy generic ordinary shadow state resurrected")
    require(9990002 not in [r.get("table_id") for r in legacy["twice_awake_mission_"]], "legacy generic Blood shadow state resurrected")
    authoritative = s.awakening_missions.mission_list()
    require({r["table_id"] for r in authoritative["mission_list"]} == {1001003, 2001002}, f"MID2561 authoritative hydration drift: {authoritative}")
    require(s.awakening_missions.load_by_type(5) == authoritative, "TASK_LOAD_BY_TYPE Awake hydration diverged from MID2561")


def test_all_blood_stage2_rows_are_ritual_bound() -> None:
    _p, s, _ = services(210051, 11001001, twice_stage=2)
    rows = s.awakening_source.rows(2)
    stage2 = []
    for mission_id, row in rows.items():
        if int(row.get("stage", 0) or 0) != 2:
            continue
        trial = tuple(int(v) for v in (row.get("trial_challenge") or ()))
        require(trial == (int(mission_id),), f"Blood stage2 ritual binding drift {mission_id}: {trial}")
        stage2.append(int(mission_id))
    require(len(stage2) == 81, f"Blood stage2 ritual census drift: {len(stage2)}")


def main() -> int:
    tests = [
        test_blood_trial_session_terminal_envelope_replay_and_claim,
        test_kongming_terminal_books_callback_order_and_mid2144,
        test_ordinary_terminal_transform_and_replay,
        test_blood_trial_session_is_generation_bound,
        test_mid2144_rejects_preawakened_kongming,
        test_bootstrap_authority_and_relog_active_missions,
        test_all_blood_stage2_rows_are_ritual_bound,
    ]
    checks = []
    for test in tests:
        test()
        checks.append(test.__name__)
        print(f"PASS {test.__name__}")
    print(json.dumps({
        "pass": "210.0", "stage": "P2-E", "status": "PASS",
        "checks": checks,
        "blood_ritual_missions": 81,
        "blood_terminal_num": 20,
        "blood_terminal_npc_ids": [],
        "kongming_book_v_tokens": list(KongMingAwakeSkillService.ownership_books()),
        "kongming_server_skill_mappings": len(KongMingAwakeSkillService.SKILL_BY_BOOK),
        "kongming_stock_picker_visible_mappings": 3,
        "broader_p2_release_fenced": True,
    }, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
