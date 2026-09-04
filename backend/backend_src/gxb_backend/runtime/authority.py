"""Evidence-gated, one-way JSON-to-PostgreSQL runtime authority switch."""
from __future__ import annotations

import hashlib
import os
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from typing import Any, Mapping
from uuid import UUID

from sqlalchemy import select, text, update
from sqlalchemy.dialects.postgresql import insert

from gxb_backend.migration.schema import migration_runs
from .schema import runtime_authority


class RuntimeAuthorityError(RuntimeError):
    pass


@dataclass(frozen=True, slots=True)
class CutoverEvidence:
    source_archive_sha256: str
    migration_report_sha256: str
    backup_restore_report_sha256: str
    client_readiness_report_sha256: str
    immutable_json_archive_path: str
    worker_count: int = 1
    legacy_rlock_retained: bool = True
    maintenance_active: bool = True
    json_writes_stopped: bool = True
    stock_client_ready: bool = True
    src64_crosschecked: bool = True

    def validated(self) -> dict[str, Any]:
        body = asdict(self)
        for key in (
            "source_archive_sha256", "migration_report_sha256",
            "backup_restore_report_sha256", "client_readiness_report_sha256",
        ):
            value = str(body[key])
            if len(value) != 64 or any(ch not in "0123456789abcdef" for ch in value):
                raise RuntimeAuthorityError(f"{key} must be a lowercase SHA-256")
        if int(self.worker_count) != 1:
            raise RuntimeAuthorityError("I8 requires exactly one HTTP worker")
        for key in (
            "legacy_rlock_retained", "maintenance_active", "json_writes_stopped",
            "stock_client_ready", "src64_crosschecked",
        ):
            if body[key] is not True:
                raise RuntimeAuthorityError(f"cutover gate not satisfied: {key}")
        if not str(self.immutable_json_archive_path).strip():
            raise RuntimeAuthorityError("immutable JSON archive path is required")
        body["evidence_digest"] = hashlib.sha256(
            repr(sorted(body.items())).encode("utf-8")
        ).hexdigest()
        return body


class RuntimeAuthorityRepository:
    ADVISORY_LOCK_KEY = 0x4758424938  # GXB-I8

    @staticmethod
    def status(connection) -> Mapping[str, Any] | None:
        return connection.execute(select(runtime_authority)).mappings().first()

    @staticmethod
    def _lock(connection) -> None:
        connection.execute(text("SELECT pg_advisory_xact_lock(:key)"), {"key": RuntimeAuthorityRepository.ADVISORY_LOCK_KEY})

    def prepare_cutover(self, connection, *, migration_run_id: UUID | str, evidence: CutoverEvidence) -> Mapping[str, Any]:
        self._lock(connection)
        run_id = UUID(str(migration_run_id))
        run = connection.execute(
            select(migration_runs).where(migration_runs.c.migration_run_id == run_id).with_for_update()
        ).mappings().first()
        if run is None:
            raise RuntimeAuthorityError("migration run does not exist")
        if str(run["status"]) != "VALIDATED":
            raise RuntimeAuthorityError("migration run must be VALIDATED before cutover preparation")
        report = dict(run.get("report") or {})
        if report.get("status") != "VALIDATED" or report.get("traffic_open") is not False:
            raise RuntimeAuthorityError("migration validation report is incomplete")
        if report.get("secrets_redacted") is not True or int(report.get("legacy_bearers_imported", -1)) != 0:
            raise RuntimeAuthorityError("migration credential-retirement evidence is incomplete")
        counts = report.get("counts")
        if not isinstance(counts, Mapping) or int(counts.get("accounts", 0)) < 1 or int(counts.get("players", 0)) < 1:
            raise RuntimeAuthorityError("migration source/target accounting is empty")
        invariants = report.get("invariant_results") or report.get("invariants")
        if invariants is not None and (not isinstance(invariants, Mapping) or not invariants or not all(v is True for v in invariants.values())):
            raise RuntimeAuthorityError("migration validation invariants failed")
        evidence_body = evidence.validated()
        stmt = (
            insert(runtime_authority)
            .values(singleton_id=1, authority="PREPARED", migration_run_id=run_id, evidence=evidence_body)
            .on_conflict_do_nothing(index_elements=[runtime_authority.c.singleton_id])
            .returning(*runtime_authority.c)
        )
        row = connection.execute(stmt).mappings().first()
        if row is not None:
            return row
        existing = self.status(connection)
        if existing is None:
            raise RuntimeAuthorityError("runtime authority insert failed")
        if UUID(str(existing["migration_run_id"])) != run_id or dict(existing["evidence"]) != evidence_body:
            raise RuntimeAuthorityError("runtime authority already prepared with different evidence")
        return existing

    def open_traffic(self, connection, *, confirmation: str) -> Mapping[str, Any]:
        if confirmation != "OPEN POSTGRESQL TRAFFIC PERMANENTLY":
            raise RuntimeAuthorityError("exact irreversible cutover confirmation is required")
        self._lock(connection)
        current = connection.execute(select(runtime_authority).where(runtime_authority.c.singleton_id == 1).with_for_update()).mappings().first()
        if current is None:
            raise RuntimeAuthorityError("cutover is not prepared")
        if str(current["authority"]) == "TRAFFIC_OPEN":
            return current
        run_id = current["migration_run_id"]
        now = datetime.now(timezone.utc)
        changed = connection.execute(
            update(migration_runs)
            .where(migration_runs.c.migration_run_id == run_id, migration_runs.c.status == "VALIDATED")
            .values(status="TRAFFIC_OPEN", traffic_open_at=now)
        )
        if int(changed.rowcount or 0) != 1:
            raise RuntimeAuthorityError("validated migration run changed before TRAFFIC_OPEN")
        connection.execute(
            update(runtime_authority)
            .where(runtime_authority.c.singleton_id == 1, runtime_authority.c.authority == "PREPARED")
            .values(authority="TRAFFIC_OPEN", traffic_open_at=now)
        )
        return self.status(connection) or {}

    def require_postgresql(self, connection) -> Mapping[str, Any]:
        row = self.status(connection)
        if row is None or str(row["authority"]) != "TRAFFIC_OPEN":
            raise RuntimeAuthorityError("PostgreSQL runtime authority is not TRAFFIC_OPEN")
        return row

    def require_service_start(self, connection, *, maintenance_active: bool) -> Mapping[str, Any]:
        """Permit PREPARED startup only behind the physical maintenance gate."""
        row=self.status(connection)
        if row is None: raise RuntimeAuthorityError("PostgreSQL runtime authority is not prepared")
        authority=str(row["authority"])
        if authority=="TRAFFIC_OPEN": return row
        if authority=="PREPARED" and maintenance_active is True: return row
        raise RuntimeAuthorityError("PREPARED runtime may start only while the physical maintenance gate is active")


def assert_legacy_json_start_allowed() -> None:
    """Forbid outage fallback to JSON once PostgreSQL traffic has opened."""
    raw_url = str(os.environ.get("GXB_DATABASE_URL", "")).strip()
    if not raw_url:
        return
    from gxb_backend.foundation.database import DatabaseSettings, ProcessEngineProvider
    provider = ProcessEngineProvider(DatabaseSettings.from_env())
    try:
        with provider.engine().connect() as connection:
            row = RuntimeAuthorityRepository.status(connection)
            if row is not None and str(row["authority"]) == "TRAFFIC_OPEN":
                raise RuntimeAuthorityError("legacy JSON runtime is permanently disabled after TRAFFIC_OPEN")
    except RuntimeAuthorityError:
        raise
    except Exception as exc:
        raise RuntimeAuthorityError("cannot prove JSON runtime is safe while PostgreSQL is configured") from exc
    finally:
        provider.dispose()
