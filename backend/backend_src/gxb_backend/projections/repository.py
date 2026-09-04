"""Repositories for rebuildable live projections and immutable final snapshots."""
from __future__ import annotations
from typing import Iterable
from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.engine import Connection
from .models import LiveProjectionRow, RankSnapshotRow
from .schema import rank_projection_live, rank_snapshots

class SnapshotConflict(RuntimeError): pass

class RankProjectionRepository:
    def upsert_live(self, connection:Connection, row:LiveProjectionRow)->str:
        values=dict(scope_type=row.scope_type,scope_id=row.scope_id,rank_type=row.rank_type,subject_type=row.subject_type,subject_id=row.subject_id,score=int(row.score),tiebreak=dict(row.tiebreak),source_version=int(row.source_version))
        stmt=(insert(rank_projection_live).values(**values).on_conflict_do_update(
            constraint="uq_rank_projection_live_identity",
            set_={"score":int(row.score),"tiebreak":dict(row.tiebreak),"source_version":int(row.source_version)},
            where=rank_projection_live.c.source_version < int(row.source_version),
        ).returning(rank_projection_live.c.source_version))
        applied=connection.execute(stmt).scalar_one_or_none()
        if applied is not None:return "APPLIED"
        current=connection.execute(select(rank_projection_live.c.source_version,rank_projection_live.c.score,rank_projection_live.c.tiebreak).where(
            rank_projection_live.c.scope_type==row.scope_type,rank_projection_live.c.scope_id==row.scope_id,rank_projection_live.c.rank_type==row.rank_type,rank_projection_live.c.subject_type==row.subject_type,rank_projection_live.c.subject_id==row.subject_id)).mappings().one()
        if int(current["source_version"])==int(row.source_version) and int(current["score"])==int(row.score) and dict(current["tiebreak"] or {})==dict(row.tiebreak): return "IDEMPOTENT"
        return "STALE"

    def replace_live_scope(self, connection:Connection, *, scope_type:str,scope_id:str,rank_type:str, rows:Iterable[LiveProjectionRow], quiesced:bool=False)->None:
        # Derived data only, but an online delete/rebuild could race a newer
        # source_version update. Require an explicit quiesced/rebuild context.
        if quiesced is not True: raise RuntimeError("live projection rebuild requires quiesced canonical source")
        connection.execute(delete(rank_projection_live).where(rank_projection_live.c.scope_type==scope_type,rank_projection_live.c.scope_id==scope_id,rank_projection_live.c.rank_type==rank_type))
        for row in rows:self.upsert_live(connection,row)

    def insert_snapshot(self, connection:Connection, row:RankSnapshotRow)->str:
        values=dict(scope_type=row.scope_type,scope_id=row.scope_id,rank_type=row.rank_type,generation_id=row.generation_id,snapshot_at=row.snapshot_at,subject_type=row.subject_type,subject_id=row.subject_id,rank=int(row.rank),score=int(row.score),tiebreak=dict(row.tiebreak),reward_band=row.reward_band,metadata=dict(row.metadata or {}))
        stmt=(insert(rank_snapshots).values(**values).on_conflict_do_nothing(constraint="uq_rank_snapshots_generation_subject").returning(rank_snapshots.c.snapshot_row_id))
        inserted=connection.execute(stmt).scalar_one_or_none()
        if inserted is not None:return "INSERTED"
        current=connection.execute(select(rank_snapshots).where(rank_snapshots.c.scope_type==row.scope_type,rank_snapshots.c.scope_id==row.scope_id,rank_snapshots.c.rank_type==row.rank_type,rank_snapshots.c.generation_id==row.generation_id,rank_snapshots.c.subject_type==row.subject_type,rank_snapshots.c.subject_id==row.subject_id)).mappings().one()
        comparable=(int(current["rank"]),int(current["score"]),dict(current["tiebreak"] or {}),current.get("reward_band"),dict(current.get("metadata") or {}))
        desired=(int(row.rank),int(row.score),dict(row.tiebreak),row.reward_band,dict(row.metadata or {}))
        if comparable!=desired: raise SnapshotConflict(f"immutable snapshot conflict for {row.generation_id}:{row.subject_id}")
        return "IDEMPOTENT"
