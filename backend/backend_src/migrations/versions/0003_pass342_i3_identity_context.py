"""Pass342 I3 relational identity/session/context/region-directory authority."""

from __future__ import annotations

from typing import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "0003_pass342_i3"
down_revision: str | Sequence[str] | None = "0002_pass341_i2"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _region_seed_rows() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []
    for region_id in range(1, 201):
        rows.append(
            {
                "region_id": region_id,
                "name": "Deep Valley" if region_id == 125 else f"Local-{region_id}",
                "next_player_id": region_id * 100_000 + 1,
                "max_player_id": (region_id + 1) * 100_000 - 1,
                "allow_new_players": True,
            }
        )
    return rows


def upgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.execute(sa.schema.CreateSequence(sa.Sequence("account_uid_seq", schema=schema, start=20_000_001)))

    op.create_table(
        "accounts",
        sa.Column("account_uid", sa.Text(), nullable=False),
        sa.Column("account_type", sa.String(length=32), server_default="normal", nullable=False),
        sa.Column("username", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("metadata", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.PrimaryKeyConstraint("account_uid"),
        schema=schema,
    )

    op.create_table(
        "account_credentials",
        sa.Column("credential_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("account_uid", sa.Text(), nullable=False),
        sa.Column("provider", sa.String(length=64), nullable=False),
        sa.Column("subject_normalized", sa.Text(), nullable=False),
        sa.Column("password_hash", sa.Text(), nullable=True),
        sa.Column("password_algorithm", sa.String(length=48), nullable=True),
        sa.Column("password_version", sa.Integer(), server_default="1", nullable=False),
        sa.Column("enabled", sa.Boolean(), server_default="true", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint(
            "provider <> 'LOCAL_PASSWORD' OR (password_hash IS NOT NULL AND password_algorithm IS NOT NULL)",
            name="ck_account_credentials_local_password_material",
        ),
        sa.ForeignKeyConstraint(["account_uid"], [f"{schema}.accounts.account_uid"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("credential_id"),
        sa.UniqueConstraint("provider", "subject_normalized", name="uq_account_credentials_provider_subject"),
        schema=schema,
    )
    op.create_index("ix_account_credentials_account_uid", "account_credentials", ["account_uid"], schema=schema)

    op.create_table(
        "account_sessions",
        sa.Column("session_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("account_uid", sa.Text(), nullable=False),
        sa.Column("issued_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_activity_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("absolute_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("revocation_reason", sa.String(length=96), nullable=True),
        sa.Column("device_metadata", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.UniqueConstraint("session_id", "account_uid", name="uq_account_sessions_session_account"),
        sa.CheckConstraint(
            "absolute_expires_at IS NULL OR absolute_expires_at > issued_at",
            name="ck_account_sessions_absolute_expiry",
        ),
        sa.ForeignKeyConstraint(["account_uid"], [f"{schema}.accounts.account_uid"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("session_id"),
        schema=schema,
    )
    op.create_index("ix_account_sessions_account_uid", "account_sessions", ["account_uid"], schema=schema)
    op.create_index("ix_account_sessions_expiry", "account_sessions", ["absolute_expires_at", "revoked_at"], schema=schema)

    op.create_table(
        "regions",
        sa.Column("region_id", sa.Integer(), autoincrement=False, nullable=False),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("next_player_id", sa.BigInteger(), nullable=False),
        sa.Column("max_player_id", sa.BigInteger(), nullable=False),
        sa.Column("allow_new_players", sa.Boolean(), server_default="true", nullable=False),
        sa.Column("metadata", postgresql.JSONB(astext_type=sa.Text()), server_default=sa.text("'{}'::jsonb"), nullable=False),
        sa.CheckConstraint("region_id > 0", name="ck_regions_positive_id"),
        sa.CheckConstraint("next_player_id > 0 AND max_player_id > 0", name="ck_regions_positive_allocator"),
        sa.CheckConstraint("next_player_id <= max_player_id + 1", name="ck_regions_allocator_bounds"),
        sa.CheckConstraint(
            "next_player_id >= (region_id::bigint * 100000) AND max_player_id < ((region_id::bigint + 1) * 100000)",
            name="ck_regions_player_id_namespace",
        ),
        sa.PrimaryKeyConstraint("region_id"),
        schema=schema,
    )
    regions_seed_table = sa.table(
        "regions",
        sa.column("region_id", sa.Integer()),
        sa.column("name", sa.Text()),
        sa.column("next_player_id", sa.BigInteger()),
        sa.column("max_player_id", sa.BigInteger()),
        sa.column("allow_new_players", sa.Boolean()),
        schema=schema,
    )
    op.bulk_insert(regions_seed_table, _region_seed_rows())

    op.create_table(
        "players",
        sa.Column("player_id", sa.BigInteger(), autoincrement=False, nullable=False),
        sa.Column("account_uid", sa.Text(), nullable=False),
        sa.Column("region_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint(
            "player_id >= (region_id::bigint * 100000) AND player_id < ((region_id::bigint + 1) * 100000)",
            name="ck_players_region_encoded_id",
        ),
        sa.ForeignKeyConstraint(["account_uid"], [f"{schema}.accounts.account_uid"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["region_id"], [f"{schema}.regions.region_id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("player_id"),
        sa.UniqueConstraint("account_uid", "region_id", name="uq_players_account_region"),
        sa.UniqueConstraint("player_id", "account_uid", "region_id", name="uq_players_identity_tuple"),
        schema=schema,
    )
    op.create_index("ix_players_account_uid", "players", ["account_uid"], schema=schema)
    op.create_index("ix_players_region_id", "players", ["region_id"], schema=schema)

    op.create_table(
        "gameplay_contexts",
        sa.Column("context_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("session_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("account_uid", sa.Text(), nullable=False),
        sa.Column("region_id", sa.Integer(), nullable=False),
        sa.Column("player_id", sa.BigInteger(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("end_reason", sa.String(length=96), nullable=True),
        sa.Column("superseded_by_context_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.CheckConstraint("ended_at IS NULL OR ended_at >= created_at", name="ck_gameplay_contexts_end_time"),
        sa.ForeignKeyConstraint(
            ["session_id", "account_uid"],
            [f"{schema}.account_sessions.session_id", f"{schema}.account_sessions.account_uid"],
            name="fk_gameplay_contexts_session_account",
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["player_id", "account_uid", "region_id"],
            [f"{schema}.players.player_id", f"{schema}.players.account_uid", f"{schema}.players.region_id"],
            name="fk_gameplay_contexts_player_account_region",
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["superseded_by_context_id"], [f"{schema}.gameplay_contexts.context_id"], ondelete="SET NULL"
        ),
        sa.PrimaryKeyConstraint("context_id"),
        sa.UniqueConstraint("context_id", "session_id", name="uq_gameplay_contexts_context_session"),
        schema=schema,
    )
    op.create_index("ix_gameplay_contexts_session_id", "gameplay_contexts", ["session_id"], schema=schema)
    op.create_index(
        "uq_gameplay_contexts_one_active_per_session",
        "gameplay_contexts",
        ["session_id"],
        unique=True,
        postgresql_where=sa.text("ended_at IS NULL"),
        schema=schema,
    )

    op.create_table(
        "session_credentials",
        sa.Column("credential_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("credential_hash", sa.LargeBinary(), nullable=False),
        sa.Column("kind", sa.String(length=32), nullable=False),
        sa.Column("session_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("context_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("issued_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("octet_length(credential_hash) = 32", name="ck_session_credentials_sha256"),
        sa.CheckConstraint(
            "kind IN ('SDK_SID_COMPAT','LOGIN_TOKEN','GAMEPLAY_TOKEN')",
            name="ck_session_credentials_kind",
        ),
        sa.CheckConstraint(
            "(kind = 'GAMEPLAY_TOKEN' AND context_id IS NOT NULL) OR (kind IN ('SDK_SID_COMPAT','LOGIN_TOKEN') AND context_id IS NULL)",
            name="ck_session_credentials_context_binding",
        ),
        sa.CheckConstraint("expires_at IS NULL OR expires_at > issued_at", name="ck_session_credentials_expiry"),
        sa.ForeignKeyConstraint(["session_id"], [f"{schema}.account_sessions.session_id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(
            ["context_id", "session_id"],
            [f"{schema}.gameplay_contexts.context_id", f"{schema}.gameplay_contexts.session_id"],
            name="fk_session_credentials_context_session",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("credential_id"),
        sa.UniqueConstraint("credential_hash", name="uq_session_credentials_hash"),
        schema=schema,
    )
    op.create_index("ix_session_credentials_session_id", "session_credentials", ["session_id"], schema=schema)
    op.create_index("ix_session_credentials_context_id", "session_credentials", ["context_id"], schema=schema)
    op.create_index(
        "uq_session_credentials_active_session_kind",
        "session_credentials",
        ["session_id", "kind"],
        unique=True,
        postgresql_where=sa.text("revoked_at IS NULL AND context_id IS NULL"),
        schema=schema,
    )
    op.create_index(
        "uq_session_credentials_active_gameplay_context",
        "session_credentials",
        ["context_id"],
        unique=True,
        postgresql_where=sa.text("kind = 'GAMEPLAY_TOKEN' AND revoked_at IS NULL"),
        schema=schema,
    )


def downgrade() -> None:
    schema = op.get_context().config.attributes.get("gxb_schema", "gxb")
    op.drop_index("uq_session_credentials_active_gameplay_context", table_name="session_credentials", schema=schema)
    op.drop_index("uq_session_credentials_active_session_kind", table_name="session_credentials", schema=schema)
    op.drop_index("ix_session_credentials_context_id", table_name="session_credentials", schema=schema)
    op.drop_index("ix_session_credentials_session_id", table_name="session_credentials", schema=schema)
    op.drop_table("session_credentials", schema=schema)
    op.drop_index("uq_gameplay_contexts_one_active_per_session", table_name="gameplay_contexts", schema=schema)
    op.drop_index("ix_gameplay_contexts_session_id", table_name="gameplay_contexts", schema=schema)
    op.drop_table("gameplay_contexts", schema=schema)
    op.drop_index("ix_players_region_id", table_name="players", schema=schema)
    op.drop_index("ix_players_account_uid", table_name="players", schema=schema)
    op.drop_table("players", schema=schema)
    op.drop_table("regions", schema=schema)
    op.drop_index("ix_account_sessions_expiry", table_name="account_sessions", schema=schema)
    op.drop_index("ix_account_sessions_account_uid", table_name="account_sessions", schema=schema)
    op.drop_table("account_sessions", schema=schema)
    op.drop_index("ix_account_credentials_account_uid", table_name="account_credentials", schema=schema)
    op.drop_table("account_credentials", schema=schema)
    op.drop_table("accounts", schema=schema)
    op.execute(sa.schema.DropSequence(sa.Sequence("account_uid_seq", schema=schema)))
