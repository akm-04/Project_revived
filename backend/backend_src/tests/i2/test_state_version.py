from __future__ import annotations

from unittest.mock import Mock

import pytest
from sqlalchemy import BigInteger, Column, MetaData, String, Table
from sqlalchemy.dialects import postgresql

from gxb_backend.transactions.errors import StateVersionConflict
from gxb_backend.transactions.state_version import execute_versioned_update


metadata = MetaData()
players = Table(
    "players",
    metadata,
    Column("player_id", BigInteger, primary_key=True),
    Column("state_version", BigInteger, nullable=False),
    Column("payload", String),
)


class Result:
    def __init__(self, row): self.row = row
    def first(self): return self.row


def test_versioned_update_compiles_expected_predicate_and_increment() -> None:
    connection = Mock()
    connection.execute.return_value = Result((8,))
    assert execute_versioned_update(
        connection,
        players,
        identity={"player_id": 5},
        expected_state_version=7,
        values={"payload": "x"},
        resource_label="player:5",
    ) == 8
    statement = connection.execute.call_args.args[0]
    compiled = str(statement.compile(dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True})).lower()
    assert "state_version=8" in compiled
    assert "players.state_version = 7" in compiled
    assert "players.player_id = 5" in compiled
    assert "returning players.state_version" in compiled


def test_zero_row_versioned_update_is_conflict() -> None:
    connection = Mock()
    connection.execute.return_value = Result(None)
    with pytest.raises(StateVersionConflict):
        execute_versioned_update(
            connection,
            players,
            identity={"player_id": 5},
            expected_state_version=7,
            values={"payload": "x"},
            resource_label="player:5",
        )


def test_state_version_cannot_be_overridden_by_caller() -> None:
    with pytest.raises(ValueError, match="managed"):
        execute_versioned_update(
            Mock(), players, identity={"player_id": 1}, expected_state_version=0,
            values={"state_version": 99}, resource_label="player:1"
        )
