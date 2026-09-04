from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from gxb_backend.identity.schema import players as i3_players
from gxb_backend.persistence.schema import account_global_state, players as i4_players

ROOT = Path(__file__).resolve().parents[2]


def _offline_head_sql() -> str:
    env = dict(os.environ)
    env["PYTHONPATH"] = str(ROOT)
    env["GXB_DATABASE_URL"] = "postgresql+psycopg://gxb:pass343-secret@localhost/gxb"
    result = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "0004_pass343_i4", "--sql"],
        cwd=ROOT,
        env=env,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    return result.stdout.lower()


def test_i4_query_projection_does_not_mutate_i3_directory_metadata() -> None:
    assert set(i3_players.c.keys()) == {"player_id", "account_uid", "region_id", "created_at"}
    assert set(i4_players.c.keys()) == {
        "player_id", "account_uid", "region_id", "created_at",
        "schema_version", "state_version", "payload", "updated_at",
    }
    assert set(i3_players.c.keys()) == {"player_id", "account_uid", "region_id", "created_at"}


def test_i4_account_global_schema_is_explicit_empty_aggregate_boundary() -> None:
    assert set(account_global_state.c.keys()) == {
        "account_uid", "schema_version", "state_version", "payload", "updated_at"
    }


def test_offline_alembic_i4_adds_only_player_aggregate_and_account_global_foundation() -> None:
    sql = _offline_head_sql()
    assert "running upgrade 0003_pass342_i3 -> 0004_pass343_i4" in sql
    for column in ("schema_version integer", "state_version bigint", "payload jsonb", "updated_at timestamp with time zone"):
        assert f"alter table gxb.players add column {column}" in sql
    assert "ck_players_i4_aggregate_all_or_none" in sql
    assert "create table gxb.account_global_state" in sql
    for forbidden in (
        "create table gxb.mail_items",
        "create table gxb.shared_resources",
        "create table gxb.global_projections",
        "create table gxb.player_states",
    ):
        assert forbidden not in sql
    assert "pass343-secret" not in sql
