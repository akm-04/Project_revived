#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, sys, tempfile, types, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
class FakeResponse:
    def __init__(self,data,status=200): self.data=data; self.status_code=int(status); self.headers={}
def jsonify(data): return data
def make_response(data,status=200): return FakeResponse(data,status)
fake=types.ModuleType("flask"); fake.jsonify=jsonify; fake.make_response=make_response; fake.request=None
sys.modules.setdefault("flask",fake)
from gxb_backend.config import Settings
from gxb_backend.state.repository import StateRepository
from gxb_backend.transport import routes_commerce
from gxb_backend.updates.local_update import load_manifest, version_check_payload, resolve_volume
class FakeRequest:
    def __init__(self,body): self._body=dict(body); self.form={}; self.cookies={}
    def get_json(self,silent=True): return dict(self._body)
class FakeApp:
    def __init__(self): self.routes={}
    def route(self,path,methods=None):
        def deco(fn): self.routes[path]=fn; return fn
        return deco
def main():
    # src_64 feedback-loop invariant: the OTA utils override must preserve the
    # effective canonical utils.lua byte-for-byte and append only Pass89 code.
    canonical_len=250825
    canonical_sha="6e56c7342e889d7ae8d41fe47cb06f66832227efe702f3863f693ee7ba84ffad"
    for arch in ("src_32","src_64"):
        override=(ROOT/"local_assets"/arch/"app/common/utils.lua").read_bytes()
        assert hashlib.sha256(override[:canonical_len]).hexdigest()==canonical_sha
        assert b"-- PASS89 PRESERVATION OTA PURCHASE BRIDGE" in override[canonical_len:]
    preserved=json.loads((ROOT/"docs/PASS89_OTA_CUMULATIVE_HASHES.json").read_text())
    assert preserved["count"]==124
    for row in preserved["files"]:
        current=ROOT/"local_assets"/row["path"]
        assert current.is_file(),row["path"]
        assert hashlib.sha256(current.read_bytes()).hexdigest()==row["sha256"],row["path"]
    settings=Settings()
    manifest=load_manifest(settings)
    assert manifest and manifest["version"]=="1.631.3" and manifest["silent"] is True
    advertised=version_check_payload(settings,{"v":"","platform":3,"app_v":"1.631.0"})
    assert advertised["is_inapp"]==1 and advertised["is_review"]==1
    desc=advertised["res"][0]; assert desc["version"]=="1.631.3" and desc["md5"]==manifest["md5"]
    current=version_check_payload(settings,{"v":"1.631.3"}); assert current["is_inapp"]==0 and "res" not in current
    volume=resolve_volume(settings,manifest["package"]+".001"); assert volume and hashlib.md5(volume.read_bytes()).hexdigest()==manifest["md5"]
    with zipfile.ZipFile(volume) as zf:
        assert zf.testzip() is None
        names=sorted(zf.namelist())
        assert len(names)==126, len(names)
        for historical in ("src_32/app/windows/LoginWindow.lua","src_64/app/windows/LoginWindow.lua","src_32/data/tables/translation.lua","src_64/data/tables/translation.lua"):
            assert historical in names, historical
        assert "src_32/app/common/utils.lua" in names and "src_64/app/common/utils.lua" in names
        u32=zf.read("src_32/app/common/utils.lua"); u64=zf.read("src_64/app/common/utils.lua"); assert u32==u64
        for marker in (b"[PASS89 OTA] direct Crystal purchase bridge installed",b"pass89OriginalAndroidPurchase",b"pass89OriginalSdkPurchase",b"expected_player_id",b"backend.token_",b"backend.region_"):
            assert marker in u64,marker
    with tempfile.TemporaryDirectory(prefix="pass89_auth_") as td:
        repo=StateRepository(ROOT/"data/player_db.json",profile="established",legacy_path=ROOT/"state/gxb_state.json",multiuser_root=Path(td)/"server_state")
        app=FakeApp(); routes_commerce.register_commerce_routes(app,repo); handler=app.routes["/preservation/v1/purchase-intents"]
        legacy={"intent_id":"p89-legacy","charge_id":80001007,"platform":"preservation_manual","token":"local_token","region":125}
        routes_commerce.request=FakeRequest(legacy); denied=handler(); assert denied.status_code==409 and denied.data["error"]=="LEGACY_SANDBOX_EXPLICIT_OPT_IN_REQUIRED"
        rec,status=repo.sdk_register("pass89vip0","pass1234"); assert rec and status=="created"
        identity=repo.sdk_login("pass89vip0","pass1234"); assert identity
        with repo.request_scope({"mid":1,"sid":identity.sid,"region":197}):
            player,_=repo.resolve_or_create_player(197); new_pid=str(player.player_id)
        body={"intent_id":"p89-normal","charge_id":80001007,"platform":"lua_preservation","token":identity.token,"region":197,"expected_player_id":new_pid}
        routes_commerce.request=FakeRequest(body); ok=handler(); assert ok.status_code==200 and ok.data["status"]=="COMMITTED",ok.data
        assert ok.data["settlement"]["state"]["vip"]==1 and ok.data["settlement"]["state"]["charge"]==100
        mismatch=dict(body); mismatch["intent_id"]="p89-mismatch"; mismatch["expected_player_id"]="13371337"
        routes_commerce.request=FakeRequest(mismatch); bad=handler(); assert bad.status_code==409 and bad.data["error"]=="AUTH_PLAYER_MISMATCH"
        legacy_pid=str(repo.store.sandbox_player().player_id)
        legacy_ok=dict(legacy); legacy_ok["intent_id"]="p89-legacy-ok"; legacy_ok["allow_legacy_sandbox"]=1; legacy_ok["expected_player_id"]=legacy_pid
        routes_commerce.request=FakeRequest(legacy_ok); allowed=handler(); assert allowed.status_code==200 and allowed.data["ok"]==1
    result={"pass":"89.0","status":"PASS","checks":["mid2_advertises_1.631.3","same_version_not_readvertised","ota_zip_md5_and_cumulative_126_overrides","ota_bridge_uses_live_token_region_and_expected_player","legacy_local_token_requires_explicit_optin","normal_sdk_token_settles_correct_player_vip0_to_vip1","expected_player_mismatch_rejected","explicit_legacy_sandbox_still_supported","canonical_utils_prefix_exact","all_124_prior_ota_overrides_byte_exact"]}
    (ROOT/"docs/PASS89_OTA_TOKEN_SELFTEST.json").write_text(json.dumps(result,indent=2)+"\n")
    print(result); return 0
if __name__=="__main__": raise SystemExit(main())
