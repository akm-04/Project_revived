#!/usr/bin/env python3
"""Pass289 static/unit self-test for the Resource/CDN compatibility seam."""
from __future__ import annotations

import hashlib
import json
import sys
import tempfile
import types
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

# ResourceGateway only needs a tiny Flask surface for these deterministic unit tests.
class _Response:
    def __init__(self, data=b"", status=200):
        self._data = data if isinstance(data, bytes) else str(data).encode()
        self.status_code = status
        self.headers = {}
    def get_data(self):
        return self._data


def _make_response(data, status=200):
    return _Response(data, status)


def _send_file(obj, **_kwargs):
    if hasattr(obj, "read"):
        data = obj.read()
    else:
        data = Path(obj).read_bytes()
    return _Response(data, 200)

fake_flask = types.ModuleType("flask")
fake_flask.Request = object
fake_flask.make_response = _make_response
fake_flask.send_file = _send_file
sys.modules.setdefault("flask", fake_flask)

from gxb_backend.config import Settings  # noqa: E402
from gxb_backend.observability.resource_gateway import ResourceGateway  # noqa: E402
import update_controller  # noqa: E402


class Req:
    method = "GET"
    remote_addr = "127.0.0.1"
    headers = {"User-Agent": "pass289-selftest"}


def req(entry_name: str, md5: str) -> str:
    return f"{entry_name}.{md5}"


def write_allow(path: Path, current_path: str, data: bytes, rel: str) -> None:
    md5 = hashlib.md5(data).hexdigest()
    sha = hashlib.sha256(data).hexdigest()
    path.write_text(json.dumps({
        "default_policy": "DENY_LEGACY_FALLBACK",
        "entries": [{
            "current_path": current_path,
            "catalog_md5": md5,
            "donor_md5": md5,
            "donor_sha256": sha,
            "donor_size": len(data),
            "fallback_relpath": rel,
        }],
    }), encoding="utf-8")


def test_gateway_policy() -> None:
    data = b"legacy-donor-payload"
    md5 = hashlib.md5(data).hexdigest()
    current_path = "res/web/images/icon/80001002_icon.png"
    requested = req("80001002_icon.png", md5)
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        local = root / "local_assets"
        donor = local / "old_res/images/icon/80001002_icon.png"
        donor.parent.mkdir(parents=True)
        donor.write_bytes(data)
        catalog = root / "catalog.json"
        catalog.write_text(json.dumps({"entries": [{"path": current_path, "md5": md5, "size": len(data)}]}))
        allow = root / "allow.json"
        write_allow(allow, current_path, data, "images/icon/80001002_icon.png")
        settings = Settings(
            static_asset_root=local,
            resource_catalog_path=catalog,
            legacy_fallback_allowlist_path=allow,
            runtime_log_dir=root / "logs",
            legacy_fallback_enabled=True,
        )
        assert settings.asset_roots == (local / "res",)
        gw = ResourceGateway(settings)
        response = gw.capture(Req(), requested)
        assert response.status_code == 200
        assert response.get_data() == data
        assert response.headers["X-GXB-Resource-Source"] == "legacy_whitelist"

        # A valid current copy always wins before historical fallback.
        current = local / "res/web/images/icon/80001002_icon.png"
        current.parent.mkdir(parents=True)
        current.write_bytes(data)
        gw_current = ResourceGateway(settings)
        response = gw_current.capture(Req(), requested)
        assert response.status_code == 200
        assert response.headers["X-GXB-Resource-Source"] == "current"
        current.unlink()

        # Tampering an approved donor fails closed; it never searches a substitute.
        donor.write_bytes(b"tampered")
        gw_bad = ResourceGateway(settings)
        response = gw_bad.capture(Req(), requested)
        assert response.status_code == 404
        assert response.headers["X-GXB-Resource-Status"] == "legacy_whitelist_mismatch"
        donor.write_bytes(data)

        # Same bytes on disk cannot be used without an exact allowlist key.
        other_catalog = root / "catalog2.json"
        other_path = "res/web/images/icon/OTHER_icon.png"
        other_catalog.write_text(json.dumps({"entries": [{"path": other_path, "md5": md5, "size": len(data)}]}))
        settings2 = Settings(
            static_asset_root=local,
            resource_catalog_path=other_catalog,
            legacy_fallback_allowlist_path=allow,
            runtime_log_dir=root / "logs2",
            legacy_fallback_enabled=True,
        )
        gw2 = ResourceGateway(settings2)
        response = gw2.capture(Req(), req("OTHER_icon.png", md5))
        assert response.status_code == 404
        assert response.headers["X-GXB-Resource-Status"] != "served"

        # Missing old_res is a warning/fail-closed condition, never startup failure.
        donor.unlink()
        donor.parent.rmdir()
        (local / "old_res/images").rmdir()
        (local / "old_res").rmdir()
        gw_missing = ResourceGateway(settings)
        response = gw_missing.capture(Req(), requested)
        assert response.status_code == 404
        assert response.headers["X-GXB-Resource-Status"] == "legacy_root_unavailable"


def test_candidate_ota() -> None:
    # Pass293 keeps the proven legacy seam but resets it to disabled/empty.
    base = json.loads((ROOT / "data/resource_catalog/version_base_1.631.0.json").read_text())
    active_version = json.loads((ROOT / "data/resource_catalog/version_active.json").read_text())
    staged_version = json.loads((ROOT / "local_assets/update_staging/version.json").read_text())
    assert len(base) == len(active_version) == len(staged_version) == 43759
    assert base == active_version == staged_version
    active = update_controller.normalize_allowlist(update_controller.load_json(update_controller.ACTIVE_ALLOWLIST))
    staged = update_controller.normalize_allowlist(update_controller.load_json(update_controller.STAGED_ALLOWLIST))
    assert active["entries"] == [] and staged["entries"] == []
    settings = json.loads((ROOT / "local_assets/settings.json").read_text())
    assert settings["resource_gateway"]["legacy_fallback_enabled"] is False


def main() -> int:
    test_gateway_policy()
    test_candidate_ota()
    print("PASS289 LEGACY SEAM REGRESSION SELFTEST: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
