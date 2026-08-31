#!/usr/bin/env python3
"""Deterministic Pass291 MID2 release-chain/controller self-test."""
from __future__ import annotations
import hashlib
import json
import shutil
import sys
import tempfile
import zipfile
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.config import Settings
from gxb_backend.updates.local_update import select_update_plan, version_check_payload
import update_controller as uc


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def assert_zip_catalog_shape(path: Path, *, catalog: bool, expected_files: int) -> None:
    with zipfile.ZipFile(path) as zf:
        names = zf.namelist()
        assert len(names) == expected_files, (len(names), expected_files)
        has32 = "src_32/version.json" in names
        has64 = "src_64/version.json" in names
        assert has32 == catalog and has64 == catalog


def temp_settings(tmp: Path, registry: dict) -> Settings:
    local = tmp / "local_assets"
    updates = local / "updates"
    updates.mkdir(parents=True)
    # Copy all release volumes named in the test registry.
    for track in registry["tracks"]:
        for r in track["releases"]:
            for idx in range(1, int(r["volume"]) + 1):
                src = ROOT / "local_assets/updates" / f"{r['package']}.{idx:03d}"
                if src.is_file():
                    shutil.copy2(src, updates / src.name)
    reg_path = local / "release_registry.json"
    reg_path.write_text(json.dumps(registry, indent=2) + "\n")
    return Settings(
        static_asset_root=local,
        local_update_release_registry_path=reg_path,
        local_update_dir=updates,
        runtime_log_dir=tmp / "logs",
    )


def test_frozen_initial_history() -> None:
    registry = json.loads((ROOT / "local_assets/release_registry.json").read_text())
    track = registry["tracks"][0]
    rel = {r["version"]: r for r in track["releases"]}
    assert rel["1.631.24"]["status"] == "PUBLISHED"
    assert rel["1.631.24"]["release_type"] == "CODE_ONLY"
    assert rel["1.631.24"]["silent"] is True
    assert rel["1.631.24"]["contains_version_json"] is False
    p24 = ROOT / "local_assets/updates/gxb-local-1.631.24.zip.001"
    assert p24.stat().st_size == 2409878
    assert md5(p24) == "dd89797c446ed3562455f9929c0aad12"
    assert hashlib.sha256(p24.read_bytes()).hexdigest() == "9f9bcb3b118eea68ddc3dfc4e23cf8cd25aef7a9c0e4fe4db745137d9c727ec0"
    assert_zip_catalog_shape(p24, catalog=False, expected_files=148)

    assert rel["1.631.25"]["status"] == "CANDIDATE"
    assert rel["1.631.25"]["release_type"] == "CATALOG_MIGRATION"
    assert rel["1.631.25"]["silent"] is False
    assert rel["1.631.25"]["contains_version_json"] is True
    p25 = ROOT / "local_assets/updates/gxb-local-1.631.25.zip.001"
    assert_zip_catalog_shape(p25, catalog=True, expected_files=150)


def test_runtime_scheduler_barrier_and_apk_gate() -> None:
    base = json.loads((ROOT / "local_assets/release_registry.json").read_text())
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td)
        settings = temp_settings(tmp, base)
        def plan(v, app="1.631.0", platform=3):
            return select_update_plan(settings, {"v": v, "app_v": app, "platform": platform, "full": True})
        assert [r["version"] for r in plan("1.631.23")] == ["1.631.24"]
        assert plan("1.631.23")[0]["silent"] is True
        assert plan("1.631.24") == []  # candidate is not runtime authority
        assert plan("1.631.24", app="1.164.0") == []
        assert plan("1.631.24", platform=2) == []
        payload = version_check_payload(settings, {"v":"1.631.23","app_v":"1.631.0","platform":3})
        assert payload["is_inapp"] == 1 and payload["is_review"] == 1
        assert [x["version"] for x in payload["res"]] == ["1.631.24"]

        # Simulate publication without changing the actual project registry.
        reg2 = deepcopy(base)
        for r in reg2["tracks"][0]["releases"]:
            if r["version"] == "1.631.25": r["status"] = "PUBLISHED"
        settings2 = temp_settings(tmp / "pub", reg2)
        assert [r["version"] for r in select_update_plan(settings2,{"v":"1.631.23","app_v":"1.631.0","platform":3})] == ["1.631.24"]
        p = select_update_plan(settings2,{"v":"1.631.24","app_v":"1.631.0","platform":3})
        assert [r["version"] for r in p] == ["1.631.25"] and p[0]["silent"] is False
        loud = version_check_payload(settings2,{"v":"1.631.24","app_v":"1.631.0","platform":3})
        assert loud["is_review"] == 0 and [x["version"] for x in loud["res"]] == ["1.631.25"]


def test_source_shaped_multi_res_and_cumulative_collapse() -> None:
    base = json.loads((ROOT / "local_assets/release_registry.json").read_text())
    # Use the same known-good ZIP bytes under distinct package names to test
    # scheduler sequencing; descriptor version is independent of ZIP contents.
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td)
        reg = deepcopy(base)
        for r in reg["tracks"][0]["releases"]:
            if r["version"] == "1.631.25": r["status"] = "PUBLISHED"
        template = deepcopy(reg["tracks"][0]["releases"][0])
        for version in ("1.631.26","1.631.27"):
            x = deepcopy(template)
            x.update({"version":version,"status":"PUBLISHED","release_type":"CODE_ONLY","silent":True,"package":f"delta-{version}.zip","cumulative":False})
            reg["tracks"][0]["releases"].append(x)
        settings = temp_settings(tmp, reg)
        src = ROOT / "local_assets/updates/gxb-local-1.631.24.zip.001"
        for version in ("1.631.26","1.631.27"):
            shutil.copy2(src, settings.local_update_dir / f"delta-{version}.zip.001")
        rows = select_update_plan(settings,{"v":"1.631.25","app_v":"1.631.0","platform":3})
        assert [r["version"] for r in rows] == ["1.631.26","1.631.27"]
        payload = version_check_payload(settings,{"v":"1.631.25","app_v":"1.631.0","platform":3})
        assert [x["version"] for x in payload["res"]] == ["1.631.26","1.631.27"]

        # If both are cumulative snapshots, newest one safely collapses the
        # homogeneous silent segment.
        for r in reg["tracks"][0]["releases"]:
            if r["version"] in {"1.631.26","1.631.27"}: r["cumulative"] = True
        settings2 = temp_settings(tmp / "cum", reg)
        for version in ("1.631.26","1.631.27"):
            shutil.copy2(src, settings2.local_update_dir / f"delta-{version}.zip.001")
        rows = select_update_plan(settings2,{"v":"1.631.25","app_v":"1.631.0","platform":3})
        assert [r["version"] for r in rows] == ["1.631.27"]


def test_multivolume_and_candidate_version_inheritance() -> None:
    with tempfile.TemporaryDirectory() as td:
        tmp=Path(td)
        old=uc.UPDATES
        uc.UPDATES=tmp
        try:
            assembled=tmp/"assembled.zip"
            assembled.write_bytes(bytes(range(251))*50000)  # ~12 MiB deterministic payload
            volume,size,m5,sha,parts=uc._split_zip(assembled,"mv-test.zip",1_000_000)
            assert volume > 1
            rebuilt=b"".join((tmp/f"mv-test.zip.{i:03d}").read_bytes() for i in range(1,volume+1))
            assert rebuilt == assembled.read_bytes()
            assert len(rebuilt)==size and hashlib.md5(rebuilt).hexdigest()==m5 and hashlib.sha256(rebuilt).hexdigest()==sha
        finally:
            uc.UPDATES=old

    synthetic={"releases":[
        {"version":"1.631.24","status":"PUBLISHED","release_type":"CODE_ONLY"},
        {"version":"1.631.25","status":"CANDIDATE","release_type":"CODE_ONLY"},
    ]}
    # Catalog migration absorbs an unpublished code candidate at the same
    # version. This is forbidden once the version is published.
    assert uc._candidate_version(synthetic, uc.CATALOG_MIGRATION, None, False, True) == "1.631.25"
    synthetic["releases"][1]["status"]="PUBLISHED"
    assert uc._candidate_version(synthetic, uc.CATALOG_MIGRATION, None, False, True) == "1.631.26"


def test_controller_safety_contracts() -> None:
    active=uc.normalize_allowlist(uc.load_json(uc.ACTIVE_ALLOWLIST, default=uc.empty_allowlist()))
    staged=uc.normalize_allowlist(uc.load_json(uc.STAGED_ALLOWLIST, default=active))
    assert len(active["entries"]) == 0 and len(staged["entries"]) == 10
    try:
        uc.build_release(uc.CODE_ONLY, version="1.631.26", silent=True)
    except ValueError as exc:
        assert "CODE_ONLY build refused" in str(exc)
    else:
        raise AssertionError("dirty whitelist was allowed into CODE_ONLY")
    try:
        uc.build_release(uc.CATALOG_MIGRATION, version="1.631.26", silent=True)
    except ValueError as exc:
        assert "loud barrier" in str(exc)
    else:
        raise AssertionError("silent catalog migration was allowed")


def main() -> int:
    registry = json.loads((ROOT / "local_assets/release_registry.json").read_text())
    if registry.get("reset_generation"):
        # Pass293 deliberately reset the live release history for clear-data clients.
        # Preserve the Pass291 generic volume/version-inheritance regression checks,
        # while Pass293 owns the new live-history assertions.
        test_multivolume_and_candidate_version_inheritance()
        print("PASS291 UPDATE SCHEDULER GENERIC REGRESSION: OK (live history superseded by Pass293 reset)")
        return 0
    test_frozen_initial_history()
    test_runtime_scheduler_barrier_and_apk_gate()
    test_source_shaped_multi_res_and_cumulative_collapse()
    test_multivolume_and_candidate_version_inheritance()
    test_controller_safety_contracts()
    print("PASS291 UPDATE SCHEDULER SELFTEST: OK")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
