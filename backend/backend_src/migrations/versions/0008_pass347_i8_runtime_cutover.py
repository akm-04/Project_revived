"""Pass347 I8 production runtime and irreversible traffic-open fence."""
from __future__ import annotations
from typing import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0008_pass347_i8"
down_revision: str | Sequence[str] | None = "0007_pass346_i7"
branch_labels = None
depends_on = None


def upgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.create_table(
        "runtime_authority",
        sa.Column("singleton_id", sa.Integer(), server_default="1", nullable=False),
        sa.Column("authority", sa.String(length=32), nullable=False),
        sa.Column("migration_run_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("evidence", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column("prepared_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("traffic_open_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("singleton_id = 1", name="ck_runtime_authority_singleton"),
        sa.CheckConstraint("authority IN ('PREPARED','TRAFFIC_OPEN')", name="ck_runtime_authority_value"),
        sa.CheckConstraint("authority <> 'TRAFFIC_OPEN' OR traffic_open_at IS NOT NULL", name="ck_runtime_authority_open_time"),
        sa.ForeignKeyConstraint(["migration_run_id"], [f"{schema}.migration_runs.migration_run_id"]),
        sa.PrimaryKeyConstraint("singleton_id"), schema=schema,
    )
    op.execute(sa.text(f'''CREATE FUNCTION "{schema}".forbid_runtime_authority_reversal() RETURNS trigger
LANGUAGE plpgsql AS $$ BEGIN
  IF OLD.authority = 'TRAFFIC_OPEN' AND NEW.authority <> 'TRAFFIC_OPEN' THEN
    RAISE EXCEPTION 'TRAFFIC_OPEN is irreversible';
  END IF;
  IF OLD.migration_run_id <> NEW.migration_run_id THEN
    RAISE EXCEPTION 'runtime migration evidence is immutable';
  END IF;
  RETURN NEW;
END $$'''))
    op.execute(sa.text(f'''CREATE TRIGGER runtime_authority_no_reversal
BEFORE UPDATE ON "{schema}".runtime_authority
FOR EACH ROW EXECUTE FUNCTION "{schema}".forbid_runtime_authority_reversal()'''))
    op.execute(sa.text(f'''CREATE FUNCTION "{schema}".forbid_migration_traffic_reversal() RETURNS trigger
LANGUAGE plpgsql AS $$ BEGIN
  IF OLD.status = 'TRAFFIC_OPEN' AND NEW.status <> 'TRAFFIC_OPEN' THEN
    RAISE EXCEPTION 'migration TRAFFIC_OPEN is irreversible';
  END IF;
  RETURN NEW;
END $$'''))
    op.execute(sa.text(f'''CREATE TRIGGER migration_run_no_traffic_reversal
BEFORE UPDATE ON "{schema}".migration_runs
FOR EACH ROW EXECUTE FUNCTION "{schema}".forbid_migration_traffic_reversal()'''))


def downgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    bind = op.get_bind()
    opened = bind.execute(sa.text(f'''SELECT 1 FROM "{schema}".runtime_authority WHERE authority='TRAFFIC_OPEN' LIMIT 1''')).first()
    if opened is not None:
        raise RuntimeError("cannot downgrade after TRAFFIC_OPEN")
    op.execute(sa.text(f'DROP TRIGGER IF EXISTS migration_run_no_traffic_reversal ON "{schema}".migration_runs'))
    op.execute(sa.text(f'DROP FUNCTION IF EXISTS "{schema}".forbid_migration_traffic_reversal()'))
    op.execute(sa.text(f'DROP TRIGGER IF EXISTS runtime_authority_no_reversal ON "{schema}".runtime_authority'))
    op.execute(sa.text(f'DROP FUNCTION IF EXISTS "{schema}".forbid_runtime_authority_reversal()'))
    op.drop_table("runtime_authority", schema=schema)
