"""Durable I7 migration state and redacted evidence owner."""
from __future__ import annotations

from sqlalchemy import CheckConstraint, Column, DateTime, String, Table, Text, func, text
from sqlalchemy.dialects.postgresql import JSONB, UUID

from gxb_backend.foundation.schema import metadata


migration_runs = Table(
    "migration_runs",
    metadata,
    Column("migration_run_id", UUID(as_uuid=True), primary_key=True),
    Column("source_content_root", String(64), nullable=False),
    Column("source_manifest_digest", String(64), nullable=False),
    Column("target_alembic_revision", String(64), nullable=False),
    Column("status", String(32), nullable=False),
    Column("started_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    Column("validated_at", DateTime(timezone=True), nullable=True),
    Column("traffic_open_at", DateTime(timezone=True), nullable=True),
    Column("report", JSONB, nullable=False, server_default=text("'{}'::jsonb")),
    CheckConstraint(
        "status IN ('DISCOVERED','SOURCE_SNAPSHOTTED','IMPORTING','IMPORTED','VALIDATING','VALIDATED','FAILED','TRAFFIC_OPEN')",
        name="ck_migration_runs_status",
    ),
    CheckConstraint("source_content_root ~ '^[0-9a-f]{64}$'", name="ck_migration_runs_content_root"),
    CheckConstraint("source_manifest_digest ~ '^[0-9a-f]{64}$'", name="ck_migration_runs_manifest_digest"),
    CheckConstraint(
        "(status <> 'VALIDATED' AND status <> 'TRAFFIC_OPEN') OR validated_at IS NOT NULL",
        name="ck_migration_runs_validated_at",
    ),
    CheckConstraint(
        "status <> 'TRAFFIC_OPEN' OR traffic_open_at IS NOT NULL",
        name="ck_migration_runs_traffic_open_at",
    ),
)

MIGRATION_TABLES = (migration_runs,)
