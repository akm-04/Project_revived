#!/usr/bin/env python3
"""Verify Pass346 stays an offline migration/recovery rehearsal wave."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify_manifest() -> int:
    manifest = json.loads((ROOT / "docs/json/PASS346_I7_MIGRATION_MANIFEST.json").read_text(encoding="utf-8"))
    failures = []
    for rel, expected in manifest["sha256_by_path"].items():
        path = ROOT / rel
        actual = sha(path) if path.is_file() else "MISSING"
        if actual != expected:
            failures.append((rel, expected, actual))
    if failures:
        raise SystemExit("PASS346 I7 INVARIANTS: FAIL hashes=" + json.dumps(failures[:20]))
    return len(manifest["sha256_by_path"])


def verify_previous_wave() -> None:
    manifest = json.loads((ROOT / "docs/json/PASS345_I6_SCHEDULER_MAIL_PROJECTION_MANIFEST.json").read_text(encoding="utf-8"))
    allowed = {"gxb_backend/foundation/schema.py", "migrations/env.py"}
    failures = []
    for rel, expected in manifest["sha256_by_path"].items():
        if rel in allowed:
            continue
        path = ROOT / rel
        actual = sha(path) if path.is_file() else "MISSING"
        if actual != expected:
            failures.append((rel, expected, actual))
    if failures:
        raise SystemExit("PASS346 I7 INVARIANTS: FAIL I6 drift=" + json.dumps(failures[:20]))


def verify_scope() -> None:
    runtime = (ROOT / "gxb_backend/app_factory.py").read_text(encoding="utf-8") + (ROOT / "gxb_backend/run.py").read_text(encoding="utf-8")
    if "gxb_backend.migration" in runtime or "MigrationCoordinator" in runtime:
        raise SystemExit("PASS346 I7 INVARIANTS: FAIL migration wired into default runtime")
    if "threading.RLock()" not in (ROOT / "gxb_backend/state/repository.py").read_text(encoding="utf-8"):
        raise SystemExit("PASS346 I7 INVARIANTS: FAIL global RLock retired early")
    if "get_player().mail_payload()" not in (ROOT / "gxb_backend/handlers/mail.py").read_text(encoding="utf-8"):
        raise SystemExit("PASS346 I7 INVARIANTS: FAIL JSON mail authority cut over early")

    source = (ROOT / "gxb_backend/migration/source.py").read_text(encoding="utf-8")
    for forbidden in ("MultiUserDatabase", ".load_player(", "TRAFFIC_OPEN"):
        if forbidden in source:
            raise SystemExit(f"PASS346 I7 INVARIANTS: FAIL source reader contains {forbidden}")
    coordinator = (ROOT / "gxb_backend/migration/coordinator.py").read_text(encoding="utf-8")
    if 'update_run(connection, identifier, "TRAFFIC_OPEN"' in coordinator:
        raise SystemExit("PASS346 I7 INVARIANTS: FAIL I7 can open traffic")
    cli = (ROOT / "tools/pass346_i7_migrate.py").read_text(encoding="utf-8")
    for required in ("--snapshot-root", "--expected-content-root", "--manifest", "endswith(\"_test\")"):
        if required not in cli:
            raise SystemExit(f"PASS346 I7 INVARIANTS: FAIL CLI guard missing {required}")


def main() -> None:
    count = verify_manifest()
    verify_previous_wave()
    verify_scope()
    print(f"PASS346 I7 INVARIANTS: PASS i7_hashes={count} traffic_open=false rlock=retained")


if __name__ == "__main__":
    main()
