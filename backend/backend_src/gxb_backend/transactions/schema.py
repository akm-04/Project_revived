"""Pass341 I2 durable transaction-kernel tables.

Only receipt, outbox and scheduled-job authority lands in I2. Identity/session,
regions and PlayerState tables remain gated to later waves.
"""

from __future__ import annotations

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    Column,
    DateTime,
    Identity,
    Index,
    Integer,
    LargeBinary,
    String,
    Table,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID

from gxb_backend.foundation.schema import metadata


operation_receipts = Table(
    "operation_receipts",
    metadata,
    Column("receipt_id", UUID(as_uuid=True), primary_key=True),
    Column("resource_kind", String(64), nullable=False),
    Column("resource_key", String(255), nullable=False),
    Column("domain", String(96), nullable=False),
    Column("operation", String(96), nullable=False),
    Column("idempotency_key", String(255), nullable=False),
    Column("request_fingerprint", LargeBinary, nullable=False),
    Column("actor_account_uid", Text, nullable=True),
    Column("context_id", UUID(as_uuid=True), nullable=True),
    Column("result", JSONB, nullable=False),
    Column("retention_policy", String(64), nullable=False, server_default="STANDARD"),
    Column("committed_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    CheckConstraint("octet_length(request_fingerprint) = 32", name="ck_operation_receipt_fingerprint_sha256"),
    UniqueConstraint(
        "resource_kind",
        "resource_key",
        "domain",
        "operation",
        "idempotency_key",
        name="uq_operation_receipt_semantic_key",
    ),
)
Index("ix_operation_receipts_committed_at", operation_receipts.c.committed_at)


outbox_events = Table(
    "outbox_events",
    metadata,
    Column("event_id", BigInteger, Identity(), primary_key=True),
    Column("topic", String(128), nullable=False),
    Column("resource_kind", String(64), nullable=False),
    Column("resource_key", String(255), nullable=False),
    Column("context_id", UUID(as_uuid=True), nullable=True),
    Column("payload", JSONB, nullable=False),
    Column("delivery_class", String(40), nullable=False),
    Column("priority", Integer, nullable=False, server_default="100"),
    Column("available_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    Column("expires_at", DateTime(timezone=True), nullable=True),
    Column("dispatch_state", String(16), nullable=False, server_default="PENDING"),
    Column("claimed_by", String(128), nullable=True),
    Column("claimed_at", DateTime(timezone=True), nullable=True),
    Column("published_at", DateTime(timezone=True), nullable=True),
    Column("attempts", Integer, nullable=False, server_default="0"),
    Column("last_error", Text, nullable=True),
    Column("created_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    CheckConstraint(
        "delivery_class IN ('TRANSIENT_REALTIME_NOTICE','IDEMPOTENT_REALTIME_CONTROL','DURABLE_USER_DELIVERY','DERIVED_PROJECTION_WORK')",
        name="ck_outbox_delivery_class",
    ),
    CheckConstraint(
        "dispatch_state IN ('PENDING','CLAIMED','DISPATCHED','DONE','EXPIRED')",
        name="ck_outbox_dispatch_state",
    ),
    CheckConstraint("attempts >= 0", name="ck_outbox_attempts_nonnegative"),
    CheckConstraint(
        "delivery_class <> 'TRANSIENT_REALTIME_NOTICE' OR expires_at IS NOT NULL",
        name="ck_outbox_transient_requires_expiry",
    ),
    CheckConstraint(
        "dispatch_state <> 'CLAIMED' OR (claimed_by IS NOT NULL AND claimed_at IS NOT NULL)",
        name="ck_outbox_claim_fields",
    ),
)
Index(
    "ix_outbox_claim",
    outbox_events.c.dispatch_state,
    outbox_events.c.available_at,
    outbox_events.c.priority,
    outbox_events.c.event_id,
)
Index("ix_outbox_topic_state", outbox_events.c.topic, outbox_events.c.dispatch_state)


scheduled_jobs = Table(
    "scheduled_jobs",
    metadata,
    Column("job_id", BigInteger, Identity(), primary_key=True),
    Column("job_type", String(128), nullable=False),
    Column("scope_type", String(64), nullable=False),
    Column("scope_id", String(255), nullable=False),
    Column("generation_id", String(255), nullable=True),
    Column("due_at", DateTime(timezone=True), nullable=False),
    Column("status", String(16), nullable=False, server_default="SCHEDULED"),
    Column("dedupe_key", String(255), nullable=False),
    Column("priority", Integer, nullable=False, server_default="100"),
    Column("attempt_count", Integer, nullable=False, server_default="0"),
    Column("lease_owner", String(128), nullable=True),
    Column("lease_until", DateTime(timezone=True), nullable=True),
    Column("payload", JSONB, nullable=False),
    Column("last_error", Text, nullable=True),
    Column("created_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    Column("completed_at", DateTime(timezone=True), nullable=True),
    UniqueConstraint("dedupe_key", name="uq_scheduled_jobs_dedupe_key"),
    CheckConstraint(
        "status IN ('SCHEDULED','RUNNING','RETRY','SUCCEEDED','CANCELLED','DEAD')",
        name="ck_scheduled_jobs_status",
    ),
    CheckConstraint("attempt_count >= 0", name="ck_scheduled_jobs_attempt_count_nonnegative"),
    CheckConstraint(
        "status <> 'RUNNING' OR (lease_owner IS NOT NULL AND lease_until IS NOT NULL)",
        name="ck_scheduled_jobs_running_lease",
    ),
)
Index(
    "ix_scheduled_jobs_claim",
    scheduled_jobs.c.status,
    scheduled_jobs.c.due_at,
    scheduled_jobs.c.priority,
    scheduled_jobs.c.job_id,
)
