"""Singleton production-authority switch; PostgreSQL is canonical after open."""
from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, Integer, String, Table, func, text
from sqlalchemy.dialects.postgresql import JSONB, UUID

from gxb_backend.foundation.schema import DEFAULT_SCHEMA, metadata

runtime_authority = Table(
    "runtime_authority",
    metadata,
    Column("singleton_id", Integer, primary_key=True, server_default="1"),
    Column("authority", String(32), nullable=False),
    Column("migration_run_id", UUID(as_uuid=True), ForeignKey(f"{DEFAULT_SCHEMA}.migration_runs.migration_run_id"), nullable=False),
    Column("evidence", JSONB, nullable=False, server_default=text("'{}'::jsonb")),
    Column("prepared_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    Column("traffic_open_at", DateTime(timezone=True), nullable=True),
    CheckConstraint("singleton_id = 1", name="ck_runtime_authority_singleton"),
    CheckConstraint("authority IN ('PREPARED','TRAFFIC_OPEN')", name="ck_runtime_authority_value"),
    CheckConstraint("authority <> 'TRAFFIC_OPEN' OR traffic_open_at IS NOT NULL", name="ck_runtime_authority_open_time"),
)
