#!/usr/bin/env python3
"""Inventory, snapshot, import and validate an offline Pass299 JSON source."""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from alembic import command
from alembic.config import Config

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.foundation.database import DatabaseSettings, ProcessEngineProvider
from gxb_backend.migration.coordinator import MigrationCoordinator
from gxb_backend.migration.report import (
    inventory_report, outcome_report, verify_restricted_manifest,
    write_json, write_restricted_manifest,
)
from gxb_backend.migration.source import MigrationSourceReader


def _reader_inventory(args: argparse.Namespace):
    reader = MigrationSourceReader()
    if args.sandbox_file:
        return reader.legacy_sandbox_fixture(Path(args.sandbox_file))
    root = getattr(args, "snapshot_root", None) or getattr(args, "source_root", None)
    inventory = reader.inventory(Path(root))
    expected = getattr(args, "expected_content_root", None)
    if expected is not None and expected != inventory.content_root:
        raise SystemExit("snapshot content root does not match --expected-content-root")
    return inventory


def _emit(payload: dict[str, object], report: str | None) -> None:
    if report:
        write_json(Path(report), payload)
    print(json.dumps(payload, indent=2, sort_keys=True))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    inventory_parser = sub.add_parser("inventory")
    inventory_source = inventory_parser.add_mutually_exclusive_group(required=True)
    inventory_source.add_argument("--source-root")
    inventory_source.add_argument("--sandbox-file")
    inventory_parser.add_argument("--report")
    inventory_parser.add_argument("--manifest")
    for name in ("migrate", "validate"):
        item = sub.add_parser(name)
        source = item.add_mutually_exclusive_group(required=True)
        source.add_argument("--snapshot-root")
        source.add_argument("--sandbox-file")
        item.add_argument("--expected-content-root")
        item.add_argument("--manifest")
        item.add_argument("--report")
    snapshot = sub.add_parser("snapshot")
    snapshot.add_argument("--source-root", required=True)
    snapshot.add_argument("--destination", required=True)
    snapshot.add_argument("--report")
    snapshot.add_argument("--manifest", required=True)
    args = parser.parse_args()

    reader = MigrationSourceReader()
    if args.command == "snapshot":
        inventory = reader.snapshot(Path(args.source_root), Path(args.destination))
        write_restricted_manifest(Path(args.manifest), inventory)
        _emit(inventory_report(inventory), args.report)
        return
    inventory = _reader_inventory(args)
    if args.command == "inventory":
        if args.manifest:
            write_restricted_manifest(Path(args.manifest), inventory)
        _emit(inventory_report(inventory), args.report)
        return
    if args.snapshot_root and (not args.expected_content_root or not args.manifest):
        raise SystemExit("--expected-content-root and --manifest are required for immutable snapshot migration/validation")
    if args.snapshot_root:
        verify_restricted_manifest(Path(args.manifest), inventory)

    env = dict(os.environ)
    if not env.get("GXB_DATABASE_URL") and env.get("GXB_TEST_DATABASE_URL"):
        env["GXB_DATABASE_URL"] = env["GXB_TEST_DATABASE_URL"]
        os.environ["GXB_DATABASE_URL"] = env["GXB_DATABASE_URL"]
    settings = DatabaseSettings.from_env(env)
    if not str(settings.url.database or "").endswith("_test"):
        raise SystemExit("I7 rehearsal database name must end with _test")
    command.upgrade(Config(str(ROOT / "alembic.ini")), "head")
    provider = ProcessEngineProvider(settings)
    try:
        if args.command == "validate":
            from gxb_backend.migration.validator import validate_candidate
            with provider.engine().begin() as connection:
                accounting = validate_candidate(connection, inventory)
            _emit({
                "pass": "346.0", "wave": "I7", "mode": "RESTORED_CANDIDATE_VALIDATION",
                "status": "VALIDATED", "source_content_root": inventory.content_root,
                "source_manifest_digest": inventory.manifest_digest,
                "counts": dict(accounting.counts), "digests": dict(accounting.digests),
                "invariants": dict(accounting.invariant_results), "traffic_open": False,
                "secrets_redacted": True, "legacy_bearers_imported": 0,
            }, args.report)
            return
        outcome = MigrationCoordinator(provider.engine()).migrate(inventory)
        _emit(outcome_report(outcome), args.report)
    finally:
        provider.dispose()


if __name__ == "__main__":
    main()
