from __future__ import annotations

from contextlib import contextmanager
from types import SimpleNamespace

from sqlalchemy.dialects import postgresql

from gxb_backend.realtime.contracts import (
    AuthenticatedPlayerIdentity,
    RealtimeEventIntent,
    RealtimeRole,
    RoomAudience,
)
from gxb_backend.realtime.control import PRIVATE_SERVER_CONTROL_MID, PrivateControlKind, RealtimeControlPublisher
from gxb_backend.realtime.durable import RealtimeControlEventHandler, RealtimeOutboxDispatcher
from gxb_backend.realtime.publisher import TypedRealtimeEventPublisher
from gxb_backend.realtime.session import AuthenticatedRealtimeSessionRegistry, RealtimeSession
from gxb_backend.transactions.models import DeliveryClass
from gxb_backend.transactions.outbox import OutboxRepository


class Sock:
    def __init__(self):
        self.closed = False
        self.sent = []

    def sendall(self, data):
        self.sent.append(bytes(data))

    def shutdown(self, how):
        pass

    def close(self):
        self.closed = True


def session(cid, *, context="c1", account_session="s1", role=RealtimeRole.WORLD, room=1, player="1001"):
    return RealtimeSession(
        cid,
        AuthenticatedPlayerIdentity(
            "u1", "", player, 1, 77,
            session_id=account_session,
            context_id=context,
        ),
        role,
        room,
        Sock(),
        1.0,
        1.0,
    )


class Encoder:
    def encode(self, mid, params, sequence=0):
        return f"{mid}:{params}".encode()


class Schemas:
    def validate(self, intent):
        pass

    def descriptor(self, mid):
        return SimpleNamespace(allowed_roles=("WORLD", "SERVICE", "GUILD"))

    def validate_resolved_role(self, intent, role):
        pass


def test_probe_01_distinct_roles_coexist():
    reg = AuthenticatedRealtimeSessionRegistry()
    reg.register_newest(session("world", role=RealtimeRole.WORLD, room=1))
    reg.register_newest(session("guild", role=RealtimeRole.GUILD, room=77))
    assert set(reg.connections_for_context("c1")) == {"world", "guild"}


def test_probe_02_newest_same_context_role_wins():
    reg = AuthenticatedRealtimeSessionRegistry()
    old = session("old")
    reg.register_newest(old)
    evicted = reg.register_newest(session("new"))
    assert evicted is old
    assert reg.get("old") is None
    assert reg.connection_for_context_role("c1", RealtimeRole.WORLD) == "new"


def test_probe_03_old_receives_superseded_control():
    reg = AuthenticatedRealtimeSessionRegistry()
    old = session("old")
    reg.register_newest(old)
    evicted = reg.register_newest(session("new"))
    controls = RealtimeControlPublisher(reg, encoder=Encoder())
    # register_newest removes the old owner from authority before the server queues control.
    assert evicted is old and reg.get("old") is None
    # Re-register only to exercise the publisher's normal removal+control operation itself.
    reg.register(old)
    assert controls.close_session(old, kind=PrivateControlKind.CONNECTION_SUPERSEDED, reason="NEWEST_CONTEXT_ROLE_WINS")
    frame = old._queue.get_nowait()
    assert str(PRIVATE_SERVER_CONTROL_MID).encode() in frame
    assert b"CONNECTION_SUPERSEDED" in frame


def test_probe_04_different_context_coexist():
    reg = AuthenticatedRealtimeSessionRegistry()
    reg.register_newest(session("a", context="c1"))
    reg.register_newest(session("b", context="c2"))
    assert len(reg) == 2


def test_probe_05_room_fanout_active_sessions():
    reg = AuthenticatedRealtimeSessionRegistry()
    a = session("a", context="c1", room=1)
    b = session("b", context="c2", account_session="s2", room=1)
    other = session("g", context="c3", account_session="s3", role=RealtimeRole.GUILD, room=77)
    for value in (a, b, other):
        reg.register_newest(value)
    publisher = TypedRealtimeEventPublisher(Schemas(), reg, encoder=Encoder())
    report = publisher.publish(RealtimeEventIntent(36855, {}, RoomAudience(RealtimeRole.WORLD, 1), "sync", "TRANSIENT_PRESENTATION"))
    assert report.selected == 2 and report.enqueued == 2
    assert a._queue.qsize() == 1 and b._queue.qsize() == 1 and other._queue.qsize() == 0


class Engine:
    def __init__(self, events): self.events = events
    @contextmanager
    def begin(self):
        yield object()


class Repo:
    def __init__(self, rows, events): self.rows = tuple(rows); self.events = events
    def claim_available(self, connection, **kwargs): return self.rows
    def mark_dispatched(self, connection, event_id, **kwargs): self.events.append(("dispatched", event_id)); return True
    def mark_done(self, connection, event_id, **kwargs): self.events.append(("done", event_id)); return True
    def release_for_retry(self, connection, event_id, **kwargs): self.events.append(("retry", event_id)); return True
    def requeue_stale_claims(self, *args, **kwargs): return 0


class Publisher:
    def publish(self, intent): return SimpleNamespace()


class ControlHandler:
    def handle(self, row): return 0


def transient_row(event_id=1):
    return {
        "event_id": event_id,
        "topic": "realtime.event",
        "delivery_class": DeliveryClass.TRANSIENT_REALTIME_NOTICE.value,
        "payload": {
            "mid": 36855,
            "params": {},
            "audience": {"kind": "ROOM", "role": "WORLD", "room_id": 1},
            "owner_domain": "sync",
            "wire_delivery_class": "TRANSIENT_PRESENTATION",
            "schema_key": "force_reload",
        },
    }


def test_probe_06_transient_marked_done():
    events = []
    report = RealtimeOutboxDispatcher(lambda: Engine(events), Publisher(), ControlHandler(), repository=Repo([transient_row()], events)).poll_once()
    assert report.transient_attempted == 1 and report.done == 1
    assert events == [("dispatched", 1), ("done", 1)]


def test_probe_07_expired_realtime_notice_dropped():
    class EmptyMappings:
        def all(self): return []
    class EmptyResult:
        def mappings(self): return EmptyMappings()
    class Capture:
        def __init__(self): self.compiled = None
        def execute(self, statement):
            self.compiled = statement.compile(dialect=postgresql.dialect())
            return EmptyResult()
    conn = Capture()
    assert OutboxRepository().claim_available(
        conn,
        worker_id="rt",
        limit=5,
        delivery_classes=(DeliveryClass.TRANSIENT_REALTIME_NOTICE,),
    ) == ()
    sql = str(conn.compiled)
    assert "expires_at IS NULL" in sql and "expires_at > now()" in sql


def test_probe_08_context_invalidation_scoped():
    reg = AuthenticatedRealtimeSessionRegistry()
    c1 = session("c1w", context="ctx1", account_session="s1")
    c2 = session("c2w", context="ctx2", account_session="s1")
    reg.register_newest(c1); reg.register_newest(c2)
    controls = RealtimeControlPublisher(reg, encoder=Encoder())
    assert controls.close_context("ctx1", reason="superseded") == 1
    assert reg.get("c1w") is None and reg.get("c2w") is c2


def test_probe_09_context_invalidation_control_delivered():
    reg = AuthenticatedRealtimeSessionRegistry(); s = session("ctx")
    reg.register_newest(s)
    controls = RealtimeControlPublisher(reg, encoder=Encoder())
    assert controls.close_context("c1", reason="superseded") == 1
    frame = s._queue.get_nowait()
    assert b"AUTH_CONTEXT_INVALIDATED" in frame


def test_probe_10_session_invalidation_closes_remaining():
    reg = AuthenticatedRealtimeSessionRegistry()
    reg.register_newest(session("w", context="c1", account_session="s1", role=RealtimeRole.WORLD, room=1))
    reg.register_newest(session("g", context="c1", account_session="s1", role=RealtimeRole.GUILD, room=77))
    reg.register_newest(session("other", context="c2", account_session="s2", role=RealtimeRole.WORLD, room=1))
    controls = RealtimeControlPublisher(reg, encoder=Encoder())
    assert controls.close_account_session("s1", reason="revoked") == 2
    assert len(reg) == 1 and reg.get("other") is not None


def test_probe_11_liveness_sweep_fallback_closes_stale():
    # Covered with the real sweeper in test_liveness; this reference probe verifies
    # its idempotent closure primitive is context-scoped and fail-closed.
    reg = AuthenticatedRealtimeSessionRegistry(); s = session("stale")
    reg.register_newest(s)
    controls = RealtimeControlPublisher(reg, encoder=Encoder())
    assert controls.close_context("c1", reason="CONTEXT_ENDED") == 1
    assert len(reg) == 0


def test_probe_12_control_idempotent_and_room_invalidation_is_durable_identity_scoped():
    reg = AuthenticatedRealtimeSessionRegistry()
    guild = session("guild", context="c1", account_session="s1", role=RealtimeRole.GUILD, room=77)
    world = session("world", context="c1", account_session="s1", role=RealtimeRole.WORLD, room=1)
    reg.register_newest(guild); reg.register_newest(world)
    controls = RealtimeControlPublisher(reg, encoder=Encoder())
    handler = RealtimeControlEventHandler(controls)
    row = {
        "topic": "realtime.room_invalidated",
        "context_id": "c1",
        "payload": {"context_id": "c1", "role": "GUILD", "room_id": 77, "reason": "MEMBERSHIP_CHANGED"},
    }
    assert handler.handle(row) == 1
    assert reg.get("guild") is None and reg.get("world") is world
    assert handler.handle(row) == 0


def test_probe_13_private_control_mid_u16():
    assert 0 <= PRIVATE_SERVER_CONTROL_MID <= 0xFFFF
