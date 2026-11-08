#!/usr/bin/env python3
"""Bot roster, mode entry and status for the v2 real-client playtest.

A bot enters every competitive mode through the same front MIDs a stock phone
sends, so the production owners write the defenses, ladders, ranks and snapshots.
Temporary test tool, not product code.
"""

import argparse
import hashlib
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
import zlib
from datetime import datetime, timezone
from pathlib import Path

HARNESS_DIRECTORY = Path(__file__).resolve().parent
sys.path.insert(0, str(HARNESS_DIRECTORY))

import import_legacy

PLAYTEST_HOME = import_legacy.PLAYTEST_HOME
FRONT_BASE = import_legacy.FRONT_BASE
STATE_DIRECTORY = import_legacy.STATE_DIRECTORY
ACCOUNTS_PATH = import_legacy.ACCOUNTS_PATH
REGION = import_legacy.REGION
ROSTER_PATH = HARNESS_DIRECTORY / "bots.json"
TEAM_ROLES_PATH = HARNESS_DIRECTORY / "team_roles.json"
SCENARIO_DIRECTORY = HARNESS_DIRECTORY / "scenarios"
CONTENT_DIRECTORY = (
    HARNESS_DIRECTORY / "backend" / "internal" / "content" / "builtin" / "generated"
)
PET_CORE_CATALOG_PATH = CONTENT_DIRECTORY / "pet_core_catalog.json"
PET_PROGRESSION_CATALOG_PATH = CONTENT_DIRECTORY / "pet_progression_catalog.json"
DEFAULT_SOURCE_SAVE = "preserve/server_state/players/12525385/player.json"

PLAYABLE_PET_TEMPLATE_COUNT = 54
MAXIMUM_PET_STAR = 5
MAXIMUM_PET_COLOR = 16
PET_ROW_COLUMNS = (
    "player_id",
    "pet_id",
    "table_id",
    "origin_table_id",
    "star",
    "level",
    "exp",
    "color",
    "birthday",
    "is_show",
    "skill_1",
    "skill_2",
    "skill_3",
    "skill_4",
    "skill_5",
    "equip_1",
    "equip_2",
    "equip_3",
    "fumo_1",
    "fumo_2",
    "fumo_3",
    "practice_str",
    "practice_int",
    "practice_agi",
    "active_style",
    "creation_content_revision",
    "state_version",
    "created_at",
    "updated_at",
)

FUNCTION_TOP_FLOOR = 4
FUNCTION_ONE_ON_ONE = 16
FUNCTION_ARENA = 37
FUNCTION_LEAGUE = 91
TOP_FLOOR_FREEZE_START_MINUTE = 13 * 60
TOP_FLOOR_FREEZE_END_MINUTE = 13 * 60 + 30
ONE_ON_ONE_CLOSE_HOUR = 14
BATTLE_PROOF_CAMPAIGN = 100001
ENERGY_FOR_BATTLE_PROOF = 1_000_000


class BotFailure(Exception):
    pass


def fail(message):
    raise BotFailure(message)


def post_envelope(payload):
    data = urllib.parse.urlencode({"payload": json.dumps(payload)}).encode("utf-8")
    request = urllib.request.Request(
        f"{FRONT_BASE}/engine",
        data=data,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=180) as reply:
            raw = reply.read()
            return reply.status, json.loads(raw)
    except urllib.error.HTTPError as error:
        raw = error.read()
        try:
            return error.code, json.loads(raw)
        except json.JSONDecodeError:
            return error.code, {"raw": raw[:300].decode("utf-8", "replace")}


def stock_request(token, mid, parameters=None):
    payload = {
        "mid": mid,
        "token": token,
        "region": REGION,
        "v_": "1.631.0",
        "app_v": "1.631.0",
        "platform": 3,
    }
    payload.update(parameters or {})
    return post_envelope(payload)


def describe_failure(status, body):
    if isinstance(body, dict):
        code = body.get("error_code")
        name = body.get("error")
        parts = [f"http {status}"]
        if code is not None:
            parts.append(f"error_code={code}")
        if name:
            parts.append(str(name))
        return " ".join(parts)
    return f"http {status}"


def query_json(sql):
    text = import_legacy.query_text(sql)
    return json.loads(text) if text else None


def load_roster():
    return json.loads(ROSTER_PATH.read_text(encoding="utf-8"))["bots"]


def load_scaling_content():
    core = json.loads((CONTENT_DIRECTORY / "hero_core_catalog.json").read_text(encoding="utf-8"))
    equipment = json.loads(
        (CONTENT_DIRECTORY / "hero_equipment_catalog.json").read_text(encoding="utf-8")
    )
    gates = json.loads(
        (CONTENT_DIRECTORY / "function_gates.json").read_text(encoding="utf-8")
    )
    return {
        "kinds": {int(template["table_id"]): template["hero_kind"] for template in core["templates"]},
        "positions": {
            (int(row["hero_table_id"]), int(row["color"]), int(row["slot"]))
            for row in equipment["positions"]
        },
        "gates": {int(row["function_id"]): row["raw_open_value"] for row in gates["gates"]},
    }


def strength_key(hero):
    return (
        int(hero.get("star", 1)),
        int(hero.get("lev", 1)),
        int(hero.get("color", 1)),
        int(hero.get("table_id", 0)),
        int(hero.get("partner_id", 0)),
    )


def load_team_roles():
    return json.loads(TEAM_ROLES_PATH.read_text(encoding="utf-8"))


def composition_score(heroes, catalogue):
    role_tags = set()
    damage_kinds = set()
    hero_types = set()
    for hero in heroes:
        role = catalogue["role_by_hero"].get(str(int(hero["table_id"])), {})
        role_tags.update(role.get("role_tags") or [role.get("role")])
        damage_kinds.update(role.get("damage_kind") or [])
        if role.get("type"):
            hero_types.add(role["type"])
    weights = {"tank": 4, "healer": 4, "controller": 2, "support": 2, "damage": 1}
    return (
        sum(weights.get(role_tag, 0) for role_tag in role_tags)
        + len(hero_types)
        + int("physical" in damage_kinds)
        + int("magic" in damage_kinds)
    )


FORMATION_ROWS = (2, 3, 4)  # distance_type front, middle, rear
MAXIMUM_PER_ROW = 2
# How many equally matched catalogue teams a bot may rotate through, so cloned rosters differ.
TEAM_VARIANT_SPREAD = 5


def position_allows(selected, hero, catalogue):
    def row_of(member):
        return catalogue["role_by_hero"].get(str(int(member["table_id"])), {}).get("distance_type")

    row = row_of(hero)
    if row not in FORMATION_ROWS:
        return False
    counts = {formation_row: 0 for formation_row in FORMATION_ROWS}
    for member in selected:
        if row_of(member) in counts:
            counts[row_of(member)] += 1
    counts[row] += 1
    if counts[row] > MAXIMUM_PER_ROW:
        return False
    slots_left = 5 - len(selected) - 1
    empty_rows = sum(1 for count in counts.values() if count == 0)
    return empty_rows <= slots_left


def team_variant(login):
    return zlib.crc32(login.casefold().encode("utf-8"))


def team_candidate(heroes, catalogue, template, unavailable_partner_ids):
    available = sorted(
        (hero for hero in heroes if int(hero["partner_id"]) not in unavailable_partner_ids),
        key=strength_key,
        reverse=True,
    )
    selected = []
    selected_partner_ids = set()
    selected_table_ids = set()
    matched_hero_count = 0
    template_heroes = template["heroes"] if template else []
    for table_id in template_heroes:
        matching = next(
            (
                hero
                for hero in available
                if int(hero["table_id"]) == int(table_id)
                and int(hero["partner_id"]) not in selected_partner_ids
                and int(hero["table_id"]) not in selected_table_ids
            ),
            None,
        )
        if matching is None:
            continue
        selected.append(matching)
        selected_partner_ids.add(int(matching["partner_id"]))
        selected_table_ids.add(int(matching["table_id"]))
        matched_hero_count += 1
    while len(selected) < 5:
        remaining = [
            hero
            for hero in available
            if int(hero["partner_id"]) not in selected_partner_ids
            and int(hero["table_id"]) not in selected_table_ids
        ]
        if not remaining:
            return None
        # A roster too narrow for the 1-2 per row rule still fields five girls.
        placeable = [hero for hero in remaining if position_allows(selected, hero, catalogue)]
        next_hero = max(
            placeable or remaining,
            key=lambda hero: (
                composition_score(selected + [hero], catalogue),
                strength_key(hero),
            ),
        )
        selected.append(next_hero)
        selected_partner_ids.add(int(next_hero["partner_id"]))
        selected_table_ids.add(int(next_hero["table_id"]))
    return {
        "heroes": selected,
        "template": template,
        "matched_hero_count": matched_hero_count,
    }


def select_teams(heroes, catalogue, team_count, variant=0):
    if team_count < 1:
        return []
    unique_partner_ids = {int(hero["partner_id"]) for hero in heroes}
    if len(unique_partner_ids) < team_count * 5:
        return []
    selected_teams = []
    unavailable_partner_ids = set()
    used_template_indexes = set()
    templates = catalogue["teams"]
    for _ in range(team_count):
        candidates = []
        for template_index, template in enumerate(templates):
            if template_index in used_template_indexes:
                continue
            candidate = team_candidate(heroes, catalogue, template, unavailable_partner_ids)
            if candidate is None:
                continue
            candidate["template_index"] = template_index
            candidates.append(candidate)
        if not candidates:
            fallback = team_candidate(heroes, catalogue, None, unavailable_partner_ids)
            if fallback is None:
                return []
            candidates.append(fallback)
        ranked = sorted(
            candidates,
            key=lambda candidate: (
                candidate["matched_hero_count"],
                {"mid": 0, "high": 1, "top": 2}.get(
                    (candidate["template"] or {}).get("tier"), 0
                ),
                composition_score(candidate["heroes"], catalogue),
                tuple(
                    strength_key(hero)
                    for hero in sorted(candidate["heroes"], key=strength_key, reverse=True)
                ),
            ),
            reverse=True,
        )
        equally_matched = [
            candidate
            for candidate in ranked[:TEAM_VARIANT_SPREAD]
            if candidate["matched_hero_count"] == ranked[0]["matched_hero_count"]
        ]
        best_team = equally_matched[(variant + len(selected_teams)) % len(equally_matched)]
        selected_teams.append(best_team)
        unavailable_partner_ids.update(
            int(hero["partner_id"]) for hero in best_team["heroes"]
        )
        if "template_index" in best_team:
            used_template_indexes.add(best_team["template_index"])
    return selected_teams


def select_pet(heroes, pets, catalogue, preferred_table_id=None, unavailable_pet_ids=None):
    unavailable_pet_ids = unavailable_pet_ids or set()
    available_pets = [
        pet
        for pet in pets
        if int(pet.get("pet_id", 0)) > 0
        and int(pet["pet_id"]) not in unavailable_pet_ids
    ]
    if not available_pets:
        return 0
    hero_table_ids = {int(hero["table_id"]) for hero in heroes}
    recommendations = {
        (int(pair["pet_id"]), int(pair["hero_id"]))
        for pair in catalogue["source_defined_pet_recommendations"]
    }
    selected_pet = max(
        available_pets,
        key=lambda pet: (
            int(preferred_table_id is not None and int(pet["table_id"]) == int(preferred_table_id)),
            sum(
                (int(pet["table_id"]), hero_table_id) in recommendations
                for hero_table_id in hero_table_ids
            ),
            int(pet.get("star", 1)),
            int(pet.get("level", 1)),
            int(pet.get("color", 1)),
            int(pet["pet_id"]),
        ),
    )
    return int(selected_pet["pet_id"])


def select_heroes(heroes, count, quality):
    ordered = sorted(heroes.items(), key=lambda item: strength_key(item[1]), reverse=quality == "strongest")
    if count > 0:
        ordered = ordered[:count]
    return {key: value for key, value in ordered}


def scale_hero(hero, specification, content):
    kind = content["kinds"].get(int(hero["table_id"]))
    if kind is None:
        fail(f"hero template {hero['table_id']} is not in the active hero catalog")
    level_cap = int(specification["hero_level_cap"])
    star_cap = int(specification["star_cap"])
    color_cap = int(specification["color_cap"])
    original_color = int(hero.get("color", 1))
    hero["lev"] = max(1, min(int(hero.get("lev", 1)), level_cap))
    hero["exp"] = 0
    hero["star"] = max(1, min(int(hero.get("star", 1)), star_cap))
    hero["color"] = max(1, min(original_color, color_cap))
    equips = list(hero.get("equips") or [0] * 6)[:6]
    equips += [0] * (6 - len(equips))
    if kind == "NORMAL":
        table_id = int(hero["table_id"])
        for slot in range(6):
            if int(equips[slot]) != 0 and (table_id, int(hero["color"]), slot + 1) not in content["positions"]:
                equips[slot] = 0
            elif int(equips[slot]) != 0:
                equips[slot] = 1
    hero["equips"] = equips
    fumos = list(hero.get("fumos") or [0] * 6)[:6]
    fumos += [0] * (6 - len(fumos))
    # A Fumo row belongs to the item of its color, so a lower color or a cleared
    # slot cannot keep the high-color raw value (I5 derives it against the item cap).
    for slot in range(6):
        if int(hero["color"]) != original_color or int(equips[slot]) == 0:
            fumos[slot] = 0
    hero["fumos"] = fumos
    if specification.get("strip_derived"):
        strip_derived_state(hero)
    return hero


def strip_derived_state(hero):
    """Keep base level/star/color/equipment/skills only.

    March projects every Top Floor defense while matching; a scaled clone's
    optional spirits, elements, courses, inscriptions and awakening cost the
    same per hero as a full clone's and push 20 candidates past the 30 s March
    transaction budget. Scaled clones are for rank range, so they carry base
    state only.
    """
    hero["element_equips"] = []
    hero["element_levels"] = []
    hero["element_bak_equips"] = []
    hero["element_bak_levels"] = []
    hero["spirit_equip"] = [0] * 6
    hero["inscript_items"] = {}
    hero["courses"] = []
    hero["courses_progress"] = []
    hero["courses_skill"] = []
    hero["courses_quality"] = []
    hero["courses_exp"] = []
    hero["evo_stage"] = 1
    hero["evo_attr_points"] = {}
    hero["twice_awake_stage"] = 0
    hero["feed_attrs"] = {}
    hero["favor_degree"] = 0
    hero["is_married"] = 0
    hero["collect_quality_stage"] = 0
    hero["collect_star_stage"] = 0
    hero["skin_ids"] = []
    hero["current_skin_id"] = 0
    hero["illusion_skin_id"] = 0
    hero["practice_attr"] = [0, 0, 0]


def gate_allows(raw_gate, level, vip, owned_girls):
    if raw_gate is None:
        return False
    parts = [int(part) for part in raw_gate.split("|")]
    kind = parts[0]
    if kind == 1:
        return level >= parts[1]
    if kind == 2:
        return True
    if kind == 3:
        return level >= parts[1] and vip >= parts[2]
    if kind == 6:
        return level >= parts[1] and owned_girls >= parts[2]
    return False


def build_overrides(player, specification, content):
    level = int(specification["player_level"])
    currency_scale = float(specification["currency_scale"])
    owned = select_heroes(
        player["heroes"]["heroes"],
        int(specification["keep_heroes"]),
        specification.get("hero_quality", "strongest"),
    )
    for hero in owned.values():
        scale_hero(hero, specification, content)
    progression = {"lev": level, "exp": max(0, int(specification["player_exp"]))}
    overrides = {
        "progression": progression,
        "heroes": {"heroes": owned},
    }
    economy = {}
    for key in import_legacy.ITEM_SCALAR_KEYS:
        if key in import_legacy.PROGRESSION_SCALAR_KEYS:
            continue
        value = (player.get("economy") or {}).get(key)
        if isinstance(value, int) and value > 0:
            economy[key] = max(1, int(value * currency_scale))
    overrides["economy"] = economy
    for key in import_legacy.PROGRESSION_SCALAR_KEYS:
        value = (player.get("progression") or {}).get(key)
        if isinstance(value, int) and value > 0:
            progression[key] = max(1, int(value * currency_scale))
    if specification.get("filter_functions"):
        vip = int((player.get("progression") or {}).get("vip", 0))
        source_functions = (player.get("progression") or {}).get("func_ids") or []
        progression["func_ids"] = [
            int(function_id)
            for function_id in source_functions
            if gate_allows(content["gates"].get(int(function_id)), level, vip, len(owned))
        ]
    return overrides


def import_roster_entry(entry, content, pet_content=None):
    save_path = HARNESS_DIRECTORY / entry.get("source_save", DEFAULT_SOURCE_SAVE)
    save = json.loads(save_path.read_text(encoding="utf-8"))
    specification = entry["overrides"]
    overrides = build_overrides(save["player"], specification, content)
    # import_player deep-merges overrides, so a smaller hero map must replace the
    # save's map before the merge instead of being merged into it.
    save["player"]["heroes"]["heroes"] = overrides.pop("heroes")["heroes"]
    report = import_legacy.import_player(
        save, entry["login"], entry["display_name"], overrides
    )
    refused_heroes = [
        row
        for row in report["content_refused"]
        if row.get("kind") in ("hero", "hero-equipment")
    ]
    if refused_heroes:
        fail(f"{entry['login']}: v2 refused a scaled hero: {refused_heroes[:3]}")
    if not report["player_id"]:
        fail(f"{entry['login']}: import produced no player id")
    pet_specification = specification.get("pets")
    if pet_specification is not None:
        if pet_content is None:
            pet_content = load_active_pet_catalog()
        player_id = int(report["player_id"])
        root_state = pet_root_states([player_id]).get(player_id)
        if root_state is None:
            fail(f"{entry['login']}: imported player has no Pet root")
        report["pets_written"] = grant_pet_rows(
            entry["login"], player_id, pet_specification, pet_content, root_state
        )
    return report


def state_query(logins):
    accounts = import_legacy.load_accounts()
    account_ids = []
    for login in logins:
        uid = accounts["logins"].get(login.casefold())
        if uid is None:
            fail(f"{login}: no harness account")
        account_ids.append(uid)
    quoted = ",".join(import_legacy.quote(uid) + "::uuid" for uid in account_ids)
    sql = (
        "SELECT COALESCE(json_agg(json_build_object("
        "'account_id',p.account_id::text,'player_id',p.player_id,'level',pp.level,'vip',dp.vip,"
        "'functions',COALESCE((SELECT json_agg(u.function_id ORDER BY u.function_id)"
        " FROM player_function_unlocks u WHERE u.player_id=p.player_id),'[]'::json))),'[]'::json)::text"
        " FROM players p"
        " JOIN player_progression pp ON pp.player_id=p.player_id"
        " JOIN player_directory_profiles dp ON dp.player_id=p.player_id"
        f" WHERE p.logical_server_id={REGION} AND p.account_id IN ({quoted})"
    )
    rows = query_json(sql) or []
    by_account = {row["account_id"]: row for row in rows}
    states = {}
    for login in logins:
        uid = accounts["logins"][login.casefold()]
        if uid not in by_account:
            fail(f"{login}: no player row on logical server {REGION}")
        states[login] = by_account[uid]
    return accounts, states


def hero_query(player_ids):
    if not player_ids:
        return {}
    identifiers = ",".join(str(int(player_id)) for player_id in player_ids)
    sql = (
        "SELECT COALESCE(json_agg(json_build_object("
        "'player_id',h.player_id,'partner_id',h.partner_id,'table_id',h.table_id,"
        "'star',h.star,'lev',h.level,'color',h.color)),'[]'::json)::text"
        " FROM player_heroes h"
        f" WHERE h.player_id IN ({identifiers})"
    )
    rows = query_json(sql) or []
    heroes = {}
    for row in rows:
        heroes.setdefault(int(row["player_id"]), []).append(row)
    return heroes


def pet_query(player_ids):
    if not player_ids:
        return {}
    identifiers = ",".join(str(int(player_id)) for player_id in player_ids)
    sql = (
        "SELECT COALESCE(json_agg(json_build_object("
        "'player_id',p.player_id,'pet_id',p.pet_id,'table_id',p.table_id,"
        "'origin_table_id',p.origin_table_id,'star',p.star,'level',p.level,'color',p.color)),'[]'::json)::text"
        " FROM player_pets p"
        f" WHERE p.player_id IN ({identifiers})"
    )
    rows = query_json(sql) or []
    pets = {}
    for row in rows:
        pets.setdefault(int(row["player_id"]), []).append(row)
    return pets


def expected_pet_template_origins(template_rows):
    expected = {}
    for template in template_rows:
        table_id = int(template["table_id"])
        origin_table_id = int(template["origin_table_id"])
        if table_id <= 0 or origin_table_id <= 0 or table_id in expected:
            fail("Pet catalog contains an invalid or duplicate template ID")
        expected[table_id] = origin_table_id
    origin_counts = {}
    for origin_table_id in expected.values():
        origin_counts[origin_table_id] = origin_counts.get(origin_table_id, 0) + 1
    if len(expected) != PLAYABLE_PET_TEMPLATE_COUNT or len(origin_counts) != 27:
        fail("Pet catalog does not describe all 54 playable templates")
    if any(count != 2 for count in origin_counts.values()):
        fail("Pet catalog does not contain paired base and awakened templates")
    if any(expected.get(origin_table_id) != origin_table_id for origin_table_id in origin_counts):
        fail("Pet catalog is missing a base template for an origin")
    return expected


def pet_templates_from_rows(template_rows, expected_origins):
    actual_origins = {}
    for row in template_rows:
        table_id = int(row["table_id"])
        origin_table_id = int(row["origin_table_id"])
        if table_id in actual_origins:
            fail("Pet content contains duplicate template IDs")
        actual_origins[table_id] = origin_table_id
    if actual_origins != expected_origins:
        fail("active Pet templates do not match the 54-template playable pool")
    return [
        {"table_id": table_id, "origin_table_id": expected_origins[table_id]}
        for table_id in sorted(expected_origins)
    ]


def pet_experience_by_level(exp_rows):
    experience_by_level = {}
    for row in exp_rows:
        level = int(row["level"])
        if level in experience_by_level:
            fail("Pet progression contains duplicate levels")
        experience_by_level[level] = int(row["total_exp"])
    if not experience_by_level:
        fail("Pet progression content is empty")
    return experience_by_level


def pet_skill_content(progression_catalog):
    slots_by_template = {}
    for row in progression_catalog["skill_slots"]:
        slots_by_template.setdefault(int(row["table_id"]), {})[int(row["slot"])] = row
    return {
        "policy_by_slot": {
            int(row["slot"]): row for row in progression_catalog["slot_policy"]
        },
        "slots_by_template": slots_by_template,
    }


def pet_skill_levels(template, level, star, color, skill_content):
    # Highest raw level each slot accepts (backend characterpet/progression.go
    # skill upgrade guard); a locked or empty slot keeps the column default 1.
    awakened = int(template["table_id"]) != int(template["origin_table_id"])
    slots = skill_content["slots_by_template"].get(int(template["table_id"]), {})
    levels = {}
    for slot in range(1, 6):
        definition = slots.get(slot)
        policy = skill_content["policy_by_slot"][slot]
        if policy["requires_awakened"]:
            unlocked = awakened
        else:
            unlocked = color >= int(policy["min_color"])
        if definition is None or int(definition["source_skill_id"]) == 0 or not unlocked:
            levels[f"skill_{slot}"] = 1
            continue
        star_bonus = int(definition["star_bonus"]) if slot <= star - 1 else 0
        levels[f"skill_{slot}"] = max(1, level + star_bonus - int(policy["effective_offset"]))
    return levels


def load_pet_catalog_files():
    core_catalog = json.loads(PET_CORE_CATALOG_PATH.read_text(encoding="utf-8"))
    progression_catalog = json.loads(
        PET_PROGRESSION_CATALOG_PATH.read_text(encoding="utf-8")
    )
    expected_origins = expected_pet_template_origins(core_catalog["templates"])
    return {
        "templates": pet_templates_from_rows(core_catalog["templates"], expected_origins),
        "experience_by_level": pet_experience_by_level(
            progression_catalog["exp_rows"]
        ),
        "skill_content": pet_skill_content(progression_catalog),
    }


def load_active_pet_catalog():
    static_catalog = load_pet_catalog_files()
    revision_id = import_legacy.active_revision()
    active_content = query_json(
        "SELECT json_build_object("
        "'templates',COALESCE((SELECT json_agg(json_build_object("
        "'table_id',table_id,'origin_table_id',origin_table_id) ORDER BY table_id)"
        " FROM gxb_content_pet_templates"
        f" WHERE revision_id={import_legacy.quote(revision_id)}),'[]'::json),"
        "'exp_rows',COALESCE((SELECT json_agg(json_build_object("
        "'level',level,'total_exp',total_exp) ORDER BY level)"
        " FROM gxb_content_pet_exp"
        f" WHERE revision_id={import_legacy.quote(revision_id)}),'[]'::json)"
        ")::text"
    )
    if not isinstance(active_content, dict):
        fail("active Pet content is missing")
    expected_origins = {
        int(template["table_id"]): int(template["origin_table_id"])
        for template in static_catalog["templates"]
    }
    return {
        "revision_id": revision_id,
        "templates": pet_templates_from_rows(
            active_content.get("templates") or [], expected_origins
        ),
        "experience_by_level": pet_experience_by_level(
            active_content.get("exp_rows") or []
        ),
        # shortcut: skill ceilings come from the generated catalog the harness deployed, not the DB revision; read the DB if they ever diverge.
        "skill_content": static_catalog["skill_content"],
    }


def select_pet_templates(login, specification, templates):
    if not isinstance(specification, dict):
        fail(f"{login}: Pet override must be an object")
    if specification.get("pool") != "playable":
        fail(f"{login}: Pet pool must be playable")
    if specification.get("seed") != "login":
        fail(f"{login}: Pet selection seed must be login")
    count = int(specification["count"])
    # The stock client has no models for several awakened pets (e.g. 110250001), so seed base forms only.
    templates = [
        template
        for template in templates
        if int(template["table_id"]) == int(template["origin_table_id"])
    ]
    origins = {int(template["origin_table_id"]) for template in templates}
    if count < 1 or count > len(origins):
        fail(f"{login}: Pet count exceeds distinct playable origins")
    login_seed = login.casefold()
    ordered_templates = sorted(
        templates,
        key=lambda template: (
            hashlib.sha256(
                f"{login_seed}:{int(template['table_id'])}".encode("utf-8")
            ).digest(),
            int(template["table_id"]),
        ),
    )
    selected_templates = []
    selected_origins = set()
    for template in ordered_templates:
        origin_table_id = int(template["origin_table_id"])
        if origin_table_id in selected_origins:
            continue
        selected_templates.append(template)
        selected_origins.add(origin_table_id)
        if len(selected_templates) == count:
            break
    if len(selected_templates) != count:
        fail(f"{login}: could not select the configured number of Pets")
    return selected_templates


def build_pet_rows(
    login,
    specification,
    content,
    revision_id,
    player_id,
    next_pet_id,
    existing_origins=(),
    created_at=None,
):
    if not isinstance(specification, dict):
        fail(f"{login}: Pet override must be an object")
    if len(revision_id) != 64:
        fail("Pet grant requires a valid content revision")
    if created_at is None:
        created_at = datetime.now(timezone.utc)
    if created_at.tzinfo is None:
        fail("Pet grant timestamp must include a timezone")
    experience_by_level = content["experience_by_level"]
    level = int(specification["level"])
    if level not in experience_by_level:
        fail(f"{login}: Pet level {level} has no progression content")
    star_value = specification["star"]
    star = MAXIMUM_PET_STAR if star_value == "max" else int(star_value)
    if not 1 <= star <= MAXIMUM_PET_STAR:
        fail(f"{login}: Pet star is outside the supported range")
    color_value = specification.get("color", 1)
    color = MAXIMUM_PET_COLOR if color_value == "max" else int(color_value)
    if not 1 <= color <= MAXIMUM_PET_COLOR:
        fail(f"{login}: Pet color is outside the supported range")
    existing_origin_ids = {int(origin_table_id) for origin_table_id in existing_origins}
    rows = []
    for template in select_pet_templates(login, specification, content["templates"]):
        origin_table_id = int(template["origin_table_id"])
        if origin_table_id in existing_origin_ids:
            continue
        pet_id = int(next_pet_id) + len(rows)
        row = {
            "player_id": int(player_id),
            "pet_id": pet_id,
            "table_id": int(template["table_id"]),
            "origin_table_id": origin_table_id,
            "star": star,
            "level": level,
            "exp": int(experience_by_level[level]),
            "color": color,
            "birthday": int(created_at.timestamp()),
            "is_show": True,
            "creation_content_revision": revision_id,
            "state_version": 1,
            "created_at": created_at.isoformat(),
            "updated_at": created_at.isoformat(),
        }
        row.update(
            pet_skill_levels(template, level, star, color, content["skill_content"])
        )
        row.update({f"equip_{slot}": 0 for slot in range(1, 4)})
        row.update({f"fumo_{slot}": 0 for slot in range(1, 4)})
        row.update({"practice_str": 0, "practice_int": 0, "practice_agi": 0})
        row["active_style"] = 0
        rows.append(row)
    return rows


def pet_root_states(player_ids):
    if not player_ids:
        return {}
    identifiers = ",".join(str(int(player_id)) for player_id in player_ids)
    rows = query_json(
        "SELECT COALESCE(json_agg(json_build_object("
        "'player_id',root.player_id,'next_pet_id',root.next_pet_id,"
        "'state_version',root.state_version,'existing_origins',COALESCE("
        "(SELECT json_agg(pet.origin_table_id ORDER BY pet.origin_table_id)"
        " FROM player_pets pet WHERE pet.player_id=root.player_id),'[]'::json))"
        " ORDER BY root.player_id),'[]'::json)::text"
        " FROM player_pet_roots root"
        f" WHERE root.player_id IN ({identifiers})"
    ) or []
    return {int(row["player_id"]): row for row in rows}


def pet_row_insert_sql(row):
    values = []
    for column in PET_ROW_COLUMNS:
        value = import_legacy.quote(row[column])
        if column in ("created_at", "updated_at"):
            value += "::timestamptz"
        values.append(value)
    return (
        f"INSERT INTO player_pets({','.join(PET_ROW_COLUMNS)}) "
        f"VALUES({','.join(values)});"
    )


def pet_grant_transaction_sql(player_id, root_state, rows):
    expected_next_pet_id = int(root_state["next_pet_id"])
    expected_state_version = int(root_state["state_version"])
    inserts = "\n".join(pet_row_insert_sql(row) for row in rows)
    return (
        "BEGIN;\n"
        "SET LOCAL lock_timeout = '5s';\n"
        "DO $pet_grant$\n"
        "DECLARE\n"
        "    current_next_pet_id bigint;\n"
        "    current_state_version bigint;\n"
        "BEGIN\n"
        "    SELECT next_pet_id,state_version INTO current_next_pet_id,current_state_version\n"
        "    FROM player_pet_roots\n"
        f"    WHERE player_id={int(player_id)} FOR UPDATE;\n"
        "    IF NOT FOUND THEN\n"
        "        RAISE EXCEPTION 'Pet root is missing';\n"
        "    END IF;\n"
        f"    IF current_next_pet_id <> {expected_next_pet_id} OR "
        f"current_state_version <> {expected_state_version} THEN\n"
        "        RAISE EXCEPTION 'Pet root changed; rerun grant-pets';\n"
        "    END IF;\n"
        f"{inserts}\n"
        "    UPDATE player_pet_roots\n"
        f"    SET next_pet_id=current_next_pet_id+{len(rows)},"
        "state_version=current_state_version+1,updated_at=transaction_timestamp()\n"
        f"    WHERE player_id={int(player_id)};\n"
        "    IF NOT FOUND THEN\n"
        "        RAISE EXCEPTION 'Pet root update failed';\n"
        "    END IF;\n"
        "END\n"
        "$pet_grant$;\n"
        "COMMIT;\n"
    )


def grant_pet_rows(login, player_id, specification, content, root_state):
    rows = build_pet_rows(
        login,
        specification,
        content,
        content["revision_id"],
        player_id,
        root_state["next_pet_id"],
        root_state.get("existing_origins") or [],
    )
    if rows:
        import_legacy.run_psql(
            pet_grant_transaction_sql(player_id, root_state, rows)
        )
    return len(rows)


def login_token(login, accounts):
    account = accounts["accounts"][accounts["logins"][login.casefold()]]
    session = account.get("session") or import_legacy.ensure_session(accounts, account)
    status, listing = post_envelope(import_legacy.envelope(session, 18))
    if status != 200:
        fail(f"{login}: MID18 {describe_failure(status, listing)}")
    status, mid1 = post_envelope(import_legacy.envelope(session, 1))
    if status != 200:
        fail(f"{login}: MID1 {describe_failure(status, mid1)}")
    token = mid1.get("token")
    if not token:
        fail(f"{login}: MID1 returned no gameplay token")
    return token, mid1


def strongest(heroes, count):
    ordered = sorted(heroes, key=strength_key, reverse=True)
    return ordered[:count]


def top_floor_window(now):
    minute = now.hour * 60 + now.minute
    return TOP_FLOOR_FREEZE_START_MINUTE <= minute < TOP_FLOOR_FREEZE_END_MINUTE


def enter_top_floor(token, functions, heroes, pets, catalogue, frozen, variant):
    if FUNCTION_TOP_FLOOR not in functions:
        return "closed (function 4)"
    status, body = stock_request(token, 272)
    if status != 200:
        return describe_failure(status, body)
    teams = select_teams(heroes, catalogue, 1, variant)
    if not teams:
        return "closed (fewer than five distinct girls)"
    team = teams[0]
    partner_ids = [int(hero["partner_id"]) for hero in team["heroes"]]
    preferred_pet_table_id = (team["template"] or {}).get("pet")
    pet_id = select_pet(team["heroes"], pets, catalogue, preferred_pet_table_id)
    status, body = stock_request(token, 278, {"heroIDs": partner_ids, "pet_id": pet_id})
    if status != 200:
        return describe_failure(status, body)
    return f"defense={len(partner_ids)}" + (" frozen" if frozen else "")


def enter_arena(token, functions, heroes, pets, catalogue, variant):
    if FUNCTION_ARENA not in functions:
        return "closed (function 37)"
    status, body = stock_request(token, 768)
    if status != 200:
        return describe_failure(status, body)
    teams = select_teams(heroes, catalogue, 1, variant)
    if not teams:
        return "closed (fewer than five distinct girls)"
    team = teams[0]
    table_ids = [int(hero["table_id"]) for hero in team["heroes"]]
    preferred_pet_table_id = (team["template"] or {}).get("pet")
    pet_id = select_pet(team["heroes"], pets, catalogue, preferred_pet_table_id)
    status, body = stock_request(token, 770, {"heros": table_ids, "pet_id": pet_id})
    if status != 200:
        return describe_failure(status, body)
    return f"defense={len(table_ids)}"


def enter_one_on_one(token, functions, heroes, pets, catalogue, now, variant):
    if FUNCTION_ONE_ON_ONE not in functions:
        return "closed (function 16)"
    if now.hour >= ONE_ON_ONE_CLOSE_HOUR:
        return "closed (window 00:00-14:00 UTC)"
    status, body = stock_request(token, 2480)
    if status != 200:
        return describe_failure(status, body)
    team_count = len(body.get("defense") or []) if isinstance(body, dict) else 0
    if team_count < 1:
        team_count = 3
    teams = select_teams(heroes, catalogue, team_count, variant)
    if not teams:
        return "closed (not enough distinct girls for teams)"
    formations = []
    used_pet_ids = set()
    for team in teams:
        partner_ids = [int(hero["partner_id"]) for hero in team["heroes"]]
        formation = "|".join(str(partner_id) for partner_id in partner_ids)
        preferred_pet_table_id = (team["template"] or {}).get("pet")
        pet_id = select_pet(
            team["heroes"], pets, catalogue, preferred_pet_table_id, used_pet_ids
        )
        if pet_id:
            formation += "@" + str(pet_id)
            used_pet_ids.add(pet_id)
        formations.append(formation)
    status, body = stock_request(token, 2481, {"formations": formations})
    if status != 200:
        return describe_failure(status, body)
    return f"teams={len(teams)}"


def enter_league(token, functions, heroes, pets, catalogue, variant):
    if FUNCTION_LEAGUE not in functions:
        return "closed (function 91)"
    status, body = stock_request(token, 2800)
    if status != 200:
        return describe_failure(status, body)
    teams = select_teams(heroes, catalogue, 1, variant)
    if not teams:
        return "closed (fewer than five distinct girls)"
    team = teams[0]
    partner_ids = [int(hero["partner_id"]) for hero in team["heroes"]]
    formation = "|".join(str(partner_id) for partner_id in partner_ids)
    preferred_pet_table_id = (team["template"] or {}).get("pet")
    pet_id = select_pet(team["heroes"], pets, catalogue, preferred_pet_table_id)
    status, body = stock_request(
        token, 2805, {"formation": formation, "pet_id": pet_id}
    )
    if status != 200:
        return "closed (season): " + describe_failure(status, body)
    return f"defense={len(partner_ids)}"


def enter_bot(login, accounts, state, heroes, pets, catalogue, modes):
    token, _ = login_token(login, accounts)
    now = datetime.now(timezone.utc)
    functions = {int(function_id) for function_id in state.get("functions") or []}
    variant = team_variant(login)
    result = {}
    if modes is None or "top_floor" in modes:
        result["top_floor"] = enter_top_floor(
            token, functions, heroes, pets, catalogue, top_floor_window(now), variant
        )
    if modes is None or "arena" in modes:
        result["arena"] = enter_arena(token, functions, heroes, pets, catalogue, variant)
    if modes is None or "one_on_one" in modes:
        result["one_on_one"] = enter_one_on_one(
            token, functions, heroes, pets, catalogue, now, variant
        )
    if modes is None or "league" in modes:
        result["league"] = enter_league(token, functions, heroes, pets, catalogue, variant)
    return result


def set_energy(player_id, amount):
    import_legacy.run_psql(
        "UPDATE player_temporal_resources SET stored_amount="
        f"{int(amount)},regen_anchor_at=now(),state_version=state_version+1,updated_at=now() "
        f"WHERE player_id={int(player_id)} AND resource_key='energy';"
    )


def prove_battle(login, accounts, state, heroes, pets, catalogue):
    ordered_heroes = strongest(heroes, len(heroes))
    full_team_count = len(ordered_heroes) // 5
    teams = select_teams(ordered_heroes, catalogue, full_team_count)
    proof_groups = list(teams)
    selected_partner_ids = {
        int(hero["partner_id"])
        for team in teams
        for hero in team["heroes"]
    }
    remaining_heroes = [
        hero
        for hero in ordered_heroes
        if int(hero["partner_id"]) not in selected_partner_ids
    ]
    for offset in range(0, len(remaining_heroes), 5):
        proof_groups.append(
            {
                "heroes": remaining_heroes[offset : offset + 5],
                "template": None,
            }
        )
    set_energy(state["player_id"], ENERGY_FOR_BATTLE_PROOF)
    token, _ = login_token(login, accounts)
    settled = 0
    for proof_group in proof_groups:
        partner_ids = [int(hero["partner_id"]) for hero in proof_group["heroes"]]
        formation = "|".join(str(partner_id) for partner_id in partner_ids)
        preferred_pet_table_id = (proof_group["template"] or {}).get("pet")
        pet_id = select_pet(
            proof_group["heroes"], pets, catalogue, preferred_pet_table_id
        )
        request = {
            "campaign_id": BATTLE_PROOF_CAMPAIGN,
            "campaign_type": 1,
            "formation": formation,
            "pet_id": pet_id,
        }
        status, body = stock_request(token, 113, request)
        if status != 200:
            fail(f"{login}: battle proof start {formation}: {describe_failure(status, body)}")
        status, body = stock_request(token, 114, dict(request, star=3))
        if status != 200:
            fail(f"{login}: battle proof settle {formation}: {describe_failure(status, body)}")
        settled += len(proof_group["heroes"])
    if settled != len(ordered_heroes):
        fail(f"{login}: battle proof covered {settled} of {len(ordered_heroes)} scaled heroes")


def command_grant_pets(arguments):
    roster = load_roster()
    for entry in roster:
        if not isinstance(entry.get("overrides", {}).get("pets"), dict):
            fail(f"{entry['login']}: missing pets override")
    pet_content = load_active_pet_catalog()
    _, states = state_query([entry["login"] for entry in roster])
    player_ids = [int(states[entry["login"]]["player_id"]) for entry in roster]
    root_states = pet_root_states(player_ids)
    for entry, player_id in zip(roster, player_ids):
        if player_id not in root_states:
            fail(f"{entry['login']}: player has no Pet root")
        build_pet_rows(
            entry["login"],
            entry["overrides"]["pets"],
            pet_content,
            pet_content["revision_id"],
            player_id,
            root_states[player_id]["next_pet_id"],
            root_states[player_id].get("existing_origins") or [],
        )
    for entry, player_id in zip(roster, player_ids):
        count = grant_pet_rows(
            entry["login"],
            player_id,
            entry["overrides"]["pets"],
            pet_content,
            root_states[player_id],
        )
        print(f"grant-pets {entry['login']} added={count}")
    pets_by_player = pet_query(player_ids)
    for entry, player_id in zip(roster, player_ids):
        expected_origins = {
            int(template["origin_table_id"])
            for template in select_pet_templates(
                entry["login"],
                entry["overrides"]["pets"],
                pet_content["templates"],
            )
        }
        actual_origins = {
            int(pet["origin_table_id"])
            for pet in pets_by_player.get(player_id, [])
        }
        if not expected_origins <= actual_origins:
            fail(f"{entry['login']}: Pet grant did not persist all selected origins")
    result = command_enter(arguments)
    if result != 0:
        return result
    print(f"BOTS_GRANT_PETS_PASS {len(roster)} bots")
    return 0


def command_create(arguments):
    roster = load_roster()
    content = load_scaling_content()
    pet_content = load_active_pet_catalog()
    catalogue = load_team_roles()
    for entry in roster:
        report = import_roster_entry(entry, content, pet_content)
        print(
            f"create {entry['login']} pid={report['player_id']} "
            f"level={entry['overrides']['player_level']} "
            f"heroes={report['rows_written'].get('player_heroes', 0)} "
            f"pets={report.get('pets_written', 0)} "
            f"refused={len(report['content_refused'])}"
        )
    accounts, states = state_query([entry["login"] for entry in roster])
    player_ids = [state["player_id"] for state in states.values()]
    heroes_by_player = hero_query(player_ids)
    proof_entries = [entry for entry in roster if entry["overrides"].get("prove_battle")]
    if proof_entries:
        pets_by_player = pet_query(player_ids)
        for entry in proof_entries:
            state = states[entry["login"]]
            player_id = int(state["player_id"])
            heroes = heroes_by_player.get(player_id, [])
            pets = pets_by_player.get(player_id, [])
            prove_battle(entry["login"], accounts, state, heroes, pets, catalogue)
            print(f"battle-proof {entry['login']} heroes={len(heroes)} ok")
    print(f"BOTS_CREATE_PASS {len(roster)} bots")
    return 0


def command_enter(arguments):
    roster = load_roster()
    catalogue = load_team_roles()
    accounts, states = state_query([entry["login"] for entry in roster])
    player_ids = [state["player_id"] for state in states.values()]
    heroes_by_player = hero_query(player_ids)
    pets_by_player = pet_query(player_ids)
    for entry in roster:
        login = entry["login"]
        state = states[login]
        player_id = int(state["player_id"])
        heroes = heroes_by_player.get(player_id, [])
        pets = pets_by_player.get(player_id, [])
        if not heroes:
            fail(f"{login}: no heroes to field")
        result = enter_bot(login, accounts, state, heroes, pets, catalogue, None)
        modes = " ".join(f"{name}={value}" for name, value in result.items())
        print(f"enter {login} pid={state['player_id']} level={state['level']} {modes}")
    print(f"BOTS_ENTER_PASS {len(roster)} bots")
    return 0


def selfcheck_pet_grants():
    content = load_pet_catalog_files()
    roster = load_roster()
    if len(roster) != 20:
        fail("bots.json must contain the 20 configured Pet bots")
    choices_by_login = {}
    for entry in roster:
        login = entry["login"]
        specification = entry["overrides"].get("pets")
        selected_templates = select_pet_templates(
            login, specification, content["templates"]
        )
        selected_template_ids = tuple(
            int(template["table_id"]) for template in selected_templates
        )
        repeated_template_ids = tuple(
            int(template["table_id"])
            for template in select_pet_templates(
                login, specification, content["templates"]
            )
        )
        selected_origins = {
            int(template["origin_table_id"]) for template in selected_templates
        }
        if selected_template_ids != repeated_template_ids:
            fail(f"{login}: Pet template selection is not deterministic")
        if len(selected_templates) != int(specification["count"]):
            fail(f"{login}: Pet template selection returned the wrong count")
        if len(selected_origins) != len(selected_templates):
            fail(f"{login}: Pet template selection repeats a unique origin")
        choices_by_login[login] = selected_template_ids
    if len(set(choices_by_login.values())) < 2:
        fail("Pet template selection did not vary across logins")
    if content["experience_by_level"].get(100) != 1_980_095:
        fail("Pet level-100 experience does not match the generated progression catalog")

    base_skills = pet_skill_levels(
        {"table_id": 10010001, "origin_table_id": 10010001},
        100, MAXIMUM_PET_STAR, MAXIMUM_PET_COLOR, content["skill_content"],
    )
    awakened_skills = pet_skill_levels(
        {"table_id": 110010001, "origin_table_id": 10010001},
        100, MAXIMUM_PET_STAR, MAXIMUM_PET_COLOR, content["skill_content"],
    )
    low_color_skills = pet_skill_levels(
        {"table_id": 10010001, "origin_table_id": 10010001},
        100, MAXIMUM_PET_STAR, 1, content["skill_content"],
    )
    if list(base_skills.values()) != [100, 110, 80, 60, 1]:
        fail(f"Pet skill ceilings wrong for a base Pet: {base_skills}")
    if list(awakened_skills.values()) != [100, 110, 80, 60, 40]:
        fail(f"Pet skill ceilings wrong for an awakened Pet: {awakened_skills}")
    if list(low_color_skills.values()) != [100, 1, 1, 1, 1]:
        fail(f"Pet skill slots unlocked below their color: {low_color_skills}")

    login = roster[0]["login"]
    specification = roster[0]["overrides"]["pets"]
    selected_templates = select_pet_templates(
        login, specification, content["templates"]
    )
    created_at = datetime(2026, 1, 2, 3, 4, 5, tzinfo=timezone.utc)
    revision_id = "a" * 64
    rows = build_pet_rows(
        login,
        specification,
        content,
        revision_id,
        12345,
        17,
        created_at=created_at,
    )
    if len(rows) != len(selected_templates):
        fail("Pet grant row builder returned the wrong number of rows")
    expected_values = {
        "player_id": 12345,
        "star": MAXIMUM_PET_STAR,
        "level": 100,
        "exp": 1_980_095,
        "color": MAXIMUM_PET_COLOR,
        "birthday": int(created_at.timestamp()),
        "is_show": True,
        "creation_content_revision": revision_id,
        "state_version": 1,
        "created_at": created_at.isoformat(),
        "updated_at": created_at.isoformat(),
        "equip_1": 0,
        "equip_2": 0,
        "equip_3": 0,
        "fumo_1": 0,
        "fumo_2": 0,
        "fumo_3": 0,
        "practice_str": 0,
        "practice_int": 0,
        "practice_agi": 0,
        "active_style": 0,
    }
    for index, (row, template) in enumerate(zip(rows, selected_templates)):
        expected_row = dict(
            expected_values,
            pet_id=17 + index,
            table_id=int(template["table_id"]),
            origin_table_id=int(template["origin_table_id"]),
            **pet_skill_levels(
                template, 100, MAXIMUM_PET_STAR, MAXIMUM_PET_COLOR, content["skill_content"]
            ),
        )
        if row != expected_row or set(row) != set(PET_ROW_COLUMNS):
            fail("Pet grant row values do not match the selected templates")
    completed_rows = build_pet_rows(
        login,
        specification,
        content,
        revision_id,
        12345,
        17,
        existing_origins=[template["origin_table_id"] for template in selected_templates],
        created_at=created_at,
    )
    if completed_rows:
        fail("Pet grant row builder did not skip existing origins")
    partial_rows = build_pet_rows(
        login,
        specification,
        content,
        revision_id,
        12345,
        17,
        existing_origins=[selected_templates[0]["origin_table_id"]],
        created_at=created_at,
    )
    if len(partial_rows) != len(rows) - 1 or partial_rows[0]["pet_id"] != 17:
        fail("Pet grant row builder did not allocate missing rows contiguously")
    grant_sql = pet_grant_transaction_sql(
        12345, {"next_pet_id": 17, "state_version": 7}, rows
    )
    if grant_sql.count("INSERT INTO player_pets(") != len(rows):
        fail("Pet grant SQL did not write each generated row")
    if "FOR UPDATE" not in grant_sql or "current_next_pet_id+3" not in grant_sql:
        fail("Pet grant SQL did not lock and advance the Pet root")


def command_selfcheck(arguments):
    catalogue = load_team_roles()
    role_by_hero = catalogue.get("role_by_hero")
    teams = catalogue.get("teams")
    recommendations = catalogue.get("source_defined_pet_recommendations")
    if not isinstance(role_by_hero, dict) or len(role_by_hero) != 277:
        fail("team_roles.json has an unexpected hero role catalogue")
    if not isinstance(teams, list) or len(teams) != 30:
        fail("team_roles.json has an unexpected team catalogue")
    if not isinstance(recommendations, list) or len(recommendations) != 134:
        fail("team_roles.json has an unexpected pet recommendation catalogue")
    for team in teams:
        if len(team.get("heroes", [])) != 5 or team.get("tier") not in ("top", "high", "mid"):
            fail("team_roles.json contains an invalid team entry")
        if any(hero_id not in role_by_hero for hero_id in team["heroes"]):
            fail("team_roles.json team references an unknown hero")
    synthetic_heroes = [
        {
            "partner_id": index + 1,
            "table_id": int(hero_table_id),
            "star": 5,
            "lev": 100,
            "color": 10,
        }
        for index, hero_table_id in enumerate(list(role_by_hero)[:15])
    ]
    selected_teams = select_teams(synthetic_heroes, catalogue, 3)
    if len(selected_teams) != 3:
        fail("team builder did not produce three complete teams")
    selected_partner_ids = [
        int(hero["partner_id"])
        for team in selected_teams
        for hero in team["heroes"]
    ]
    if len(selected_partner_ids) != 15 or len(set(selected_partner_ids)) != 15:
        fail("team builder reused a hero across teams")
    for team in selected_teams:
        if len(team["heroes"]) != 5 or len({int(hero["table_id"]) for hero in team["heroes"]}) != 5:
            fail("team builder returned an incomplete or duplicate lineup")
    by_row = {
        formation_row: [
            hero_table_id
            for hero_table_id, role in role_by_hero.items()
            if role.get("distance_type") == formation_row
        ][:5]
        for formation_row in FORMATION_ROWS
    }
    row_roster = [
        {"partner_id": 1000 + index, "table_id": int(hero_table_id), "star": 5, "lev": 100, "color": 10}
        for index, hero_table_id in enumerate(
            hero_table_id for row_ids in by_row.values() for hero_table_id in row_ids
        )
    ]
    for team in select_teams(row_roster, catalogue, 3):
        rows = [role_by_hero[str(hero["table_id"])]["distance_type"] for hero in team["heroes"]]
        if any(not 1 <= rows.count(formation_row) <= MAXIMUM_PER_ROW for formation_row in FORMATION_ROWS):
            fail(f"team builder broke the 1-2 per row rule: {rows}")
    catalogue_roster = []
    for team in teams:
        for hero_table_id in team["heroes"]:
            if all(hero["table_id"] != int(hero_table_id) for hero in catalogue_roster):
                catalogue_roster.append(
                    {"partner_id": 2000 + len(catalogue_roster), "table_id": int(hero_table_id), "star": 5, "lev": 100, "color": 10}
                )
    first_teams = {
        tuple(hero["table_id"] for hero in select_teams(catalogue_roster, catalogue, 1, variant)[0]["heroes"])
        for variant in range(TEAM_VARIANT_SPREAD)
    }
    if len(first_teams) < 2:
        fail("cloned rosters with different logins all field the same team")
    preferred_table_id = int(teams[0]["pet"])
    synthetic_pets = [
        {"pet_id": 801, "table_id": preferred_table_id, "star": 1, "level": 1},
        {"pet_id": 802, "table_id": preferred_table_id + 1, "star": 5, "level": 100},
    ]
    selected_pet_id = select_pet(
        selected_teams[0]["heroes"], synthetic_pets, catalogue, preferred_table_id
    )
    if selected_pet_id != 801:
        fail("pet selection confused pet instance IDs with table IDs")
    second_pet_id = select_pet(
        selected_teams[0]["heroes"], synthetic_pets, catalogue, unavailable_pet_ids={801}
    )
    if second_pet_id != 802 or select_pet([], [], catalogue) != 0:
        fail("pet selection failed ownership or empty-roster checks")
    selfcheck_pet_grants()
    print("BOTS_SELFCHECK_PASS teams=3 pet_templates=54 network=none database=none")
    return 0


def command_status(arguments):
    roster = load_roster()
    accounts, states = state_query([entry["login"] for entry in roster])
    for entry in roster:
        login = entry["login"]
        state = states[login]
        row = query_json(
            "SELECT json_build_object("
            "'top_floor_defense',(SELECT jsonb_array_length(defense) FROM top_floor_players WHERE player_id=p.player_id),"
            "'arena_defense',(SELECT jsonb_array_length(defense->'heroes') FROM arena_players WHERE player_id=p.player_id),"
            "'one_on_one_teams',(SELECT jsonb_array_length(teams) FROM one_on_one_players WHERE player_id=p.player_id),"
            "'league_defense',(SELECT jsonb_array_length(payload->'Defense'->'Heroes') FROM league_players WHERE player_id=p.player_id)"
            ")::text FROM players p WHERE p.player_id=" + str(int(state["player_id"]))
        ) or {}

        def shown(value):
            return "-" if value is None else str(value)

        print(
            f"{login} pid={state['player_id']} level={state['level']} vip={state['vip']} "
            f"top_floor={shown(row.get('top_floor_defense'))} "
            f"arena={shown(row.get('arena_defense'))} "
            f"one_on_one={shown(row.get('one_on_one_teams'))} "
            f"league={shown(row.get('league_defense'))}"
        )
    print(f"BOTS_STATUS {len(roster)} bots")
    return 0


def create_born_player(accounts, login, display_name):
    normalized = login.casefold()
    uid = accounts["logins"].get(normalized)
    if uid is None:
        uid = str(uuid.uuid4())
        accounts["accounts"][uid] = {
            "uid": uid,
            "login": login,
            "username": login,
            "account_type": "normal",
            "created_at": 0,
            "password": None,
            "session": None,
        }
        accounts["logins"][normalized] = uid
    account = accounts["accounts"][uid]
    account["password"] = import_legacy.password_record(import_legacy.assigned_password(login))
    import_legacy.save_accounts(accounts)
    player_id, _ = import_legacy.birth_player(accounts, account)
    print(f"born {login} pid={player_id} name={display_name}")
    return player_id


def command_scenario(arguments):
    if not arguments:
        fail("usage: bots.py scenario <name>")
    name = arguments[0]
    path = SCENARIO_DIRECTORY / f"{name}.json"
    scenario = json.loads(path.read_text(encoding="utf-8"))
    content = load_scaling_content()
    catalogue = load_team_roles()
    scenario_players = scenario.get("players") or []
    pet_content = None
    if any(entry.get("overrides", {}).get("pets") is not None for entry in scenario_players):
        pet_content = load_active_pet_catalog()
    logins = []
    for entry in scenario_players:
        report = import_roster_entry(entry, content, pet_content)
        logins.append(entry["login"])
        print(f"scenario {name}: import {entry['login']} pid={report['player_id']}")
    born_accounts = import_legacy.load_accounts()
    for born in scenario.get("born_accounts") or []:
        create_born_player(born_accounts, born["login"], born["display_name"])
    if logins:
        accounts, states = state_query(logins)
        player_ids = [state["player_id"] for state in states.values()]
        heroes_by_player = hero_query(player_ids)
        pets_by_player = pet_query(player_ids)
        for entry in scenario_players:
            login = entry["login"]
            state = states[login]
            player_id = int(state["player_id"])
            heroes = heroes_by_player.get(player_id, [])
            pets = pets_by_player.get(player_id, [])
            result = enter_bot(
                login,
                accounts,
                state,
                heroes,
                pets,
                catalogue,
                scenario.get("modes"),
            )
            modes = " ".join(f"{mode}={value}" for mode, value in result.items())
            print(f"scenario {name}: enter {login} {modes}")
    print(f"SCENARIO_PASS {name}")
    return 0


def main(arguments):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command",
        choices=["create", "grant-pets", "enter", "status", "scenario", "selfcheck"],
    )
    parser.add_argument("name", nargs="?")
    parsed = parser.parse_args(arguments)
    try:
        if parsed.command == "create":
            return command_create(parsed)
        if parsed.command == "grant-pets":
            return command_grant_pets(parsed)
        if parsed.command == "enter":
            return command_enter(parsed)
        if parsed.command == "status":
            return command_status(parsed)
        if parsed.command == "selfcheck":
            return command_selfcheck(parsed)
        return command_scenario([] if parsed.name is None else [parsed.name])
    except BotFailure as error:
        print(f"bots: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
