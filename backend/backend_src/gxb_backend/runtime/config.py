"""Environment contract for the I9 concurrency-proven production reference."""
from __future__ import annotations
import os
from dataclasses import dataclass
from datetime import timedelta
from pathlib import Path

from gxb_backend.foundation.database import DatabaseSettings
from gxb_backend.identity.models import IdentityPolicy


class RuntimeConfigurationError(ValueError): pass


PROVEN_HTTP_WORKER_STAGES = (1, 2, 4)
MAX_PROVEN_HTTP_WORKERS = max(PROVEN_HTTP_WORKER_STAGES)


@dataclass(frozen=True, slots=True)
class ProductionRuntimeSettings:
    database: DatabaseSettings
    http_workers: int
    anonymous_account_uid: str
    identity_policy: IdentityPolicy
    maintenance_file: Path

    @property
    def maintenance_active(self) -> bool: return self.maintenance_file.is_file()

    @classmethod
    def from_env(cls, env=None, *, application_name: str = "gxb-http"):
        source = dict(os.environ if env is None else env)
        source["GXB_DATABASE_APPLICATION_NAME"] = application_name
        database = DatabaseSettings.from_env(source)
        try:
            workers = int(source.get("GXB_HTTP_WORKERS", "1"))
        except ValueError as exc:
            raise RuntimeConfigurationError("GXB_HTTP_WORKERS must be an integer") from exc
        if workers not in PROVEN_HTTP_WORKER_STAGES:
            raise RuntimeConfigurationError(
                "GXB_HTTP_WORKERS must use a proven gradual stage: "
                + ", ".join(str(value) for value in PROVEN_HTTP_WORKER_STAGES)
            )
        def seconds(name: str, default: int) -> timedelta:
            try: value = int(source.get(name, str(default)))
            except ValueError as exc: raise RuntimeConfigurationError(f"{name} must be an integer") from exc
            if value <= 0: raise RuntimeConfigurationError(f"{name} must be positive")
            return timedelta(seconds=value)
        return cls(
            database=database,
            http_workers=workers,
            anonymous_account_uid=str(source.get("GXB_ANONYMOUS_ACCOUNT_UID", "13371337")),
            maintenance_file=Path(source.get("GXB_MAINTENANCE_FILE", "/run/gxb/maintenance")),
            identity_policy=IdentityPolicy(
                absolute_session_ttl=seconds("GXB_SESSION_ABSOLUTE_TTL_SECONDS", 30 * 86400),
                idle_session_ttl=seconds("GXB_SESSION_IDLE_TTL_SECONDS", 24 * 3600),
                activity_write_interval=seconds("GXB_SESSION_ACTIVITY_WRITE_SECONDS", 60),
            ),
        )
