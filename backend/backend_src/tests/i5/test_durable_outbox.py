from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime, timedelta, timezone

from gxb_backend.realtime.contracts import PlayerAudience, RealtimeEventIntent, RealtimeRole, RoomAudience
from gxb_backend.realtime.durable import DurableRealtimeIntentStager, RealtimeControlEventHandler, RealtimeOutboxDispatcher
from gxb_backend.transactions.models import DeliveryClass


class Schemas:
    def __init__(self): self.values=[]
    def validate(self,intent): self.values.append(intent)


class Tx:
    def __init__(self): self.out=[]
    def stage_outbox(self,intent): self.out.append(intent)


def test_durable_stager_preserves_wire_intent_but_uses_transient_outbox_semantics():
    schemas=Schemas(); tx=Tx(); stager=DurableRealtimeIntentStager(schemas)
    intent=RealtimeEventIntent(36855,{"x":1},PlayerAudience("10",roles=(RealtimeRole.WORLD,)),"sync","TRANSIENT_PRESENTATION","force_reload")
    expiry=datetime.now(timezone.utc)+timedelta(seconds=30)
    stager.stage(tx,intent,expires_at=expiry,context_id=None,priority=9)
    out=tx.out[0]
    assert out.delivery_class is DeliveryClass.TRANSIENT_REALTIME_NOTICE
    assert out.expires_at==expiry and out.priority==9
    assert out.payload["wire_delivery_class"]=="TRANSIENT_PRESENTATION"
    row={"topic":out.topic,"payload":out.payload}
    decoded=RealtimeOutboxDispatcher.decode_intent(row)
    assert decoded==intent


class FakeEngine:
    def __init__(self,events): self.events=events
    @contextmanager
    def begin(self):
        self.events.append("db.begin")
        yield object()
        self.events.append("db.commit")


class Repo:
    def __init__(self,rows,events): self.rows=tuple(rows); self.events=events
    def claim_available(self,connection,**kwargs):
        self.events.append(("claim",tuple(kwargs["delivery_classes"])))
        assert DeliveryClass.DURABLE_USER_DELIVERY not in kwargs["delivery_classes"]
        return self.rows
    def mark_dispatched(self,connection,event_id,**kwargs): self.events.append(("mark_dispatched",event_id)); return True
    def mark_done(self,connection,event_id,**kwargs): self.events.append(("done",event_id,kwargs.get("error"))); return True
    def release_for_retry(self,connection,event_id,**kwargs): self.events.append(("release",event_id)); return True
    def requeue_stale_claims(self,*args,**kwargs): return 0


class Publisher:
    def __init__(self,events): self.events=events
    def publish(self,intent): self.events.append(("publish",intent.mid)); return None


class Controls:
    def __init__(self,events,fail=False): self.events=events; self.fail=fail
    def handle(self,row):
        self.events.append(("control",row["event_id"]))
        if self.fail: raise RuntimeError("boom")
        return 2


def transient_row():
    return {"event_id":1,"topic":"realtime.event","delivery_class":DeliveryClass.TRANSIENT_REALTIME_NOTICE.value,"payload":{"mid":36855,"params":{},"audience":{"kind":"ROOM","role":"WORLD","room_id":1},"owner_domain":"sync","wire_delivery_class":"TRANSIENT_PRESENTATION","schema_key":"force_reload"}}


def control_row(event_id=2):
    return {"event_id":event_id,"topic":"identity.context_selected","delivery_class":DeliveryClass.IDEMPOTENT_REALTIME_CONTROL.value,"payload":{"context_id":"c"}}


def test_transient_dispatch_is_marked_before_socket_io_and_controls_finish_after_action():
    events=[]; repo=Repo([transient_row(),control_row()],events); engine=FakeEngine(events)
    dispatcher=RealtimeOutboxDispatcher(lambda:engine,Publisher(events),Controls(events),repository=repo)
    report=dispatcher.poll_once()
    assert report.claimed==2 and report.transient_attempted==1 and report.controls_applied==2 and report.done==2
    assert events.index(("mark_dispatched",1)) < events.index(("publish",36855))
    assert events.index(("control",2)) < next(i for i,e in enumerate(events) if isinstance(e,tuple) and e[:2]==("done",2))


def test_idempotent_control_failure_is_released_for_retry():
    events=[]; repo=Repo([control_row(5)],events); engine=FakeEngine(events)
    report=RealtimeOutboxDispatcher(lambda:engine,Publisher(events),Controls(events,fail=True),repository=repo).poll_once()
    assert report.released==1 and ("release",5) in events


def test_real_outbox_repository_claim_sql_is_realtime_class_bounded():
    from sqlalchemy.dialects import postgresql
    from gxb_backend.transactions.outbox import OutboxRepository

    class EmptyMappings:
        def all(self): return []
    class EmptyResult:
        def mappings(self): return EmptyMappings()
    class CaptureConnection:
        def __init__(self): self.compiled=None
        def execute(self, statement):
            self.compiled=statement.compile(dialect=postgresql.dialect())
            return EmptyResult()

    connection=CaptureConnection()
    rows=OutboxRepository().claim_available(
        connection, worker_id="rt", limit=7,
        delivery_classes=(DeliveryClass.TRANSIENT_REALTIME_NOTICE,DeliveryClass.IDEMPOTENT_REALTIME_CONTROL),
    )
    assert rows==()
    params=[]
    for value in connection.compiled.params.values():
        params.extend(value if isinstance(value,(list,tuple)) else [value])
    assert DeliveryClass.TRANSIENT_REALTIME_NOTICE.value in params
    assert DeliveryClass.IDEMPOTENT_REALTIME_CONTROL.value in params
    assert DeliveryClass.DURABLE_USER_DELIVERY.value not in params
    sql=str(connection.compiled)
    assert "delivery_class" in sql and "FOR UPDATE SKIP LOCKED" in sql
