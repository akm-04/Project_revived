#!/usr/bin/env python3
"""Pass91 focused MID657 VIP one-time award lifecycle self-test."""
from __future__ import annotations

import copy
import json
import subprocess
import sys
import tempfile
import shutil
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.vip_award_catalog import VipAwardSourceCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.repository import StateRepository
from gxb_backend.state.multiuser_database import SANDBOX_SID
from gxb_backend.handlers.context import HandlerContext
from gxb_backend.handlers.system import SystemHandlers
from gxb_backend.config import Settings
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.vip_award_service import VipAwardService

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
SRC = Path("/mnt/data/pass90_assets/app-assets/output/assets/src_64")


def check(name: str, condition: bool, details: dict | None = None) -> dict:
    if not condition:
        raise AssertionError(f"{name}: {details or {}}")
    return {"name": name, "status": "PASS", "details": details or {}}


def item_qty(player: PlayerState, item_id: int) -> int:
    total = 0
    for row in player.backpack_items if isinstance(player.backpack_items, list) else []:
        if not isinstance(row, dict):
            continue
        try:
            rid = int(row.get("item_id", row.get("table_id", row.get("itemID", 0))) or 0)
            qty = int(row.get("item_num", row.get("num", row.get("itemNum", 0))) or 0)
        except (TypeError, ValueError):
            continue
        if rid == int(item_id):
            total += qty
    return total


def services_for(player: PlayerState, commit_callback):
    catalog = GameDataCatalog.load(DATA / "game_data_catalog.json")
    return RequestServices(player, DATA, commit_callback, catalog=catalog)


def main() -> int:
    checks = []
    source = VipAwardSourceCatalog(DATA)
    checks.append(check(
        "source_tiers_complete",
        source.levels() == tuple(range(1, 16)),
        {"levels": list(source.levels())},
    ))
    t1 = source.tier(1)
    t15 = source.tier(15)
    checks.append(check(
        "source_representative_rewards_exact",
        t1.gift_id == 90001099
        and t1.items == ((50001009, 6), (50001013, 10), (50001015, 2))
        and t1.crystal == 5
        and t15.gift_id == 90001113
        and t15.items == ((50001011, 5), (50001069, 1), (50001007, 20))
        and t15.crystal == 700,
        {"vip1": t1.response_awards(), "vip15": t15.response_awards()},
    ))

    # MID1 hydration/migration contract: source client requires a non-empty
    # one-based table. Preserve only explicit claimed=1 values.
    legacy = PlayerState(vip=15, charge=500000, vip_awards=[])
    changed = VipAwardService.normalize_player_claims(legacy)
    checks.append(check(
        "legacy_empty_claim_state_migrates_to_15_zeroes",
        changed and legacy.vip_awards == [0] * 15 and len(legacy.player_info_payload()["vip_awards"]) == 15,
    ))
    legacy.vip_awards = {"1": 1, "2": 0, "15": 1, "junk": 1}
    VipAwardService.normalize_player_claims(legacy)
    checks.append(check(
        "legacy_object_claim_state_preserves_explicit_claims",
        legacy.vip_awards[0] == 1 and legacy.vip_awards[1] == 0 and legacy.vip_awards[14] == 1
        and len(legacy.vip_awards) == 15,
        {"claims": legacy.vip_awards},
    ))
    legacy.vip_awards = [True] + [False] * 14
    bool_changed = VipAwardService.normalize_player_claims(legacy)
    checks.append(check(
        "claim_vector_is_literal_integer_zero_one",
        bool_changed and type(legacy.vip_awards[0]) is int and legacy.vip_awards[0] == 1
        and all(type(v) is int for v in legacy.vip_awards),
        {"claims": legacy.vip_awards},
    ))

    # VIP0 cannot claim VIP1 and no state mutates.
    p0 = PlayerState(account_uid="vip0", player_id="19790001", vip=0, charge=0, crystal=10, vip_awards=[0] * 15)
    s0 = services_for(p0, lambda: None)
    before0 = copy.deepcopy(vars(p0))
    r0 = s0.vip_awards.claim(1)
    checks.append(check(
        "vip0_cannot_claim_vip1",
        r0.get("error_code") == 1 and vars(p0) == before0,
        {"response": r0},
    ))

    # VIP1 claim must atomically grant source items + Crystal and mark exactly one tier.
    commits: list[dict] = []
    p1 = PlayerState(account_uid="vip1", player_id="19790002", vip=1, charge=30, crystal=100, vip_awards=[0] * 15)
    initial_items = {item_id: item_qty(p1, item_id) for item_id, _ in t1.items}
    def commit_ok():
        commits.append(copy.deepcopy(vars(p1)))
    s1 = services_for(p1, commit_ok)
    r1 = s1.vip_awards.claim(1)
    checks.append(check(
        "vip1_claims_vip1_atomically",
        r1.get("error_code", 0) == 0
        and r1.get("awards") == t1.response_awards()
        and p1.crystal == 105
        and p1.vip_awards == [1] + [0] * 14
        and all(item_qty(p1, item_id) == initial_items[item_id] + qty for item_id, qty in t1.items)
        and len(commits) == 1,
        {"response": r1, "crystal": p1.crystal, "claims": p1.vip_awards},
    ))
    after_first = copy.deepcopy(vars(p1))
    duplicate = s1.vip_awards.claim(1)
    checks.append(check(
        "duplicate_claim_grants_nothing",
        duplicate == {"awards": []} and vars(p1) == after_first and len(commits) == 1,
        {"response": duplicate},
    ))

    # A VIP15 account may claim an unclaimed lower tier but cannot reclaim it.
    p15 = PlayerState(account_uid="vip15", player_id="19790003", vip=15, charge=500000, crystal=0, vip_awards=[0] * 15)
    s15 = services_for(p15, lambda: None)
    low = s15.vip_awards.claim(3)
    checks.append(check(
        "vip15_can_claim_unclaimed_lower_tier",
        low.get("awards") == source.tier(3).response_awards() and p15.vip_awards[2] == 1 and sum(p15.vip_awards) == 1,
    ))

    # Simulated durable write failure: UoW must restore stack, Crystal and claim marker.
    pf = PlayerState(account_uid="fail", player_id="19790004", vip=2, charge=300, crystal=77, vip_awards=[0] * 15)
    def fail_commit():
        raise OSError("simulated durable write failure")
    sf = services_for(pf, fail_commit)
    before_fail = copy.deepcopy(vars(pf))
    raised = False
    try:
        sf.vip_awards.claim(2)
    except OSError:
        raised = True
    checks.append(check(
        "durable_failure_rolls_back_reward_and_claim_marker",
        raised and vars(pf) == before_fail,
    ))

    # Actual player-load normalization + SystemHandlers MID657 integration, with
    # a durable reload proving the claim marker and reward survive restart.
    with tempfile.TemporaryDirectory(prefix="pass91_repo_") as td:
        td = Path(td)
        data_copy = td / "data"
        shutil.copytree(DATA, data_copy)
        repo = StateRepository(
            path=data_copy / "player_db.json",
            profile="established",
            multiuser_root=data_copy / "server_state",
        )
        sandbox = repo.store.sandbox_player()
        sandbox.vip = 15
        sandbox.charge = max(500000, int(sandbox.charge or 0))
        sandbox.vip_awards = []
        before_crystal = int(sandbox.crystal)
        repo.store.save_player(sandbox)
        # Reload goes through MultiUserDatabase.normalize_player and must hydrate
        # the full non-empty vector before MID1/player_info would serialize it.
        hydrated = repo.store.sandbox_player()
        hydration_ok = hydrated.vip_awards == [0] * 15
        req = {"mid": 657, "sid": SANDBOX_SID, "region": 125, "id": 1}
        with repo.request_scope(req):
            response = SystemHandlers(HandlerContext(repo, Settings())).get_vip_award(req)
        reloaded = repo.store.sandbox_player()
        with repo.request_scope(req):
            duplicate_response = SystemHandlers(HandlerContext(repo, Settings())).get_vip_award(req)
        checks.append(check(
            "repository_mid657_hydrates_claims_and_survives_restart",
            hydration_ok
            and response.get("awards") == t1.response_awards()
            and reloaded.vip_awards[0] == 1
            and int(reloaded.crystal) == before_crystal + t1.crystal
            and duplicate_response == {"awards": []},
            {"response": response, "duplicate": duplicate_response, "claims": reloaded.vip_awards},
        ))

    # Source-generation drift guard. If effective src_64 changes, generated
    # runtime metadata must change with it rather than silently keeping stale rewards.
    if SRC.exists():
        with tempfile.TemporaryDirectory(prefix="pass91_meta_") as td:
            td = Path(td)
            subprocess.run([
                sys.executable, str(ROOT / "tools/build_commerce_vip_meta.py"), str(SRC),
                "--commerce-output", str(td / "commerce_source_meta.json"),
                "--vip-output", str(td / "vip_source_meta.json"),
                "--vip-award-output", str(td / "vip_award_meta.json"),
            ], check=True, stdout=subprocess.DEVNULL)
            checks.append(check(
                "effective_src64_regenerates_runtime_metadata_byte_exact",
                all((td / name).read_bytes() == (DATA / name).read_bytes() for name in (
                    "commerce_source_meta.json", "vip_source_meta.json", "vip_award_meta.json"
                )),
            ))

    report = {
        "pass": "91.0",
        "status": "PASS",
        "mid": 657,
        "checks": checks,
        "scope": "VIP one-time award lifecycle only; MID116 remains deferred",
    }
    out = ROOT / "docs/PASS91_VIP_AWARD_SELFTEST.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
