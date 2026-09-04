from __future__ import annotations

from contextlib import contextmanager
from dataclasses import dataclass
from unittest.mock import Mock

import pytest

from gxb_backend.foundation.contracts import TransactionRequest
from gxb_backend.foundation.resource_keys import ResourceClass, ResourceKey
from gxb_backend.transactions.coordinator import ResourceTransactionCoordinator, RetryPolicy
from gxb_backend.transactions.errors import StateVersionConflict, TransactionRetryExhausted, is_retryable_transaction_error
from gxb_backend.transactions.locking import ResourceLockRegistry


class FakeOrigError(Exception):
    def __init__(self, sqlstate: str):
        super().__init__(sqlstate)
        self.sqlstate = sqlstate


class WrapperError(Exception):
    def __init__(self, orig: BaseException):
        super().__init__(str(orig))
        self.orig = orig


class FakeDbTransaction:
    def __init__(self, connection):
        self.connection = connection

    def __enter__(self):
        self.connection.events.append("begin")
        return self

    def __exit__(self, exc_type, exc, tb):
        self.connection.events.append("rollback" if exc_type else "commit")
        return False


class FakeConnection:
    def __init__(self, name: str):
        self.name = name
        self.events: list[object] = []

    def __enter__(self):
        self.events.append("connect")
        return self

    def __exit__(self, exc_type, exc, tb):
        self.events.append("close")
        return False

    def begin(self):
        return FakeDbTransaction(self)


class FakeEngine:
    def __init__(self):
        self.connections: list[FakeConnection] = []

    def connect(self):
        connection = FakeConnection(f"c{len(self.connections) + 1}")
        self.connections.append(connection)
        return connection


def registry_with_recording_lockers(events: list[tuple[str, object]]) -> ResourceLockRegistry:
    registry = ResourceLockRegistry()
    for cls, kind in [
        (ResourceClass.SESSION, "session"),
        (ResourceClass.CONTEXT, "context"),
        (ResourceClass.ACCOUNT_GLOBAL, "account"),
        (ResourceClass.REGION, "region"),
        (ResourceClass.GENERATION, "season"),
        (ResourceClass.SHARED, "guild"),
        (ResourceClass.PLAYER, "player"),
        (ResourceClass.CHILD, "slot"),
    ]:
        registry.register(cls, kind, lambda connection, key, cls=cls: events.append((cls.name, key.identity)))
    return registry


def full_request() -> TransactionRequest:
    return TransactionRequest(
        request_id="req-1",
        operation_name="shared-op",
        client_operation_id="client-op-7",
        resources=(
            ResourceKey.of(ResourceClass.CHILD, "slot", "fight-2"),
            ResourceKey.player(10),
            ResourceKey.of(ResourceClass.SHARED, "guild", 8),
            ResourceKey.of(ResourceClass.GENERATION, "season", 2026),
            ResourceKey.of(ResourceClass.REGION, "region", 2),
            ResourceKey.player(2),
            ResourceKey.of(ResourceClass.ACCOUNT_GLOBAL, "account", "acct"),
            ResourceKey.of(ResourceClass.CONTEXT, "context", "ctx"),
            ResourceKey.of(ResourceClass.SESSION, "session", "sid"),
        ),
    )


def test_retryable_sqlstates_are_exactly_serialization_and_deadlock() -> None:
    assert is_retryable_transaction_error(WrapperError(FakeOrigError("40001")))
    assert is_retryable_transaction_error(WrapperError(FakeOrigError("40P01")))
    assert not is_retryable_transaction_error(WrapperError(FakeOrigError("23505")))
    assert not is_retryable_transaction_error(RuntimeError("network"))


def test_resource_locks_are_acquired_in_frozen_universal_order_and_players_numeric() -> None:
    lock_events: list[tuple[str, object]] = []
    engine = FakeEngine()
    coordinator = ResourceTransactionCoordinator(
        lambda: engine,
        lock_registry=registry_with_recording_lockers(lock_events),
        retry_policy=RetryPolicy(max_attempts=1),
    )
    result = coordinator.run(full_request(), lambda tx: tuple(k.identity for k in tx.request.resources))
    assert result[0] == ("sid",)
    assert [name for name, _ in lock_events] == [
        "SESSION", "CONTEXT", "ACCOUNT_GLOBAL", "REGION", "GENERATION", "SHARED", "PLAYER", "PLAYER", "CHILD"
    ]
    assert lock_events[6][1] == (2,)
    assert lock_events[7][1] == (10,)
    assert engine.connections[0].events == ["connect", "begin", "commit", "close"]


def test_whole_transaction_retries_on_serialization_with_fresh_connection_and_stable_request() -> None:
    engine = FakeEngine()
    registry = ResourceLockRegistry()
    registry.register(ResourceClass.PLAYER, "player", lambda connection, key: None)
    sleeps: list[float] = []
    seen: list[tuple[str, str, str]] = []
    attempts = 0

    def operation(tx):
        nonlocal attempts
        attempts += 1
        seen.append((tx.connection.name, tx.request.request_id, tx.request.client_operation_id or ""))
        if attempts == 1:
            raise WrapperError(FakeOrigError("40001"))
        return "ok"

    coordinator = ResourceTransactionCoordinator(
        lambda: engine,
        lock_registry=registry,
        retry_policy=RetryPolicy(max_attempts=3, base_delay_seconds=0.01, max_delay_seconds=0.01, jitter_fraction=0),
        sleep=sleeps.append,
    )
    request = TransactionRequest("req", "op", (ResourceKey.player(5),), "stable-op", True)
    assert coordinator.run(request, operation) == "ok"
    assert seen == [("c1", "req", "stable-op"), ("c2", "req", "stable-op")]
    assert engine.connections[0].events == ["connect", "begin", "rollback", "close"]
    assert engine.connections[1].events == ["connect", "begin", "commit", "close"]
    assert sleeps == [0.01]


def test_nonretryable_failure_rolls_back_once() -> None:
    engine = FakeEngine()
    registry = ResourceLockRegistry()
    registry.register(ResourceClass.PLAYER, "player", lambda connection, key: None)
    coordinator = ResourceTransactionCoordinator(lambda: engine, lock_registry=registry)
    with pytest.raises(ValueError, match="bad-domain-input"):
        coordinator.run(
            TransactionRequest("r", "o", (ResourceKey.player(1),)),
            lambda tx: (_ for _ in ()).throw(ValueError("bad-domain-input")),
        )
    assert len(engine.connections) == 1
    assert engine.connections[0].events == ["connect", "begin", "rollback", "close"]


def test_state_version_conflict_can_retry_whole_operation() -> None:
    engine = FakeEngine()
    registry = ResourceLockRegistry()
    registry.register(ResourceClass.PLAYER, "player", lambda connection, key: None)
    calls = 0

    def operation(tx):
        nonlocal calls
        calls += 1
        if calls == 1:
            raise StateVersionConflict("player:1", 7)
        return calls

    coordinator = ResourceTransactionCoordinator(
        lambda: engine,
        lock_registry=registry,
        retry_policy=RetryPolicy(max_attempts=2, base_delay_seconds=0, max_delay_seconds=0),
    )
    assert coordinator.run(TransactionRequest("r", "o", (ResourceKey.player(1),), retry_safe=True), operation) == 2


def test_retry_exhaustion_reports_attempt_count() -> None:
    engine = FakeEngine()
    registry = ResourceLockRegistry()
    registry.register(ResourceClass.PLAYER, "player", lambda connection, key: None)
    coordinator = ResourceTransactionCoordinator(
        lambda: engine,
        lock_registry=registry,
        retry_policy=RetryPolicy(max_attempts=2, base_delay_seconds=0, max_delay_seconds=0),
    )
    with pytest.raises(TransactionRetryExhausted) as captured:
        coordinator.run(
            TransactionRequest("r", "o", (ResourceKey.player(1),), retry_safe=True),
            lambda tx: (_ for _ in ()).throw(WrapperError(FakeOrigError("40P01"))),
        )
    assert captured.value.attempts == 2
    assert len(engine.connections) == 2


def test_missing_canonical_locker_fails_before_domain_operation() -> None:
    engine = FakeEngine()
    called = False
    coordinator = ResourceTransactionCoordinator(lambda: engine, lock_registry=ResourceLockRegistry())

    def operation(tx):
        nonlocal called
        called = True

    with pytest.raises(KeyError, match="PLAYER:player"):
        coordinator.run(TransactionRequest("r", "o", (ResourceKey.player(1),)), operation)
    assert called is False
    assert engine.connections[0].events == ["connect", "begin", "rollback", "close"]


def test_retryable_database_error_is_not_retried_without_explicit_retry_safe_opt_in() -> None:
    engine = FakeEngine()
    registry = ResourceLockRegistry()
    registry.register(ResourceClass.PLAYER, "player", lambda connection, key: None)
    coordinator = ResourceTransactionCoordinator(
        lambda: engine,
        lock_registry=registry,
        retry_policy=RetryPolicy(max_attempts=3, base_delay_seconds=0, max_delay_seconds=0),
    )
    with pytest.raises(WrapperError):
        coordinator.run(
            TransactionRequest("r", "unsafe-external-op", (ResourceKey.player(1),), retry_safe=False),
            lambda tx: (_ for _ in ()).throw(WrapperError(FakeOrigError("40001"))),
        )
    assert len(engine.connections) == 1


def test_operation_context_time_and_randomness_seed_are_stable_across_retry() -> None:
    from datetime import datetime, timezone

    engine = FakeEngine()
    registry = ResourceLockRegistry()
    registry.register(ResourceClass.PLAYER, "player", lambda connection, key: None)
    fixed_time = datetime(2026, 9, 2, 15, 30, tzinfo=timezone.utc)
    seen = []
    calls = 0

    def operation(tx):
        nonlocal calls
        calls += 1
        rng = tx.operation_context.deterministic_random()
        seen.append((tx.operation_context.started_at, tx.operation_context.randomness_seed, rng.random()))
        if calls == 1:
            raise WrapperError(FakeOrigError("40P01"))
        return "ok"

    coordinator = ResourceTransactionCoordinator(
        lambda: engine,
        lock_registry=registry,
        retry_policy=RetryPolicy(max_attempts=2, base_delay_seconds=0, max_delay_seconds=0),
        clock=lambda: fixed_time,
        seed_factory=lambda: 123456,
    )
    assert coordinator.run(
        TransactionRequest("r", "deterministic", (ResourceKey.player(1),), retry_safe=True), operation
    ) == "ok"
    assert seen[0] == seen[1]


def test_retryable_failure_while_flushing_durable_outbox_replays_entire_safe_operation() -> None:
    from datetime import datetime, timedelta, timezone
    from unittest.mock import Mock
    from gxb_backend.transactions.models import OutboxIntent

    engine = FakeEngine()
    registry = ResourceLockRegistry()
    registry.register(ResourceClass.PLAYER, "player", lambda connection, key: None)
    outbox = Mock()
    outbox.enqueue.side_effect = [WrapperError(FakeOrigError("40P01")), (101,)]
    operation_calls = []

    def operation(tx):
        operation_calls.append(tx.connection.name)
        tx.stage_outbox(
            OutboxIntent(
                "player.changed", "player", "1", {"version": 8},
                expires_at=tx.operation_context.started_at + timedelta(minutes=1),
            )
        )
        return "domain-result"

    coordinator = ResourceTransactionCoordinator(
        lambda: engine,
        lock_registry=registry,
        outbox_repository=outbox,
        retry_policy=RetryPolicy(max_attempts=2, base_delay_seconds=0, max_delay_seconds=0),
    )
    assert coordinator.run(
        TransactionRequest("r", "safe-with-outbox", (ResourceKey.player(1),), retry_safe=True), operation
    ) == "domain-result"
    assert operation_calls == ["c1", "c2"]
    assert outbox.enqueue.call_count == 2
    assert engine.connections[0].events == ["connect", "begin", "rollback", "close"]
    assert engine.connections[1].events == ["connect", "begin", "commit", "close"]


def test_retryable_outbox_flush_failure_does_not_replay_non_retry_safe_operation() -> None:
    from datetime import datetime, timedelta, timezone
    from unittest.mock import Mock
    from gxb_backend.transactions.models import OutboxIntent

    engine = FakeEngine()
    registry = ResourceLockRegistry()
    registry.register(ResourceClass.PLAYER, "player", lambda connection, key: None)
    outbox = Mock()
    outbox.enqueue.side_effect = WrapperError(FakeOrigError("40001"))
    calls = 0

    def operation(tx):
        nonlocal calls
        calls += 1
        tx.stage_outbox(
            OutboxIntent(
                "player.changed", "player", "1", {},
                expires_at=tx.operation_context.started_at + timedelta(minutes=1),
            )
        )

    coordinator = ResourceTransactionCoordinator(lambda: engine, lock_registry=registry, outbox_repository=outbox)
    with pytest.raises(WrapperError):
        coordinator.run(TransactionRequest("r", "unsafe", (ResourceKey.player(1),), retry_safe=False), operation)
    assert calls == 1
    assert len(engine.connections) == 1
