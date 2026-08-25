#!/usr/bin/env python3
"""Pass88 preservation route contract test without external Flask dependency."""
from __future__ import annotations

import sys
import tempfile
import types
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))


class FakeResponse:
    def __init__(self, data, status=200):
        self.data = data
        self.status_code = int(status)
        self.headers = {}


def jsonify(data):
    return data


def make_response(data, status=200):
    return FakeResponse(data, status)


fake_flask = types.ModuleType("flask")
fake_flask.jsonify = jsonify
fake_flask.make_response = make_response
fake_flask.request = None
sys.modules.setdefault("flask", fake_flask)

from gxb_backend.state.repository import StateRepository
from gxb_backend.transport import routes_commerce


class FakeRequest:
    def __init__(self, body):
        self._body = dict(body)
        self.form = {}
        self.cookies = {}
    def get_json(self, silent=True):
        return dict(self._body)


class FakeApp:
    def __init__(self):
        self.routes = {}
    def route(self, path, methods=None):
        def deco(fn):
            self.routes[path] = fn
            return fn
        return deco


def main():
    with tempfile.TemporaryDirectory(prefix="pass88_route_") as td:
        repo = StateRepository(
            ROOT / "data/player_db.json",
            profile="established",
            legacy_path=ROOT / "state/gxb_state.json",
            multiuser_root=Path(td) / "server_state",
        )
        app = FakeApp()
        routes_commerce.register_commerce_routes(app, repo)
        handler = app.routes["/preservation/v1/purchase-intents"]
        body = {
            "intent_id": "route-contract-001",
            "charge_id": 80001007,
            "platform": "preservation_manual",
            "token": "local_token",
            "region": 125,
            "allow_legacy_sandbox": 1,
        }
        routes_commerce.request = FakeRequest(body)
        first = handler()
        assert first.status_code == 200, first.data
        assert first.data["ok"] == 1 and first.data["status"] == "COMMITTED"
        assert first.data["recharge_event"]["mid"] == 36857
        first_total = first.data["recharge_event"]["params"]["total"]

        routes_commerce.request = FakeRequest(body)
        replay = handler()
        assert replay.status_code == 200, replay.data
        assert replay.data["status"] == "REPLAYED" and replay.data["replayed"] == 1
        assert replay.data["recharge_event"]["params"]["total"] == first_total

        bad = dict(body)
        bad["intent_id"] = "route-contract-bad"
        bad["token"] = "not-a-session"
        routes_commerce.request = FakeRequest(bad)
        denied = handler()
        assert denied.status_code == 401 and denied.data["ok"] == 0

        print({
            "pass": "88.0",
            "status": "PASS",
            "checks": [
                "authenticated_route_commits",
                "route_retry_replays",
                "unknown_session_rejected",
            ],
        })
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
