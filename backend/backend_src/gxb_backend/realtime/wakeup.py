"""PostgreSQL LISTEN/NOTIFY wakeup adapter for the durable realtime outbox."""
from __future__ import annotations

import re
from typing import Callable, Protocol


_CHANNEL_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_$]*$")


class OutboxWakeupSource(Protocol):
    def open(self) -> None: ...
    def wait(self, timeout: float) -> bool: ...
    def close(self) -> None: ...


class PsycopgOutboxWakeupListener:
    """Dedicated autocommit LISTEN connection; notifications carry no truth."""

    def __init__(
        self,
        conninfo: str,
        *,
        channel: str = "gxb_outbox",
        connect_factory: Callable | None = None,
    ) -> None:
        if not _CHANNEL_RE.fullmatch(str(channel)):
            raise ValueError("invalid PostgreSQL LISTEN channel")
        self.conninfo = str(conninfo)
        self.channel = str(channel)
        self._connect_factory = connect_factory
        self._connection = None

    def open(self) -> None:
        if self._connection is not None:
            return
        factory = self._connect_factory
        if factory is None:
            import psycopg
            factory = psycopg.connect
        connection = factory(self.conninfo, autocommit=True)
        try:
            connection.execute(f'LISTEN "{self.channel}"')
        except Exception:
            try:
                connection.close()
            finally:
                raise
        self._connection = connection

    def wait(self, timeout: float) -> bool:
        if self._connection is None:
            raise RuntimeError("wakeup listener is not open")
        timeout = max(0.0, float(timeout))
        notifications = self._connection.notifies(timeout=timeout, stop_after=1)
        try:
            for notice in notifications:
                if str(getattr(notice, "channel", "")) == self.channel:
                    return True
            return False
        finally:
            close = getattr(notifications, "close", None)
            if callable(close):
                close()

    def close(self) -> None:
        connection, self._connection = self._connection, None
        if connection is not None:
            connection.close()
