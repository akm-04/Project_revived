#!/usr/bin/env python3
"""Pass138 Phase 2: MID241 deterministic Gift Opening foundation regression."""
from __future__ import annotations

import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import types

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.gift_opening_source_catalog import GiftOpeningSourceCatalog
from gxb_backend.protocol.mids import MID
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.random_outcome_service import EntropyDrawRequest
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.response_projector import ResponseProjector
from gxb_backend.state.reward_transaction_service import RewardValidationError

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
SOURCE = GiftOpeningSourceCatalog(DATA)


def require(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


class RecordingZeroEntropy:
    def __init__(self) -> None:
        self.requests: list[EntropyDrawRequest] = []

    def draw(self, request: EntropyDrawRequest) -> int:
        self.requests.append(request)
        return 0


def make_services(seed: dict[int, int], *, crystal: int = 1000, mana: int = 1000):
    player = apply_established_profile(PlayerState())
    player.account_uid = "13800001"
    player.player_id = "13800001"
    player.player_name = "Pass138 Gift Opening"
    player.crystal = crystal
    player.mana = mana
    player.backpack_items = [
        {"table_id": item_id, "item_num": amount, "time": 0}
        for item_id, amount in sorted(seed.items())
        if amount > 0
    ]
    commits: list[int] = []
    entropy = RecordingZeroEntropy()
    services = RequestServices(
        player,
        DATA,
        lambda: commits.append(1),
        catalog=CATALOG,
        entropy_provider=entropy,
    )
    return player, services, commits, entropy


def test_generated_catalog_counts_and_supersession() -> None:
    summary = SOURCE.summary
    require(summary["effective_operation_count_including_missing_gift_source"] == 2736, "effective operation count drift")
    require(summary["status_counts"] == {"DETERMINISTIC": 2175, "MISSING_GIFT": 368, "RANDOM": 193}, "status census drift")
    require(summary["phase2_deterministic_ordinary_operation_count"] == 1431, "corrected Phase2 operation count drift")
    require(summary["phase2_deterministic_ordinary_source_item_count"] == 382, "corrected Phase2 item count drift")
    require(summary["phase3_ordinary_random_operation_count"] == 100, "Phase3 ordinary random count drift")
    supersession = summary["pass136_supersession"]
    require(supersession["previous_phase2_ordinary_operation_count"] == 1637, "Pass136 baseline missing")
    require(supersession["unmodeled_raw_gift_equip_operations"] == 199, "gift.equip correction drift")
    require(supersession["deterministic_generated_hunqi_operations"] == 7, "deterministic HUNQI correction drift")


def test_source_catalog_rebuild_is_byte_identical_when_src64_available() -> None:
    raw = os.environ.get("GXB_SRC64", "").strip()
    if not raw:
        print("SKIP test_source_catalog_rebuild_is_byte_identical_when_src64_available (GXB_SRC64 unset)")
        return
    src64 = Path(raw)
    require(src64.is_dir(), f"GXB_SRC64 does not exist: {src64}")
    with tempfile.TemporaryDirectory(prefix="pass138_catalog_") as td:
        rebuilt = Path(td) / "gift_opening_source_catalog.json"
        subprocess.run([
            sys.executable,
            str(ROOT / "tools/build_gift_opening_source_catalog.py"),
            "--src64", str(src64),
            "--output", str(rebuilt),
        ], check=True, stdout=subprocess.DEVNULL)
        require(rebuilt.read_bytes() == (DATA / "gift_opening_source_catalog.json").read_bytes(), "generated Gift Opening catalog is stale versus effective src64")


def test_exact_pair_and_route_facts() -> None:
    auto = SOURCE.operation(50001059, 90001219)
    select = SOURCE.operation(50001172, 90041001)
    sx = SOURCE.operation(50001335, 90001677)
    require(auto is not None and auto.route == "AUTO_FIRST_GIFT" and auto.supports_num, "auto-first route drift")
    require(select is not None and select.route == "SELECT_EQUIP" and select.supports_num, "select-equip route drift")
    require(sx is not None and sx.route == "SPECIAL_SX_SELECT" and not sx.supports_num, "SX route drift")
    require(SOURCE.operation(50001172, 90001219) is None, "catalog accepts non-effective cross-item gift pair")


def test_all_1431_phase2_operations_plan_and_validate_without_entropy() -> None:
    _player, services, _commits, entropy = make_services({})
    accepted = 0
    rejected = 0
    for operation in SOURCE.operations():
        if operation.capability == SOURCE.PHASE2_CAPABILITY:
            plan = services.gift_opening_planner.plan(operation.item_id, operation.gift_id, 1)
            services.rewards.validate(plan.rewards)
            require((plan.operation.item_id, plan.operation.gift_id) == (operation.item_id, operation.gift_id), "planner exact operation pair drift")
            accepted += 1
        elif operation.capability == SOURCE.PHASE3_CAPABILITY:
            # Pass140 activates this lane; Phase138 regression only proves the
            # deterministic foundation still plans without entropy.
            continue
        else:
            try:
                services.gift_opening_planner.plan(operation.item_id, operation.gift_id, 1)
            except Exception:
                rejected += 1
            else:
                raise AssertionError(f"unsupported capability planned: {operation.item_id}/{operation.gift_id}/{operation.capability}")
    require(accepted == 1431, f"exhaustive Phase2 accepted count drift: {accepted}")
    require(rejected == 2736 - 1431 - 100, f"exhaustive non-Phase2/3 rejection count drift: {rejected}")
    require(entropy.requests == [], "exhaustive deterministic planning consumed entropy")


def test_select_equip_batch_is_atomic_and_wire_shaped() -> None:
    player, services, commits, entropy = make_services({50001172: 2})
    before_version = services.uow.current_state_version
    out = services.gift_opening.open({"item_id": 50001172, "gift_id": 90041001, "num": 2})
    require(out == {"awards": [{"table_id": 20001154, "item_num": 2}]}, f"MID241 award wire drift: {out}")
    require(services.inventory.quantity(50001172) == 0, "source package not debited exactly twice")
    require(services.inventory.quantity(20001154) == 2, "selected reward not credited twice")
    require(services.uow.current_state_version == before_version + 1, "MID241 batch did not commit exactly one UoW state version")
    require(len(commits) == 1, "MID241 batch durable commit count drift")
    require(entropy.requests == [], "deterministic MID241 consumed gameplay entropy")


def test_auto_first_fixed_multi_item_reward() -> None:
    _player, services, _commits, entropy = make_services({50001059: 1})
    op = SOURCE.operation(50001059, 90001219)
    require(op is not None and len(op.fixed_items) == 12, "source multi-item gift fixture drift")
    out = services.gift_opening.open({"item_id": 50001059, "gift_id": 90001219, "num": 1})
    require(out.get("error_code", 0) == 0 and len(out.get("awards") or []) == 12, f"multi-item deterministic open failed: {out}")
    require(services.inventory.quantity(50001059) == 0, "multi-item source not consumed")
    require(entropy.requests == [], "multi-item deterministic gift consumed entropy")


def test_special_sx_selected_ordinary_is_deterministic_single_only() -> None:
    _player, services, commits, entropy = make_services({50001335: 2})
    out = services.gift_opening.open({"item_id": 50001335, "gift_id": 90001677, "num": 1})
    require(out == {"awards": [{"table_id": 50001146, "item_num": 1}]}, f"SX ordinary selection failed: {out}")
    before = copy.deepcopy(services.player.backpack_items)
    version = services.uow.current_state_version
    denied = services.gift_opening.open({"item_id": 50001335, "gift_id": 90001677, "num": 2})
    require(denied.get("error_code") == 1 and services.player.backpack_items == before, "SX route accepted unsupported batch")
    require(services.uow.current_state_version == version and len(commits) == 1, "denied SX batch mutated state")
    require(entropy.requests == [], "SX deterministic selection consumed entropy")


def test_scalar_reward_projects_cumulative_economy() -> None:
    player, services, _commits, entropy = make_services({50001903: 1}, crystal=1000)
    projector = ResponseProjector.capture(player, resource_registry=services.resource_registry)
    out = services.gift_opening.open({"item_id": 50001903, "gift_id": 91199143})
    projected = projector.project(out, player, committed_journal=services.uow.consume_journal(), profile=None)
    require(out == {"awards": []}, f"scalar-only gift wire must retain empty awards list: {out}")
    require(player.crystal == 1500, "scalar gift did not credit canonical EconomyLedger")
    require(projected.get("economy_", {}).get("crystal") == 1500, f"scalar gift did not project cumulative economy_: {projected}")
    require(entropy.requests == [], "scalar deterministic gift consumed entropy")


def test_unsupported_lanes_fail_before_mutation_or_entropy() -> None:
    cases = [
        (50001052, 90001088, "hero_entity"),
        (50001190, 90050001, "raw_gift_equip"),
        (50002146, 90040415, "generated_hunqi_missing_quantity"),
        (50002142, 90040410, "spirit_energy_temporal"),
        (50002184, 90040464, "missing_gift_source"),
    ]
    for item_id, gift_id, label in cases:
        player, services, commits, entropy = make_services({item_id: 2})
        before = copy.deepcopy(vars(player))
        out = services.gift_opening.open({"item_id": item_id, "gift_id": gift_id, "num": 1})
        require(out.get("error_code") == 1, f"{label} did not fail closed: {out}")
        require(vars(player) == before, f"{label} mutated player before capability rejection")
        require(commits == [], f"{label} committed despite fail-closed gate")
        require(entropy.requests == [], f"{label} consumed entropy in Phase2")


def test_wrong_pair_invalid_num_and_insufficient_are_mutation_free() -> None:
    player, services, commits, entropy = make_services({50001172: 1})
    before = copy.deepcopy(vars(player))
    requests = [
        {"item_id": 50001172, "gift_id": 90001219, "num": 1},
        {"item_id": 50001172, "gift_id": 90041001, "num": 0},
        {"item_id": 50001172, "gift_id": 90041001, "num": True},
        {"item_id": 50001172, "gift_id": 90041001, "num": 2},
    ]
    for req in requests:
        out = services.gift_opening.open(req)
        require(out.get("error_code") == 1, f"invalid MID241 request accepted: {req} -> {out}")
        require(vars(player) == before, f"invalid MID241 request mutated state: {req}")
    require(commits == [] and entropy.requests == [], "invalid requests committed or consumed entropy")


def test_post_debit_reward_failure_rolls_back_whole_uow() -> None:
    player, services, commits, entropy = make_services({50001172: 1})
    before = copy.deepcopy(vars(player))
    original_apply = services.gift_opening.rewards.apply

    def fail_after_debit(_plan):
        raise RewardValidationError("simulated post-debit reward failure")

    services.gift_opening.rewards.apply = fail_after_debit  # type: ignore[method-assign]
    try:
        out = services.gift_opening.open({"item_id": 50001172, "gift_id": 90041001, "num": 1})
    finally:
        services.gift_opening.rewards.apply = original_apply  # type: ignore[method-assign]
    require(out.get("error_code") == 1, f"simulated settlement failure did not fail closed: {out}")
    require(vars(player) == before, "source debit survived post-debit reward failure")
    require(commits == [] and entropy.requests == [], "rolled-back gift committed or consumed entropy")


def test_dispatcher_binds_mid241_to_inventory_gift_handler() -> None:
    fake_flask = types.ModuleType("flask")
    fake_flask.Request = object
    fake_flask.jsonify = lambda data=None, **_kwargs: data
    fake_flask.make_response = lambda data=None, status=200, **_kwargs: data
    fake_flask.send_file = lambda *args, **kwargs: None
    sys.modules.setdefault("flask", fake_flask)
    from gxb_backend.config import Settings
    from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
    from gxb_backend.state.repository import StateRepository

    with tempfile.TemporaryDirectory(prefix="pass138_dispatch_") as td:
        root = Path(td)
        state = StateRepository(
            DATA / "player_db.json",
            profile="established",
            legacy_path=ROOT / "state/gxb_state.json",
            multiuser_root=root / "server_state",
        )
        dispatcher = EngineDispatcher(
            state,
            Settings(multiuser_root=root / "server_state", runtime_log_dir=root / "runtime_logs"),
        )
        handler = dispatcher.handlers.get(MID.EXCHAGE_CODE_HERO)
        require(handler is not None, "MID241 is not bound")
        require(getattr(handler, "__self__", None) is dispatcher.inventory, "MID241 bound outside InventoryHandlers")
        require(getattr(handler, "__name__", "") == "open_gift", "MID241 bound to wrong InventoryHandlers method")


def test_phase2_deterministic_path_remains_entropy_free_under_phase3_composition() -> None:
    _player, services, _commits, entropy = make_services({50001172: 1})
    planner = services.gift_opening_planner
    attrs = vars(planner)
    require(set(attrs) == {"source", "random_outcomes"}, f"Gift planner composition drift: {sorted(attrs)}")
    out = services.gift_opening.open({"item_id": 50001172, "gift_id": 90041001, "num": 1})
    require(out == {"awards": [{"table_id": 20001154, "item_num": 1}]}, f"Phase2 deterministic regression drift: {out}")
    require(entropy.requests == [], "Phase2 deterministic path consumed entropy after Phase3 composition")
    require(services.gift_opening.source is services.gift_opening_source, "GiftOpeningService source identity drift")
    require(services.gift_opening.planner is planner, "GiftOpeningService planner identity drift")
    require(services.gift_opening.stacks is services.stack_inventory, "GiftOpeningService created parallel stack owner")
    require(services.gift_opening.rewards is services.rewards, "GiftOpeningService created parallel reward owner")
    require(services.gift_opening.uow is services.uow, "GiftOpeningService created parallel UoW")


def main() -> None:
    tests = [
        test_generated_catalog_counts_and_supersession,
        test_source_catalog_rebuild_is_byte_identical_when_src64_available,
        test_exact_pair_and_route_facts,
        test_all_1431_phase2_operations_plan_and_validate_without_entropy,
        test_select_equip_batch_is_atomic_and_wire_shaped,
        test_auto_first_fixed_multi_item_reward,
        test_special_sx_selected_ordinary_is_deterministic_single_only,
        test_scalar_reward_projects_cumulative_economy,
        test_unsupported_lanes_fail_before_mutation_or_entropy,
        test_wrong_pair_invalid_num_and_insufficient_are_mutation_free,
        test_post_debit_reward_failure_rolls_back_whole_uow,
        test_dispatcher_binds_mid241_to_inventory_gift_handler,
        test_phase2_deterministic_path_remains_entropy_free_under_phase3_composition,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    report = {
        "pass": "138.0",
        "phase": 2,
        "status": "STATIC_REGRESSION_ACCEPTED",
        "tests": len(tests),
        "phase2_active_operations": 1431,
        "phase2_active_source_items": 382,
        "pass136_superseded_counts": {"operations": 1637, "source_items": 583},
        "source_corrections": {"raw_gift_equip": 199, "deterministic_generated_hunqi": 7},
        "entropy_draws_for_deterministic_and_rejected_phase2_operations": 0,
        "mid241_uuid_receipt_added": False,
    }
    (ROOT / "docs/PASS138_GIFT_OPENING_SELFTEST.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    print(f"PASS Pass138 Gift Opening Phase2 foundation ({len(tests)} tests)")


if __name__ == "__main__":
    main()
