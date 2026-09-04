#!/usr/bin/env python3
"""Verify Pass345 I6 remains a bounded scheduler/mail/projection wave over sealed Pass344."""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from pass_artifact_resolver import resolve_pass_artifact

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

RUNTIME = ROOT / "docs/json/PASS345_RUNTIME_DELTA_MANIFEST.json"
I6 = ROOT / "docs/json/PASS345_I6_SCHEDULER_MAIL_PROJECTION_MANIFEST.json"
P344 = ROOT / "docs/json/PASS344_SOURCE_BACKEND_CROSSCHECK.json"
EXPECTED_RUNTIME_ROOT = "4a76b2101a70a5d95f2517496916223b42adf2c922295d968b8bae73ddc86039"
EXPECTED_RUNTIME_BYTES = 83565877
EXPECTED_RUNTIME_FILES = 495


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def root_digest(paths: dict[str, Path]) -> tuple[str, int]:
    digest = hashlib.sha256()
    total = 0
    for rel in sorted(paths):
        content = paths[rel].read_bytes()
        rel_bytes = rel.encode("utf-8")
        total += len(content)
        digest.update(len(rel_bytes).to_bytes(4, "big"))
        digest.update(rel_bytes)
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return digest.hexdigest(), total


def verify_runtime() -> tuple[int, str, int]:
    data = json.loads(RUNTIME.read_text())
    if data["baseline_artifact"] != "gxb-backend-v0.58.0-pass344.0":
        raise SystemExit("PASS345 I6 INVARIANTS: FAIL baseline artifact")
    expected = data["baseline_sha256_by_path"]
    if len(expected) != EXPECTED_RUNTIME_FILES:
        raise SystemExit("PASS345 I6 INVARIANTS: FAIL runtime file count")
    observed: dict[str, Path] = {}
    drift = []
    for rel, want in expected.items():
        path = resolve_pass_artifact(ROOT, rel)
        if not path.is_file():
            drift.append((rel, want, "MISSING"))
            continue
        got = sha(path)
        observed[rel] = path
        if got != want:
            drift.append((rel, want, got))
    if drift:
        raise SystemExit("PASS345 I6 INVARIANTS: FAIL runtime drift=" + json.dumps(drift[:20]))
    digest, total = root_digest(observed)
    if digest != EXPECTED_RUNTIME_ROOT or total != EXPECTED_RUNTIME_BYTES:
        raise SystemExit(f"PASS345 I6 INVARIANTS: FAIL runtime root/bytes {digest}/{total}")
    return len(observed), digest, total


def verify_src64_and_mature_seams() -> None:
    data = json.loads(P344.read_text())
    client_rows = data.get("client_runtime_rechecked", [])
    if not client_rows:
        raise SystemExit("PASS345 I6 INVARIANTS: FAIL missing Pass344 src64 evidence")
    for row in client_rows:
        rel = row.get("path")
        want = row.get("sha256")
        if rel and want and (ROOT / rel).is_file() and sha(resolve_pass_artifact(ROOT, rel)) != want:
            raise SystemExit(f"PASS345 I6 INVARIANTS: FAIL src64 drift {rel}")
    backend_rows = {row["path"]: row for row in data.get("backend_runtime_rechecked", []) if isinstance(row, dict) and row.get("path")}
    for rel in (
        "gxb_backend/state/repository.py",
        "gxb_backend/state/multiuser_database.py",
        "gxb_backend/dispatch/engine_dispatcher.py",
        "gxb_backend/auth/perimeter.py",
    ):
        row = backend_rows.get(rel)
        if row and sha(resolve_pass_artifact(ROOT, rel)) != row["sha256"]:
            raise SystemExit(f"PASS345 I6 INVARIANTS: FAIL mature seam drift {rel}")
    if "threading.RLock()" not in (ROOT / "gxb_backend/state/repository.py").read_text():
        raise SystemExit("PASS345 I6 INVARIANTS: FAIL global RLock retired early")


def verify_i6_manifest() -> int:
    data = json.loads(I6.read_text())
    failures = []
    for rel, want in data["sha256_by_path"].items():
        path = resolve_pass_artifact(ROOT, rel)
        got = sha(path) if path.is_file() else "MISSING"
        if got != want:
            failures.append((rel, want, got))
    if failures:
        raise SystemExit("PASS345 I6 INVARIANTS: FAIL I6 hashes=" + json.dumps(failures[:20]))
    return len(data["sha256_by_path"])


def verify_scope() -> None:
    app = (ROOT / "gxb_backend/app_factory.py").read_text()
    run = (ROOT / "gxb_backend/run.py").read_text()
    combined = app + "\n" + run
    for forbidden in (
        "SchedulerProcess(",
        "SchedulerWorker(",
        "ProjectionOutboxWorker(",
        "MailRepository(",
        "gxb_backend.scheduler.runtime",
        "gxb_backend.mail.repository",
        "gxb_backend.projections.outbox",
    ):
        if forbidden in combined:
            raise SystemExit(f"PASS345 I6 INVARIANTS: FAIL I6 wired into default runtime: {forbidden}")
    if "get_player().mail_payload()" not in (ROOT / "gxb_backend/handlers/mail.py").read_text():
        raise SystemExit("PASS345 I6 INVARIANTS: FAIL legacy JSON mail handler switched before cutover")

    migration = (ROOT / "migrations/versions/0006_pass345_i6_scheduler_mail_projection.py").read_text()
    for required in ("mail_items", "rank_projection_live", "rank_snapshots", "DERIVED_PROJECTION_WORK"):
        if required not in migration:
            raise SystemExit(f"PASS345 I6 INVARIANTS: FAIL missing I6 schema {required}")
    for forbidden in ("domain_generation_rows", "shared_resources", "realtime_sessions", "CREATE TABLE scheduler_state"):
        if forbidden in migration:
            raise SystemExit(f"PASS345 I6 INVARIANTS: FAIL I6 schema creep {forbidden}")

    realtime = (ROOT / "gxb_backend/realtime/durable.py").read_text()
    if "DeliveryClass.DERIVED_PROJECTION_WORK" in realtime or "DeliveryClass.DURABLE_USER_DELIVERY" in realtime:
        raise SystemExit("PASS345 I6 INVARIANTS: FAIL realtime consumer crossed I6 partition")
    projection = (ROOT / "gxb_backend/projections/outbox.py").read_text()
    if "PROJECTION_DELIVERY_CLASSES=(DeliveryClass.DERIVED_PROJECTION_WORK,)" not in projection:
        raise SystemExit("PASS345 I6 INVARIANTS: FAIL projection consumer partition")

    scheduler_text = "\n".join(p.read_text().lower() for p in (ROOT / "gxb_backend/scheduler").glob("*.py"))
    for forbidden in ("energy_regen", "daily_reset_job", "player_regen"):
        if forbidden in scheduler_text:
            raise SystemExit(f"PASS345 I6 INVARIANTS: FAIL per-player timer fanout {forbidden}")

    mail = (ROOT / "gxb_backend/mail/service.py").read_text()
    for required in ("player_state_resource", "mail_resource", "record_or_replay", "settlement.settle"):
        if required not in mail:
            raise SystemExit(f"PASS345 I6 INVARIANTS: FAIL mail atomicity seam {required}")


def main() -> None:
    count, digest, total = verify_runtime()
    verify_src64_and_mature_seams()
    hashes = verify_i6_manifest()
    verify_scope()
    print(
        f"PASS345 I6 INVARIANTS: PASS runtime_files={count} runtime_bytes={total} "
        f"runtime_root={digest} i6_hashes={hashes}"
    )


if __name__ == "__main__":
    main()
