from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest
from sqlalchemy.dialects import postgresql

from gxb_backend.foundation.contracts import PlayerAggregateRecord
from gxb_backend.persistence.repositories import AccountGlobalRepository, PlayerIdentityMismatch, PostgresPlayerAggregateRepository
from gxb_backend.transactions.errors import StateVersionConflict


def _record(version: int = 5) -> PlayerAggregateRecord:
    return PlayerAggregateRecord(
        player_id=12_500_001,
        account_uid="20000001",
        region_id=125,
        schema_version=6,
        state_version=version,
        payload={"identity": {"player_name": "I4"}, "domains": {}},
    )


class _ExecuteCapture:
    def __init__(self, *, rowcount=1, mapping=None):
        self.rowcount = rowcount
        self.mapping = mapping
        self.statements = []

    def execute(self, statement):
        self.statements.append(statement)
        if self.mapping is not None:
            first = MagicMock(return_value=self.mapping)
            mappings = MagicMock()
            mappings.first = first
            return SimpleNamespace(mappings=lambda: mappings)
        return SimpleNamespace(rowcount=self.rowcount)




def test_is_materialized_distinguishes_directory_stub_from_jsonb_aggregate() -> None:
    repo = PostgresPlayerAggregateRepository()
    assert repo.is_materialized(_ExecuteCapture(mapping={"payload": None}), 12_500_001) is False
    assert repo.is_materialized(_ExecuteCapture(mapping={"payload": {"identity": {}}}), 12_500_001) is True

def test_load_for_update_uses_player_primary_key_and_row_lock() -> None:
    rec = _record()
    row = {
        "player_id": rec.player_id,
        "account_uid": rec.account_uid,
        "region_id": rec.region_id,
        "schema_version": rec.schema_version,
        "state_version": rec.state_version,
        "payload": dict(rec.payload),
    }
    conn = _ExecuteCapture(mapping=row)
    loaded = PostgresPlayerAggregateRepository().load_for_update(conn, rec.player_id)
    assert loaded == rec
    sql = str(conn.statements[0].compile(dialect=postgresql.dialect()))
    assert "FOR UPDATE" in sql
    assert "gxb.players.player_id" in sql


def test_save_requires_exact_one_version_increment_and_identity_tuple_predicate() -> None:
    repo = PostgresPlayerAggregateRepository()
    conn = _ExecuteCapture(rowcount=1)
    result = repo.save(conn, _record(6), expected_state_version=5)
    assert result.state_version == 6
    sql = str(conn.statements[0].compile(dialect=postgresql.dialect()))
    assert "gxb.players.player_id" in sql
    assert "gxb.players.account_uid" in sql
    assert "gxb.players.region_id" in sql
    assert "gxb.players.state_version" in sql

    with pytest.raises(StateVersionConflict):
        repo.save(_ExecuteCapture(rowcount=1), _record(8), expected_state_version=5)


def test_zero_row_save_is_state_version_conflict_not_silent_overwrite() -> None:
    with pytest.raises(StateVersionConflict) as exc:
        PostgresPlayerAggregateRepository().save(_ExecuteCapture(rowcount=0), _record(6), expected_state_version=5)
    assert exc.value.resource == "player:12500001"
    assert exc.value.expected == 5


def test_materialize_only_updates_matching_unmaterialized_i3_directory_row() -> None:
    conn = _ExecuteCapture(rowcount=1)
    PostgresPlayerAggregateRepository().materialize(conn, _record())
    sql = str(conn.statements[0].compile(dialect=postgresql.dialect()))
    assert "gxb.players.payload IS NULL" in sql
    assert "gxb.players.account_uid" in sql
    assert "gxb.players.region_id" in sql
    with pytest.raises(PlayerIdentityMismatch):
        PostgresPlayerAggregateRepository().materialize(_ExecuteCapture(rowcount=0), _record())


def test_account_global_empty_row_uses_semantic_account_key_on_conflict() -> None:
    conn = _ExecuteCapture(rowcount=1)
    AccountGlobalRepository().ensure_empty(conn, "20000001")
    sql = str(conn.statements[0].compile(dialect=postgresql.dialect()))
    assert "ON CONFLICT (account_uid) DO NOTHING" in sql
    assert "account_global_state" in sql
