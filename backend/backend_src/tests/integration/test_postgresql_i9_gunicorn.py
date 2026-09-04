"""Actual Gunicorn gthread proof for each Pass348 worker stage (1, 2, 4)."""
from __future__ import annotations

import json
import os
import re
import socket
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from contextlib import closing
from pathlib import Path
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from uuid import uuid4

import pytest
from sqlalchemy import select

from gxb_backend.foundation.database import DatabaseSettings, ProcessEngineProvider
from gxb_backend.persistence.schema import players


pytestmark = pytest.mark.postgresql
ROOT = Path(__file__).resolve().parents[2]
_SAFE_DATABASE = re.compile(r"^[a-z_][a-z0-9_]{0,62}(?:test|_test)$")


def _post_json(url: str, body: dict) -> tuple[int, dict]:
    request = Request(
        url,
        data=json.dumps(body, separators=(",", ":")).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=30) as response:
            return int(response.status), json.loads(response.read())
    except HTTPError as exc:
        return int(exc.code), json.loads(exc.read())


def _post_engine(base_url: str, body: dict) -> tuple[int, dict]:
    request = Request(
        base_url + "/api/v1",
        data=urlencode({"payload": json.dumps(body, separators=(",", ":"))}).encode(),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=60) as response:
            return int(response.status), json.loads(response.read())
    except HTTPError as exc:
        return int(exc.code), json.loads(exc.read())


def _get_json(url: str) -> tuple[int, dict]:
    try:
        with urlopen(url, timeout=10) as response:
            return int(response.status), json.loads(response.read())
    except HTTPError as exc:
        return int(exc.code), json.loads(exc.read())


def _free_tcp_port() -> int:
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as listener:
        listener.bind(("127.0.0.1", 0))
        return int(listener.getsockname()[1])


def _login(base_url: str, index: int) -> dict:
    nonce = uuid4().hex
    login = f"i9-http-{index}-{nonce}@local"
    password = "I9-http-proof-123"
    status, registered = _post_json(
        base_url + "/server/mobile_api_new/",
        {
            "mid": 65282,
            "payload": {"login_email": login, "password": password, "repassword": password},
        },
    )
    assert status == 200 and registered["error_code"] == 0
    status, identity = _post_json(
        base_url + "/server/mobile_api_new/",
        {"mid": 65281, "payload": {"login_email": login, "password": password}},
    )
    assert status == 200 and identity["error_code"] == 0
    return identity


def _select(base_url: str, identity: dict, request_id: str) -> tuple[int, dict]:
    return _post_engine(
        base_url,
        {
            "mid": 1,
            "sid": identity["sid"],
            "login_token": identity["token"],
            "region": 125,
            "request_id": request_id,
            "client_op_id": request_id,
        },
    )


def test_gunicorn_stage_parallelism_and_stock_identity_flow(tmp_path):
    raw_url = os.environ.get("GXB_TEST_DATABASE_URL", "")
    raw_workers = os.environ.get("GXB_I9_HTTP_WORKERS", "")
    if not raw_url or not raw_workers:
        pytest.skip("GXB_TEST_DATABASE_URL and GXB_I9_HTTP_WORKERS are required")
    workers = int(raw_workers)
    assert workers in (1, 2, 4)
    settings = DatabaseSettings.from_env({"GXB_DATABASE_URL": raw_url})
    assert _SAFE_DATABASE.fullmatch(settings.url.database or "")
    port = _free_tcp_port()
    base_url = f"http://127.0.0.1:{port}"
    env = dict(os.environ)
    env.update(
        GXB_DATABASE_URL=raw_url,
        GXB_HTTP_WORKERS=str(workers),
        GXB_HTTP_THREADS="8",
        GXB_HTTP_BIND=f"127.0.0.1:{port}",
        GXB_MAINTENANCE_FILE=str(tmp_path / "maintenance-disabled"),
        GXB_RUNTIME_LOG_DIR=str(tmp_path / "runtime-logs"),
        GXB_AUTO_UPDATE_ENSURE="0",
        PYTHONUNBUFFERED="1",
    )
    log_path = tmp_path / f"gunicorn-{workers}.log"
    with log_path.open("wb") as log:
        process = subprocess.Popen(
            [sys.executable, "-m", "gunicorn", "-c", "deploy/gunicorn.conf.py", "gxb_backend.runtime.wsgi:app"],
            cwd=ROOT,
            env=env,
            stdout=log,
            stderr=subprocess.STDOUT,
        )
        try:
            deadline = time.monotonic() + 60
            while time.monotonic() < deadline:
                if process.poll() is not None:
                    raise AssertionError(log_path.read_text(errors="replace"))
                try:
                    status, ready = _get_json(base_url + "/health/ready")
                    if status == 200 and ready.get("status") == "ready":
                        break
                except OSError:
                    pass
                time.sleep(0.1)
            else:
                raise AssertionError("Gunicorn readiness timeout\n" + log_path.read_text(errors="replace"))
            assert ready["authority"] == "TRAFFIC_OPEN"
            assert ready["http_workers"] == workers
            assert ready["legacy_rlock_retained"] is False

            observed_pids = set()
            for _ in range(20):
                with ThreadPoolExecutor(max_workers=max(8, workers * 8)) as pool:
                    samples = tuple(pool.map(lambda _: _get_json(base_url + "/health/live"), range(64)))
                for status, live in samples:
                    assert status == 200
                    observed_pids.add(int(live["pid"]))
                if len(observed_pids) == workers:
                    break
            boot_pids = {
                int(value)
                for value in re.findall(r"Booting worker with pid: (\d+)", log_path.read_text(errors="replace"))
            }
            assert len(boot_pids) == workers
            assert observed_pids
            assert observed_pids <= boot_pids

            identities = tuple(_login(base_url, index) for index in range(4))
            booted = []
            for index, identity in enumerate(identities):
                status, regions_body = _post_engine(
                    base_url,
                    {
                        "mid": 18,
                        "sid": identity["sid"],
                        "login_token": identity["token"],
                        "request_id": f"i9-http-{workers}-mid18-{index}",
                    },
                )
                assert status == 200 and regions_body["error_code"] == 0
                status, boot = _select(base_url, identity, f"i9-http-{workers}-mid1-{index}")
                assert status == 200 and boot["error_code"] == 0
                status, player = _post_engine(
                    base_url,
                    {
                        "mid": 17,
                        "token": boot["token"],
                        "region": 125,
                        "request_id": f"i9-http-{workers}-mid17-{index}",
                    },
                )
                assert status == 200 and player["error_code"] == 0
                booted.append((identity, boot["token"], int(player["player_id"])))
            assert len({player_id for _, _, player_id in booted}) == len(booted)

            # A same-session MID1 race must remain explicit and leave exactly
            # one credential live, regardless of which transition wins.
            race_identity = booted[0][0]
            with ThreadPoolExecutor(max_workers=2) as pool:
                race = tuple(
                    pool.map(
                        lambda index: _select(
                            base_url,
                            race_identity,
                            f"i9-http-{workers}-context-race-{index}-{uuid4().hex}",
                        ),
                        range(2),
                    )
                )
            # A loser can be rejected as CONTEXT_STALE (409) or as an already
            # revoked gameplay credential (401), depending on whether the
            # superseding transaction commits before its bootstrap lease read.
            assert all(status in (200, 401, 409) for status, _ in race)
            candidate_tokens = [body.get("token") for status, body in race if status == 200]
            assert candidate_tokens
            validation = [
                _post_engine(
                    base_url,
                    {
                        "mid": 17,
                        "token": token,
                        "region": 125,
                        "request_id": f"i9-http-{workers}-validate-{index}",
                    },
                )
                for index, token in enumerate(candidate_tokens)
            ]
            valid_tokens = [
                token
                for token, (status, body) in zip(candidate_tokens, validation, strict=True)
                if status == 200 and body.get("error_code") == 0
            ]
            assert len(valid_tokens) == 1
            booted[0] = (race_identity, valid_tokens[0], booted[0][2])

            provider = ProcessEngineProvider(settings)
            try:
                player_id = booted[0][2]
                with provider.engine().connect() as connection:
                    before_version = int(
                        connection.scalar(select(players.c.state_version).where(players.c.player_id == player_id))
                    )
                same_player_requests = (
                    {"mid": 26, "token": booted[0][1], "region": 125, "story_id": 348001, "request_id": f"i9-http-{workers}-same-story"},
                    {"mid": 26, "token": booted[0][1], "region": 125, "guide_id": 348002, "request_id": f"i9-http-{workers}-same-guide"},
                )
                independent_requests = tuple(
                    {
                        "mid": 2866,
                        "token": token,
                        "region": 125,
                        "guide_return_id": 348100 + index,
                        "request_id": f"i9-http-{workers}-independent-{index}",
                    }
                    for index, (_, token, _) in enumerate(booted[1:], start=1)
                )
                requests = same_player_requests + independent_requests
                with ThreadPoolExecutor(max_workers=len(requests)) as pool:
                    responses = tuple(pool.map(lambda body: _post_engine(base_url, body), requests))
                assert all(status == 200 and body.get("error_code") == 0 for status, body in responses)
                with provider.engine().connect() as connection:
                    row = connection.execute(
                        select(players.c.state_version, players.c.payload).where(players.c.player_id == player_id)
                    ).mappings().one()
                progression = dict(row["payload"]["progression"])
                assert progression["story_id"] == 348001
                assert progression["guide_id"] == 348002
                assert int(row["state_version"]) >= before_version + 2
            finally:
                provider.dispose()
        finally:
            process.terminate()
            try:
                process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
