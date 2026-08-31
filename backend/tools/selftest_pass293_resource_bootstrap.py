#!/usr/bin/env python3
"""Pass293 deterministic self-test for clear-data bulk-resource bootstrap chain."""
from __future__ import annotations

import hashlib
import importlib.util
import json
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
import sys
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.config import Settings
from gxb_backend.updates.local_update import select_update_plan


def md5(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


def write_release(updates: Path, version: str, release_type: str, silent: bool, payload: bytes, package: str) -> dict:
    p = updates / f"{package}.001"
    p.write_bytes(payload)
    return {
        "version": version,
        "status": "PUBLISHED",
        "release_type": release_type,
        "silent": silent,
        "package": package,
        "volume": 1,
        "size": len(payload),
        "md5": md5(payload),
        "cumulative": release_type == "CODE_ONLY",
        "contains_version_json": False,
    }


def scheduler_chain_test() -> None:
    with tempfile.TemporaryDirectory() as td:
        base = Path(td)
        updates = base / "updates"; updates.mkdir()
        registry_path = base / "release_registry.json"
        asset = write_release(updates, "1.631.1", "BULK_RESOURCE_BOOTSTRAP", False, b"asset-bootstrap-zip", "gxb-assets-1.631.1.zip")
        code = write_release(updates, "1.631.2", "CODE_ONLY", True, b"code-only-zip", "gxb-local-1.631.2.zip")
        registry = {
            "schema_version": 1,
            "tracks": [{
                "track_id": "android-app-1.631.0",
                "enabled": True,
                "app_v": "1.631.0",
                "platform": 3,
                "base_version": "1.631.0",
                "policy": {"required_initial_barrier": {"version": "1.631.1", "release_type": "BULK_RESOURCE_BOOTSTRAP"}},
                "releases": [asset, code],
            }],
        }
        registry_path.write_text(json.dumps(registry))
        settings = Settings(local_update_release_registry_path=registry_path, local_update_dir=updates)
        p0 = select_update_plan(settings, {"v": "1.631.0", "app_v": "1.631.0", "platform": 3})
        assert [r["version"] for r in p0] == ["1.631.1"] and not p0[0]["silent"]
        p1 = select_update_plan(settings, {"v": "1.631.1", "app_v": "1.631.0", "platform": 3})
        assert [r["version"] for r in p1] == ["1.631.2"] and p1[0]["silent"]
        p2 = select_update_plan(settings, {"v": "1.631.2", "app_v": "1.631.0", "platform": 3})
        assert p2 == []
        old = select_update_plan(settings, {"v": "1.164.0", "app_v": "1.164.0", "platform": 3})
        assert old == []

        # Even if an operator somehow publishes 1.631.2 without the bootstrap,
        # clean clients fail closed rather than skipping the required barrier.
        bad = json.loads(json.dumps(registry))
        bad["tracks"][0]["releases"] = [code]
        bad_path = base / "release_registry_bad.json"
        bad_path.write_text(json.dumps(bad))
        bad_settings = Settings(local_update_release_registry_path=bad_path, local_update_dir=updates)
        assert select_update_plan(bad_settings, {"v": "1.631.0", "app_v": "1.631.0", "platform": 3}) == []


def bulk_path_test() -> None:
    spec = importlib.util.spec_from_file_location("update_controller", ROOT / "update_controller.py")
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    with tempfile.TemporaryDirectory() as td:
        res = Path(td)
        f = res / "web/images/icon/test_icon.png"
        f.parent.mkdir(parents=True)
        data = b"synthetic-current-resource"
        f.write_bytes(data)
        rows = [{"path": "res/web/images/icon/test_icon.png", "md5": md5(data), "size": len(data), "force": 0}]
        files, summary = module.collect_exact_bulk_assets(rows, res, min_files=1, progress_every=0)
        assert files == [(f, "res/images/icon/test_icon.png")]
        assert summary["exact_files"] == 1
        assert summary["historical_old_res_used"] is False


def runtime_baseline_test() -> None:
    settings = json.loads((ROOT / "local_assets/settings.json").read_text())
    assert settings["resource_gateway"]["legacy_fallback_enabled"] is False
    reg = json.loads((ROOT / "local_assets/release_registry.json").read_text())
    track = reg["tracks"][0]
    assert track["base_version"] == "1.631.0"
    assert track["releases"] == []
    active = json.loads((ROOT / "data/resource_catalog/legacy_fallback_allowlist.json").read_text())
    staged = json.loads((ROOT / "local_assets/update_policy/legacy_fallback_allowlist.staged.json").read_text())
    assert active["entries"] == [] and staged["entries"] == []


if __name__ == "__main__":
    scheduler_chain_test()
    bulk_path_test()
    runtime_baseline_test()
    print("PASS293 RESOURCE BOOTSTRAP SELFTEST: OK")
