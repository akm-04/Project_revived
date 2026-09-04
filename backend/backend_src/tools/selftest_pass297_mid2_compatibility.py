#!/usr/bin/env python3
"""Pass297 deterministic tests for stock-client-compatible MID2 provisioning."""
from __future__ import annotations

import hashlib
import importlib.util
import json
import shutil
import sys
import tempfile
from copy import deepcopy
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.config import Settings
from gxb_backend.updates.mid2_compat import (
    CURRENT_STOCK_PROFILE,
    SIGNED_INT32_MAX,
    evaluate_volume_plan,
    float32_reported_int,
    is_float32_exact_int,
    plan_volume_sizes,
)
from gxb_backend.updates.local_update import deep_verify_release, select_update_plan

spec = importlib.util.spec_from_file_location("pass297_update_controller", ROOT / "update_controller.py")
uc = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(uc)


def digest(data: bytes, algo: str = "md5") -> str:
    h = hashlib.new(algo); h.update(data); return h.hexdigest()


def write_release(root: Path, version: str, release_type: str, silent: bool, payload: bytes, lane: str) -> dict:
    package = f"gxb-assets-{version}.zip" if release_type == "BULK_RESOURCE_BOOTSTRAP" else f"gxb-local-{version}.zip"
    lane_dir = root / lane; lane_dir.mkdir(parents=True, exist_ok=True)
    part = lane_dir / f"{package}.001"; part.write_bytes(payload)
    metrics = evaluate_volume_plan([len(payload)], len(payload))
    return {
        "version": version,
        "status": "PUBLISHED",
        "release_type": release_type,
        "silent": silent,
        "package": package,
        "lane": lane,
        "volume": 1,
        "volume_files": [{
            "index": 1, "name": part.name, "size": len(payload),
            "md5": digest(payload), "sha256": digest(payload, "sha256"),
        }],
        "size": len(payload),
        "md5": digest(payload),
        "sha256": digest(payload, "sha256"),
        "cumulative": release_type == "CODE_ONLY",
        "contains_version_json": release_type == "CATALOG_MIGRATION",
        **metrics,
    }


def test_source_proven_numeric_examples() -> None:
    assert is_float32_exact_int(99_000_000)
    assert float32_reported_int(69_535_905) == 69_535_904
    assert not is_float32_exact_int(69_535_905)
    assert float32_reported_int(254_229_537) == 254_229_536
    assert not is_float32_exact_int(254_229_537)
    assert is_float32_exact_int(16_777_216)
    assert not is_float32_exact_int(16_777_217)


def test_current_bulk_plan_matches_frozen_pass296_design() -> None:
    plan = plan_volume_sizes(1_059_535_905, 99_000_000)
    assert plan == [99_000_000] * 10 + [61_147_296, 8_388_609], plan
    metrics = evaluate_volume_plan(plan, 1_059_535_905)
    assert metrics == {
        "client_compatibility_profile": CURRENT_STOCK_PROFILE,
        "volume_size_float32_exact": True,
        "client_accounted_size": 1_059_535_905,
        "max_prefix_offset": 1_051_147_296,
        "assembled_size_int32_safe": True,
    }


def test_planner_rejects_native_offset_overflow() -> None:
    try:
        plan_volume_sizes(SIGNED_INT32_MAX + 1, 99_000_000)
    except ValueError as exc:
        assert "signed-int32" in str(exc)
    else:
        raise AssertionError("native int32 assembly overflow was accepted")


def test_splitter_integrates_safe_plan_and_exact_reassembly() -> None:
    # 2^24+1 is the smallest integer that exposes the current float32 loss.
    # The planner must split it into exact fragments instead of emitting one
    # lossy volume.
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        assembled = root / "assembled.zip"
        pattern = bytes(range(251))
        target_size = 16_777_217
        with assembled.open("wb") as fh:
            full, rem = divmod(target_size, len(pattern))
            for _ in range(full):
                fh.write(pattern)
            fh.write(pattern[:rem])
        volume, size, md5, sha, parts = uc._split_zip(assembled, "precision.zip", 99_000_000, out_dir=root)
        assert volume == 2
        assert [p["size"] for p in parts] == [8_388_609, 8_388_608]
        assert all(is_float32_exact_int(p["size"]) for p in parts)
        rebuilt = b"".join((root / f"precision.zip.{i:03d}").read_bytes() for i in range(1, volume + 1))
        assert len(rebuilt) == size == target_size
        assert hashlib.md5(rebuilt).hexdigest() == md5
        assert hashlib.sha256(rebuilt).hexdigest() == sha
        assert rebuilt == assembled.read_bytes()


def test_runtime_direct_required_barrier_routing() -> None:
    with tempfile.TemporaryDirectory() as td:
        root = Path(td); updates = root / "updates"; updates.mkdir()
        old_asset = write_release(updates, "1.631.1", "BULK_RESOURCE_BOOTSTRAP", False, b"old-bad-provenance-placeholder", "assets")
        old_code = write_release(updates, "1.631.2", "CODE_ONLY", True, b"old-code-provenance-placeholder", "code")
        barrier = write_release(updates, "1.631.3", "BULK_RESOURCE_BOOTSTRAP", False, b"corrected-barrier", "assets")
        code = write_release(updates, "1.631.4", "CODE_ONLY", True, b"fresh-code", "code")
        registry = {
            "schema_version": 1,
            "tracks": [{
                "track_id": "android-app-1.631.0", "enabled": True, "app_v": "1.631.0", "platform": 3,
                "base_version": "1.631.0",
                "policy": {"required_initial_barrier": {"version": "1.631.3", "release_type": "BULK_RESOURCE_BOOTSTRAP"}},
                "releases": [old_asset, old_code, barrier, code],
            }],
        }
        reg_path = root / "release_registry.json"; reg_path.write_text(json.dumps(registry))
        settings = Settings(local_update_dir=updates, local_update_release_registry_path=reg_path, runtime_log_dir=root / "logs")
        for current in ("1.631.0", "1.631.1", "1.631.2"):
            rows = select_update_plan(settings, {"v": current, "app_v": "1.631.0", "platform": 3})
            assert [r["version"] for r in rows] == ["1.631.3"], (current, rows)
        rows = select_update_plan(settings, {"v": "1.631.3", "app_v": "1.631.0", "platform": 3})
        assert [r["version"] for r in rows] == ["1.631.4"]
        assert select_update_plan(settings, {"v": "1.631.4", "app_v": "1.631.0", "platform": 3}) == []


def test_runtime_never_falls_back_around_invalid_active_barrier() -> None:
    with tempfile.TemporaryDirectory() as td:
        root = Path(td); updates = root / "updates"; updates.mkdir()
        old_asset = write_release(updates, "1.631.1", "BULK_RESOURCE_BOOTSTRAP", False, b"old-barrier", "assets")
        barrier = write_release(updates, "1.631.3", "BULK_RESOURCE_BOOTSTRAP", False, b"corrected-barrier", "assets")
        code = write_release(updates, "1.631.4", "CODE_ONLY", True, b"fresh-code", "code")
        # Corrupt the active barrier after sidecar/registry hashes are frozen.
        (updates / "assets" / barrier["volume_files"][0]["name"]).write_bytes(b"corrupt")
        registry = {
            "schema_version": 1,
            "tracks": [{
                "track_id": "android-app-1.631.0", "enabled": True, "app_v": "1.631.0", "platform": 3,
                "base_version": "1.631.0",
                "policy": {"required_initial_barrier": {"version": "1.631.3", "release_type": "BULK_RESOURCE_BOOTSTRAP"}},
                "releases": [old_asset, barrier, code],
            }],
        }
        reg_path = root / "release_registry.json"; reg_path.write_text(json.dumps(registry))
        settings = Settings(local_update_dir=updates, local_update_release_registry_path=reg_path, runtime_log_dir=root / "logs")
        assert select_update_plan(settings, {"v": "1.631.0", "app_v": "1.631.0", "platform": 3}) == []


def test_runtime_rejects_nonexact_actual_volume() -> None:
    with tempfile.TemporaryDirectory() as td:
        root = Path(td); updates = root / "updates/assets"; updates.mkdir(parents=True)
        payload = b"x" * 16_777_217
        package = "gxb-assets-1.631.3.zip"
        part = updates / f"{package}.001"; part.write_bytes(payload)
        release = {
            "version": "1.631.3", "status": "PUBLISHED", "release_type": "BULK_RESOURCE_BOOTSTRAP",
            "silent": False, "package": package, "lane": "assets", "volume": 1,
            "volume_files": [{"index":1,"name":part.name,"size":len(payload),"md5":digest(payload),"sha256":digest(payload,"sha256")}],
            "size": len(payload), "md5": digest(payload), "sha256": digest(payload,"sha256"),
            "cumulative": False, "contains_version_json": False,
        }
        settings = Settings(local_update_dir=root / "updates", local_update_release_registry_path=root / "registry.json")
        assert deep_verify_release(settings, release, log=False) is None



def test_startup_reconciles_persisted_pass294_barrier_policy() -> None:
    names = ["LOCAL", "UPDATES", "ASSET_UPDATES", "CODE_UPDATES", "CATALOG_UPDATES", "REGISTRY", "AUTO_POLICY", "CURRENT_RES"]
    old = {name: getattr(uc, name) for name in names}
    with tempfile.TemporaryDirectory() as td:
        root = Path(td); local = root / "local_assets"; updates = local / "updates"
        mapping = {
            "LOCAL": local, "UPDATES": updates, "ASSET_UPDATES": updates / "assets",
            "CODE_UPDATES": updates / "code", "CATALOG_UPDATES": updates / "catalog",
            "REGISTRY": local / "release_registry.json", "AUTO_POLICY": local / "settings.json",
            "CURRENT_RES": local / "res",
        }
        try:
            for name, value in mapping.items():
                setattr(uc, name, value)
            for d in (local, uc.ASSET_UPDATES, uc.CODE_UPDATES, uc.CATALOG_UPDATES):
                d.mkdir(parents=True, exist_ok=True)
            persisted = {
                "schema_version": 1,
                "tracks": [{
                    "track_id": "android-app-1.631.0", "enabled": True, "app_v": "1.631.0", "platform": 3,
                    "base_version": "1.631.0",
                    "policy": {"required_initial_barrier": {"version": "1.631.1", "release_type": "BULK_RESOURCE_BOOTSTRAP"}},
                    "releases": [],
                }],
            }
            uc.write_json_atomic(uc.REGISTRY, persisted)
            uc.write_json_atomic(uc.AUTO_POLICY, {
                "updates": {
                    "enabled": True, "auto_ensure": True, "auto_publish": True, "max_volume_bytes": 99_000_000,
                    "asset_bootstrap": {"enabled": True, "version": "1.631.3", "min_exact_files": 25000},
                    "code_baseline": {"enabled": True, "version": "1.631.4"},
                }
            })
            result = uc.ensure_auto_releases(policy_path=uc.AUTO_POLICY)
            assert result["actions"] == [
                "update-required-barrier:1.631.3",
                "warn-missing-res:1.631.3",
                "withhold-code:1.631.4",
            ], result
            current = uc.load_registry()["tracks"][0]["policy"]["required_initial_barrier"]
            assert current == {"version": "1.631.3", "release_type": "BULK_RESOURCE_BOOTSTRAP"}
        finally:
            for name, value in old.items():
                setattr(uc, name, value)

def test_project_policy_versions() -> None:
    # Later passes may advance the active monotonic barrier while retaining the
    # Pass297 numeric compatibility contract. Keep this regression focused on
    # the shared cap/profile and barrier-policy consistency rather than pinning
    # the deployment forever to the first corrected 1.631.3/1.631.4 pair.
    settings = json.loads((ROOT / "local_assets/settings.json").read_text())
    assert settings["updates"]["max_volume_bytes"] == 99_000_000
    asset_v = settings["updates"]["asset_bootstrap"]["version"]
    code_v = settings["updates"]["code_baseline"]["version"]
    assert asset_v == "1.631.1"
    assert code_v == "1.631.2" and uc.parse_version(code_v) > uc.parse_version(asset_v)
    registry = json.loads((ROOT / "local_assets/release_registry.json").read_text())
    required = registry["tracks"][0]["policy"]["required_initial_barrier"]
    assert required == {"version": asset_v, "release_type": "BULK_RESOURCE_BOOTSTRAP"}


def main() -> int:
    test_source_proven_numeric_examples()
    test_current_bulk_plan_matches_frozen_pass296_design()
    test_planner_rejects_native_offset_overflow()
    test_splitter_integrates_safe_plan_and_exact_reassembly()
    test_runtime_direct_required_barrier_routing()
    test_runtime_never_falls_back_around_invalid_active_barrier()
    test_runtime_rejects_nonexact_actual_volume()
    test_startup_reconciles_persisted_pass294_barrier_policy()
    test_project_policy_versions()
    print("PASS297 MID2 COMPATIBILITY SELFTEST: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
