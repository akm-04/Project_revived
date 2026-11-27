#!/usr/bin/env python3
"""Self-check for a running playtest instance: MID20480, one backend OTA res file, SDK login and MID1."""

import argparse
import hashlib
import json
import os
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[1]
PLAYTEST_HOME = Path(os.environ.get("PLAYTEST_HOME", Path(__file__).resolve().parent / "runtime"))
PLAYTEST_TOOLS = Path(
    os.environ.get(
        "PLAYTEST_TOOLS",
        WORKSPACE / "tmp" / "tools_r4_accept" / "gxb-e2e-self-contained" / "bin",
    )
)
PLAYTEST_BIND = os.environ.get("PLAYTEST_BIND", "127.0.0.1")
ENGINE_ORIGIN = os.environ.get(
    "PLAYTEST_ENGINE_ORIGIN", "https://gxbv2engine.shares.zrok.io"
).rstrip("/")
FRONT_BASE = f"http://{PLAYTEST_BIND}:{int(os.environ.get('PLAYTEST_FRONT_PORT', '18956'))}"
SDK_BASE = f"http://{PLAYTEST_BIND}:18955"
DATABASE_NAME = "gxb_playtest"
POSTGRES_PORT = 18957
OTA_ASSETS_DIRECTORY = PLAYTEST_HOME / "ota_root" / "updates" / "assets"


def post_form(url, payload):
    data = urllib.parse.urlencode({"payload": json.dumps(payload)}).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=30) as reply:
        return reply.status, reply.read()


def post_json(url, payload):
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=30) as reply:
        return reply.status, reply.read()


def fetch(url):
    with urllib.request.urlopen(url, timeout=60) as reply:
        return reply.status, reply.read()


def psql(statement):
    result = subprocess.run(
        [
            str(PLAYTEST_TOOLS / "psql"),
            "-X",
            "-q",
            "-t",
            "-A",
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
            "-c",
            statement,
        ],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())
    return result.stdout.strip()


def check_prelogin():
    _, body = post_form(
        f"{FRONT_BASE}/center/v1",
        {
            "mid": 20480,
            "area": "tw",
            "type": 0,
            "app_v": "1.631.0",
            "platform": 0,
        },
    )
    reply = json.loads(body)
    res_url = reply.get("res_download_url")
    # Empty = the backend OTA's lazy fetch is off (no assets release yet); otherwise the front adds the launch id.
    if res_url and not (res_url.startswith(f"{ENGINE_ORIGIN}/s/") and res_url.endswith("/engine/res/")):
        raise AssertionError(
            f"MID20480 res_download_url is {res_url!r}, expected '' or {ENGINE_ORIGIN}/s/<launch>/engine/res/"
        )
    print(f"check 1 ok: MID20480 res_download_url={res_url!r}")


def check_asset():
    sidecars = sorted(OTA_ASSETS_DIRECTORY.glob("*.res.json"), key=lambda path: path.stat().st_mtime)
    if not sidecars:
        print("check 2 skipped: no backend OTA assets release built yet")
        return
    entry = json.loads(sidecars[-1].read_text(encoding="utf-8"))["entries"][0]
    name = Path(entry["path"]).name
    status, body = fetch(f"{FRONT_BASE}/engine/res/{name}.{entry['md5']}")
    if status != 200 or hashlib.md5(body).hexdigest() != entry["md5"]:
        raise AssertionError(f"res {name} gave {status} or a wrong md5")
    try:
        fetch(f"{FRONT_BASE}/engine/res/{name}.{uuid.uuid4().hex}")
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise AssertionError(f"wrong md5 gave {error.code}, expected 404")
    else:
        raise AssertionError("wrong md5 did not give 404")
    print(f"check 2 ok: {name} served through the front by the backend OTA, wrong md5 gave 404")


def check_login_and_mid1():
    login = "playtest-" + uuid.uuid4().hex
    password = uuid.uuid4().hex
    _, register_body = post_json(
        f"{SDK_BASE}/server/mobile_api_new",
        {
            "mid": 65282,
            "payload": {
                "login_email": login,
                "password": password,
                "repassword": password,
            },
        },
    )
    register_reply = json.loads(register_body)
    if register_reply.get("error_code") != 0:
        raise AssertionError(f"register error_code {register_reply.get('error_code')}")
    uid = register_reply["data"]["uid"]

    _, login_body = post_json(
        f"{SDK_BASE}/server/mobile_api_new",
        {"mid": 65281, "payload": {"login_email": login, "password": password}},
    )
    login_reply = json.loads(login_body)
    if login_reply.get("error_code") != 0 or login_reply["data"]["uid"] != uid:
        raise AssertionError("login did not return the registered uid")
    sid = login_reply["data"]["sid"]
    token = login_reply["data"]["token"]
    if not sid or not token:
        raise AssertionError("login returned an empty session credential")

    _, wrong_body = post_json(
        f"{SDK_BASE}/server/mobile_api_new",
        {"mid": 65281, "payload": {"login_email": login, "password": "wrong-" + password}},
    )
    wrong_reply = json.loads(wrong_body)
    if wrong_reply.get("error_code") == 0:
        raise AssertionError("wrong password was accepted")

    mid1_payload = {
        "mid": 1,
        "sid": sid,
        "login_token": token,
        "region": 1,
        "v_": "1.631.0",
        "app_v": "1.631.0",
        "platform": 0,
    }
    status, _ = post_form(
        f"{FRONT_BASE}/engine",
        {"mid": 18, "sid": sid, "login_token": token, "v_": "1.631.0", "app_v": "1.631.0", "platform": 0},
    )
    if status != 200:
        raise AssertionError(f"MID18 status {status}")
    status, _ = post_form(f"{FRONT_BASE}/engine", mid1_payload)
    if status != 200:
        raise AssertionError(f"MID1 status {status}")
    first_players = psql(
        f"SELECT player_id FROM players WHERE account_id = '{uid}'::uuid ORDER BY player_id"
    ).splitlines()
    if len(first_players) != 1:
        raise AssertionError(f"MID1 created {len(first_players)} players, expected one")

    _, second_body = post_json(
        f"{SDK_BASE}/server/mobile_api_new",
        {"mid": 65281, "payload": {"login_email": login, "password": password}},
    )
    second_reply = json.loads(second_body)
    if second_reply["data"]["uid"] != uid:
        raise AssertionError("second login returned a different uid")
    if second_reply["data"]["sid"] != sid or second_reply["data"]["token"] != token:
        raise AssertionError("second login did not reuse the account session")
    status, _ = post_form(
        f"{FRONT_BASE}/engine",
        {"mid": 18, "sid": sid, "login_token": token, "v_": "1.631.0", "app_v": "1.631.0", "platform": 0},
    )
    if status != 200:
        raise AssertionError(f"second MID18 status {status}")
    status, _ = post_form(f"{FRONT_BASE}/engine", mid1_payload)
    if status != 200:
        raise AssertionError(f"second MID1 status {status}")
    second_players = psql(
        f"SELECT player_id FROM players WHERE account_id = '{uid}'::uuid ORDER BY player_id"
    ).splitlines()
    if second_players != first_players:
        raise AssertionError("second login changed the player")
    print(
        f"check 3 ok: register/login/wrong-password, MID1 player {first_players[0]}, "
        "same uid and player after second login"
    )


def check_realtime_http_poll():
    url = f"{FRONT_BASE}/realtime/poll"
    status, body = post_json(url, {"frames": []})
    if status != 200:
        raise AssertionError(f"HTTP poll create status {status}")
    created = json.loads(body)
    session_id = created.get("session_id")
    if not isinstance(session_id, str) or not session_id or created.get("frames") != []:
        raise AssertionError(f"HTTP poll create reply was invalid: {created!r}")

    status, body = post_json(url, {"session_id": session_id, "frames": []})
    if status != 200:
        raise AssertionError(f"HTTP poll reuse status {status}")
    reused = json.loads(body)
    if reused.get("session_id") != session_id or reused.get("frames") != []:
        raise AssertionError("HTTP poll did not preserve the session through the front")

    try:
        post_json(url, {"session_id": "unknown-session", "frames": []})
    except urllib.error.HTTPError as error:
        if error.code != 409:
            raise AssertionError(f"unknown HTTP poll session status {error.code}, expected 409")
    else:
        raise AssertionError("unknown HTTP poll session was accepted")
    print("check 4 ok: /realtime/poll create, reuse and unknown-session refusal through the asset front")




def main(arguments=None):
    parser = argparse.ArgumentParser(description="Check a running playtest instance")
    parser.add_argument("--realtime-only", action="store_true", help="check only /realtime/poll through the asset front")
    options = parser.parse_args(arguments)
    if options.realtime_only:
        check_realtime_http_poll()
        print("selfcheck ok")
        return
    checks = (check_prelogin, check_asset, check_login_and_mid1, check_realtime_http_poll)
    for check in checks:
        check()
    print("selfcheck ok")


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, RuntimeError, urllib.error.URLError, KeyError) as error:
        print(f"selfcheck FAILED: {error}", file=sys.stderr)
        sys.exit(1)
