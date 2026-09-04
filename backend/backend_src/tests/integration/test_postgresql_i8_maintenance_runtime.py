"""I8 PREPARED-state internal smoke while public admissions remain closed."""
from __future__ import annotations

import json
import os
import re

import pytest

from gxb_backend.foundation.database import DatabaseSettings
from gxb_backend.runtime.composition import (
    create_postgres_app,
    create_postgres_state,
    create_scheduler_process,
)

pytestmark = pytest.mark.postgresql
_SAFE_DATABASE = re.compile(r"^[a-z_][a-z0-9_]{0,62}(?:test|_test)$")


def configured(monkeypatch):
    if os.environ.get("GXB_EXPECT_MAINTENANCE_PREPARED") != "1":
        pytest.skip("dedicated PREPARED maintenance smoke only")
    url = os.environ.get("GXB_TEST_DATABASE_URL", "")
    if not url:
        pytest.skip("GXB_TEST_DATABASE_URL not configured")
    settings = DatabaseSettings.from_env({"GXB_DATABASE_URL": url})
    assert _SAFE_DATABASE.fullmatch(settings.url.database or "")
    monkeypatch.setenv("GXB_DATABASE_URL", url)
    monkeypatch.setenv("GXB_HTTP_WORKERS", "1")
    marker = os.environ.get("GXB_MAINTENANCE_FILE", "")
    assert marker and os.path.isfile(marker)


def test_internal_stock_flow_and_workers_are_safe_before_traffic_open(monkeypatch):
    configured(monkeypatch)
    app = create_postgres_app()
    client = app.test_client()
    identity = client.post(
        "/server/mobile_api_new/",
        json={"mid": 65284, "payload": {"device_id": "pytest-i8-prepared"}},
    ).get_json()

    def post(body):
        return client.post(
            "/api/v1", data={"payload": json.dumps(body, separators=(",", ":"))}
        ).get_json()

    regions = post({
        "mid": 18, "sid": identity["sid"], "login_token": identity["token"],
        "request_id": "pytest-i8-prepared-18",
    })
    boot = post({
        "mid": 1, "sid": identity["sid"], "login_token": identity["token"],
        "region": 125, "request_id": "pytest-i8-prepared-1",
        "client_op_id": "pytest-i8-prepared-op",
    })
    player = post({
        "mid": 17, "token": boot["token"], "region": 125,
        "request_id": "pytest-i8-prepared-17",
    })
    ready = client.get("/health/ready").get_json()
    state, provider, _ = create_postgres_state()
    scheduler, scheduler_provider = create_scheduler_process()
    try:
        assert state.resolve_realtime_identity(boot["token"], 125) is None
        assert scheduler.recover_startup() == 0
        assert scheduler.run_once() == (0, 0)
    finally:
        provider.dispose()
        scheduler_provider.dispose()
    assert regions["error_code"] == boot["error_code"] == player["error_code"] == 0
    assert ready["authority"] == "PREPARED"
    assert ready["status"] == "maintenance_ready" and ready["maintenance_active"] is True
