"""Typed I2 receipt/outbox/job records and enums."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum
from typing import Any, Mapping
from uuid import UUID


class DeliveryClass(StrEnum):
    TRANSIENT_REALTIME_NOTICE = "TRANSIENT_REALTIME_NOTICE"
    IDEMPOTENT_REALTIME_CONTROL = "IDEMPOTENT_REALTIME_CONTROL"
    DURABLE_USER_DELIVERY = "DURABLE_USER_DELIVERY"
    DERIVED_PROJECTION_WORK = "DERIVED_PROJECTION_WORK"


class OutboxState(StrEnum):
    PENDING = "PENDING"
    CLAIMED = "CLAIMED"
    DISPATCHED = "DISPATCHED"
    DONE = "DONE"
    EXPIRED = "EXPIRED"


class JobStatus(StrEnum):
    SCHEDULED = "SCHEDULED"
    RUNNING = "RUNNING"
    RETRY = "RETRY"
    SUCCEEDED = "SUCCEEDED"
    CANCELLED = "CANCELLED"
    DEAD = "DEAD"


@dataclass(frozen=True)
class ReceiptKey:
    resource_kind: str
    resource_key: str
    domain: str
    operation: str
    idempotency_key: str

    def __post_init__(self) -> None:
        for field in ("resource_kind", "resource_key", "domain", "operation", "idempotency_key"):
            if not str(getattr(self, field)).strip():
                raise ValueError(f"{field} must not be empty")

    @property
    def scope(self) -> str:
        return "/".join(
            (self.resource_kind, self.resource_key, self.domain, self.operation, self.idempotency_key)
        )


@dataclass(frozen=True)
class ReceiptRecord:
    receipt_id: UUID
    key: ReceiptKey
    request_fingerprint: str
    result: Mapping[str, Any]
    committed_at: datetime | None = None


@dataclass(frozen=True)
class OutboxIntent:
    topic: str
    resource_kind: str
    resource_key: str
    payload: Mapping[str, Any]
    delivery_class: DeliveryClass = DeliveryClass.TRANSIENT_REALTIME_NOTICE
    context_id: UUID | None = None
    available_at: datetime | None = None
    priority: int = 100
    expires_at: datetime | None = None

    def __post_init__(self) -> None:
        if not self.topic.strip() or not self.resource_kind.strip() or not self.resource_key.strip():
            raise ValueError("outbox topic/resource identifiers must not be empty")
        if isinstance(self.priority, bool) or not isinstance(self.priority, int):
            raise TypeError("outbox priority must be an integer")
        if self.delivery_class is DeliveryClass.TRANSIENT_REALTIME_NOTICE and self.expires_at is None:
            raise ValueError("transient realtime notices require expires_at")


@dataclass(frozen=True)
class ScheduledJobIntent:
    dedupe_key: str
    job_type: str
    scope_type: str
    scope_id: str
    due_at: datetime
    payload: Mapping[str, Any]
    generation_id: str | None = None
    priority: int = 100

    def __post_init__(self) -> None:
        for field in ("dedupe_key", "job_type", "scope_type", "scope_id"):
            if not str(getattr(self, field)).strip():
                raise ValueError(f"{field} must not be empty")
        if self.due_at.tzinfo is None or self.due_at.utcoffset() is None:
            raise ValueError("scheduled job due_at must be timezone-aware")
        if isinstance(self.priority, bool) or not isinstance(self.priority, int):
            raise TypeError("scheduled job priority must be an integer")
