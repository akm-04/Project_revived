"""Dedicated I6 SchedulerWorker over the I2 durable scheduled_jobs queue."""
from __future__ import annotations

from dataclasses import dataclass
import time
from typing import Any, Callable, Mapping, Protocol
from sqlalchemy.engine import Engine

from gxb_backend.transactions.jobs import ScheduledJobRepository


class ScheduledJobHandler(Protocol):
    """Domain handler owns its fresh ResourceTransaction and revalidation."""
    def __call__(self, row: Mapping[str, Any]) -> None: ...


@dataclass(frozen=True)
class SchedulerSettings:
    worker_id: str
    lease_seconds: int = 30
    batch_size: int = 25
    max_attempts: int = 5
    poll_interval_seconds: float = 1.0
    def __post_init__(self)->None:
        if not str(self.worker_id).strip(): raise ValueError("worker_id is required")
        for name in ("lease_seconds","batch_size","max_attempts"):
            if isinstance(getattr(self,name),bool) or int(getattr(self,name))<=0: raise ValueError(f"{name} must be positive")
        if self.poll_interval_seconds<=0: raise ValueError("poll_interval_seconds must be positive")


class SchedulerWorker:
    """Claim short, execute outside queue txn, settle status short.

    The queue is at-least-once *attempt* authority only. Domain handlers must
    make externally effective transitions idempotent through their own state
    machines/receipts/delivery keys.
    """
    def __init__(self, engine_provider:Callable[[],Engine], repository:ScheduledJobRepository, settings:SchedulerSettings, handlers:Mapping[str,ScheduledJobHandler], *, sleep:Callable[[float],None]=time.sleep)->None:
        self.engine_provider=engine_provider; self.repository=repository; self.settings=settings; self.handlers=dict(handlers); self.sleep=sleep
    def _claim(self)->tuple[Mapping[str,Any],...]:
        engine=self.engine_provider()
        with engine.begin() as connection:
            return self.repository.claim_due(connection,worker_id=self.settings.worker_id,lease_seconds=self.settings.lease_seconds,limit=self.settings.batch_size)
    def _settle(self,row:Mapping[str,Any],error:Exception|None)->None:
        engine=self.engine_provider(); job_id=int(row["job_id"]); attempts=int(row.get("attempt_count",0) or 0)
        with engine.begin() as connection:
            if error is None:
                if not self.repository.mark_succeeded(connection,job_id,worker_id=self.settings.worker_id): raise RuntimeError(f"lost scheduler lease for job {job_id}")
            elif attempts>=self.settings.max_attempts:
                if not self.repository.mark_dead(connection,job_id,worker_id=self.settings.worker_id,error=str(error)):
                    raise RuntimeError(f"lost scheduler lease for job {job_id}")
            else:
                if not self.repository.mark_retry(connection,job_id,worker_id=self.settings.worker_id,error=str(error)):
                    raise RuntimeError(f"lost scheduler lease for job {job_id}")
    def run_once(self)->int:
        rows=self._claim()
        for row in rows:
            error=None
            handler=self.handlers.get(str(row["job_type"]))
            try:
                if handler is None: raise LookupError(f"no scheduler handler for job_type={row['job_type']}")
                handler(row)
            except Exception as exc: error=exc
            self._settle(row,error)
        return len(rows)
    def run_forever(self, *, stop:Callable[[],bool]=lambda:False)->None:
        while not stop():
            if self.run_once()==0:self.sleep(self.settings.poll_interval_seconds)
