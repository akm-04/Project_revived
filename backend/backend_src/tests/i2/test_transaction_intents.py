from __future__ import annotations

from datetime import datetime, timedelta, timezone
from unittest.mock import Mock

import pytest

from gxb_backend.foundation.contracts import TransactionRequest
from gxb_backend.transactions.coordinator import SqlAlchemyResourceTransaction
from gxb_backend.transactions.models import DeliveryClass, OutboxIntent, ScheduledJobIntent


def test_outbox_and_job_intents_flush_inside_same_transaction_connection() -> None:
    connection = Mock()
    outbox = Mock()
    jobs = Mock()
    jobs.schedule.return_value = (1, False)
    tx = SqlAlchemyResourceTransaction(TransactionRequest("r", "op", ()), connection, outbox_repository=outbox, job_repository=jobs)
    tx.stage_outbox(
        OutboxIntent(
            "notice", "player", "1", {"x": 1},
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=1),
        )
    )
    tx.stage_job(
        ScheduledJobIntent("job:1", "settle", "player", "1", datetime.now(timezone.utc), {"x": 1})
    )
    tx.flush_staged_intents()
    outbox.enqueue.assert_called_once()
    jobs.schedule.assert_called_once()
    assert outbox.enqueue.call_args.args[0] is connection
    assert jobs.schedule.call_args.args[0] is connection


def test_untyped_legacy_postcommit_seam_fails_closed() -> None:
    tx = SqlAlchemyResourceTransaction(TransactionRequest("r", "op", ()), Mock())
    with pytest.raises(ValueError, match="typed resource/expiry metadata"):
        tx.stage_post_commit("topic", {"x": 1})


def test_staged_intents_require_repository_before_flush() -> None:
    tx = SqlAlchemyResourceTransaction(TransactionRequest("r", "op", ()), Mock())
    tx.stage_outbox(
        OutboxIntent("notice", "player", "1", {}, expires_at=datetime.now(timezone.utc) + timedelta(seconds=1))
    )
    with pytest.raises(RuntimeError, match="without OutboxRepository"):
        tx.flush_staged_intents()


def test_sqlalchemy_transaction_still_satisfies_i0_resource_transaction_protocol() -> None:
    from gxb_backend.foundation.contracts import ResourceTransaction
    tx = SqlAlchemyResourceTransaction(TransactionRequest("r", "op", ()), Mock())
    assert isinstance(tx, ResourceTransaction)
