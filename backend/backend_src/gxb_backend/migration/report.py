"""Redacted I7 evidence serialization."""
from __future__ import annotations

import json
import os
from dataclasses import asdict
from pathlib import Path

from .models import MigrationOutcome, SourceInventory


def inventory_report(inventory: SourceInventory) -> dict[str, object]:
    return {
        "pass": "346.0", "wave": "I7", "status": "DISCOVERED",
        "source_content_root": inventory.content_root,
        "source_manifest_digest": inventory.manifest_digest,
        "counts": inventory.counts,
        "adjustments": [asdict(x) for x in inventory.adjustments],
        "warnings": list(inventory.warnings),
        "secrets_redacted": True, "legacy_bearers_imported": 0,
    }


def outcome_report(outcome: MigrationOutcome) -> dict[str, object]:
    return {
        "pass": "346.0", "wave": "I7", "mode": "OFFLINE_REHEARSAL",
        "migration_run_id": outcome.migration_run_id, "status": outcome.status,
        "source_content_root": outcome.source_content_root,
        "source_manifest_digest": outcome.source_manifest_digest,
        "counts": dict(outcome.counts), "digests": dict(outcome.digests),
        "adjustments": [asdict(x) for x in outcome.adjustments],
        "warnings": list(outcome.warnings), "mail_remaps": list(outcome.mail_remaps),
        "secrets_redacted": True, "legacy_bearers_imported": 0,
        "traffic_open": False,
    }


def manifest_report(inventory: SourceInventory) -> dict[str, object]:
    """Restricted manifest: paths can contain legacy session identifiers."""
    return {
        "schema_version": 1,
        "source_content_root": inventory.content_root,
        "source_manifest_digest": inventory.manifest_digest,
        "files": [asdict(x) for x in inventory.entries],
    }


def write_json(path: Path, payload: dict[str, object]) -> None:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def write_restricted_manifest(path: Path, inventory: SourceInventory) -> None:
    write_json(path, manifest_report(inventory))
    os.chmod(path, 0o600)


def verify_restricted_manifest(path: Path, inventory: SourceInventory) -> None:
    payload = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("snapshot manifest must be a JSON object")
    if payload != manifest_report(inventory):
        raise ValueError("snapshot does not match its restricted per-file manifest")
