"""Alembic environment for the PostgreSQL-only gameplay authority."""

from __future__ import annotations

import os
from logging.config import fileConfig

from alembic import context

from gxb_backend.foundation.database import DatabaseSettings, ProcessEngineProvider
from gxb_backend.foundation.schema import ALEMBIC_VERSION_TABLE, load_i8_runtime_tables, metadata


config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

load_i8_runtime_tables()
target_metadata = metadata


def _settings() -> DatabaseSettings:
    env = dict(os.environ)
    if not env.get("GXB_DATABASE_URL") and env.get("GXB_TEST_DATABASE_URL"):
        env["GXB_DATABASE_URL"] = env["GXB_TEST_DATABASE_URL"]
    return DatabaseSettings.from_env(env)


def run_migrations_offline() -> None:
    settings = _settings()
    config.attributes["gxb_schema"] = settings.schema
    context.configure(
        url=settings.url.render_as_string(hide_password=False),
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        version_table=ALEMBIC_VERSION_TABLE,
        compare_type=True,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    provider = ProcessEngineProvider(_settings())
    config.attributes["gxb_schema"] = provider.settings.schema
    try:
        with provider.engine().connect() as connection:
            context.configure(
                connection=connection,
                target_metadata=target_metadata,
                version_table=ALEMBIC_VERSION_TABLE,
                compare_type=True,
            )
            with context.begin_transaction():
                context.run_migrations()
    finally:
        provider.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
