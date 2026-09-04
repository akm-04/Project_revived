from __future__ import annotations

import os
import re

import pytest
from sqlalchemy import func, select

from gxb_backend.foundation.database import DatabaseSettings, ProcessEngineProvider
from gxb_backend.mail.repository import MailRepository
from gxb_backend.migration.schema import migration_runs
from gxb_backend.persistence.repositories import PostgresPlayerAggregateRepository
from gxb_backend.persistence.schema import players
from gxb_backend.runtime.schema import runtime_authority

pytestmark = pytest.mark.postgresql
_SAFE_DATABASE = re.compile(r"^[a-z_][a-z0-9_]{0,62}(?:test|_test)$")


def test_live_sqlalchemy_connection_remains_core_connection() -> None:
    raw_url = os.environ.get("GXB_TEST_DATABASE_URL", "")
    if not raw_url:
        pytest.skip("GXB_TEST_DATABASE_URL not configured")
    env = dict(os.environ); env["GXB_DATABASE_URL"] = raw_url
    settings = DatabaseSettings.from_env(env)
    assert _SAFE_DATABASE.fullmatch(settings.url.database or "")
    provider = ProcessEngineProvider(settings)
    try:
        with provider.engine().begin() as connection:
            player_id = connection.scalar(select(func.min(players.c.player_id)))
            if player_id is None:
                pytest.skip("I7 candidate has no migrated player")
            aggregate = PostgresPlayerAggregateRepository().load_for_update(connection, int(player_id))
            assert aggregate is not None
            MailRepository().list_player(connection, int(player_id))
            statuses = set(connection.scalars(select(migration_runs.c.status)))
            assert statuses <= {"DISCOVERED", "SOURCE_SNAPSHOTTED", "IMPORTING", "IMPORTED", "VALIDATING", "VALIDATED", "FAILED", "TRAFFIC_OPEN"}
            if "TRAFFIC_OPEN" in statuses:
                assert connection.scalar(select(func.count()).select_from(runtime_authority).where(runtime_authority.c.authority == "TRAFFIC_OPEN")) == 1
    finally:
        provider.dispose()
