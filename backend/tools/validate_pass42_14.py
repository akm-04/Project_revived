#!/usr/bin/env python3
"""Pass42.14 Small x100 hotfix repository/static validation; no Flask/client gameplay."""
from __future__ import annotations

from collections import Counter
import json
from pathlib import Path
import subprocess

from gxb_backend.content.game_data_catalog import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.summon_private_policy import ClassicVendingPrivatePlanner

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


class ZeroRandom:
    def randbelow(self, upper: int) -> int:
        if int(upper) <= 0:
            raise ValueError("upper must be positive")
        return 0


def make_services(tag: str, mana: int = 3_000_000) -> RequestServices:
    player = apply_established_profile(PlayerState())
    player.account_uid = f"4214{tag}"
    player.player_id = f"4214{tag}"
    player.mana = int(mana)
    player.crystal = 999_999
    player.vip = 15
    return RequestServices(
        player,
        DATA,
        lambda: None,
        catalog=GameDataCatalog.load(DATA / "game_data_catalog.json"),
    )


def main() -> int:
    checks: dict[str, object] = {}

    operations = json.loads((DATA / "summon_operation_catalog.json").read_text())
    op100 = next(row for row in operations["operations"] if row["semantic"] == "small_paid_100")
    assert (op100["protocol_mid"], op100["summon_type"], op100["summon_index"]) == (50, 1, 4)
    assert op100["support_status"] == "private_policy_supported"
    assert op100["strategy"] == "classic_paid_private_policy"
    assert op100["pull_count"] == 100
    assert op100["cost_plan_id"] == "small_paid_hundred"
    assert op100["counter_policy_id"] == "small_classic"
    assert op100["rng_status"] == "private_server_policy_v1"
    checks["operation_topology"] = {
        "mid": 50,
        "summon_type": 1,
        "summon_index": 4,
        "pull_count": 100,
    }

    costs = json.loads((DATA / "summon_cost_policy.json").read_text())
    cost100 = next(row for row in costs["plans"] if row["id"] == "small_paid_hundred")
    assert cost100["pull_count"] == 100
    assert cost100["components"] == [{"kind": "economy", "field": "mana", "amount": 900000}]
    assert cost100["execution_status"] == "private_policy_active"
    checks["cost_plan"] = {"mana": 900000, "pull_count": 100, "status": "active"}

    private = json.loads((DATA / "summon_private_server_policy.json").read_text())
    assert "small_paid_100" in private["_meta"]["active_semantics"]
    assert "small_paid_100" not in private["_meta"]["deferred"]
    assert private["small"]["ten_pull_guarantee"]["mode"] == "at_least_one_item"

    result_policy = json.loads((DATA / "summon_result_policy.json").read_text())
    rp100 = next(row for row in result_policy["semantic_policies"] if row["semantic"] == "small_paid_100")
    assert rp100["activation_status"] == "private_policy_active"
    assert rp100["expected_rows"] == 100
    assert set(rp100["allowed_row_kinds"]) == {"hero", "item", "to_stone"}
    checks["result_policy"] = {"expected_rows": 100, "allowed": sorted(rp100["allowed_row_kinds"])}

    # Deterministically force ordinary Small selections toward the Hero/super pool.
    # Each 10-result block must still contain an item-class result after guarantee repair.
    guarantee_services = make_services("G")
    guarantee_services.summon_private_planner = ClassicVendingPrivatePlanner(
        guarantee_services.summon_pool_catalog,
        guarantee_services.summon_private_policy,
        random_source=ZeroRandom(),
        balance_planner=guarantee_services.classic_vending_balance_planner,
    )
    guarantee_services.summon.private_planner = guarantee_services.summon_private_planner
    desc100 = guarantee_services.summon_operation_catalog.require(
        type(guarantee_services.summon_operation_catalog.keys()[0])(50, 1, 4)
    )
    counter = guarantee_services.summon_counter_policies.require("small_classic")
    guarantee_services.player.summon[counter.persistence_key] = 0
    selections, counter_after = guarantee_services.summon._classic_select_results(desc100)
    assert len(selections) == 100 and counter_after == 100
    block_item_counts = []
    for start in range(0, 100, 10):
        count = sum(1 for pool, _, _ in selections[start:start + 10] if pool.result_kind == "item")
        assert count >= 1, (start, count)
        block_item_counts.append(count)
    checks["x100_ten_block_guarantee"] = block_item_counts

    # End-to-end request-scoped repository execution: atomic cost, 100 wire rows,
    # counter progression, and short-window replay with no second charge.
    services = make_services("R")
    player = services.player
    repo = services.summon
    repo.normalize()
    counter = services.summon_counter_policies.require("small_classic")
    before_mana = player.mana
    before_counter = int(player.summon.get(counter.persistence_key, 0) or 0)
    response = repo.summon_hero({"summon_type": 1, "summon_index": 4})
    assert response.get("error_code", 0) == 0
    assert len(response.get("result") or []) == 100
    assert player.mana == before_mana - 900000
    assert int(player.summon.get(counter.persistence_key, 0) or 0) == before_counter + 100
    assert response.get("economy_", {}).get("mana") == player.mana
    assert isinstance(response.get("summon_info"), dict)
    kind_counts = Counter(
        "hero" if row.get("is_partner") else ("to_stone" if row.get("to_stone") else "item")
        for row in response["result"]
    )
    after_mana = player.mana
    after_counter = int(player.summon[counter.persistence_key])
    replay = repo.summon_hero({"summon_type": 1, "summon_index": 4})
    assert replay == response
    assert player.mana == after_mana
    assert int(player.summon[counter.persistence_key]) == after_counter
    checks["repository_x100"] = {
        "rows": 100,
        "mana_debit": 900000,
        "counter_delta": 100,
        "wire_kind_counts_sample_run": dict(kind_counts),
        "immediate_retry_replayed_without_second_debit": True,
    }

    # Existing Small buttons retain their established costs/counts.
    for tag, index, expected_rows, expected_cost in (("1", 2, 1, 10000), ("10", 3, 10, 90000)):
        svc = make_services(tag)
        before = svc.player.mana
        out = svc.summon.summon_hero({"summon_type": 1, "summon_index": index})
        assert out.get("error_code", 0) == 0
        assert len(out.get("result") or []) == expected_rows
        assert svc.player.mana == before - expected_cost
    checks["small_regression"] = {"x1": "1 row / 10000 Mana", "x10": "10 rows / 90000 Mana"}

    proc = subprocess.run(
        ["python3", str(ROOT / "gacha_control.py"), "--check"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=True,
    )
    assert "PASS" in proc.stdout
    checks["gacha_control_sync"] = proc.stdout.strip()

    report = {
        "schema_version": 1,
        "pass": "42.14",
        "backend": "v0.8.34",
        "validation_type": "repository/static hotfix validation; no Flask/client gameplay",
        "status": "pass",
        "checks": checks,
        "runtime_boundary": "Fresh debug.zip proves the v0.8.33 x100 request and rejection. v0.8.34 x100 success remains repository-confirmed until a new client smoke is supplied.",
    }
    out = ROOT / "docs" / "PASS42_14_BACKEND_STATIC_VALIDATION.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
