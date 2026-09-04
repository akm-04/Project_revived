"""Pass345 derived-projection outbox lane, partitioned from realtime/mail."""
from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Callable, Mapping
from gxb_backend.transactions.models import DeliveryClass, OutboxIntent
from gxb_backend.transactions.outbox import OutboxRepository

PROJECTION_DELIVERY_CLASSES=(DeliveryClass.DERIVED_PROJECTION_WORK,)

class ProjectionIntentStager:
    def stage(self, transaction, *, topic:str, resource_kind:str, resource_key:str, payload:Mapping[str,Any], priority:int=100)->None:
        transaction.stage_outbox(OutboxIntent(topic=topic,resource_kind=resource_kind,resource_key=resource_key,payload=dict(payload),delivery_class=DeliveryClass.DERIVED_PROJECTION_WORK,priority=int(priority)))

@dataclass(frozen=True)
class ProjectionDispatchReport:
    claimed:int=0; applied:int=0; released:int=0

class ProjectionOutboxWorker:
    def __init__(self,engine_provider,handlers:Mapping[str,Callable[[Mapping[str,Any]],None]],*,repository:OutboxRepository|None=None,worker_id:str='gxb-projection',batch_size:int=100)->None:
        self.engine_provider=engine_provider; self.handlers=dict(handlers); self.repository=repository or OutboxRepository(); self.worker_id=str(worker_id); self.batch_size=int(batch_size)
        if not self.worker_id.strip() or self.batch_size<=0: raise ValueError('invalid projection worker configuration')
    def _engine(self):
        p=self.engine_provider; return p() if callable(p) else p.engine()
    def recover_stale_claims(self, *, stale_after_seconds:int)->int:
        engine=self._engine()
        with engine.begin() as connection:
            return self.repository.requeue_stale_claims(connection, stale_after_seconds=int(stale_after_seconds))

    def poll_once(self)->ProjectionDispatchReport:
        engine=self._engine()
        with engine.begin() as connection:
            rows=self.repository.claim_available(connection,worker_id=self.worker_id,limit=self.batch_size,delivery_classes=PROJECTION_DELIVERY_CLASSES)
        applied=released=0
        for row in rows:
            event_id=int(row['event_id']); error=None
            try:
                handler=self.handlers.get(str(row['topic']))
                if handler is None: raise LookupError(f"no projection handler for topic={row['topic']}")
                handler(row)
            except Exception as exc: error=exc
            with engine.begin() as connection:
                if error is None:
                    if not self.repository.mark_done(connection,event_id,worker_id=self.worker_id): raise RuntimeError(f'lost projection outbox claim {event_id}')
                    applied+=1
                else:
                    if not self.repository.release_for_retry(connection,event_id,worker_id=self.worker_id,error=str(error)): raise RuntimeError(f'lost projection outbox claim {event_id}')
                    released+=1
        return ProjectionDispatchReport(len(rows),applied,released)
