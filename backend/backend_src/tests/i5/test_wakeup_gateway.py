from __future__ import annotations

import time
from types import SimpleNamespace

from gxb_backend.realtime.gateway import RealtimeGateway, RealtimeGatewaySettings
from gxb_backend.realtime.wakeup import PsycopgOutboxWakeupListener


class Generator:
    def __init__(self,values): self.values=values; self.closed=False
    def __iter__(self): return iter(self.values)
    def close(self): self.closed=True


class Conn:
    def __init__(self): self.executed=[]; self.calls=[]; self.closed=False; self.gen=None
    def execute(self,sql): self.executed.append(sql)
    def notifies(self,**kwargs): self.calls.append(kwargs); self.gen=Generator([SimpleNamespace(channel="gxb_outbox",payload="wake")]); return self.gen
    def close(self): self.closed=True


def test_psycopg_wakeup_uses_autocommit_listen_and_timeout_generator():
    conn=Conn(); calls=[]
    def factory(conninfo,**kwargs): calls.append((conninfo,kwargs)); return conn
    listener=PsycopgOutboxWakeupListener("postgresql://secret@db/gxb",connect_factory=factory)
    listener.open(); assert calls[0][1]["autocommit"] is True
    assert conn.executed==['LISTEN "gxb_outbox"']
    assert listener.wait(.25) is True
    assert conn.calls==[{"timeout":.25,"stop_after":1}]
    assert conn.gen.closed
    listener.close(); assert conn.closed


class FakeServer:
    def __init__(self,events): self.events=events
    def start(self): self.events.append("server.start")
    def stop(self): self.events.append("server.stop")


class FakeDispatcher:
    def __init__(self,events): self.events=events; self.polls=0
    def recover_stale_claims(self,**kw): self.events.append("recover"); return 0
    def poll_once(self): self.polls+=1; self.events.append("poll")


class FakeSweeper:
    def __init__(self,events): self.events=events
    def sweep_once(self): self.events.append("sweep")


class FakeWakeup:
    def __init__(self,events): self.events=events; self.opened=False
    def open(self): self.opened=True; self.events.append("listen.open")
    def wait(self,timeout): self.events.append("listen.wait"); time.sleep(min(timeout,.005)); return False
    def close(self): self.events.append("listen.close")


def test_gateway_establishes_listen_before_initial_poll_and_polls_even_when_notify_missed():
    events=[]; d=FakeDispatcher(events); w=FakeWakeup(events)
    g=RealtimeGateway(FakeServer(events),d,FakeSweeper(events),wakeup=w,settings=RealtimeGatewaySettings(.01,.05,10))
    g.start()
    time.sleep(.045)
    g.stop()
    assert events.index("listen.open") < events.index("recover") < events.index("poll") < events.index("server.start")
    assert d.polls>=2, events
