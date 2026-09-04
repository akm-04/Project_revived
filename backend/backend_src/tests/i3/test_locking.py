from __future__ import annotations

from uuid import uuid4

from sqlalchemy.dialects import postgresql

from gxb_backend.foundation.resource_keys import ResourceClass, ResourceKey
from gxb_backend.identity.locking import register_i3_identity_lockers
from gxb_backend.transactions.locking import ResourceLockRegistry


class Result:
    def first(self):
        return None


class Connection:
    def __init__(self):
        self.statements = []

    def execute(self, statement, *args, **kwargs):
        self.statements.append(statement)
        return Result()


def sql(statement) -> str:
    return str(statement.compile(dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True})).lower()


def test_i3_lockers_target_canonical_rows_and_postgresql_lock_modes() -> None:
    registry = register_i3_identity_lockers(ResourceLockRegistry())
    sid = uuid4()
    ctx = uuid4()
    resources = (
        ResourceKey.of(ResourceClass.SESSION, "account_credential", "user@example.com"),
        ResourceKey.of(ResourceClass.SESSION, "account_session", sid),
        ResourceKey.of(ResourceClass.SESSION, "account_session_liveness", sid),
        ResourceKey.of(ResourceClass.CONTEXT, "active_context_for_session", sid),
        ResourceKey.of(ResourceClass.CONTEXT, "gameplay_context_liveness", ctx),
        ResourceKey.of(ResourceClass.REGION, "region_allocator", 125),
        ResourceKey.of(ResourceClass.PLAYER, "player_directory", 12_500_001),
    )
    connection = Connection()
    registry.acquire_all(connection, resources)
    compiled = [sql(item) for item in connection.statements]
    assert "account_credentials" in compiled[0] and "for update" in compiled[0]
    assert "account_sessions" in compiled[1] and "for update" in compiled[1]
    assert "account_sessions" in compiled[2] and "for share" in compiled[2]
    assert "gameplay_contexts" in compiled[3] and "for update" in compiled[3]
    assert "gameplay_contexts" in compiled[4] and "for share" in compiled[4]
    assert "regions" in compiled[5] and "for update" in compiled[5]
    assert "players" in compiled[6] and "for share" in compiled[6]
