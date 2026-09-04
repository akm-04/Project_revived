"""Durable PostgreSQL outbox primitives; socket delivery remains Wave I5."""

from __future__ import annotations

from collections.abc import Iterable
from datetime import timedelta
from typing import Any, Mapping

from sqlalchemy import and_, func, or_, select, update
from sqlalchemy.engine import Connection

from .models import DeliveryClass, OutboxIntent, OutboxState
from .schema import outbox_events


class OutboxRepository:
    table = outbox_events

    def enqueue(self, connection: Connection, intents: Iterable[OutboxIntent]) -> tuple[int, ...]:
        event_ids: list[int] = []
        for intent in intents:
            values: dict[str, Any] = {
                "topic": intent.topic,
                "resource_kind": intent.resource_kind,
                "resource_key": intent.resource_key,
                "context_id": intent.context_id,
                "payload": dict(intent.payload),
                "delivery_class": intent.delivery_class.value,
                "priority": intent.priority,
                "expires_at": intent.expires_at,
            }
            if intent.available_at is not None:
                values["available_at"] = intent.available_at
            result = connection.execute(self.table.insert().values(**values).returning(self.table.c.event_id))
            event_ids.append(int(result.scalar_one()))
        return tuple(event_ids)

    def claim_available(
        self,
        connection: Connection,
        *,
        worker_id: str,
        limit: int,
        delivery_classes: Iterable[DeliveryClass | str] | None = None,
    ) -> tuple[Mapping[str, Any], ...]:
        if not worker_id.strip():
            raise ValueError("worker_id must not be empty")
        if isinstance(limit, bool) or not isinstance(limit, int) or limit <= 0:
            raise ValueError("limit must be a positive integer")
        now = func.now()
        conditions = [
            self.table.c.dispatch_state == OutboxState.PENDING.value,
            self.table.c.available_at <= now,
            or_(self.table.c.expires_at.is_(None), self.table.c.expires_at > now),
        ]
        if delivery_classes is not None:
            values = tuple(
                value.value if isinstance(value, DeliveryClass) else DeliveryClass(str(value)).value
                for value in delivery_classes
            )
            if not values:
                return ()
            conditions.append(self.table.c.delivery_class.in_(values))
        eligible = and_(*conditions)
        candidates = (
            select(self.table.c.event_id)
            .where(eligible)
            .order_by(self.table.c.priority.asc(), self.table.c.event_id.asc())
            .limit(limit)
            .with_for_update(skip_locked=True)
            .cte("outbox_candidates")
        )
        statement = (
            update(self.table)
            .where(self.table.c.event_id.in_(select(candidates.c.event_id)))
            .values(
                dispatch_state=OutboxState.CLAIMED.value,
                claimed_by=worker_id,
                claimed_at=now,
                attempts=self.table.c.attempts + 1,
            )
            .returning(*self.table.c)
        )
        rows = list(connection.execute(statement).mappings().all())
        rows.sort(key=lambda row: (int(row["priority"]), int(row["event_id"])))
        return tuple(rows)

    def mark_dispatched(self, connection: Connection, event_id: int, *, worker_id: str) -> bool:
        statement = (
            update(self.table)
            .where(
                self.table.c.event_id == event_id,
                self.table.c.dispatch_state == OutboxState.CLAIMED.value,
                self.table.c.claimed_by == worker_id,
            )
            .values(dispatch_state=OutboxState.DISPATCHED.value, published_at=func.now())
        )
        return connection.execute(statement).rowcount == 1

    def mark_done(
        self,
        connection: Connection,
        event_id: int,
        *,
        worker_id: str,
        error: str | None = None,
    ) -> bool:
        values: dict[str, Any] = {
            "dispatch_state": OutboxState.DONE.value,
            "published_at": func.now(),
        }
        if error is not None:
            values["last_error"] = str(error)[:4000]
        statement = (
            update(self.table)
            .where(
                self.table.c.event_id == event_id,
                self.table.c.dispatch_state.in_((OutboxState.CLAIMED.value, OutboxState.DISPATCHED.value)),
                self.table.c.claimed_by == worker_id,
            )
            .values(**values)
        )
        return connection.execute(statement).rowcount == 1

    def release_for_retry(self, connection: Connection, event_id: int, *, worker_id: str, error: str) -> bool:
        statement = (
            update(self.table)
            .where(
                self.table.c.event_id == event_id,
                self.table.c.dispatch_state == OutboxState.CLAIMED.value,
                self.table.c.claimed_by == worker_id,
            )
            .values(
                dispatch_state=OutboxState.PENDING.value,
                claimed_by=None,
                claimed_at=None,
                last_error=str(error)[:4000],
            )
        )
        return connection.execute(statement).rowcount == 1


    def requeue_stale_claims(self, connection: Connection, *, stale_after_seconds: int) -> int:
        if isinstance(stale_after_seconds, bool) or not isinstance(stale_after_seconds, int) or stale_after_seconds <= 0:
            raise ValueError("stale_after_seconds must be a positive integer")
        statement = (
            update(self.table)
            .where(
                self.table.c.dispatch_state == OutboxState.CLAIMED.value,
                self.table.c.claimed_at.is_not(None),
                self.table.c.claimed_at <= func.now() - timedelta(seconds=stale_after_seconds),
            )
            .values(
                dispatch_state=OutboxState.PENDING.value,
                claimed_by=None,
                claimed_at=None,
                last_error="stale claim reclaimed",
            )
        )
        return int(connection.execute(statement).rowcount or 0)

    def expire_stale(self, connection: Connection) -> int:
        statement = (
            update(self.table)
            .where(
                self.table.c.dispatch_state == OutboxState.PENDING.value,
                self.table.c.expires_at.is_not(None),
                self.table.c.expires_at <= func.now(),
            )
            .values(dispatch_state=OutboxState.EXPIRED.value)
        )
        return int(connection.execute(statement).rowcount or 0)
