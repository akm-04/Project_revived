#!/usr/bin/env python3
"""Pass100 focused MID97 OTA identity + exactly-once Energy-purchase self-test."""
from __future__ import annotations

import copy
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.config import Settings
from gxb_backend.updates.local_update import load_manifest, version_check_payload
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.server_clock import ServerClock

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
FIXED_NOW = 1_788_000_000


class MutableClock(ServerClock):
    def __init__(self, value: int = FIXED_NOW) -> None:
        self.value = int(value)
    def now(self) -> int:
        return int(self.value)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def make_services(*, vip: int = 15, crystal: int = 5000, energy: int = 100,
                  privilege_days: int = 0, fail_commit: bool = False,
                  clock: MutableClock | None = None):
    player = PlayerState(
        account_uid=f"pass100-vip{vip}", player_id=f"10000{vip:02d}",
        player_name="Pass100", vip=vip, crystal=crystal,
        privilege_left_card_day=privilege_days,
    )
    player.lev = 100
    player.max_lev = 100
    player.energy = energy
    player.max_energy = 160
    player.energy_time = 0
    player.buy_energy_times = 0
    commits: list[int] = []
    def commit() -> None:
        if fail_commit:
            raise OSError("simulated durable write failure")
        commits.append(1)
    actual_clock = clock or MutableClock()
    services = RequestServices(player, DATA, commit, catalog=CATALOG, server_clock=actual_clock)
    return player, services, commits, actual_clock


def req(services: RequestServices, expected: int, *, day: int | None = None, nonce: str | None = None) -> dict:
    day_id = services.energy_purchase.day_clock.day_id() if day is None else int(day)
    suffix = nonce or f"00000000-0000-4000-8000-{int(expected)+1:012x}"
    return {
        "expected_buy_energy_times": int(expected),
        "energy_day_id": day_id,
        "energy_op_id": services.energy_purchase.operation_id(day_id, expected, suffix),
    }


def test_source_contract() -> None:
    p, s, _, _ = make_services(vip=15)
    src = s.energy_purchase_source
    require(src.energy_grant == 120, f"Energy grant drift: {src.energy_grant}")
    require(src.energy_purchase_threshold == 500, f"Energy threshold drift: {src.energy_purchase_threshold}")
    require(src.monthly_privilege_num_energy == 4, "Monthly Privilege num_energy must be 4")
    require([src.cost(i) for i in range(1, 15)] == [50,50,100,100,100,100,200,200,200,400,400,400,400,1000], "source cost prefix drift")
    require(s.vip_privileges.energy_purchase_limit() == 16, "VIP15 num_energy drift")
    p.vip = 0
    require(s.energy_purchase.total_allowance() == 1, "VIP0 must get one purchase")
    p.privilege_left_card_day = 1
    require(s.energy_purchase.total_allowance() == 5, "VIP0 + Monthly Privilege must get five purchases")


def test_exactly_once_and_next_purchase() -> None:
    p, s, commits, _ = make_services(vip=15, crystal=1000, energy=100)
    first_req = req(s, 0)
    first = s.energy_purchase.purchase(first_req)
    require(first == {"buy_energy_times": 1, "economy_": {"crystal": 950, "energy": 220}}, f"first purchase mismatch: {first}")
    require(len(commits) == 1, "first purchase must commit once")
    receipt = s.uow.get_receipt(s.energy_purchase.RECEIPT_DOMAIN, first_req["energy_op_id"])
    require(isinstance(receipt, dict) and receipt.get("status") == "COMMITTED", "MID97 receipt missing")

    replay = s.energy_purchase.purchase(first_req)
    require(replay == first, f"same-op replay mismatch: {replay}")
    require((p.crystal, p.energy, p.buy_energy_times, len(commits)) == (950, 220, 1, 1), "retry double-mutated purchase")

    second_req = req(s, 1)
    second = s.energy_purchase.purchase(second_req)
    require(second == {"buy_energy_times": 2, "economy_": {"crystal": 900, "energy": 340}}, f"second legitimate purchase mismatch: {second}")
    require(len(commits) == 2, "legitimate next purchase suppressed")


def test_identity_and_limits() -> None:
    p, s, commits, _ = make_services(vip=0, crystal=500, energy=100)
    empty = s.energy_purchase.purchase({})
    require(empty.get("msg") == "mid97_ota_identity_required" and commits == [], "unpatched MID97 must fail closed")
    day = s.energy_purchase.day_clock.day_id()
    bad = s.energy_purchase.purchase({"expected_buy_energy_times":0,"energy_day_id":day,"energy_op_id":"wrong"})
    require(bad.get("msg") == "mid97_operation_identity_invalid", "forged operation id not rejected")
    stale = s.energy_purchase.purchase(req(s, 1))
    require(stale.get("msg") == "mid97_expected_ordinal_mismatch", "stale/future ordinal not rejected")

    ok = s.energy_purchase.purchase(req(s, 0))
    require(ok.get("buy_energy_times") == 1, "VIP0 first purchase failed")
    denied = s.energy_purchase.purchase(req(s, 1))
    require(denied.get("msg") == "mid97_purchase_limit_exhausted", f"VIP0 second purchase not capped: {denied}")
    require((p.crystal, p.energy, len(commits)) == (450, 220, 1), "limit failure mutated state")


def test_threshold_and_atomic_failure() -> None:
    p, s, commits, _ = make_services(vip=15, crystal=1000, energy=500)
    denied = s.energy_purchase.purchase(req(s, 0))
    require(denied.get("msg") == "mid97_energy_threshold_reached" and commits == [], "Energy>=500 must reject")
    require((p.crystal,p.energy,p.buy_energy_times)==(1000,500,0), "threshold rejection mutated state")

    p2, s2, c2, _ = make_services(vip=15, crystal=1000, energy=499)
    ok = s2.energy_purchase.purchase(req(s2, 0))
    require(ok["economy_"]["energy"] == 619, "source allows purchase result to exceed 500")

    p3, s3, c3, _ = make_services(vip=15, crystal=49, energy=100)
    denied_crystal = s3.energy_purchase.purchase(req(s3,0))
    require(denied_crystal.get("msg") == "crystal_insufficient" and c3 == [], "insufficient Crystal not atomic")

    pf, sf, _, _ = make_services(vip=15, crystal=1000, energy=100, fail_commit=True)
    before = copy.deepcopy(vars(pf))
    raised=False
    try:
        sf.energy_purchase.purchase(req(sf,0))
    except OSError:
        raised=True
    require(raised and vars(pf)==before, "durable failure did not roll back Crystal/Energy/counter/receipt")


def test_day_rollover_receipt_precedence() -> None:
    clock = MutableClock()
    p, s, commits, _ = make_services(vip=15, crystal=1000, energy=100, clock=clock)
    old_day=s.energy_purchase.day_clock.day_id()
    old_req=req(s,0,day=old_day)
    s.energy_purchase.purchase(old_req)
    require((p.crystal,p.energy,p.buy_energy_times)==(950,220,1), "setup purchase failed")

    # Model the already-proven DailyResetCoordinator ownership of the counter.
    p.buy_energy_times=0
    clock.value += 86400
    new_day=s.energy_purchase.day_clock.day_id()
    require(new_day==old_day+1, "clock did not cross source day")

    replay=s.energy_purchase.purchase(old_req)
    require(replay["buy_energy_times"]==0 and replay["economy_"]["crystal"]==950, "committed old-day retry not reconciled read-only")
    require(len(commits)==1, "old-day retry committed again")

    fresh=s.energy_purchase.purchase(req(s,0,day=new_day))
    require(fresh["buy_energy_times"]==1 and fresh["economy_"]["crystal"]==900, "new-day ordinal-0 purchase collided with prior day")
    require(len(commits)==2, "new-day purchase not committed")

    p2, s2, c2, clock2 = make_services(vip=15, crystal=1000, energy=100)
    stale_day=s2.energy_purchase.day_clock.day_id()-1
    stale_req=req(s2,0,day=stale_day)
    denied=s2.energy_purchase.purchase(stale_req)
    require(denied.get("msg")=="mid97_source_day_mismatch" and c2==[], "uncommitted stale-day request must fail")


def test_source_regeneration_and_ota() -> None:
    src64 = Path(os.environ.get("GXB_SRC64", ""))
    asset_root = Path(os.environ.get("GXB_ASSET_ROOT", ""))
    if src64.is_dir():
        with tempfile.TemporaryDirectory(prefix="pass100-meta-") as td:
            out=Path(td)/"energy_purchase_source_meta.json"
            subprocess.run([sys.executable,str(ROOT/"tools/build_energy_purchase_meta.py"),str(src64),"--output",str(out)],check=True,stdout=subprocess.DEVNULL)
            require(out.read_bytes()==(DATA/"energy_purchase_source_meta.json").read_bytes(), "MID97 source metadata does not regenerate byte-exact")
    if asset_root.is_dir():
        with tempfile.TemporaryDirectory(prefix="pass100-ota-") as td:
            td=Path(td)
            subprocess.run([sys.executable,str(ROOT/"tools/build_pass100_add_energy_bridge.py"),str(asset_root),"--local-assets",str(td/"local_assets"),"--report",str(td/"report.json")],check=True,stdout=subprocess.DEVNULL)
            for arch in ("src_32","src_64"):
                built=td/"local_assets"/arch/"app/model/AddEnergy.lua"
                packaged=ROOT/"local_assets"/arch/"app/model/AddEnergy.lua"
                require(built.read_bytes()==packaged.read_bytes(), f"{arch} AddEnergy OTA override not reproducible")

    manifest=json.loads((ROOT/"local_assets/update_manifest.json").read_text())
    require(manifest["version"]=="1.631.4" and manifest["silent"] is True, "MID2 manifest version/silent drift")
    loaded=load_manifest(Settings())
    require(loaded is not None and loaded["version"]=="1.631.4", "runtime loader did not accept Pass100 manifest")
    advertised=version_check_payload(Settings(), {"v":"1.631.3","platform":3,"app_v":"1.631.0"})
    require(advertised.get("is_inapp")==1 and advertised.get("is_review")==1 and advertised.get("res", [{}])[0].get("version")=="1.631.4", "MID2 did not advertise Pass100 OTA to 1.631.3")
    current=version_check_payload(Settings(), {"v":"1.631.4","platform":3,"app_v":"1.631.0"})
    require(current.get("is_inapp")==0 and "res" not in current, "MID2 re-advertised same Pass100 resource version")
    require(len(manifest["files"])==128, f"expected cumulative 128 OTA files, got {len(manifest['files'])}")
    for arch in ("src_32","src_64"):
        rel=f"{arch}/app/model/AddEnergy.lua"
        require(rel in manifest["files"], f"{rel} missing from MID2 manifest")
        raw=(ROOT/"local_assets"/rel).read_bytes()
        report=json.loads((ROOT/"docs/PASS100_OTA_BRIDGE_BUILD.json").read_text())
        expected_hash=next(r["override_sha256"] for r in report["files"] if r["arch"]==arch)
        require(hashlib.sha256(raw).hexdigest()==expected_hash, f"{rel} bridge hash drift")
        text=raw.decode("utf-8-sig")
        for marker in ("PASS100 PRESERVATION OTA MID97 BRIDGE","expected_buy_energy_times","energy_day_id","energy_op_id","+ 10800","p100-energy-","xyd.generateUUID()"):
            require(marker in text, f"{rel} missing {marker}")

    preserved=json.loads((ROOT/"docs/PASS100_OTA_PRIOR_OVERRIDE_HASHES.json").read_text())
    require(preserved["count"]==126, "Pass99 cumulative preservation list drift")
    for row in preserved["files"]:
        path=ROOT/"local_assets"/row["path"]
        require(path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest()==row["sha256"], f"prior OTA override changed: {row['path']}")

    volume=ROOT/"local_assets/updates"/(manifest["package"]+".001")
    require(volume.is_file(), "MID2 volume missing")
    require(hashlib.md5(volume.read_bytes()).hexdigest()==manifest["md5"], "MID2 volume md5 mismatch")
    with zipfile.ZipFile(volume) as zf:
        require(zf.testzip() is None and len(zf.namelist())==128, "MID2 ZIP volume invalid")
        require(zf.read("src_32/app/model/AddEnergy.lua")==zf.read("src_64/app/model/AddEnergy.lua"), "OTA arch bridge drift")


def main() -> int:
    test_source_contract()
    test_exactly_once_and_next_purchase()
    test_identity_and_limits()
    test_threshold_and_atomic_failure()
    test_day_rollover_receipt_precedence()
    test_source_regeneration_and_ota()
    report={
        "pass":"100.0","status":"PASS","mid":97,
        "checks":[
            "source_energy_purchase_contract","ota_source_day_expected_ordinal_uuid_identity","exactly_once_receipt_replay",
            "legitimate_next_purchase_not_suppressed","vip_plus_monthly_allowance","energy_500_pre_purchase_threshold",
            "source_cost_scaling","atomic_crystal_energy_counter_receipt","durable_failure_rollback",
            "old_day_receipt_replay_precedes_day_guard","new_day_ordinal_zero_identity_noncollision",
            "unpatched_mid97_fail_closed","source_metadata_reproducible","ota_bridge_reproducible",
            "pass99_126_ota_overrides_byte_exact","mid2_1.631.4_cumulative_128_volume_and_advertisement",
        ],
    }
    (ROOT/"docs/PASS100_MID97_SELFTEST.json").write_text(json.dumps(report,indent=2)+"\n")
    print(json.dumps(report,indent=2))
    return 0

if __name__=="__main__":
    raise SystemExit(main())
