from __future__ import annotations

import os
import re

import pytest
from alembic import command
from alembic.config import Config
from alembic.script import ScriptDirectory
from sqlalchemy import text

from gxb_backend.foundation.database import DatabaseSettings, ProcessEngineProvider
from gxb_backend.foundation.schema import ALEMBIC_VERSION_TABLE


pytestmark = pytest.mark.postgresql
_SAFE_DATABASE = re.compile(r"^[a-z_][a-z0-9_]{0,62}(?:test|_test)$")


def test_i0_migration_and_read_committed_probe() -> None:
    raw_url = os.environ.get("GXB_TEST_DATABASE_URL", "")
    if not raw_url:
        pytest.skip("GXB_TEST_DATABASE_URL not configured")
    env = dict(os.environ)
    env["GXB_DATABASE_URL"] = raw_url
    settings = DatabaseSettings.from_env(env)
    database_name = settings.url.database or ""
    assert _SAFE_DATABASE.fullmatch(database_name), "integration DB must be explicitly disposable"

    config = Config("alembic.ini")
    expected_head = ScriptDirectory.from_config(config).get_current_head()
    assert expected_head is not None
    command.upgrade(config, "head")
    provider = ProcessEngineProvider(settings)
    try:
        probe = provider.probe()
        assert probe["database"] == database_name
        assert probe["isolation"] == "read committed"
        with provider.engine().connect() as connection:
            schema_exists = connection.scalar(
                text("SELECT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = :name)"),
                {"name": settings.schema},
            )
            revision = connection.scalar(text(f'SELECT version_num FROM "{ALEMBIC_VERSION_TABLE}"'))
        assert schema_exists is True
        assert revision == expected_head
    finally:
        provider.dispose()
