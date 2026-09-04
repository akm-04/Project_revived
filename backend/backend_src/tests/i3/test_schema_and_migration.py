from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from gxb_backend.identity.repositories import RegionDirectoryRepository
from gxb_backend.identity.schema import IDENTITY_TABLES, players


ROOT = Path(__file__).resolve().parents[2]


def test_i3_schema_is_identity_directory_only_not_playerstate_authority() -> None:
    names = {table.name for table in IDENTITY_TABLES}
    assert names == {
        "accounts",
        "account_credentials",
        "account_sessions",
        "regions",
        "players",
        "gameplay_contexts",
        "session_credentials",
    }
    assert set(players.c.keys()) == {"player_id", "account_uid", "region_id", "created_at"}
    for forbidden in ("payload", "state", "state_version", "schema_version", "player_json", "mail"):
        assert forbidden not in players.c


def test_compatibility_region_catalog_is_exact_current_backend_namespace() -> None:
    rows = RegionDirectoryRepository.compatibility_seed_rows()
    assert len(rows) == 200
    assert rows[0]["region_id"] == 1
    assert rows[0]["next_player_id"] == 100_001
    assert rows[0]["max_player_id"] == 199_999
    assert rows[124]["region_id"] == 125
    assert rows[124]["name"] == "Deep Valley"
    assert rows[-1]["region_id"] == 200
    assert rows[-1]["next_player_id"] == 20_000_001
    assert rows[-1]["max_player_id"] == 20_099_999


def test_offline_alembic_i3_creates_only_i2_plus_identity_plane_and_seeds_regions() -> None:
    env = dict(os.environ)
    env["PYTHONPATH"] = str(ROOT)
    env["GXB_DATABASE_URL"] = "postgresql+psycopg://gxb:pass342-secret@localhost/gxb"
    result = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "0003_pass342_i3", "--sql"],
        cwd=ROOT,
        env=env,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    sql = result.stdout.lower()
    assert "create sequence gxb.account_uid_seq start with 20000001" in sql
    for table in (
        "operation_receipts",
        "outbox_events",
        "scheduled_jobs",
        "accounts",
        "account_credentials",
        "account_sessions",
        "regions",
        "players",
        "gameplay_contexts",
        "session_credentials",
    ):
        assert f"create table gxb.{table}" in sql
    for future in (
        "account_global_state",
        "mail_items",
        "shared_resources",
        "global_projections",
        "player_state",
        "player_states",
    ):
        assert f"create table gxb.{future}" not in sql
    assert sql.count("insert into gxb.regions") == 200
    assert "(125, 'deep valley', 12500001, 12599999, true)" in sql
    assert "uq_players_account_region" in sql
    assert "uq_gameplay_contexts_one_active_per_session" in sql
    assert "uq_session_credentials_hash" in sql
    # Region and player IDs are allocated by explicit frozen authority; no hidden
    # PostgreSQL SERIAL/BIGSERIAL sequences may compete with those allocators.
    assert "region_id serial" not in sql
    assert "player_id bigserial" not in sql
    assert "create sequence gxb.regions_region_id_seq" not in sql
    assert "create sequence gxb.players_player_id_seq" not in sql
    assert "pass342-secret" not in sql


def test_i3_schema_enforces_context_session_account_player_binding_at_database_boundary() -> None:
    from sqlalchemy import ForeignKeyConstraint, UniqueConstraint
    from gxb_backend.identity.schema import account_sessions, gameplay_contexts, session_credentials

    assert "account_uid" in gameplay_contexts.c
    session_uniques = {
        constraint.name
        for constraint in account_sessions.constraints
        if isinstance(constraint, UniqueConstraint)
    }
    assert "uq_account_sessions_session_account" in session_uniques

    context_fks = {
        constraint.name: tuple(column.name for column in constraint.columns)
        for constraint in gameplay_contexts.constraints
        if isinstance(constraint, ForeignKeyConstraint)
    }
    assert context_fks["fk_gameplay_contexts_session_account"] == ("session_id", "account_uid")
    assert context_fks["fk_gameplay_contexts_player_account_region"] == (
        "player_id",
        "account_uid",
        "region_id",
    )

    credential_fks = {
        constraint.name: tuple(column.name for column in constraint.columns)
        for constraint in session_credentials.constraints
        if isinstance(constraint, ForeignKeyConstraint)
    }
    assert credential_fks["fk_session_credentials_context_session"] == (
        "context_id",
        "session_id",
    )
