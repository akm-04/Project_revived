#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"
SRC64 = ROOT / "source_evidence" / "src_64"

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.hero_repository import HeroRepository
from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices

GAME = GameDataCatalog.load(DATA / "game_data_catalog.json")


def req(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


# Exact six Spirit instances recovered from the Pass170 stock-client smoke restart
# payload for KM-Moe (partner_id=10073). Keeping the failing persisted shape in the
# regression makes this a true reconciliation test rather than a synthetic guess.
SMOKE_SPIRITS = [
    {"collo_count": 1, "exp": 0, "is_equip": 10073, "is_lock": 0, "lev": 0, "main": 1, "main_attr": 44, "main_attr_value": 120, "spirit_id": 1, "star": 5, "sub": [], "sub_attr": [], "sub_attr_value": [], "table_id": 250001054},
    {"collo_count": 1, "exp": 192750, "is_equip": 10073, "is_lock": 0, "lev": 13, "main": 1, "main_attr": 43, "main_attr_value": 460, "spirit_id": 4, "star": 6, "sub": [3, 9, 11, 8], "sub_attr": [6, 46, 48, 45], "sub_attr_value": [84, 156, 720, 156], "table_id": 250000962},
    {"collo_count": 1, "exp": 0, "is_equip": 10073, "is_lock": 0, "lev": 0, "main": 1, "main_attr": 4, "main_attr_value": 800, "spirit_id": 5, "star": 6, "sub": [7], "sub_attr": [44], "sub_attr_value": [72], "table_id": 250000865},
    {"collo_count": 1, "exp": 0, "is_equip": 10073, "is_lock": 0, "lev": 0, "main": 2, "main_attr": 6, "main_attr_value": 70, "spirit_id": 7, "star": 5, "sub": [8], "sub_attr": [45], "sub_attr_value": [60], "table_id": 250001051},
    {"collo_count": 1, "exp": 0, "is_equip": 10073, "is_lock": 0, "lev": 0, "main": 1, "main_attr": 7, "main_attr_value": 7, "spirit_id": 12, "star": 5, "sub": [5, 10, 8, 7], "sub_attr": [8, 47, 45, 44], "sub_attr_value": [0.9, 300, 60, 24], "table_id": 250001153},
    {"collo_count": 1, "exp": 0, "is_equip": 10073, "is_lock": 0, "lev": 0, "main": 2, "main_attr": 45, "main_attr_value": 120, "spirit_id": 15, "star": 5, "sub": [3], "sub_attr": [6], "sub_attr_value": [15], "table_id": 250000956},
]
SMOKE_EQUIP = [7, 4, 12, 1, 5, 15]


def smoke_player() -> PlayerState:
    p = PlayerState(player_id="12525385", account_uid="13371337", player_name="Moppleton")
    p.heroes = {
        "10073": {
            "partner_id": 10073,
            "table_id": 10001200,
            "star": 5,
            "lev": 100,
            "spirit_equip": list(SMOKE_EQUIP),
            # This is the exact Pass170 persistence/bootstrap defect: an empty
            # server-fabricated cache is present beside valid persistent IDs.
            "spirit_item": [],
        }
    }
    p.spirit_list = [dict(row) for row in SMOKE_SPIRITS]
    p.horcrux_state = {}
    return p


def test_source_optional_cache_contract() -> None:
    src = (SRC64 / "app/model/NormalHero.lua").read_text(encoding="utf-8-sig")
    req("arg_3_0.spiritItems_ = arg_3_1.spirit_item" in src, "NormalHero spirit_item assignment drift")
    req("if arg_252_0.spiritItems_ then" in src and "getSpiritItemBySpiritID(iter_252_1)" in src, "getSpiritSuitID fallback contract drift")
    req("if arg_253_0.spiritItems_ then" in src and "getSpiritItemBySpiritID(iter_253_1)" in src, "getSpiritEquipsAttr fallback contract drift")


def test_owned_hero_normalization_omits_semantic_cache() -> None:
    p = smoke_player()
    changed = HeroRepository(p, data_dir=DATA, catalog=GAME).normalize()
    hero = p.heroes["10073"]
    req(changed, "stale spirit_item cache was not treated as a migration change")
    req(hero["spirit_equip"] == SMOKE_EQUIP, "valid six-slot IDs changed during cache migration")
    req("spirit_item" not in hero, "self-player hero still projects a fabricated spirit_item cache")
    req({int(row["spirit_id"]) for row in p.spirit_list} == {1, 4, 5, 7, 12, 15}, "Backpack Spirit authority changed")


def test_durable_restart_bootstrap_uses_backpack_fallback() -> None:
    with tempfile.TemporaryDirectory(prefix="pass171_restart_") as td:
        db = MultiUserDatabase(Path(td) / "server_state", DATA)
        p = smoke_player()
        db.save_player(p)
        loaded = db.load_player(p.player_id)
        req(loaded is not None, "durable restart reload failed")
        # MultiUserDatabase maintenance must self-heal the stale cache on load.
        hero = loaded.heroes["10073"]
        req(hero["spirit_equip"] == SMOKE_EQUIP, "restart changed valid equipment IDs")
        req("spirit_item" not in hero, "restart maintenance retained stale empty Spirit cache")

        services = RequestServices(loaded, DATA, lambda: None, catalog=GAME)
        hero_wire = services.heroes.payload()["heros"]["10073"]
        backpack_wire = loaded.backpack_payload()
        req("spirit_item" not in hero_wire, "MID49 bootstrap reintroduced spirit_item=[]")
        req(hero_wire["spirit_equip"] == SMOKE_EQUIP, "MID49 equipment wire drift")

        by_id = {int(row["spirit_id"]): row for row in backpack_wire["spirit_list"]}
        resolved = [by_id.get(spirit_id) for spirit_id in hero_wire["spirit_equip"]]
        req(all(row is not None for row in resolved), "Backpack fallback cannot resolve every equipped spirit_id")
        req([int(row["spirit_id"]) for row in resolved] == SMOKE_EQUIP, "Backpack fallback slot ordering drift")

        # Source-shaped numeric lookup check: getSpiritEquipsAttr ultimately sums
        # materialized main/sub values of a requested attribute. Attribute 45 in
        # the real smoke fixture is 60 (Spirit 7 sub) + 156 (Spirit 4 sub) +
        # 60 (Spirit 12 sub) + 120 (Spirit 15 main) = 396. This verifies restart
        # resolution preserves
        # numeric stat materialization rather than merely avoiding nil objects.
        attr_id = 45
        total = 0.0
        for row in resolved:
            if int(row.get("main_attr", 0)) == attr_id:
                total += float(row.get("main_attr_value", 0))
            for sub_attr, sub_value in zip(row.get("sub_attr", []), row.get("sub_attr_value", [])):
                if int(sub_attr) == attr_id:
                    total += float(sub_value)
        req(total == 396.0, f"equipped numeric attr 45 drift after restart: {total}")

        # The load maintenance write should also make the repair durable, so a
        # second restart cannot resurrect the empty semantic cache.
        reloaded = db.load_player(p.player_id)
        req(reloaded is not None and "spirit_item" not in reloaded.heroes["10073"], "second restart resurrected spirit_item cache")


def test_advanced_pack_oath_observation_is_source_expected() -> None:
    catalog = json.loads((DATA / "gift_opening_source_catalog.json").read_text(encoding="utf-8"))
    row = next(op for op in catalog["operations"] if int(op.get("item_id", 0)) == 50002168 and int(op.get("gift_id", 0)) == 90040453)
    req(row.get("item_name") == "Adv. Horcrux Pack", "advanced-pack source identity drift")
    candidates = row["drop_occurrences"][0]["candidates"]
    req(len(candidates) == 6, "advanced-pack candidate cardinality drift")
    req({str(candidate.get("item_name")) for candidate in candidates} == {"Oath"}, "advanced pack is no longer Oath-only in source")
    req(sum(int(candidate.get("drop_rate", 0)) for candidate in candidates) == 10000, "advanced-pack source weights drift")
    req(sorted(int(candidate["item_id"]) for candidate in candidates) == [250001151,250001152,250001153,250001154,250001155,250001156], "advanced-pack Oath position set drift")


def main() -> None:
    tests = [
        test_source_optional_cache_contract,
        test_owned_hero_normalization_omits_semantic_cache,
        test_durable_restart_bootstrap_uses_backpack_fallback,
        test_advanced_pack_oath_observation_is_source_expected,
    ]
    for test in tests:
        test()
        print("PASS", test.__name__, flush=True)
    print(f"PASS Pass171 H6 restart reconciliation ({len(tests)}/{len(tests)})", flush=True)


if __name__ == "__main__":
    main()
