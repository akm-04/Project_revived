"""Pass345 I6 durable relational mailbox schema.

The stock/current client identifies one mail by the compound pair
``(is_region, id)``.  We preserve that source-proven wire identity instead of
collapsing the two namespaces into one guessed server owner.
"""
from __future__ import annotations

from sqlalchemy import BigInteger, Boolean, CheckConstraint, Column, DateTime, ForeignKey, Identity, Index, Sequence, String, Table, Text, UniqueConstraint, func, text
from sqlalchemy.dialects.postgresql import JSONB

from gxb_backend.foundation.schema import metadata
from gxb_backend.persistence import schema as _persistence_schema  # ensure players physical owner exists

mail_protocol_id_seq = Sequence("mail_protocol_id_seq", start=1, metadata=metadata, schema=metadata.schema)

mail_items = Table(
    "mail_items",
    metadata,
    Column("mail_row_id", BigInteger, Identity(), primary_key=True),
    Column("player_id", BigInteger, ForeignKey(f"{metadata.schema}.players.player_id", ondelete="CASCADE"), nullable=False),
    Column("is_region", Boolean, nullable=False, server_default="false"),
    Column("protocol_mail_id", BigInteger, server_default=mail_protocol_id_seq.next_value(), nullable=False),
    Column("legacy_mail_id", BigInteger, nullable=True),
    Column("delivery_key", String(255), nullable=False),
    Column("protocol_payload", JSONB, nullable=False, server_default=text("'{}'::jsonb")),
    Column("attachments", JSONB, nullable=False, server_default=text("'[]'::jsonb")),
    Column("created_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    Column("expires_at", DateTime(timezone=True), nullable=True),
    Column("read_at", DateTime(timezone=True), nullable=True),
    Column("claimed_at", DateTime(timezone=True), nullable=True),
    Column("source_type", String(96), nullable=False),
    Column("source_id", String(255), nullable=False),
    Column("metadata", JSONB, nullable=False, server_default=text("'{}'::jsonb")),
    UniqueConstraint("delivery_key", name="uq_mail_items_delivery_key"),
    # Bounded I6 refinement over Pass334: source proves (is_region,id), not id alone.
    UniqueConstraint("player_id", "is_region", "protocol_mail_id", name="uq_mail_items_protocol_identity"),
    CheckConstraint("protocol_mail_id > 0", name="ck_mail_items_protocol_id_positive"),
    CheckConstraint("expires_at IS NULL OR expires_at > created_at", name="ck_mail_items_expiry_after_create"),
)
Index("ix_mail_items_player_created", mail_items.c.player_id, mail_items.c.created_at.desc(), mail_items.c.mail_row_id.desc())
Index("ix_mail_items_player_unclaimed", mail_items.c.player_id, mail_items.c.claimed_at, mail_items.c.expires_at)

MAIL_TABLES = (mail_items,)
