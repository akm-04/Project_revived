"""Authoritative server-clock primitive for request-scoped temporal policies."""
from __future__ import annotations

import time
from typing import Callable


class ServerClock:
    """Server epoch source; device/client-local time is never accepted as authority."""

    def __init__(self, now_fn: Callable[[], int | float] | None = None) -> None:
        self._now_fn = now_fn or time.time

    def now(self) -> int:
        return int(self._now_fn())


class ServerDayClock:
    """Stateless source-day math for the canonical 05:00 GMT+8 boundary.

    The recovered client formula is ``floor((unix_timestamp + 3h) / 86400)``.
    Keeping the shift explicit avoids dependence on host timezone or DST.
    """

    DAY_SECONDS = 86_400
    SOURCE_SHIFT_SECONDS = 3 * 3_600

    def __init__(self, clock: ServerClock | None = None) -> None:
        self.clock = clock or ServerClock()

    def now(self) -> int:
        return self.clock.now()

    def day_id(self, epoch: int | float | None = None) -> int:
        value = self.now() if epoch is None else int(epoch)
        return (value + self.SOURCE_SHIFT_SECONDS) // self.DAY_SECONDS

    def day_start_epoch(self, day_id: int) -> int:
        return int(day_id) * self.DAY_SECONDS - self.SOURCE_SHIFT_SECONDS

    def next_day_start_epoch(self, epoch: int | float | None = None) -> int:
        return self.day_start_epoch(self.day_id(epoch) + 1)
