#!/usr/bin/env python3
"""Pass168 H3 generated Horcrux reward bridge + MID241 regression gate."""
from __future__ import annotations

import copy
import hashlib
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.content.gift_opening_source_catalog import GiftOpeningSourceCatalog
from gxb_backend.content.horcrux_source_catalog import HorcruxSourceCatalog
from gxb_backend.state.horcrux_materializer import (
    HorcruxGeneratedRewardOwner,
    HorcruxGiftRewardAdapter,
    HorcruxMaterializer,
    HorcruxRandomOutcomeAdapter,
)
from gxb_backend.state.horcrux_policy import HorcruxPolicyRegistry
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.random_outcome_service import EntropyDrawRequest, RandomOutcomeService
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.reward_transaction_service import (
    InventoryGrant,
    RewardOrigin,
    RewardPlan,
    RewardValidationError,
    SpecializedGrant,
)

GAME = GameDataCatalog.load(DATA / "game_data_catalog.json")
GIFTS = GiftOpeningSourceCatalog(DATA)
HORCRUX = HorcruxSourceCatalog(DATA, game_data=GAME)
POLICY = HorcruxPolicyRegistry(DATA)


def req(value: bool, message: str) -> None:
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


def make_services(seed: dict[int, int], values=(), *, pid="168001", spirits=None):
    player = apply_established_profile(PlayerState())
    player.player_id = player.account_uid = pid
    player.player_name = "Pass168 H3"
    player.backpack_items = [
        {"table_id": item_id, "item_num": amount, "time": 0}
        for item_id, amount in sorted(seed.items()) if amount > 0
    ]
    if spirits is not None:
        player.spirit_list = copy.deepcopy(spirits)
        player.horcrux_state = {}
    commits: list[int] = []
    entropy = ScriptedEntropy(values)
    services = RequestServices(
        player, DATA, lambda: commits.append(1), catalog=GAME, entropy_provider=entropy
    )
    services.heroes.normalize()
    services.horcrux_repository.normalize()
    return player, services, commits, entropy


def test_source_generated_operation_and_overlay_boundary() -> None:
    generated = [
        op for op in GIFTS.operations()
        if op.capability in HorcruxGiftRewardAdapter.SUPPORTED_CAPABILITIES
    ]
    req(len(generated) == 20, f"generated MID241 operation count drift: {len(generated)}")
    req(sum(op.status == "DETERMINISTIC" for op in generated) == 7, "generated deterministic operation count drift")
    req(sum(op.status == "RANDOM" for op in generated) == 13, "generated random operation count drift")
    bad = GIFTS.operation(50009446, 99990840)
    req(bad is not None and bad.capability == "HUNQI_WITH_MISSING_ITEM_DEFS", "9199043 source operation drift")
    raw_ids = [c.item_id for c in bad.drop_occurrences[0].candidates]
    req(any(x in raw_ids for x in (250000768, 250000769, 250000967, 250000968, 250000969)), "raw malformed 9199043 evidence was silently rewritten")
    overlay = POLICY.anomaly_overlay("dropbox_9199043")
    req(overlay is not None, "9199043 compatibility overlay missing")
    ids = [int(x) for x in overlay["effective_candidates"]]
    weights = [int(x) for x in overlay["effective_weights"]]
    req(len(ids) == len(weights) == 12 and sum(weights) == 1000, "9199043 overlay cardinality/weight drift")
    req(weights[:4] == [84] * 4 and weights[4:] == [83] * 8, "9199043 overlay weight mapping drift")
    req(not set(ids).intersection({250000768, 250000769, 250000967, 250000968, 250000969}), "9199043 malformed IDs leaked into effective overlay")
    req(all(HORCRUX.template(x) is not None for x in ids), "9199043 overlay contains unknown Horcrux template")



def test_all_20_generated_operations_plan_and_validate() -> None:
    _player, services, _commits, entropy = make_services({}, values=[0] * 64, pid="168009")
    count = 0
    random_count = 0
    for operation in GIFTS.operations():
        if operation.capability not in HorcruxGiftRewardAdapter.SUPPORTED_CAPABILITIES:
            continue
        resolved = services.gift_opening_planner.resolve(operation.item_id, operation.gift_id, 1)
        services.rewards.validate(services.gift_opening_planner.preflight_rewards(resolved))
        plan = services.gift_opening_planner.plan_resolved(resolved)
        services.rewards.validate(plan.rewards)
        req(plan.wire_awards == () and len(plan.rewards.specialized) >= 1, f"generated plan shape drift {operation.item_id}/{operation.gift_id}")
        count += 1
        random_count += operation.status == "RANDOM"
    req(count == 20 and random_count == 13, f"generated exhaustive planning count drift {count}/{random_count}")
    req(len(entropy.requests) == 13 and all(r.namespace == "gift.open" for r in entropy.requests), f"generated planner consumed wrong pre-settlement entropy: {entropy.requests}")

def test_materializer_exact_draw_topology_and_alignment() -> None:
    # table 250000161 -> model31: 2 main candidates and 0..4 sub count weights.
    # Script: main index1; sub-count roll50 => count2; selector local3 then local0.
    entropy = ScriptedEntropy([1, 50, 3, 0])
    ros = RandomOutcomeService(entropy)
    mat = HorcruxMaterializer(HORCRUX, POLICY, HorcruxRandomOutcomeAdapter(ros))
    row = mat.materialize(250000161)
    req([r.namespace for r in entropy.requests] == [
        "horcrux.generate.main",
        "horcrux.generate.sub_count",
        "horcrux.generate.sub_selector",
        "horcrux.generate.sub_selector",
    ], f"generation draw order drift: {entropy.requests}")
    req([r.upper_exclusive for r in entropy.requests] == [2, 100, 12, 11], "generation draw bounds drift")
    req(row["main"] == 2 and row["main_attr"] == 6 and row["main_attr_value"] == 80, f"main alignment drift: {row}")
    req(row["sub"] == [4, 1], f"1-based distinct sub selectors drift: {row['sub']}")
    req(row["sub_attr"] == [7, 4], f"sub attr alignment drift: {row['sub_attr']}")
    req(row["sub_attr_value"] == [3, 312], f"sub value alignment drift: {row['sub_attr_value']}")
    req(row["lev"] == row["exp"] == row["is_equip"] == row["is_lock"] == row["collo_count"] == 0, "fresh-instance defaults drift")

    # Source single-main model consumes no main entropy; sub-count remains first draw.
    entropy2 = ScriptedEntropy([0])  # roll0 => zero secondary stats, so no selector draw.
    mat2 = HorcruxMaterializer(HORCRUX, POLICY, HorcruxRandomOutcomeAdapter(RandomOutcomeService(entropy2)))
    row2 = mat2.materialize(250000115)
    req([r.namespace for r in entropy2.requests] == ["horcrux.generate.sub_count"], f"single-main forced draw consumed entropy: {entropy2.requests}")
    req(row2["main"] == 1 and row2["sub"] == [], "single-main/zero-sub materialization drift")


def test_victory_vow_num_two_atomic_spirit_awards() -> None:
    # Per instance: main roll0, subcount roll0 => no sub selectors.
    player, services, commits, entropy = make_services({50002146: 2}, values=[0, 0, 0, 0], pid="168010")
    out = services.gift_opening.open({"item_id": 50002146, "gift_id": 90040415, "num": 2})
    req(out.get("awards") == [], f"Victory Vow emitted fake ordinary award: {out}")
    spirits = out.get("spirit_awards")
    req(isinstance(spirits, list) and len(spirits) == 2, f"Victory Vow spirit_awards drift: {out}")
    req([r["table_id"] for r in spirits] == [250000161, 250000161], "Victory Vow selected-template drift")
    req([r["spirit_id"] for r in spirits] == [1, 2], "Victory Vow allocator drift")
    req([r.namespace for r in entropy.requests] == [
        "horcrux.generate.main", "horcrux.generate.sub_count",
        "horcrux.generate.main", "horcrux.generate.sub_count",
    ], f"deterministic generated Gift escaped Horcrux draw topology: {entropy.requests}")
    req(not any(r.namespace == "gift.open" for r in entropy.requests), "deterministic Victory Vow consumed gift.open entropy")
    req(services.inventory.quantity(50002146) == 0 and len(player.spirit_list) == 2, "Victory Vow settlement state drift")
    req(player.horcrux_state["next_spirit_id"] == 3 and commits == [1], "Victory Vow did not commit once atomically")


def test_random_gift_selects_template_before_horcrux_generation() -> None:
    # 50002145 pool700028: gift roll0 chooses first source candidate. Then
    # materializer main0 + subcount0.  Global request order proves Gift owns
    # template selection and Horcrux owns only generated instance randomness.
    player, services, commits, entropy = make_services({50002145: 1}, values=[0, 0, 0], pid="168011")
    out = services.gift_opening.open({"item_id": 50002145, "gift_id": 90040414, "num": 1})
    req([r.namespace for r in entropy.requests] == [
        "gift.open", "horcrux.generate.main", "horcrux.generate.sub_count"
    ], f"Gift/Horcrux RNG ownership order drift: {entropy.requests}")
    req(len(out.get("spirit_awards", [])) == 1 and out["awards"] == [], f"random Horcrux wire drift: {out}")
    req(out["spirit_awards"][0]["table_id"] == 250000161, "pool700028 source-order selection drift")
    req(commits == [1] and services.inventory.quantity(50002145) == 0 and len(player.spirit_list) == 1, "random Horcrux Gift settlement drift")


def test_9199043_runtime_uses_overlay_not_corrupt_rows() -> None:
    # roll0 selects first effective overlay row (84 weight), then generated main
    # and subcount draws are zeros.
    _player, services, commits, entropy = make_services({50009446: 1}, values=[0, 0, 0], pid="168012")
    out = services.gift_opening.open({"item_id": 50009446, "gift_id": 99990840, "num": 1})
    req(out.get("spirit_awards", [{}])[0].get("table_id") == 250000264, f"9199043 overlay first candidate drift: {out}")
    req(entropy.requests[0].namespace == "gift.open" and entropy.requests[0].upper_exclusive == 1000, "9199043 overlay weights not used by Gift domain")
    req(commits == [1], "9199043 overlay settlement did not commit once")


def test_specialized_owner_preflight_and_rollback() -> None:
    _p, services, _commits, _entropy = make_services({}, pid="168013")
    unknown = RewardPlan(
        origin=RewardOrigin(domain="test", operation="unknown"),
        specialized=(SpecializedGrant("UNKNOWN", ContentRef(CatalogNamespace.ITEM, 250000161), 1),),
    )
    try:
        services.rewards.validate(unknown)
    except RewardValidationError:
        pass
    else:
        raise AssertionError("unregistered specialized owner did not fail closed")

    # Once H3 has a unique-instance owner, type24 must never fall back into
    # generic StackInventory settlement through RewardTransactionService.
    ordinary_horcrux = RewardPlan(
        origin=RewardOrigin(domain="test", operation="wrong_owner"),
        inventory=(InventoryGrant(ContentRef(CatalogNamespace.ITEM, 250000161), 1),),
    )
    try:
        services.rewards.validate(ordinary_horcrux)
    except RewardValidationError:
        pass
    else:
        raise AssertionError("type24 Horcrux was accepted as ordinary InventoryGrant")

    player, services, commits, entropy = make_services({50002146: 2}, values=[0, 0, 0, 0], pid="168014")
    before = copy.deepcopy(vars(player))
    original = services.horcrux_repository.add_instance
    calls = {"n": 0}
    def fail_second(instance):
        calls["n"] += 1
        if calls["n"] == 2:
            raise ValueError("simulated generated-owner failure")
        return original(instance)
    services.horcrux_repository.add_instance = fail_second  # type: ignore[method-assign]
    try:
        out = services.gift_opening.open({"item_id": 50002146, "gift_id": 90040415, "num": 2})
    finally:
        services.horcrux_repository.add_instance = original  # type: ignore[method-assign]
    req(out.get("error_code") == 1, f"generated settlement failure did not fail closed: {out}")
    req(vars(player) == before and commits == [], "generated owner failure leaked gift/instance/cursor mutation")
    req(len(entropy.requests) == 4, "rollback incorrectly rewound ephemeral entropy mechanics")


def test_soft_2000_cap_does_not_truncate_mid241() -> None:
    existing = [
        {"spirit_id": i, "table_id": 250000161, "is_equip": 0, "is_lock": 0, "collo_count": 0}
        for i in range(1, 2000)
    ]
    player, services, commits, _entropy = make_services({50002146: 2}, values=[0, 0, 0, 0], pid="168015", spirits=existing)
    req(services.horcrux_repository.owned_count() == 1999, "soft-cap fixture drift")
    out = services.gift_opening.open({"item_id": 50002146, "gift_id": 90040415, "num": 2})
    req(len(out.get("spirit_awards", [])) == 2, "MID241 truncated generated rewards at Trial soft cap")
    req(services.horcrux_repository.owned_count() == 2001, "MID241 did not atomically cross 2000")
    req([r["spirit_id"] for r in out["spirit_awards"]] == [2000, 2001], "allocator repair/cross-cap IDs drift")
    req(commits == [1], "cross-cap MID241 did not commit once")


def test_hota001_source_delta_and_architecture_parity() -> None:
    original = ROOT / "source_evidence/src_64/app/windows/SelectEquipWindow.lua"
    p32 = ROOT / "local_assets/src_32/app/windows/SelectEquipWindow.lua"
    p64 = ROOT / "local_assets/src_64/app/windows/SelectEquipWindow.lua"
    req(original.exists() and p32.exists() and p64.exists(), "HOTA-001 evidence/override files missing")
    raw = original.read_text(encoding="utf-8-sig")
    v32 = p32.read_text(encoding="utf-8-sig")
    v64 = p64.read_text(encoding="utf-8-sig")
    req(v32 == v64, "HOTA-001 src32/src64 patches diverged")
    old = "arg_4_0.selfPlayer:handleRewards(arg_7_1.awards)"
    new = "arg_4_0.selfPlayer:handleRewards(arg_7_1.awards, nil, arg_7_1.spirit_awards)"
    req(raw.count(old) == 1 and new not in raw, "HOTA-001 original-source evidence drift")
    req(v64.count(new) == 1 and old not in v64, "HOTA-001 patch point drift")
    # Normalize just the one accepted call-site delta; everything else must be source-identical.
    req(v64.replace(new, old) == raw, "HOTA-001 changed more than the bounded reward forwarding call")
    req(hashlib.sha256(original.read_bytes()).hexdigest() == "1a9163609cc32f3bdb1d5241c14860521c141146588d754b422b6d3234de0737", "SelectEquipWindow source hash drift")


def main() -> None:
    tests = [
        test_source_generated_operation_and_overlay_boundary,
        test_all_20_generated_operations_plan_and_validate,
        test_materializer_exact_draw_topology_and_alignment,
        test_victory_vow_num_two_atomic_spirit_awards,
        test_random_gift_selects_template_before_horcrux_generation,
        test_9199043_runtime_uses_overlay_not_corrupt_rows,
        test_specialized_owner_preflight_and_rollback,
        test_soft_2000_cap_does_not_truncate_mid241,
        test_hota001_source_delta_and_architecture_parity,
    ]
    for test in tests:
        test()
        print("PASS", test.__name__, flush=True)
    print(f"PASS Pass168 H3 Horcrux generated rewards ({len(tests)}/{len(tests)})", flush=True)


if __name__ == "__main__":
    main()
