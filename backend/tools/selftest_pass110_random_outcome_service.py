from __future__ import annotations

import json
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.random_outcome_service import (
    EntropyDrawRequest,
    NamespacedRandbelowAdapter,
    RandomOutcomeService,
    SystemEntropyProvider,
)
from gxb_backend.state.request_services import RequestServices
from gxb_backend.testing.scripted_entropy import (
    ScriptedEntropyDraw,
    ScriptedEntropyProvider,
)

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def require_raises(exc_type, fn, contains: str | None = None) -> BaseException:
    try:
        fn()
    except exc_type as exc:
        if contains is not None:
            require(contains in str(exc), f"exception did not contain {contains!r}: {exc}")
        return exc
    except Exception as exc:  # pragma: no cover - diagnostic branch
        raise AssertionError(
            f"expected {exc_type.__name__}, got {type(exc).__name__}: {exc}"
        ) from exc
    raise AssertionError(f"expected {exc_type.__name__}")


def test_scripted_ordinals_and_namespaces() -> None:
    provider = ScriptedEntropyProvider(
        [
            ScriptedEntropyDraw("summon.classic.pool", 0, 10, 3),
            ScriptedEntropyDraw("summon.classic.pool", 1, 7, 6),
            ScriptedEntropyDraw("summon.sx", 0, 2, 1),
        ]
    )
    service = RandomOutcomeService(provider)
    require(service.randbelow("summon.classic.pool", 10) == 3, "first pool draw drift")
    require(service.randbelow("summon.sx", 2) == 1, "namespace ordinal was not independent")
    require(service.randbelow("summon.classic.pool", 7) == 6, "second pool ordinal drift")
    require(
        provider.consumed
        == (
            ("summon.classic.pool", 0),
            ("summon.sx", 0),
            ("summon.classic.pool", 1),
        ),
        "draw ordering drift",
    )
    provider.assert_exhausted()


def test_validation_consumes_zero_draws() -> None:
    provider = ScriptedEntropyProvider(
        [ScriptedEntropyDraw("campaign.repeat", 0, 4, 2)]
    )
    service = RandomOutcomeService(provider)
    for namespace in ("", "Summon.classic", ".summon", "summon..classic", "summon/classic"):
        require_raises(ValueError, lambda ns=namespace: service.randbelow(ns, 4))
    for upper in (0, -1, True, 1.5):
        require_raises(ValueError, lambda value=upper: service.randbelow("campaign.repeat", value))
    require(provider.consumed == (), "validation failure consumed entropy")
    require(service.randbelow("campaign.repeat", 4) == 2, "ordinal advanced after validation failure")
    provider.assert_exhausted()


def test_choose_and_weighted_exact_one_draw() -> None:
    provider = ScriptedEntropyProvider(
        [
            ScriptedEntropyDraw("gift.open", 0, 5, 4),
            ScriptedEntropyDraw("gift.open", 1, 6, 0),
            ScriptedEntropyDraw("gift.open", 2, 6, 1),
            ScriptedEntropyDraw("gift.open", 3, 6, 5),
        ]
    )
    service = RandomOutcomeService(provider)
    require(service.choose_index("gift.open", 5) == 4, "choose_index mismatch")
    weights = (1, 0, 2, 3)
    require(service.weighted_index("gift.open", weights) == 0, "weighted lower boundary drift")
    require(service.weighted_index("gift.open", weights) == 2, "zero-weight boundary drift")
    require(service.weighted_index("gift.open", weights) == 3, "weighted upper boundary drift")
    provider.assert_exhausted()


def test_weight_validation_is_pre_draw() -> None:
    provider = ScriptedEntropyProvider(
        [ScriptedEntropyDraw("practice.hero", 0, 3, 1)]
    )
    service = RandomOutcomeService(provider)
    invalid = ((), (0, 0), (1, -1), (1, True), (1, 1.5), "123")
    for weights in invalid:
        require_raises(
            ValueError,
            lambda current=weights: service.weighted_index("practice.hero", current),
        )
    require(provider.consumed == (), "invalid weights consumed entropy")
    require(service.weighted_index("practice.hero", (1, 2)) == 1, "valid weighted draw drift")
    provider.assert_exhausted()


def test_provider_failure_does_not_advance_ordinal() -> None:
    mismatch = ScriptedEntropyProvider(
        [ScriptedEntropyDraw("summon.classic.balance", 0, 10, 2)]
    )
    service = RandomOutcomeService(mismatch)
    require_raises(AssertionError, lambda: service.randbelow("summon.classic.balance", 9), "mismatch")
    require(service.randbelow("summon.classic.balance", 10) == 2, "failed provider call advanced ordinal")
    mismatch.assert_exhausted()

    out_of_range = ScriptedEntropyProvider(
        [ScriptedEntropyDraw("summon.medium_legacy", 0, 3, 3)]
    )
    service2 = RandomOutcomeService(out_of_range)
    require_raises(AssertionError, lambda: service2.randbelow("summon.medium_legacy", 3), "out of range")

    unexpected = ScriptedEntropyProvider([])
    require_raises(
        AssertionError,
        lambda: RandomOutcomeService(unexpected).randbelow("summon.sx", 2),
        "unexpected entropy draw",
    )

    missing = ScriptedEntropyProvider(
        [ScriptedEntropyDraw("summon.sx", 0, 2, 0)]
    )
    require_raises(AssertionError, missing.assert_exhausted, "missing expected entropy draws")


def test_service_rejects_invalid_provider_values_without_ordinal_drift() -> None:
    class BadThenGood:
        def __init__(self) -> None:
            self.calls = 0

        def draw(self, request: EntropyDrawRequest) -> int:
            self.calls += 1
            if self.calls == 1:
                return request.upper_exclusive
            return 0

    provider = BadThenGood()
    service = RandomOutcomeService(provider)
    require_raises(ValueError, lambda: service.randbelow("rune.generate", 8), "outside requested range")
    require(service.randbelow("rune.generate", 8) == 0, "invalid provider value advanced ordinal")
    require(provider.calls == 2, "provider call count drift")


def test_namespaced_adapter() -> None:
    provider = ScriptedEntropyProvider(
        [
            ScriptedEntropyDraw("summon.classic.pool", 0, 10000, 9999),
            ScriptedEntropyDraw("summon.classic.pool", 1, 4, 2),
        ]
    )
    service = RandomOutcomeService(provider)
    adapter = NamespacedRandbelowAdapter(service, "summon.classic.pool")
    require(adapter.randbelow(10000) == 9999, "adapter first draw drift")
    require(adapter.randbelow(4) == 2, "adapter second draw drift")
    provider.assert_exhausted()
    require_raises(ValueError, lambda: NamespacedRandbelowAdapter(service, "BAD.namespace"))


def test_system_provider_bounds() -> None:
    provider = SystemEntropyProvider()
    for upper in (1, 2, 17, 10000):
        value = provider.draw(EntropyDrawRequest("selftest.system", 0, upper))
        require(isinstance(value, int) and 0 <= value < upper, "system entropy escaped bound")


def test_request_services_wiring_is_request_scoped_and_inert() -> None:
    scripted_a = ScriptedEntropyProvider(
        [ScriptedEntropyDraw("selftest.request_scope", 0, 2, 1)]
    )
    scripted_b = ScriptedEntropyProvider(
        [ScriptedEntropyDraw("selftest.request_scope", 0, 2, 0)]
    )
    p1 = PlayerState(player_id="991100", account_uid="991100", player_name="Pass110A")
    p2 = PlayerState(player_id="991101", account_uid="991101", player_name="Pass110B")
    s1 = RequestServices(p1, DATA, lambda: None, catalog=CATALOG, entropy_provider=scripted_a)
    s2 = RequestServices(p2, DATA, lambda: None, catalog=CATALOG, entropy_provider=scripted_b)
    require(s1.random_outcomes is not s2.random_outcomes, "ROS instance leaked across request graphs")
    require(s1.random_outcomes.randbelow("selftest.request_scope", 2) == 1, "request A injection failed")
    require(s2.random_outcomes.randbelow("selftest.request_scope", 2) == 0, "request B injection failed")
    scripted_a.assert_exhausted()
    scripted_b.assert_exhausted()

    # Foundation-only boundary: existing planners still own their legacy RNG
    # dependencies until the explicitly separate migration pass.
    require(s1.summon_private_planner.random is not s1.random_outcomes, "MID50 was migrated during foundation pass")
    require(s1.campaign_drop_planner.random_source is not s1.random_outcomes, "Campaign was migrated during foundation pass")


def main() -> int:
    test_scripted_ordinals_and_namespaces()
    test_validation_consumes_zero_draws()
    test_choose_and_weighted_exact_one_draw()
    test_weight_validation_is_pre_draw()
    test_provider_failure_does_not_advance_ordinal()
    test_service_rejects_invalid_provider_values_without_ordinal_drift()
    test_namespaced_adapter()
    test_system_provider_bounds()
    test_request_services_wiring_is_request_scoped_and_inert()
    report = {
        "pass": "110.0",
        "status": "PASS",
        "scope": "RandomOutcomeService foundation only",
        "checks": [
            "strict namespace and positive-bound validation",
            "request-scoped namespace ordinals",
            "validation failures consume zero draws",
            "provider failures do not advance ordinals",
            "choose_index exactly one draw",
            "weighted_index integer cumulative selection exactly one draw",
            "zero/invalid weights fail before entropy",
            "strict scripted missing/unexpected/mismatched/out-of-range failure",
            "script exhaustion detects skipped expected draws",
            "namespaced randbelow adapter compatibility",
            "SystemEntropyProvider bounded OS entropy",
            "RequestServices request-scoped composition/injection",
            "MID50 and Campaign planners deliberately remain unmigrated",
        ],
    }
    (ROOT / "docs/PASS110_RANDOM_OUTCOME_SERVICE_SELFTEST.json").write_text(
        json.dumps(report, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
