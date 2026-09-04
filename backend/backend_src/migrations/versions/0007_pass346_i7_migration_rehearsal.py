"""Pass346 I7 offline migration-run state and candidate evidence."""
from __future__ import annotations

from typing import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0007_pass346_i7"
down_revision: str | Sequence[str] | None = "0006_pass345_i6"
branch_labels = None
depends_on = None


def upgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.create_table(
        "migration_runs",
        sa.Column("migration_run_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("source_content_root", sa.String(length=64), nullable=False),
        sa.Column("source_manifest_digest", sa.String(length=64), nullable=False),
        sa.Column("target_alembic_revision", sa.String(length=64), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("validated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("traffic_open_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("report", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.CheckConstraint(
            "status IN ('DISCOVERED','SOURCE_SNAPSHOTTED','IMPORTING','IMPORTED','VALIDATING','VALIDATED','FAILED','TRAFFIC_OPEN')",
            name="ck_migration_runs_status",
        ),
        sa.CheckConstraint("source_content_root ~ '^[0-9a-f]{64}$'", name="ck_migration_runs_content_root"),
        sa.CheckConstraint("source_manifest_digest ~ '^[0-9a-f]{64}$'", name="ck_migration_runs_manifest_digest"),
        sa.CheckConstraint(
            "(status <> 'VALIDATED' AND status <> 'TRAFFIC_OPEN') OR validated_at IS NOT NULL",
            name="ck_migration_runs_validated_at",
        ),
        sa.CheckConstraint("status <> 'TRAFFIC_OPEN' OR traffic_open_at IS NOT NULL", name="ck_migration_runs_traffic_open_at"),
        sa.PrimaryKeyConstraint("migration_run_id"),
        schema=schema,
    )
    op.create_index("ix_migration_runs_status_started", "migration_runs", ["status", "started_at"], schema=schema)


def downgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.drop_index("ix_migration_runs_status_started", table_name="migration_runs", schema=schema)
    op.drop_table("migration_runs", schema=schema)
