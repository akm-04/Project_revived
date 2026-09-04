"""Pass343 I4 player/account-global persistence schema projections.

I3's ``identity.schema.players`` Table intentionally remains the historical
*directory-only* metadata object.  I4 uses a separate SQLAlchemy projection of
the same physical PostgreSQL row so importing I4 cannot mutate I3's schema
contract merely through Python import order.  Alembic revision 0004 is the
sole authority that alters the physical ``gxb.players`` table.
"""
from __future__ import annotations

from sqlalchemy import BigInteger, CheckConstraint, Column, DateTime, ForeignKey, Integer, MetaData, Table, Text, func, text
from sqlalchemy.dialects.postgresql import JSONB

from gxb_backend.foundation.schema import metadata
from gxb_backend.identity import schema as _identity_schema  # ensure accounts exist in shared metadata

# Query/update projection for the *current* physical players row.  It deliberately
# lives in separate metadata so I3's directory-only Table remains immutable.
_player_query_metadata = MetaData(schema=metadata.schema)
players = Table(
    "players",
    _player_query_metadata,
    Column("player_id", BigInteger, primary_key=True, autoincrement=False),
    Column("account_uid", Text, nullable=False),
    Column("region_id", Integer, nullable=False),
    Column("created_at", DateTime(timezone=True), nullable=False),
    Column("schema_version", Integer, nullable=True),
    Column("state_version", BigInteger, nullable=True),
    Column("payload", JSONB, nullable=True),
    Column("updated_at", DateTime(timezone=True), nullable=True),
)

# Account-global authority is new physical schema in I4, so it belongs in the
# shared Alembic metadata.  I4 initializes this as an empty explicit aggregate;
# it never infers/merges region-player VIP or progression into account scope.
account_global_state = Table(
    "account_global_state",
    metadata,
    Column(
        "account_uid",
        Text,
        ForeignKey(f"{metadata.schema}.accounts.account_uid", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column("schema_version", Integer, nullable=False, server_default="1"),
    Column("state_version", BigInteger, nullable=False, server_default="0"),
    Column("payload", JSONB, nullable=False, server_default=text("'{}'::jsonb")),
    Column("updated_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    CheckConstraint("schema_version > 0", name="ck_account_global_schema_version"),
    CheckConstraint("state_version >= 0", name="ck_account_global_state_version"),
)

PERSISTENCE_TABLES = (players, account_global_state)
