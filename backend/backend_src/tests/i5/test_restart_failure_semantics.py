from __future__ import annotations

import time
from types import SimpleNamespace

from sqlalchemy.dialects import postgresql

from gxb_backend.realtime.gateway import RealtimeGateway, RealtimeGatewaySettings
from gxb_backend.realtime.durable import RealtimeControlEventHandler
from gxb_backend.transactions.models import OutboxState
from gxb_backend.transactions.outbox import OutboxRepository


class Result:
    def __init__(self, rowcount=0): self.rowcount=rowcount


class CaptureConnection:
    def __init__(self): self.compiled=[]
    def execute(self, statement):
        self.compiled.append(statement.compile(dialect=postgresql.dialect()))
        return Result(0)


def test_restart_reclaims_only_claimed_rows_never_dispatched_transient_attempts():
    conn=CaptureConnection()
    OutboxRepository().requeue_stale_claims(conn, stale_after_seconds=30)
    sql=str(conn.compiled[-1])
    params=list(conn.compiled[-1].params.values())
    assert OutboxState.CLAIMED.value in params
    assert OutboxState.DISPATCHED.value not in params
    assert "dispatch_state" in sql and "claimed_at" in sql


class Server:
    def __init__(self,events): self.events=events
    def start(self): self.events.append("server.start")
    def stop(self): self.events.append("server.stop")


class Dispatcher:
    def __init__(self,events): self.events=events; self.polls=0
    def recover_stale_claims(self,**kwargs): self.events.append("recover"); return 1
    def poll_once(self): self.polls+=1; self.events.append("poll")


class Sweeper:
    def sweep_once(self): return None


class FlakyWakeup:
    def __init__(self,events): self.events=events; self.opens=0; self.waits=0
    def open(self): self.opens+=1; self.events.append(f"open{self.opens}")
    def wait(self,timeout):
        self.waits+=1; self.events.append(f"wait{self.waits}")
        if self.waits==1: raise OSError("listener dropped")
        time.sleep(min(timeout,.003)); return False
    def close(self): self.events.append("close")


def test_wakeup_failure_reconnects_and_periodic_polling_continues():
    events=[]; dispatcher=Dispatcher(events); wakeup=FlakyWakeup(events)
    gateway=RealtimeGateway(
        Server(events), dispatcher, Sweeper(), wakeup=wakeup,
        settings=RealtimeGatewaySettings(.01,.1,30),
    )
    gateway.start(); time.sleep(.055); gateway.stop()
    assert wakeup.opens>=2
    assert dispatcher.polls>=2
    assert events.index("recover") < events.index("server.start")


class Controls:
    def close_context_room(self,*args,**kwargs): return 1


def test_room_invalidation_rejects_transient_connection_id_only_payload():
    handler=RealtimeControlEventHandler(Controls())
    row={"topic":"realtime.room_invalidated","payload":{"connection_id":"socket-123"}}
    try:
        handler.handle(row)
    except ValueError as exc:
        assert "context_id, role and room_id" in str(exc)
    else:
        raise AssertionError("transient connection_id must not be durable room authority")


def test_room_invalidation_accepts_durable_context_role_room_identity():
    calls=[]
    class C:
        def close_context_room(self,context_id,**kwargs): calls.append((context_id,kwargs)); return 1
    handler=RealtimeControlEventHandler(C())
    row={
        "topic":"realtime.room_invalidated",
        "context_id":"ctx-1",
        "payload":{"role":"GUILD","room_id":77,"reason":"MEMBERSHIP_CHANGED"},
    }
    assert handler.handle(row)==1
    assert calls[0][0]=="ctx-1"
    assert calls[0][1]["room_id"]==77
    assert calls[0][1]["role"].value=="GUILD"
