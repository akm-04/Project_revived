"""Dedicated I6 background process composition.

One process may host two independent durable lanes: scheduled_jobs and derived
projection outbox work.  Each lane keeps its own short claim/settle
transactions; neither loop owns canonical gameplay state.
"""
from __future__ import annotations

from dataclasses import dataclass
import time
from typing import Callable

from gxb_backend.projections.outbox import ProjectionOutboxWorker
from .worker import SchedulerWorker


@dataclass(frozen=True)
class SchedulerProcessSettings:
    poll_interval_seconds: float = 1.0
    projection_stale_claim_seconds: int = 30

    def __post_init__(self) -> None:
        if self.poll_interval_seconds <= 0:
            raise ValueError("poll_interval_seconds must be > 0")
        if isinstance(self.projection_stale_claim_seconds, bool) or self.projection_stale_claim_seconds <= 0:
            raise ValueError("projection_stale_claim_seconds must be positive")


class SchedulerProcess:
    """Baseline one-process composition for scheduled + projection lanes.

    ``start`` is intentionally not wired into the default runtime in I6.  I8
    packaging will decide process supervision/startup.
    """

    def __init__(
        self,
        scheduler: SchedulerWorker,
        projections: ProjectionOutboxWorker,
        *,
        settings: SchedulerProcessSettings | None = None,
        sleep: Callable[[float], None] = time.sleep,
    ) -> None:
        self.scheduler = scheduler
        self.projections = projections
        self.settings = settings or SchedulerProcessSettings()
        self.sleep = sleep

    def recover_startup(self) -> int:
        return self.projections.recover_stale_claims(
            stale_after_seconds=self.settings.projection_stale_claim_seconds
        )

    def run_once(self) -> tuple[int, int]:
        scheduled = int(self.scheduler.run_once())
        projected = int(self.projections.poll_once().claimed)
        return scheduled, projected

    def run_forever(self, *, stop: Callable[[], bool] = lambda: False) -> None:
        self.recover_startup()
        while not stop():
            scheduled, projected = self.run_once()
            if scheduled == 0 and projected == 0:
                self.sleep(self.settings.poll_interval_seconds)
