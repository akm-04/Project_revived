"""Pass341 transaction-kernel error taxonomy and retry classification."""

from __future__ import annotations

from typing import Any


SERIALIZATION_FAILURE = "40001"
DEADLOCK_DETECTED = "40P01"
_RETRYABLE_SQLSTATES = frozenset({SERIALIZATION_FAILURE, DEADLOCK_DETECTED})


class TransactionKernelError(RuntimeError):
    """Base class for bounded I2 transaction-kernel failures."""


class StateVersionConflict(TransactionKernelError):
    def __init__(self, resource: str, expected: int, observed: int | None = None) -> None:
        self.resource = resource
        self.expected = expected
        self.observed = observed
        suffix = "" if observed is None else f", observed={observed}"
        super().__init__(f"state_version conflict for {resource}: expected={expected}{suffix}")


class ReceiptReplayConflict(TransactionKernelError):
    def __init__(self, receipt_scope: str) -> None:
        self.receipt_scope = receipt_scope
        super().__init__(f"idempotency receipt fingerprint mismatch for {receipt_scope}")


class TransactionRetryExhausted(TransactionKernelError):
    def __init__(self, attempts: int, cause: BaseException) -> None:
        self.attempts = attempts
        self.cause = cause
        super().__init__(f"transaction retry exhausted after {attempts} attempts: {cause}")


def _sqlstate_from_object(value: Any) -> str | None:
    if value is None:
        return None
    direct = getattr(value, "sqlstate", None)
    if isinstance(direct, str) and direct:
        return direct
    pgcode = getattr(value, "pgcode", None)
    if isinstance(pgcode, str) and pgcode:
        return pgcode
    diag = getattr(value, "diag", None)
    diag_state = getattr(diag, "sqlstate", None)
    if isinstance(diag_state, str) and diag_state:
        return diag_state
    return None


def sqlstate_from_exception(exc: BaseException) -> str | None:
    """Extract PostgreSQL SQLSTATE without depending on psycopg at import time."""

    seen: set[int] = set()
    current: Any = exc
    while current is not None and id(current) not in seen:
        seen.add(id(current))
        state = _sqlstate_from_object(current)
        if state:
            return state
        current = getattr(current, "orig", None) or getattr(current, "__cause__", None)
    return None


def is_retryable_transaction_error(exc: BaseException) -> bool:
    """Only whole-transaction PostgreSQL rollback classes are automatically retryable."""

    return sqlstate_from_exception(exc) in _RETRYABLE_SQLSTATES
