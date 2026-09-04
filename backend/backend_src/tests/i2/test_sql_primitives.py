from __future__ import annotations

from datetime import datetime, timezone
from unittest.mock import Mock

from sqlalchemy.dialects import postgresql

from gxb_backend.transactions.jobs import ScheduledJobRepository
from gxb_backend.transactions.models import ScheduledJobIntent
from gxb_backend.transactions.outbox import OutboxRepository


class CaptureResult:
    rowcount = 1
    def mappings(self): return self
    def all(self): return []
    def scalar_one_or_none(self): return None
    def scalar_one(self): return 42


def compile_first_statement(callable_):
    connection = Mock()
    connection.execute.return_value = CaptureResult()
    callable_(connection)
    statement = connection.execute.call_args_list[0].args[0]
    return str(statement.compile(dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True})).lower()


def test_outbox_claim_uses_skip_locked_and_stable_priority_event_order() -> None:
    sql = compile_first_statement(lambda c: OutboxRepository().claim_available(c, worker_id="gw-1", limit=8))
    assert "for update skip locked" in sql
    assert "order by gxb.outbox_events.priority asc, gxb.outbox_events.event_id asc" in sql
    assert "dispatch_state" in sql and "claimed" in sql


def test_job_claim_uses_skip_locked_and_reclaims_expired_running_lease() -> None:
    sql = compile_first_statement(lambda c: ScheduledJobRepository().claim_due(c, worker_id="sched-1", lease_seconds=30, limit=4))
    assert "for update skip locked" in sql
    assert "scheduled" in sql and "retry" in sql and "running" in sql
    assert "lease_until" in sql
    assert "attempt_count" in sql


def test_job_schedule_uses_unique_dedupe_constraint() -> None:
    connection = Mock()
    result = CaptureResult()
    result.scalar_one_or_none = lambda: 9
    connection.execute.return_value = result
    intent = ScheduledJobIntent(
        "season:7:finalize", "finalize", "generation", "7",
        datetime(2026, 9, 2, tzinfo=timezone.utc), {"generation": 7}
    )
    assert ScheduledJobRepository().schedule(connection, intent) == (9, False)
    sql = str(connection.execute.call_args.args[0].compile(dialect=postgresql.dialect())).lower()
    assert "on conflict on constraint uq_scheduled_jobs_dedupe_key do nothing" in sql


def test_outbox_stale_claim_requeue_targets_claimed_rows_only() -> None:
    connection = Mock()
    connection.execute.return_value = CaptureResult()
    assert OutboxRepository().requeue_stale_claims(connection, stale_after_seconds=30) == 1
    sql = str(connection.execute.call_args.args[0].compile(dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True})).lower()
    assert "dispatch_state = 'claimed'" in sql
    assert "claimed_at" in sql
    assert "now()" in sql and "make_interval(secs=>30.0)" in sql
    assert "dispatch_state='pending'" in sql.replace(" ", "") or "dispatch_state = 'pending'" in sql


def test_outbox_stale_claim_requeue_requires_positive_timeout() -> None:
    import pytest
    with pytest.raises(ValueError, match="positive integer"):
        OutboxRepository().requeue_stale_claims(Mock(), stale_after_seconds=0)
