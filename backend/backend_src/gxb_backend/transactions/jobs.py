"""Durable scheduled-job queue primitives; execution topology remains Wave I6."""

from __future__ import annotations

from datetime import timedelta
from typing import Any, Mapping

from sqlalchemy import and_, func, or_, select, update
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.engine import Connection

from .models import JobStatus, ScheduledJobIntent
from .schema import scheduled_jobs


class ScheduledJobRepository:
    table = scheduled_jobs

    def schedule(self, connection: Connection, intent: ScheduledJobIntent) -> tuple[int, bool]:
        statement = (
            insert(self.table)
            .values(
                job_type=intent.job_type,
                scope_type=intent.scope_type,
                scope_id=intent.scope_id,
                generation_id=intent.generation_id,
                due_at=intent.due_at,
                dedupe_key=intent.dedupe_key,
                priority=intent.priority,
                payload=dict(intent.payload),
            )
            .on_conflict_do_nothing(constraint="uq_scheduled_jobs_dedupe_key")
            .returning(self.table.c.job_id)
        )
        inserted = connection.execute(statement).scalar_one_or_none()
        if inserted is not None:
            return int(inserted), False
        existing = connection.execute(
            select(self.table.c.job_id).where(self.table.c.dedupe_key == intent.dedupe_key)
        ).scalar_one()
        return int(existing), True

    def claim_due(
        self,
        connection: Connection,
        *,
        worker_id: str,
        lease_seconds: int,
        limit: int,
    ) -> tuple[Mapping[str, Any], ...]:
        if not worker_id.strip():
            raise ValueError("worker_id must not be empty")
        if isinstance(lease_seconds, bool) or not isinstance(lease_seconds, int) or lease_seconds <= 0:
            raise ValueError("lease_seconds must be a positive integer")
        if isinstance(limit, bool) or not isinstance(limit, int) or limit <= 0:
            raise ValueError("limit must be a positive integer")
        now = func.now()
        eligible = or_(
            and_(
                self.table.c.status.in_((JobStatus.SCHEDULED.value, JobStatus.RETRY.value)),
                self.table.c.due_at <= now,
            ),
            and_(
                self.table.c.status == JobStatus.RUNNING.value,
                self.table.c.lease_until.is_not(None),
                self.table.c.lease_until <= now,
            ),
        )
        candidates = (
            select(self.table.c.job_id)
            .where(eligible)
            .order_by(self.table.c.priority.asc(), self.table.c.due_at.asc(), self.table.c.job_id.asc())
            .limit(limit)
            .with_for_update(skip_locked=True)
            .cte("job_candidates")
        )
        lease_interval = timedelta(seconds=lease_seconds)
        statement = (
            update(self.table)
            .where(self.table.c.job_id.in_(select(candidates.c.job_id)))
            .values(
                status=JobStatus.RUNNING.value,
                lease_owner=worker_id,
                lease_until=now + lease_interval,
                attempt_count=self.table.c.attempt_count + 1,
                last_error=None,
            )
            .returning(*self.table.c)
        )
        rows = list(connection.execute(statement).mappings().all())
        rows.sort(key=lambda row: (int(row["priority"]), row["due_at"], int(row["job_id"])))
        return tuple(rows)

    def mark_succeeded(self, connection: Connection, job_id: int, *, worker_id: str) -> bool:
        statement = (
            update(self.table)
            .where(
                self.table.c.job_id == job_id,
                self.table.c.status == JobStatus.RUNNING.value,
                self.table.c.lease_owner == worker_id,
            )
            .values(
                status=JobStatus.SUCCEEDED.value,
                lease_owner=None,
                lease_until=None,
                completed_at=func.now(),
            )
        )
        return connection.execute(statement).rowcount == 1

    def mark_retry(self, connection: Connection, job_id: int, *, worker_id: str, error: str) -> bool:
        statement = (
            update(self.table)
            .where(
                self.table.c.job_id == job_id,
                self.table.c.status == JobStatus.RUNNING.value,
                self.table.c.lease_owner == worker_id,
            )
            .values(
                status=JobStatus.RETRY.value,
                lease_owner=None,
                lease_until=None,
                last_error=str(error)[:4000],
            )
        )
        return connection.execute(statement).rowcount == 1

    def mark_dead(self, connection: Connection, job_id: int, *, worker_id: str, error: str) -> bool:
        statement = (
            update(self.table)
            .where(
                self.table.c.job_id == job_id,
                self.table.c.status == JobStatus.RUNNING.value,
                self.table.c.lease_owner == worker_id,
            )
            .values(
                status=JobStatus.DEAD.value,
                lease_owner=None,
                lease_until=None,
                last_error=str(error)[:4000],
                completed_at=func.now(),
            )
        )
        return connection.execute(statement).rowcount == 1
