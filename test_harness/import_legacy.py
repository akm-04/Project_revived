#!/usr/bin/env python3
"""Import a preserved v1 player save into a born v2 player on the playtest stack.

The account is created through the harness SDK store, the player is born by the
stock MID18/MID1 flow, then one psql transaction replaces the birth rows with
rows the v2 owners accept. Temporary test tool, not product code.
"""

import copy
import hashlib
import hmac
import json
import os
import secrets
import subprocess
import sys
import time
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

HARNESS_DIRECTORY = Path(__file__).resolve().parent
WORKSPACE = HARNESS_DIRECTORY.parent
PLAYTEST_HOME = Path(os.environ.get("PLAYTEST_HOME", HARNESS_DIRECTORY / "runtime"))
PLAYTEST_TOOLS = Path(
    os.environ.get(
        "PLAYTEST_TOOLS",
        WORKSPACE / "tmp" / "tools_r4_accept" / "gxb-e2e-self-contained" / "bin",
    )
)
POSTGRES_PORT = 18957
DATABASE_NAME = "gxb_playtest"
FRONT_BASE = f"http://{os.environ.get('PLAYTEST_BIND', '127.0.0.1')}:18956"
REGION = 1
STATE_DIRECTORY = PLAYTEST_HOME / "state"
ACCOUNTS_PATH = STATE_DIRECTORY / "accounts.json"
CREDENTIALS_PATH = HARNESS_DIRECTORY / "psk" / "accounts.txt"
FIXED_PASSWORDS = {"moppleton": "akm11111", "alpaca123": "akm22222", "campaigner": "akm33333"}
FIRST_ASSIGNED_PASSWORD_NUMBER = 10001
REPORT_DIRECTORY = STATE_DIRECTORY
PRESERVE_PLAYERS = HARNESS_DIRECTORY / "preserve" / "server_state" / "players"
PASSWORD_ALGORITHM = "pbkdf2-sha256"
PBKDF2_ITERATIONS = 200_000

ITEM_SCALAR_KEYS = (
    "mana",
    "crystal",
    "lucky_coin",
    "arena_coin",
    "march_coin",
    "top_coin",
    "guild_coin",
    "region_coin",
    "king_coin",
    "honor_coin",
    "god_war_coin",
    "friendship_coin",
    "friend_medal",
    "summon_coin",
    "skin_fragment",
    "glue",
    "lvbu_coin",
    "paradise_coin",
    "team_dungeon_coin",
    "ice_core",
    "spirit_stone",
    "social",
    "glory",
    "magic_energy",
    "magic_dust",
    "magic_liquid",
    "magic_exp",
    "degree_cer",
    "graduate_cer",
    "patent_cer",
    "occult_ticket",
    "tutor_coin",
    "skin_coin",
)
PROGRESSION_SCALAR_KEYS = ("degree_cer", "graduate_cer", "patent_cer")
MAX_HERO_STAR = 8
MAX_HERO_COLOR = 16
RAW_SKILL_SEED_POLICY = "I7C2A_V1_RAW_SKILL_SEED_V1"
LIBRARY_SEED_POLICY = "LIBRARY_NEUTRAL_SEED_V1"
EVOLUTION_POLICY = "C2I_V1_STONE_LIFECYCLE_V2"
ELEMENT_POLICY = "C2G_EMPTY_PRESERVATION_SEED_V1"
SPIRIT_POLICY = "C2H_EMPTY_PRESERVATION_SEED_V1"
SPIRIT_INSTANCE_POLICY = "C2H_V1_PRESERVATION_ROLL_V1"
RAW_AWAKENING_POLICY = "C4C_PRIVATE_CHARACTER_RAW_AWAKENING_BIRTH_V1"
PRIVILEGE_POLICY = "C4A_MANUAL_PRIVILEGE_SNAPSHOT_V1"
PRIVILEGE_CLASS = "MANUAL_PRESERVATION"
PRIVILEGE_MONTHLY_ABSENT = "QUALIFIED_ABSENT"
PRIVILEGE_ISSUER = "legacy-import"
PRIVILEGE_REASON = "v1-save-import"
AUTH_PROFILE = "SID_LOGIN_TOKEN_PAIR"

IMPORTED_PATHS = {
    "player.identity.player_name",
    "player.identity.avatar_id",
    "player.identity.avatar_frame_id",
    "player.identity.player_type",
    "player.progression.lev",
    "player.progression.exp",
    "player.progression.story_id",
    "player.progression.story_state",
    "player.progression.guide_id",
    "player.progression.guide_return_id",
    "player.progression.guide_function_ids",
    "player.progression.func_ids",
    "player.progression.vip",
    "player.progression.skill_point",
    "player.progression.conquer_lev",
    "player.progression.conquer_loop_id",
    "player.progression.degree_cer",
    "player.progression.graduate_cer",
    "player.progression.patent_cer",
    "player.economy.charge",
    "player.economy.energy",
    "player.economy.spirit_energy",
    "player.heroes.hero_next_partner_id",
    "player.heroes.hero_sort_type",
    "player.heroes.heroes",
    "player.heroes.collected_heros",
    "player.inventory.backpack_items",
    "player.inventory.spirit_list",
    "player.lobby.summon",
    "player.world.world_map",
}
IMPORTED_PATHS.update(f"player.economy.{key}" for key in ITEM_SCALAR_KEYS)

NOT_IMPORTED_REASONS = {
    "_meta": "save-file metadata; no v2 owner",
    "player.identity.account_uid": "v2 links players by the harness account and session, not the v1 uid",
    "player.identity.player_id": "v2 allocates the player id inside the logical server",
    "player.identity.region": "v2 uses logical server 1; the v1 region 194/197 has no v2 server",
    "player.identity.region_name": "v2 derives the logical-server name",
    "player.identity.token": "v1 local token; v2 issues its own gameplay bearer",
    "player.identity.guild_id": "guild membership has its own owner; v1 value is zero",
    "player.progression.arena_beat_flag": "no v2 arena-beat owner",
    "player.progression.boss_incr_exp": "no v2 owner",
    "player.progression.conquer_region": "no v2 owner",
    "player.progression.crab_times": "no v2 owner",
    "player.progression.first_main_touch": "client UI flag; no v2 owner",
    "player.progression.function_state": "v2 derives eligibility; announced/pending have no owner",
    "player.progression.main_scene_type": "client UI state; no v2 owner",
    "player.progression.max_color": "v2 derives max color from content",
    "player.progression.max_lev": "v2 derives max level from content",
    "player.progression.tutorial_state": "no v2 tutorial milestone owner; first-entry flag is cleared instead",
    "player.economy.energy_time": "regen anchor is reset to the import time",
    "player.economy.spirit_energy_time": "regen anchor is reset to the import time",
    "player.economy.skill_time": "regen anchor is reset to the import time",
    "player.economy.invitation": "catalog status PARTIAL / FAIL_CLOSED; no active v2 owner",
    "player.economy.invitation_time": "catalog status PARTIAL / FAIL_CLOSED; no active v2 owner",
    "player.economy.max_energy": "v2 derives the energy cap from level and content",
    "player.economy.max_invitation": "catalog status PARTIAL / FAIL_CLOSED; no active v2 owner",
    "player.economy.buy_energy_times": "purchase counters have no v2 owner",
    "player.economy.buy_glue_times": "purchase counters have no v2 owner",
    "player.economy.buy_mana_times": "purchase counters have no v2 owner",
    "player.economy.buy_skill_times": "purchase counters have no v2 owner",
    "player.economy.buy_spirit_energy_times": "purchase counters have no v2 owner",
    "player.economy.left_card_day": "card state has no v2 owner",
    "player.economy.left_month_tili_day": "card state has no v2 owner",
    "player.economy.left_week_card_day": "card state has no v2 owner",
    "player.economy.month_card_end": "card state has no v2 owner",
    "player.economy.month_card_start": "card state has no v2 owner",
    "player.economy.privilege_left_card_day": "card state has no v2 owner",
    "player.economy.privilege_month_card_end": "card state has no v2 owner",
    "player.heroes.formation": "no v2 representative-hero owner",
    "player.heroes.hero_pieces": "no v2 hero-piece owner",
    "player.heroes.save_pet": "v1 saved-team payload; no v2 owner-shaped conversion",
    "player.heroes.save_team": "v1 saved-team payload; no v2 owner-shaped conversion",
    "player.heroes.save_team_name": "v1 saved-team payload; no v2 owner-shaped conversion",
    "player.inventory.essences": "no active v2 essence owner",
    "player.inventory.runes": "no active v2 rune owner",
    "player.inventory.scrolls": "no active v2 scroll owner",
    "player.library.bg_has_buy": "no v2 library background owner",
    "player.library.bg_main": "no v2 library background owner",
    "player.library.bg_room": "no v2 library background owner",
    "player.library.library_cg_infos": "no v2 library CG owner",
    "player.library.library_infos": "v2 derives favor/marriage from player_library_heroes",
    "player.library.library_talk_infos": "no v2 library talk owner",
    "player.lobby.activities": "no v2 activity owner for the v1 blob",
    "player.lobby.board_contents": "no v2 board-content owner",
    "player.lobby.bubble_info": "v2 projects bubbles from player_display_selections",
    "player.lobby.comment_open": "no v2 owner",
    "player.lobby.fbshare_open": "no v2 owner",
    "player.lobby.friends": "social owner exists but has no v1 friend import shape",
    "player.lobby.illusion": "illusion owner exists but the v1 blob has no convertible run",
    "player.lobby.is_commented": "no v2 owner",
    "player.lobby.mails": "v2 mail owner has its own receipt-backed shape",
    "player.lobby.message_pushes": "no v2 owner",
    "player.lobby.mission_state": "v2 mission programs use different ids; v1 story mission 80001 has no owner program",
    "player.lobby.missions": "v2 mission programs use different ids",
    "player.lobby.pets": "empty in all three saves; player_pet_roots is seeded at birth",
    "player.lobby.redmarks": "client UI state; no v2 owner",
    "player.lobby.shop_statuses": "no v2 shop owner for the v1 blob",
    "player.lobby.shops": "no v2 shop owner for the v1 blob",
    "player.lobby.title_info": "v2 projects titles from player_display_selections",
    "player.lobby.vip_awards": "no v2 VIP-award owner",
    "player.world.active_campaign_battle": "in-flight v1 battle; not imported",
    "player.domains.adventure_list": "v2 adventure owner has a different shape",
    "player.domains.arena_info": "v2 arena owner has a different shape",
    "player.domains.arena_mode_info": "v2 arena owner has a different shape",
    "player.domains.arena_records": "v2 arena owner has a different shape",
    "player.domains.auction_by_type": "no v2 auction owner",
    "player.domains.awakening_state": "raw awakening stage is imported per hero; v1 mission slots have no v2 owner shape",
    "player.domains.battle_formation": "no v2 battle-formation owner",
    "player.domains.battle_pass_info": "no v2 battle-pass owner",
    "player.domains.building_list": "v1 town buildings do not map to the v2 book or workplace owners",
    "player.domains.class_info": "no v2 owner",
    "player.domains.commerce_state": "qualifying charge is imported; product counters have no v2 owner",
    "player.domains.daily_consume_state": "v2 daily consumption is event-driven; v1 counts are empty",
    "player.domains.daily_reset_state": "v2 recomputes the game day on read",
    "player.domains.gift_box_info": "no v2 owner",
    "player.domains.hero_recommend_scores": "no v2 owner",
    "player.domains.horcrux_state": "spirit instances/programs imported; embedded trial and collocation counters have no v2 owner shape",
    "player.domains.hunqi_start_info": "no v2 owner",
    "player.domains.invite_infos": "social owner has a different shape",
    "player.domains.march_info": "v2 march owner payload has a different shape",
    "player.domains.occult_state": "v2 occult owner payload has a different shape",
    "player.domains.offline_info": "no v2 owner",
    "player.domains.peak_records": "v2 peak arena owner has a different shape",
    "player.domains.persistence_state": "v1 persistence receipts/migrations; not imported",
    "player.domains.practice_info": "practice owner has its own shape; v1 blob is empty",
    "player.domains.study_infos": "no v2 owner",
    "player.domains.tea_talk_info": "guild tea owner has a different shape",
    "player.domains.trial_infos": "v2 trial owner has a different shape",
    "player.domains.white_album_state": "v2 library special claims are already seeded; v1 blob is empty",
    "player.domains.workshop_state": "v1 book/cabinet facts do not map to the v2 workplace owner",
    "player.domains.world_boss": "world-boss owner has a different shape",
}
HERO_NOT_IMPORTED_REASONS = {
    "skill_book_info": "v2 book owner has no per-hero skill fact",
    "fumo_levels": "v2 derives fumo levels from raw fumo and content",
    "spirit_item": "v2 derives spirit item wires from imported spirit instances",
    "house_id": "v2 dorm room ownership has a different shape; dorm facet is seeded",
    "house_table_id": "v2 dorm room ownership has a different shape; dorm facet is seeded",
    "house_comfort": "v2 dorm comfort is derived from room furniture",
    "house_equips": "v2 dorm room ownership has a different shape",
    "house_expand_lev": "v2 dorm room ownership has a different shape",
    "is_board": "no v2 board owner",
    "board_card": "no v2 board owner",
    "board_model_id": "no v2 board owner",
    "unlocked_dynamic_card": "v2 projects LIVE card models from entitlements; v1 string has no owner",
    "dynamic_card_state": "v2 projects LIVE card models from entitlements; v1 string has no owner",
    "book_shelf_lev": "v2 book owner has no per-hero shelf level",
    "conquer_lev": "v2 conquest belongs to player_conquer_facts, not a hero",
    "conquer_loop_id": "v2 conquest belongs to player_conquer_facts, not a hero",
    "region_arena_times": "no v2 owner",
    "buffs": "no v2 per-hero buff owner",
    "force": "v2 computes force from owned state",
    "player_id": "v2 allocates the player id",
}



def fail(message):
    raise SystemExit(f"import_legacy: {message}")


def tool_path(name):
    return str(PLAYTEST_TOOLS / name)


def psql_arguments():
    return [
        tool_path("psql"),
        "-X",
        "-q",
        "-v",
        "ON_ERROR_STOP=1",
        "-h",
        str(PLAYTEST_HOME / "pg"),
        "-p",
        str(POSTGRES_PORT),
        "-U",
        "postgres",
        "-d",
        DATABASE_NAME,
    ]


def run_psql(sql, fetch=False):
    result = subprocess.run(
        psql_arguments() + (["-t", "-A", "-f", "-"] if not fetch else ["-t", "-A", "-c", sql]),
        input=sql if not fetch else None,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        fail(f"psql failed: {result.stderr.strip()[:800]}")
    return result.stdout


def query_text(sql):
    return run_psql(sql, fetch=True).strip()


def quote(value):
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def json_literal(value):
    raw = json.dumps(value, ensure_ascii=False, sort_keys=True)
    return quote(raw) + "::jsonb"


def int_array(values):
    if not values:
        return "'{}'::bigint[]"
    return "ARRAY[" + ",".join(str(int(value)) for value in values) + "]::bigint[]"


def active_revision():
    revision = query_text("SELECT revision_id FROM gxb_content_activation WHERE slot='content'")
    if len(revision) != 64:
        fail("active content revision is missing")
    return revision


def load_accounts():
    try:
        value = json.loads(ACCOUNTS_PATH.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        value = {"version": 1, "accounts": {}, "logins": {}, "devices": {}}
    for key in ("accounts", "logins", "devices"):
        if not isinstance(value.get(key), dict):
            value[key] = {}
    return value


def save_accounts(accounts):
    STATE_DIRECTORY.mkdir(parents=True, exist_ok=True)
    temporary = ACCOUNTS_PATH.with_name(f"{ACCOUNTS_PATH.name}.{os.getpid()}.tmp")
    descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
        json.dump(accounts, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, ACCOUNTS_PATH)
    os.chmod(ACCOUNTS_PATH, 0o600)


def normalize_login(login):
    return str(login or "").strip().casefold()


def password_record(password):
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, PBKDF2_ITERATIONS)
    return {
        "algorithm": PASSWORD_ALGORITHM,
        "iterations": PBKDF2_ITERATIONS,
        "salt": salt.hex(),
        "hash": digest.hex(),
    }


def credential_digest(secret, label, raw):
    digest = hmac.new(secret.encode("utf-8"), digestmod=hashlib.sha256)
    digest.update(b"gxb-v2/credential/v1\x00")
    digest.update(label.encode("utf-8"))
    digest.update(b"\x00")
    digest.update(raw.encode("utf-8"))
    return digest.hexdigest()


def issue_session(account_uid, session_id, sid, token, digest_secret):
    sid_digest = credential_digest(digest_secret, "sid", sid)
    token_digest = credential_digest(digest_secret, "login_token", token)
    statements = [
        "BEGIN;",
        "INSERT INTO accounts(account_id,account_uid,status,created_at)"
        f" VALUES ({quote(account_uid)}::uuid,{quote(account_uid)},'ACTIVE',clock_timestamp())"
        " ON CONFLICT (account_id) DO NOTHING;",
        "INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)"
        f" VALUES ({quote(session_id)}::uuid,{quote(account_uid)}::uuid,"
        f"{quote(AUTH_PROFILE)},clock_timestamp(),clock_timestamp());",
    ]
    for kind, digest in (("SID", sid_digest), ("LOGIN_TOKEN", token_digest)):
        credential_id = str(uuid.uuid4())
        statements.append(
            "INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)"
            f" VALUES ({quote(credential_id)}::uuid,{quote(session_id)}::uuid,"
            f"{quote(kind)},decode({quote(digest)},'hex'),clock_timestamp());"
        )
    statements.append("COMMIT;")
    run_psql("\n".join(statements) + "\n")


def ensure_session(accounts, account):
    if account.get("session"):
        return account["session"]
    secrets_value = json.loads((STATE_DIRECTORY / "secrets.json").read_text(encoding="utf-8"))
    session_id = str(uuid.uuid4())
    sid = "pl-sid-" + uuid.uuid4().hex
    token = "pl-login-" + uuid.uuid4().hex
    issue_session(account["uid"], session_id, sid, token, secrets_value["credential_digest_secret"])
    account["session"] = {"session_id": session_id, "sid": sid, "token": token}
    save_accounts(accounts)
    return account["session"]


def post_front(payload):
    data = urllib.parse.urlencode({"payload": json.dumps(payload)}).encode("utf-8")
    request = urllib.request.Request(
        f"{FRONT_BASE}/engine",
        data=data,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=120) as reply:
        body = reply.read()
        if reply.status != 200:
            fail(f"front answered HTTP {reply.status} for MID {payload.get('mid')}")
        return json.loads(body)


def envelope(session, mid, extra=None):
    payload = {
        "mid": mid,
        "sid": session["sid"],
        "login_token": session["token"],
        "region": REGION,
        "v_": "1.631.0",
        "app_v": "1.631.0",
        "platform": 3,
    }
    payload.update(extra or {})
    return payload


def birth_player(accounts, account):
    session = ensure_session(accounts, account)
    listing = post_front(envelope(session, 18))
    players = listing.get("players") or []
    if not players:
        post_front(envelope(session, 1))
    row = query_text(
        "SELECT player_id FROM players WHERE account_id="
        f"'{account['uid']}'::uuid AND logical_server_id={REGION}"
    )
    if not row:
        fail(f"MID1 did not create a player for login {account.get('login')}")
    return int(row.splitlines()[0]), session


def deep_merge(base, changes):
    out = copy.deepcopy(base)
    for key, value in (changes or {}).items():
        if isinstance(value, dict) and isinstance(out.get(key), dict):
            out[key] = deep_merge(out[key], value)
        else:
            out[key] = copy.deepcopy(value)
    return out


def player_state(save):
    return save.get("player", save)


def content_payload(revision, table):
    raw = query_text(f"SELECT payload::text FROM {table} WHERE revision_id={quote(revision)}")
    if not raw:
        fail(f"content table {table} has no payload for the active revision")
    return json.loads(raw)


def scalar_currencies(player):
    economy = player.get("economy") or {}
    progression = player.get("progression") or {}
    balances = {}
    for key in ITEM_SCALAR_KEYS:
        if key in PROGRESSION_SCALAR_KEYS:
            continue
        value = economy.get(key)
        if isinstance(value, int) and value > 0:
            balances[key] = value
    for key in PROGRESSION_SCALAR_KEYS:
        value = progression.get(key)
        if isinstance(value, int) and value > 0:
            balances[key] = value
    return balances


def temporal_amounts(player):
    economy = player.get("economy") or {}
    progression = player.get("progression") or {}
    amounts = {
        "energy": economy.get("energy"),
        "spirit_energy": economy.get("spirit_energy"),
        "skill_point": progression.get("skill_point"),
    }
    return {key: value for key, value in amounts.items() if isinstance(value, int)}


def content_hero_equipment(revision):
    text = query_text(
        "SELECT COALESCE(jsonb_object_agg(hero_table_id||'/'||color||'/'||slot,item_id),'{}'::jsonb)::text"
        f" FROM gxb_content_hero_equipment WHERE revision_id={quote(revision)}"
    )
    mapping = json.loads(text) if text else {}
    return {tuple(int(part) for part in key.split("/")): int(value) for key, value in mapping.items()}


def content_hero_templates(revision):
    text = query_text(
        "SELECT COALESCE(jsonb_object_agg(table_id,jsonb_build_object('kind',kind,'origin',origin_table_id)),'{}'::jsonb)::text"
        f" FROM gxb_content_hero_templates WHERE revision_id={quote(revision)}"
    )
    return {
        int(key): {"kind": value["kind"], "origin": int(value["origin"])}
        for key, value in json.loads(text).items()
    }


def content_super_positions(revision):
    text = query_text(
        "SELECT COALESCE(jsonb_object_agg(hero_table_id||'/'||slot,item_id),'{}'::jsonb)::text"
        f" FROM gxb_content_super_equipment_positions WHERE revision_id={quote(revision)}"
    )
    return {
        tuple(int(part) for part in key.split("/")): int(value)
        for key, value in json.loads(text).items()
    }


def content_item_caps(revision):
    text = query_text(
        "SELECT COALESCE(jsonb_object_agg(item_id,stack_cap),'{}'::jsonb)::text"
        " FROM gxb_content_resource_definitions WHERE item_id IS NOT NULL AND stack_cap IS NOT NULL"
        f" AND revision_id={quote(revision)}"
    )
    return {int(key): int(value) for key, value in json.loads(text).items()}


def content_campaign_nodes(revision):
    payload = content_payload(revision, "content_campaign_catalogs")
    return {
        int(node["id"]): node
        for node in payload.get("nodes", [])
        if isinstance(node, dict) and "id" in node
    }


def content_privilege_thresholds(revision):
    payload = content_payload(revision, "content_privilege_catalogs")
    return sorted(
        (int(row["level"]), int(row["charge"])) for row in payload.get("rows", [])
    )


def derive_vip(thresholds, charge):
    level = 0
    for row_level, row_charge in thresholds:
        if charge < row_charge:
            break
        level = row_level
    return level


def content_spirit_catalog(revision):
    payload = content_payload(revision, "content_spirit_input_catalogs")
    tables = payload["tables"]
    models = {}
    for row in tables["models"]:
        models[int(row["id"])] = {
            "main": split_ints(row.get("main")),
            "main_base": split_numbers(row.get("main_value")),
            "main_step": split_numbers(row.get("main_strth")),
            "sub": split_ints(row.get("sub")),
            "sub_base": split_numbers(row.get("sub_value")),
            "sub_step": split_numbers(row.get("sub_strth")),
            "rates": split_ints(row.get("sub_num_rate")),
            "sub_num": int(row["sub_num"]),
            "star": int(row["star"]),
            "position": int(row["pos"]),
        }
    templates = {int(row["item_id"]): int(row["model_id"]) for row in tables["equipment"]}
    strength = {}
    for row in tables["strengthen"]:
        strength.setdefault(int(row["star"]), {})[int(row["lv"])] = int(row["exp"])
    return {"models": models, "templates": templates, "strength": strength}


def split_ints(raw):
    return [int(value) for value in (raw or "").split("|") if value != ""]


def split_numbers(raw):
    return [float(value) for value in (raw or "").split("|") if value != ""]


def spirit_level(catalog, star, experience):
    thresholds = catalog["strength"].get(star)
    if not thresholds:
        return None
    total = 0
    level = 0
    for ordinal in range(1, 16):
        total += thresholds[ordinal]
        if experience >= total:
            level = ordinal
    if experience > total:
        return None
    return level


def spirit_instance(catalog, raw, refused):
    template_id = int(raw["table_id"])
    model_id = catalog["templates"].get(template_id)
    model = catalog["models"].get(model_id)
    if model is None:
        refused.append({"kind": "spirit", "id": template_id, "reason": "no active spirit model"})
        return None
    star = int(raw["star"])
    level = int(raw["lev"])
    experience = int(raw["exp"])
    main = int(raw["main"])
    subs = [int(value) for value in raw.get("sub") or []]
    values = [float(value) for value in raw.get("sub_attr_value") or []]
    if star != model["star"] or not 1 <= main <= len(model["main"]) or len(subs) != len(values):
        refused.append({"kind": "spirit", "id": template_id, "reason": "shape mismatch"})
        return None
    if spirit_level(catalog, star, experience) != level:
        refused.append({"kind": "spirit", "id": template_id, "reason": "level does not match experience"})
        return None
    expected_main = model["main_base"][main - 1] + model["main_step"][main - 1] * level
    if abs(expected_main - float(raw["main_attr_value"])) > 1e-6:
        refused.append({"kind": "spirit", "id": template_id, "reason": "main value mismatch"})
        return None
    improvements = 0
    for selection, value in zip(subs, values):
        if not 1 <= selection <= len(model["sub"]):
            refused.append({"kind": "spirit", "id": template_id, "reason": "sub selection out of range"})
            return None
        base = model["sub_base"][selection - 1]
        step = model["sub_step"][selection - 1]
        difference = value - base
        if step == 0:
            if difference != 0:
                refused.append({"kind": "spirit", "id": template_id, "reason": "sub value above base"})
                return None
            continue
        increments = difference / step
        if increments < 0 or abs(increments - round(increments)) > 1e-9:
            refused.append({"kind": "spirit", "id": template_id, "reason": "sub value off the step grid"})
            return None
        improvements += int(round(increments))
    born_count = improvements + len(subs) - level // 3
    if born_count < 0 or born_count >= len(model["rates"]) or model["rates"][born_count] <= 0:
        refused.append({"kind": "spirit", "id": template_id, "reason": "birth sub count unqualified"})
        return None
    return {
        "spirit_id": int(raw["spirit_id"]),
        "table_id": template_id,
        "star": star,
        "lev": level,
        "exp": experience,
        "main": main,
        "main_attr_value": raw["main_attr_value"],
        "sub": subs,
        "sub_attr_value": raw.get("sub_attr_value") or [],
        "birth_sub": subs[:born_count],
        "locked": bool(raw.get("is_lock")),
        "policy": SPIRIT_INSTANCE_POLICY,
    }


def content_course_rules(revision):
    payload = content_payload(revision, "content_course_input_catalogs")
    return {
        "books": {int(row["id"]) for row in payload["tables"]["book"]},
        "thresholds": [int(value) for value in payload["Thresholds"]],
        "slots": [bool(value) for value in payload["Slots"]],
        "max_exp": int(payload["MaxEXP"]),
    }


def content_element_items(revision):
    payload = content_payload(revision, "content_element_input_catalogs")
    return {
        int(row["id"]): {"type": int(row["equip_type"]), "partner": int(row["partner_id"])}
        for row in payload["tables"]["equipment"]
    }


def course_quality(thresholds, experience):
    quality = 1
    for index, threshold in enumerate(thresholds):
        if experience >= threshold:
            quality = index + 1
    return quality


def course_records(raw, rules, refused):
    records = []
    seen_slots = set()
    course_ids = list(raw.get("courses") or [])
    progresses = list(raw.get("courses_progress") or [])
    skills = list(raw.get("courses_skill") or [])
    qualities = list(raw.get("courses_quality") or [])
    experiences = list(raw.get("courses_exp") or [])
    for index, course_id in enumerate(course_ids):
        course_id = int(course_id)
        progress = int(progresses[index]) if index < len(progresses) else 0
        skill = int(skills[index]) if index < len(skills) else 0
        quality = int(qualities[index]) if index < len(qualities) else 1
        experience = int(experiences[index]) if index < len(experiences) else 0
        if course_id not in rules["books"]:
            refused.append({"kind": "course", "id": course_id, "reason": "no active course book"})
            continue
        if not 0 <= progress <= 100 or not 0 <= experience <= rules["max_exp"] or quality != course_quality(rules["thresholds"], experience):
            refused.append({"kind": "course", "id": course_id, "reason": "v1 progress, exp or quality does not satisfy the v2 course catalog"})
            continue
        if skill < 0 or skill > 6 or (skill > 0 and (not rules["slots"][skill - 1] or progress != 100 or skill in seen_slots)) or (progress < 100 and experience != 0):
            refused.append({"kind": "course", "id": course_id, "reason": "v1 course skill slot is not qualified"})
            continue
        if skill > 0:
            seen_slots.add(skill)
        records.append({"id": course_id, "progress": progress, "quality": quality, "add_skill": skill, "exp": experience})
    return records


def element_facts(raw, items, origin, refused):
    slots = list(raw.get("element_equips") or [])
    levels = list(raw.get("element_levels") or [])
    backup_ids = list(raw.get("element_bak_equips") or [])
    backup_levels = list(raw.get("element_bak_levels") or [])
    valid = len(slots) <= 4 and len(levels) <= 4
    seen = set()
    for index in range(4):
        identifier = int(slots[index]) if index < len(slots) else 0
        level = int(levels[index]) if index < len(levels) else 0
        if identifier == 0:
            valid = valid and level == 0
            continue
        item = items.get(identifier)
        if item is None:
            valid = False
            continue
        valid = valid and 0 <= level <= 10 and identifier not in seen
        valid = valid and not (index == 0 and item["type"] == 1) and not (index > 0 and item["type"] != 1)
        valid = valid and not (item["partner"] > 0 and item["partner"] != origin)
        seen.add(identifier)
    backup = {}
    for index, identifier in enumerate(backup_ids):
        identifier = int(identifier)
        level = int(backup_levels[index]) if index < len(backup_levels) else 0
        item = items.get(identifier)
        if item is None:
            valid = False
            continue
        valid = valid and 0 <= level <= 10 and identifier not in seen
        valid = valid and not (item["partner"] > 0 and item["partner"] != origin)
        seen.add(identifier)
        backup[str(identifier)] = level
    if not valid:
        refused.append({"kind": "element", "id": raw.get("partner_id"), "reason": "v1 element equipment is not qualified by the active element catalog", "values": {"slots": slots, "levels": levels, "bak_equips": backup_ids, "bak_levels": backup_levels}})
        return [0, 0, 0, 0], [0, 0, 0, 0], {}
    padded_slots = [int(slots[index]) if index < len(slots) else 0 for index in range(4)]
    padded_levels = [int(levels[index]) if index < len(levels) else 0 for index in range(4)]
    return padded_slots, padded_levels, backup


def clamp(value, low, high):
    return max(low, min(high, value))


def build_hero_rows(player, revision, refused):
    heroes = (player.get("heroes") or {}).get("heroes") or {}
    equipment = content_hero_equipment(revision)
    super_positions = content_super_positions(revision)
    kinds = content_hero_templates(revision)
    course_rules = content_course_rules(revision)
    element_items = content_element_items(revision)
    rows = []
    seen_partners = set()
    for key, raw in sorted(heroes.items(), key=lambda item: int(item[1].get("partner_id", item[0]))):
        partner = int(raw.get("partner_id", key))
        table_id = int(raw.get("table_id", 0))
        if partner <= 0 or table_id <= 0 or partner in seen_partners:
            refused.append({"kind": "hero", "id": table_id, "reason": "invalid or duplicate partner id"})
            continue
        seen_partners.add(partner)
        template = kinds.get(table_id)
        if template is None:
            refused.append({"kind": "hero", "id": table_id, "reason": "no active hero template"})
            continue
        kind = template["kind"]
        origin_table_id = template["origin"]
        star = int(raw.get("star", 1))
        level = int(raw.get("lev", 1))
        color = int(raw.get("color", 1))
        if star < 1 or star > MAX_HERO_STAR or level < 1 or color < 1 or color > MAX_HERO_COLOR:
            refused.append({"kind": "hero", "id": table_id, "reason": "star, level or color outside v2 bounds"})
            continue
        flags = list(raw.get("equips") or [0] * 6) + [0] * 6
        slots = [0] * 6
        for index in range(6):
            flag = int(flags[index])
            if flag == 0:
                continue
            if kind == "SUPER":
                slots[index] = flag
                if (table_id, index + 1) not in super_positions:
                    refused.append({"kind": "hero-equipment", "id": table_id, "reason": f"super slot {index + 1} lacks content"})
            else:
                if (table_id, color, index + 1) not in equipment:
                    refused.append({"kind": "hero-equipment", "id": table_id, "reason": f"normal slot {index + 1} color {color} lacks content"})
                    continue
                slots[index] = 1
        fumo = list(raw.get("fumos") or [0] * 6)[:6]
        fumo += [0] * (6 - len(fumo))
        practice = list(raw.get("practice_attr") or [0, 0, 0])[:3]
        practice += [0] * (3 - len(practice))
        skills = list(raw.get("skills") or [1] * 6)[:6]
        skills += [1] * (6 - len(skills))
        skill_ids = list(raw.get("skill_ids") or [0] * 6)[:6]
        skill_ids += [0] * (6 - len(skill_ids))
        courses = course_records(raw, course_rules, refused)
        element_slots, element_levels, element_backup = element_facts(raw, element_items, origin_table_id, refused)
        rows.append(
            {
                "partner_id": partner,
                "table_id": table_id,
                "origin_table_id": origin_table_id,
                "kind": kind,
                "star": star,
                "level": level,
                "exp": max(0, int(raw.get("exp", 0))),
                "color": color,
                "equipment": slots,
                "fumo": fumo,
                "practice": practice,
                "skills": skills,
                "skill_ids": skill_ids,
                "current_skin_id": max(0, int(raw.get("current_skin_id", 0))),
                "illusion_skin_id": int(raw.get("illusion_skin_id", -1)) if int(raw.get("illusion_skin_id", 0)) > 0 else -1,
                "is_like": int(raw.get("is_like", 0)),
                "skin_ids": [int(value) for value in raw.get("skin_ids") or []],
                "feed_attrs": raw.get("feed_attrs") or {},
                "favor_degree": int(raw.get("favor_degree", 0)),
                "is_married": int(raw.get("is_married", 0)),
                "collect_quality_stage": int(raw.get("collect_quality_stage", 0)),
                "collect_star_stage": int(raw.get("collect_star_stage", 0)),
                "evo_stage": int(raw.get("evo_stage", 1)),
                "evo_points": raw.get("evo_attr_points") or {},
                "raw_awakening_stage": int(raw.get("twice_awake_stage", 0)),
                "element_slots": element_slots,
                "element_levels": element_levels,
                "element_backup": element_backup,
                "spirit_equip": list(raw.get("spirit_equip") or [0] * 6)[:6],
                "inscript_items": raw.get("inscript_items") or {},
                "courses": courses,
                "house": {
                    "house_id": int(raw.get("house_id", 0)),
                    "house_table_id": int(raw.get("house_table_id", 0)),
                    "house_comfort": int(raw.get("house_comfort", 0)),
                    "house_equips": raw.get("house_equips") or {},
                    "house_expand_lev": int(raw.get("house_expand_lev", 0)),
                },
                "skill_book_info": raw.get("skill_book_info") or {},
                "is_board": int(raw.get("is_board", 0)),
                "board_card": int(raw.get("board_card", 1)),
                "board_model_id": int(raw.get("board_model_id", 0)),
                "unlocked_dynamic_card": raw.get("unlocked_dynamic_card") or "",
                "dynamic_card_state": raw.get("dynamic_card_state") or "",
                "book_shelf_lev": int(raw.get("book_shelf_lev", 0)),
                "conquer_lev": int(raw.get("conquer_lev", 0)),
                "conquer_loop_id": int(raw.get("conquer_loop_id", 1)),
                "region_arena_times": int(raw.get("region_arena_times", 0)),
                "buffs": raw.get("buffs") or {},
            }
        )
    return rows


def feed_axis_values(feed_attrs):
    values = [0] * 6
    for key, value in (feed_attrs or {}).items():
        try:
            index = int(key) - 1
        except (TypeError, ValueError):
            return None
        if index < 0 or index >= 6 or not isinstance(value, int):
            return None
        values[index] = value
    return values


def build_campaign_rows(player, revision, refused):
    world = (player.get("world") or {}).get("world_map") or {}
    catalog = content_campaign_nodes(revision)
    day = game_day(int(time.time()))
    nodes = []
    for kind in ("normal", "super", "challenge"):
        for raw in world.get(kind) or []:
            campaign_id = int(raw.get("campaign_id", 0))
            node = catalog.get(campaign_id)
            if node is None:
                refused.append({"kind": "campaign", "id": campaign_id, "reason": "no active campaign node"})
                continue
            star = clamp(int(raw.get("star", 0)), 0, 3)
            resets = int(raw.get("reset_count", 0))
            used = 0
            if kind == "super":
                limit = int(node.get("daily_limit", 0))
                remaining = int(raw.get("daily_limit", 0))
                if remaining > limit:
                    refused.append({"kind": "campaign-limit", "id": campaign_id, "reason": f"remaining {remaining} above content limit {limit}"})
                used = max(0, limit - remaining)
            nodes.append(
                {
                    "campaign_id": campaign_id,
                    "star": star,
                    "win_day": day,
                    "wins": used,
                    "reset_day": day,
                    "resets": max(0, resets),
                    "partner_drop": bool(int(raw.get("is_partner_drop", 0))),
                }
            )
    chapter = world.get("chapter_info") or {}
    return nodes, chapter


def game_day(timestamp):
    return (timestamp + 8 * 3600 - 5 * 3600) // 86400


def build_statements(player, revision, player_id, report):
    rows = report["rows_written"]
    now = "now()"
    statements = ["BEGIN;", "SET LOCAL lock_timeout='5s';", "SET LOCAL statement_timeout='120s';"]

    def write(table, sql):
        statements.append(sql)
        rows[table] = rows.get(table, 0) + 1

    identity = player.get("identity") or {}
    progression = player.get("progression") or {}
    display_name = report["display_name"]
    avatar_id = int(identity.get("avatar_id") or 110001001)
    avatar_frame_id = int(identity.get("avatar_frame_id") or 0)
    player_type = int(identity.get("player_type") or 0)
    lev = max(1, int(progression.get("lev", 1)))
    exp = max(0, int(progression.get("exp", 0)))
    vip = int(progression.get("vip", 0))
    conquer_lev = int(progression.get("conquer_lev", 0))
    conquer_loop_id = max(1, int(progression.get("conquer_loop_id", 1)))

    write("player_profiles", f"UPDATE player_profiles SET display_name={quote(display_name)},avatar_id={avatar_id},avatar_frame_id={avatar_frame_id},player_type={player_type},state_version=state_version+1,updated_at={now} WHERE player_id={player_id};")
    write("player_directory_profiles", f"UPDATE player_directory_profiles SET name={quote(display_name)},lev={lev},vip={vip},avatar_id={avatar_id},avatar_frame_id={avatar_frame_id},conquer_lev={conquer_lev},conquer_loop_id={conquer_loop_id},state_version=state_version+1,updated_at={now} WHERE player_id={player_id};")
    write("players", f"UPDATE players SET first_entry_pending=false,state_version=state_version+1 WHERE player_id={player_id};")
    write("player_progression", f"UPDATE player_progression SET level={lev},exp={exp},state_version=state_version+1,updated_at={now} WHERE player_id={player_id};")
    write("player_story_cursors", f"UPDATE player_story_cursors SET story_id={max(0,int(progression.get('story_id',0)))},story_state={max(0,int(progression.get('story_state',0)))},guide_id={max(0,int(progression.get('guide_id',0)))},state_version=state_version+1,updated_at={now} WHERE player_id={player_id};")
    guide_ids = player.get("progression", {}).get("guide_function_ids") or {}
    write("player_guide_return_state", f"UPDATE player_guide_return_state SET guide_return_id={int(progression.get('guide_return_id',0))},guide_function_ids={int_array([int(key) for key in guide_ids])},state_version=state_version+1,updated_at={now} WHERE player_id={player_id};")

    function_ids = sorted({int(value) for value in progression.get("func_ids") or [] if int(value) > 0})
    statements.append(f"DELETE FROM player_function_unlocks WHERE player_id={player_id};")
    statements.append(f"DELETE FROM player_function_eligibility WHERE player_id={player_id};")
    for function_id in function_ids:
        fact_key = f"legacy-import:v1:{player_id}:{function_id}"
        write("player_function_unlocks", f"INSERT INTO player_function_unlocks(player_id,function_id,opened_at,source_fact_key,state_version) VALUES({player_id},{function_id},{now},{quote(fact_key)},1);")
        write("player_function_eligibility", f"INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at) VALUES({player_id},{function_id},{quote(revision)},{quote(fact_key)},{now});")
    write("player_function_state_owners", f"UPDATE player_function_state_owners SET state_version={1 + len(function_ids)},updated_at={now} WHERE player_id={player_id};")

    charge = int((player.get("economy") or {}).get("charge", 0) or 0)
    thresholds = content_privilege_thresholds(revision)
    derived_vip = derive_vip(thresholds, charge)
    if derived_vip != vip:
        report["notes"].append(f"v1 vip {vip} does not match charge {charge} (content level {derived_vip}); stored content level")
        vip = derived_vip
        statements.append(f"UPDATE player_directory_profiles SET vip={vip} WHERE player_id={player_id};")
    statements.append(f"DELETE FROM commerce_privilege_roots WHERE player_id={player_id};")
    write("commerce_privilege_roots", f"INSERT INTO commerce_privilege_roots(player_id,logical_server_id,qualifying_charge,vip_level,monthly_state,content_revision,policy_version,origin_class,issuer,reason,state_version,created_at,updated_at) VALUES({player_id},{REGION},{charge},{vip},{quote(PRIVILEGE_MONTHLY_ABSENT)},{quote(revision)},{quote(PRIVILEGE_POLICY)},{quote(PRIVILEGE_CLASS)},{quote(PRIVILEGE_ISSUER)},{quote(PRIVILEGE_REASON)},1,{now},{now});")

    statements.append(f"DELETE FROM player_currency_balances WHERE player_id={player_id};")
    for key, amount in sorted(scalar_currencies(player).items()):
        write("player_currency_balances", f"INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at) VALUES({player_id},{quote(key)},{amount},1,{now});")

    for key, amount in sorted(temporal_amounts(player).items()):
        write("player_temporal_resources", f"UPDATE player_temporal_resources SET stored_amount={amount},regen_anchor_at={now},policy_version={quote(revision)},content_revision={quote(revision)},state_version=state_version+1,updated_at={now} WHERE player_id={player_id} AND resource_key={quote(key)};")

    caps = content_item_caps(revision)
    statements.append(f"DELETE FROM player_item_stacks WHERE player_id={player_id};")
    for raw in (player.get("inventory") or {}).get("backpack_items") or []:
        item_id = int(raw.get("table_id", 0))
        quantity = int(raw.get("item_num", 0))
        if item_id <= 0 or quantity <= 0:
            continue
        if item_id not in caps:
            report["content_refused"].append({"kind": "item", "id": item_id, "reason": "no active stack item definition"})
            continue
        if quantity > caps[item_id]:
            report["clamps"].append({"path": f"player.inventory.backpack_items.{item_id}", "from": quantity, "to": caps[item_id]})
            quantity = caps[item_id]
        write("player_item_stacks", f"INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at) VALUES({player_id},{item_id},{quantity},1,{now},{now});")

    heroes = build_hero_rows(player, revision, report["content_refused"])
    for table in (
        "player_heroes",
        "player_hero_skin_entitlements",
        "player_hero_live_entitlements",
        "player_library_heroes",
        "player_dorm_heroes",
        "player_course_heroes",
        "player_inscription_heroes",
        "player_element_heroes",
        "player_spirit_heroes",
        "player_hero_evolution",
        "player_hero_raw_awakening",
    ):
        statements.append(f"DELETE FROM {table} WHERE player_id={player_id};")
    heroes_data = (player.get("heroes") or {})
    max_partner = max([row["partner_id"] for row in heroes] + [0])
    next_partner = max(int(heroes_data.get("hero_next_partner_id", max_partner + 1)), max_partner + 1)
    sort_type = int(heroes_data.get("hero_sort_type", 0))
    write("player_hero_roots", f"UPDATE player_hero_roots SET next_partner_id={next_partner},sort_type={sort_type},state_version=state_version+1,updated_at={now} WHERE player_id={player_id};")

    for row in heroes:
        write("player_heroes", "INSERT INTO player_heroes("
            "player_id,partner_id,table_id,origin_table_id,star,level,exp,color,equip_1,equip_2,equip_3,equip_4,equip_5,equip_6,"
            "fumo_1,fumo_2,fumo_3,fumo_4,fumo_5,fumo_6,practice_str,practice_int,practice_agi,current_skin_id,illusion_skin_id,is_like,"
            "raw_skill_1,raw_skill_2,raw_skill_3,raw_skill_4,raw_skill_5,raw_skill_6,"
            "raw_skill_id_1,raw_skill_id_2,raw_skill_id_3,raw_skill_id_4,raw_skill_id_5,raw_skill_id_6,"
            "creation_content_revision,state_version,created_at,updated_at,skill_seed_policy_id) VALUES("
            + ",".join([str(player_id), str(row["partner_id"]), str(row["table_id"]), str(row["origin_table_id"]), str(row["star"]), str(row["level"]), str(row["exp"]), str(row["color"])]
                       + [str(value) for value in row["equipment"]]
                       + [str(value) for value in row["fumo"]]
                       + [str(value) for value in row["practice"]]
                       + [str(row["current_skin_id"]), str(row["illusion_skin_id"]), str(row["is_like"])]
                       + [str(value) for value in row["skills"]]
                       + [str(value) for value in row["skill_ids"]]
                       + [quote(revision), "1", now, now, quote(RAW_SKILL_SEED_POLICY)])
            + ");")
        feed = feed_axis_values(row["feed_attrs"])
        if feed is None:
            report["content_refused"].append({"kind": "library-feed", "id": row["partner_id"], "reason": "feed_attrs keys are not six axes"})
            feed = [0, 0, 0, 0, 0, 0]
        write("player_library_heroes", f"INSERT INTO player_library_heroes(player_id,partner_id,state_version,favor_degree,is_married,feed_attrs,collect_quality_stage,collect_star_stage,seed_policy_id,created_at,updated_at) VALUES({player_id},{row['partner_id']},1,{row['favor_degree']},{'TRUE' if row['is_married'] else 'FALSE'},{json_literal(feed)},{row['collect_quality_stage']},{row['collect_star_stage']},{quote(LIBRARY_SEED_POLICY)},{now},{now});")
        write("player_hero_evolution", f"INSERT INTO player_hero_evolution(player_id,partner_id,state_version,policy_id,facts,created_at,updated_at) VALUES({player_id},{row['partner_id']},1,{quote(EVOLUTION_POLICY)},{json_literal({'evo_stage': row['evo_stage'], 'evo_attr_points': row['evo_points']})},{now},{now});")
        stage = row["raw_awakening_stage"]
        raw_version = 1 if stage == 0 else 2
        producer = "" if stage == 0 else f"I9_AWAKENING_MISSIONS_V1/legacy-import/{row['partner_id']}"
        write("player_hero_raw_awakening", f"INSERT INTO player_hero_raw_awakening(player_id,partner_id,state_version,raw_stage,birth_policy,creation_content_revision,birth_at,created_at,updated_at,producer_reference) VALUES({player_id},{row['partner_id']},{raw_version},{stage},{quote(RAW_AWAKENING_POLICY)},{quote(revision)},{now},{now},{now},{quote(producer)});")
        for model_id in sorted(set(row["skin_ids"] + ([row["current_skin_id"]] if row["current_skin_id"] else []) + ([row["illusion_skin_id"]] if row["illusion_skin_id"] > 0 else []))):
            write("player_hero_skin_entitlements", f"INSERT INTO player_hero_skin_entitlements(player_id,partner_id,model_id,expires_at) VALUES({player_id},{row['partner_id']},{model_id},NULL) ON CONFLICT (player_id,partner_id,model_id) DO NOTHING;")
        write("player_dorm_heroes", f"INSERT INTO player_dorm_heroes(player_id,partner_id,house_id,state_version,equipment,lounge_anchor,lounge_fraction,created_at,updated_at) VALUES({player_id},{row['partner_id']},NULL,1,'[0,0,0,0,0]'::jsonb,NULL,0,{now},{now});")
        write("player_course_heroes", f"INSERT INTO player_course_heroes(player_id,partner_id,state_version,facts,created_at,updated_at) VALUES({player_id},{row['partner_id']},1,{json_literal({'courses': row['courses']})},{now},{now});")
        slots = list(row["inscript_items"].values()) if isinstance(row["inscript_items"], dict) else list(row["inscript_items"])
        slot_values = [0, 0, 0]
        if any(int(value) for value in slots):
            report["content_refused"].append({"kind": "inscription", "id": row["partner_id"], "reason": "v1 inscription slots have no verified position mapping; seeded empty", "values": slots})
            slots = []
        for index, value in enumerate(slots[:3]):
            slot_values[index] = int(value)
        write("player_inscription_heroes", f"INSERT INTO player_inscription_heroes(player_id,partner_id,state_version,facts,created_at,updated_at) VALUES({player_id},{row['partner_id']},1,{json_literal({'Slots': slot_values})},{now},{now});")
        write("player_element_heroes", f"INSERT INTO player_element_heroes(player_id,partner_id,state_version,facts,created_at,updated_at) VALUES({player_id},{row['partner_id']},1,{json_literal({'slots': row['element_slots'], 'levels': row['element_levels'], 'backup': row['element_backup'], 'policy': ELEMENT_POLICY})},{now},{now});")

    spirit = import_spirit(player, revision, player_id, write, report)
    for row in heroes:
        slots = [0] * 6
        for index, spirit_id in enumerate(row["spirit_equip"][:6]):
            if int(spirit_id) in spirit["instance_ids"]:
                slots[index] = int(spirit_id)
            elif int(spirit_id) != 0:
                report["content_refused"].append({"kind": "spirit-slot", "id": spirit_id, "reason": "spirit not imported"})
        write("player_spirit_heroes", f"INSERT INTO player_spirit_heroes(player_id,partner_id,state_version,facts,created_at,updated_at) VALUES({player_id},{row['partner_id']},1,{json_literal({'slots': slots, 'policy': SPIRIT_POLICY})},{now},{now});")

    nodes, chapter = build_campaign_rows(player, revision, report["content_refused"])
    statements.append(f"DELETE FROM campaign_nodes WHERE player_id={player_id};")
    statements.append(f"DELETE FROM campaign_players WHERE player_id={player_id};")
    write("campaign_players", f"INSERT INTO campaign_players(player_id,normal_bonus_id,super_bonus_id,pending_generation,last_generation,state_version,updated_at) VALUES({player_id},{int(chapter.get('normal_bonus_id',0) or 0)},{int(chapter.get('super_bonus_id',0) or 0)},'', '',1,{now});")
    for node in nodes:
        write("campaign_nodes", f"INSERT INTO campaign_nodes(player_id,campaign_id,star,win_day,wins,reset_day,resets,partner_drop,clear_count_floor,clear_count_exact,first_clear_day) VALUES({player_id},{node['campaign_id']},{node['star']},{node['win_day']},{node['wins']},{node['reset_day']},{node['resets']},{'TRUE' if node['partner_drop'] else 'FALSE'},{node['wins']},true,NULL);")

    summon = import_summon(player, player_id, statements, write, now)
    if summon is not None:
        report["notes"].append("summon rotation ids are derived by content from the game day, not imported")

    statements.append("COMMIT;")
    return statements


def summarize(value):
    if isinstance(value, dict):
        return {"type": "object", "keys": len(value), "empty": not value}
    if isinstance(value, list):
        return {"type": "array", "size": len(value), "empty": not value}
    return value


def report_unmapped(player, save, report):
    for path, reason in sorted(NOT_IMPORTED_REASONS.items()):
        value = save.get("_meta") if path == "_meta" else player
        if path != "_meta":
            for part in path.split(".")[1:]:
                value = value.get(part) if isinstance(value, dict) else None
        report["not_imported"].append({"path": path, "value": summarize(value), "reason": reason})
    heroes = (player.get("heroes") or {}).get("heroes") or {}
    for field, reason in sorted(HERO_NOT_IMPORTED_REASONS.items()):
        present = [
            int(raw.get("partner_id", key))
            for key, raw in heroes.items()
            if raw.get(field) not in (None, 0, "", [], {}, [0, 0, 0], [0] * 6)
            and not (field in ("board_card", "conquer_loop_id") and raw.get(field) == 1)
        ]
        if present:
            report["not_imported"].append(
                {"path": f"player.heroes.heroes[].{field}", "value": {"heroes": len(present)}, "reason": reason}
            )


def import_spirit(player, revision, player_id, write, report):
    spirit_list = (player.get("inventory") or {}).get("spirit_list") or []
    catalog = content_spirit_catalog(revision)
    instances = []
    for raw in spirit_list:
        instance = spirit_instance(catalog, raw, report["content_refused"])
        if instance is not None:
            instances.append(instance)
    instance_ids = {instance["spirit_id"] for instance in instances}
    positions = {}
    for instance in instances:
        model_id = catalog["templates"].get(instance["table_id"])
        model = catalog["models"].get(model_id)
        if model is not None:
            positions[instance["spirit_id"]] = model["position"]
    root = (player.get("domains") or {}).get("horcrux_state") or {}
    programs = {}
    seen_names = set()
    for key, raw in (root.get("collocations") or {}).items():
        slots = [int(value) for value in raw.get("spirit_ids") or []][:6]
        slots += [0] * (6 - len(slots))
        name = str(raw.get("name") or "Plan")
        qualified = 1 <= len(name) <= 10 and name.strip() != "" and name not in seen_names
        seen = set()
        for index, spirit_id in enumerate(slots):
            if spirit_id == 0:
                continue
            qualified = qualified and spirit_id in positions and positions[spirit_id] == index + 1 and spirit_id not in seen
            seen.add(spirit_id)
        if not qualified:
            report["content_refused"].append({"kind": "spirit-program", "id": int(raw.get("id", key)), "reason": "v1 collocation does not satisfy v2 program slots or name"})
            continue
        seen_names.add(name)
        programs[int(raw.get("id", key))] = {"id": int(raw.get("id", key)), "name": name, "slots": slots}
    next_id = max([instance["spirit_id"] for instance in instances] + [1]) + 1
    facts = {
        "policy": SPIRIT_POLICY,
        "next_id": max(int(root.get("next_spirit_id", next_id)), next_id),
        "next_program_id": max([program["id"] for program in programs.values()] + [1]) + 1,
        "instances": {str(instance["spirit_id"]): instance for instance in instances},
        "programs": {str(identifier): program for identifier, program in programs.items()},
    }
    write("player_spirit_roots", f"UPDATE player_spirit_roots SET state_version=2,creation_revision={quote(revision)},facts={json_literal(facts)},updated_at=now() WHERE player_id={player_id};")
    return {"instance_ids": instance_ids}


def import_summon(player, player_id, statements, write, now):
    summon = (player.get("lobby") or {}).get("summon")
    if not isinstance(summon, dict):
        return None
    state = {
        "mana_free_time": int(summon.get("mana_free_time", 0) or 0),
        "crystal_free_time": int(summon.get("crystal_free_time", 0) or 0),
        "mana_free_num": int(summon.get("mana_free_num", 0) or 0),
        "mana_free_day": game_day(int(time.time())),
        "featured_target": 0,
        "featured_pity": 0,
        "sx_target": 0,
        "sx_pity": 0,
        "magic_target": 0,
        "counters": {},
    }
    statements.append(f"DELETE FROM summon_players WHERE player_id={player_id};")
    write("summon_players", f"INSERT INTO summon_players(player_id,mana_free_time,mana_free_num,mana_free_day,crystal_free_time,counters,featured_target,featured_pity,sx_target,sx_pity,magic_target,state_version,updated_at) VALUES({player_id},{state['mana_free_time']},{state['mana_free_num']},{state['mana_free_day']},{state['crystal_free_time']},{json_literal(state['counters'])},{state['featured_target']},{state['featured_pity']},{state['sx_target']},{state['sx_pity']},{state['magic_target']},1,{now});")
    return state


def import_player(save, login, display_name, overrides):
    player = deep_merge(player_state(save), overrides)
    report = {
        "login": login,
        "display_name": display_name,
        "player_id": None,
        "rows_written": {},
        "not_imported": [],
        "content_refused": [],
        "clamps": [],
        "notes": [
            "not_imported lists every unmapped second-level field; per-hero unmapped fields are listed when the save carries a non-default value",
        ],
    }
    accounts = load_accounts()
    normalized = normalize_login(login)
    uid = accounts["logins"].get(normalized)
    account = accounts["accounts"].get(uid) if uid else None
    if account is None:
        uid = str(uuid.uuid4())
        account = {
            "uid": uid,
            "login": login,
            "username": login,
            "account_type": "normal",
            "created_at": int(time.time()),
            "password": None,
            "session": None,
        }
        accounts["accounts"][uid] = account
        accounts["logins"][normalized] = uid
    account["password"] = password_record(assigned_password(login))
    account["login"] = login
    account["username"] = login
    account["account_type"] = "normal"
    save_accounts(accounts)

    player_id, _ = birth_player(accounts, account)
    report["player_id"] = player_id
    revision = active_revision()
    statements = build_statements(player, revision, player_id, report)
    run_psql("\n".join(statements) + "\n")
    heroes_state = player.get("heroes") or {}
    owned_tables = {
        int(raw.get("table_id", 0)) for raw in (heroes_state.get("heroes") or {}).values()
    }
    for table_id in sorted({int(key) for key in (heroes_state.get("collected_heros") or {})} - owned_tables):
        report["content_refused"].append({"kind": "collected-hero", "id": int(table_id), "reason": "collected in v1 but not owned; no v2 collected-only owner"})
    report_unmapped(player, save, report)
    report["rows_written"] = {table: count for table, count in sorted(report["rows_written"].items())}
    write_report(login, report)
    return report


def write_report(login, report):
    REPORT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    path = REPORT_DIRECTORY / f"import_report_{normalize_login(login) or 'player'}.json"
    temporary = path.with_name(f"{path.name}.{os.getpid()}.tmp")
    descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, sort_keys=True)
        handle.write("\n")
    os.replace(temporary, path)


def read_credentials():
    lines = {}
    try:
        for line in CREDENTIALS_PATH.read_text(encoding="utf-8").splitlines():
            if not line or line.startswith("#"):
                continue
            name, _, existing = line.partition("\t")
            lines[name] = existing
    except FileNotFoundError:
        pass
    return lines


def assigned_password(login):
    """The login's test password. psk/accounts.txt survives resets, so a login keeps its password across redeploys."""
    lines = read_credentials()
    if login in lines:
        return lines[login]
    password = FIXED_PASSWORDS.get(login)
    number = FIRST_ASSIGNED_PASSWORD_NUMBER
    while password is None or password in lines.values():
        password = f"akm{number}"
        number += 1
    lines[login] = password
    CREDENTIALS_PATH.parent.mkdir(parents=True, exist_ok=True)
    body = ["# login\tpassword"] + [f"{name}\t{lines[name]}" for name in sorted(lines)]
    descriptor = os.open(CREDENTIALS_PATH, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
        handle.write("\n".join(body) + "\n")
    os.chmod(CREDENTIALS_PATH, 0o600)
    return password


# LoginWindow.lua:60 reads regions[4] of the list sorted newest first and crashes the login page when it is nil, so a fresh install
# needs four listed servers; with exactly four it lands on Server 1.
# shortcut: harness rows until the product migration planned before seal 798 (D435) adds them.
DIRECTORY_SERVERS_SQL = """
INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,state_version,created_at)
VALUES
 (3,'Server 3',CURRENT_TIMESTAMP,true,true,true,325001,399999,1,CURRENT_TIMESTAMP),
 (4,'Server 4',CURRENT_TIMESTAMP,true,true,true,425001,499999,1,CURRENT_TIMESTAMP)
ON CONFLICT (logical_server_id) DO NOTHING;
"""

SEEDS = (
    {"directory": "12525385", "login": "moppleton"},
    {"directory": "19700001", "login": "alpaca123"},
    {"directory": "19700002", "login": "campaigner"},
)


def seed():
    run_psql(DIRECTORY_SERVERS_SQL)
    for seed_entry in SEEDS:
        path = PRESERVE_PLAYERS / seed_entry["directory"] / "player.json"
        save = json.loads(path.read_text(encoding="utf-8"))
        player = player_state(save)
        login = seed_entry["login"]
        display_name = str((player.get("identity") or {}).get("player_name") or login)
        report = import_player(save, login, display_name, None)
        print(
            f"seed: {login} player {report['player_id']} rows={sum(report['rows_written'].values())} "
            f"refused={len(report['content_refused'])}"
        )
    return 0


def main(arguments):
    if arguments[:1] == ["seed"]:
        return seed()
    if arguments[:1] == ["import"] and len(arguments) >= 4:
        path = Path(arguments[1])
        save = json.loads(path.read_text(encoding="utf-8"))
        report = import_player(save, arguments[2], arguments[3], None)
        print(json.dumps({"login": report["login"], "player_id": report["player_id"]}, sort_keys=True))
        return 0
    fail("usage: import_legacy.py seed | import <save.json> <login> <display_name>")


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
