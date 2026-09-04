#!/usr/bin/env python3
"""Pass182 MID57/max_color reconciliation + Girl Gear Pack QA seed self-test."""
from __future__ import annotations

import json
import tempfile
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.handlers.heroes import HeroHandlers
from gxb_backend.state.multiuser_database import MultiUserDatabase, SANDBOX_UID
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.transport.result import EngineTransportResult

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
EQUIP_META = json.loads((DATA / "hero_equipment_meta.json").read_text(encoding="utf-8"))
ADV_META = json.loads((DATA / "hero_advanced_progression_meta.json").read_text(encoding="utf-8"))


def req(condition, message):
    if not condition:
        raise AssertionError(message)


def hero(pid: int, tid: int, color: int, equips=None, fumos=None):
    return {
        "partner_id": pid,
        "table_id": tid,
        "star": 5,
        "lev": 100,
        "exp": 0,
        "color": color,
        "skills": [1] * 6,
        "equips": list(equips or [0] * 6),
        "fumos": list(fumos or [0] * 6),
        "fumo_levels": [0] * 6,
        "element_equips": [0] * 4,
        "element_levels": [0] * 4,
        "element_bak_equips": [],
        "element_bak_levels": [],
        "inscript_items": [],
    }


def services(h: dict | None = None, *, max_color: int = 5):
    p = PlayerState(player_id="182001", account_uid="182001", player_name="Pass182")
    p.lev = 100
    p.max_lev = 100
    p.max_color = max_color
    p.mana = 999_999_999
    p.crystal = 999_999
    p.heroes = {} if h is None else {str(h["partner_id"]): h}
    p.collected_heros = {}
    commits = []
    s = RequestServices(
        p,
        DATA,
        lambda: commits.append(int(p.persistence_state.get("state_version", -1))),
        catalog=CATALOG,
    )
    return p, s, commits


def stage(tid: int, color: int):
    row = EQUIP_META["partners"][str(tid)]
    return [int(v) for v in row["equip_lists"][str(color)]]


def seed_missing_direct_items(player: PlayerState, ids: list[int], equips: list[int]):
    player.backpack_items = [
        {"table_id": item_id, "item_num": 1, "time": 0}
        for idx, item_id in enumerate(ids)
        if item_id > 0 and int(equips[idx]) == 0
    ]


def first_fumo_slot(ids: list[int]):
    for idx, item_id in enumerate(ids):
        if item_id <= 0:
            continue
        thresholds = (ADV_META["advanced_items"].get(str(item_id), {}) or {}).get("fumo_thresholds") or []
        if sum(int(v) for v in thresholds) > 0:
            return idx
    raise AssertionError("no Fumo-capable ordinary slot in test stage")


def make_partially_collected(tid: int, color: int, pid: int):
    ids = stage(tid, color)
    slot = first_fumo_slot(ids)
    equips = [0] * 6
    fumos = [0] * 6
    equips[slot] = 1
    fumos[slot] = 100
    return hero(pid, tid, color, equips=equips, fumos=fumos), ids, slot


def test_below_threshold_mid57_promotes():
    h, ids, slot = make_partially_collected(10001001, 4, 182011)
    p, s, commits = services(h, max_color=5)
    seed_missing_direct_items(p, ids, h["equips"])
    before_fumo_items = {i: s.stack_inventory.quantity(i) for i in (50001007, 50001006, 50001003)}

    out = s.hero_equipment.one_click_promote(h["partner_id"])
    journal = s.uow.consume_journal()
    current = s.heroes.get(h["partner_id"])
    req("error_code" not in out, "below-threshold MID57 failed")
    req(current["color"] == 5, "below-threshold MID57 did not promote")
    req(current["equips"] == [0] * 6 and current["fumos"] == [0] * 6, "below-threshold promotion did not clear ordinary gear/Fumo")
    req(journal and journal[-1]["category"] == "ENTITY" and journal[-1]["action"] == "PROMOTE_COLOR", "below-threshold terminal mutation drift")
    req(len(commits) == 1, "below-threshold MID57 did not commit once")
    req(out.get("restore_items"), "below-threshold Fumo restoration missing")
    req(any(s.stack_inventory.quantity(i) > before_fumo_items[i] for i in before_fumo_items), "below-threshold Fumo credits missing")
    req(slot >= 0, "Fumo fixture invalid")


def test_threshold_mid57_collects_then_mid51_promotes():
    h, ids, slot = make_partially_collected(10001001, 5, 182021)
    original_fumos = list(h["fumos"])
    p, s, commits = services(h, max_color=5)
    seed_missing_direct_items(p, ids, h["equips"])
    before_fumo_items = {i: s.stack_inventory.quantity(i) for i in (50001007, 50001006, 50001003)}

    out57 = s.hero_equipment.one_click_promote(h["partner_id"])
    journal57 = s.uow.consume_journal()
    after57 = s.heroes.get(h["partner_id"])
    required = [idx for idx, item_id in enumerate(ids) if item_id > 0]
    req(out57 == {"restore_items": []}, "threshold MID57 wire result must not expose restoration")
    req(after57["color"] == 5, "threshold MID57 incorrectly promoted")
    req(after57["fumos"] == original_fumos, "threshold MID57 changed Fumo")
    req(all(after57["equips"][idx] == 1 for idx in required), "threshold MID57 did not collect current ordinary tier")
    req(journal57 and journal57[-1]["action"] == "SET_EQUIP_SLOTS", "threshold MID57 terminal mutation is not SET_EQUIP_SLOTS")
    req(all(s.stack_inventory.quantity(i) == before_fumo_items[i] for i in before_fumo_items), "threshold MID57 credited Fumo restoration")

    out51 = s.hero_equipment.powerup_hero(h["partner_id"])
    journal51 = s.uow.consume_journal()
    after51 = s.heroes.get(h["partner_id"])
    req("error_code" not in out51, "MID51 after threshold collect failed")
    req(after51["color"] == 6, "MID51 after threshold did not promote")
    req(after51["equips"] == [0] * 6 and after51["fumos"] == [0] * 6, "MID51 did not clear ordinary state")
    req(out51.get("restore_items"), "MID51 did not perform preserved Fumo restoration")
    req(journal51 and journal51[-1]["action"] == "PROMOTE_COLOR", "MID51 terminal mutation drift")
    req(len(commits) == 2, "threshold MID57 + MID51 must commit exactly twice")
    req(slot >= 0, "threshold Fumo fixture invalid")


def test_above_threshold_and_terminal_16():
    h, ids, _ = make_partially_collected(10001001, 6, 182031)
    p, s, _ = services(h, max_color=5)
    seed_missing_direct_items(p, ids, h["equips"])
    out57 = s.hero_equipment.one_click_promote(h["partner_id"])
    req(out57 == {"restore_items": []} and s.heroes.get(h["partner_id"])["color"] == 6, "above-threshold MID57 did not remain equip-only")
    s.uow.consume_journal()
    out51 = s.hero_equipment.powerup_hero(h["partner_id"])
    req("error_code" not in out51 and s.heroes.get(h["partner_id"])["color"] == 7, "above-threshold MID51 promotion failed")
    s.uow.consume_journal()

    h15, ids15, _ = make_partially_collected(10001042, 15, 182041)
    p15, s15, commits15 = services(h15, max_color=5)
    seed_missing_direct_items(p15, ids15, h15["equips"])
    out15 = s15.hero_equipment.one_click_promote(h15["partner_id"])
    req(out15 == {"restore_items": []} and s15.heroes.get(h15["partner_id"])["color"] == 15, "15-> threshold collect failed")
    s15.uow.consume_journal()
    out16 = s15.hero_equipment.powerup_hero(h15["partner_id"])
    s15.uow.consume_journal()
    req("error_code" not in out16 and s15.heroes.get(h15["partner_id"])["color"] == 16, "MID51 did not reach terminal color 16")
    before = json.dumps(s15.heroes.get(h15["partner_id"]), sort_keys=True)
    rejected = s15.hero_equipment.one_click_promote(h15["partner_id"])
    req(rejected == {"error_code": 1}, "color16 MID57 must reject")
    req(json.dumps(s15.heroes.get(h15["partner_id"]), sort_keys=True) == before, "color16 rejected MID57 mutated Hero")
    req(not s15.uow.consume_journal() and len(commits15) == 2, "color16 rejected MID57 committed")


def test_p2_special_fence_preserved():
    special = None
    for tid, row in EQUIP_META["partners"].items():
        for color_s, ids in (row.get("equip_lists") or {}).items():
            color = int(color_s)
            if color >= 16:
                continue
            metas = [EQUIP_META["items"].get(str(i), {}) for i in ids if int(i) > 0]
            if any(int(m.get("is_awaken_item", 0)) > 0 or int(m.get("is_bloodline_item", 0)) > 0 for m in metas):
                special = (int(tid), color)
                break
        if special:
            break
    req(special is not None, "special-equipment fixture missing")
    h = hero(182051, special[0], special[1], equips=[1] * 6, fumos=[77] * 6)
    p, s, commits = services(h, max_color=5)
    before = json.dumps(s.heroes.get(h["partner_id"]), sort_keys=True)
    result = s.hero_equipment.one_click_promote(h["partner_id"])
    transport = HeroHandlers._promotion_transport(result)
    req(isinstance(transport, EngineTransportResult) and transport.status_code == 409, "P2 MID57 fence lost HTTP409")
    req(json.dumps(s.heroes.get(h["partner_id"]), sort_keys=True) == before, "P2 fenced MID57 mutated Hero")
    req(not s.uow.consume_journal() and not commits, "P2 fenced MID57 committed")


def test_dev_gear_pack_qty7_fixture():
    payload = json.loads((DATA / "debug_guest_girl_gear_pack_seed_pass182.json").read_text(encoding="utf-8"))
    ids = [int(v) for v in payload["item_ids"]]
    req(len(ids) == 199 and len(set(ids)) == 199 and int(payload["target_quantity"]) == 7, "Pass182 pack fixture census drift")

    with tempfile.TemporaryDirectory(prefix="gxb-pass182-") as td:
        db = MultiUserDatabase(Path(td), DATA)
        player = PlayerState(player_id="182061", account_uid=SANDBOX_UID, player_name="Sandbox")
        player.backpack_items = [{"table_id": ids[0], "item_num": 999, "time": 0}]
        req(db._apply_pass182_debug_girl_gear_pack_seed(player), "Pass182 sandbox pack fixture did not apply")
        by_id = {int(r["table_id"]): int(r["item_num"]) for r in player.backpack_items if isinstance(r, dict)}
        req(all(by_id.get(item_id) == 7 for item_id in ids), "not all 199 Girl Gear Packs normalized to exactly 7")
        marker = payload["_meta"]["migration_marker"]
        req(player.persistence_state["migrations"][marker]["source_item_count"] == 199, "pack fixture migration marker drift")
        by_row = next(r for r in player.backpack_items if int(r.get("table_id", 0)) == ids[0])
        by_row["item_num"] = 6
        req(not db._apply_pass182_debug_girl_gear_pack_seed(player), "pack fixture must be one-shot")
        req(int(by_row["item_num"]) == 6, "pack fixture replenished after migration")

        credential = PlayerState(player_id="182062", account_uid="credential", player_name="Credential")
        req(not db._apply_pass182_debug_girl_gear_pack_seed(credential) and not credential.backpack_items, "pack fixture leaked into credential account")


def main():
    tests = [
        test_below_threshold_mid57_promotes,
        test_threshold_mid57_collects_then_mid51_promotes,
        test_above_threshold_and_terminal_16,
        test_p2_special_fence_preserved,
        test_dev_gear_pack_qty7_fixture,
    ]
    for fn in tests:
        fn()
        print("PASS", fn.__name__)
    print(json.dumps({
        "pass": "182.0",
        "status": "PASS",
        "mid57_below_max_color": "PROMOTE_COLOR_WITH_FUMO_RESTORE",
        "mid57_at_or_above_max_color": "SET_EQUIP_SLOTS_NO_RESTORE",
        "mid51": "ACTUAL_PROMOTION_AT_THRESHOLD",
        "absolute_terminal": 16,
        "p2_special_equipment": "HTTP409_NO_MUTATION",
        "dev_girl_gear_pack_rows": 199,
        "dev_girl_gear_pack_quantity": 7,
    }, sort_keys=True))


if __name__ == "__main__":
    main()
