#!/usr/bin/env python3
"""Acceptance check for the imported v1 players: SDK session, MID18/MID1, stock boot, battles."""

import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
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
STATE_DIRECTORY = PLAYTEST_HOME / "state"
ACCOUNTS_PATH = STATE_DIRECTORY / "accounts.json"
CREDENTIALS_PATH = STATE_DIRECTORY / "credentials.txt"
PRESERVE_PLAYERS = HARNESS_DIRECTORY / "preserve" / "server_state" / "players"
FRONT_BASE = f"http://{os.environ.get('PLAYTEST_BIND', '127.0.0.1')}:18956"
SDK_BASE = f"http://{os.environ.get('PLAYTEST_BIND', '127.0.0.1')}:18955"
REGION = 1
POSTGRES_PORT = 18957
DATABASE_NAME = "gxb_playtest"

CURRENCY_KEYS = (
    "mana", "crystal", "lucky_coin", "arena_coin", "march_coin", "top_coin", "guild_coin",
    "region_coin", "king_coin", "honor_coin", "god_war_coin", "friendship_coin", "friend_medal",
    "summon_coin", "skin_fragment", "glue", "lvbu_coin", "paradise_coin", "team_dungeon_coin",
    "ice_core", "spirit_stone", "social", "glory", "magic_energy", "magic_dust", "magic_liquid",
    "magic_exp", "degree_cer", "graduate_cer", "patent_cer", "occult_ticket", "tutor_coin", "skin_coin",
)
SEEDS = (
    ("moppleton", "12525385"),
    ("alpaca123", "19700001"),
    ("campaigner", "19700002"),
)
BOOT_MIDS_BEFORE_STORY = (2784, 1537)
BOOT_MIDS_AFTER_STORY = (1056, 56, 836, 1344, 176, 2754, 354, 1302, 612)
SERVICE_ROOM_ID = 99999


def fail(message):
    raise SystemExit(f"check_import: {message}")


def post_form(url, payload, timeout=180):
    data = urllib.parse.urlencode({"payload": json.dumps(payload)}).encode("utf-8")
    request = urllib.request.Request(
        url, data=data, headers={"Content-Type": "application/x-www-form-urlencoded"}, method="POST"
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as reply:
            return reply.status, json.loads(reply.read())
    except urllib.error.HTTPError as error:
        return error.code, error.read()[:400]


def post_json(url, payload, timeout=60):
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url, data=data, headers={"Content-Type": "application/json"}, method="POST"
    )
    with urllib.request.urlopen(request, timeout=timeout) as reply:
        return reply.status, json.loads(reply.read())


def psql(query):
    result = subprocess.run(
        [
            str(PLAYTEST_TOOLS / "psql"),
            "-X", "-q", "-t", "-A",
            "-h", str(PLAYTEST_HOME / "pg"),
            "-p", str(POSTGRES_PORT),
            "-U", "postgres",
            "-d", DATABASE_NAME,
            "-c", query,
        ],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        fail(result.stderr.strip()[:500])
    return result.stdout.strip()


def load_credentials():
    credentials = {}
    for line in CREDENTIALS_PATH.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        login, _, password = line.partition("\t")
        credentials[login] = password
    return credentials


def login_session(login, account, credentials):
    stored = account.get("session")
    password = credentials.get(login)
    if not stored or not password or password == "v1-password-record-copied":
        if not stored:
            fail(f"{login} has no stored SDK session")
        return stored, "stored SDK session"
    status, body = post_json(
        f"{SDK_BASE}/server/mobile_api_new",
        {"mid": 65281, "payload": {"login_email": login, "password": password}},
    )
    if status != 200 or body.get("error_code") != 0 or body["data"]["uid"] != account["uid"]:
        fail(f"{login} SDK password login failed")
    return {"sid": body["data"]["sid"], "token": body["data"]["token"]}, "SDK password login"


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


def gameplay_envelope(token, mid, extra=None):
    payload = {
        "mid": mid,
        "token": token,
        "region": REGION,
        "v_": "1.631.0",
        "app_v": "1.631.0",
        "platform": 3,
    }
    payload.update(extra or {})
    return payload


def start_journal():
    return int(psql("SELECT COALESCE(max(journal_id),0) FROM request_journal"))


def journal_problems(player_id, after):
    rows = psql(
        "SELECT mid||'|'||outcome||'|'||http_status||'|'||COALESCE(error_class,'')||'|'||COALESCE(cause,'')"
        f" FROM request_journal WHERE player_id={player_id} AND journal_id>{after}"
        " AND (http_status>=500 OR outcome NOT IN ('OK','INACTIVE_MODE')) ORDER BY journal_id"
    )
    return [row for row in rows.splitlines() if row]


def boot_replay(session, mid1_body):
    token = mid1_body.get("token")
    if not token:
        fail("MID1 reply has no gameplay token")
    story = mid1_body["detail"]["17"]
    story_params = {
        "story_id": int(story.get("story_id", 0)),
        "story_state": int(story.get("story_state", 0)),
        "guide_id": int(story.get("guide_id", 0)),
    }
    sequence = []
    for mid in BOOT_MIDS_BEFORE_STORY:
        sequence.append((mid, {}))
    for room in (REGION, SERVICE_ROOM_ID):
        sequence.append((192, {"room_id": room}))
    sequence.append((121, {"operation_id": 1}))
    sequence.append((26, dict(story_params)))
    sequence.append((121, {"operation_id": 1}))
    for mid in BOOT_MIDS_AFTER_STORY:
        sequence.append((mid, {}))
    for mid, extra in sequence:
        status, body = post_form(f"{FRONT_BASE}/engine", gameplay_envelope(token, mid, extra))
        if status != 200:
            fail(f"boot MID {mid} answered HTTP {status}: {body}")
    return token, len(sequence)


def set_energy(player_id, amount):
    psql(
        "UPDATE player_temporal_resources SET stored_amount="
        f"{int(amount)},regen_anchor_at=now(),state_version=state_version+1,updated_at=now() "
        f"WHERE player_id={int(player_id)} AND resource_key='energy'"
    )


def check_battles(token, partner_ids):
    settled = 0
    for offset in range(0, len(partner_ids), 5):
        formation = "|".join(str(value) for value in partner_ids[offset:offset + 5])
        request = {"campaign_id": 100001, "campaign_type": 1, "formation": formation, "pet_id": 0}
        status, body = post_form(f"{FRONT_BASE}/engine", gameplay_envelope(token, 113, request))
        if status != 200:
            fail(f"campaign battle for {formation} answered HTTP {status}: {body}")
        status, body = post_form(
            f"{FRONT_BASE}/engine",
            gameplay_envelope(token, 114, dict(request, star=3)),
        )
        if status != 200:
            fail(f"campaign settlement for {formation} answered HTTP {status}: {body}")
        settled += len(partner_ids[offset:offset + 5])
    return settled


def check_player(login, directory, accounts, credentials):
    save = json.loads((PRESERVE_PLAYERS / directory / "player.json").read_text(encoding="utf-8"))
    player = save["player"]
    report = json.loads((STATE_DIRECTORY / f"import_report_{login}.json").read_text(encoding="utf-8"))
    account = accounts["accounts"][accounts["logins"][login]]
    session, login_kind = login_session(login, account, credentials)

    before = start_journal()
    status, listing = post_form(f"{FRONT_BASE}/engine", envelope(session, 18))
    if status != 200:
        fail(f"{login} MID18 answered HTTP {status}: {listing}")
    players = listing.get("players") or []
    if len(players) != 1:
        fail(f"{login} MID18 lists {len(players)} players, expected one")
    listed = players[0]
    status, mid1 = post_form(f"{FRONT_BASE}/engine", envelope(session, 1))
    if status != 200:
        fail(f"{login} MID1 answered HTTP {status}: {mid1}")

    detail = mid1["detail"]
    profile = detail["17"]
    progression = player["progression"]
    refused_kinds = [entry["kind"] for entry in report["content_refused"]]
    expected_heroes = len((player.get("heroes") or {}).get("heroes") or {}) - refused_kinds.count("hero")
    expected_items = len((player.get("inventory") or {}).get("backpack_items") or []) - refused_kinds.count("item")
    actual_heroes = len(detail["49"]["heros"])
    actual_items = len(detail["81"]["list"])
    if int(profile.get("lev", 0)) != int(progression.get("lev", 0)):
        fail(f"{login} level {profile.get('lev')} != save {progression.get('lev')}")
    if int(profile.get("vip", 0)) != int(progression.get("vip", 0)):
        fail(f"{login} vip {profile.get('vip')} != save {progression.get('vip')}")
    if actual_heroes != expected_heroes:
        fail(f"{login} hero count {actual_heroes} != expected {expected_heroes}")
    if actual_items != expected_items:
        fail(f"{login} item count {actual_items} != expected {expected_items}")
    if int(listed.get("lev", 0)) != int(progression.get("lev", 0)):
        fail(f"{login} MID18 lev {listed.get('lev')} != save {progression.get('lev')}")

    economy = player.get("economy") or {}
    for key in CURRENCY_KEYS:
        if key in ("degree_cer", "graduate_cer", "patent_cer"):
            expected = int(progression.get(key, 0) or 0)
        else:
            expected = int(economy.get(key, 0) or 0)
        actual = int(profile.get(key, 0) or 0)
        if actual != expected:
            fail(f"{login} currency {key} {actual} != save {expected}")

    token, boot_count = boot_replay(session, mid1)
    partners = sorted(
        int(raw.get("partner_id", key))
        for key, raw in ((player.get("heroes") or {}).get("heroes") or {}).items()
    )
    expected_energy = int(economy.get("energy", 0) or 0)
    set_energy(report["player_id"], 1000000)
    try:
        settled = check_battles(token, partners)
    finally:
        set_energy(report["player_id"], expected_energy)
    if settled != actual_heroes:
        fail(f"{login} battle check covered {settled} heroes, roster has {actual_heroes}")

    problems = journal_problems(report["player_id"], before)
    if problems:
        fail(f"{login} journal problems: {problems}")
    print(
        f"check {login}: ok pid={report['player_id']} {login_kind} lev={profile['lev']} vip={profile['vip']} "
        f"heroes={actual_heroes} items={actual_items} boot_mids={boot_count} battle_heroes={settled}"
    )


def main():
    accounts = json.loads(ACCOUNTS_PATH.read_text(encoding="utf-8"))
    credentials = load_credentials()
    for login, directory in SEEDS:
        check_player(login, directory, accounts, credentials)
    print("check_import ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
