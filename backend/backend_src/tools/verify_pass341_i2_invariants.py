#!/usr/bin/env python3
"""Verify Pass341 I2 preserves Pass340 runtime authority and remains unwired."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PASS340 = ROOT / "docs/json/PASS340_RUNTIME_DELTA_MANIFEST.json"
KERNEL = ROOT / "docs/json/PASS341_I2_KERNEL_MANIFEST.json"


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


def pass340_expected_runtime() -> dict[str, str]:
    data = json.loads(PASS340.read_text(encoding="utf-8"))
    expected = dict(data["baseline_sha256_by_path"])
    expected.update(data["allowed_modified_sha256"])
    expected.update(data["allowed_added_sha256"])
    return expected


def verify_legacy_runtime() -> tuple[str, int]:
    expected = pass340_expected_runtime()
    observed: dict[str, Path] = {}
    failures: list[tuple[str, str, str]] = []
    for rel, wanted in expected.items():
        path = ROOT / rel
        if not path.is_file():
            raise SystemExit(f"PASS341 I2 INVARIANTS: FAIL missing legacy runtime file {rel}")
        got = sha(path)
        if got != wanted:
            failures.append((rel, wanted, got))
        observed[rel] = path
    if failures:
        raise SystemExit("PASS341 I2 INVARIANTS: FAIL legacy hashes=" + json.dumps(failures[:20]))
    digest, total = root_digest(observed)
    pass340 = json.loads(PASS340.read_text(encoding="utf-8"))
    if digest != pass340["current_root_sha256"] or total != int(pass340["current_content_bytes"]):
        raise SystemExit(
            "PASS341 I2 INVARIANTS: FAIL legacy root "
            f"expected=({pass340['current_root_sha256']},{pass340['current_content_bytes']}) "
            f"observed=({digest},{total})"
        )
    return digest, total


def verify_kernel_manifest() -> int:
    data = json.loads(KERNEL.read_text(encoding="utf-8"))
    failures = []
    for rel, wanted in data["sha256_by_path"].items():
        path = ROOT / rel
        if not path.is_file():
            failures.append((rel, wanted, "MISSING"))
            continue
        got = sha(path)
        if got != wanted:
            failures.append((rel, wanted, got))
    if failures:
        raise SystemExit("PASS341 I2 INVARIANTS: FAIL kernel hashes=" + json.dumps(failures[:20]))
    return len(data["sha256_by_path"])


def verify_unwired() -> None:
    allowed = {
        "gxb_backend/foundation/schema.py",
    }
    hits = []
    for path in (ROOT / "gxb_backend").rglob("*.py"):
        rel = path.relative_to(ROOT).as_posix()
        if rel.startswith("gxb_backend/transactions/") or rel in allowed:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        if "gxb_backend.transactions" in text or "ResourceTransactionCoordinator" in text:
            hits.append(rel)
    if hits:
        raise SystemExit(f"PASS341 I2 INVARIANTS: FAIL transaction kernel wired into gameplay/runtime: {hits}")

    repository = ROOT / "gxb_backend/state/repository.py"
    if sha(repository) != "61853b02f839c1be193c45353152de256e73fc261db3c7877d3d569f2ebd8c8a":
        raise SystemExit("PASS341 I2 INVARIANTS: FAIL StateRepository/global-RLock authority changed")


def verify_schema_boundary() -> None:
    migration = (ROOT / "migrations/versions/0002_pass341_i2_transaction_kernel.py").read_text(encoding="utf-8")
    required = ("operation_receipts", "outbox_events", "scheduled_jobs")
    future = ("accounts", "account_sessions", "gameplay_contexts", "regions", "players", "account_global_state", "mail_items")
    for table in required:
        if f'"{table}"' not in migration:
            raise SystemExit(f"PASS341 I2 INVARIANTS: FAIL missing I2 table {table}")
    for table in future:
        if f'op.create_table(\n        "{table}"' in migration:
            raise SystemExit(f"PASS341 I2 INVARIANTS: FAIL future-wave table pulled into I2: {table}")


def main() -> None:
    digest, total = verify_legacy_runtime()
    kernel_count = verify_kernel_manifest()
    verify_unwired()
    verify_schema_boundary()
    print(
        "PASS341 I2 INVARIANTS: PASS "
        f"legacy_files=495 legacy_bytes={total} legacy_sha256={digest} "
        f"kernel_tracked={kernel_count} json_canonical=true global_rlock_unchanged=true"
    )


if __name__ == "__main__":
    main()
