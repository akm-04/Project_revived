"""Durable session/context liveness validation for the dedicated I5 gateway."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import time
from typing import Any, Iterable, Mapping

from sqlalchemy import select

from gxb_backend.identity.models import IdentityPolicy
from gxb_backend.identity.schema import account_sessions, gameplay_contexts

from .control import PrivateControlKind, RealtimeControlPublisher
from .session import AuthenticatedRealtimeSessionRegistry


@dataclass(frozen=True, slots=True)
class RealtimeLivenessStatus:
    session_id: str
    context_id: str
    live: bool
    reason: str


@dataclass(frozen=True, slots=True)
class RealtimeSweepReport:
    checked_pairs: int
    closed: int
    database_available: bool
    outage_grace_exhausted: bool = False


class RelationalRealtimeLivenessReader:
    """Batch-read durable liveness; no registry/socket side effects."""

    @staticmethod
    def _key(session_id: Any, context_id: Any) -> tuple[str, str]:
        return str(session_id), str(context_id)

    def read(
        self,
        connection,
        pairs: Iterable[tuple[str, str]],
        *,
        policy: IdentityPolicy,
        now: datetime | None = None,
    ) -> dict[tuple[str, str], RealtimeLivenessStatus]:
        requested = {self._key(s, c) for s, c in pairs if str(s) and str(c)}
        if not requested:
            return {}
        session_ids = tuple({s for s, _ in requested})
        context_ids = tuple({c for _, c in requested})
        statement = (
            select(
                account_sessions.c.session_id,
                account_sessions.c.last_activity_at,
                account_sessions.c.absolute_expires_at,
                account_sessions.c.revoked_at,
                gameplay_contexts.c.context_id,
                gameplay_contexts.c.session_id.label("context_session_id"),
                gameplay_contexts.c.ended_at,
            )
            .select_from(
                gameplay_contexts.join(
                    account_sessions,
                    gameplay_contexts.c.session_id == account_sessions.c.session_id,
                )
            )
            .where(
                account_sessions.c.session_id.in_(session_ids),
                gameplay_contexts.c.context_id.in_(context_ids),
            )
        )
        rows = tuple(connection.execute(statement).mappings().all())
        return self.evaluate(requested, rows, policy=policy, now=now)

    def evaluate(
        self,
        requested: Iterable[tuple[str, str]],
        rows: Iterable[Mapping[str, Any]],
        *,
        policy: IdentityPolicy,
        now: datetime | None = None,
    ) -> dict[tuple[str, str], RealtimeLivenessStatus]:
        instant = now or datetime.now(timezone.utc)
        requested_set = {self._key(s, c) for s, c in requested}
        result: dict[tuple[str, str], RealtimeLivenessStatus] = {
            key: RealtimeLivenessStatus(key[0], key[1], False, "AUTHORITY_MISSING")
            for key in requested_set
        }
        for row in rows:
            key = self._key(row.get("session_id"), row.get("context_id"))
            if key not in requested_set:
                continue
            if self._key(row.get("context_session_id"), row.get("context_id"))[0] != key[0]:
                result[key] = RealtimeLivenessStatus(*key, False, "CONTEXT_SESSION_MISMATCH")
                continue
            if row.get("revoked_at") is not None:
                result[key] = RealtimeLivenessStatus(*key, False, "SESSION_REVOKED")
                continue
            absolute = row.get("absolute_expires_at")
            if absolute is not None and instant >= absolute:
                result[key] = RealtimeLivenessStatus(*key, False, "SESSION_EXPIRED")
                continue
            last_activity = row.get("last_activity_at")
            if policy.idle_session_ttl is not None and last_activity is not None and instant >= last_activity + policy.idle_session_ttl:
                result[key] = RealtimeLivenessStatus(*key, False, "SESSION_IDLE_EXPIRED")
                continue
            if row.get("ended_at") is not None:
                result[key] = RealtimeLivenessStatus(*key, False, "CONTEXT_ENDED")
                continue
            result[key] = RealtimeLivenessStatus(*key, True, "LIVE")
        return result


class RealtimeLivenessSweeper:
    """Defense-in-depth closure independent of outbox/NOTIFY delivery."""

    def __init__(
        self,
        engine_provider,
        registry: AuthenticatedRealtimeSessionRegistry,
        controls: RealtimeControlPublisher,
        *,
        policy: IdentityPolicy,
        reader: RelationalRealtimeLivenessReader | None = None,
        database_grace_seconds: float = 30.0,
        monotonic=None,
        clock=None,
    ) -> None:
        self._engine_provider = engine_provider
        self.registry = registry
        self.controls = controls
        self.policy = policy
        self.reader = reader or RelationalRealtimeLivenessReader()
        self.database_grace_seconds = float(database_grace_seconds)
        if self.database_grace_seconds < 0:
            raise ValueError("database_grace_seconds must be >= 0")
        self._monotonic = monotonic or time.monotonic
        self._clock = clock or (lambda: datetime.now(timezone.utc))
        self._outage_since: float | None = None

    def _engine(self):
        provider = self._engine_provider
        return provider() if callable(provider) else provider.engine()

    def _pairs(self) -> tuple[tuple[str, str], ...]:
        pairs = {
            (str(session.session_id), str(session.context_id))
            for session in self.registry.snapshot()
            if session.session_id and session.context_id
        }
        return tuple(sorted(pairs))

    def sweep_once(self) -> RealtimeSweepReport:
        pairs = self._pairs()
        if not pairs:
            self._outage_since = None
            return RealtimeSweepReport(0, 0, True, False)
        try:
            engine = self._engine()
            with engine.connect() as connection:
                statuses = self.reader.read(connection, pairs, policy=self.policy, now=self._clock())
        except Exception:
            now_mono = float(self._monotonic())
            if self._outage_since is None:
                self._outage_since = now_mono
            exhausted = now_mono - self._outage_since >= self.database_grace_seconds
            closed = 0
            if exhausted:
                for session in self.registry.snapshot():
                    if self.controls.close_session(
                        session,
                        kind=PrivateControlKind.AUTH_CONTEXT_INVALIDATED,
                        reason="AUTHORITY_UNAVAILABLE",
                    ):
                        closed += 1
            return RealtimeSweepReport(len(pairs), closed, False, exhausted)
        self._outage_since = None
        closed = 0
        for key, status in statuses.items():
            if status.live:
                continue
            closed += self.controls.close_context(key[1], reason=status.reason)
        return RealtimeSweepReport(len(pairs), closed, True, False)
