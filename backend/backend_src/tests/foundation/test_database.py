from __future__ import annotations

import pytest

from gxb_backend.foundation import database
from gxb_backend.foundation.database import (
    DatabaseConfigurationError,
    DatabaseSettings,
    ProcessEngineProvider,
)


def test_settings_normalize_psycopg_and_hide_password() -> None:
    settings = DatabaseSettings.from_env(
        {
            "GXB_DATABASE_URL": "postgresql://gxb:secret@db.example/gxb",
            "GXB_DATABASE_SCHEMA": "gxb",
            "GXB_DATABASE_POOL_SIZE": "3",
            "GXB_DATABASE_MAX_OVERFLOW": "1",
            "GXB_DATABASE_POOL_TIMEOUT": "2.5",
        }
    )
    assert settings.url.drivername == "postgresql+psycopg"
    assert "secret" not in settings.safe_url
    assert "***" in settings.safe_url
    assert settings.pool_size == 3
    assert settings.max_overflow == 1
    assert settings.pool_timeout_seconds == 2.5


@pytest.mark.parametrize(
    "env",
    [
        {},
        {"GXB_DATABASE_URL": "sqlite:///not-supported.db"},
        {"GXB_DATABASE_URL": "postgresql:///gxb", "GXB_DATABASE_SCHEMA": "Bad-Name"},
        {"GXB_DATABASE_URL": "postgresql:///gxb", "GXB_DATABASE_POOL_SIZE": "0"},
        {"GXB_DATABASE_URL": "postgresql:///gxb", "GXB_DATABASE_MAX_OVERFLOW": "-1"},
    ],
)
def test_invalid_settings_are_rejected(env: dict[str, str]) -> None:
    with pytest.raises((DatabaseConfigurationError, ValueError)):
        DatabaseSettings.from_env(env)


class FakeEngine:
    def __init__(self) -> None:
        self.disposals: list[bool] = []

    def dispose(self, close: bool = True) -> None:
        self.disposals.append(close)


def test_engine_is_lazy_and_recreated_after_fork(monkeypatch: pytest.MonkeyPatch) -> None:
    created: list[FakeEngine] = []

    def fake_create_engine(*args, **kwargs):  # type: ignore[no-untyped-def]
        created.append(FakeEngine())
        return created[-1]

    pid = [100]
    monkeypatch.setattr(database, "create_engine", fake_create_engine)
    monkeypatch.setattr(database.os, "getpid", lambda: pid[0])
    settings = DatabaseSettings.from_env({"GXB_DATABASE_URL": "postgresql:///gxb"})
    provider = ProcessEngineProvider(settings)
    assert created == []
    assert provider.engine() is provider.engine()
    assert len(created) == 1

    pid[0] = 101
    assert provider.engine() is created[1]
    assert created[0].disposals == [False]
    provider.dispose()
    assert created[1].disposals == [True]

