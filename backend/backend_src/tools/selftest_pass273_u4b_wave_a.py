#!/usr/bin/env python3
"""Pass273 U4B Wave A: catalogs + strict post-commit foundation."""
from __future__ import annotations

import copy
import json
import sys
from contextlib import contextmanager
from pathlib import Path
from types import MethodType, SimpleNamespace

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

# The reconstruction selftest exercises dispatcher lifecycle only; the CI/tool
# environment used for artifact validation does not necessarily install Flask.
# Provide a minimal import shim before loading EngineDispatcher. Runtime wheels
# remain governed by requirements.txt and are not altered by this test.
try:
    import flask as _flask  # type: ignore
except ModuleNotFoundError:
    import types
    _flask = types.ModuleType("flask")
    _flask.Request = type("Request", (), {})
    _flask.jsonify = lambda value=None, **kwargs: value if value is not None else kwargs
    _flask.make_response = lambda value=None, *args, **kwargs: value
    _flask.send_file = lambda *args, **kwargs: None
    sys.modules["flask"] = _flask

from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
from gxb_backend.state.defaults import default_player
from gxb_backend.state.unit_of_work import OperationContext, PlayerUnitOfWork
from gxb_backend.synchronization import SynchronizationCatalogs

DATA = ROOT / "data"


def test_catalogs() -> dict:
    catalogs = SynchronizationCatalogs.load(DATA)
    assert len(catalogs.hydration_rows()) == 37
    assert catalogs.stage3_contract_mids() == (
        17, 49, 56, 81, 112, 115, 229, 289, 336, 352, 368, 384, 612, 624,
        780, 836, 2137, 2416, 2485, 2560, 2984,
    )
    assert catalogs.bootstrap_compatibility_extra_mids() == (176,)
    assert catalogs.stage3_mids() == (
        17, 49, 56, 81, 112, 115, 176, 229, 289, 336, 352, 368, 384, 612, 624,
        780, 836, 2137, 2416, 2485, 2560, 2984,
    )
    assert [row.channel for row in catalogs.semantic_channels()] == ["economy_", "new_funcs_", "redmarks_"]
    assert [row.mid for row in catalogs.deferred_adapters()] == [124, 530, 816, 822, 1152]
    assert [row.message_type for row in catalogs.message_push_types()] == list(range(1, 13))
    assert not [row.mid for row in catalogs.realtime_events() if row.enabled_in_wave_a]
    return {
        "hydration_contracts": 37,
        "stage3_count": len(catalogs.stage3_mids()),
        "deferred_mids": [row.mid for row in catalogs.deferred_adapters()],
        "message_push_count": len(catalogs.message_push_types()),
        "realtime_enabled": 0,
    }


def _ctx(name: str) -> OperationContext:
    return OperationContext(
        actor_player_id="12500001",
        domain="pass273_selftest",
        operation_name=name,
        server_time=1_700_000_273,
    )


def test_uow_postcommit() -> dict:
    player = default_player()
    player.player_id = "12500001"
    commits: list[int] = []
    uow = PlayerUnitOfWork(player, lambda: commits.append(1))

    try:
        uow.stage_post_commit("realtime.transient", {"x": 1})
    except RuntimeError:
        pass
    else:
        raise AssertionError("stage_post_commit outside transaction did not fail closed")

    source = {"mid": 36855, "params": {"reason": "test"}}
    with uow.transaction(_ctx("commit")):
        uow.stage_post_commit("realtime.transient", source)
        source["params"]["reason"] = "mutated-after-stage"
        uow.request_save()
    assert commits == [1]
    committed = uow.consume_post_commit("realtime.transient")
    assert committed == [{"mid": 36855, "params": {"reason": "test"}}]
    assert uow.consume_post_commit("realtime.transient") == []

    with uow.transaction(_ctx("no_save")):
        uow.stage_post_commit("realtime.transient", {"id": "drop-no-save"})
    assert uow.drain_post_commit() == {}

    try:
        with uow.transaction(_ctx("rollback")):
            uow.stage_post_commit("realtime.transient", {"id": "drop-rollback"})
            uow.request_save()
            raise ValueError("rollback")
    except ValueError:
        pass
    else:
        raise AssertionError("rollback test did not raise")
    assert uow.drain_post_commit() == {}

    failing = PlayerUnitOfWork(player, lambda: (_ for _ in ()).throw(OSError("disk")))
    before = copy.deepcopy(vars(player))
    try:
        with failing.transaction(_ctx("commit_fail")):
            player.mana = 1
            failing.stage_post_commit("realtime.transient", {"id": "drop-failed-commit"})
            failing.request_save()
    except OSError:
        pass
    else:
        raise AssertionError("commit failure did not escape")
    assert failing.drain_post_commit() == {}
    assert vars(player) == before

    with uow.transaction(_ctx("multi_topic")):
        uow.stage_post_commit("realtime.transient", {"id": 1})
        uow.stage_post_commit("future.audit", {"id": 2})
        uow.request_save()
    drained = uow.drain_post_commit()
    assert drained == {
        "realtime.transient": [{"id": 1}],
        "future.audit": [{"id": 2}],
    }
    assert uow.drain_post_commit() == {}

    return {
        "strict_active_transaction": True,
        "commit_only_visibility": True,
        "rollback_drop": True,
        "commit_failure_drop": True,
        "no_save_drop": True,
        "deep_copy": True,
        "all_topic_drain": True,
    }


class _FakeUow:
    def __init__(self, pending):
        self.pending = pending
        self.drains = 0

    def drain_post_commit(self):
        self.drains += 1
        out = self.pending
        self.pending = {}
        return copy.deepcopy(out)


class _FakeState:
    def __init__(self, pending):
        self.in_scope = False
        self.services = SimpleNamespace(uow=_FakeUow(pending))

    @contextmanager
    def request_scope(self, req):
        assert not self.in_scope
        self.in_scope = True
        try:
            yield
        finally:
            self.in_scope = False

    def current_services_or_none(self):
        return self.services


def _make_dispatcher(state, sink, *, raises=False):
    d = EngineDispatcher.__new__(EngineDispatcher)
    d.state = state
    d._post_commit_sink = sink
    if raises:
        def scoped(self, req):
            raise RuntimeError("after-commit-http-projection-failure")
    else:
        def scoped(self, req):
            return {"ok": True}
    d._dispatch_scoped = MethodType(scoped, d)
    return d


def test_dispatch_exit_drain() -> dict:
    observations = []
    state = _FakeState({"realtime.transient": [{"id": 1}]})

    def sink(topic, values):
        observations.append((state.in_scope, topic, values))

    result = _make_dispatcher(state, sink).dispatch({"mid": 1})
    assert result == {"ok": True}
    assert observations == [(False, "realtime.transient", ({"id": 1},))]
    assert state.services.uow.drains == 1

    observations.clear()
    state = _FakeState({"realtime.transient": [{"id": 2}]})
    def sink2(topic, values):
        observations.append((state.in_scope, topic, values))
    try:
        _make_dispatcher(state, sink2, raises=True).dispatch({"mid": 1})
    except RuntimeError as exc:
        assert "projection-failure" in str(exc)
    else:
        raise AssertionError("dispatcher exception path did not re-raise")
    assert observations == [(False, "realtime.transient", ({"id": 2},))]
    assert state.services.uow.drains == 1

    # Sink failure must never replace a successful HTTP outcome.
    state = _FakeState({"realtime.transient": [{"id": 3}]})
    def failing_sink(topic, values):
        assert not state.in_scope
        raise OSError("socket unavailable")
    result = _make_dispatcher(state, failing_sink).dispatch({"mid": 1})
    assert result == {"ok": True}

    return {
        "normal_exit_drained_once": True,
        "exception_exit_drained_once": True,
        "delivery_after_request_scope": True,
        "sink_failure_isolated": True,
    }


def main() -> int:
    report = {
        "pass": "273.0",
        "backend": "0.38.0",
        "wave": "U4B_A",
        "status": "PASS",
        "catalogs": test_catalogs(),
        "uow_postcommit": test_uow_postcommit(),
        "dispatcher_exit": test_dispatch_exit_drain(),
    }
    out = ROOT / "docs" / "PASS273_U4B_WAVE_A_SELFTEST.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
