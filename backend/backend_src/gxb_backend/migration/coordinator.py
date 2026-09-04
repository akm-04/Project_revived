"""Explicit offline I7 state machine. This module cannot open gameplay traffic."""
from __future__ import annotations

from dataclasses import asdict
from datetime import datetime, timezone
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy.engine import Engine

from .models import MigrationOutcome, SourceInventory
from .source import MigrationSourceReader
from .validator import validate_candidate
from .writer import assert_fresh_candidate, create_run, import_inventory, update_run


class MigrationCoordinator:
    def __init__(self, engine: Engine) -> None:
        self.engine = engine

    def migrate(self, inventory: SourceInventory, *, run_id: UUID | None = None) -> MigrationOutcome:
        identifier = run_id or uuid4()
        started_at = datetime.now(timezone.utc).replace(microsecond=0)
        MigrationSourceReader.assert_stable(inventory)
        with self.engine.begin() as connection:
            assert_fresh_candidate(connection)
            create_run(connection, identifier, inventory, started_at)
            update_run(connection, identifier, "SOURCE_SNAPSHOTTED")
        try:
            with self.engine.begin() as connection:
                update_run(connection, identifier, "IMPORTING")
                counts, mail_remaps = import_inventory(connection, inventory, identifier, started_at)
                update_run(connection, identifier, "IMPORTED")
            with self.engine.begin() as connection:
                update_run(connection, identifier, "VALIDATING")
            with self.engine.begin() as connection:
                accounting = validate_candidate(connection, inventory)
                report = self._report(inventory, accounting.counts, accounting.digests, mail_remaps)
                update_run(connection, identifier, "VALIDATED", report)
            return MigrationOutcome(
                migration_run_id=str(identifier), status="VALIDATED",
                source_content_root=inventory.content_root,
                source_manifest_digest=inventory.manifest_digest,
                counts=dict(accounting.counts), digests=dict(accounting.digests),
                adjustments=inventory.adjustments, warnings=inventory.warnings,
                mail_remaps=mail_remaps,
            )
        except Exception as exc:
            redacted = {"pass": "346.0", "wave": "I7", "status": "FAILED", "error_type": type(exc).__name__, "traffic_open": False}
            try:
                with self.engine.begin() as connection:
                    update_run(connection, identifier, "FAILED", redacted)
            except Exception:
                pass
            raise

    @staticmethod
    def _report(inventory: SourceInventory, counts: Any, digests: Any, mail_remaps: Any) -> dict[str, Any]:
        return {
            "pass": "346.0", "wave": "I7", "mode": "OFFLINE_REHEARSAL",
            "status": "VALIDATED", "traffic_open": False,
            "source_content_root": inventory.content_root,
            "source_manifest_digest": inventory.manifest_digest,
            "counts": dict(counts), "digests": dict(digests),
            "adjustments": [asdict(x) for x in inventory.adjustments],
            "warnings": list(inventory.warnings), "mail_remaps": list(mail_remaps),
            "secrets_redacted": True, "legacy_bearers_imported": 0,
        }
