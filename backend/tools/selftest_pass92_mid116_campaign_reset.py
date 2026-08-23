#!/usr/bin/env python3
"""Pass92 focused MID116 Super Campaign paid-reset self-test."""
from __future__ import annotations

import copy
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.campaign_reset_catalog import CampaignResetSourceCatalog
from gxb_backend.state.daily_reset import CampaignDailyResetParticipant, DailyResetContext
from gxb_backend.state.multiuser_database import SANDBOX_SID
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.repository import StateRepository
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.response_projector import ResponseProjector

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
SRC = Path(os.environ.get("GXB_SRC64", "/mnt/data/pass92_work/assets/app-assets/output/assets/src_64"))
CID = 100019


def check(name: str, condition: bool, details: dict | None = None) -> dict:
    if not condition:
        raise AssertionError(f"{name}: {details or {}}")
    return {"name": name, "status": "PASS", "details": copy.deepcopy(details or {})}


def services(*, vip: int, crystal: int = 5000, privilege_days: int = 0, fail_commit: bool = False):
    p = PlayerState(
        account_uid=f"pass92-vip{vip}",
        player_id=f"9200{vip:02d}",
        player_name="Pass92",
        vip=vip,
        crystal=crystal,
        privilege_left_card_day=privilege_days,
    )
    commits: list[int] = []

    def commit():
        if fail_commit:
            raise OSError("simulated durable write failure")
        commits.append(int(p.persistence_state.get("state_version", 0)))

    s = RequestServices(p, DATA, commit, catalog=CATALOG)
    s.world.normalize()
    row = {
        "campaign_id": CID,
        "star": 3,
        "daily_limit": 0,
        "reset_count": 0,
        "is_partner_drop": 1,
    }
    current = s.world._find_row(CID, 2)
    if current is None:
        s.world._mode_rows(2).append(row)
    else:
        current.clear()
        current.update(row)
        row = current
    return p, s, row, commits


def main() -> int:
    checks = []
    source = CampaignResetSourceCatalog(DATA)
    checks.append(check(
        "source_reset_contract_exact",
        source.monthly_privilege_num_elite == 3
        and [source.cost(i) for i in range(1, 9)] == [20, 50, 50, 100, 100, 200, 200, 400]
        and source.cost(28) == 1000,
        {"monthly_bonus": source.monthly_privilege_num_elite, "first8": [source.cost(i) for i in range(1, 9)], "cost28": source.cost(28)},
    ))

    # VIP1 has no source num_elite reset privilege.
    p1, s1, row1, commits1 = services(vip=1, crystal=500)
    before1 = copy.deepcopy(vars(p1))
    out1 = s1.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    checks.append(check(
        "vip1_without_monthly_has_no_reset",
        out1.get("error_code") == 1 and out1.get("msg") == "campaign_reset_limit_exhausted"
        and vars(p1) == before1 and commits1 == [],
        {"response": out1},
    ))

    # VIP2 gets exactly one paid reset. First source cost is 20. Star and
    # is_partner_drop must survive while remaining attempts restore to 3.
    p2, s2, row2, commits2 = services(vip=2, crystal=100)
    before_star = row2["star"]
    before_partner = row2["is_partner_drop"]
    v_before = s2.uow.current_state_version
    out2 = s2.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    checks.append(check(
        "vip2_first_reset_atomic",
        out2 == {"campaign_id": CID, "star": 3, "daily_limit": 3, "reset_count": 1}
        and p2.crystal == 80 and row2["star"] == before_star and row2["is_partner_drop"] == before_partner
        and len(commits2) == 1 and s2.uow.current_state_version == v_before + 1,
        {"response": out2, "crystal": p2.crystal, "row": row2},
    ))
    # Default web ResponseProjector exposes the cumulative Crystal debit in
    # economy_, matching the UI's global resource-sync contract.
    pp, sp, rp, _ = services(vip=2, crystal=100)
    projector = ResponseProjector.capture(pp, resource_registry=sp.resource_registry)
    pout = sp.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    projected = projector.project(pout, pp, committed_journal=sp.uow.consume_journal(), profile=None)
    checks.append(check(
        "mid116_projects_cumulative_crystal",
        projected.get("economy_", {}).get("crystal") == 80,
        {"projected": projected},
    ))

    # Lost-response/source retry reconciliation: while refreshed attempts still
    # exist, the same MID116 is a mutation-free read of the committed row.
    version_after = s2.uow.current_state_version
    replay = s2.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    checks.append(check(
        "postcommit_retry_reconciles_without_second_charge",
        replay == out2 and p2.crystal == 80 and len(commits2) == 1 and s2.uow.current_state_version == version_after,
        {"response": replay},
    ))

    # Once attempts are consumed again, VIP2's single allowance is exhausted.
    row2["daily_limit"] = 0
    denied2 = s2.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    checks.append(check(
        "vip2_second_paid_reset_rejected",
        denied2.get("error_code") == 1 and denied2.get("msg") == "campaign_reset_limit_exhausted"
        and p2.crystal == 80 and row2["reset_count"] == 1,
        {"response": denied2},
    ))

    # Active Monthly Privilege is orthogonal to VIP. Even VIP1 gets +3 reset
    # allowance from row1 num_elite=3; it does not mutate/decrement card days.
    pm, sm, rowm, _ = services(vip=1, crystal=500, privilege_days=7)
    outm = sm.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    checks.append(check(
        "monthly_privilege_adds_three_without_card_lifecycle_mutation",
        sm.campaign_reset_policy.total_allowance() == 3
        and outm.get("reset_count") == 1 and pm.crystal == 480 and pm.privilege_left_card_day == 7,
        {"allowance": sm.campaign_reset_policy.total_allowance(), "response": outm},
    ))

    # VIP15 source allowance is 25; Monthly Privilege extends it to 28 and the
    # source table has explicit costs for all reachable ordinals.
    p15, s15, row15, _ = services(vip=15, crystal=5000)
    row15["reset_count"] = 24
    out25 = s15.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    row15["daily_limit"] = 0
    denied26 = s15.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    p15.privilege_left_card_day = 1
    out26 = s15.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    row15["daily_limit"] = 0
    row15["reset_count"] = 27
    out28 = s15.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    row15["daily_limit"] = 0
    denied29 = s15.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    checks.append(check(
        "vip15_plus_monthly_reaches_source_max_28",
        out25.get("reset_count") == 25 and denied26.get("error_code") == 1
        and out26.get("reset_count") == 26 and out28.get("reset_count") == 28
        and denied29.get("error_code") == 1 and s15.campaign_reset_policy.total_allowance() == 28,
        {"out25": out25, "out26": out26, "out28": out28, "denied29": denied29},
    ))

    # Insufficient Crystal must fail before the campaign row mutates.
    pi, si, rowi, commits_i = services(vip=2, crystal=19)
    before_i = copy.deepcopy(vars(pi))
    insufficient = si.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    checks.append(check(
        "insufficient_crystal_is_atomic",
        insufficient.get("error_code") == 1 and insufficient.get("msg") == "crystal_insufficient"
        and vars(pi) == before_i and commits_i == [],
        {"response": insufficient},
    ))

    # Invalid domain/state inputs do not consume a state version.
    px, sx, rowx, _ = services(vip=15, crystal=9999)
    vx = sx.uow.current_state_version
    normal = sx.world.reset_campaign({"campaign_id": 100001, "campaign_type": 1})
    rowx["daily_limit"] = 3
    rowx["reset_count"] = 0
    nonexhausted = sx.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    checks.append(check(
        "fail_closed_domain_and_initial_nonexhausted_guards",
        normal.get("error_code") == 1 and nonexhausted.get("error_code") == 1
        and sx.uow.current_state_version == vx,
        {"normal": normal, "nonexhausted": nonexhausted},
    ))

    # Durable write failure must roll both typed Crystal debit and Campaign row
    # back to the exact pre-request snapshot.
    pf, sf, rowf, _ = services(vip=2, crystal=100, fail_commit=True)
    before_f = copy.deepcopy(vars(pf))
    raised = False
    try:
        sf.world.reset_campaign({"campaign_id": CID, "campaign_type": 2})
    except OSError:
        raised = True
    checks.append(check(
        "durable_failure_rolls_back_crystal_and_campaign",
        raised and vars(pf) == before_f,
    ))

    # Daily source-day rollover still clears paid-reset count independently of
    # VIP and restores the source baseline.
    pd, sd, rowd, _ = services(vip=15, crystal=0)
    rowd["reset_count"] = 17
    rowd["daily_limit"] = 0
    reset = CampaignDailyResetParticipant(DATA).reset(
        pd,
        DailyResetContext(previous_day_id=200, current_day_id=201, current_day_start=0, now=0, trigger_mid=229),
    )
    checks.append(check(
        "daily_reset_still_restores_baseline_and_reset_count",
        reset.changed and rowd["daily_limit"] == 3 and rowd["reset_count"] == 0,
        {"row": rowd},
    ))

    # Actual handler/repository integration under a player request scope.
    with tempfile.TemporaryDirectory(prefix="pass92_repo_") as td:
        td = Path(td)
        data_copy = td / "data"
        shutil.copytree(DATA, data_copy)
        repo = StateRepository(path=data_copy / "player_db.json", profile="established", multiuser_root=data_copy / "server_state")
        sandbox = repo.store.sandbox_player()
        sandbox.vip = 2
        sandbox.charge = 300
        sandbox.crystal = 100
        # Ensure representative source-known Super row is unlocked and exhausted.
        rows = sandbox.world_map.setdefault("super", [])
        row = next((r for r in rows if isinstance(r, dict) and int(r.get("campaign_id", 0) or 0) == CID), None)
        if row is None:
            row = {"campaign_id": CID, "star": 3, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}
            rows.append(row)
        else:
            row.update({"star": 3, "daily_limit": 0, "reset_count": 0})
        repo.store.save_player(sandbox)
        req = {"mid": 116, "sid": SANDBOX_SID, "region": 125, "campaign_id": CID, "campaign_type": 2}
        with repo.request_scope(req):
            response = repo.get_world_repository().reset_campaign(req)
        reloaded = repo.store.sandbox_player()
        rr = next(r for r in reloaded.world_map.get("super", []) if int(r.get("campaign_id", 0) or 0) == CID)
        checks.append(check(
            "request_scoped_mid116_persists_source_shaped_row",
            response == {"campaign_id": CID, "star": 3, "daily_limit": 3, "reset_count": 1}
            and int(reloaded.crystal) == 80 and int(rr.get("daily_limit", 0)) == 3 and int(rr.get("reset_count", 0)) == 1,
            {"response": response, "crystal": reloaded.crystal, "row": rr},
        ))

    # Effective-source regeneration drift guard.
    if SRC.exists():
        with tempfile.TemporaryDirectory(prefix="pass92_meta_") as td:
            out = Path(td) / "campaign_reset_meta.json"
            subprocess.run([sys.executable, str(ROOT / "tools/build_campaign_reset_meta.py"), str(SRC), "--output", str(out)], check=True, stdout=subprocess.DEVNULL)
            checks.append(check(
                "effective_src64_regenerates_reset_metadata_byte_exact",
                out.read_bytes() == (DATA / "campaign_reset_meta.json").read_bytes(),
            ))

    report = {
        "pass": "92.0",
        "status": "PASS",
        "mid": 116,
        "checks": checks,
        "scope": "Super Campaign paid resets only; MID117/118 and Monthly Privilege lifecycle remain deferred",
    }
    out = ROOT / "docs/PASS92_MID116_SELFTEST.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
