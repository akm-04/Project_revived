#!/usr/bin/env python3
"""Pass140 Phase 3: MID241 ordinary random Gift Opening regression."""
from __future__ import annotations

import copy
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.gift_opening_source_catalog import (
    GiftOpeningDropCandidate,
    GiftOpeningDropOccurrence,
    GiftOpeningOperation,
    GiftOpeningSourceCatalog,
)
from gxb_backend.state.gift_opening_service import (
    GIFT_OPEN_RNG_NAMESPACE,
    GiftOpeningError,
    GiftOpeningPlanner,
    GiftRandomOutcomeAdapter,
)
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.random_outcome_service import EntropyDrawRequest, RandomOutcomeService
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.reward_transaction_service import RewardValidationError

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
SOURCE = GiftOpeningSourceCatalog(DATA)


def require(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


class ScriptedEntropy:
    def __init__(self, values=()) -> None:
        self.values = list(values)
        self.requests: list[EntropyDrawRequest] = []

    def draw(self, request: EntropyDrawRequest) -> int:
        self.requests.append(request)
        value = self.values.pop(0) if self.values else 0
        if value < 0 or value >= request.upper_exclusive:
            raise AssertionError(f"scripted entropy {value} invalid for {request}")
        return value


def make_services(seed: dict[int, int], values=()):
    player = apply_established_profile(PlayerState())
    player.account_uid = "14000001"
    player.player_id = "14000001"
    player.player_name = "Pass140 Gift Random"
    player.backpack_items = [
        {"table_id": item_id, "item_num": amount, "time": 0}
        for item_id, amount in sorted(seed.items()) if amount > 0
    ]
    commits: list[int] = []
    entropy = ScriptedEntropy(values)
    services = RequestServices(
        player, DATA, lambda: commits.append(1), catalog=CATALOG,
        entropy_provider=entropy,
    )
    return player, services, commits, entropy


def test_fresh_catalog_boundary_and_rebuild() -> None:
    require(SOURCE.count_capability(SOURCE.PHASE3_CAPABILITY) == 100, "Phase3 operation count drift")
    random_ops = [op for op in SOURCE.operations() if op.capability == SOURCE.PHASE3_CAPABILITY]
    require(len({op.item_id for op in random_ops}) == 100, "Phase3 source item count drift")
    require(sum(len(op.drop_occurrences) for op in random_ops) == 134, "Phase3 drop occurrence count drift")
    raw = os.environ.get("GXB_SRC64", "").strip()
    if raw:
        with tempfile.TemporaryDirectory(prefix="pass140_catalog_") as td:
            rebuilt = Path(td) / "gift_opening_source_catalog.json"
            subprocess.run([
                sys.executable, str(ROOT / "tools/build_gift_opening_source_catalog.py"),
                "--src64", raw, "--output", str(rebuilt),
            ], check=True, stdout=subprocess.DEVNULL)
            require(rebuilt.read_bytes() == (DATA / "gift_opening_source_catalog.json").read_bytes(), "Gift catalog stale versus effective src64")


def test_all_100_random_operations_plan_and_preflight() -> None:
    _player, services, _commits, entropy = make_services({})
    planned = 0
    expected_draws = 0
    for operation in SOURCE.operations():
        if operation.capability != SOURCE.PHASE3_CAPABILITY:
            continue
        resolved = services.gift_opening_planner.resolve(operation.item_id, operation.gift_id, 1)
        services.rewards.validate(services.gift_opening_planner.preflight_rewards(resolved))
        plan = services.gift_opening_planner.plan_resolved(resolved)
        services.rewards.validate(plan.rewards)
        planned += 1
        expected_draws += len(operation.drop_occurrences)
    require(planned == 100, f"planned random operation count drift: {planned}")
    require(expected_draws == 134, f"expected draw topology drift: {expected_draws}")
    require(len(entropy.requests) == expected_draws, f"actual draw topology drift: {len(entropy.requests)}")
    require(all(r.namespace == GIFT_OPEN_RNG_NAMESPACE for r in entropy.requests), "random gifts escaped gift.open namespace")


def test_arbitrary_weight_total_uses_relative_integer_weights() -> None:
    # Pool 680004 totals 100, proving there is no hard-coded /10000 denominator.
    player, services, commits, entropy = make_services({50001560: 1}, values=[99])
    out = services.gift_opening.open({"item_id": 50001560, "gift_id": 90067001, "num": 1})
    require(out == {"awards": [{"table_id": 190001017, "item_num": 1}]}, f"relative-weight selection drift: {out}")
    require(len(entropy.requests) == 1 and entropy.requests[0].upper_exclusive == 100, f"relative total was normalized incorrectly: {entropy.requests}")
    require(commits == [1] and services.inventory.quantity(50001560) == 0, "relative-weight gift did not settle atomically")


def test_zero_weight_candidates_cannot_win() -> None:
    # Special Magazine pool 600004 begins with a zero-weight candidate. Roll 0
    # must select the second source row (weight 7500), never the zero-weight row.
    _player, services, _commits, entropy = make_services({50001419: 1}, values=[0, 0, 0, 0, 0])
    out = services.gift_opening.open({"item_id": 50001419, "gift_id": 90060007, "num": 1})
    require(out == {"awards": [{"table_id": 50001421, "item_num": 5}]}, f"zero-weight candidate became selectable: {out}")
    require(len(entropy.requests) == 5, "five repeated Magazine occurrences did not consume five draws")


def test_repeated_pool_occurrences_and_num_batching_preserve_draws() -> None:
    operation = SOURCE.operation(50001418, 90060006)
    require(operation is not None, "Daily Magazine fixture missing")
    require([o.dropbox_id for o in operation.drop_occurrences] == [600003] * 5, "Daily Magazine repeated pool source order drift")
    _player, services, commits, entropy = make_services({50001418: 2}, values=[0] * 10)
    out = services.gift_opening.open({"item_id": 50001418, "gift_id": 90060006, "num": 2})
    require(out == {"awards": [{"table_id": 50001420, "item_num": 10}]}, f"Magazine num aggregation drift: {out}")
    require(len(entropy.requests) == 10, f"num=2 five-draw Magazine topology drift: {len(entropy.requests)}")
    require([r.ordinal for r in entropy.requests] == list(range(10)), "gift.open request ordinals drift")
    require(all(r.upper_exclusive == 10000 for r in entropy.requests), "Magazine source total drift")
    require(commits == [1] and services.inventory.quantity(50001418) == 0, "Magazine batch did not use one atomic UoW")


def test_invalid_or_insufficient_random_request_consumes_no_entropy() -> None:
    player, services, commits, entropy = make_services({50001418: 1})
    before = copy.deepcopy(vars(player))
    denied = services.gift_opening.open({"item_id": 50001418, "gift_id": 90060006, "num": 2})
    require(denied.get("error_code") == 1 and vars(player) == before, "insufficient random request mutated player")
    require(entropy.requests == [] and commits == [], "insufficient random request consumed entropy/commit")
    # Deferred deterministic equipment lane remains fail-closed and entropy-free.
    denied = services.gift_opening.open({"item_id": 50001190, "gift_id": 90050001, "num": 1})
    require(denied.get("error_code") == 1 and entropy.requests == [], "gift.equip crossed into Phase3 entropy")


def test_all_zero_pool_fails_before_draw() -> None:
    candidate = GiftOpeningDropCandidate(
        source_ordinal=0, row_id=1, item_id=50001420, item_num=1,
        drop_rate=0, roll_type=1, item_type=4,
    )
    operation = GiftOpeningOperation(
        item_id=999000001, gift_id=999000002, route="AUTO_FIRST_GIFT",
        supports_num=True, status="RANDOM", capability=SOURCE.PHASE3_CAPABILITY,
        raw_items=(), raw_item_nums=(), fixed_items=(), fixed_scalars=(), raw_equip="",
        drop_occurrences=(GiftOpeningDropOccurrence(ordinal=0, dropbox_id=999, missing_source=False, candidates=(candidate,)),),
    )
    class FakeSource:
        PHASE2_CAPABILITY = SOURCE.PHASE2_CAPABILITY
        PHASE3_CAPABILITY = SOURCE.PHASE3_CAPABILITY
        phase2_scalar_map = SOURCE.phase2_scalar_map
        def operation(self, item_id, gift_id):
            return operation if (int(item_id), int(gift_id)) == (operation.item_id, operation.gift_id) else None
    entropy = ScriptedEntropy()
    planner = GiftOpeningPlanner(FakeSource(), GiftRandomOutcomeAdapter(RandomOutcomeService(entropy)))
    try:
        planner.resolve(operation.item_id, operation.gift_id, 1)
    except GiftOpeningError:
        pass
    else:
        raise AssertionError("all-zero pool did not fail closed")
    require(entropy.requests == [], "all-zero pool consumed entropy")


def test_post_rng_settlement_failure_rolls_back_player_state() -> None:
    player, services, commits, entropy = make_services({50001560: 1}, values=[0])
    before = copy.deepcopy(vars(player))
    original_apply = services.gift_opening.rewards.apply
    def fail_after_rng(_plan):
        raise RewardValidationError("simulated post-RNG settlement failure")
    services.gift_opening.rewards.apply = fail_after_rng  # type: ignore[method-assign]
    try:
        out = services.gift_opening.open({"item_id": 50001560, "gift_id": 90067001, "num": 1})
    finally:
        services.gift_opening.rewards.apply = original_apply  # type: ignore[method-assign]
    require(out.get("error_code") == 1, f"post-RNG failure did not fail closed: {out}")
    require(vars(player) == before and commits == [], "post-RNG failure leaked mutation/commit")
    require(len(entropy.requests) == 1, "validated RNG draw topology unexpectedly rolled back")


def test_request_composition_identity_and_deterministic_zero_entropy() -> None:
    _player, services, _commits, entropy = make_services({50001172: 1})
    require(services.gift_random_outcomes._service is services.random_outcomes, "Gift adapter is not request ROS-backed")
    require(services.gift_random_outcomes.namespace == GIFT_OPEN_RNG_NAMESPACE, "Gift namespace drift")
    require(services.gift_opening_planner.random_outcomes is services.gift_random_outcomes, "planner random adapter identity drift")
    out = services.gift_opening.open({"item_id": 50001172, "gift_id": 90041001, "num": 1})
    require(out.get("error_code", 0) == 0 and entropy.requests == [], "deterministic MID241 consumed Phase3 entropy")


def main() -> None:
    tests = [
        test_fresh_catalog_boundary_and_rebuild,
        test_all_100_random_operations_plan_and_preflight,
        test_arbitrary_weight_total_uses_relative_integer_weights,
        test_zero_weight_candidates_cannot_win,
        test_repeated_pool_occurrences_and_num_batching_preserve_draws,
        test_invalid_or_insufficient_random_request_consumes_no_entropy,
        test_all_zero_pool_fails_before_draw,
        test_post_rng_settlement_failure_rolls_back_player_state,
        test_request_composition_identity_and_deterministic_zero_entropy,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    report = {
        "pass": "140.0", "phase": 3, "status": "STATIC_REGRESSION_ACCEPTED",
        "tests": len(tests), "ordinary_random_operations": 100,
        "ordinary_random_source_items": 100, "drop_occurrences": 134,
        "namespace": GIFT_OPEN_RNG_NAMESPACE,
        "weight_policy": "positive raw drop_rate as relative integer weights; zero cannot win",
        "batching_policy": "repeat operation num times; preserve ordered/repeated occurrences; aggregate first-seen awards",
        "generated_unique_gift_equip": "FAIL_CLOSED",
        "mid241_uuid_receipt_added": False,
    }
    (ROOT / "docs/PASS140_GIFT_OPENING_RANDOM_SELFTEST.json").write_text(json.dumps(report, indent=2) + "\n")
    print(f"PASS Pass140 Gift Opening Phase3 ({len(tests)} tests)")


if __name__ == "__main__":
    main()
