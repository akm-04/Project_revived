#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from types import SimpleNamespace

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.unit_of_work import OperationContext

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def require(value, message):
    if not value:
        raise AssertionError(message)


def services(name: str = "waveb"):
    p = PlayerState(player_id=name, account_uid=name, player_name=name)
    commits = []
    s = RequestServices(p, DATA, lambda: commits.append(1), catalog=CATALOG)
    return p, s, commits


def family(snapshot, fid):
    for row in snapshot:
        if isinstance(row, dict) and int(row.get("function_id", 0)) == fid:
            return row
    return None


def test_semantic_bus():
    p, s, _ = services("semantic")
    p.skill_point = 19
    s.uow.stage_semantic("economy_", {"skill_point": 1, "mana": 8})
    s.uow.stage_semantic("new_funcs_", 12)
    s.uow.stage_semantic("new_funcs_", 5)
    out = s.apply_semantic_deltas({"new_funcs_": [7]})
    require(out["economy_"]["skill_point"] == 19 and out["economy_"]["mana"] == 8, "economy semantic merge drift")
    require(out["new_funcs_"] == [5, 7, 12], "new_funcs semantic merge drift")

    s.uow.stage_semantic("unknown_future_channel_", {"x": 1})
    out = s.apply_semantic_deltas({})
    require("unknown_future_channel_" not in out, "unknown semantic channel escaped to wire")
    require(s.apply_semantic_deltas({}) == {}, "unknown semantic channel leaked into next request")

    s.uow.stage_semantic("redmarks_", 27)
    blocked = SimpleNamespace(global_fields=frozenset({"economy_", "new_funcs_"}))
    out = s.apply_semantic_deltas({}, profile=blocked)
    require("redmarks_" not in out, "projection profile failed to gate staged redmarks")

    with s.uow.transaction(OperationContext(actor_player_id=p.player_id, domain="test", operation_name="rollback_semantic")):
        s.uow.stage_semantic("redmarks_", 27)
        # no canonical save -> staged semantics are discarded by UoW contract
        pass
    require("redmarks_" not in s.apply_semantic_deltas({}), "no-save transaction published redmark")


def test_story_mission():
    p, s, commits = services("story")
    p.world_map = {"normal": [{"campaign_id": 100004, "star": 3}]}
    p.mission_state = {
        "story": {
            "missions": {"80001": {"table_id": 80001, "count": 1, "is_complete": 1, "is_reward": 0}},
            "claimed": [],
            "claim_receipts": {},
        }
    }
    p.redmarks = [{"function_id": 999, "redmark_list": [9999]}]
    snap = s.generic_redmarks.snapshot()
    row = family(snap, 27)
    require(row == {"function_id": 27, "redmark_list": [2704]}, "Story 2704 derivation wrong")
    require(family(snap, 999) is None, "legacy persisted redmark leaked into derived snapshot")

    result = s.missions.claim(80001)
    require(isinstance(result, dict) and commits, "Story claim did not commit")
    projected = s.apply_semantic_deltas(result)
    require(projected.get("redmarks_", {}).get("27") == {"function_id": 27, "redmark_list": []}, "Story claim did not emit family clear")
    require(family(s.generic_redmarks.snapshot(), 27) is None, "Story badge persisted after claim")

    replay = s.missions.claim(80001)
    replay_projected = s.apply_semantic_deltas(replay)
    require(replay_projected.get("redmarks_", {}).get("27", {}).get("redmark_list") == [], "Story response-loss replay did not re-emit clear")


def test_awakening_mission():
    p, s, _ = services("awake")
    complete = {"mission_id": 2001002, "awake_type": 2, "generation": 1, "stage": 2, "complete": True, "count": 1}
    with s.uow.transaction(OperationContext(actor_player_id=p.player_id, domain="test", operation_name="blood_complete")):
        s.awakening_missions._set_active(s.awakening_missions.HERO_TWICE, complete)
    projected = s.apply_semantic_deltas({})
    require(projected.get("redmarks_", {}).get("27") == {"function_id": 27, "redmark_list": [2705]}, "twice-Awakening 2705 derivation wrong")

    with s.uow.transaction(OperationContext(actor_player_id=p.player_id, domain="test", operation_name="blood_clear")):
        s.awakening_missions._set_active(s.awakening_missions.HERO_TWICE, None)
    projected = s.apply_semantic_deltas({})
    require(projected.get("redmarks_", {}).get("27", {}).get("redmark_list") == [], "Awakening family clear missing")

    # Reserved/deferred Pet Awakening must never drive generic Mission badges.
    pet = {"mission_id": 999001, "awake_type": 3, "generation": 1, "stage": 2, "complete": True, "count": 1}
    with s.uow.transaction(OperationContext(actor_player_id=p.player_id, domain="test", operation_name="pet_deferred")):
        s.awakening_missions.state.set_active(3, pet)
    require(family(s.generic_redmarks.snapshot(), 27) is None, "deferred Pet Awakening unfenced through 2705")


def test_battle_pass():
    p, s, _ = services("bp")
    p.battle_pass_info = {
        "base_info": {"point": 100, "awarded_lev": 0, "adv_awarded_lev": 0, "limit_purchase_buy": 0, "is_advanced": 0, "coin_num": 0},
        "mission_info": {"mission_list": [], "mission_counts": [], "is_award": []},
    }
    row = s.generic_redmarks.family_row(97)
    require(row == {"function_id": 97, "redmark_list": [2801]}, "BattlePass 2801 level predicate drift")

    # Current client fast path: once awarded level is >=90, readiness requires a
    # full 10-level loop gap, not merely reaching a blank 91..99 reward row.
    p.battle_pass_info["base_info"].update({"point": 9100, "awarded_lev": 90})
    require(2801 not in s.generic_redmarks.family_row(97)["redmark_list"], "BattlePass >=90 loop predicate drift")
    p.battle_pass_info["base_info"].update({"point": 10000, "awarded_lev": 90})
    require(2801 in s.generic_redmarks.family_row(97)["redmark_list"], "BattlePass level-100 loop readiness missing")

    p.battle_pass_info = {
        "base_info": {"point": 0, "awarded_lev": 0, "adv_awarded_lev": 0, "limit_purchase_buy": 0, "is_advanced": 0, "coin_num": 0},
        "mission_info": {"mission_list": [1], "mission_counts": [1], "is_award": [0]},
    }
    row = s.generic_redmarks.family_row(97)
    require(row == {"function_id": 97, "redmark_list": [2802]}, "BattlePass 2802 mission predicate drift")
    require(2803 not in row["redmark_list"], "forbidden BattlePass 2803 persisted")
    p.battle_pass_info["mission_info"]["is_award"] = [1]
    require(s.generic_redmarks.family_row(97)["redmark_list"] == [], "BattlePass mission clear wrong")

    s.uow.stage_semantic("redmarks_", 97)
    out = s.apply_semantic_deltas({"redmarks_": {"97": {"function_id": 97, "redmark_list": [2801, 2802, 2803]}}})
    require(out["redmarks_"]["97"] == {"function_id": 97, "redmark_list": []}, "derived dirty family did not replace explicit stale row")
    require(all(isinstance(key, str) for key in out["redmarks_"]), "response-wide redmarks_ is not string-keyed")


def test_mid2560_owner():
    p, s, _ = services("mid2560")
    p.redmarks = [{"function_id": 27, "redmark_list": [2701, 2702, 2703, 2706]}, {"function_id": 123, "redmark_list": [1]}]
    require(s.generic_redmarks.snapshot() == [], "derived MID2560 owner trusted legacy persisted redmarks")
    dispatcher_source = (ROOT / "gxb_backend" / "dispatch" / "engine_dispatcher.py").read_text(encoding="utf-8")
    require("return self.state.get_services().generic_redmarks.snapshot()" in dispatcher_source, "MID2560 route not bound to derived owner")
    bootstrap_source = (ROOT / "gxb_backend" / "handlers" / "bootstrap.py").read_text(encoding="utf-8")
    require(
        ('"2560": self.ctx.state.get_services().generic_redmarks.snapshot()' in bootstrap_source)
        or ('hydration_snapshot.stage3_snapshot()' in bootstrap_source),
        "bootstrap MID2560 not bound to derived owner/hydration assembler",
    )


def main():
    test_semantic_bus()
    test_story_mission()
    test_awakening_mission()
    test_battle_pass()
    test_mid2560_owner()
    source = json.loads((DATA / "battle_pass_redmark_source_catalog.json").read_text(encoding="utf-8"))
    require(len(source["mission_required_counts"]) == 43 and len(source["rewards"]) == 100, "BattlePass source catalog census wrong")
    print(json.dumps({
        "pass": "274.0",
        "status": "PASS",
        "wave": "B_TYPED_HTTP_SEMANTICS_MISSION_BATTLEPASS_PROJECTION",
        "semantic_channels": ["economy_", "new_funcs_", "redmarks_"],
        "mission_marks": [2704, 2705],
        "battle_pass_marks": [2801, 2802],
        "forbidden_persistent_mark": 2803,
        "mid2560_derived": True,
        "legacy_redmark_not_authority": True,
    }, indent=2, sort_keys=True))

if __name__ == "__main__":
    main()
