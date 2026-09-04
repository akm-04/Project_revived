"""Pass341 I2 PostgreSQL transaction-kernel primitives."""

from .coordinator import OperationContext, ResourceTransactionCoordinator, RetryPolicy, SqlAlchemyResourceTransaction
from .errors import (
    ReceiptReplayConflict,
    StateVersionConflict,
    TransactionKernelError,
    TransactionRetryExhausted,
    is_retryable_transaction_error,
    sqlstate_from_exception,
)
from .jobs import ScheduledJobRepository
from .locking import ResourceLockRegistry
from .models import DeliveryClass, JobStatus, OutboxIntent, OutboxState, ReceiptKey, ScheduledJobIntent
from .outbox import OutboxRepository
from .receipts import ReceiptRepository, canonical_request_fingerprint
from .state_version import execute_versioned_update

__all__ = [
    "DeliveryClass",
    "JobStatus",
    "OutboxIntent",
    "OutboxRepository",
    "OutboxState",
    "OperationContext",
    "ReceiptKey",
    "ReceiptRepository",
    "ReceiptReplayConflict",
    "ResourceLockRegistry",
    "ResourceTransactionCoordinator",
    "RetryPolicy",
    "ScheduledJobIntent",
    "ScheduledJobRepository",
    "SqlAlchemyResourceTransaction",
    "StateVersionConflict",
    "TransactionKernelError",
    "TransactionRetryExhausted",
    "canonical_request_fingerprint",
    "execute_versioned_update",
    "is_retryable_transaction_error",
    "sqlstate_from_exception",
]
