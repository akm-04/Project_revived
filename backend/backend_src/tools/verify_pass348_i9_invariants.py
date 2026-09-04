#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from pass_artifact_resolver import resolve_pass_artifact


ROOT = Path(__file__).resolve().parents[1]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    manifest = json.loads((ROOT / "docs/json/PASS348_I9_MANIFEST.json").read_text())
    drift = []
    for relative, expected in manifest["sha256_by_path"].items():
        path = resolve_pass_artifact(ROOT, relative)
        actual = sha256(path) if path.is_file() else "MISSING"
        if actual != expected:
            drift.append((relative, expected, actual))
    if drift:
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL " + json.dumps(drift[:20]))

    relational = (ROOT / "gxb_backend/runtime/state_repository.py").read_text()
    legacy = (ROOT / "gxb_backend/state/repository.py").read_text()
    runtime = (ROOT / "gxb_backend/runtime/config.py").read_text()
    gunicorn = (ROOT / "deploy/gunicorn.conf.py").read_text()
    composition = (ROOT / "gxb_backend/runtime/composition.py").read_text()
    mail = (ROOT / "gxb_backend/mail/repository.py").read_text()
    dispatcher = (ROOT / "gxb_backend/dispatch/engine_dispatcher.py").read_text()
    identity_errors = (ROOT / "gxb_backend/identity/errors.py").read_text()
    if "with self._lock" in relational or "del self._lock" not in relational:
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL PostgreSQL request RLock")
    if "threading.RLock()" not in legacy or "with self._lock" not in legacy:
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL legacy JSON lock drift")
    if "PROVEN_HTTP_WORKER_STAGES = (1, 2, 4)" not in runtime:
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL runtime worker stages")
    if "workers not in (1, 2, 4)" not in gunicorn or "preload_app = False" not in gunicorn:
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL Gunicorn stage/fork policy")
    if '"legacy_rlock_retained":False' not in composition.replace(" ", ""):
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL readiness lock identity")
    if ".on_conflict_do_nothing()" not in mail or "record.delivery_key" not in mail:
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL mail race convergence")
    if "except IdentityError as exc:" not in dispatcher or "str(exc.error_kind)" not in dispatcher:
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL identity transport mapping")
    if 'error_kind = "CONTEXT_STALE"' not in identity_errors:
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL stale-context identity marker")
    for marker in ("STATE_VERSION_CONFLICT", "TRANSACTION_RETRY_EXHAUSTED"):
        if marker not in dispatcher:
            raise SystemExit("PASS348 I9 INVARIANTS: FAIL transport marker " + marker)

    pre = json.loads((ROOT / "docs/json/PASS348_I9_PRE_RETIREMENT_PROOF.json").read_text())
    post = json.loads((ROOT / "docs/json/PASS348_I9_POST_RETIREMENT_PROOF.json").read_text())
    if pre.get("status") != "PASS" or post.get("status") != "PASS":
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL proof status")
    if [row["workers"] for row in post["gunicorn_stages"]] != [1, 2, 4]:
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL multi-worker evidence")

    source = json.loads((ROOT / "docs/json/PASS348_SOURCE_BACKEND_CROSSCHECK.json").read_text())
    for row in source["source_facts"]:
        if sha256(ROOT / row["path"]) != row["sha256"]:
            raise SystemExit("PASS348 I9 INVARIANTS: FAIL source drift " + row["path"])
    if 'version = "0.62.0"' not in (ROOT / "pyproject.toml").read_text():
        raise SystemExit("PASS348 I9 INVARIANTS: FAIL package version")
    print(
        "PASS348 I9 INVARIANTS: PASS "
        f"hashes={len(manifest['sha256_by_path'])} rlock=retired-postgres-only "
        "workers=1,2,4 postgres=canonical json-fallback=forbidden"
    )


if __name__ == "__main__":
    main()
