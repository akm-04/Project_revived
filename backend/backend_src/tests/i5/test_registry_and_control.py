from __future__ import annotations

from dataclasses import dataclass

from gxb_backend.realtime.contracts import AuthenticatedPlayerIdentity, RealtimeRole
from gxb_backend.realtime.control import PrivateControlKind, RealtimeControlPublisher
from gxb_backend.realtime.session import AuthenticatedRealtimeSessionRegistry, RealtimeSession


class FakeSocket:
    def __init__(self): self.closed=False; self.sent=[]
    def sendall(self, data): self.sent.append(bytes(data))
    def shutdown(self, how): pass
    def close(self): self.closed=True


def _session(cid: str, *, session="s1", context="c1", role=RealtimeRole.WORLD):
    identity=AuthenticatedPlayerIdentity("u1","","1001",1,0,session_id=session,context_id=context)
    return RealtimeSession(cid,identity,role,1,FakeSocket(),1.0,1.0)


def test_registry_indexes_session_context_and_newest_context_role_wins():
    registry=AuthenticatedRealtimeSessionRegistry()
    old=_session("old")
    registry.register_newest(old)
    guild=_session("guild", role=RealtimeRole.GUILD)
    registry.register_newest(guild)
    newer=_session("new")
    evicted=registry.register_newest(newer)
    assert evicted is old
    assert registry.get("old") is None
    assert registry.connection_for_context_role("c1",RealtimeRole.WORLD)=="new"
    assert set(registry.connections_for_context("c1"))=={"new","guild"}
    assert set(registry.connections_for_session("s1"))=={"new","guild"}


def test_different_contexts_do_not_evict_each_other():
    registry=AuthenticatedRealtimeSessionRegistry()
    a=_session("a",context="c1")
    b=_session("b",context="c2")
    assert registry.register_newest(a) is None
    assert registry.register_newest(b) is None
    assert len(registry)==2


def test_control_close_removes_transient_authority_before_socket_drain():
    registry=AuthenticatedRealtimeSessionRegistry(); session=_session("x")
    registry.register_newest(session)
    controls=RealtimeControlPublisher(registry)
    assert controls.close_session(session,kind=PrivateControlKind.CONNECTION_SUPERSEDED,reason="new wins")
    assert registry.get("x") is None
    # frame + graceful sentinel are queued; raw auth bearer is not part of identity
    assert session.identity.sid==""
    assert session._queue.qsize()==2


class FakeTimer:
    created=[]
    def __init__(self, delay, callback):
        self.delay=delay; self.callback=callback; self.daemon=False; self.started=False
        self.__class__.created.append(self)
    def start(self): self.started=True


def test_control_close_arms_bounded_hard_close_after_best_effort_drain():
    FakeTimer.created.clear()
    registry=AuthenticatedRealtimeSessionRegistry(); session=_session("bounded")
    registry.register_newest(session)
    controls=RealtimeControlPublisher(registry,drain_timeout_seconds=0.25,timer_factory=FakeTimer)
    assert controls.close_session(session,kind=PrivateControlKind.AUTH_CONTEXT_INVALIDATED,reason="stale")
    assert registry.get("bounded") is None
    assert len(FakeTimer.created)==1
    timer=FakeTimer.created[0]
    assert timer.started and timer.daemon and timer.delay==0.25
    assert not session.sock.closed
    timer.callback()
    assert session.sock.closed
