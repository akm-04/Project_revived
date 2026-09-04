"""Pass342 I3 relational identity/session/context/region directory schema.

I3 deliberately creates only the relational identity plane and a minimal player
*directory* row.  Mature PlayerState gameplay payload/state_version authority is
still JSON and remains Wave I4 scope.
"""

from __future__ import annotations

from sqlalchemy import (
    BigInteger,
    Boolean,
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    ForeignKeyConstraint,
    Index,
    Integer,
    LargeBinary,
    Sequence,
    String,
    Table,
    Text,
    UniqueConstraint,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID

from gxb_backend.foundation.schema import metadata


account_uid_seq = Sequence(
    "account_uid_seq",
    start=20_000_001,
    metadata=metadata,
    schema=metadata.schema,
)


accounts = Table(
    "accounts",
    metadata,
    Column("account_uid", Text, primary_key=True),
    Column("account_type", String(32), nullable=False, server_default="normal"),
    Column("username", Text, nullable=False),
    Column("created_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    Column("metadata", JSONB, nullable=False, server_default=text("'{}'::jsonb")),
)


account_credentials = Table(
    "account_credentials",
    metadata,
    Column("credential_id", UUID(as_uuid=True), primary_key=True),
    Column(
        "account_uid",
        Text,
        ForeignKey(f"{metadata.schema}.accounts.account_uid", ondelete="CASCADE"),
        nullable=False,
    ),
    Column("provider", String(64), nullable=False),
    Column("subject_normalized", Text, nullable=False),
    Column("password_hash", Text, nullable=True),
    Column("password_algorithm", String(48), nullable=True),
    Column("password_version", Integer, nullable=False, server_default="1"),
    Column("enabled", Boolean, nullable=False, server_default="true"),
    Column("created_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    Column("updated_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    CheckConstraint(
        "provider <> 'LOCAL_PASSWORD' OR (password_hash IS NOT NULL AND password_algorithm IS NOT NULL)",
        name="ck_account_credentials_local_password_material",
    ),
    UniqueConstraint("provider", "subject_normalized", name="uq_account_credentials_provider_subject"),
)
Index("ix_account_credentials_account_uid", account_credentials.c.account_uid)


account_sessions = Table(
    "account_sessions",
    metadata,
    Column("session_id", UUID(as_uuid=True), primary_key=True),
    Column(
        "account_uid",
        Text,
        ForeignKey(f"{metadata.schema}.accounts.account_uid", ondelete="CASCADE"),
        nullable=False,
    ),
    Column("issued_at", DateTime(timezone=True), nullable=False),
    Column("last_activity_at", DateTime(timezone=True), nullable=False),
    Column("absolute_expires_at", DateTime(timezone=True), nullable=True),
    Column("revoked_at", DateTime(timezone=True), nullable=True),
    Column("revocation_reason", String(96), nullable=True),
    Column("device_metadata", JSONB, nullable=True),
    UniqueConstraint("session_id", "account_uid", name="uq_account_sessions_session_account"),
    CheckConstraint(
        "absolute_expires_at IS NULL OR absolute_expires_at > issued_at",
        name="ck_account_sessions_absolute_expiry",
    ),
)
Index("ix_account_sessions_account_uid", account_sessions.c.account_uid)
Index("ix_account_sessions_expiry", account_sessions.c.absolute_expires_at, account_sessions.c.revoked_at)


regions = Table(
    "regions",
    metadata,
    Column("region_id", Integer, primary_key=True, autoincrement=False),
    Column("name", Text, nullable=False),
    Column("next_player_id", BigInteger, nullable=False),
    Column("max_player_id", BigInteger, nullable=False),
    Column("allow_new_players", Boolean, nullable=False, server_default="true"),
    Column("metadata", JSONB, nullable=False, server_default=text("'{}'::jsonb")),
    CheckConstraint("region_id > 0", name="ck_regions_positive_id"),
    CheckConstraint("next_player_id > 0 AND max_player_id > 0", name="ck_regions_positive_allocator"),
    CheckConstraint("next_player_id <= max_player_id + 1", name="ck_regions_allocator_bounds"),
    CheckConstraint(
        "next_player_id >= (region_id::bigint * 100000) AND "
        "max_player_id < ((region_id::bigint + 1) * 100000)",
        name="ck_regions_player_id_namespace",
    ),
)


players = Table(
    "players",
    metadata,
    Column("player_id", BigInteger, primary_key=True, autoincrement=False),
    Column(
        "account_uid",
        Text,
        ForeignKey(f"{metadata.schema}.accounts.account_uid", ondelete="RESTRICT"),
        nullable=False,
    ),
    Column(
        "region_id",
        Integer,
        ForeignKey(f"{metadata.schema}.regions.region_id", ondelete="RESTRICT"),
        nullable=False,
    ),
    Column("created_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    CheckConstraint(
        "player_id >= (region_id::bigint * 100000) AND "
        "player_id < ((region_id::bigint + 1) * 100000)",
        name="ck_players_region_encoded_id",
    ),
    UniqueConstraint("account_uid", "region_id", name="uq_players_account_region"),
    UniqueConstraint("player_id", "account_uid", "region_id", name="uq_players_identity_tuple"),
)
Index("ix_players_account_uid", players.c.account_uid)
Index("ix_players_region_id", players.c.region_id)


gameplay_contexts = Table(
    "gameplay_contexts",
    metadata,
    Column("context_id", UUID(as_uuid=True), primary_key=True),
    Column("session_id", UUID(as_uuid=True), nullable=False),
    Column("account_uid", Text, nullable=False),
    Column("region_id", Integer, nullable=False),
    Column("player_id", BigInteger, nullable=False),
    Column("created_at", DateTime(timezone=True), nullable=False),
    Column("ended_at", DateTime(timezone=True), nullable=True),
    Column("end_reason", String(96), nullable=True),
    Column(
        "superseded_by_context_id",
        UUID(as_uuid=True),
        ForeignKey(f"{metadata.schema}.gameplay_contexts.context_id", ondelete="SET NULL"),
        nullable=True,
    ),
    ForeignKeyConstraint(
        ["session_id", "account_uid"],
        [
            f"{metadata.schema}.account_sessions.session_id",
            f"{metadata.schema}.account_sessions.account_uid",
        ],
        name="fk_gameplay_contexts_session_account",
        ondelete="CASCADE",
    ),
    ForeignKeyConstraint(
        ["player_id", "account_uid", "region_id"],
        [
            f"{metadata.schema}.players.player_id",
            f"{metadata.schema}.players.account_uid",
            f"{metadata.schema}.players.region_id",
        ],
        name="fk_gameplay_contexts_player_account_region",
        ondelete="RESTRICT",
    ),
    UniqueConstraint("context_id", "session_id", name="uq_gameplay_contexts_context_session"),
    CheckConstraint("ended_at IS NULL OR ended_at >= created_at", name="ck_gameplay_contexts_end_time"),
)
Index("ix_gameplay_contexts_session_id", gameplay_contexts.c.session_id)
Index(
    "uq_gameplay_contexts_one_active_per_session",
    gameplay_contexts.c.session_id,
    unique=True,
    postgresql_where=gameplay_contexts.c.ended_at.is_(None),
)


session_credentials = Table(
    "session_credentials",
    metadata,
    Column("credential_id", UUID(as_uuid=True), primary_key=True),
    Column("credential_hash", LargeBinary, nullable=False),
    Column("kind", String(32), nullable=False),
    Column(
        "session_id",
        UUID(as_uuid=True),
        ForeignKey(f"{metadata.schema}.account_sessions.session_id", ondelete="CASCADE"),
        nullable=False,
    ),
    Column("context_id", UUID(as_uuid=True), nullable=True),
    Column("issued_at", DateTime(timezone=True), nullable=False),
    Column("expires_at", DateTime(timezone=True), nullable=True),
    Column("revoked_at", DateTime(timezone=True), nullable=True),
    CheckConstraint("octet_length(credential_hash) = 32", name="ck_session_credentials_sha256"),
    CheckConstraint(
        "kind IN ('SDK_SID_COMPAT','LOGIN_TOKEN','GAMEPLAY_TOKEN')",
        name="ck_session_credentials_kind",
    ),
    CheckConstraint(
        "(kind = 'GAMEPLAY_TOKEN' AND context_id IS NOT NULL) OR "
        "(kind IN ('SDK_SID_COMPAT','LOGIN_TOKEN') AND context_id IS NULL)",
        name="ck_session_credentials_context_binding",
    ),
    CheckConstraint("expires_at IS NULL OR expires_at > issued_at", name="ck_session_credentials_expiry"),
    ForeignKeyConstraint(
        ["context_id", "session_id"],
        [
            f"{metadata.schema}.gameplay_contexts.context_id",
            f"{metadata.schema}.gameplay_contexts.session_id",
        ],
        name="fk_session_credentials_context_session",
        ondelete="CASCADE",
    ),
    UniqueConstraint("credential_hash", name="uq_session_credentials_hash"),
)
Index("ix_session_credentials_session_id", session_credentials.c.session_id)
Index("ix_session_credentials_context_id", session_credentials.c.context_id)
Index(
    "uq_session_credentials_active_session_kind",
    session_credentials.c.session_id,
    session_credentials.c.kind,
    unique=True,
    postgresql_where=(
        session_credentials.c.revoked_at.is_(None)
        & session_credentials.c.context_id.is_(None)
    ),
)
Index(
    "uq_session_credentials_active_gameplay_context",
    session_credentials.c.context_id,
    unique=True,
    postgresql_where=(
        session_credentials.c.kind == "GAMEPLAY_TOKEN"
    ) & session_credentials.c.revoked_at.is_(None),
)


IDENTITY_TABLES = (
    accounts,
    account_credentials,
    account_sessions,
    regions,
    players,
    gameplay_contexts,
    session_credentials,
)
