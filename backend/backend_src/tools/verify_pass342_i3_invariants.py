#!/usr/bin/env python3
"""Verify Pass342 I3 preserves Pass341 runtime and stays inside identity scope."""
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
PASS340_RUNTIME = ROOT / "docs/json/PASS340_RUNTIME_DELTA_MANIFEST.json"
PASS341_COMMIT = ROOT / "docs/json/PASS341_IMPLEMENTATION_COMMIT.json"
I3_MANIFEST = ROOT / "docs/json/PASS342_I3_IDENTITY_MANIFEST.json"

EXPECTED_LEGACY_ROOT = "d90e6b6e73bf1bebb760a51762191e04e6d53ff55065e125cd1c989736e176f1"
EXPECTED_LEGACY_FILES = 495


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
    data = json.loads(PASS340_RUNTIME.read_text(encoding="utf-8"))
    expected = dict(data["baseline_sha256_by_path"])
    expected.update(data["allowed_modified_sha256"])
    expected.update(data["allowed_added_sha256"])
    return expected


def verify_legacy_runtime() -> tuple[str, int, int]:
    expected = pass340_expected_runtime()
    if len(expected) != EXPECTED_LEGACY_FILES:
        raise SystemExit(
            f"PASS342 I3 INVARIANTS: FAIL expected runtime count {EXPECTED_LEGACY_FILES}, got {len(expected)}"
        )
    observed: dict[str, Path] = {}
    failures = []
    for rel, wanted in expected.items():
        path = ROOT / rel
        if not path.is_file():
            failures.append((rel, wanted, "MISSING"))
            continue
        got = sha(path)
        if got != wanted:
            failures.append((rel, wanted, got))
        observed[rel] = path
    if failures:
        raise SystemExit("PASS342 I3 INVARIANTS: FAIL legacy hashes=" + json.dumps(failures[:20]))
    digest, total = root_digest(observed)
    pass340 = json.loads(PASS340_RUNTIME.read_text(encoding="utf-8"))
    if digest != pass340["current_root_sha256"] or digest != EXPECTED_LEGACY_ROOT:
        raise SystemExit(
            "PASS342 I3 INVARIANTS: FAIL legacy root "
            f"expected={EXPECTED_LEGACY_ROOT} observed={digest}"
        )
    if total != int(pass340["current_content_bytes"]):
        raise SystemExit(
            "PASS342 I3 INVARIANTS: FAIL legacy bytes "
            f"expected={pass340['current_content_bytes']} observed={total}"
        )
    return digest, total, len(observed)


def verify_pass341_kernel_preserved() -> int:
    data = json.loads(PASS341_COMMIT.read_text(encoding="utf-8"))
    hashes = data["implementation_sha256"]
    intentionally_changed = {
        "gxb_backend/foundation/schema.py",
        "migrations/env.py",
        "tests/foundation/test_alembic_offline.py",
        "VERSION.json",
        "gxb_backend/version.py",
        "pyproject.toml",
    }
    failures = []
    checked = 0
    for rel, wanted in hashes.items():
        if rel in intentionally_changed:
            continue
        path = ROOT / rel
        got = sha(path) if path.is_file() else "MISSING"
        if got != wanted:
            failures.append((rel, wanted, got))
        checked += 1
    if failures:
        raise SystemExit("PASS342 I3 INVARIANTS: FAIL Pass341 kernel drift=" + json.dumps(failures[:20]))
    return checked


def verify_i3_manifest() -> int:
    data = json.loads(I3_MANIFEST.read_text(encoding="utf-8"))
    failures = []
    for rel, wanted in data["sha256_by_path"].items():
        path = ROOT / rel
        got = sha(path) if path.is_file() else "MISSING"
        if got != wanted:
            failures.append((rel, wanted, got))
    if failures:
        raise SystemExit("PASS342 I3 INVARIANTS: FAIL I3 hashes=" + json.dumps(failures[:20]))
    return len(data["sha256_by_path"])


def verify_scope_and_unwired() -> None:
    from gxb_backend.identity.schema import IDENTITY_TABLES, players

    expected_tables = {
        "accounts",
        "account_credentials",
        "account_sessions",
        "regions",
        "players",
        "gameplay_contexts",
        "session_credentials",
    }
    names = {table.name for table in IDENTITY_TABLES}
    if names != expected_tables:
        raise SystemExit(f"PASS342 I3 INVARIANTS: FAIL identity tables {sorted(names)}")
    if set(players.c.keys()) != {"player_id", "account_uid", "region_id", "created_at"}:
        raise SystemExit("PASS342 I3 INVARIANTS: FAIL I4 PlayerState fields leaked into players")

    allowed_importers = {"gxb_backend/foundation/schema.py"}
    hits = []
    for path in (ROOT / "gxb_backend").rglob("*.py"):
        rel = path.relative_to(ROOT).as_posix()
        if rel.startswith("gxb_backend/identity/") or rel in allowed_importers:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        if "gxb_backend.identity" in text or "RelationalAuthAdapter" in text or "ContextSelectionService" in text:
            hits.append(rel)
    if hits:
        raise SystemExit(f"PASS342 I3 INVARIANTS: FAIL identity plane wired into mature runtime: {hits}")

    identity_text = "\n".join(
        p.read_text(encoding="utf-8", errors="replace")
        for p in sorted((ROOT / "gxb_backend/identity").glob("*.py"))
    )
    for forbidden in ("SANDBOX_SID", "SANDBOX_TOKEN", "AdminRoot"):
        if forbidden in identity_text:
            raise SystemExit(f"PASS342 I3 INVARIANTS: FAIL forbidden sandbox authority string {forbidden}")

    future_tables = {
        "player_state",
        "player_states",
        "account_global_state",
        "mail_items",
        "shared_resources",
        "global_projections",
    }
    if names & future_tables:
        raise SystemExit(f"PASS342 I3 INVARIANTS: FAIL future schema creep {sorted(names & future_tables)}")


def main() -> None:
    root, total, runtime_count = verify_legacy_runtime()
    preserved = verify_pass341_kernel_preserved()
    i3_count = verify_i3_manifest()
    verify_scope_and_unwired()
    print(
        "PASS342 I3 INVARIANTS: PASS "
        f"legacy_files={runtime_count} legacy_bytes={total} legacy_root={root} "
        f"pass341_preserved={preserved} i3_hashes={i3_count}"
    )


if __name__ == "__main__":
    main()
