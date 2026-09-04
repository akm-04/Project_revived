#!/usr/bin/env python3
"""Current Pass351 I10 reconciliation invariant verifier.

Historical Pass348 exact-hash verifier remains immutable provenance and is not
expected to pass after explicitly authorized I10 deltas. This verifier seals the
current candidate while re-asserting the foundational runtime invariants.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def require(cond: bool, message: str) -> None:
    if not cond:
        raise SystemExit("PASS351 I10 INVARIANTS: FAIL " + message)


def main() -> None:
    version = json.loads((ROOT / "VERSION.json").read_text())
    require(version.get("pass") == "351.0", "VERSION pass")
    require(version.get("backend_version") == "0.65.0", "VERSION backend")

    report = json.loads((ROOT / "docs/json/PASS351_I10_STOCK_LIFECYCLE_RECONCILIATION.json").read_text())
    require(report.get("status") == "CANDIDATE_PENDING_STOCK_RETEST", "candidate status")
    bad = []
    for rel, expected in report.get("candidate_hashes", {}).items():
        path = ROOT / rel
        actual = sha256(path) if path.is_file() else "MISSING"
        if actual != expected:
            bad.append((rel, expected, actual))
    require(not bad, "candidate hash drift " + json.dumps(bad[:20]))

    # Foundational I9 invariants remain true even though exact Pass348 file hashes
    # are historical and later authorized I10 changes exist.
    relational = (ROOT / "gxb_backend/runtime/state_repository.py").read_text()
    legacy = (ROOT / "gxb_backend/state/repository.py").read_text()
    runtime = (ROOT / "gxb_backend/runtime/config.py").read_text()
    gunicorn = (ROOT / "deploy/gunicorn.conf.py").read_text()
    composition = (ROOT / "gxb_backend/runtime/composition.py").read_text()
    require("with self._lock" not in relational and "del self._lock" in relational, "PostgreSQL request RLock returned")
    require("threading.RLock()" in legacy and "with self._lock" in legacy, "legacy JSON RLock changed")
    require("PROVEN_HTTP_WORKER_STAGES = (1, 2, 4)" in runtime, "worker stages")
    require("workers not in (1, 2, 4)" in gunicorn and "preload_app = False" in gunicorn, "Gunicorn fork/stage policy")
    require('"legacy_rlock_retained":False' in composition.replace(" ", ""), "readiness RLock identity")

    # Pass349 pre-login fix remains bounded.
    perimeter = (ROOT / "gxb_backend/auth/perimeter.py").read_text()
    require("2_864" in perimeter and "PUBLIC_MIDS" in perimeter, "MID2864 public-bootstrap delta missing")

    # Pass350 migration-region fix remains present.
    normalize = (ROOT / "tools/dev_legacy_sandbox_normalize.py").read_text()
    require("LEGACY_SANDBOX_REGION_PLAYER_ID_REMAP" in normalize, "Pass350 sandbox remap missing")

    # Pass351 exact sentinel rule: no generic malformed ingress relaxation.
    decoder = (ROOT / "gxb_backend/transport/decoder.py").read_text()
    routes = (ROOT / "gxb_backend/transport/routes_engine.py").read_text()
    require("def is_legacy_nil_payload" in decoder and 'bytes(raw) == b"nil"' in decoder, "nil sentinel predicate")
    require("if is_legacy_nil_payload(raw):" in routes, "nil route policy")
    require('"error_kind": "MALFORMED_ENGINE_REQUEST"' in routes and "status_code=400" in routes, "generic malformed fail-closed")

    # Re-entrant MID1 and abandoned-directory-stub repair must remain present.
    credentials = (ROOT / "gxb_backend/identity/credentials.py").read_text()
    service = (ROOT / "gxb_backend/identity/service.py").read_text()
    persistence = (ROOT / "gxb_backend/persistence/repositories.py").read_text()
    require("def gameplay_token_for_context" in credentials and "gxb-gameplay-context-v1" in credentials, "context-bound deterministic bearer")
    require("old_context.region_id == region_id" in service and "resolved_retry" in service, "same-context MID1 reuse")
    require("def is_materialized" in persistence, "materialization probe")
    require("except PlayerAggregateNotMaterialized:" in relational and "self._aggregates.materialize" in relational, "stub self-heal")

    print(
        "PASS351 I10 INVARIANTS: PASS "
        f"sealed_hashes={len(report.get('candidate_hashes', {}))} "
        "i9_foundation=retained mid2864=retained nil=exact-only reentrant_mid1=bounded stub_repair=enabled"
    )


if __name__ == "__main__":
    main()
