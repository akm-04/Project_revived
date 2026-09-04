"""Pass341 I2 receipt, outbox and scheduled-job transaction kernel."""

from __future__ import annotations

from typing import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "0002_pass341_i2"
down_revision: str | Sequence[str] | None = "0001_pass339_i0"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.create_table(
        "operation_receipts",
        sa.Column("receipt_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("resource_kind", sa.String(length=64), nullable=False),
        sa.Column("resource_key", sa.String(length=255), nullable=False),
        sa.Column("domain", sa.String(length=96), nullable=False),
        sa.Column("operation", sa.String(length=96), nullable=False),
        sa.Column("idempotency_key", sa.String(length=255), nullable=False),
        sa.Column("request_fingerprint", sa.LargeBinary(), nullable=False),
        sa.Column("actor_account_uid", sa.Text(), nullable=True),
        sa.Column("context_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("result", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("retention_policy", sa.String(length=64), server_default="STANDARD", nullable=False),
        sa.Column("committed_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint("octet_length(request_fingerprint) = 32", name="ck_operation_receipt_fingerprint_sha256"),
        sa.PrimaryKeyConstraint("receipt_id"),
        sa.UniqueConstraint(
            "resource_kind", "resource_key", "domain", "operation", "idempotency_key",
            name="uq_operation_receipt_semantic_key",
        ),
        schema=schema,
    )
    op.create_index("ix_operation_receipts_committed_at", "operation_receipts", ["committed_at"], schema=schema)

    op.create_table(
        "outbox_events",
        sa.Column("event_id", sa.BigInteger(), sa.Identity(), nullable=False),
        sa.Column("topic", sa.String(length=128), nullable=False),
        sa.Column("resource_kind", sa.String(length=64), nullable=False),
        sa.Column("resource_key", sa.String(length=255), nullable=False),
        sa.Column("context_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("delivery_class", sa.String(length=40), nullable=False),
        sa.Column("priority", sa.Integer(), server_default="100", nullable=False),
        sa.Column("available_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("dispatch_state", sa.String(length=16), server_default="PENDING", nullable=False),
        sa.Column("claimed_by", sa.String(length=128), nullable=True),
        sa.Column("claimed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("attempts", sa.Integer(), server_default="0", nullable=False),
        sa.Column("last_error", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint("attempts >= 0", name="ck_outbox_attempts_nonnegative"),
        sa.CheckConstraint(
            "delivery_class <> 'TRANSIENT_REALTIME_NOTICE' OR expires_at IS NOT NULL",
            name="ck_outbox_transient_requires_expiry",
        ),
        sa.CheckConstraint(
            "dispatch_state <> 'CLAIMED' OR (claimed_by IS NOT NULL AND claimed_at IS NOT NULL)",
            name="ck_outbox_claim_fields",
        ),
        sa.CheckConstraint(
            "delivery_class IN ('TRANSIENT_REALTIME_NOTICE','IDEMPOTENT_REALTIME_CONTROL','DURABLE_USER_DELIVERY')",
            name="ck_outbox_delivery_class",
        ),
        sa.CheckConstraint(
            "dispatch_state IN ('PENDING','CLAIMED','DISPATCHED','DONE','EXPIRED')",
            name="ck_outbox_dispatch_state",
        ),
        sa.PrimaryKeyConstraint("event_id"),
        schema=schema,
    )
    op.create_index(
        "ix_outbox_claim", "outbox_events", ["dispatch_state", "available_at", "priority", "event_id"], schema=schema
    )
    op.create_index("ix_outbox_topic_state", "outbox_events", ["topic", "dispatch_state"], schema=schema)

    op.create_table(
        "scheduled_jobs",
        sa.Column("job_id", sa.BigInteger(), sa.Identity(), nullable=False),
        sa.Column("job_type", sa.String(length=128), nullable=False),
        sa.Column("scope_type", sa.String(length=64), nullable=False),
        sa.Column("scope_id", sa.String(length=255), nullable=False),
        sa.Column("generation_id", sa.String(length=255), nullable=True),
        sa.Column("due_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(length=16), server_default="SCHEDULED", nullable=False),
        sa.Column("dedupe_key", sa.String(length=255), nullable=False),
        sa.Column("priority", sa.Integer(), server_default="100", nullable=False),
        sa.Column("attempt_count", sa.Integer(), server_default="0", nullable=False),
        sa.Column("lease_owner", sa.String(length=128), nullable=True),
        sa.Column("lease_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("last_error", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("attempt_count >= 0", name="ck_scheduled_jobs_attempt_count_nonnegative"),
        sa.CheckConstraint(
            "status <> 'RUNNING' OR (lease_owner IS NOT NULL AND lease_until IS NOT NULL)",
            name="ck_scheduled_jobs_running_lease",
        ),
        sa.CheckConstraint(
            "status IN ('SCHEDULED','RUNNING','RETRY','SUCCEEDED','CANCELLED','DEAD')",
            name="ck_scheduled_jobs_status",
        ),
        sa.PrimaryKeyConstraint("job_id"),
        sa.UniqueConstraint("dedupe_key", name="uq_scheduled_jobs_dedupe_key"),
        schema=schema,
    )
    op.create_index(
        "ix_scheduled_jobs_claim", "scheduled_jobs", ["status", "due_at", "priority", "job_id"], schema=schema
    )


def downgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.drop_index("ix_scheduled_jobs_claim", table_name="scheduled_jobs", schema=schema)
    op.drop_table("scheduled_jobs", schema=schema)
    op.drop_index("ix_outbox_topic_state", table_name="outbox_events", schema=schema)
    op.drop_index("ix_outbox_claim", table_name="outbox_events", schema=schema)
    op.drop_table("outbox_events", schema=schema)
    op.drop_index("ix_operation_receipts_committed_at", table_name="operation_receipts", schema=schema)
    op.drop_table("operation_receipts", schema=schema)
