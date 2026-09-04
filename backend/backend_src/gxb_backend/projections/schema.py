"""I6 derived live rank projection and immutable finalized snapshots."""
from __future__ import annotations
from sqlalchemy import BigInteger, CheckConstraint, Column, DateTime, Identity, Index, Integer, String, Table, Text, UniqueConstraint, func, text
from sqlalchemy.dialects.postgresql import JSONB
from gxb_backend.foundation.schema import metadata

rank_projection_live = Table(
    "rank_projection_live", metadata,
    Column("projection_row_id", BigInteger, Identity(), primary_key=True),
    Column("scope_type", String(64), nullable=False),
    Column("scope_id", String(255), nullable=False),
    Column("rank_type", String(96), nullable=False),
    Column("subject_type", String(64), nullable=False),
    Column("subject_id", String(255), nullable=False),
    Column("score", BigInteger, nullable=False),
    Column("tiebreak", JSONB, nullable=False, server_default=text("'{}'::jsonb")),
    Column("source_version", BigInteger, nullable=False),
    Column("updated_at", DateTime(timezone=True), nullable=False, server_default=func.now()),
    UniqueConstraint("scope_type","scope_id","rank_type","subject_type","subject_id",name="uq_rank_projection_live_identity"),
    CheckConstraint("source_version >= 0", name="ck_rank_projection_live_source_version"),
)
Index("ix_rank_projection_live_read", rank_projection_live.c.scope_type,rank_projection_live.c.scope_id,rank_projection_live.c.rank_type,rank_projection_live.c.score.desc(),rank_projection_live.c.subject_id)

rank_snapshots = Table(
    "rank_snapshots", metadata,
    Column("snapshot_row_id", BigInteger, Identity(), primary_key=True),
    Column("scope_type", String(64), nullable=False),
    Column("scope_id", String(255), nullable=False),
    Column("rank_type", String(96), nullable=False),
    Column("generation_id", String(255), nullable=False),
    Column("snapshot_at", DateTime(timezone=True), nullable=False),
    Column("subject_type", String(64), nullable=False),
    Column("subject_id", String(255), nullable=False),
    Column("rank", Integer, nullable=False),
    Column("score", BigInteger, nullable=False),
    Column("tiebreak", JSONB, nullable=False, server_default=text("'{}'::jsonb")),
    Column("reward_band", String(96), nullable=True),
    Column("metadata", JSONB, nullable=False, server_default=text("'{}'::jsonb")),
    UniqueConstraint("scope_type","scope_id","rank_type","generation_id","subject_type","subject_id",name="uq_rank_snapshots_generation_subject"),
    CheckConstraint("rank > 0", name="ck_rank_snapshots_rank_positive"),
)
Index("ix_rank_snapshots_read",rank_snapshots.c.scope_type,rank_snapshots.c.scope_id,rank_snapshots.c.rank_type,rank_snapshots.c.generation_id,rank_snapshots.c.rank)

PROJECTION_TABLES=(rank_projection_live,rank_snapshots)
