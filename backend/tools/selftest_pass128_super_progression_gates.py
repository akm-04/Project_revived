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
from gxb_backend.content.super_campaign_catalog import SUPER_FUNCTION_ID, SuperCampaignCatalog
from gxb_backend.state.campaign_drop_planner import CAMPAIGN_REPEAT_NAMESPACE
from gxb_backend.state.maintenance_services import PlayerMaintenanceServices
from gxb_backend.state.mid117_operation_receipt import RECEIPT_DOMAIN
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.unit_of_work import OperationContext
from gxb_backend.testing.scripted_entropy import ScriptedEntropyDraw, ScriptedEntropyProvider

GAME = GameDataCatalog.load(DATA / "game_data_catalog.json")
SUPER = SuperCampaignCatalog(DATA)
FIRST_SUPER = SUPER.first_id
FIRST_NORMAL = SUPER.related_normal_id(FIRST_SUPER)
SECOND_SUPER = SUPER.next_id(FIRST_SUPER)
SECOND_NORMAL = SUPER.related_normal_id(SECOND_SUPER)
RAID_TICKET = 50001013
UUID_A = "mid117-128e4567-e89b-42d3-a456-426614174000"
UUID_B = "mid117-128e4567-e89b-42d3-a456-426614174001"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def row(cid: int, *, star: int = 0, daily: int = 0) -> dict:
    return {
        "campaign_id": int(cid),
        "star": int(star),
        "daily_limit": int(daily),
        "reset_count": 0,
        "is_partner_drop": 0,
    }


def world(*, normal_rows=None, super_rows=None, super_cursor: int = 0) -> dict:
    normal_rows = list(normal_rows or [])
    super_rows = list(super_rows or [])
    normal_cursor = int(normal_rows[-1]["campaign_id"]) if normal_rows else 0
    normal_chapter = 1 if normal_rows else 0
    super_chapter = SUPER.chapter(super_cursor) if super_cursor else 0
    return {
        "normal": normal_rows,
        "super": super_rows,
        "challenge": [],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": normal_chapter,
            "normal_campaign_id": normal_cursor,
            "super_chapter_id": super_chapter,
            "super_campaign_id": int(super_cursor),
            "normal_stars": sum(int(r.get("star", 0)) for r in normal_rows),
            "normal_bonus_id": 0,
            "super_stars": 0,
            "super_bonus_id": 0,
        },
    }


def base_player(*, level: int = 100, func31: bool = True, normal_star: int = 3, super_star: int = 3, daily: int = 3) -> PlayerState:
    p = PlayerState(player_id="991280", account_uid="991280", player_name="Pass128", vip=15)
    p.lev = level
    p.max_lev = 100
    p.exp = 0
    p.energy = 300
    p.max_energy = 160
    p.energy_time = 0
    p.crystal = 1000
    p.func_ids = [SUPER_FUNCTION_ID] if func31 else []
    p.function_state = {}
    p.backpack_items = [{"table_id": RAID_TICKET, "item_num": 50, "time": 0}]
    p.world_map = world(
        normal_rows=[row(FIRST_NORMAL, star=normal_star)],
        super_rows=[row(FIRST_SUPER, star=super_star, daily=daily)],
        super_cursor=FIRST_SUPER,
    )
    return p


def service(player: PlayerState, draws=None, commits=None):
    commits = commits if commits is not None else []
    provider = ScriptedEntropyProvider(draws or [])
    svc = RequestServices(player, DATA, lambda: commits.append(1), catalog=GAME, entropy_provider=provider)
    return svc, provider, commits


def miss_draws(count: int = 1) -> list[ScriptedEntropyDraw]:
    # Source Super 100019 has sixteen residual repeat draws per sweep.
    return [
        ScriptedEntropyDraw(CAMPAIGN_REPEAT_NAMESPACE, i, 10000, 9999)
        for i in range(16 * count)
    ]


def sweep_req(op_id: str) -> dict:
    return {
        "campaign_sweep_op_id": op_id,
        "campaign_id": FIRST_SUPER,
        "campaign_type": 2,
        "sweep_num": 1,
        "sweep_type": 1,
        "awake_mission": 0,
    }


def test_catalog_source_relationships() -> None:
    ids = SUPER.ids()
    require(len(ids) == 155 and ids[0] == 100019 and ids[-1] == 2300024, "Super source chain drift")
    require(SUPER.related_normal_id(FIRST_SUPER) == 100001, "first Normal anchor drift")
    require(SECOND_SUPER == 100020 and SECOND_NORMAL == 100004, "second Super relation drift")
    for index, cid in enumerate(ids):
        expected_next = ids[index + 1] if index + 1 < len(ids) else 0
        expected_last = ids[index - 1] if index else 0
        require(SUPER.next_id(cid) == expected_next, f"next edge drift at {cid}")
        require(SUPER.last_id(cid) == expected_last, f"last edge drift at {cid}")


def test_level11_bootstrap_projection_before_announcement() -> None:
    p = base_player(level=10, func31=False)
    p.exp = 101  # player.lua level-10 cumulative threshold is 102.
    p.world_map = world(normal_rows=[row(FIRST_NORMAL, star=0)], super_rows=[], super_cursor=0)
    commits: list[int] = []
    svc, provider, _ = service(p, [], commits)
    seen: list[tuple[str, int]] = []
    original = svc.function_state._semantic_callback

    def semantic(name: str, value: object) -> None:
        ivalue = int(value)
        if name == "new_funcs_" and ivalue == SUPER_FUNCTION_ID:
            first = svc.super_campaign_projection.find_row(FIRST_SUPER)
            chapter = p.world_map["chapter_info"]
            require(first is not None and int(first["star"]) == 0 and int(first["daily_limit"]) == 3,
                    "Function31 announced before first Super row existed")
            require(int(chapter["super_campaign_id"]) == FIRST_SUPER and int(chapter["super_chapter_id"]) == 1,
                    "Function31 announced before Super cursors existed")
        seen.append((name, ivalue))
        if original:
            original(name, value)

    svc.function_state._semantic_callback = semantic
    with svc.uow.transaction(OperationContext(
        actor_player_id=str(p.player_id), domain="pass128_selftest", operation_name="level11_bootstrap",
        server_time=1_700_000_128,
    )):
        changed = svc.player_progression.grant_exp(1)

    require(changed.get("lev") == 11 and p.lev == 11, f"level-11 crossing failed: {changed}")
    require(SUPER_FUNCTION_ID in svc.function_state.announced_ids(), "Function31 not announced")
    require(("new_funcs_", SUPER_FUNCTION_ID) in seen, "Function31 semantic not emitted")
    require(commits == [1], f"bootstrap did not commit exactly once: {commits}")
    provider.assert_exhausted()


def test_level11_bootstrap_rolls_back_atomically_on_commit_failure() -> None:
    p = base_player(level=10, func31=False)
    p.exp = 101
    p.world_map = world(normal_rows=[row(FIRST_NORMAL, star=0)], super_rows=[], super_cursor=0)
    svc = RequestServices(
        p, DATA, lambda: (_ for _ in ()).throw(OSError("synthetic pass128 commit failure")),
        catalog=GAME, entropy_provider=ScriptedEntropyProvider([]),
    )
    before = copy.deepcopy(vars(p))
    raised = False
    try:
        with svc.uow.transaction(OperationContext(
            actor_player_id=str(p.player_id), domain="pass128_selftest", operation_name="bootstrap_rollback",
            server_time=1_700_000_129,
        )):
            svc.player_progression.grant_exp(1)
    except OSError:
        raised = True
    require(raised, "synthetic commit failure did not escape")
    require(vars(p) == before, "level/Function31/Super projection did not roll back atomically")


def test_legacy_level11_self_heal_is_idempotent() -> None:
    p = base_player(level=100, func31=False)
    p.world_map = world(normal_rows=[row(FIRST_NORMAL, star=3)], super_rows=[], super_cursor=0)
    m = PlayerMaintenanceServices(p, DATA)
    require(m.elite_campaign_unlock.maintenance_reconcile() is True, "legacy level>=11 save did not reconcile")
    require(SUPER_FUNCTION_ID in m.function_state.announced_ids(), "legacy reconcile did not announce Function31")
    first = m.super_campaign_projection.find_row(FIRST_SUPER)
    require(first is not None and int(first["daily_limit"]) == 3, "legacy reconcile did not materialize first Super")
    require(int(p.world_map["chapter_info"]["super_campaign_id"]) == FIRST_SUPER, "legacy cursor not repaired")
    marker = (p.persistence_state.get("migrations") or {}).get(m.elite_campaign_unlock.MIGRATION_MARKER)
    require(isinstance(marker, dict) and marker.get("applied") == 1, "legacy migration marker missing")
    require(m.elite_campaign_unlock.maintenance_reconcile() is False, "legacy reconcile ghost-mutated canonical state")


def test_announced_function_world_map_self_heals_missing_first_row() -> None:
    p = base_player(level=100, func31=True)
    p.world_map = world(normal_rows=[row(FIRST_NORMAL, star=3)], super_rows=[], super_cursor=0)
    svc, _, commits = service(p, [], [])
    payload = svc.world.payload()
    require(any(int(r.get("campaign_id", 0)) == FIRST_SUPER for r in payload["super"]), "LOAD_WORLD_MAP did not self-heal first Super")
    require(int(payload["chapter_info"]["super_campaign_id"]) == FIRST_SUPER, "LOAD_WORLD_MAP cursor self-heal failed")
    require(len(commits) == 1, f"first self-heal expected one persistence request: {commits}")
    payload2 = svc.world.payload()
    require(int(payload2["chapter_info"]["super_campaign_id"]) == FIRST_SUPER, "canonical reload drift")
    require(len(commits) == 1, "canonical LOAD_WORLD_MAP ghost-saved repeatedly")


def test_mid113_bouncer_blocks_before_attempt_energy_rng_or_session() -> None:
    p = base_player(func31=True, normal_star=0, super_star=0, daily=3)
    svc, provider, commits = service(p, [], [])
    before = (p.energy, copy.deepcopy(p.world_map), copy.deepcopy(p.active_campaign_battle))
    out = svc.world.begin_fight({"campaign_id": FIRST_SUPER, "campaign_type": 2, "formation": "A"})
    require(out.get("error_code") == 1 and out.get("msg") == "campaign_normal_prerequisite_locked", f"MID113 bypass not blocked: {out}")
    require((p.energy, p.world_map, p.active_campaign_battle) == before, "MID113 bouncer mutated attempts/Energy/session")
    require(provider.consumed == (), "MID113 bouncer consumed RNG")
    require(commits == [], "MID113 bouncer committed state")


def test_mid113_sticky_stage_replay_precedes_new_bouncer() -> None:
    p = base_player(func31=True, normal_star=3, super_star=1, daily=3)
    svc1, provider1, commits = service(p, [], [])
    first = svc1.world.begin_fight({"campaign_id": FIRST_SUPER, "campaign_type": 2, "formation": "A"})
    require(first.get("error_code", 0) == 0, f"authorized MID113 stage failed: {first}")
    provider1.assert_exhausted()
    # A staged server-owned outcome remains authoritative even if a synthetic
    # test mutates the prerequisite afterward; replay must not reroll/replace it.
    p.world_map["normal"][0]["star"] = 0
    svc2, provider2, _ = service(p, [], commits)
    replay = svc2.world.begin_fight({"campaign_id": FIRST_SUPER, "campaign_type": 2, "formation": "B"})
    require(replay == first, "same-stage STAGED replay was re-authorized or changed")
    require(provider2.consumed == (), "same-stage replay consumed RNG")


def test_mid117_bouncer_precedes_attempt_cost_rng_receipt() -> None:
    p = base_player(func31=True, normal_star=0, super_star=3, daily=3)
    svc, provider, commits = service(p, miss_draws(1), [])
    # Canonicalize derived chapter counters before the mutation-sensitive
    # snapshot; the gate itself must not be blamed for repairing stale fixture
    # metadata such as super_stars.
    svc.world.normalize()
    before = (p.energy, copy.deepcopy(p.backpack_items), copy.deepcopy(p.world_map))
    out = svc.world.sweep(sweep_req(UUID_A))
    require(out.get("error_code") == 1 and out.get("msg") == "campaign_normal_prerequisite_locked", f"MID117 bypass not blocked: {out}")
    require((p.energy, p.backpack_items, p.world_map) == before, "MID117 bouncer mutated attempt/cost/reward state")
    require(provider.consumed == (), "MID117 bouncer consumed entropy")
    require(svc.uow.get_receipt(RECEIPT_DOMAIN, UUID_A) is None, "MID117 bouncer wrote receipt")
    require(commits == [], "MID117 bouncer committed state")


def test_mid117_receipt_replay_precedes_current_prerequisite() -> None:
    p = base_player(func31=True, normal_star=3, super_star=3, daily=3)
    commits: list[int] = []
    svc1, provider1, _ = service(p, miss_draws(1), commits)
    first = svc1.world.sweep(sweep_req(UUID_B))
    require(first.get("error_code", 0) == 0, f"authorized MID117 failed: {first}")
    provider1.assert_exhausted()
    require(int(p.world_map["super"][0]["daily_limit"]) == 2, "authorized MID117 attempt decrement drift")
    p.world_map["normal"][0]["star"] = 0
    svc2, provider2, _ = service(p, [], commits)
    replay = svc2.world.sweep(sweep_req(UUID_B))
    require(replay.get("items") == first.get("items"), "committed MID117 replay changed frozen rewards")
    require(int(p.world_map["super"][0]["daily_limit"]) == 2, "MID117 replay consumed another attempt")
    require(provider2.consumed == (), "MID117 replay reran bouncer/RNG")
    require(commits == [1], f"MID117 replay created extra durable commit: {commits}")


def test_super_win_materializes_next_but_next_normal_still_gates_entry() -> None:
    p = base_player(func31=True, normal_star=3, super_star=1, daily=3)
    # The next Normal anchor exists but is intentionally unbeaten.
    p.world_map["normal"].append(row(SECOND_NORMAL, star=0))
    p.world_map["chapter_info"]["normal_campaign_id"] = SECOND_NORMAL
    svc1, provider1, commits = service(p, [], [])
    stage = svc1.world.begin_fight({"campaign_id": FIRST_SUPER, "campaign_type": 2, "formation": "A"})
    require(stage.get("error_code", 0) == 0, f"Super MID113 setup failed: {stage}")
    provider1.assert_exhausted()
    svc2, provider2, _ = service(p, [], commits)
    win = svc2.world.commit_fight_result({"campaign_id": FIRST_SUPER, "campaign_type": 2, "formation": "A", "star": 1})
    require(win.get("error_code", 0) == 0 and win.get("is_win") == 1, f"Super win failed: {win}")
    provider2.assert_exhausted()
    next_row = next((r for r in p.world_map["super"] if int(r.get("campaign_id", 0)) == SECOND_SUPER), None)
    require(next_row is not None and int(next_row["star"]) == 0 and int(next_row["daily_limit"]) == 3,
            f"next Super frontier not materialized source-shaped: {next_row}")
    require(int(p.world_map["chapter_info"]["super_campaign_id"]) == SECOND_SUPER, "Super frontier cursor did not advance")
    svc3, provider3, _ = service(p, [], commits)
    denied = svc3.world.begin_fight({"campaign_id": SECOND_SUPER, "campaign_type": 2, "formation": "B"})
    require(denied.get("error_code") == 1 and denied.get("msg") == "campaign_normal_prerequisite_locked", f"next visible Super bypassed Normal gate: {denied}")
    require(provider3.consumed == (), "next-stage Normal gate consumed RNG")



def test_terminal_super_win_keeps_terminal_frontier_without_phantom_row() -> None:
    terminal = SUPER.terminal_id
    anchor = SUPER.related_normal_id(terminal)
    p = base_player(func31=True, normal_star=3, super_star=1, daily=3)
    super_rows = [
        row(cid, star=(1 if cid == terminal else 0), daily=SUPER.daily_limit(cid))
        for cid in SUPER.ids()
    ]
    p.world_map = world(
        normal_rows=[row(anchor, star=3)],
        super_rows=super_rows,
        super_cursor=terminal,
    )
    svc1, provider1, commits = service(p, [], [])
    stage = svc1.world.begin_fight({"campaign_id": terminal, "campaign_type": 2, "formation": "T"})
    require(stage.get("error_code", 0) == 0, f"terminal Super MID113 setup failed: {stage}")
    provider1.assert_exhausted()
    svc2, provider2, _ = service(p, [], commits)
    win = svc2.world.commit_fight_result({"campaign_id": terminal, "campaign_type": 2, "formation": "T", "star": 1})
    require(win.get("error_code", 0) == 0 and win.get("is_win") == 1, f"terminal Super win failed: {win}")
    provider2.assert_exhausted()
    super_ids = [int(r.get("campaign_id", 0)) for r in p.world_map["super"]]
    require(super_ids == list(SUPER.ids()), f"terminal Super changed source frontier set: {super_ids[-5:]}")
    require(int(p.world_map["chapter_info"]["super_campaign_id"]) == terminal, "terminal Super cursor drifted")
    require(SUPER.next_id(terminal) == 0, "terminal source edge is no longer terminal")

def test_qa_visibility_never_bypasses_authorization() -> None:
    p = base_player(func31=True, normal_star=3, super_star=0, daily=3)
    # Mimic Pass75 visibility policy: every source Super row exists, while one
    # related Normal prerequisite is explicitly made uncleared for negative QA.
    p.world_map["super"] = [row(cid, star=0, daily=SUPER.daily_limit(cid)) for cid in SUPER.ids()]
    p.world_map["chapter_info"]["super_campaign_id"] = SUPER.terminal_id
    p.world_map["chapter_info"]["super_chapter_id"] = SUPER.chapter(SUPER.terminal_id)
    target = SECOND_SUPER
    anchor = SECOND_NORMAL
    p.world_map["normal"].append(row(anchor, star=0))
    svc, provider, commits = service(p, [], [])
    decision = svc.super_campaign_access.evaluate(target, 2)
    require(not decision.allowed and decision.reason == "campaign_normal_prerequisite_locked", f"QA preseed bypassed access policy: {decision}")
    out = svc.world.begin_fight({"campaign_id": target, "campaign_type": 2, "formation": "QA"})
    require(out.get("error_code") == 1 and out.get("msg") == "campaign_normal_prerequisite_locked", f"QA MID113 bypassed bouncer: {out}")
    require(provider.consumed == () and commits == [], "QA negative gate mutated/committed state")


def main() -> int:
    tests = [
        test_catalog_source_relationships,
        test_level11_bootstrap_projection_before_announcement,
        test_level11_bootstrap_rolls_back_atomically_on_commit_failure,
        test_legacy_level11_self_heal_is_idempotent,
        test_announced_function_world_map_self_heals_missing_first_row,
        test_mid113_bouncer_blocks_before_attempt_energy_rng_or_session,
        test_mid113_sticky_stage_replay_precedes_new_bouncer,
        test_mid117_bouncer_precedes_attempt_cost_rng_receipt,
        test_mid117_receipt_replay_precedes_current_prerequisite,
        test_super_win_materializes_next_but_next_normal_still_gates_entry,
        test_terminal_super_win_keeps_terminal_frontier_without_phantom_row,
        test_qa_visibility_never_bypasses_authorization,
    ]
    checks = []
    for test in tests:
        test()
        checks.append(test.__name__)
        print(f"PASS {test.__name__}")
    report = {
        "pass": "128.0",
        "status": "PASS",
        "scope": "Super Campaign projection/Function31/access gates",
        "checks": checks,
        "source": {
            "super_rows": len(SUPER.ids()),
            "first_super": FIRST_SUPER,
            "first_normal_anchor": FIRST_NORMAL,
            "second_super": SECOND_SUPER,
            "second_normal_anchor": SECOND_NORMAL,
            "terminal_super": SUPER.terminal_id,
        },
    }
    (ROOT / "docs/PASS128_SUPER_PROGRESSION_GATES_SELFTEST.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
