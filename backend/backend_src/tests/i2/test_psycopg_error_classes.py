from __future__ import annotations

from psycopg import errors

from gxb_backend.transactions.errors import is_retryable_transaction_error, sqlstate_from_exception


def test_real_psycopg_transaction_rollback_classes_match_retry_policy() -> None:
    serialization = errors.SerializationFailure("serialize")
    deadlock = errors.DeadlockDetected("deadlock")
    unique = errors.UniqueViolation("duplicate")
    assert sqlstate_from_exception(serialization) == "40001"
    assert sqlstate_from_exception(deadlock) == "40P01"
    assert sqlstate_from_exception(unique) == "23505"
    assert is_retryable_transaction_error(serialization)
    assert is_retryable_transaction_error(deadlock)
    assert not is_retryable_transaction_error(unique)
