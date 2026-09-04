from __future__ import annotations

from types import SimpleNamespace

from sqlalchemy.dialects import postgresql

from gxb_backend.foundation.contracts import TransactionRequest
from gxb_backend.foundation.resource_keys import ResourceClass
from gxb_backend.persistence.locking import account_global_resource, player_state_resource, register_i4_persistence_lockers
from gxb_backend.transactions.locking import ResourceLockRegistry


class _Conn:
    def __init__(self): self.statements=[]
    def execute(self, stmt):
        self.statements.append(stmt)
        return SimpleNamespace(first=lambda: None)


def test_i4_resource_keys_land_in_frozen_classes_and_player_id_is_numeric() -> None:
    ag = account_global_resource("20000001")
    p2 = player_state_resource("2")
    p10 = player_state_resource("10")
    assert ag.resource_class is ResourceClass.ACCOUNT_GLOBAL
    assert p2.resource_class is ResourceClass.PLAYER
    assert p2.identity == (2,)
    assert p2.sort_key < p10.sort_key


def test_i4_lockers_lock_real_canonical_rows_for_update() -> None:
    registry = register_i4_persistence_lockers(ResourceLockRegistry())
    conn = _Conn()
    acquired = registry.acquire_all(conn, [player_state_resource(12500001), account_global_resource("20000001")])
    assert [r.resource_class for r in acquired] == [ResourceClass.ACCOUNT_GLOBAL, ResourceClass.PLAYER]
    sql = [str(stmt.compile(dialect=postgresql.dialect())) for stmt in conn.statements]
    assert "account_global_state" in sql[0] and "FOR UPDATE" in sql[0]
    assert "gxb.players" in sql[1] and "FOR UPDATE" in sql[1]
