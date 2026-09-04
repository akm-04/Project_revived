from __future__ import annotations

from datetime import datetime, timezone

import pytest

from gxb_backend.foundation.resource_keys import ResourceClass, ResourceKey
from gxb_backend.transactions.locking import ResourceLockRegistry
from gxb_backend.transactions.models import DeliveryClass, OutboxIntent, ReceiptKey, ScheduledJobIntent


def test_duplicate_locker_registration_is_rejected() -> None:
    registry = ResourceLockRegistry()
    registry.register(ResourceClass.PLAYER, "player", lambda c, k: None)
    with pytest.raises(ValueError, match="already registered"):
        registry.register(ResourceClass.PLAYER, "player", lambda c, k: None)


def test_lock_registry_deduplicates_resource_keys() -> None:
    seen = []
    registry = ResourceLockRegistry()
    registry.register(ResourceClass.PLAYER, "player", lambda c, k: seen.append(k.identity))
    ordered = registry.acquire_all(object(), [ResourceKey.player(2), ResourceKey.player(2), ResourceKey.player(1)])
    assert [key.identity for key in ordered] == [(1,), (2,)]
    assert seen == [(1,), (2,)]


def test_receipt_key_requires_explicit_semantic_identity() -> None:
    with pytest.raises(ValueError, match="idempotency_key"):
        ReceiptKey("player", "1", "shop", "buy", "")


def test_transient_outbox_notice_requires_expiry() -> None:
    with pytest.raises(ValueError, match="expires_at"):
        OutboxIntent("chat", "room", "1", {"x": 1})
    intent = OutboxIntent(
        "control",
        "context",
        "ctx",
        {"kind": "revoked"},
        delivery_class=DeliveryClass.IDEMPOTENT_REALTIME_CONTROL,
    )
    assert intent.expires_at is None


def test_scheduled_job_due_time_must_be_timezone_aware() -> None:
    with pytest.raises(ValueError, match="timezone-aware"):
        ScheduledJobIntent("k", "settle", "generation", "7", datetime(2026, 1, 1), {})
    value = ScheduledJobIntent("k", "settle", "generation", "7", datetime(2026, 1, 1, tzinfo=timezone.utc), {})
    assert value.due_at.tzinfo is not None


def test_locker_registration_requires_resource_class_enum() -> None:
    registry = ResourceLockRegistry()
    with pytest.raises(TypeError, match="ResourceClass"):
        registry.register(10, "player", lambda c, k: None)  # type: ignore[arg-type]
