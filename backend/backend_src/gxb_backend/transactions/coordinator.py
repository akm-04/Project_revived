"""Pass341 ResourceTransaction implementation and whole-operation retry boundary."""

from __future__ import annotations

import random
import secrets
import time
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Callable, Mapping, TypeVar

from sqlalchemy.engine import Connection, Engine

from gxb_backend.foundation.contracts import TransactionRequest
from gxb_backend.foundation.resource_keys import order_resource_keys

from .errors import StateVersionConflict, TransactionRetryExhausted, is_retryable_transaction_error
from .locking import ResourceLockRegistry
from .models import OutboxIntent, ScheduledJobIntent
from .outbox import OutboxRepository
from .jobs import ScheduledJobRepository


T = TypeVar("T")


@dataclass(frozen=True)
class RetryPolicy:
    max_attempts: int = 3
    base_delay_seconds: float = 0.010
    max_delay_seconds: float = 0.100
    jitter_fraction: float = 0.25
    retry_state_version_conflicts: bool = True

    def __post_init__(self) -> None:
        if self.max_attempts < 1:
            raise ValueError("max_attempts must be >= 1")
        if self.base_delay_seconds < 0 or self.max_delay_seconds < 0:
            raise ValueError("retry delays must be non-negative")
        if self.max_delay_seconds < self.base_delay_seconds:
            raise ValueError("max_delay_seconds must be >= base_delay_seconds")
        if not 0 <= self.jitter_fraction <= 1:
            raise ValueError("jitter_fraction must be between 0 and 1")

    def delay_for_retry(self, retry_number: int, *, random_unit: float) -> float:
        nominal = min(self.max_delay_seconds, self.base_delay_seconds * (2 ** max(0, retry_number - 1)))
        jitter = nominal * self.jitter_fraction * ((2.0 * random_unit) - 1.0)
        return max(0.0, nominal + jitter)


@dataclass(frozen=True)
class OperationContext:
    """Stable semantic inputs shared by every internal retry attempt."""

    request: TransactionRequest
    started_at: datetime
    randomness_seed: int

    def deterministic_random(self) -> random.Random:
        return random.Random(self.randomness_seed)


class SqlAlchemyResourceTransaction:
    """One SQLAlchemy Connection/DB transaction spanning every semantic participant."""

    def __init__(
        self,
        request: TransactionRequest,
        connection: Connection,
        *,
        outbox_repository: OutboxRepository | None = None,
        job_repository: ScheduledJobRepository | None = None,
        operation_context: OperationContext | None = None,
    ) -> None:
        self._request = request
        self._connection = connection
        self._outbox_repository = outbox_repository
        self._job_repository = job_repository
        self._operation_context = operation_context or OperationContext(
            request=request, started_at=datetime.now(timezone.utc), randomness_seed=secrets.randbits(128)
        )
        self._outbox: list[OutboxIntent] = []
        self._jobs: list[ScheduledJobIntent] = []
        self._flushed = False

    @property
    def request(self) -> TransactionRequest:
        return self._request

    @property
    def connection(self) -> Connection:
        return self._connection

    @property
    def operation_context(self) -> OperationContext:
        return self._operation_context

    def stage_post_commit(self, topic: str, payload: Mapping[str, Any]) -> None:
        """Legacy I0 seam: stage a durable transient intent, never publish in-memory."""
        raise ValueError(
            "stage_post_commit requires typed resource/expiry metadata in I2; use stage_outbox()"
        )

    def stage_outbox(self, intent: OutboxIntent) -> None:
        if self._flushed:
            raise RuntimeError("transaction intents already flushed")
        if not isinstance(intent, OutboxIntent):
            raise TypeError("intent must be OutboxIntent")
        self._outbox.append(intent)

    def stage_job(self, intent: ScheduledJobIntent) -> None:
        if self._flushed:
            raise RuntimeError("transaction intents already flushed")
        if not isinstance(intent, ScheduledJobIntent):
            raise TypeError("intent must be ScheduledJobIntent")
        self._jobs.append(intent)

    def flush_staged_intents(self) -> None:
        if self._flushed:
            return
        if self._outbox:
            if self._outbox_repository is None:
                raise RuntimeError("outbox intents staged without OutboxRepository")
            self._outbox_repository.enqueue(self._connection, self._outbox)
        if self._jobs:
            if self._job_repository is None:
                raise RuntimeError("scheduled jobs staged without ScheduledJobRepository")
            for job in self._jobs:
                self._job_repository.schedule(self._connection, job)
        self._flushed = True


class ResourceTransactionCoordinator:
    """Outer transaction owner with deterministic locking and bounded whole-op retry."""

    def __init__(
        self,
        engine_provider: Callable[[], Engine],
        *,
        lock_registry: ResourceLockRegistry,
        outbox_repository: OutboxRepository | None = None,
        job_repository: ScheduledJobRepository | None = None,
        retry_policy: RetryPolicy | None = None,
        sleep: Callable[[float], None] = time.sleep,
        random_unit: Callable[[], float] = random.random,
        clock: Callable[[], datetime] | None = None,
        seed_factory: Callable[[], int] | None = None,
    ) -> None:
        self._engine_provider = engine_provider
        self._locks = lock_registry
        self._outbox = outbox_repository
        self._jobs = job_repository
        self._retry = retry_policy or RetryPolicy()
        self._sleep = sleep
        self._random_unit = random_unit
        self._clock = clock or (lambda: datetime.now(timezone.utc))
        self._seed_factory = seed_factory or (lambda: secrets.randbits(128))

    @contextmanager
    def begin(self, request: TransactionRequest, *, operation_context: OperationContext | None = None):
        """Single-attempt context manager for callers that own retry policy externally."""
        ordered_request = self._normalized_request(request)
        engine = self._engine_provider()
        with engine.connect() as connection:
            with connection.begin():
                self._locks.acquire_all(connection, ordered_request.resources)
                transaction = SqlAlchemyResourceTransaction(
                    ordered_request,
                    connection,
                    outbox_repository=self._outbox,
                    job_repository=self._jobs,
                    operation_context=operation_context,
                )
                yield transaction
                transaction.flush_staged_intents()

    def run(self, request: TransactionRequest, operation: Callable[[SqlAlchemyResourceTransaction], T]) -> T:
        """Run and, when safe, retry the complete operation from a fresh DB transaction."""
        if not callable(operation):
            raise TypeError("operation must be callable")
        normalized = self._normalized_request(request)
        operation_context = OperationContext(
            request=normalized,
            started_at=self._clock(),
            randomness_seed=self._seed_factory(),
        )
        last_error: Exception | None = None
        for attempt in range(1, self._retry.max_attempts + 1):
            try:
                with self.begin(normalized, operation_context=operation_context) as transaction:
                    return operation(transaction)
            except Exception as exc:
                retryable = normalized.retry_safe and self._should_retry(exc)
                if not retryable or attempt >= self._retry.max_attempts:
                    if retryable and attempt >= self._retry.max_attempts:
                        raise TransactionRetryExhausted(attempts=attempt, cause=exc) from exc
                    raise
                last_error = exc
                delay = self._retry.delay_for_retry(attempt, random_unit=self._random_unit())
                if delay:
                    self._sleep(delay)
        assert last_error is not None
        raise TransactionRetryExhausted(attempts=self._retry.max_attempts, cause=last_error)

    def _should_retry(self, exc: BaseException) -> bool:
        if is_retryable_transaction_error(exc):
            return True
        return self._retry.retry_state_version_conflicts and isinstance(exc, StateVersionConflict)

    @staticmethod
    def _normalized_request(request: TransactionRequest) -> TransactionRequest:
        if not isinstance(request, TransactionRequest):
            raise TypeError("request must be TransactionRequest")
        ordered = order_resource_keys(request.resources)
        return TransactionRequest(
            request_id=request.request_id,
            operation_name=request.operation_name,
            resources=ordered,
            client_operation_id=request.client_operation_id,
            retry_safe=request.retry_safe,
        )
