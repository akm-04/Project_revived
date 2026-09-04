#!/usr/bin/env python3
"""Create/check the explicitly disposable PostgreSQL I0 integration database."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

import psycopg
from psycopg import sql
from psycopg.conninfo import conninfo_to_dict, make_conninfo

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.foundation.observability import redact


_SAFE_TEST_DATABASE = re.compile(r"^[a-z_][a-z0-9_]{0,62}(?:test|_test)$")


def _database_name() -> str:
    value = os.getenv("GXB_TEST_DATABASE", "gxb_i0_test").strip()
    if not _SAFE_TEST_DATABASE.fullmatch(value):
        raise SystemExit("GXB_TEST_DATABASE must be a lowercase disposable name ending in test or _test")
    return value


def _admin_dsn() -> str:
    value = os.getenv("GXB_POSTGRES_ADMIN_DSN", "").strip()
    if not value:
        raise SystemExit("GXB_POSTGRES_ADMIN_DSN is required")
    return value


def ensure() -> dict[str, object]:
    database = _database_name()
    admin_dsn = _admin_dsn()
    with psycopg.connect(admin_dsn, autocommit=True) as connection:
        exists = connection.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s", (database,)
        ).fetchone()
        created = exists is None
        if created:
            connection.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(database)))

    parts = conninfo_to_dict(admin_dsn)
    parts["dbname"] = database
    safe_parts = dict(parts)
    safe_parts.pop("password", None)
    return {
        "status": "PASS",
        "database": database,
        "created": created,
        "connection": redact(make_conninfo(**safe_parts)),
    }


def check() -> dict[str, object]:
    database = _database_name()
    parts = conninfo_to_dict(_admin_dsn())
    parts["dbname"] = database
    with psycopg.connect(make_conninfo(**parts)) as connection:
        row = connection.execute(
            "SELECT current_database(), current_user, current_setting('transaction_isolation')"
        ).fetchone()
    return {
        "status": "PASS",
        "database": row[0],
        "user": row[1],
        "isolation": row[2],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("ensure", "check"))
    args = parser.parse_args()
    result = ensure() if args.command == "ensure" else check()
    print(json.dumps(result, sort_keys=True, separators=(",", ":")))


if __name__ == "__main__":
    main()
