"""Pass345 I6 scheduler/projection/relational-mail schema."""
from __future__ import annotations
from typing import Sequence
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0006_pass345_i6"
down_revision: str | Sequence[str] | None = "0005_pass344_i5"
branch_labels = None
depends_on = None


def upgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    # Pass336 froze an explicit projection-work outbox class. I6 is the first
    # consumer wave that needs it, so extend the I2 constraint here.
    op.drop_constraint("ck_outbox_delivery_class", "outbox_events", type_="check", schema=schema)
    op.create_check_constraint(
        "ck_outbox_delivery_class",
        "outbox_events",
        "delivery_class IN ('TRANSIENT_REALTIME_NOTICE','IDEMPOTENT_REALTIME_CONTROL','DURABLE_USER_DELIVERY','DERIVED_PROJECTION_WORK')",
        schema=schema,
    )
    op.execute(f'CREATE SEQUENCE IF NOT EXISTS "{schema}".mail_protocol_id_seq START WITH 1')
    op.create_table(
        "mail_items",
        sa.Column("mail_row_id", sa.BigInteger(), sa.Identity(), nullable=False),
        sa.Column("player_id", sa.BigInteger(), nullable=False),
        sa.Column("is_region", sa.Boolean(), server_default="false", nullable=False),
        sa.Column("protocol_mail_id", sa.BigInteger(), server_default=sa.text(f'nextval(\'"{schema}".mail_protocol_id_seq\'::regclass)'), nullable=False),
        sa.Column("legacy_mail_id", sa.BigInteger(), nullable=True),
        sa.Column("delivery_key", sa.String(length=255), nullable=False),
        sa.Column("protocol_payload", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column("attachments", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'[]'::jsonb"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("read_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("claimed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("source_type", sa.String(length=96), nullable=False),
        sa.Column("source_id", sa.String(length=255), nullable=False),
        sa.Column("metadata", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.CheckConstraint("protocol_mail_id > 0", name="ck_mail_items_protocol_id_positive"),
        sa.CheckConstraint("expires_at IS NULL OR expires_at > created_at", name="ck_mail_items_expiry_after_create"),
        sa.ForeignKeyConstraint(["player_id"], [f"{schema}.players.player_id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("mail_row_id"),
        sa.UniqueConstraint("delivery_key", name="uq_mail_items_delivery_key"),
        # Source-grounded refinement: stock client identity is (is_region,id).
        sa.UniqueConstraint("player_id", "is_region", "protocol_mail_id", name="uq_mail_items_protocol_identity"),
        schema=schema,
    )
    op.create_index("ix_mail_items_player_created", "mail_items", ["player_id", sa.text("created_at DESC"), sa.text("mail_row_id DESC")], schema=schema)
    op.create_index("ix_mail_items_player_unclaimed", "mail_items", ["player_id", "claimed_at", "expires_at"], schema=schema)

    op.create_table(
        "rank_projection_live",
        sa.Column("projection_row_id", sa.BigInteger(), sa.Identity(), nullable=False),
        sa.Column("scope_type", sa.String(length=64), nullable=False),
        sa.Column("scope_id", sa.String(length=255), nullable=False),
        sa.Column("rank_type", sa.String(length=96), nullable=False),
        sa.Column("subject_type", sa.String(length=64), nullable=False),
        sa.Column("subject_id", sa.String(length=255), nullable=False),
        sa.Column("score", sa.BigInteger(), nullable=False),
        sa.Column("tiebreak", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column("source_version", sa.BigInteger(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint("source_version >= 0", name="ck_rank_projection_live_source_version"),
        sa.PrimaryKeyConstraint("projection_row_id"),
        sa.UniqueConstraint("scope_type","scope_id","rank_type","subject_type","subject_id",name="uq_rank_projection_live_identity"),
        schema=schema,
    )
    op.create_index("ix_rank_projection_live_read","rank_projection_live",["scope_type","scope_id","rank_type",sa.text("score DESC"),"subject_id"],schema=schema)

    op.create_table(
        "rank_snapshots",
        sa.Column("snapshot_row_id", sa.BigInteger(), sa.Identity(), nullable=False),
        sa.Column("scope_type", sa.String(length=64), nullable=False),
        sa.Column("scope_id", sa.String(length=255), nullable=False),
        sa.Column("rank_type", sa.String(length=96), nullable=False),
        sa.Column("generation_id", sa.String(length=255), nullable=False),
        sa.Column("snapshot_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("subject_type", sa.String(length=64), nullable=False),
        sa.Column("subject_id", sa.String(length=255), nullable=False),
        sa.Column("rank", sa.Integer(), nullable=False),
        sa.Column("score", sa.BigInteger(), nullable=False),
        sa.Column("tiebreak", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column("reward_band", sa.String(length=96), nullable=True),
        sa.Column("metadata", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.CheckConstraint("rank > 0", name="ck_rank_snapshots_rank_positive"),
        sa.PrimaryKeyConstraint("snapshot_row_id"),
        sa.UniqueConstraint("scope_type","scope_id","rank_type","generation_id","subject_type","subject_id",name="uq_rank_snapshots_generation_subject"),
        schema=schema,
    )
    op.create_index("ix_rank_snapshots_read","rank_snapshots",["scope_type","scope_id","rank_type","generation_id","rank"],schema=schema)


def downgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.drop_table("rank_snapshots", schema=schema)
    op.drop_table("rank_projection_live", schema=schema)
    op.drop_table("mail_items", schema=schema)
    op.execute(f'DROP SEQUENCE IF EXISTS "{schema}".mail_protocol_id_seq')
    op.drop_constraint("ck_outbox_delivery_class", "outbox_events", type_="check", schema=schema)
    op.create_check_constraint("ck_outbox_delivery_class", "outbox_events", "delivery_class IN ('TRANSIENT_REALTIME_NOTICE','IDEMPOTENT_REALTIME_CONTROL','DURABLE_USER_DELIVERY')", schema=schema)
