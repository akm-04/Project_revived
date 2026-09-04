"""SQLAlchemy Core repositories for Pass343 I4 aggregate persistence."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Mapping
from sqlalchemy import func, select, update
from sqlalchemy.engine import Connection

from gxb_backend.foundation.contracts import PlayerAggregateRecord
from gxb_backend.transactions.errors import StateVersionConflict
from .schema import account_global_state, players

class PlayerAggregateNotMaterialized(LookupError): pass
class PlayerIdentityMismatch(RuntimeError): pass


def _connection(transaction: Any) -> Any:
    """Accept an outer ResourceTransaction or a SQLAlchemy Connection.

    SQLAlchemy Connection itself exposes a ``.connection`` DBAPI proxy.  The
    former duck-typing check accidentally unwrapped live SQLAlchemy connections
    to psycopg, where Core statements are invalid; offline fakes did not expose
    this inherited I4 defect.
    """
    if isinstance(transaction, Connection):
        return transaction
    return transaction.connection if hasattr(transaction, "connection") else transaction

class PostgresPlayerAggregateRepository:
    def is_materialized(self, connection:Connection, player_id:int)->bool:
        row=connection.execute(select(players.c.payload).where(players.c.player_id==int(player_id))).mappings().first()
        return bool(row is not None and row.get("payload") is not None)

    def load(self, connection:Connection, player_id:int)->PlayerAggregateRecord|None:
        row=connection.execute(select(players).where(players.c.player_id==int(player_id))).mappings().first()
        if row is None:return None
        if row.get("payload") is None: raise PlayerAggregateNotMaterialized(str(player_id))
        return PlayerAggregateRecord(player_id=int(row["player_id"]),account_uid=str(row["account_uid"]),region_id=int(row["region_id"]),schema_version=int(row["schema_version"]),state_version=int(row["state_version"]),payload=dict(row["payload"]))

    def load_for_update(self, transaction:Any, player_id:int)->PlayerAggregateRecord|None:
        conn=_connection(transaction)
        stmt=select(players).where(players.c.player_id==int(player_id)).with_for_update()
        row=conn.execute(stmt).mappings().first()
        if row is None: return None
        if row.get("payload") is None: raise PlayerAggregateNotMaterialized(str(player_id))
        return PlayerAggregateRecord(player_id=int(row["player_id"]),account_uid=str(row["account_uid"]),region_id=int(row["region_id"]),schema_version=int(row["schema_version"]),state_version=int(row["state_version"]),payload=dict(row["payload"]))

    def materialize(self, transaction:Any, record:PlayerAggregateRecord)->PlayerAggregateRecord:
        conn=_connection(transaction)
        stmt=(update(players).where(players.c.player_id==int(record.player_id),players.c.account_uid==str(record.account_uid),players.c.region_id==int(record.region_id),players.c.payload.is_(None)).values(schema_version=int(record.schema_version),state_version=int(record.state_version),payload=dict(record.payload),updated_at=func.now()))
        result=conn.execute(stmt)
        if int(getattr(result,"rowcount",0) or 0)!=1: raise PlayerIdentityMismatch(f"player {record.player_id} missing, already materialized, or identity tuple mismatch")
        return record

    def save(self, transaction:Any, record:PlayerAggregateRecord, *, expected_state_version:int)->PlayerAggregateRecord:
        expected=int(expected_state_version); desired=int(record.state_version)
        if desired!=expected+1: raise StateVersionConflict(f"player:{record.player_id}", expected, desired)
        conn=_connection(transaction)
        stmt=(update(players).where(players.c.player_id==int(record.player_id),players.c.account_uid==str(record.account_uid),players.c.region_id==int(record.region_id),players.c.state_version==expected).values(schema_version=int(record.schema_version),state_version=desired,payload=dict(record.payload),updated_at=func.now()))
        result=conn.execute(stmt)
        if int(getattr(result,"rowcount",0) or 0)!=1: raise StateVersionConflict(f"player:{record.player_id}", expected)
        return record

@dataclass(frozen=True)
class AccountGlobalRecord:
    account_uid:str; schema_version:int; state_version:int; payload:Mapping[str,Any]

class AccountGlobalRepository:
    def load_for_update(self, transaction:Any, account_uid:str)->AccountGlobalRecord|None:
        conn=_connection(transaction)
        row=conn.execute(select(account_global_state).where(account_global_state.c.account_uid==str(account_uid)).with_for_update()).mappings().first()
        if row is None:return None
        return AccountGlobalRecord(str(row['account_uid']),int(row['schema_version']),int(row['state_version']),dict(row['payload']))
    def ensure_empty(self, transaction:Any, account_uid:str)->None:
        from sqlalchemy.dialects.postgresql import insert as pg_insert
        conn=_connection(transaction)
        stmt=(pg_insert(account_global_state)
              .values(account_uid=str(account_uid),schema_version=1,state_version=0,payload={})
              .on_conflict_do_nothing(index_elements=[account_global_state.c.account_uid]))
        conn.execute(stmt)
