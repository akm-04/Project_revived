"""Process-local synchronous SQLAlchemy/psycopg foundation.

No Engine is created at import time.  Callers own a ProcessEngineProvider and
must construct it after worker creation.  If a provider is nevertheless copied
across fork, it disposes the inherited pool without closing the parent's live
connections and creates a fresh child-process Engine.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Mapping

from sqlalchemy import Engine, create_engine, text
from sqlalchemy.engine import URL, make_url

from .schema import DEFAULT_SCHEMA, validate_schema_name


class DatabaseConfigurationError(ValueError):
    pass


@dataclass(frozen=True)
class DatabaseSettings:
    url: URL
    schema: str = DEFAULT_SCHEMA
    application_name: str = "gxb-http"
    pool_size: int = 4
    max_overflow: int = 0
    pool_timeout_seconds: float = 5.0

    @classmethod
    def from_env(
        cls,
        env: Mapping[str, str] | None = None,
        *,
        prefix: str = "GXB_DATABASE_",
    ) -> "DatabaseSettings":
        source = os.environ if env is None else env
        raw_url = str(source.get(f"{prefix}URL", "")).strip()
        if not raw_url:
            raise DatabaseConfigurationError(f"{prefix}URL is required")
        url = make_url(raw_url)
        if url.drivername not in {"postgresql", "postgresql+psycopg"}:
            raise DatabaseConfigurationError("only synchronous PostgreSQL/psycopg is supported")
        if url.drivername == "postgresql":
            url = url.set(drivername="postgresql+psycopg")

        def integer(name: str, default: int, *, minimum: int = 0) -> int:
            try:
                value = int(source.get(f"{prefix}{name}", str(default)))
            except (TypeError, ValueError) as exc:
                raise DatabaseConfigurationError(f"{prefix}{name} must be an integer") from exc
            if value < minimum:
                raise DatabaseConfigurationError(f"{prefix}{name} must be >= {minimum}")
            return value

        try:
            timeout = float(source.get(f"{prefix}POOL_TIMEOUT", "5"))
        except (TypeError, ValueError) as exc:
            raise DatabaseConfigurationError(f"{prefix}POOL_TIMEOUT must be numeric") from exc
        if timeout <= 0:
            raise DatabaseConfigurationError(f"{prefix}POOL_TIMEOUT must be > 0")

        return cls(
            url=url,
            schema=validate_schema_name(source.get(f"{prefix}SCHEMA", DEFAULT_SCHEMA)),
            application_name=str(source.get(f"{prefix}APPLICATION_NAME", "gxb-http")).strip()
            or "gxb-http",
            pool_size=integer("POOL_SIZE", 4, minimum=1),
            max_overflow=integer("MAX_OVERFLOW", 0),
            pool_timeout_seconds=timeout,
        )

    @property
    def safe_url(self) -> str:
        return self.url.render_as_string(hide_password=True)

    def safe_summary(self) -> dict[str, object]:
        return {
            "url": self.safe_url,
            "schema": self.schema,
            "application_name": self.application_name,
            "pool_size": self.pool_size,
            "max_overflow": self.max_overflow,
            "pool_timeout_seconds": self.pool_timeout_seconds,
        }


class ProcessEngineProvider:
    """Own one bounded SQLAlchemy Engine/pool per OS process."""

    def __init__(self, settings: DatabaseSettings) -> None:
        self.settings = settings
        self._pid: int | None = None
        self._engine: Engine | None = None

    def _build(self) -> Engine:
        return create_engine(
            self.settings.url,
            isolation_level="READ COMMITTED",
            pool_pre_ping=True,
            pool_size=self.settings.pool_size,
            max_overflow=self.settings.max_overflow,
            pool_timeout=self.settings.pool_timeout_seconds,
            connect_args={"application_name": self.settings.application_name},
        )

    def engine(self) -> Engine:
        pid = os.getpid()
        if self._engine is not None and self._pid != pid:
            self._engine.dispose(close=False)
            self._engine = None
        if self._engine is None:
            self._engine = self._build()
            self._pid = pid
        return self._engine

    def probe(self) -> dict[str, str]:
        with self.engine().connect() as connection:
            result = connection.execute(
                text(
                    "SELECT current_database(), current_user, "
                    "current_setting('transaction_isolation')"
                )
            ).one()
        return {
            "database": str(result[0]),
            "user": str(result[1]),
            "isolation": str(result[2]),
        }

    def dispose(self) -> None:
        if self._engine is not None:
            self._engine.dispose()
        self._engine = None
        self._pid = None
