#!/usr/bin/env python3
"""Protocol smoke tests for the corrected backend.

Run:
    python3 test_backend.py
"""

import json
import os
import sys
import zlib
from urllib.parse import quote

# Import without starting the Flask listeners.
import server
from server import app, decode_payload, engine_dispatch


def check(name, condition):
    if not condition:
        raise AssertionError(name)
    print("[PASS]", name)


def main():
    # Decoder tests
    obj = {"mid": 20480, "app_v": "1.631.0"}

    value, via = decode_payload(json.dumps(obj))
    check("plain JSON", value == obj)

    value, via = decode_payload(quote(json.dumps(obj)))
    check("URL encoded JSON", value == obj)

    packed = zlib.compress(json.dumps(obj).encode())
    value, via = decode_payload(packed)
    check("zlib JSON", value == obj)

    # Engine contracts
    r = engine_dispatch({"mid": 20480})
    check("20480 root url", "url" in r)
    check("20480 flat", "data" not in r)

    r = engine_dispatch({"mid": 2})
    check("version no restart", r["need_restart"] == 0)

    r = engine_dispatch({"mid": 18})
    check("regions", len(r["regions"]) >= 4)
    check("players empty", r["players"] == {})

    r = engine_dispatch({"mid": 1, "region": 7})
    check("token", r["token"] == "local_token")
    # Regression test for the "stuck on loading spinner" bug (2026-08-16):
    # SelfPlayer.lua:loadGameStartInfoEvent_ does pairs(params.detail)
    # unconditionally when the TOKEN event fires -- if "detail" is missing
    # this throws inside the client's event dispatch and silently aborts
    # before MainScene ever gets created. "detail" must always be a dict.
    check("token response has detail dict", isinstance(r.get("detail"), dict))
    check("token response has uid", r.get("uid") == "13371337")
    check("detail has LOAD_PLAYER_INFO (17) pre-populated",
          r["detail"].get("17", {}).get("player_id") == "13371337")
    check("detail initializes LOAD_HEROS (49)",
          r["detail"].get("49", {}).get("heros") == {})
    check("detail initializes GET_LIBRARY_INFOS (836)",
          r["detail"].get("836", {}).get("library_bg_infos", {}).get("bg_main") == 1)
    check("library talk info is dict",
          isinstance(r["detail"]["836"].get("library_talk_infos"), dict))
    check("library CG info is list",
          isinstance(r["detail"]["836"].get("library_cg_infos"), list))
    check("library background has room id",
          r["detail"]["836"]["library_bg_infos"].get("bg_room") == 2)

    r = engine_dispatch({"mid": 7})
    check("announce is string", isinstance(r["contents"], str))
    check("announce decodes", json.loads(r["contents"]) == {})

    r = engine_dispatch({"mid": 2864, "unique_key": "mtspy"})
    check("AB group is scalar", r == "A")

    r = engine_dispatch({"mid": 17, "region": 7})
    check("player info root", r["player_id"] == "13371337")
    check("player info not nested", "player_info" not in r)

    # SDK response contracts
    client = app.test_client()

    resp = client.post(
        "/server/mobile_api_new/",
        json={"mid": "65284", "payload": {"tp_code": "anonymous"}},
    )
    sdk = resp.get_json()
    check("SDK HTTP 200", resp.status_code == 200)
    check("SDK uid root", sdk["uid"] == "13371337")
    check("SDK UID uppercase", sdk["UID"] == "13371337")
    check("SDK sid root", sdk["sid"] == "13371337")
    check("SDK SID uppercase", sdk["SID"] == "13371337")
    check("SDK data identity", sdk["data"]["sid"] == "13371337")
    cookie_headers = resp.headers.getlist("Set-Cookie")
    check("SDK Set-Cookie QQWSID", any(c.startswith("QQWSID=13371337;") for c in cookie_headers))
    check("SDK Set-Cookie QQWUID", any(c.startswith("QQWUID=13371337;") for c in cookie_headers))
    check("SDK Set-Cookie QQWUNAME", any(c.startswith("QQWUNAME=AdminRoot;") for c in cookie_headers))
    check("SDK Set-Cookie QQWTOKEN", any(c.startswith("QQWTOKEN=local_token;") for c in cookie_headers))

    print("\nAll smoke tests passed.")


if __name__ == "__main__":
    main()
