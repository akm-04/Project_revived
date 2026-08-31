#!/usr/bin/env python3
"""Pass299 OTA runtime-closure and canonical-generation normalization tests."""
from __future__ import annotations

import importlib.util
import json
import tempfile
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

spec = importlib.util.spec_from_file_location("pass299_update_controller", ROOT / "update_controller.py")
uc = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(uc)

from gxb_backend.updates import local_update as lu


def test_project_canonical_versions() -> None:
    settings = json.loads((ROOT / "local_assets/settings.json").read_text())
    updates = settings["updates"]
    assert updates["canonical_generation"] == "OTA_CANONICAL_V1_PASS299"
    assert updates["asset_bootstrap"]["version"] == "1.631.1"
    assert updates["code_baseline"]["version"] == "1.631.2"
    registry = json.loads((ROOT / "local_assets/release_registry.json").read_text())
    assert registry["runtime_generation"] == "OTA_CANONICAL_V1_PASS299"
    track = registry["tracks"][0]
    assert track["ota_generation"] == "OTA_CANONICAL_V1_PASS299"
    assert track["policy"]["required_initial_barrier"] == {
        "version": "1.631.1", "release_type": "BULK_RESOURCE_BOOTSTRAP"
    }
    assert track["releases"] == []


def test_generation_filter() -> None:
    track = {
        "ota_generation": "new",
        "releases": [
            {"version": "1.631.1", "status": "PUBLISHED", "ota_generation": "old"},
            {"version": "1.631.1", "status": "PUBLISHED", "ota_generation": "new"},
            {"version": "1.631.2", "status": "PUBLISHED", "ota_generation": "new"},
        ],
    }
    pending = lu._pending_published(track, "1.631.0")
    assert [(r["version"], r["ota_generation"]) for r in pending] == [
        ("1.631.1", "new"), ("1.631.2", "new")
    ]


def test_registry_reset_and_stale_sidecar_archive() -> None:
    names = [
        "LOCAL", "UPDATES", "ASSET_UPDATES", "CODE_UPDATES", "CATALOG_UPDATES",
        "UPDATE_HISTORY", "REGISTRY", "AUTO_POLICY",
    ]
    old = {name: getattr(uc, name) for name in names}
    try:
        with tempfile.TemporaryDirectory() as td:
            base = Path(td) / "local_assets"
            mapping = {
                "LOCAL": base,
                "UPDATES": base / "updates",
                "ASSET_UPDATES": base / "updates/assets",
                "CODE_UPDATES": base / "updates/code",
                "CATALOG_UPDATES": base / "updates/catalog",
                "UPDATE_HISTORY": base / "updates/history",
                "REGISTRY": base / "release_registry.json",
                "AUTO_POLICY": base / "settings.json",
            }
            for name, value in mapping.items():
                setattr(uc, name, value)
            for path in [uc.ASSET_UPDATES, uc.CODE_UPDATES, uc.CATALOG_UPDATES]:
                path.mkdir(parents=True, exist_ok=True)
            registry = {
                "schema_version": 1,
                "runtime_generation": "PASS298_EXPERIMENTAL",
                "tracks": [{
                    "track_id": "android-app-1.631.0", "enabled": True,
                    "app_v": "1.631.0", "platform": 3, "base_version": "1.631.0",
                    "ota_generation": "PASS298_EXPERIMENTAL",
                    "policy": {"required_initial_barrier": {"version": "1.631.5", "release_type": uc.BULK_RESOURCE}},
                    "releases": [
                        {"version": "1.631.5", "status": "PUBLISHED", "release_type": uc.BULK_RESOURCE},
                        {"version": "1.631.6", "status": "PUBLISHED", "release_type": uc.CODE_ONLY},
                    ],
                }],
            }
            uc.write_json_atomic(uc.REGISTRY, registry)
            uc.write_json_atomic(uc.AUTO_POLICY, {
                "updates": {
                    "enabled": True, "auto_ensure": True, "auto_publish": False,
                    "canonical_generation": "OTA_CANONICAL_V1_PASS299",
                    "reset_active_registry_on_generation_mismatch": True,
                    "asset_bootstrap": {"enabled": False, "version": "1.631.1"},
                    "code_baseline": {"enabled": False, "version": "1.631.2"},
                }
            })
            result = uc.ensure_auto_releases(policy_path=uc.AUTO_POLICY)
            assert result["ota_generation"] == "OTA_CANONICAL_V1_PASS299"
            after = uc.load_registry(); track = uc.current_track(after)
            assert after["runtime_generation"] == "OTA_CANONICAL_V1_PASS299"
            assert track["ota_generation"] == "OTA_CANONICAL_V1_PASS299"
            assert track["releases"] == []
            archived_registries = list((uc.UPDATE_HISTORY / "registry").glob("release_registry.*.json"))
            assert len(archived_registries) == 1
            archived_payload = json.loads(archived_registries[0].read_text())
            assert archived_payload["runtime_generation"] == "PASS298_EXPERIMENTAL"

            package = "gxb-assets-1.631.1.zip"
            stale_sidecar = uc.ASSET_UPDATES / f"{package}.release.json"
            stale_part = uc.ASSET_UPDATES / f"{package}.001"
            uc.write_json_atomic(stale_sidecar, {
                "version": "1.631.1", "status": "PUBLISHED", "release_type": uc.BULK_RESOURCE,
                "lane": "assets", "package": package, "ota_generation": "OLD_FAILED_GENERATION",
            })
            stale_part.write_bytes(b"historical failed bytes")
            moved = uc._archive_stale_same_version_artifacts(
                "1.631.1", uc.BULK_RESOURCE, "OTA_CANONICAL_V1_PASS299"
            )
            assert len(moved) == 2
            assert not stale_sidecar.exists() and not stale_part.exists()
            archived_parts = list((uc.UPDATE_HISTORY / "artifacts").rglob(f"{package}.001"))
            archived_sidecars = list((uc.UPDATE_HISTORY / "artifacts").rglob(f"{package}.release.json"))
            assert len(archived_parts) == 1 and len(archived_sidecars) == 1
            assert archived_parts[0].read_bytes() == b"historical failed bytes"
    finally:
        for name, value in old.items():
            setattr(uc, name, value)


def main() -> int:
    test_project_canonical_versions()
    test_generation_filter()
    test_registry_reset_and_stale_sidecar_archive()
    print("PASS299 OTA CLOSURE SELFTEST: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
