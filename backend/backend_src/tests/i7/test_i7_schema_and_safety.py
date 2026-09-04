from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest
from gxb_backend.migration.backup import _libpq_url, create_custom_dump, restore_custom_dump
from gxb_backend.migration.schema import migration_runs

ROOT = Path(__file__).resolve().parents[2]


def test_i7_offline_revision_contains_state_machine() -> None:
    env = dict(os.environ)
    env["GXB_DATABASE_URL"] = "postgresql+psycopg://gxb@127.0.0.1/gxb_i7_test"
    result = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "0007_pass346_i7", "--sql"],
        cwd=ROOT, env=env, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    sql = result.stdout
    assert "0006_pass345_i6 -> 0007_pass346_i7" in sql
    assert "CREATE TABLE gxb.migration_runs" in sql
    assert "traffic_open_at" in sql
    assert "ck_migration_runs_status" in sql


def test_schema_metadata_exposes_no_secret_columns() -> None:
    assert migration_runs.c.keys() == [
        "migration_run_id", "source_content_root", "source_manifest_digest",
        "target_alembic_revision", "status", "started_at", "validated_at",
        "traffic_open_at", "report",
    ]
    assert not ({"token", "sid", "password_hash", "secret"} & set(migration_runs.c.keys()))


def test_backup_subprocess_url_does_not_expose_password() -> None:
    url, env = _libpq_url("postgresql+psycopg://person:very-secret@localhost/db_test")
    assert "very-secret" not in url
    assert env["PGPASSWORD"] == "very-secret"


@pytest.mark.parametrize("url", [
    "postgresql+psycopg://user@localhost/gxb",
    "postgresql+psycopg://user@localhost/production",
])
def test_backup_tools_refuse_non_disposable_database(url: str, tmp_path: Path) -> None:
    with pytest.raises(ValueError, match="end with _test"):
        create_custom_dump(url, tmp_path / "x.dump")
    with pytest.raises(ValueError, match="end with _test"):
        restore_custom_dump(url, tmp_path / "x.dump")
