#!/usr/bin/env python3
"""Pass75 Campaign ownership + Pass74 runtime-neighbor characterization."""
from __future__ import annotations

import json
import tempfile
from collections import Counter
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def require(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def services(*, uid: str = "997501", energy: int = 100) -> tuple[PlayerState, RequestServices, list[int]]:
    p = PlayerState(player_id="997501", account_uid=uid, player_name="Pass75")
    # Keep Campaign EXP from introducing level-up Energy awards into the Energy
    # ownership assertions below. This is a test isolation choice, not a policy.
    p.lev = 100
    p.max_lev = 100
    p.exp = 0
    p.mana = 0
    p.crystal = 0
    p.energy = int(energy)
    p.energy_time = 0
    p.max_energy = 100
    commits: list[int] = []
    s = RequestServices(p, DATA, lambda: commits.append(int(p.persistence_state.get("state_version", 0))), catalog=CATALOG)
    s.world.normalize()
    return p, s, commits


def campaign_test() -> dict[str, object]:
    source = json.loads((DATA / "pass75_campaign_ownership_meta.json").read_text(encoding="utf-8"))
    audit = source.get("audit") or {}
    require(audit == {
        "campaign_rows": 917,
        "chapters": 23,
        "normal_ids": 429,
        "relation_mismatches": [],
        "super_ids": 155,
    }, f"Campaign source audit drift: {audit!r}")
    require(source["campaigns"]["100001"]["energy_cost"] == 6, "100001 win Energy cost drift")
    require(source["campaigns"]["100001"]["defeat_cost"] == 1, "100001 defeat Energy cost drift")
    require(source["campaigns"]["100002"]["energy_cost"] == 9, "100002 Energy cost drift")
    require(source["campaigns"]["100019"]["energy_cost"] == 12, "100019 Super Energy cost drift")
    require(source["campaigns"]["100001"]["relate_campaign_id"] == 100019, "Normal/Super relation drift")

    p, s, _ = services(energy=100)
    fight = {"campaign_id": 100001, "campaign_type": 1, "formation": ""}
    version_before_orphan = s.uow.current_state_version
    orphan = s.world.commit_fight_result({**fight, "star": 3})
    require(orphan.get("error_code") == 1 and orphan.get("msg") == "campaign_session_mismatch", "orphan MID114 did not fail closed")
    require(s.world._find_row(100001, 1).get("star") == 0 and p.energy == 100 and s.uow.current_state_version == version_before_orphan, "orphan MID114 mutated Campaign state/resource/version")
    start = s.world.begin_fight(fight)
    require(start.get("error_code") is None, f"Normal MID113 unexpectedly rejected: {start}")
    require(p.energy == 100, "MID113 must preview, not debit, Campaign Energy")
    out = s.world.commit_fight_result({**fight, "star": 3})
    require(p.energy == 94, f"Normal win did not debit exact source Energy: {p.energy}")
    require((out.get("economy_") or {}).get("energy") == 94, "Normal win did not project cumulative Energy")
    require((out.get("economy_") or {}).get("mana") == 495, "Normal source Mana reward drift")
    require((out.get("economy_") or {}).get("crystal") == 30, "Normal 3-star Crystal reward drift")
    require(s.world._find_row(100002, 1) is not None, "Normal clear did not unlock source next campaign")
    version_after = s.uow.current_state_version
    retry = s.world.commit_fight_result({**fight, "star": 3})
    require(retry == out and p.energy == 94 and s.uow.current_state_version == version_after, "MID114 retry duplicated Campaign settlement")

    # A real loss uses source defeat_cost, not full entry Energy.
    loss_start = s.world.begin_fight(fight)
    require(loss_start.get("error_code") is None, "loss setup rejected")
    loss = s.world.commit_fight_result({**fight, "star": 0})
    require(p.energy == 93, f"Campaign loss must debit source defeat_cost=1, got {p.energy}")
    require((loss.get("economy_") or {}).get("energy") == 93, "loss cumulative Energy projection missing")
    require((loss.get("economy_") or {}).get("mana") is None, "loss fabricated scalar reward")

    # Source row 100002 proves the old 'always 6 Energy' shorthand is invalid.
    fight2 = {"campaign_id": 100002, "campaign_type": 1, "formation": ""}
    require(s.world.begin_fight(fight2).get("error_code") is None, "100002 MID113 rejected after unlock")
    s.world.commit_fight_result({**fight2, "star": 1})
    require(p.energy == 84, f"100002 did not debit source energy_cost=9, got {p.energy}")

    # Insufficient Energy is rejected before a battle session is staged.
    low, lows, _ = services(uid="997502", energy=5)
    rejected = lows.world.begin_fight(fight)
    require(rejected.get("error_code") == 1 and rejected.get("msg") == "energy_insufficient", "Campaign entry Energy precondition missing")
    require(low.energy == 5 and not low.active_campaign_battle, "rejected MID113 mutated Energy/session")

    # Super/Elite is an independent wire list but source-related to Normal.
    sp, ss, _ = services(uid="997503", energy=50)
    ss.world._mode_rows(2).append({"campaign_id": 100019, "star": 0, "daily_limit": 3, "reset_count": 0, "is_partner_drop": 0})
    sfight = {"campaign_id": 100019, "campaign_type": 2, "formation": ""}
    require(ss.world.begin_fight(sfight).get("error_code") is None, "source-related Super campaign rejected")
    sout = ss.world.commit_fight_result({**sfight, "star": 1})
    require(sp.energy == 38 and (sout.get("economy_") or {}).get("energy") == 38, "Super source Energy settlement drift")
    require((sout.get("economy_") or {}).get("mana") == 930, "Super source Mana reward drift")
    require(ss.world.begin_fight({"campaign_id": 100001, "campaign_type": 2, "formation": ""}).get("msg") == "campaign_mode_mismatch", "wire Campaign mode validation missing")

    return {
        "source_campaign_rows": 917,
        "normal_source_rows": 429,
        "super_source_rows": 155,
        "normal_win_energy": 6,
        "normal_defeat_energy": 1,
        "second_stage_energy": 9,
        "super_energy": 12,
        "result_retry_idempotent": True,
        "orphan_result_fail_closed": True,
    }


def debug_unlock_test() -> dict[str, object]:
    source = json.loads((DATA / "pass75_campaign_ownership_meta.json").read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory(prefix="gxb-pass75-debug-unlock-") as td:
        store = MultiUserDatabase(Path(td), DATA)
        debug = store.create_fresh_player(uid="13371337", region=197, region_name="Local-197")
        normal = debug.world_map.get("normal") or []
        super_rows = debug.world_map.get("super") or []
        require(len(normal) == len(source["normal_campaign_ids"]) == 429, f"debug Normal unlock count drift {len(normal)}")
        require(len(super_rows) == len(source["super_campaign_ids"]) == 155, f"debug Super unlock count drift {len(super_rows)}")
        require(all(int(row.get("star", 0) or 0) >= 1 for row in normal), "debug Normal prerequisite row not cleared/unlocked")
        require(all(int(row.get("daily_limit", 0) or 0) == 3 for row in super_rows), "debug Super source daily_limit drift")
        marker = (debug.persistence_state.get("migrations") or {}).get("pass75_debug_campaign_unlock_v1")
        require(isinstance(marker, dict) and marker.get("policy") == "PRIVATE_SERVER_POLICY", "debug Campaign unlock marker missing")
        before = len(normal) + len(super_rows)
        # One-shot policy must not continuously rewrite progress.
        require(store._apply_pass75_debug_campaign_unlock(debug) is False, "debug Campaign unlock unexpectedly reapplied")
        require(len(debug.world_map["normal"]) + len(debug.world_map["super"]) == before, "debug unlock reapply changed map rows")

        regular = store.create_fresh_player(uid="997599", region=198, region_name="Local-198")
        require(len(regular.world_map.get("normal") or []) < 429, "credential account received PRIVATE_SERVER_POLICY Campaign unlock")
        require(len(regular.world_map.get("super") or []) == 0, "credential account received Super debug unlock")

    return {"debug_uid": "13371337", "normal_unlocked": 429, "super_unlocked": 155, "one_shot": True, "credential_isolated": True}


def runtime_neighbor_test() -> dict[str, object]:
    # Daily Task load must remain source-shaped even when daily missions are not
    # implemented, otherwise TaskWindow:updateDaily() nil-dereferences before
    # the user can switch to the Awaken tab.
    p = PlayerState(player_id="997504", account_uid="997504")
    daily = p.mission_payload(1)
    huoyue = ((daily.get("extra_info") or {}).get("huoyue_info") or {})
    require(huoyue.get("day_huoyue") == 0 and huoyue.get("week_huoyue") == 0, "Daily Task loader zero contract missing")

    # Pass74 already owned all three source inscription certificate families.
    meta = json.loads((DATA / "hero_advanced_progression_meta.json").read_text(encoding="utf-8"))
    counts = Counter(int(row.get("resolve_material", 0) or 0) for row in (meta.get("inscriptions") or {}).values())
    require(counts == Counter({21: 9, 19: 7, 20: 7}), f"inscription certificate family audit drift {counts}")
    resource_by_material = {19: "degree_cer", 20: "graduate_cer", 21: "patent_cer"}
    reps: dict[int, tuple[int, int]] = {}
    for row in (meta.get("inscriptions") or {}).values():
        material = int(row.get("resolve_material", 0) or 0)
        if material in resource_by_material and material not in reps:
            reps[material] = (int((row.get("item_ids") or [0])[0]), int(row.get("resolve_num", 0) or 0))
    items = {item_id: 1 for item_id, _ in reps.values()}
    mp = PlayerState(player_id="997505", account_uid="997505")
    mp.backpack_items = [{"table_id": iid, "item_num": 1, "time": 0} for iid in items]
    ms = RequestServices(mp, DATA, lambda: None, catalog=CATALOG)
    for material in (19, 20, 21):
        item_id, expected = reps[material]
        result = ms.hero_advanced.inscription_resolve({"item_id": item_id, "resolve_num": 1})
        require(result == {}, f"certificate family {material} dissolve rejected")
        key = resource_by_material[material]
        require(ms.economy_ledger.balance(key) == expected, f"certificate family {material}/{key} credit drift")
        require(ms.stack_inventory.quantity(item_id) == 0, f"certificate family {material} emblem debit drift")
        ms.uow.consume_journal()

    # Breakout/Stone Evolution stage-up must persist an empty canonical point
    # map, not resurrect stage-1 values through extension-preserving JSON merge.
    stone_meta = meta["stone_evolution"]
    attrs = [int(v) for v in stone_meta["1"]["attrs"]]
    full = {str(v): int(stone_meta["1"]["limit_num"]) for v in attrs}
    hero = {
        "partner_id": 75001, "table_id": 10001001, "star": 4, "lev": 90, "exp": 0,
        "color": 16, "skills": [1] * 6, "equips": [0] * 6,
        "evo_stage": 1, "evo_attr_points": full,
    }
    with tempfile.TemporaryDirectory(prefix="gxb-pass75-stone-persist-") as td:
        store = MultiUserDatabase(Path(td), DATA)
        sp = PlayerState(player_id="19775001", account_uid="997506", player_name="StonePersist")
        sp.lev = 100; sp.max_lev = 100; sp.heroes = {"75001": hero}
        store.save_player(sp)
        ss = RequestServices(sp, DATA, lambda: store.save_player(sp), catalog=CATALOG)
        evolved = ss.hero_advanced.breach_stone_evolve({"partner_id": 75001})
        require(evolved.get("evo_info") == {"evo_attr_points": {}, "evo_stage": 2}, "Stone stage-up response drift")
        loaded = store.load_player(sp.player_id)
        require(loaded is not None, "Stone persistence reload failed")
        loaded_hero = loaded.heroes.get("75001") or {}
        require(int(loaded_hero.get("evo_stage", 0)) == 2 and loaded_hero.get("evo_attr_points") == {}, f"Stone stage reset resurrected after reload: {loaded_hero.get('evo_attr_points')}")

    return {
        "daily_task_window_shape_safe": True,
        "certificate_material_families": {"19": "degree_cer", "20": "graduate_cer", "21": "patent_cer"},
        "certificate_source_archetypes": {"degree": 7, "graduate": 7, "patent": 9},
        "stone_stage_empty_points_persist": True,
    }


def main() -> int:
    report = {
        "pass": "75.0",
        "status": "PASS",
        "campaign": campaign_test(),
        "debug_unlock": debug_unlock_test(),
        "runtime_neighbor_fixes": runtime_neighbor_test(),
        "deferred": [
            "Campaign sweep Energy/scalar ownership remains a separate source-contract migration",
            "Elite/Super daily attempt decrement/reset ownership remains deferred until its reset contract is explicitly migrated",
            "repeat Campaign drop RNG remains disabled until source/server policy authority exists",
            "debug advanced-item bag-cap/mail warning remains PRIVATE_SERVER_POLICY test-side effect",
        ],
    }
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
