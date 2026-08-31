#!/usr/bin/env python3
"""Pass294 deterministic tests for separated auto-maintained MID2 lanes."""
from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import shutil
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.config import Settings
import gxb_backend.updates.local_update as lu
from gxb_backend.updates.local_update import select_update_plan, resolve_volume

spec = importlib.util.spec_from_file_location("pass294_update_controller", ROOT / "update_controller.py")
uc = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(uc)


def h(data: bytes, algo="md5") -> str:
    x = hashlib.new(algo); x.update(data); return x.hexdigest()


@contextmanager
def temp_controller():
    names = [
        "LOCAL","UPDATES","ASSET_UPDATES","CODE_UPDATES","CATALOG_UPDATES","POLICY_DIR","STAGING",
        "LEGACY_MANIFEST","REGISTRY","STATE","AUTO_POLICY","CURRENT_RES","OLD_RES","DATA","BASE_VERSION",
        "ACTIVE_VERSION","ACTIVE_CATALOG","ACTIVE_ALLOWLIST","STAGED_ALLOWLIST",
    ]
    old = {n: getattr(uc, n) for n in names}
    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        local = root / "local_assets"; data = root / "data/resource_catalog"
        local.mkdir(parents=True); data.mkdir(parents=True)
        mapping = {
            "LOCAL": local, "UPDATES": local/"updates", "ASSET_UPDATES": local/"updates/assets",
            "CODE_UPDATES": local/"updates/code", "CATALOG_UPDATES": local/"updates/catalog",
            "POLICY_DIR": local/"update_policy", "STAGING": local/"update_staging",
            "LEGACY_MANIFEST": local/"update_manifest.json", "REGISTRY": local/"release_registry.json",
            "STATE": local/"update_controller_state.json", "AUTO_POLICY": local/"settings.json",
            "CURRENT_RES": local/"res", "OLD_RES": local/"old_res", "DATA": data,
            "BASE_VERSION": data/"version_base_1.631.0.json", "ACTIVE_VERSION": data/"version_active.json",
            "ACTIVE_CATALOG": data/"resource_catalog.json", "ACTIVE_ALLOWLIST": data/"legacy_fallback_allowlist.json",
            "STAGED_ALLOWLIST": local/"update_policy/legacy_fallback_allowlist.staged.json",
        }
        for n,v in mapping.items(): setattr(uc,n,v)
        for d in (uc.ASSET_UPDATES, uc.CODE_UPDATES, uc.CATALOG_UPDATES, uc.POLICY_DIR, uc.STAGING, uc.CURRENT_RES, local/"src_32", local/"src_64"):
            d.mkdir(parents=True, exist_ok=True)
        reg = {
            "schema_version":1,
            "tracks":[{
                "track_id":"android-app-1.631.0","enabled":True,"app_v":"1.631.0","platform":3,
                "base_version":"1.631.0",
                "policy":{"required_initial_barrier":{"version":"1.631.1","release_type":uc.BULK_RESOURCE}},
                "releases":[],
            }],
        }
        uc.write_json_atomic(uc.REGISTRY, reg)
        empty = uc.empty_allowlist(); uc.write_json_atomic(uc.ACTIVE_ALLOWLIST, empty); uc.write_json_atomic(uc.STAGED_ALLOWLIST, empty)
        # Three tiny exact-current lazy assets.
        rows=[]
        for idx in range(3):
            payload=(f"asset-{idx}-"*200).encode()
            rel=f"web/images/icon/test{idx}_icon.png"
            p=uc.CURRENT_RES/rel; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(payload)
            rows.append({"path":f"res/{rel}","md5":h(payload),"size":len(payload),"force":0})
        uc.write_json_atomic(uc.BASE_VERSION, rows); uc.write_json_atomic(uc.ACTIVE_VERSION, rows); uc.write_json_atomic(uc.ACTIVE_CATALOG, uc.build_reverse_catalog(rows))
        # Cumulative code lane source.
        (local/"src_32/test.lua").write_text("return 32\n")
        (local/"src_64/test.lua").write_text("return 64\n")
        settings={
            "schema_version":1,
            "resource_gateway":{"legacy_fallback_enabled":False},
            "updates":{
                "enabled":True,"auto_ensure":True,"auto_publish":True,"max_volume_bytes":1000,
                "asset_bootstrap":{"enabled":True,"version":"1.631.1","min_exact_files":3},
                "code_baseline":{"enabled":True,"version":"1.631.2"},
            },
        }
        uc.write_json_atomic(uc.AUTO_POLICY, settings)
        try:
            yield root
        finally:
            for n,v in old.items(): setattr(uc,n,v)


def test_auto_build_idempotency_and_no_res_restore():
    with temp_controller() as root:
        first=uc.ensure_auto_releases(policy_path=uc.AUTO_POLICY)
        assert "build+publish:1.631.1" in first["actions"]
        assert "build+publish:1.631.2" in first["actions"]
        reg=uc.load_registry(); rels=uc.current_track(reg)["releases"]
        assert [(r["version"],r["lane"],r["status"]) for r in rels] == [
            ("1.631.1","assets","PUBLISHED"),("1.631.2","code","PUBLISHED")]
        asset=rels[0]
        assert asset["volume"] > 1
        assert all(int(x["size"]) <= 1000 for x in asset["volume_files"])
        assert uc.release_sidecar_path(asset).is_file()
        second=uc.ensure_auto_releases(policy_path=uc.AUTO_POLICY)
        assert second["actions"] == ["skip:1.631.1","skip:1.631.2"]
        # Simulate a Git deployment that retains immutable shards/sidecars but no res tree or registry history.
        shutil.rmtree(uc.CURRENT_RES)
        reg["tracks"][0]["releases"]=[]; uc.write_json_atomic(uc.REGISTRY, reg)
        restored=uc.ensure_auto_releases(policy_path=uc.AUTO_POLICY)
        assert restored["actions"] == ["skip:1.631.1","skip:1.631.2"], restored
        reg2=uc.load_registry(); assert [r["version"] for r in uc.current_track(reg2)["releases"]] == ["1.631.1","1.631.2"]


def test_auto_publish_false_and_barrier():
    with temp_controller():
        settings=uc.load_json(uc.AUTO_POLICY); settings["updates"]["auto_publish"]=False; uc.write_json_atomic(uc.AUTO_POLICY, settings)
        result=uc.ensure_auto_releases(policy_path=uc.AUTO_POLICY)
        assert result["actions"] == ["build-candidate:1.631.1","withhold-code:1.631.2"], result
        track=uc.current_track(uc.load_registry()); assert len(track["releases"])==1 and track["releases"][0]["status"]=="CANDIDATE"


def test_git_safe_constant_and_resolution():
    assert uc.GIT_SAFE_VOLUME_BYTES == 99_000_000
    try:
        uc._split_zip(Path(__file__), "bad.zip", 100_000_000, out_dir=Path(tempfile.mkdtemp()))
    except ValueError as exc:
        assert "Git-safe" in str(exc)
    else:
        raise AssertionError("100,000,000-byte shard cap was accepted")
    with temp_controller():
        uc.ensure_auto_releases(policy_path=uc.AUTO_POLICY)
        reg=uc.load_registry(); asset=uc.current_track(reg)["releases"][0]
        settings=Settings(local_update_dir=uc.UPDATES, local_update_release_registry_path=uc.REGISTRY)
        name=asset["volume_files"][0]["name"]
        assert resolve_volume(settings, f"assets/{name}") == uc.ASSET_UPDATES/name
        assert resolve_volume(settings, f"code/{name}") is None
        assert resolve_volume(settings, "../assets/"+name) is None



def test_mid2_stat_cache_avoids_rehash():
    with temp_controller():
        uc.ensure_auto_releases(policy_path=uc.AUTO_POLICY)
        settings=Settings(local_update_dir=uc.UPDATES, local_update_release_registry_path=uc.REGISTRY, runtime_log_dir=uc.LOCAL/"logs")
        primed=lu.prime_release_integrity_cache(settings)
        assert primed == {"verified":2,"failed":0}, primed
        original=lu.deep_verify_release
        try:
            def forbidden(*_a, **_k):
                raise AssertionError("MID2 attempted a deep payload rehash despite unchanged stat fingerprint")
            lu.deep_verify_release=forbidden
            rows=lu.select_update_plan(settings,{"v":"1.631.0","app_v":"1.631.0","platform":3})
            assert [r["version"] for r in rows] == ["1.631.1"]
        finally:
            lu.deep_verify_release=original
        # A stat change invalidates the cache and requires re-verification.
        asset=uc.current_track(uc.load_registry())["releases"][0]
        shard=uc.ASSET_UPDATES/asset["volume_files"][0]["name"]
        st=shard.stat(); os.utime(shard, ns=(st.st_atime_ns, st.st_mtime_ns+1_000_000))
        calls={"n":0}
        original=lu.deep_verify_release
        try:
            def counted(settings_, release_, *, log=True):
                calls["n"] += 1
                return original(settings_, release_, log=log)
            lu.deep_verify_release=counted
            rows=lu.select_update_plan(settings,{"v":"1.631.0","app_v":"1.631.0","platform":3})
            assert rows and calls["n"] == 1
        finally:
            lu.deep_verify_release=original

def test_project_settings_contract():
    payload=json.loads((ROOT/"local_assets/settings.json").read_text())
    assert payload["updates"]["auto_ensure"] is True
    assert payload["updates"]["auto_publish"] is True
    assert payload["updates"]["max_volume_bytes"] == 99_000_000
    asset_v=payload["updates"]["asset_bootstrap"]["version"]
    code_v=payload["updates"]["code_baseline"]["version"]
    assert asset_v == "1.631.1"
    assert code_v == "1.631.2" and uc.parse_version(code_v) > uc.parse_version(asset_v)
    assert payload["resource_gateway"]["legacy_fallback_enabled"] is False
    readme=(ROOT/"local_assets/README.md").read_text()
    for token in ("auto_publish", "99,000,000", "updates/assets", "updates/code", "release_registry.json"):
        assert token in readme


if __name__ == "__main__":
    test_auto_build_idempotency_and_no_res_restore()
    test_auto_publish_false_and_barrier()
    test_git_safe_constant_and_resolution()
    test_mid2_stat_cache_avoids_rehash()
    test_project_settings_contract()
    print("PASS294 AUTO UPDATE SELFTEST: OK")
