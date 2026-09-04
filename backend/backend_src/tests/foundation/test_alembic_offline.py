from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def test_alembic_offline_upgrade_has_only_i0_namespace_plus_i2_kernel_and_is_secret_safe() -> None:
    env = dict(os.environ)
    env["PYTHONPATH"] = str(ROOT)
    env["GXB_DATABASE_URL"] = "postgresql+psycopg://gxb:offline-secret@localhost/gxb"
    result = subprocess.run(
        [sys.executable, "-m", "alembic", "upgrade", "0002_pass341_i2", "--sql"],
        cwd=ROOT,
        env=env,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    sql = result.stdout.lower()
    assert "create schema if not exists gxb" in sql
    assert "gxb_alembic_version" in sql
    for table in ("operation_receipts", "outbox_events", "scheduled_jobs"):
        assert f"create table gxb.{table}" in sql
    for future_table in ("accounts", "account_sessions", "gameplay_contexts", "regions", "players", "account_global_state", "mail_items"):
        assert f"create table gxb.{future_table}" not in sql
    assert "uq_operation_receipt_semantic_key" in sql
    assert "uq_scheduled_jobs_dedupe_key" in sql
    assert "ix_outbox_claim" in sql
    assert "ck_operation_receipt_fingerprint_sha256" in sql
    assert "ck_outbox_transient_requires_expiry" in sql
    assert "ck_outbox_claim_fields" in sql
    assert "ck_scheduled_jobs_running_lease" in sql
    assert "offline-secret" not in sql
