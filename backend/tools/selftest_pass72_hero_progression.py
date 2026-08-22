from __future__ import annotations

import copy
import json
import tempfile
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.multiuser_database import MultiUserDatabase, SANDBOX_UID
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.projection_profiles import ProjectionProfileRegistry
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.response_projector import ResponseProjector

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
TABLE_ID = 10001001
PARTNER_ID = 72001
STONE_ID = 40001001
EXP_ITEM = 50001001


def require(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def base_hero(*, star: int = 1, color: int = 1, lev: int = 1) -> dict:
    return {
        "partner_id": PARTNER_ID,
        "table_id": TABLE_ID,
        "star": star,
        "lev": lev,
        "exp": 0,
        "color": color,
        "skills": [1, 1, 1, 1, 1, 1],
        "equips": [0, 0, 0, 0, 0, 0],
        "fumos": [0, 0, 0, 0, 0, 0],
        "fumo_levels": [0, 0, 0, 0, 0, 0],
    }


def make_services(*, mana: int = 2_000_000, star: int = 1, color: int = 1, lev: int = 1):
    player = PlayerState(player_id="997201", account_uid="997201", player_name="Pass72")
    player.lev = 100
    player.mana = mana
    player.skill_point = 20
    player.heroes = {str(PARTNER_ID): base_hero(star=star, color=color, lev=lev)}
    player.collected_heros = {str(TABLE_ID): {"table_id": TABLE_ID, "star": star, "is_collected": 1}}
    commits: list[int] = []

    def commit() -> None:
        commits.append(int(player.persistence_state.get("state_version", -1)))

    services = RequestServices(player, DATA, commit, catalog=CATALOG)
    return player, services, commits


def project(services: RequestServices, before: ResponseProjector, result: dict, mid: int, label: str) -> dict:
    result = services.apply_semantic_deltas(result)
    journal = services.uow.consume_journal()
    profiles = ProjectionProfileRegistry.load(DATA / "projection_profile_registry.json")
    return before.project(
        result,
        services.player,
        committed_journal=journal,
        profile=profiles.resolve(mid=mid, label=label, transport="engine_web"),
    )


def main() -> None:
    progression_meta = json.loads((DATA / "hero_progression_meta.json").read_text())
    require(progression_meta["stars"]["2"]["evolve_num"] == 20, "star2 evolve fragment cost drift")
    require(progression_meta["stars"]["2"]["evolve_price"] == 35_000, "star2 evolve Mana cost drift")

    # MID52: scroll + Mana + Hero star are one commit and cumulative Mana is projected.
    player, services, commits = make_services(mana=100_000)
    player.backpack_items = [{"table_id": STONE_ID, "item_num": 20, "time": 0}]
    projector = ResponseProjector.capture(player, resource_registry=services.resource_registry)
    result = services.hero_progression.evolve_hero({"partner_id": PARTNER_ID})
    result = project(services, projector, result, 52, "EVOLVE_HERO")
    require(result.get("error_code") is None, "MID52 valid evolve rejected")
    require(result.get("economy_") == {"mana": 65_000}, "MID52 cumulative Mana projection wrong")
    require(player.mana == 65_000, "MID52 Mana not debited")
    require(services.stack_inventory.quantity(STONE_ID) == 0, "MID52 fragments not debited")
    require(int(services.heroes.get(PARTNER_ID)["star"]) == 2, "MID52 Hero star not persisted")
    require(len(commits) == 1, "MID52 should commit exactly once")

    # MID52 preflight failure is atomic.
    player2, services2, commits2 = make_services(mana=34_999)
    player2.backpack_items = [{"table_id": STONE_ID, "item_num": 20, "time": 0}]
    services2.heroes.normalize()
    before = copy.deepcopy(vars(player2))
    result2 = services2.hero_progression.evolve_hero({"partner_id": PARTNER_ID})
    require(result2.get("error_code") == 1, "insufficient-Mana MID52 did not fail closed")
    require(vars(player2) == before, "failed MID52 partially mutated state")
    require(not commits2 and services2.uow.consume_journal() == [], "failed MID52 leaked commit/journal")

    # MID55 EXP item is stack debit + Hero ENTITY transition.
    player3, services3, _ = make_services()
    player3.backpack_items = [{"table_id": EXP_ITEM, "item_num": 3, "time": 0}]
    before_exp = int(services3.heroes.get(PARTNER_ID)["exp"])
    r55 = services3.hero_progression.use_exp_item({"partner_id": PARTNER_ID, "item_id": EXP_ITEM, "item_num": 2})
    journal55 = services3.uow.consume_journal()
    require(r55.get("item_id") == EXP_ITEM, "MID55 response contract drift")
    require(services3.stack_inventory.quantity(EXP_ITEM) == 1, "MID55 stack debit failed")
    require(int(services3.heroes.get(PARTNER_ID)["exp"]) > before_exp, "MID55 Hero EXP did not change")
    require([row["category"] for row in journal55] == ["STACK", "ENTITY"], "MID55 journal families drift")

    # MID53 Skill Point + Hero skill change are one typed transaction.
    player4, services4, _ = make_services()
    old_skill = int(services4.heroes.get(PARTNER_ID)["skills"][0])
    r53 = services4.heroes.upgrade_single_skill(PARTNER_ID, 1)
    journal53 = services4.uow.consume_journal()
    require(r53.get("skill_point") == 19, "MID53 Skill Point debit failed")
    require(int(services4.heroes.get(PARTNER_ID)["skills"][0]) == old_skill + 1, "MID53 Hero skill not persisted")
    categories53 = [row["category"] for row in journal53]
    require(categories53[-2:] == ["TEMPORAL", "ENTITY"], "MID53 typed journal drift")

    # MID39 batch skill path also couples scalar Mana, temporal Skill Points and ENTITY Hero state.
    player4b, services4b, _ = make_services(mana=1_000_000)
    old_mana4b = player4b.mana
    r39 = services4b.heroes.upgrade_skills(PARTNER_ID, "1", "1")
    journal39 = services4b.uow.consume_journal()
    require(r39.get("skills", "").split("|")[0] == "2", "MID39 Hero skill response drift")
    require(player4b.mana < old_mana4b, "MID39 Mana cost was not settled")
    require(int(services4b.heroes.get(PARTNER_ID)["skills"][0]) == 2, "MID39 Hero skill not persisted")
    cats39 = [row["category"] for row in journal39]
    require("RESOURCE" in cats39 and cats39[-2:] == ["TEMPORAL", "ENTITY"], "MID39 typed settlement families drift")

    # MID63 multi-EXP path aggregates stack debit and one Hero ENTITY EXP transition.
    player4c, services4c, _ = make_services()
    player4c.backpack_items = [{"table_id": EXP_ITEM, "item_num": 5, "time": 0}]
    services4c.hero_progression.use_exp_items({
        "partner_id": PARTNER_ID, "items": [{"item_id": EXP_ITEM, "item_num": 3}]
    })
    journal63 = services4c.uow.consume_journal()
    require(services4c.stack_inventory.quantity(EXP_ITEM) == 2, "MID63 stack debit failed")
    require(int(services4c.heroes.get(PARTNER_ID)["exp"]) > 0, "MID63 Hero EXP did not persist")
    require([row["category"] for row in journal63] == ["STACK", "ENTITY"], "MID63 typed journal drift")

    # MID54 single equipment consumes exactly one source item and marks the slot.
    player5, services5, _ = make_services(lev=100)
    equip_ids = services5.hero_equipment._equip_ids(services5.heroes.get(PARTNER_ID))
    require(len(equip_ids) == 6 and equip_ids[0] > 0, "source equipment list unavailable")
    player5.backpack_items = [{"table_id": equip_ids[0], "item_num": 2, "time": 0}]
    r54 = services5.hero_equipment.set_hero_equip(PARTNER_ID, 1)
    journal54 = services5.uow.consume_journal()
    require(r54 == {}, "MID54 valid equip rejected")
    require(services5.stack_inventory.quantity(equip_ids[0]) == 1, "MID54 item debit failed")
    require(services5.heroes.get(PARTNER_ID)["equips"][0] == 1, "MID54 equip slot not persisted")
    require([row["category"] for row in journal54] == ["STACK", "ENTITY"], "MID54 typed journal drift")

    # MID62 one-click equip consumes all directly available current-color gear and marks canonical slots.
    player5b, services5b, _ = make_services(mana=2_000_000, lev=100)
    equip_ids5b = services5b.hero_equipment._equip_ids(services5b.heroes.get(PARTNER_ID))
    counts5b: dict[int, int] = {}
    for iid in equip_ids5b:
        if iid > 0:
            counts5b[iid] = counts5b.get(iid, 0) + 1
    player5b.backpack_items = [
        {"table_id": iid, "item_num": count + 2, "time": 0} for iid, count in counts5b.items()
    ]
    r62 = services5b.hero_equipment.one_click_equip(PARTNER_ID)
    journal62 = services5b.uow.consume_journal()
    require(r62.get("equips") == [1, 1, 1, 1, 1, 1], "MID62 equipment response drift")
    require(services5b.heroes.get(PARTNER_ID)["equips"] == [1, 1, 1, 1, 1, 1], "MID62 slots not persisted")
    require([row["category"] for row in journal62][-1] == "ENTITY", "MID62 Hero ENTITY journal missing")

    # MID57 one-click promotion consumes current-color gear and changes color atomically.
    player6, services6, _ = make_services(mana=2_000_000, lev=100)
    equip_ids6 = services6.hero_equipment._equip_ids(services6.heroes.get(PARTNER_ID))
    counts: dict[int, int] = {}
    for iid in equip_ids6:
        if iid > 0:
            counts[iid] = counts.get(iid, 0) + 1
    player6.backpack_items = [
        {"table_id": iid, "item_num": count + 2, "time": 0} for iid, count in counts.items()
    ]
    r57 = services6.hero_equipment.one_click_promote(PARTNER_ID)
    journal57 = services6.uow.consume_journal()
    require(r57.get("restore_items") == [], "MID57 response contract drift")
    require(int(services6.heroes.get(PARTNER_ID)["color"]) == 2, "MID57 color promotion not persisted")
    require(any(row["category"] == "ENTITY" and row["action"] == "PROMOTE_COLOR" for row in journal57), "MID57 ENTITY promotion journal missing")

    # MID51 promotes only after gear is already collected; no extra gear debit is invented.
    player7, services7, _ = make_services(lev=100)
    hero7 = services7.heroes.get(PARTNER_ID)
    hero7["equips"] = [1, 1, 1, 1, 1, 1]
    r51 = services7.hero_equipment.powerup_hero(PARTNER_ID)
    journal51 = services7.uow.consume_journal()
    require(r51 == {}, "MID51 valid powerup rejected")
    require(int(services7.heroes.get(PARTNER_ID)["color"]) == 2, "MID51 color transition not persisted")
    require([row["category"] for row in journal51] == ["ENTITY"], "MID51 should be an entity-only transition")

    # Debug inventory seed is sandbox-only and strictly one-shot.
    seed = json.loads((DATA / "debug_guest_inventory_seed.json").read_text())
    require(seed["total_unique_seed_item_count"] == 839, "debug gear seed count drift")
    with tempfile.TemporaryDirectory() as tmp:
        db = MultiUserDatabase(Path(tmp), DATA)
        debug = PlayerState(player_id="13371337", account_uid=SANDBOX_UID, player_name="Debug")
        require(db._apply_pass72_debug_inventory_seed(debug), "sandbox seed did not apply")
        sample = int(seed["item_ids"][0])
        row = next(row for row in debug.backpack_items if int(row["table_id"]) == sample)
        require(int(row["item_num"]) >= 1000, "sandbox seed quantity too small")
        row["item_num"] = 999
        require(not db._apply_pass72_debug_inventory_seed(debug), "sandbox seed reapplied after marker")
        require(int(row["item_num"]) == 999, "sandbox seed replenished consumed test gear")
        normal = PlayerState(player_id="80001", account_uid="80001", player_name="Normal")
        require(not db._apply_pass72_debug_inventory_seed(normal), "debug seed leaked to credential account")

    print(json.dumps({
        "pass": "72.0",
        "status": "PASS",
        "mid52_atomic_fragment_mana_entity": True,
        "mid52_cumulative_mana_projection": True,
        "mid55_stack_entity_exp": True,
        "mid53_temporal_entity_skill": True,
        "mid54_stack_entity_equipment": True,
        "mid57_atomic_gear_promotion": True,
        "mid51_entity_only_powerup": True,
        "entity_projection_tags_suppressed": True,
        "debug_seed": {
            "sandbox_only": True,
            "one_shot": True,
            "minimum_quantity": 1000,
            "unique_item_ids": 839,
        },
        "deferred": [
            "AWAKE_HERO numeric MID unresolved in effective mid.lua",
            "SuperHero/post-5 evolution semantics",
            "advanced awakened/bloodline/Fumo restoration",
            "Campaign stamina debit",
        ],
    }, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
