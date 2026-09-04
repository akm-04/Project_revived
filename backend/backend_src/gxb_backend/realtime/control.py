"""Private Pass332/340/344 realtime-control wire and gateway delivery."""

from __future__ import annotations

from enum import Enum
import threading
from typing import Callable, Mapping, Any

from .codec import RealtimeFrameEncoder
from .session import AuthenticatedRealtimeSessionRegistry, RealtimeSession


PRIVATE_SERVER_CONTROL_MID = 65_000


class PrivateControlKind(str, Enum):
    CONNECTION_SUPERSEDED = "CONNECTION_SUPERSEDED"
    ROOM_INVALIDATED = "ROOM_INVALIDATED"
    AUTH_CONTEXT_INVALIDATED = "AUTH_CONTEXT_INVALIDATED"


def normalize_control_payload(payload: Mapping[str, Any]) -> dict[str, object]:
    """Validate a private control payload without touching durable state."""
    try:
        kind = PrivateControlKind(str(payload.get("kind", "")))
    except ValueError as exc:
        raise ValueError("unsupported private realtime control kind") from exc
    out: dict[str, object] = {"kind": kind.value}
    if "room_id" in payload and payload.get("room_id") is not None:
        room_id = int(payload["room_id"])
        if room_id <= 0:
            raise ValueError("room_id must be positive")
        out["room_id"] = room_id
    reason = payload.get("reason")
    if reason not in (None, ""):
        out["reason"] = str(reason)[:96]
    return out


class RealtimeControlPublisher:
    """Idempotent transient close/invalidation actions over the gateway registry."""

    def __init__(
        self,
        registry: AuthenticatedRealtimeSessionRegistry,
        *,
        encoder: RealtimeFrameEncoder | None = None,
        drain_timeout_seconds: float = 0.5,
        timer_factory: Callable[[float, Callable[[], None]], threading.Timer] = threading.Timer,
    ) -> None:
        self.registry = registry
        self.encoder = encoder or RealtimeFrameEncoder()
        self.drain_timeout_seconds = max(0.01, float(drain_timeout_seconds))
        self._timer_factory = timer_factory

    def _arm_bounded_close(self, session: RealtimeSession) -> None:
        timer = self._timer_factory(self.drain_timeout_seconds, session.close)
        # threading.Timer exposes daemon; test doubles need not.
        if hasattr(timer, "daemon"):
            timer.daemon = True
        timer.start()

    def close_session(
        self,
        session: RealtimeSession,
        *,
        kind: PrivateControlKind,
        reason: str | None = None,
        room_id: int | None = None,
    ) -> bool:
        payload: dict[str, object] = {"kind": kind.value}
        if reason:
            payload["reason"] = str(reason)
        if room_id is not None:
            payload["room_id"] = int(room_id)
        frame = self.encoder.encode(
            PRIVATE_SERVER_CONTROL_MID,
            normalize_control_payload(payload),
            sequence=0,
        )
        removed = self.registry.remove(session.connection_id)
        if removed is None:
            return False
        if removed.enqueue_then_close(frame):
            self._arm_bounded_close(removed)
            return True
        removed.close()
        return True

    def close_connection(self, connection_id: str, *, kind: PrivateControlKind, reason: str | None = None) -> bool:
        session = self.registry.get(connection_id)
        if session is None:
            return False
        return self.close_session(session, kind=kind, reason=reason)

    def close_context(self, context_id: str, *, reason: str) -> int:
        closed = 0
        for connection_id in self.registry.connections_for_context(context_id):
            session = self.registry.get(connection_id)
            if session is not None and self.close_session(
                session,
                kind=PrivateControlKind.AUTH_CONTEXT_INVALIDATED,
                reason=reason,
            ):
                closed += 1
        return closed

    def close_account_session(self, session_id: str, *, reason: str) -> int:
        closed = 0
        for connection_id in self.registry.connections_for_session(session_id):
            session = self.registry.get(connection_id)
            if session is not None and self.close_session(
                session,
                kind=PrivateControlKind.AUTH_CONTEXT_INVALIDATED,
                reason=reason,
            ):
                closed += 1
        return closed

    def close_context_room(
        self,
        context_id: str,
        *,
        role,
        room_id: int,
        reason: str,
    ) -> int:
        """Close only the current transient owner of one durable context/role/room.

        Durable producers never know connection IDs.  The gateway resolves the
        current socket locally and verifies the room still matches before the
        private ROOM_INVALIDATED control is queued.
        """
        from .contracts import RealtimeRole

        role = RealtimeRole(role)
        room_id = int(room_id)
        if room_id <= 0:
            raise ValueError("room_id must be positive")
        connection_id = self.registry.connection_for_context_role(str(context_id), role)
        if not connection_id:
            return 0
        session = self.registry.get(connection_id)
        if session is None or int(session.room_id) != room_id:
            return 0
        return int(
            self.close_session(
                session,
                kind=PrivateControlKind.ROOM_INVALIDATED,
                reason=reason,
                room_id=room_id,
            )
        )
