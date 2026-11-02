#!/usr/bin/env python3
"""Bot roster, mode entry and status for the v2 real-client playtest.

A bot enters every competitive mode through the same front MIDs a stock phone
sends, so the production owners write the defenses, ladders, ranks and snapshots.
Temporary test tool, not product code.
"""

import argparse
import json
import secrets
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
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
SCENARIO_DIRECTORY = HARNESS_DIRECTORY / "scenarios"
CONTENT_DIRECTORY = (
    HARNESS_DIRECTORY / "backend" / "internal" / "content" / "builtin" / "generated"
)
DEFAULT_SOURCE_SAVE = "preserve/server_state/players/12525385/player.json"

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


def import_roster_entry(entry, content):
    save_path = HARNESS_DIRECTORY / entry.get("source_save", DEFAULT_SOURCE_SAVE)
    save = json.loads(save_path.read_text(encoding="utf-8"))
    specification = entry["overrides"]
    overrides = build_overrides(save["player"], specification, content)
    # import_player deep-merges overrides, so a smaller hero map must replace the
    # save's map before the merge instead of being merged into it.
    save["player"]["heroes"]["heroes"] = overrides.pop("heroes")["heroes"]
    report = import_legacy.import_player(
        save, entry["login"], entry["display_name"], None, overrides
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


def strongest_table_ids(heroes, count):
    seen = set()
    tables = []
    for hero in sorted(heroes, key=strength_key, reverse=True):
        table_id = int(hero["table_id"])
        if table_id in seen:
            continue
        seen.add(table_id)
        tables.append(table_id)
        if len(tables) == count:
            break
    return tables


def split_teams(partner_ids, team_count):
    if team_count < 1:
        return []
    teams = [[] for _ in range(team_count)]
    for index, partner_id in enumerate(partner_ids):
        teams[index % team_count].append(partner_id)
    if any(len(team) < 1 or len(team) > 5 for team in teams):
        return []
    return teams


def top_floor_window(now):
    minute = now.hour * 60 + now.minute
    return TOP_FLOOR_FREEZE_START_MINUTE <= minute < TOP_FLOOR_FREEZE_END_MINUTE


def enter_top_floor(token, functions, heroes, frozen):
    if FUNCTION_TOP_FLOOR not in functions:
        return "closed (function 4)"
    status, body = stock_request(token, 272)
    if status != 200:
        return describe_failure(status, body)
    partner_ids = [int(hero["partner_id"]) for hero in strongest(heroes, 5)]
    status, body = stock_request(token, 278, {"heroIDs": partner_ids, "pet_id": 0})
    if status != 200:
        return describe_failure(status, body)
    return f"defense={len(partner_ids)}" + (" frozen" if frozen else "")


def enter_arena(token, functions, heroes):
    if FUNCTION_ARENA not in functions:
        return "closed (function 37)"
    status, body = stock_request(token, 768)
    if status != 200:
        return describe_failure(status, body)
    table_ids = strongest_table_ids(heroes, 5)
    if len(table_ids) != 5:
        return "closed (fewer than five girls)"
    status, body = stock_request(token, 770, {"heros": table_ids, "pet_id": 0})
    if status != 200:
        return describe_failure(status, body)
    return f"defense={len(table_ids)}"


def enter_one_on_one(token, functions, heroes, now):
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
    partner_ids = [int(hero["partner_id"]) for hero in strongest(heroes, 15)]
    teams = split_teams(partner_ids, team_count)
    if not teams:
        return "closed (not enough girls for teams)"
    formations = ["|".join(str(partner_id) for partner_id in team) for team in teams]
    status, body = stock_request(token, 2481, {"formations": formations})
    if status != 200:
        return describe_failure(status, body)
    return f"teams={len(teams)}"


def enter_league(token, functions, heroes):
    if FUNCTION_LEAGUE not in functions:
        return "closed (function 91)"
    status, body = stock_request(token, 2800)
    if status != 200:
        return describe_failure(status, body)
    partner_ids = [int(hero["partner_id"]) for hero in strongest(heroes, 5)]
    formation = "|".join(str(partner_id) for partner_id in partner_ids)
    status, body = stock_request(token, 2805, {"formation": formation, "pet_id": 0})
    if status != 200:
        return "closed (season): " + describe_failure(status, body)
    return f"defense={len(partner_ids)}"


def enter_bot(login, accounts, state, heroes, modes):
    token, _ = login_token(login, accounts)
    now = datetime.now(timezone.utc)
    functions = {int(function_id) for function_id in state.get("functions") or []}
    result = {}
    if modes is None or "top_floor" in modes:
        result["top_floor"] = enter_top_floor(token, functions, heroes, top_floor_window(now))
    if modes is None or "arena" in modes:
        result["arena"] = enter_arena(token, functions, heroes)
    if modes is None or "one_on_one" in modes:
        result["one_on_one"] = enter_one_on_one(token, functions, heroes, now)
    if modes is None or "league" in modes:
        result["league"] = enter_league(token, functions, heroes)
    return result


def set_energy(player_id, amount):
    import_legacy.run_psql(
        "UPDATE player_temporal_resources SET stored_amount="
        f"{int(amount)},regen_anchor_at=now(),state_version=state_version+1,updated_at=now() "
        f"WHERE player_id={int(player_id)} AND resource_key='energy';"
    )


def prove_battle(login, accounts, state, heroes):
    partner_ids = [int(hero["partner_id"]) for hero in strongest(heroes, len(heroes))]
    set_energy(state["player_id"], ENERGY_FOR_BATTLE_PROOF)
    token, _ = login_token(login, accounts)
    settled = 0
    for offset in range(0, len(partner_ids), 5):
        formation = "|".join(str(value) for value in partner_ids[offset:offset + 5])
        request = {
            "campaign_id": BATTLE_PROOF_CAMPAIGN,
            "campaign_type": 1,
            "formation": formation,
            "pet_id": 0,
        }
        status, body = stock_request(token, 113, request)
        if status != 200:
            fail(f"{login}: battle proof start {formation}: {describe_failure(status, body)}")
        status, body = stock_request(token, 114, dict(request, star=3))
        if status != 200:
            fail(f"{login}: battle proof settle {formation}: {describe_failure(status, body)}")
        settled += len(partner_ids[offset:offset + 5])
    if settled != len(partner_ids):
        fail(f"{login}: battle proof covered {settled} of {len(partner_ids)} scaled heroes")


def command_create(arguments):
    roster = load_roster()
    content = load_scaling_content()
    for entry in roster:
        report = import_roster_entry(entry, content)
        print(
            f"create {entry['login']} pid={report['player_id']} "
            f"level={entry['overrides']['player_level']} "
            f"heroes={report['rows_written'].get('player_heroes', 0)} "
            f"refused={len(report['content_refused'])}"
        )
    accounts, states = state_query([entry["login"] for entry in roster])
    heroes_by_player = hero_query([state["player_id"] for state in states.values()])
    for entry in roster:
        if not entry["overrides"].get("prove_battle"):
            continue
        state = states[entry["login"]]
        heroes = heroes_by_player.get(int(state["player_id"]), [])
        prove_battle(entry["login"], accounts, state, heroes)
        print(f"battle-proof {entry['login']} heroes={len(heroes)} ok")
    print(f"BOTS_CREATE_PASS {len(roster)} bots")
    return 0


def command_enter(arguments):
    roster = load_roster()
    accounts, states = state_query([entry["login"] for entry in roster])
    heroes_by_player = hero_query([state["player_id"] for state in states.values()])
    for entry in roster:
        login = entry["login"]
        state = states[login]
        heroes = heroes_by_player.get(int(state["player_id"]), [])
        if not heroes:
            fail(f"{login}: no heroes to field")
        result = enter_bot(login, accounts, state, heroes, None)
        modes = " ".join(f"{name}={value}" for name, value in result.items())
        print(f"enter {login} pid={state['player_id']} level={state['level']} {modes}")
    print(f"BOTS_ENTER_PASS {len(roster)} bots")
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
    password = secrets.token_urlsafe(18)
    account["password"] = import_legacy.password_record(password)
    import_legacy.save_accounts(accounts)
    player_id, _ = import_legacy.birth_player(accounts, account)
    import_legacy.write_credential_entry(login, password)
    print(f"born {login} pid={player_id} name={display_name}")
    return player_id


def command_scenario(arguments):
    if not arguments:
        fail("usage: bots.py scenario <name>")
    name = arguments[0]
    path = SCENARIO_DIRECTORY / f"{name}.json"
    scenario = json.loads(path.read_text(encoding="utf-8"))
    content = load_scaling_content()
    logins = []
    for entry in scenario.get("players") or []:
        report = import_roster_entry(entry, content)
        logins.append(entry["login"])
        print(f"scenario {name}: import {entry['login']} pid={report['player_id']}")
    born_accounts = import_legacy.load_accounts()
    for born in scenario.get("born_accounts") or []:
        create_born_player(born_accounts, born["login"], born["display_name"])
    if logins:
        accounts, states = state_query(logins)
        heroes_by_player = hero_query([state["player_id"] for state in states.values()])
        for entry in scenario["players"]:
            login = entry["login"]
            state = states[login]
            heroes = heroes_by_player.get(int(state["player_id"]), [])
            result = enter_bot(login, accounts, state, heroes, scenario.get("modes"))
            modes = " ".join(f"{mode}={value}" for mode, value in result.items())
            print(f"scenario {name}: enter {login} {modes}")
    print(f"SCENARIO_PASS {name}")
    return 0


def main(arguments):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["create", "enter", "status", "scenario"])
    parser.add_argument("name", nargs="?")
    parsed = parser.parse_args(arguments)
    try:
        if parsed.command == "create":
            return command_create(parsed)
        if parsed.command == "enter":
            return command_enter(parsed)
        if parsed.command == "status":
            return command_status(parsed)
        return command_scenario([] if parsed.name is None else [parsed.name])
    except BotFailure as error:
        print(f"bots: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
