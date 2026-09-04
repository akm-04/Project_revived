#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
from pathlib import Path

from pass_artifact_resolver import resolve_pass_artifact

ROOT = Path(__file__).resolve().parents[1]


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    manifest = json.loads((ROOT / "docs/json/PASS347_1_I8_REPAIR_MANIFEST.json").read_text())
    bad = []
    for relative, expected in manifest["sha256_by_path"].items():
        path = resolve_pass_artifact(ROOT, relative)
        actual = sha(path) if path.is_file() else "MISSING"
        if actual != expected:
            bad.append((relative, expected, actual))
    if bad:
        raise SystemExit("PASS347.1 I8 INVARIANTS: FAIL " + json.dumps(bad[:20]))

    authority = (ROOT / "gxb_backend/runtime/authority.py").read_text()
    composition = (ROOT / "gxb_backend/runtime/composition.py").read_text()
    maintenance = (ROOT / "gxb_backend/runtime/maintenance.py").read_text()
    cutover = (ROOT / "tools/pass347_i8_cutover.py").read_text()
    nginx = (ROOT / "deploy/nginx/gxb.conf").read_text()
    gunicorn = (ROOT / "deploy/gunicorn.conf.py").read_text()
    for required in ("PREPARED", "TRAFFIC_OPEN", "physical maintenance gate"):
        if required not in authority:
            raise SystemExit("PASS347.1 I8 INVARIANTS: FAIL authority " + required)
    for required in ("MaintenanceGatedSchedulerProcess", "paused=gate.active"):
        if required not in composition:
            raise SystemExit("PASS347.1 I8 INVARIANTS: FAIL composition " + required)
    if "return0,0" not in maintenance.replace(" ", ""):
        raise SystemExit("PASS347.1 I8 INVARIANTS: FAIL scheduler maintenance pause")
    if "maintenance-off" not in cutover or "require_postgresql(connection)" not in cutover:
        raise SystemExit("PASS347.1 I8 INVARIANTS: FAIL verified release")
    if "-f /run/gxb/maintenance" not in nginx or "return 503" not in nginx:
        raise SystemExit("PASS347.1 I8 INVARIANTS: FAIL public maintenance gate")
    if "unix:/run/gxb/http.sock" not in gunicorn or "workers != 1" not in gunicorn:
        raise SystemExit("PASS347.1 I8 INVARIANTS: FAIL private one-worker bind")

    source = json.loads((ROOT / "docs/json/PASS347_1_SOURCE_BACKEND_CROSSCHECK.json").read_text())
    for row in source["source_facts"]:
        if sha(ROOT / row["path"]) != row["sha256"]:
            raise SystemExit("PASS347.1 I8 INVARIANTS: FAIL source drift " + row["path"])
    if sha(ROOT / "gxb_backend/state/multiuser_database.py") != "af43acc4a8e9d133f3c99fe65846459cab92aebb3f505b2d8725f947ee68fde3":
        raise SystemExit("PASS347.1 I8 INVARIANTS: FAIL legacy migration source drift")
    print(
        "PASS347.1 I8 INVARIANTS: PASS "
        f"hashes={len(manifest['sha256_by_path'])} maintenance=physical "
        "prepared=private workers=1 rlock=retained postgres=canonical-after-open"
    )


if __name__ == "__main__":
    main()
