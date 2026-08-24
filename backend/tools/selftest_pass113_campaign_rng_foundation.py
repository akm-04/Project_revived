from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.campaign_drop_source_catalog import (
    CampaignDropSourceCatalog,
    CampaignDropSourceRow,
)
from gxb_backend.content.game_data_catalog import CatalogNamespace, ContentRef
from gxb_backend.state.campaign_drop_planner import (
    CAMPAIGN_REPEAT_NAMESPACE,
    CAMPAIGN_REPEAT_POLICY_ID,
    CAMPAIGN_REPEAT_POLICY_VERSION,
    CAMPAIGN_REPEAT_RATE_BASE,
    CAMPAIGN_REPEAT_STRATEGY,
    CampaignDropPlanner,
    CampaignDropPolicy,
    CampaignDropPolicyRegistry,
    CampaignRepeatPolicyRegistry,
    CampaignDropSourceCorruptionError,
    CampaignRandomOutcomeAdapter,
    CampaignRepeatPoolUnavailableError,
)
from gxb_backend.state.mid117_operation_receipt import (
    Mid117OperationIdentity,
    Mid117OperationIdentityError,
    build_mid117_replay_payload,
    mid117_request_fingerprint,
    validate_mid117_replay_payload,
)
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.random_outcome_service import RandomOutcomeService
from gxb_backend.testing.scripted_entropy import ScriptedEntropyDraw, ScriptedEntropyProvider

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
SOURCE_CATALOG_SHA256 = hashlib.sha256((DATA / "campaign_drop_source_catalog.json").read_bytes()).hexdigest()
PASS111_WORLD_SHA256 = "e434550cb6db77c17b50b17b25dc2886262a742c1d1628700cce6f4f27920752"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_raises(exc_type, fn, contains: str | None = None):
    try:
        fn()
    except exc_type as exc:
        if contains is not None:
            require(contains in str(exc), f"exception did not contain {contains!r}: {exc}")
        return exc
    except Exception as exc:
        raise AssertionError(f"expected {exc_type.__name__}, got {type(exc).__name__}: {exc}") from exc
    raise AssertionError(f"expected {exc_type.__name__}")


def source_row(row_id: int, item_id: int, rate: int, ordinal: int, pool_id: int = 777) -> CampaignDropSourceRow:
    return CampaignDropSourceRow(
        row_id=row_id,
        dropbox_id=pool_id,
        item=ContentRef(CatalogNamespace.ITEM, item_id),
        increase_rate=rate,
        pool_ordinal=ordinal,
        source_file_ordinal=ordinal,
    )


class FakeCatalog:
    def __init__(self, pool_id: int, rows: tuple[CampaignDropSourceRow, ...]):
        self.pool_id = pool_id
        self.rows = rows

    def pool_for(self, campaign_id, channel):
        require(channel == "repeat", "synthetic catalog used outside repeat channel")
        return self.pool_id, self.rows


class FakeRegistry:
    registry_version = "selftest-pass113"

    def resolve(self, *, wire_campaign_type):
        return CampaignDropPolicy(
            policy_id=CAMPAIGN_REPEAT_POLICY_ID,
            version=CAMPAIGN_REPEAT_POLICY_VERSION,
            enabled=True,
            channel="repeat",
            wire_campaign_types=(1, 2, 24),
            pool_ids=None,
            strategy=CAMPAIGN_REPEAT_STRATEGY,
            parameters={"rate_base": CAMPAIGN_REPEAT_RATE_BASE},
            evidence="private_server_compatibility_source_bounded_not_recovered_official_server_code",
        )


def make_planner(rows, draws, pool_id=777):
    provider = ScriptedEntropyProvider(draws)
    service = RandomOutcomeService(provider)
    adapter = CampaignRandomOutcomeAdapter(service)
    planner = CampaignDropPlanner(
        FakeCatalog(pool_id, tuple(rows)),
        CampaignDropPolicyRegistry(DATA),
        adapter,
        repeat_policy_registry=FakeRegistry(),
    )
    return planner, provider


def test_policy_registry_contract() -> None:
    registry = CampaignRepeatPolicyRegistry(DATA)
    policy = registry.resolve(wire_campaign_type=1)
    require(policy is not None, "repeat policy missing")
    require(policy.policy_id == CAMPAIGN_REPEAT_POLICY_ID, "repeat policy id drift")
    require(policy.version == CAMPAIGN_REPEAT_POLICY_VERSION, "repeat policy version drift")
    require(policy.enabled, "repeat policy must be executable in inert planner")
    require(policy.strategy == CAMPAIGN_REPEAT_STRATEGY, "repeat strategy drift")
    require(int(policy.parameters.get("rate_base")) == 10000, "repeat base drift")
    require("private_server" in policy.evidence, "policy lost private-server evidence label")


def test_rate_decomposition_and_aggregation() -> None:
    rows = [
        source_row(1, 1001, 360000, 1),
        source_row(2, 1002, 13332, 2),
        source_row(3, 1003, 4000, 3),
        source_row(4, 1003, 4000, 4),
        source_row(5, 1004, 10000, 5),
        source_row(6, 1005, 0, 6),
    ]
    draws = [
        ScriptedEntropyDraw(CAMPAIGN_REPEAT_NAMESPACE, 0, 10000, 3331),  # 13332 => 2
        ScriptedEntropyDraw(CAMPAIGN_REPEAT_NAMESPACE, 1, 10000, 3999),  # 4000 hit
        ScriptedEntropyDraw(CAMPAIGN_REPEAT_NAMESPACE, 2, 10000, 4000),  # 4000 miss
    ]
    planner, provider = make_planner(rows, draws)
    plan = planner.plan_repeat_sweep(campaign_id=123, wire_campaign_type=1)
    require(plan.status == "planned", "repeat planner did not plan")
    require(
        list(plan.canonical_awards)
        == [
            {"item_id": 1001, "item_num": 36},
            {"item_id": 1002, "item_num": 2},
            {"item_id": 1003, "item_num": 1},
            {"item_id": 1004, "item_num": 1},
        ],
        f"rate decomposition/aggregation drift: {plan.canonical_awards}",
    )
    require(provider.consumed == tuple((CAMPAIGN_REPEAT_NAMESPACE, i) for i in range(3)), "draw topology drift")
    provider.assert_exhausted()


def test_residual_boundary_miss() -> None:
    planner, provider = make_planner(
        [source_row(1, 1001, 13332, 1)],
        [ScriptedEntropyDraw(CAMPAIGN_REPEAT_NAMESPACE, 0, 10000, 3332)],
    )
    plan = planner.plan_repeat_sweep(campaign_id=123, wire_campaign_type=1)
    require(list(plan.canonical_awards) == [{"item_id": 1001, "item_num": 1}], "residual upper boundary drift")
    provider.assert_exhausted()


def test_zero_and_exact_multiple_consume_no_entropy() -> None:
    planner, provider = make_planner(
        [source_row(1, 1001, 0, 1), source_row(2, 1002, 10000, 2), source_row(3, 1003, 360000, 3)],
        [],
    )
    plan = planner.plan_repeat_sweep(campaign_id=123, wire_campaign_type=1)
    require(list(plan.canonical_awards) == [{"item_id": 1002, "item_num": 1}, {"item_id": 1003, "item_num": 36}], "deterministic quantity drift")
    require(provider.consumed == (), "zero/exact multiple unexpectedly consumed entropy")
    provider.assert_exhausted()


def test_missing_pool_and_zero_pool_invariants() -> None:
    missing, provider = make_planner([], [], pool_id=2200001)
    require_raises(CampaignRepeatPoolUnavailableError, lambda: missing.plan_repeat_sweep(campaign_id=2200001, wire_campaign_type=1), "campaign_repeat_pool_unavailable")
    require(provider.consumed == (), "missing pool consumed entropy")

    zero, provider2 = make_planner([], [], pool_id=0)
    plan = zero.plan_repeat_sweep(campaign_id=100002, wire_campaign_type=1)
    require(plan.status == "planned" and plan.source_pool_id == 0 and plan.canonical_awards == (), "pool id 0 did not remain deterministic-only")
    require(provider2.consumed == (), "pool id 0 consumed entropy")


def test_invalid_rate_fails_before_entropy() -> None:
    planner, provider = make_planner(
        [source_row(1, 1001, -1, 1)],
        [ScriptedEntropyDraw(CAMPAIGN_REPEAT_NAMESPACE, 0, 10000, 0)],
    )
    require_raises(CampaignDropSourceCorruptionError, lambda: planner.plan_repeat_sweep(campaign_id=123, wire_campaign_type=1), "invalid increase_rate")
    require(provider.consumed == (), "invalid source rate consumed entropy")


def test_actual_source_missing_pool_count() -> None:
    source = CampaignDropSourceCatalog(DATA)
    raw = json.loads((DATA / "campaign_drop_source_catalog.json").read_text(encoding="utf-8"))
    missing = []
    zero = 0
    for campaign_id, row in raw["campaigns"].items():
        pool_id, rows = source.pool_for(int(campaign_id), "repeat")
        if pool_id == 0:
            zero += 1
        elif not rows:
            missing.append((int(campaign_id), pool_id))
    require(len(missing) == 24, f"effective-source missing pool count drift: {len(missing)}")
    require(zero == 372, f"effective-source zero-pool count drift: {zero}")


def test_request_services_ros_wiring_is_inert() -> None:
    player = PlayerState(player_id="991130", account_uid="991130", player_name="Pass113")
    services = RequestServices(player, DATA, lambda: None, catalog=CATALOG, entropy_provider=ScriptedEntropyProvider([]))
    require(isinstance(services.campaign_random, CampaignRandomOutcomeAdapter), "Campaign ROS adapter not composed")
    require(services.campaign_random._service is services.random_outcomes, "Campaign adapter is not request-scoped ROS")
    legacy_repeat = services.campaign_drop_planner.plan(
        campaign_id=100001, wire_campaign_type=1, first_clear=False
    )
    require(legacy_repeat.status == "disabled_unknown" and legacy_repeat.canonical_awards == (), "MID113 legacy repeat planning activated early")
    world_hash = hashlib.sha256((ROOT / "gxb_backend/state/world_repository.py").read_bytes()).hexdigest()
    require(world_hash == PASS111_WORLD_SHA256, "WorldRepository changed during inert Phase C1")
    require("campaign_sweep_op_id" not in (ROOT / "gxb_backend/state/world_repository.py").read_text(encoding="utf-8"), "live MID117 identity activated early")
    manifest = json.loads((ROOT / "local_assets/update_manifest.json").read_text(encoding="utf-8"))
    require(manifest.get("version") == "1.631.5", "OTA/resource version advanced during inert Phase C1")
    require(not (ROOT / "local_assets/src_64/app/windows/SweepWindow.lua").exists(), "SweepWindow OTA override shipped early")


def valid_request(**overrides):
    req = {
        "campaign_sweep_op_id": "mid117-123e4567-e89b-42d3-a456-426614174000",
        "campaign_id": 100001,
        "campaign_type": 1,
        "sweep_num": 2,
        "sweep_type": 1,
        "awake_mission": 0,
    }
    req.update(overrides)
    return req


def test_mid117_identity_and_fingerprint() -> None:
    require(Mid117OperationIdentity.from_request({}) is None, "absent operation id should remain inert")
    identity = Mid117OperationIdentity.from_request(valid_request())
    require(identity is not None, "valid identity not parsed")
    require(identity.operation_id.startswith("mid117-"), "operation id normalization drift")
    with_hints = valid_request(itemComposeID=123, needItemComposeNum=4)
    identity2 = Mid117OperationIdentity.from_request(with_hints)
    require(identity2 is not None and identity2.fingerprint == identity.fingerprint, "UI-only compose hints polluted fingerprint")
    require(
        mid117_request_fingerprint(campaign_id=100001, campaign_type=1, sweep_num=2, sweep_type=1, awake_mission=0)
        == identity.fingerprint,
        "fingerprint helper drift",
    )
    require(Mid117OperationIdentity.from_request(valid_request(sweep_num=3)).fingerprint != identity.fingerprint, "semantic tuple change did not change fingerprint")
    require_raises(Mid117OperationIdentityError, lambda: Mid117OperationIdentity.from_request(valid_request(campaign_sweep_op_id="mid117-not-a-uuid")), "UUIDv4")
    require_raises(Mid117OperationIdentityError, lambda: Mid117OperationIdentity.from_request(valid_request(sweep_type=3)), "sweep_type")


def test_mid117_replay_split_and_validation() -> None:
    identity = Mid117OperationIdentity.from_request(valid_request())
    require(identity is not None, "identity setup failed")
    response = {
        "items": [[{"item_id": 2001, "item_num": 2}], []],
        "economys": [{"exp": 0, "mana": 0}, {"exp": 0, "mana": 0}],
        "additional": [],
        "chapter_event": {"id": 7},
        "economy_": {"energy": 88, "crystal": 77},
        "campaign": {"campaign_id": 100001, "daily_limit": 3},
        "challenge": {"foo": 1},
    }
    payload = build_mid117_replay_payload(
        identity=identity,
        response=response,
        source_pool_id=301101,
        source_catalog_sha256=SOURCE_CATALOG_SHA256,
        repeat_policy_id=CAMPAIGN_REPEAT_POLICY_ID,
        repeat_policy_version=CAMPAIGN_REPEAT_POLICY_VERSION,
    )
    require(payload["static_response"]["items"] == response["items"], "static items not preserved")
    require("economy_" not in payload["static_response"] and "campaign" not in payload["static_response"], "cumulative projection leaked into static response")
    require(payload["projection"] == {"economy_keys": ["crystal", "energy"], "campaign": True, "trial": False, "challenge": True}, "projection descriptor drift")
    require(payload["audit"]["source_catalog_sha256"] == SOURCE_CATALOG_SHA256, "catalog audit hash drift")
    response["items"][0][0]["item_num"] = 999
    require(payload["static_response"]["items"][0][0]["item_num"] == 2, "replay payload did not deep-copy static outcome")
    validated = validate_mid117_replay_payload(payload, identity=identity)
    require(validated == payload and validated is not payload, "receipt validation/copy drift")

    bad = copy.deepcopy(payload)
    bad["static_response"]["items"] = [[]]
    require_raises(ValueError, lambda: validate_mid117_replay_payload(bad, identity=identity), "items")
    wrong_identity = Mid117OperationIdentity.from_request(valid_request(sweep_num=3))
    require_raises(ValueError, lambda: validate_mid117_replay_payload(payload, identity=wrong_identity), "sweep_num")


def main() -> int:
    test_policy_registry_contract()
    test_rate_decomposition_and_aggregation()
    test_residual_boundary_miss()
    test_zero_and_exact_multiple_consume_no_entropy()
    test_missing_pool_and_zero_pool_invariants()
    test_invalid_rate_fails_before_entropy()
    test_actual_source_missing_pool_count()
    test_request_services_ros_wiring_is_inert()
    test_mid117_identity_and_fingerprint()
    test_mid117_replay_split_and_validation()
    report = {
        "pass": "113.0",
        "status": "PASS",
        "scope": "Campaign MID117 RNG Phase C1 inert foundation",
        "checks": [
            "versioned campaign_repeat_rate_decomposition_v1 policy registry contract",
            "guaranteed quantity + residual Bernoulli decomposition",
            "strict campaign.repeat.residual namespace and draw topology",
            "boundary hit/miss semantics",
            "zero and exact-multiple rates consume zero entropy",
            "first-source-order canonical aggregation",
            "positive missing pools fail before entropy",
            "repeat_dropbox_id=0 remains deterministic-only",
            "invalid negative rate fails before entropy",
            "effective-source 24 missing positive pools / 372 zero pools invariant",
            "RequestServices Campaign adapter uses request-scoped RandomOutcomeService",
            "WorldRepository MID117 live path remains byte-identical to Pass111",
            "OTA/resource version remains 1.631.5 and SweepWindow override is absent",
            "MID117 UUIDv4 validation and semantic fingerprint",
            "UI compose hints excluded from fingerprint",
            "split exact static response vs live projection descriptor",
            "receipt audit metadata and replay validation",
        ],
    }
    (ROOT / "docs/PASS113_CAMPAIGN_RNG_FOUNDATION_SELFTEST.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
