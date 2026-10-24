#!/usr/bin/env python3
"""Validate cumulative candidate invariants without weakening historical phase guards.

Historical validators retain their snapshot-era rules. This wrapper first runs R6 in
explicit cumulative mode, then validates the current forward migration inventory and
release/SBOM identity. Exact native PostgreSQL/River/client evidence remains separate.
"""
from __future__ import annotations
import hashlib, json, os, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "docs" / "architecture" / "CUMULATIVE_MIGRATION_LOCK.json"
errs: list[str] = []

r6_cmd = [sys.executable, str(ROOT / "tools" / "validate_r6.py"), "--cumulative"]
compat_scratch = os.environ.get("GXB_COMPAT_SCRATCH") == "1"
if compat_scratch:
    r6_cmd.append("--compat-scratch")
r = subprocess.run(r6_cmd, cwd=ROOT)
if r.returncode != 0:
    errs.append("historical R6 invariants failed in cumulative mode")

if not LOCK.exists():
    errs.append("missing docs/architecture/CUMULATIVE_MIGRATION_LOCK.json")
else:
    data = json.loads(LOCK.read_text())
    expected = data.get("migrations", {})
    actual = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT / "migrations").glob("*.sql"))}
    if actual != expected:
        missing = sorted(set(expected) - set(actual))
        extra = sorted(set(actual) - set(expected))
        drift = sorted(k for k in set(actual) & set(expected) if actual[k] != expected[k])
        errs.append(f"cumulative migration inventory/hash drift missing={missing} extra={extra} changed={drift}")
    latest = sorted(actual)[-1] if actual else ""
    if data.get("highest_migration") != latest:
        errs.append(f"cumulative migration lock high-water mark {data.get('highest_migration')!r} != actual latest {latest!r}")

try:
    build = json.loads((ROOT / "BUILD_INFO.json").read_text())
    snap = json.loads((ROOT / "SNAPSHOT_INFO.json").read_text())
    sbom = json.loads((ROOT / "SBOM.spdx.json").read_text())
    sbom_pkg = next(p for p in sbom.get("packages", []) if p.get("SPDXID") == "SPDXRef-GXB")
    if build.get("version") != snap.get("version") or build.get("version") != sbom_pkg.get("versionInfo"):
        errs.append(f"release version drift build={build.get('version')} snapshot={snap.get('version')} sbom={sbom_pkg.get('versionInfo')}")
    version_file=(ROOT / "VERSION").read_text().strip()
    if build.get("version") != version_file:
        errs.append(f"VERSION file disagrees with build/snapshot: {version_file} vs {build.get('version')}")
    manifest=json.loads((ROOT / "internal/content/builtin/generated/manifest.json").read_text())
    lock=json.loads((ROOT / "docs/architecture/CUMULATIVE_MIGRATION_LOCK.json").read_text())
    for name, info in [('BUILD_INFO',build),('SNAPSHOT_INFO',snap)]:
        if info.get('migration_high_water')!=lock['highest_migration']:
            errs.append(name+' stale current migration high-water')
        if info.get('content_revision')!=manifest['revision_id']:
            errs.append(name+' stale current content revision')
    if sbom.get("name") != "gxb-backend-v2-resolved":
        errs.append(f"stale SBOM document name {sbom.get('name')!r}")
except Exception as exc:
    errs.append(f"release/SBOM identity read failed: {exc}")

if errs:
    print("CURRENT CUMULATIVE CANDIDATE VALIDATION: FAIL")
    for e in errs:
        print(" -", e)
    raise SystemExit(1)
print("CURRENT CUMULATIVE CANDIDATE VALIDATION: PASS")
print("historical R6 pins retained; exact forward migration inventory and current release/SBOM version agree" + ("; COMPATIBILITY_COPY_ONLY toolchain accommodation explicitly excluded from canonical/native proof" if compat_scratch else ""))
