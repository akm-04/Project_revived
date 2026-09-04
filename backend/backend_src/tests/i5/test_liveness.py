from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from uuid import uuid4

from gxb_backend.identity.models import IdentityPolicy
from gxb_backend.realtime.contracts import AuthenticatedPlayerIdentity, RealtimeRole
from gxb_backend.realtime.liveness import RelationalRealtimeLivenessReader, RealtimeLivenessStatus, RealtimeLivenessSweeper
from gxb_backend.realtime.session import AuthenticatedRealtimeSessionRegistry, RealtimeSession


NOW=datetime(2026,9,3,tzinfo=timezone.utc)
POLICY=IdentityPolicy(absolute_session_ttl=timedelta(days=30),idle_session_ttl=timedelta(hours=2),activity_write_interval=timedelta(minutes=5))


def row(session="s",context="c",**overrides):
    base={"session_id":session,"context_session_id":session,"context_id":context,"last_activity_at":NOW-timedelta(minutes=1),"absolute_expires_at":NOW+timedelta(days=1),"revoked_at":None,"ended_at":None}
    base.update(overrides); return base


def test_liveness_evaluation_fails_closed_for_missing_revoked_expired_idle_and_ended():
    reader=RelationalRealtimeLivenessReader()
    requested=[("a","ca"),("b","cb"),("c","cc"),("d","cd"),("e","ce"),("f","cf")]
    rows=[
      row("a","ca"),
      row("b","cb",revoked_at=NOW),
      row("c","cc",absolute_expires_at=NOW),
      row("d","cd",last_activity_at=NOW-timedelta(hours=3)),
      row("e","ce",ended_at=NOW),
    ]
    got=reader.evaluate(requested,rows,policy=POLICY,now=NOW)
    assert got[("a","ca")].live
    assert got[("b","cb")].reason=="SESSION_REVOKED"
    assert got[("c","cc")].reason=="SESSION_EXPIRED"
    assert got[("d","cd")].reason=="SESSION_IDLE_EXPIRED"
    assert got[("e","ce")].reason=="CONTEXT_ENDED"
    assert got[("f","cf")].reason=="AUTHORITY_MISSING"


class Sock:
    def shutdown(self,*a): pass
    def close(self): pass


def make_session(cid="x",sid="s",ctx="c"):
    return RealtimeSession(cid,AuthenticatedPlayerIdentity("u","","1001",1,0,session_id=sid,context_id=ctx),RealtimeRole.WORLD,1,Sock(),1,1)


class Controls:
    def __init__(self,registry): self.registry=registry; self.closed=[]
    def close_context(self,context_id,*,reason):
        ids=self.registry.connections_for_context(context_id); self.closed.append((context_id,reason,ids))
        for cid in ids: self.registry.remove(cid)
        return len(ids)
    def close_session(self,session,*,kind,reason): self.closed.append((session.connection_id,reason)); self.registry.remove(session.connection_id); return True


class Reader:
    def __init__(self,statuses=None,error=None): self.statuses=statuses or {}; self.error=error
    def read(self,*a,**k):
        if self.error: raise self.error
        return self.statuses


class Engine:
    @contextmanager
    def connect(self): yield object()


def test_sweeper_closes_durable_invalid_context():
    reg=AuthenticatedRealtimeSessionRegistry(); reg.register_newest(make_session())
    controls=Controls(reg)
    statuses={("s","c"):RealtimeLivenessStatus("s","c",False,"CONTEXT_ENDED")}
    sweep=RealtimeLivenessSweeper(lambda:Engine(),reg,controls,policy=POLICY,reader=Reader(statuses),database_grace_seconds=10)
    report=sweep.sweep_once()
    assert report.database_available and report.closed==1 and len(reg)==0


def test_database_outage_uses_short_grace_then_fails_closed():
    reg=AuthenticatedRealtimeSessionRegistry(); reg.register_newest(make_session())
    controls=Controls(reg); times=iter([100.0,106.0])
    sweep=RealtimeLivenessSweeper(lambda:Engine(),reg,controls,policy=POLICY,reader=Reader(error=RuntimeError("db down")),database_grace_seconds=5,monotonic=lambda:next(times))
    first=sweep.sweep_once()
    assert not first.database_available and not first.outage_grace_exhausted and len(reg)==1
    second=sweep.sweep_once()
    assert second.outage_grace_exhausted and second.closed==1 and len(reg)==0
