#!/usr/bin/env python3
"""
GXB private-server compatibility backend.

Two HTTP surfaces:
  :5000  Java/Xinyd SDK endpoint(s)
  :9000  UpdateScene center + Lua engine API

This version is intentionally tolerant:
  * SDK mids may be numeric strings or symbolic strings.
  * Engine payload may be plain JSON, URL-encoded JSON, or zlib JSON.
  * zlib battle requests may arrive as multipart file parts.
  * every engine success response includes error_code=0.
  * SDK login responses expose identity fields both at root and in data,
    including uppercase aliases used by some SDK session code.
  * MID 2864 returns the string A, because SelfPlayer stores its response
    directly as the AB-test group value.
"""

import json
import os
import threading
import time
import urllib.parse
import zlib
from pathlib import Path

from flask import Flask, request, jsonify, make_response

import mids
import game_logic
from mids import MID


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

HOST = os.getenv("GXB_BIND", "0.0.0.0")
SDK_PORT = int(os.getenv("GXB_SDK_PORT", "5000"))
ENGINE_PORT = int(os.getenv("GXB_ENGINE_PORT", "9000"))

# Must be reachable FROM THE ANDROID DEVICE, not merely from the server.
SELF_URL = os.getenv(
    "GXB_SELF_URL",
    "http://172.20.0.21:9000/api/v1",
)

CENTER_DISCOVERY_MID = 20480
VERSION_CHECK_MID = 2

app = Flask(__name__)
app.config["JSON_SORT_KEYS"] = False


# Backend.lua sendAsFormData_()
FORM_DATA_MIDS = {
    getattr(MID, "ARENA_FIGHT_RESULT", -1),
    getattr(MID, "PEAK_START_FIGHT", -1),
    getattr(MID, "TREASURE_SAVE_BATTLE_RESULT", -1),
    getattr(MID, "REARENA_END_FIGHT", -1),
    getattr(MID, "REGION_FIGHT_RESULT", -1),
    getattr(MID, "CONQUER_SCHOOL_FIGHT_RESULT", -1),
    getattr(MID, "SAVE_FURNITURES", -1),
}


# ---------------------------------------------------------------------------
# Response helpers
# ---------------------------------------------------------------------------

def engine_ok(data=None):
    out = {"error_code": 0}
    if data:
        out.update(data)
    return out


def build_response(data, cookies=None):
    """Build a JSON response and optionally attach HTTP Set-Cookie headers."""
    response = make_response(jsonify(data))
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Connection"] = "keep-alive"

    # The xyd Android SDK does not derive UserSession from the JSON body for
    # these login mids. XinydUtils reads the response cookie store and maps
    # these four cookie names into UserSession.{SID,UID,UNAME,TOKEN}.
    if cookies:
        for name, value in cookies.items():
            response.set_cookie(
                name,
                str(value),
                path="/",
                httponly=False,
                secure=False,
                samesite=None,
            )
    return response


def sdk_identity():
    # Keep this deterministic while the private server has one local account.
    # The uppercase aliases are deliberate: the current log shows SDK session
    # state as SID/UID/UNAME/TOKEN, while other observed code uses lowercase.
    return {
        "uid": "13371337",
        "sid": "13371337",
        "access_token": "local_token",
        "token": "local_token",
        "username": "AdminRoot",
        "nickname": "AdminRoot",
        "is_new": 0,
        "UID": "13371337",
        "SID": "13371337",
        "UNAME": "AdminRoot",
        "TOKEN": "local_token",
    }


def sdk_session_cookies():
    """Return the HTTP cookies consumed by XinydUtils.setCookie()."""
    ident = sdk_identity()
    return {
        "QQWSID": ident["SID"],
        "QQWUID": ident["UID"],
        "QQWUNAME": ident["UNAME"],
        "QQWTOKEN": ident["TOKEN"],
    }


def sdk_success(identity=False, data=None):
    body = {
        "status": 1,
        "code": 1,
        "error_code": 0,
        "msg": "success",
        "data": dict(data or {}),
        "package_info": {},
    }
    if identity:
        ident = sdk_identity()
        body.update(ident)
        body["data"].update(ident)
    return body


# ---------------------------------------------------------------------------
# Payload decoding
# ---------------------------------------------------------------------------

def _json_load_bytes(raw):
    if isinstance(raw, bytes):
        text = raw.decode("utf-8", "replace")
    else:
        text = str(raw)
    return json.loads(text)


def decode_payload(raw):
    """
    Accept the encodings actually used by the Lua client.

    Order:
      1. JSON
      2. URL-decoded JSON
      3. repeated URL-decoding (defensive)
      4. zlib JSON
      5. zlib after URL decoding
    """
    if raw is None:
        return None, "empty"

    if isinstance(raw, str):
        raw_text = raw
        raw_bytes = raw.encode("latin1", "replace")
    else:
        raw_bytes = bytes(raw)
        raw_text = raw_bytes.decode("utf-8", "replace")

    candidates = [
        (raw_text, "plain-json"),
        (urllib.parse.unquote_plus(raw_text), "url-decoded-json"),
        (urllib.parse.unquote(urllib.parse.unquote_plus(raw_text)),
         "double-url-decoded-json"),
    ]

    for text, method in candidates:
        try:
            value = json.loads(text)
            if isinstance(value, dict):
                return value, method
        except Exception:
            pass

    for blob, method in [
        (raw_bytes, "zlib-json"),
        (urllib.parse.unquote_to_bytes(raw_text), "url-decoded-zlib-json"),
    ]:
        try:
            value = json.loads(zlib.decompress(blob).decode("utf-8"))
            if isinstance(value, dict):
                return value, method
        except Exception:
            pass

    return None, "undecoded"


def get_engine_payload():
    # Normal Backend.lua requests.
    if "payload" in request.form:
        return request.form.get("payload"), "form-payload"

    # Multipart compressed requests. Werkzeug exposes uploaded parts here.
    if "payload" in request.files:
        return request.files["payload"].read(), "multipart-payload"

    # A few test clients/proxies send the body directly.
    if request.data:
        return request.data, "raw-body"

    return None, "empty"


# ---------------------------------------------------------------------------
# SDK layer :5000
# ---------------------------------------------------------------------------

KNOWN_SDK_IDENTITY_MIDS = {
    "65305", "65284", "65281", "65304",
    "65305.0", "65284.0", "65281.0", "65304.0",
}

KNOWN_SDK_LOG_MIDS = {"65319"}

PAYMENT_QUERY_NAMES = {
    "query_pay_method_amounts",
}


def handle_sdk():
    body = request.get_json(silent=True)
    if not isinstance(body, dict):
        # Some SDK endpoints can be reached by multipart/form requests.
        raw = request.form.get("payload")
        if raw:
            try:
                body = json.loads(raw)
            except Exception:
                body = None

    if not isinstance(body, dict):
        print("[SDK] malformed/non-JSON request")
        return build_response(sdk_success(False))

    mid = str(body.get("mid", ""))
    payload = body.get("payload")
    print(f"[SDK] mid={mid!r} payload={payload!r}")

    # Device initialization / login / retry helper mids.  The exact Java
    # contract is only partially visible in the available assets, so we
    # return the observed identity fields consistently.
    if mid in KNOWN_SDK_IDENTITY_MIDS:
        # 65284 (anonymous login) is the important one: XinydUtils reads
        # Set-Cookie and populates XinydUser.UserSession from QQW* cookies.
        # Keep the JSON identity too for compatibility with other SDK code.
        cookies = sdk_session_cookies()
        print(
            "[SDK] setting session cookies: "
            + ", ".join(f"{k}={v}" for k, v in cookies.items())
        )
        return build_response(
            sdk_success(identity=True),
            cookies=cookies,
        )

    # SDK log-upload registration is happy with an empty data object.
    if mid in KNOWN_SDK_LOG_MIDS:
        return build_response(sdk_success(False))

    # Payment is not part of the game-server state machine.  Returning an
    # explicit empty successful result is safer than pretending it is a
    # login response (the old server did exactly that and the SDK reported
    # "payment system initialization failed").
    if mid in PAYMENT_QUERY_NAMES:
        return build_response(sdk_success(False, {
            "methods": [],
            "amounts": [],
        }))

    # Unknown SDK calls: preserve the SDK envelope, but DO NOT inject fake
    # login identity into arbitrary calls.
    return build_response(sdk_success(False))


# ---------------------------------------------------------------------------
# Engine layer :9000
# ---------------------------------------------------------------------------

def engine_dispatch(req_data):
    try:
        req_mid = int(req_data.get("mid", 0))
    except (TypeError, ValueError):
        return engine_ok()

    name = mids.mid_name(req_mid) if hasattr(mids, "mid_name") else str(req_mid)
    print(
        f"[ENGINE IN] mid={name} ({req_mid}) "
        f"data={json.dumps(req_data, ensure_ascii=False, default=str)}"
    )

    if req_mid == CENTER_DISCOVERY_MID:
        result = game_logic.handle_center_discovery(req_data, SELF_URL)
        return engine_ok(result)

    if req_mid == VERSION_CHECK_MID:
        return engine_ok(game_logic.handle_version_check(req_data))

    if req_mid == MID.RETRIEVE_TOKEN:
        return engine_ok(game_logic.handle_retrieve_token(req_data))

    if req_mid == MID.QUERY_SERVER_TIME:
        return engine_ok(game_logic.handle_query_server_time(req_data))

    if req_mid == MID.LOAD_PLAYER_INFO:
        return engine_ok(game_logic.handle_load_player_info(req_data))

    if req_mid == MID.LOAD_USER_REGIONS:
        return engine_ok(game_logic.handle_load_user_regions(req_data))

    if req_mid == MID.LOAD_ANNOUNCE:
        return engine_ok(game_logic.handle_load_announce(req_data))

    if req_mid == getattr(MID, "GET_PLAYER_GROUP_BY_KEY", -999999):
        # SelfPlayer:getAbtestGroupByKey() stores the callback response itself
        # as the group value. Returning {"error_code":0} corrupts that state.
        return game_logic.handle_get_player_group(req_data)

    if req_mid in (
        getattr(MID, "ACTIVITY_1124_AWARD", -1),
        getattr(MID, "ACTIVITY_1149_AWARD", -1),
        getattr(MID, "ACTIVITY_1231_AWARD", -1),
    ):
        return engine_ok(game_logic.handle_activity_award(req_data))

    print(f"[ENGINE] no handler for {name} ({req_mid}); returning generic OK")
    return engine_ok()


@app.route("/server/mobile_api_new/", methods=["POST"])
@app.route("/server/mobile_api_new", methods=["POST"])
def sdk_route():
    return handle_sdk()


@app.route("/home_api/upload_sdk_logs", methods=["POST"])
@app.route("/home_api/upload_sdk_logs/", methods=["POST"])
def sdk_upload():
    # The SDK only checks that this upload endpoint answers. We do not need
    # to persist the log unless desired.
    print("[SDK] upload_sdk_logs received")
    return build_response({"error_code": 0})


@app.route("/center/v1", methods=["POST"])
def center_route():
    raw, source = get_engine_payload()
    req_data, method = decode_payload(raw)
    print(f"[CENTER] source={source} decode={method}")
    if not req_data:
        return build_response(engine_ok())
    return build_response(engine_dispatch(req_data))


@app.route("/api/v1", methods=["POST"])
def api_route():
    raw, source = get_engine_payload()
    req_data, method = decode_payload(raw)
    print(f"[API] source={source} decode={method}")
    if not req_data:
        print("[API] could not decode payload")
        return build_response(engine_ok())

    response = engine_dispatch(req_data)
    print(
        "[ENGINE OUT]",
        json.dumps(response, ensure_ascii=False, separators=(",", ":"))
    )
    return build_response(response)


@app.route("/", methods=["POST", "GET"])
@app.route("/<path:path>", methods=["POST", "GET"])
def catch_all(path):
    port = request.environ.get("SERVER_PORT")
    print(f"[HTTP] unmatched path=/{path} port={port}")

    if str(port) == str(SDK_PORT):
        return handle_sdk()

    raw, source = get_engine_payload()
    req_data, method = decode_payload(raw)
    if req_data:
        return build_response(engine_dispatch(req_data))

    return build_response(engine_ok())


def run_server(port):
    # Flask's threaded mode matters here because the client can issue
    # overlapping model loads.
    app.run(
        host=HOST,
        port=port,
        debug=False,
        threaded=True,
        use_reloader=False,
    )


if __name__ == "__main__":
    print("==================================================")
    print(" GXB private backend")
    print(f" SDK    : http://0.0.0.0:{SDK_PORT}")
    print(f" ENGINE : http://0.0.0.0:{ENGINE_PORT}")
    print(f" SELF_URL = {SELF_URL}")
    print("==================================================")

    t1 = threading.Thread(target=run_server, args=(SDK_PORT,), daemon=True)
    t2 = threading.Thread(target=run_server, args=(ENGINE_PORT,), daemon=True)
    t1.start()
    t2.start()

    try:
        while True:
            time.sleep(3600)
    except KeyboardInterrupt:
        print("\nStopping.")
