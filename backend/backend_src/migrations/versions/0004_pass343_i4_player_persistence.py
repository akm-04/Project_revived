"""Pass343 I4 PlayerState JSONB strangler and account-global foundation."""

from __future__ import annotations

from typing import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0004_pass343_i4"
down_revision: str | Sequence[str] | None = "0003_pass342_i3"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    # Nullable as a group in I4: I3 directory rows can exist before the later
    # offline migration/cutover materializes their PlayerState aggregate.
    op.add_column("players", sa.Column("schema_version", sa.Integer(), nullable=True), schema=schema)
    op.add_column("players", sa.Column("state_version", sa.BigInteger(), nullable=True), schema=schema)
    op.add_column("players", sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=True), schema=schema)
    op.add_column("players", sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True), schema=schema)
    op.create_check_constraint(
        "ck_players_i4_aggregate_all_or_none",
        "players",
        "(payload IS NULL AND schema_version IS NULL AND state_version IS NULL AND updated_at IS NULL) OR "
        "(payload IS NOT NULL AND schema_version IS NOT NULL AND schema_version > 0 AND "
        "state_version IS NOT NULL AND state_version >= 0 AND updated_at IS NOT NULL)",
        schema=schema,
    )

    op.create_table(
        "account_global_state",
        sa.Column("account_uid", sa.Text(), nullable=False),
        sa.Column("schema_version", sa.Integer(), server_default="1", nullable=False),
        sa.Column("state_version", sa.BigInteger(), server_default="0", nullable=False),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint("schema_version > 0", name="ck_account_global_schema_version"),
        sa.CheckConstraint("state_version >= 0", name="ck_account_global_state_version"),
        sa.ForeignKeyConstraint(["account_uid"], [f"{schema}.accounts.account_uid"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("account_uid"),
        schema=schema,
    )


def downgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.drop_table("account_global_state", schema=schema)
    op.drop_constraint("ck_players_i4_aggregate_all_or_none", "players", type_="check", schema=schema)
    op.drop_column("players", "updated_at", schema=schema)
    op.drop_column("players", "payload", schema=schema)
    op.drop_column("players", "state_version", schema=schema)
    op.drop_column("players", "schema_version", schema=schema)
