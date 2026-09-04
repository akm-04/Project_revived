#!/usr/bin/env python3
"""Pass298 deterministic tests for post-bulk stock lazy-state reconciliation."""
from __future__ import annotations

import hashlib
import importlib.util
import json
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.updates.lazy_bootstrap import build_lazy_map, lazy_key, validate_lazy_map

spec = importlib.util.spec_from_file_location("pass298_update_controller", ROOT / "update_controller.py")
uc = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(uc)


def md5(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


def stock_rows() -> tuple[list[dict], bytes, bytes]:
    exact = b"exact-current-resource"
    absent = b"resource-not-present-locally"
    rows = [
        {"path": "res/web/images/icon/exact.png", "md5": md5(exact), "size": len(exact), "force": 0},
        {"path": "res/web/images/icon/absent.png", "md5": md5(absent), "size": len(absent), "force": 0},
        {"path": "res/web/images/icon/forced.png", "md5": "0", "size": 0, "force": 1},
    ]
    return rows, exact, absent


def test_lazy_projection_shape() -> None:
    rows, _exact, _absent = stock_rows()
    supplied = {"res/web/images/icon/exact.png"}
    lazy_map, summary = build_lazy_map(rows, supplied)
    assert lazy_key("res/web/images/icon/exact.png") not in lazy_map
    missing_key = lazy_key("res/web/images/icon/absent.png")
    assert missing_key in lazy_map
    value = json.loads(lazy_map[missing_key])
    assert value == {
        "size": rows[1]["size"],
        "md5": rows[1]["md5"],
        "path": rows[1]["path"],
    }
    assert lazy_key("res/web/images/icon/forced.png") not in lazy_map
    assert summary["catalog_lazy_considered"] == 2
    assert summary["supplied_exact_lazy_paths"] == 1
    assert summary["retained_lazy_markers"] == 1
    assert validate_lazy_map(lazy_map, rows, supplied) == summary


def test_bulk_release_contains_root_lazy_file_and_exact_alias() -> None:
    rows, exact, _absent = stock_rows()
    names = [
        "LOCAL", "UPDATES", "ASSET_UPDATES", "CODE_UPDATES", "CATALOG_UPDATES",
        "POLICY_DIR", "STAGING", "REGISTRY", "STATE", "AUTO_POLICY", "CURRENT_RES",
        "OLD_RES", "DATA", "BASE_VERSION", "ACTIVE_VERSION", "ACTIVE_CATALOG",
        "ACTIVE_ALLOWLIST", "STAGED_ALLOWLIST", "LEGACY_MANIFEST",
    ]
    old = {name: getattr(uc, name) for name in names}
    with tempfile.TemporaryDirectory() as td:
        base = Path(td)
        local = base / "local_assets"
        data = base / "data/resource_catalog"
        mapping = {
            "LOCAL": local,
            "UPDATES": local / "updates",
            "ASSET_UPDATES": local / "updates/assets",
            "CODE_UPDATES": local / "updates/code",
            "CATALOG_UPDATES": local / "updates/catalog",
            "POLICY_DIR": local / "update_policy",
            "STAGING": local / "update_staging",
            "REGISTRY": local / "release_registry.json",
            "STATE": local / "update_controller_state.json",
            "AUTO_POLICY": local / "settings.json",
            "CURRENT_RES": local / "res",
            "OLD_RES": local / "old_res",
            "DATA": data,
            "BASE_VERSION": data / "version_base_1.631.0.json",
            "ACTIVE_VERSION": data / "version_active.json",
            "ACTIVE_CATALOG": data / "resource_catalog.json",
            "ACTIVE_ALLOWLIST": data / "legacy_fallback_allowlist.json",
            "STAGED_ALLOWLIST": local / "update_policy/legacy_fallback_allowlist.staged.json",
            "LEGACY_MANIFEST": local / "update_manifest.json",
        }
        try:
            for name, value in mapping.items():
                setattr(uc, name, value)
            for d in (local, data, uc.ASSET_UPDATES, uc.CODE_UPDATES, uc.CATALOG_UPDATES, uc.POLICY_DIR, uc.CURRENT_RES):
                d.mkdir(parents=True, exist_ok=True)
            exact_path = uc.CURRENT_RES / "web/images/icon/exact.png"
            exact_path.parent.mkdir(parents=True, exist_ok=True)
            exact_path.write_bytes(exact)
            uc.write_json_atomic(uc.BASE_VERSION, rows)
            uc.write_json_atomic(uc.ACTIVE_VERSION, rows)
            empty = uc.empty_allowlist()
            uc.write_json_atomic(uc.ACTIVE_ALLOWLIST, empty)
            uc.write_json_atomic(uc.STAGED_ALLOWLIST, empty)
            registry = {
                "schema_version": 1,
                "tracks": [{
                    "track_id": "android-app-1.631.0", "enabled": True,
                    "app_v": "1.631.0", "platform": 3, "base_version": "1.631.0",
                    "policy": {"required_initial_barrier": {"version": "1.631.5", "release_type": "BULK_RESOURCE_BOOTSTRAP"}},
                    "releases": [],
                }],
            }
            uc.write_json_atomic(uc.REGISTRY, registry)
            release = uc.build_release(
                uc.BULK_RESOURCE, version="1.631.5", silent=False,
                max_volume_bytes=99_000_000, bulk_min_files=1,
            )
            assert release["contains_lazy_file"] is True
            assert release["bulk_lazy_state_mode"] == "POST_BULK_RECONCILED"
            assert release["bulk_exact_files"] == 1
            assert release["bulk_lazy_supplied_exact"] == 1
            assert release["bulk_lazy_markers"] == 1
            package = release["package"]
            assembled = base / "assembled.zip"
            with assembled.open("wb") as dst:
                for i in range(1, int(release["volume"]) + 1):
                    dst.write((uc.ASSET_UPDATES / f"{package}.{i:03d}").read_bytes())
            assert hashlib.md5(assembled.read_bytes()).hexdigest() == release["md5"]
            with zipfile.ZipFile(assembled) as zf:
                names_in_zip = set(zf.namelist())
                assert "res/images/icon/exact.png" in names_in_zip
                assert "lazyFile.json" in names_in_zip
                assert "src_32/version.json" not in names_in_zip
                assert "src_64/version.json" not in names_in_zip
                lazy_map = json.loads(zf.read("lazyFile.json"))
            assert lazy_key("res/web/images/icon/exact.png") not in lazy_map
            assert lazy_key("res/web/images/icon/absent.png") in lazy_map
        finally:
            for name, value in old.items():
                setattr(uc, name, value)


def test_project_policy_versions() -> None:
    settings = json.loads((ROOT / "local_assets/settings.json").read_text())
    assert settings["updates"]["asset_bootstrap"]["version"] == "1.631.1"
    assert settings["updates"]["code_baseline"]["version"] == "1.631.2"
    registry = json.loads((ROOT / "local_assets/release_registry.json").read_text())
    required = registry["tracks"][0]["policy"]["required_initial_barrier"]
    assert required == {"version": "1.631.1", "release_type": "BULK_RESOURCE_BOOTSTRAP"}


def main() -> int:
    test_lazy_projection_shape()
    test_bulk_release_contains_root_lazy_file_and_exact_alias()
    test_project_policy_versions()
    print("PASS298 LAZY BOOTSTRAP SELFTEST: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
