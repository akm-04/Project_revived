"""Safe wrappers for custom pg_dump/pg_restore I7 rehearsal artifacts."""
from __future__ import annotations

import hashlib
import os
import subprocess
from dataclasses import dataclass
from pathlib import Path

from sqlalchemy.engine import URL, make_url


@dataclass(frozen=True, slots=True)
class BackupArtifact:
    path: Path
    size: int
    sha256: str


def _require_test_database(url: str) -> None:
    name = str(make_url(url).database or "")
    if not name.endswith("_test"):
        raise ValueError("I7 backup/restore database name must end with _test")


def _libpq_url(url: str) -> tuple[str, dict[str, str]]:
    parsed = make_url(url)
    if parsed.drivername not in {"postgresql", "postgresql+psycopg"}:
        raise ValueError("only PostgreSQL URLs are supported")
    env = dict(os.environ)
    if parsed.password is not None:
        env["PGPASSWORD"] = parsed.password
    safe = URL.create(
        "postgresql", username=parsed.username, host=parsed.host, port=parsed.port,
        database=parsed.database, query=parsed.query,
    ).render_as_string(hide_password=False)
    return safe, env


def create_custom_dump(database_url: str, destination: Path, *, pg_dump: str = "pg_dump") -> BackupArtifact:
    _require_test_database(database_url)
    destination = Path(destination).resolve()
    if destination.exists():
        raise FileExistsError(f"backup destination already exists: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    safe_url, env = _libpq_url(database_url)
    subprocess.run([pg_dump, "--format=custom", "--no-owner", "--no-privileges", "--file", str(destination), "--dbname", safe_url], check=True, env=env)
    digest = hashlib.sha256()
    size = 0
    with destination.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk); size += len(chunk)
    return BackupArtifact(destination, size, digest.hexdigest())


def restore_custom_dump(database_url: str, archive: Path, *, pg_restore: str = "pg_restore") -> None:
    _require_test_database(database_url)
    archive = Path(archive).resolve()
    if not archive.is_file():
        raise FileNotFoundError(archive)
    # Caller must create a fresh disposable database. No --clean/drop behavior is hidden here.
    safe_url, env = _libpq_url(database_url)
    subprocess.run([pg_restore, "--exit-on-error", "--single-transaction", "--no-owner", "--no-privileges", "--dbname", safe_url, str(archive)], check=True, env=env)
